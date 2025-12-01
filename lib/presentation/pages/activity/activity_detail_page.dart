import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/gps_route.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/gps_route_repository.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({
    super.key,
    required this.session,
    this.routeOverride,
  });

  final ActivitySession session;
  final GpsRoute? routeOverride;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final duration = Duration(seconds: session.durationSeconds);
    final durationStr =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    final meta = ActivityTypeHelper.resolve(session.activityType);

    final gpsRepo = context.read<GpsRouteRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(meta.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + type
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Icon(meta.icon, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      df.format(session.date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Stats
            _StatRow(label: 'Thời gian', value: durationStr),
            if (session.distanceKm != null)
              _StatRow(
                label: 'Quãng đường',
                value: '${session.distanceKm!.toStringAsFixed(2)} km',
              ),
            if (session.averageSpeed != null)
              _StatRow(
                label: 'Tốc độ TB',
                value: '${session.averageSpeed!.toStringAsFixed(1)} km/h',
              ),
            _StatRow(
              label: 'Calories',
              value: '${session.calories.toStringAsFixed(0)} kcal',
            ),
            if (session.averageHeartRate != null)
              _StatRow(
                label: 'Nhịp tim TB',
                value: '${session.averageHeartRate} bpm',
              ),
            const SizedBox(height: 16),
            // Nếu có routeOverride (đi từ tab GPS Routes) thì luôn hiển thị bản đồ,
            // còn lại thì chỉ hiển thị khi buổi tập có dữ liệu quãng đường.
            if (routeOverride != null ||
                (session.distanceKm != null && session.distanceKm! > 0))
              _buildRouteSection(context, gpsRepo),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Ghi chú',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(session.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection(
    BuildContext context,
    GpsRouteRepository gpsRepo,
  ) {
    if (routeOverride != null && routeOverride!.segments.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lộ trình GPS',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: _GpsRouteMap(route: routeOverride!),
          ),
        ],
      );
    }

    return FutureBuilder<GpsRoute?>(
      future: gpsRepo.getRouteForActivity(
        userId: session.userId,
        activityId: session.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final route = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lộ trình GPS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: _GpsRouteMap(route: route),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa buổi tập?'),
        content: const Text('Bạn có chắc chắn muốn xóa buổi tập này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final activityRepo = context.read<ActivityRepository>();
      final gpsRepo = context.read<GpsRouteRepository>();

      await activityRepo.deleteSession(
        userId: session.userId,
        sessionId: session.id,
      );

      // Xóa luôn GPS routes gắn với buổi tập này để tab GPS Routes cập nhật ngay.
      await gpsRepo.deleteRoutesForActivity(
        userId: session.userId,
        activityId: session.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa buổi tập.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _GpsRouteMap extends StatelessWidget {
  const _GpsRouteMap({required this.route});

  final GpsRoute route;

  @override
  Widget build(BuildContext context) {
    if (route.segments.isEmpty || route.startPoint == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(40),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Không có dữ liệu GPS.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final center = LatLng(
      route.startPoint!.lat,
      route.startPoint!.lng,
    );

    final polylines = <Polyline>[];
    for (final segment in route.segments) {
      if (segment.points.length < 2) continue;
      polylines.add(
        Polyline(
          points: segment.points
              .map((p) => LatLng(p.lat, p.lng))
              .toList(growable: false),
          strokeWidth: 4,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final markers = <Marker>[];
    final start = route.startPoint;
    final end = route.endPoint;
    if (start != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(start.lat, start.lng),
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 32,
          ),
        ),
      );
    }
    if (end != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(end.lat, end.lng),
          child: const Icon(
            Icons.flag,
            color: Colors.green,
            size: 30,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fitness_app',
          ),
          if (polylines.isNotEmpty)
            PolylineLayer(
              polylines: polylines,
            ),
          if (markers.isNotEmpty)
            MarkerLayer(
              markers: markers,
            ),
        ],
      ),
    );
  }
}

