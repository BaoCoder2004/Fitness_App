import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/admin_layout.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final users = snapshot.data?.docs ?? [];
          final recentUsers = List<QueryDocumentSnapshot>.from(users)
            ..sort((a, b) {
              final ad = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bd = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (ad == null && bd == null) return 0;
              if (ad == null) return 1;
              if (bd == null) return -1;
              return bd.compareTo(ad);
            });

          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));

          final totalUsers = users.length;
          final newUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt == null) return false;
            return createdAt.toDate().isAfter(weekAgo);
          }).length;

          final activeUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] as String? ?? 'active') == 'active';
          }).length;

          final blockedUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] as String?) == 'blocked';
          }).length;

          final adminUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['role'] as String?) == 'admin';
          }).length;

          return Container(
            color: const Color(0xFFF6F8FB),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Tổng quan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Cards row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1100;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row of small cards
                          GridView.count(
                            crossAxisCount: _getCrossAxisCount(context),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 3.5,
                            padding: EdgeInsets.zero,
                            children: [
                              StatCard(
                                title: 'Tổng số user',
                                value: totalUsers.toString(),
                                icon: Icons.people,
                                color: Colors.indigo,
                              ),
                              StatCard(
                                title: 'User mới (7 ngày)',
                                value: newUsers.toString(),
                                icon: Icons.person_add_alt_1,
                                color: Colors.blue,
                              ),
                              StatCard(
                                title: 'Đang hoạt động',
                                value: activeUsers.toString(),
                                icon: Icons.check_circle,
                                color: Colors.teal,
                              ),
                              StatCard(
                                title: 'Đã khóa',
                                value: blockedUsers.toString(),
                                icon: Icons.block,
                                color: Colors.redAccent,
                              ),
                              StatCard(
                                title: 'Admin',
                                value: adminUsers.toString(),
                                icon: Icons.admin_panel_settings,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isWide ? 5 : 6,
                                child: _DonutStatusChart(
                                  data: {
                                    'Active': activeUsers,
                                    'Blocked': blockedUsers,
                                    'Admin': adminUsers,
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: isWide ? 7 : 6,
                                child: _RecentUsersCard(
                                  recentUsers: recentUsers.take(5).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1300) return 5;
    if (width > 1100) return 4;
    if (width > 850) return 3;
    if (width > 600) return 2;
    return 1;
  }
}

class _DonutStatusChart extends StatelessWidget {
  const _DonutStatusChart({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final total = data.values.isEmpty ? 0 : data.values.reduce((a, b) => a + b);
    final sections = data.entries.where((e) => e.value > 0).toList();
    final colors = {
      'Active': Colors.teal,
      'Blocked': Colors.redAccent,
      'Admin': Colors.orange,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
                flex: 3,
            child: SizedBox(
                  height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                      centerSpaceRadius: 42,
                  sections: sections.isEmpty
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: Colors.grey.shade300,
                            title: '',
                          ),
                        ]
                      : sections
                          .map(
                            (e) => PieChartSectionData(
                              value: e.value.toDouble(),
                              color: colors[e.key] ?? Colors.blueGrey,
                              title: '',
                              radius: 56,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng user: $total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...data.entries.map((e) {
                  final pct = total == 0 ? 0 : ((e.value / total) * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[e.key] ?? Colors.blueGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${e.value} (${pct}%)',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersCard extends StatelessWidget {
  const _RecentUsersCard({required this.recentUsers});

  final List<QueryDocumentSnapshot> recentUsers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: recentUsers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có user mới.'),
            )
          : Column(
              children: recentUsers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? 'Chưa có tên';
                final email = data['email'] as String? ?? '';
                final role = data['role'] as String? ?? 'user';
                final status = data['status'] as String? ?? 'active';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final createdAtText = createdAt != null
                    ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                    : '—';

                Color roleColor = role == 'admin'
                    ? const Color(0xFFFFE8C7)
                    : const Color(0xFFE5EDFF);
                Color statusColor = status == 'active'
                    ? const Color(0xFFE7F8EF)
                    : const Color(0xFFFDEBEC);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role == 'admin' ? 'Admin' : 'User',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'active' ? 'Hoạt động' : 'Bị khóa',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        createdAtText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

