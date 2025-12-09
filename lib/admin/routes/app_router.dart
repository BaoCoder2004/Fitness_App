import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../pages/dashboard_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/unlock_requests_page.dart';
import '../pages/users_page.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isLoggedIn = authProvider.currentUser != null;
        final isAdmin = authProvider.isAdmin;
        final isLoginPage = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoginPage) {
          return '/login';
        }

        if (isLoggedIn && !isAdmin && !isLoginPage) {
          return '/login?error=unauthorized';
        }

        if (isLoggedIn && isAdmin && isLoginPage) {
          return '/dashboard';
        }
      } catch (e) {
        // Provider not available yet, allow navigation
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/unlock-requests',
        builder: (context, state) => const UnlockRequestsPage(),
      ),
    ],
  );
}

