import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> fetchProfile(String uid);

  Future<void> createProfile(UserProfile profile);

  Future<void> updateProfile(UserProfile profile);
}

