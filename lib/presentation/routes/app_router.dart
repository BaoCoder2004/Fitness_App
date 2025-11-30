import 'package:flutter/material.dart';

import '../pages/auth/login_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/profile/profile_page.dart';

class AppRouter {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case dashboard:
      default:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
    }
  }
}

