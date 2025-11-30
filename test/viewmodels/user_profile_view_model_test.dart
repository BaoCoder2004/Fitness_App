  import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitness_app/domain/entities/app_user.dart';
import 'package:fitness_app/domain/entities/user_profile.dart';
import 'package:fitness_app/domain/repositories/auth_repository.dart';
import 'package:fitness_app/domain/repositories/user_profile_repository.dart';
import 'package:fitness_app/domain/repositories/weight_history_repository.dart';
import 'package:fitness_app/presentation/viewmodels/user_profile_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockWeightHistoryRepository extends Mock
    implements WeightHistoryRepository {}

void main() {
  final fallbackProfile = UserProfile(
    uid: 'fallback',
    email: 'fallback@example.com',
    name: 'Fallback User',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(fallbackProfile);
  });

  group('UserProfileViewModel', () {
    late _MockAuthRepository authRepository;
    late _MockUserProfileRepository userProfileRepository;
    late _MockWeightHistoryRepository weightHistoryRepository;
    late UserProfileViewModel viewModel;

    final appUser = AppUser(
      uid: 'user123',
      email: 'test@example.com',
      emailVerified: true,
      displayName: 'Test User',
    );

    final profile = UserProfile(
      uid: 'user123',
      email: 'test@example.com',
      name: 'Test User',
      weightKg: 70,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      authRepository = _MockAuthRepository();
      userProfileRepository = _MockUserProfileRepository();
      weightHistoryRepository = _MockWeightHistoryRepository();

      viewModel = UserProfileViewModel(
        authRepository: authRepository,
        userProfileRepository: userProfileRepository,
        weightHistoryRepository: weightHistoryRepository,
      );

      when(() => authRepository.currentUser).thenReturn(appUser);
      when(() => userProfileRepository.fetchProfile(any()))
          .thenAnswer((_) async => profile);
      when(() => userProfileRepository.createProfile(any()))
          .thenAnswer((_) async {});
      when(() => userProfileRepository.updateProfile(any()))
          .thenAnswer((_) async {});
      when(() => weightHistoryRepository.watchRecords(any()))
          .thenAnswer((_) => Stream.value([]));
      when(
        () => weightHistoryRepository.addRecord(
          userId: any(named: 'userId'),
          weightKg: any(named: 'weightKg'),
          recordedAt: any(named: 'recordedAt'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
    });

    test('adds weight history when weight changes', () async {
      await viewModel.loadProfile();

      await viewModel.saveProfile(
        name: 'Test User',
        weightKg: 72,
      );

      verify(
        () => weightHistoryRepository.addRecord(
          userId: 'user123',
          weightKg: 72,
          recordedAt: any(named: 'recordedAt'),
          note: null,
        ),
      ).called(1);
    });

    test('does not add weight history when weight unchanged', () async {
      await viewModel.loadProfile();

      await viewModel.saveProfile(
        name: 'Test User',
        weightKg: 70,
      );

      verifyNever(() => weightHistoryRepository.addRecord(
            userId: any(named: 'userId'),
            weightKg: any(named: 'weightKg'),
            recordedAt: any(named: 'recordedAt'),
            note: any(named: 'note'),
          ));
    });
  });
}

