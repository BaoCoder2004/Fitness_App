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
  
  // Không clear error khi sign out để giữ lại thông báo lỗi (như blocked account)
  void clearErrorOnSignOut() => _setError(null);

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      
      // Kiểm tra role và status sau khi đăng nhập
      final user = _authRepository.currentUser;
      if (user != null) {
        final profile = await _userProfileRepository.fetchProfile(user.uid);
        if (profile?.role == 'admin') {
          // Admin không được đăng nhập vào mobile app
          await _authRepository.signOut();
          _setError('Tài khoản admin không thể đăng nhập vào ứng dụng mobile. Vui lòng sử dụng admin panel.');
          throw Exception('Admin cannot login to mobile app');
        }
        if (profile?.status == 'blocked') {
          // User bị khóa không được đăng nhập
          await _authRepository.signOut();
          _setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
          throw Exception('User account is blocked');
        }
      }
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (e) {
      if (_errorMessage == null) {
        // Kiểm tra loại lỗi cụ thể
        if (e.toString().contains('network') || e.toString().contains('Network')) {
          _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          _setError('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
        } else if (e.toString().contains('blocked')) {
          _setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
        } else {
          _setError('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu, sau đó thử lại.');
        }
      }
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
      
      // Kiểm tra role và status sau khi đăng nhập
      final user = _authRepository.currentUser;
      if (user != null) {
        final profile = await _userProfileRepository.fetchProfile(user.uid);
        if (profile?.role == 'admin') {
          // Admin không được đăng nhập vào mobile app
          await _authRepository.signOut();
          _setError('Tài khoản admin không thể đăng nhập vào ứng dụng mobile. Vui lòng sử dụng admin panel.');
          throw Exception('Admin cannot login to mobile app');
        }
        if (profile?.status == 'blocked') {
          // User bị khóa không được đăng nhập
          await _authRepository.signOut();
          _setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
          throw Exception('User account is blocked');
        }
      }
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (e) {
      if (_errorMessage == null) {
        // Kiểm tra loại lỗi cụ thể
        if (e.toString().contains('network') || e.toString().contains('Network')) {
          _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          _setError('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
        } else if (e.toString().contains('blocked')) {
          _setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.');
        } else if (e.toString().contains('sign_in_canceled') || e.toString().contains('cancelled')) {
          _setError('Đăng nhập bằng Google đã bị hủy.');
        } else {
          _setError('Không thể đăng nhập bằng Google. Vui lòng thử lại sau.');
        }
      }
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
      _setError(_mapChangePasswordError(e.code));
      rethrow;
    } catch (e) {
      // Kiểm tra loại lỗi cụ thể từ FirebaseAuthException đã được xử lý ở trên
      // Nếu đến đây là lỗi khác (network, timeout, etc.)
      if (_errorMessage == null) {
        if (e.toString().contains('network') || e.toString().contains('Network')) {
          _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          _setError('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
        } else {
          _setError('Không thể đổi mật khẩu. Vui lòng kiểm tra mật khẩu hiện tại và thử lại.');
        }
      }
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
        role: 'user', // Set default role for new users
        status: 'active', // Set default status for new users
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userProfileRepository.createProfile(profile);
      await _authRepository.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      rethrow;
    } catch (e) {
      // Kiểm tra loại lỗi cụ thể từ FirebaseAuthException đã được xử lý ở trên
      // Nếu đến đây là lỗi khác (network, timeout, etc.)
      if (_errorMessage == null) {
        if (e.toString().contains('network') || e.toString().contains('Network')) {
          _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          _setError('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
        } else {
          _setError('Không thể đăng ký tài khoản. Vui lòng kiểm tra thông tin và thử lại.');
        }
      }
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
    // Clear error message khi đăng xuất để tránh hiển thị thông báo lỗi cũ
    clearError();
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
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng đợi một lát và thử lại.';
      case 'user-disabled':
        return 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này không được phép.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra lại email và mật khẩu.';
      default:
        return 'Đăng nhập thất bại. Vui lòng kiểm tra thông tin và thử lại.';
    }
  }

  /// Map Firebase error codes thành thông báo lỗi phù hợp cho chức năng đổi mật khẩu
  String _mapChangePasswordError(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Mật khẩu hiện tại không đúng. Vui lòng kiểm tra lại.';
      case 'invalid-credential':
        return 'Mật khẩu hiện tại không đúng. Vui lòng kiểm tra lại.';
      case 'weak-password':
        return 'Mật khẩu mới quá yếu. Vui lòng chọn mật khẩu mạnh hơn (ít nhất 6 ký tự).';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để đổi mật khẩu.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản. Vui lòng đăng nhập lại.';
      case 'user-disabled':
        return 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng đợi một lát và thử lại.';
      default:
        return 'Không thể đổi mật khẩu. Vui lòng kiểm tra mật khẩu hiện tại và thử lại.';
    }
  }
}
