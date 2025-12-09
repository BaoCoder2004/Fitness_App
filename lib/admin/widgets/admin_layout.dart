import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AdminLayout extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget child;

  const AdminLayout({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarColor = const Color(0xFF1F2933);
    final isWide = MediaQuery.of(context).size.width > 1100;
    final showFullSidebar = ValueNotifier<bool>(false);
    void openSidebar() => showFullSidebar.value = true;
    void closeSidebar() => showFullSidebar.value = false;
    Future<void> doLogout() async {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) context.go('/login');
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Icon(Icons.dashboard_customize, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        actions: const [],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _SidebarContent(
                sidebarColor: sidebarColor,
                currentRoute: currentRoute,
              ),
            ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide)
                Container(
                  width: 88,
                  height: double.infinity,
                  color: sidebarColor,
                  child: _SidebarContent(
                    sidebarColor: sidebarColor,
                    currentRoute: currentRoute,
                    isRail: true,
                    expanded: false,
                    onExpandRequest: openSidebar,
                    onLogout: doLogout,
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF6F8FB),
                  child: child,
                ),
              ),
            ],
          ),
          if (isWide)
            ValueListenableBuilder<bool>(
              valueListenable: showFullSidebar,
              builder: (context, expanded, _) {
                return IgnorePointer(
                  ignoring: !expanded,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: expanded ? 1 : 0,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: closeSidebar,
                          child: Container(
                            color: Colors.black.withOpacity(0.25),
                          ),
                        ),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: expanded ? Offset.zero : const Offset(-0.05, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 210,
                              height: double.infinity,
                              color: sidebarColor,
                              child: _SidebarContent(
                                sidebarColor: sidebarColor,
                                currentRoute: currentRoute,
                                isRail: false,
                                expanded: true,
                                onCloseRequest: closeSidebar,
                                onLogout: doLogout,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.sidebarColor,
    required this.currentRoute,
    this.isRail = false,
    this.expanded = false,
    this.onExpandRequest,
    this.onCloseRequest,
    this.onLogout,
  });

  final Color sidebarColor;
  final String currentRoute;
  final bool isRail;
  final bool expanded;
  final VoidCallback? onExpandRequest;
  final VoidCallback? onCloseRequest;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    Widget navItem({
      required IconData icon,
      required String label,
      required String route,
    }) {
      final selected = currentRoute == route;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isRail) {
              // Khi đang ở chế độ rail, click chỉ để mở sidebar full
              onExpandRequest?.call();
              return;
            }
            if (currentRoute != route) {
              context.go(route);
            }
            onCloseRequest?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isRail
                ? Center(
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                      if (!isRail) ...[
                        const SizedBox(width: 10),
                        AnimatedOpacity(
                          opacity: expanded ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        color: sidebarColor,
        padding: EdgeInsets.symmetric(horizontal: isRail ? 8 : 14, vertical: 16),
        child: Column(
        crossAxisAlignment:
            isRail ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            navItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
            navItem(icon: Icons.people_alt_outlined, label: 'Quản lý User', route: '/users'),
            navItem(icon: Icons.lock_open_outlined, label: 'Yêu cầu mở khóa', route: '/unlock-requests'),
            navItem(icon: Icons.person_outline, label: 'Hồ sơ', route: '/profile'),
            const Spacer(),
            if (onLogout != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    if (isRail) {
                      onExpandRequest?.call();
                      return;
                    }
                    await onLogout?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isRail
                        ? const Icon(Icons.logout, color: Colors.white70)
                        : Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.white70),
                              if (expanded) ...[
                                const SizedBox(width: 10),
                                const Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

