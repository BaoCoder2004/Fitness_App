import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Heart Rate Service UUID (Standard BLE Service)
const String heartRateServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
/// Heart Rate Measurement Characteristic UUID
const String heartRateMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';

enum HeartRateZone {
  fatBurn, // 50-60% max HR
  cardio,  // 60-70% max HR
  peak,    // 70-85% max HR
  above,   // >85% max HR
}

class HeartRateService {
  HeartRateService() {
    _heartRateController = StreamController<int>.broadcast();
  }

  StreamController<int>? _heartRateController;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _characteristicSubscription;
  bool _isScanning = false;
  bool _isConnected = false;

  /// Dừng quét thiết bị
  Future<void> stopScan() async {
    if (_isScanning) {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
    }
  }

  /// Stream nhận dữ liệu nhịp tim real-time
  Stream<int> get heartRateStream => _heartRateController?.stream ?? const Stream.empty();

  /// Trạng thái kết nối
  bool get isConnected => _isConnected;

  /// Thiết bị đang kết nối
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Tính nhịp tim tối đa dựa trên tuổi (220 - age)
  static int calculateMaxHR(int age) {
    return 220 - age;
  }

  /// Xác định Heart Rate Zone hiện tại
  static HeartRateZone getHeartRateZone(int heartRate, int maxHR) {
    final percentage = (heartRate / maxHR) * 100;
    if (percentage < 50) {
      return HeartRateZone.fatBurn; // Dưới 50% - Warm up
    } else if (percentage < 60) {
      return HeartRateZone.fatBurn; // 50-60% - Fat Burn
    } else if (percentage < 70) {
      return HeartRateZone.cardio; // 60-70% - Cardio
    } else if (percentage <= 85) {
      return HeartRateZone.peak; // 70-85% - Peak
    } else {
      return HeartRateZone.above; // >85% - Above Peak
    }
  }

  /// Lấy tên zone bằng tiếng Việt
  static String getZoneName(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.fatBurn:
        return 'Fat Burn';
      case HeartRateZone.cardio:
        return 'Cardio';
      case HeartRateZone.peak:
        return 'Peak';
      case HeartRateZone.above:
        return 'Trên Peak';
    }
  }

  /// Kiểm tra Bluetooth có bật không
  Future<bool> isBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Quét các thiết bị BLE hỗ trợ Heart Rate Service
  Stream<List<ScanResult>> scanDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    if (_isScanning) {
      throw Exception('Đang quét thiết bị, vui lòng đợi...');
    }

    final isEnabled = await isBluetoothEnabled();
    if (!isEnabled) {
      throw Exception('Vui lòng bật Bluetooth');
    }

    _isScanning = true;
    try {
      // Bắt đầu quét
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(heartRateServiceUuid)],
      );

      // Stream kết quả quét
      await for (final results in FlutterBluePlus.scanResults) {
        if (!_isScanning) break;
        yield results;
      }
    } finally {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
    }
  }

  /// Kết nối với thiết bị đo nhịp tim
  Future<void> connectDevice(BluetoothDevice device) async {
    if (_isConnected && _connectedDevice?.remoteId == device.remoteId) {
      return; // Đã kết nối rồi
    }

    // Ngắt kết nối cũ nếu có
    await disconnectDevice();

    try {
      _connectedDevice = device;
      await device.connect(timeout: const Duration(seconds: 15));
      _isConnected = true;

      // Khám phá services
      final services = await device.discoverServices();

      // Tìm Heart Rate Service
      BluetoothService? heartRateService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == heartRateServiceUuid.toLowerCase()) {
          heartRateService = service;
          break;
        }
      }

      if (heartRateService == null) {
        await disconnectDevice();
        throw Exception('Thiết bị không hỗ trợ Heart Rate Service');
      }

      // Tìm Heart Rate Measurement Characteristic
      BluetoothCharacteristic? characteristic;
      for (final char in heartRateService.characteristics) {
        if (char.uuid.toString().toLowerCase() == heartRateMeasurementUuid.toLowerCase()) {
          characteristic = char;
          break;
        }
      }

      if (characteristic == null) {
        await disconnectDevice();
        throw Exception('Không tìm thấy Heart Rate Measurement Characteristic');
      }

      // Đăng ký notifications
      await characteristic.setNotifyValue(true);

      // Lắng nghe dữ liệu nhịp tim
      _characteristicSubscription = characteristic.onValueReceived.listen((value) {
        final heartRate = _parseHeartRate(Uint8List.fromList(value));
        if (heartRate != null && _heartRateController != null && !_heartRateController!.isClosed) {
          _heartRateController!.add(heartRate);
        }
      });

      // Lắng nghe sự kiện ngắt kết nối
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _connectedDevice = null;
        }
      });
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      rethrow;
    }
  }

  /// Ngắt kết nối thiết bị
  Future<void> disconnectDevice() async {
    try {
      _characteristicSubscription?.cancel();
      _characteristicSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      // Ignore errors when disconnecting
    } finally {
      _isConnected = false;
      _connectedDevice = null;
    }
  }

  /// Parse dữ liệu nhịp tim từ BLE characteristic
  /// Format: Byte 0 = Flags, Byte 1+ = Heart Rate Value (8-bit hoặc 16-bit)
  int? _parseHeartRate(Uint8List value) {
    if (value.isEmpty) return null;

    final flags = value[0];
    final is16Bit = (flags & 0x01) != 0; // Bit 0 = 1 nếu là 16-bit

    if (is16Bit && value.length >= 3) {
      // 16-bit value (little-endian)
      return (value[2] << 8) | value[1];
    } else if (value.length >= 2) {
      // 8-bit value
      return value[1];
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    disconnectDevice();
    _heartRateController?.close();
    _heartRateController = null;
  }
}

