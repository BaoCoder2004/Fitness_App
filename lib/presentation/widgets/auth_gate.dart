import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_nav_shell.dart';
import '../../core/services/unlock_request_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';
import '../pages/auth/email_verification_page.dart';
import '../pages/auth/login_page.dart';
import 'unlock_request_dialog.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<AppUser?> _refreshCurrentUser(AuthRepository authRepository) async {
    try {
      await authRepository.reloadCurrentUser();
    } catch (_) {
      // ignore refresh errors, auth state stream will handle sign-out if needed
    }
    return authRepository.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return StreamBuilder(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder<AppUser?>(
          future: _refreshCurrentUser(authRepository),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final refreshedUser = userSnapshot.data;
            if (refreshedUser == null) {
              Future.microtask(() => authRepository.signOut());
              return const LoginPage();
            }
            if (!refreshedUser.emailVerified) {
              return const EmailVerificationPage();
            }
            
            // Kiểm tra role - chặn admin vào mobile app
            return FutureBuilder(
              future: context.read<UserProfileRepository>().fetchProfile(refreshedUser.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final profile = profileSnapshot.data;
                if (profile?.role == 'admin') {
                  // Admin không được vào mobile app
                  // Hiển thị thông báo trước khi sign out
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tài khoản admin không thể đăng nhập vào ứng dụng mobile. Vui lòng sử dụng admin panel.'),
                          duration: Duration(seconds: 5),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                  Future.microtask(() => authRepository.signOut());
                  return const LoginPage();
                }
                if (profile?.status == 'blocked') {
                  // User bị khóa - hiển thị dialog liên hệ trước khi sign out
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ admin để mở khóa.',
                          style: TextStyle(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 4),
                        backgroundColor: Colors.red,
                      ),
                    );
                    final unlockService = context.read<UnlockRequestService>();
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => UnlockRequestDialog(
                        userId: refreshedUser.uid,
                        unlockRequestService: unlockService,
                        defaultEmail: refreshedUser.email,
                        defaultName: profile?.name ?? '',
                      ),
                    );
                    if (context.mounted) {
                      await authRepository.signOut();
                    }
                  });
                  return const LoginPage();
                }
                
                return AppNavShell(
                  authRepository: authRepository,
                  userProfileRepository: context.read<UserProfileRepository>(),
                  weightHistoryRepository: context.read<WeightHistoryRepository>(),
                );
              },
            );
          },
        );
      },
    );
  }
}

