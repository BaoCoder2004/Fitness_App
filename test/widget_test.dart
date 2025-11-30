// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:fitness_app/domain/repositories/auth_repository.dart';
import 'package:fitness_app/domain/repositories/user_profile_repository.dart';
import 'package:fitness_app/presentation/pages/auth/login_page.dart';
import 'package:fitness_app/presentation/viewmodels/auth_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late AuthViewModel authViewModel;

  setUp(() {
    authViewModel = AuthViewModel(
      authRepository: _MockAuthRepository(),
      userProfileRepository: _MockUserProfileRepository(),
    );
  });

  testWidgets('Login page renders key UI elements', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: authViewModel,
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.text('Đăng nhập với Google'), findsOneWidget);
    expect(find.text('Bạn chưa có tài khoản?'), findsOneWidget);
  });
}
