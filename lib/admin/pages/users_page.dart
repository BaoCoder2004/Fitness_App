import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/admin_layout.dart';
import '../providers/auth_provider.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterRole = 'all';

  Future<void> _updateStatus(BuildContext context, String userId, String status) async {
    final newStatus = status == 'active' ? 'blocked' : 'active';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == 'blocked' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
        content: Text(
          newStatus == 'blocked'
              ? 'Bạn có chắc muốn khóa tài khoản này?'
              : 'Bạn có chắc muốn mở khóa tài khoản này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(newStatus == 'blocked' ? 'Khóa' : 'Mở khóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'status': newStatus});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 'blocked'
                    ? 'Đã khóa tài khoản thành công'
                    : 'Đã mở khóa tài khoản thành công',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateRole(BuildContext context, String userId, String role) async {
    final newRole = role == 'admin' ? 'user' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newRole == 'admin' ? 'Cấp quyền Admin' : 'Thu hồi quyền Admin'),
        content: Text(
          newRole == 'admin'
              ? 'Bạn có chắc muốn cấp quyền admin cho user này? Hành động này có thể gây rủi ro bảo mật.'
              : 'Bạn có chắc muốn thu hồi quyền admin của user này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(newRole == 'admin' ? 'Cấp quyền' : 'Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'role': newRole});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newRole == 'admin'
                    ? 'Đã cấp quyền admin thành công'
                    : 'Đã thu hồi quyền admin thành công',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final headerStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        );

    return AdminLayout(
      title: 'Quản lý người dùng',
      currentRoute: '/users',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF6F8FB),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quản lý người dùng',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Theo dõi tài khoản, vai trò và trạng thái của người dùng.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm email hoặc họ tên...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: _FilterChipDropdown(
                    label: 'Trạng thái',
                    value: _filterStatus,
                    items: const [
                      ('all', 'Tất cả trạng thái'),
                      ('active', 'Hoạt động'),
                      ('blocked', 'Bị khóa'),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: _FilterChipDropdown(
                    label: 'Vai trò',
                    value: _filterRole,
                    items: const [
                      ('all', 'Tất cả vai trò'),
                      ('user', 'Người dùng'),
                      ('admin', 'Admin'),
                    ],
                    onChanged: (v) => setState(() => _filterRole = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
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
                  final filteredUsers = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final role = data['role'] as String? ?? 'user';
                    final email = (data['email'] as String? ?? '').toLowerCase();
                    final name = (data['name'] as String? ?? '').toLowerCase();
                    if (_filterRole != 'all' && role != _filterRole) return false;
                    final status = (data['status'] as String? ?? 'active');
                    if (_filterStatus != 'all' && status != _filterStatus) return false;
                    if (_searchQuery.isEmpty) return true;
                    return email.contains(_searchQuery) || name.contains(_searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có người dùng nào.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DataTableTheme(
                        data: DataTableThemeData(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F6FA)),
                          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                            (states) => states.contains(MaterialState.hovered)
                                ? const Color(0xFFEEF2F7)
                                : null,
                          ),
                          headingTextStyle: headerStyle,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowHeight: 48,
                                    dataRowHeight: 60,
                                    columnSpacing: 28,
                                    horizontalMargin: 16,
                                    columns: const [
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Họ tên')),
                                      DataColumn(label: Text('Vai trò')),
                                      DataColumn(label: Text('Trạng thái')),
                                      DataColumn(label: Text('Ngày tạo')),
                                      DataColumn(label: Text('Thao tác')),
                                    ],
                                    rows: filteredUsers.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final email = data['email'] as String? ?? '';
                                      final name = data['name'] as String? ?? 'Chưa có tên';
                                      final role = data['role'] as String? ?? 'user';
                                      final status = data['status'] as String? ?? 'active';
                                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                                      final createdAtText = createdAt != null
                                          ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                                          : '—';

                                      Color roleColor = role == 'admin'
                                          ? const Color(0xFFFFE8C7)
                                          : const Color(0xFFE5EDFF);
                                      Color roleTextColor = role == 'admin'
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF1D4ED8);
                                      Color statusColor = status == 'active'
                                          ? const Color(0xFFE7F8EF)
                                          : const Color(0xFFFDEBEC);
                                      Color statusTextColor = status == 'active'
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB42318);

                                      final isCurrent = currentUser != null && doc.id == currentUser.uid;
                                      final isAdmin = role == 'admin';

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(email)),
                                          DataCell(Text(name)),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: roleColor,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                role == 'admin' ? 'Admin' : 'Người dùng',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: roleTextColor),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                status == 'active' ? 'Hoạt động' : 'Bị khóa',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(createdAtText)),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                  onPressed: isAdmin ? null : () => _updateStatus(context, doc.id, status),
                                                  child: Text(
                                                    status == 'active' ? 'Khóa' : 'Mở khóa',
                                                    style: TextStyle(color: isAdmin ? Colors.grey : const Color(0xFF111827)),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                TextButton(
                                                  onPressed: isCurrent ? null : () => _updateRole(context, doc.id, role),
                                                  child: Text(
                                                    role == 'admin' ? 'Thu hồi admin' : 'Cấp admin',
                                                    style: TextStyle(color: isCurrent ? Colors.grey : const Color(0xFF4F46E5)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipDropdown extends StatelessWidget {
  const _FilterChipDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      initialValue: value,
      onSelected: onChanged,
      elevation: 10,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 40), // dịch xuống dưới thêm
      itemBuilder: (context) => items
          .map(
            (e) => PopupMenuItem<String>(
              value: e.$1,
              child: Text(
                e.$2,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                items.firstWhere((e) => e.$1 == value).$2,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

