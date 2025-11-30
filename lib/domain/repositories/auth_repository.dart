import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> reloadCurrentUser();

  Future<void> reauthenticate({
    required String email,
    required String password,
  });

  Future<void> updatePassword(String newPassword);
}

