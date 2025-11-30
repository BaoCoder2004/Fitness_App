import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/auth_failure.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
    required WeightHistoryRepository weightHistoryRepository,
  })  : _authRepository = authRepository,
        _userProfileRepository = userProfileRepository,
        _weightHistoryRepository = weightHistoryRepository;

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;
  final WeightHistoryRepository _weightHistoryRepository;

  UserProfile? _profile;
  List<WeightRecord> _weightHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<WeightRecord>>? _weightSubscription;

  UserProfile? get profile => _profile;
  List<WeightRecord> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      _setError('User chưa đăng nhập');
      return;
    }
    _setLoading(true);
    try {
      var profile = await _userProfileRepository.fetchProfile(user.uid);
      final isNewProfile = profile == null;
      profile ??= UserProfile(
        uid: user.uid,
        email: user.email,
        name: user.displayName ?? 'Người dùng',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (isNewProfile) {
        await _userProfileRepository.createProfile(profile);
      }
      _profile = profile;
      _weightSubscription?.cancel();
      _weightSubscription =
          _weightHistoryRepository.watchRecords(user.uid).listen((records) {
        _weightHistory = records;
        notifyListeners();
      });
      _setError(null);
    } catch (e) {
      _setError('Không thể tải hồ sơ. Vui lòng thử lại.');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveProfile({
    required String name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? avatarBase64,
    bool avatarChanged = false,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw AuthFailure('User chưa đăng nhập');
    }
    if (_profile == null) {
      await loadProfile();
    }
    final previousWeight = _profile?.weightKg;
    final normalizedGender = _normalizeGender(gender);
    final updated = (_profile ??
            UserProfile(
              uid: user.uid,
              email: user.email,
              name: name,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      name: name,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: normalizedGender,
      avatarBase64: avatarBase64,
      avatarBase64Set: avatarChanged,
      updatedAt: DateTime.now(),
    );
    await _userProfileRepository.updateProfile(updated);
    _profile = updated;
    notifyListeners();

    if (weightKg != null &&
        (previousWeight == null || weightKg != previousWeight)) {
      await _weightHistoryRepository.addRecord(
        userId: user.uid,
        weightKg: weightKg,
        recordedAt: DateTime.now(),
      );
    }
  }

  String? _normalizeGender(String? gender) {
    if (gender == null) return null;
    switch (gender.toLowerCase()) {
      case 'male':
      case 'nam':
        return 'male';
      case 'female':
      case 'nữ':
      case 'nu':
        return 'female';
      default:
        return 'other';
    }
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    super.dispose();
  }
}

