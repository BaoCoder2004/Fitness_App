import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
  })  : _authRepository = authRepository,
        _userProfileRepository = userProfileRepository;

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _authRepository.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() => _setError(null);

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (_) {
      _setError('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError();
    try {
      await _authRepository.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (_) {
      _setError('Không thể đăng nhập bằng Google. Thử lại sau.');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reauthenticateAndChangePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentEmail = _authRepository.currentUser?.email;
      if (currentEmail == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Vui lòng đăng nhập lại để đổi mật khẩu.',
        );
      }
      await _authRepository.reauthenticate(
        email: currentEmail,
        password: currentPassword,
      );
      await _authRepository.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (_) {
      _setError('Không thể đổi mật khẩu. Vui lòng thử lại.');
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    clearError();
    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userProfileRepository.createProfile(profile);
      await _authRepository.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (_) {
      _setError('Không thể đăng ký tài khoản. Vui lòng thử lại.');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    await _authRepository.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    await _authRepository.reloadCurrentUser();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}
