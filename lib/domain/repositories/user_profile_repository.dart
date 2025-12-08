import 'dart:async';

import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> fetchProfile(String uid);

  Future<void> createProfile(UserProfile profile);

  Future<void> updateProfile(UserProfile profile);
  
  /// Listen vào thay đổi của user profile trong Firestore
  /// Trả về Stream<UserProfile?> để có thể detect khi status thay đổi
  Stream<UserProfile?> watchProfile(String uid);
}

