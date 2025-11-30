import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';
import '../../presentation/pages/activity/activity_page.dart';
import '../../presentation/pages/ai_coach/ai_coach_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';

class AppNavShell extends StatefulWidget {
  const AppNavShell({
    super.key,
    required this.authRepository,
    required this.userProfileRepository,
    required this.weightHistoryRepository,
  });

  final AuthRepository authRepository;
  final UserProfileRepository userProfileRepository;
  final WeightHistoryRepository weightHistoryRepository;

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ActivityPage(),
    StatisticsPage(),
    AICoachPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

