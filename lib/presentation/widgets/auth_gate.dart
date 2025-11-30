import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_nav_shell.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';
import '../pages/auth/email_verification_page.dart';
import '../pages/auth/login_page.dart';

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
            return AppNavShell(
              authRepository: authRepository,
              userProfileRepository: context.read<UserProfileRepository>(),
              weightHistoryRepository: context.read<WeightHistoryRepository>(),
            );
          },
        );
      },
    );
  }
}

