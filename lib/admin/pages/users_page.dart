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
      title: 'Quản lý User',
      currentRoute: '/users',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quản lý User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên hoặc email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _FilterChipDropdown(
                  label: 'Trạng thái',
                  value: _filterStatus,
                  items: const [
                    ('all', 'Tất cả trạng thái'),
                    ('active', 'Hoạt động'),
                    ('blocked', 'Bị khóa'),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
                const SizedBox(width: 8),
                _FilterChipDropdown(
                  label: 'Role',
                  value: _filterRole,
                  items: const [
                    ('all', 'Tất cả role'),
                    ('user', 'User'),
                    ('admin', 'Admin'),
                  ],
                  onChanged: (v) => setState(() => _filterRole = v),
                ),
              ],
            ),
          ),
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
                  // Hiển thị cả admin và chính mình; chỉ lọc theo search/filter
                  if (_filterRole != 'all' && role != _filterRole) return false;
                  final status = (data['status'] as String? ?? 'active');
                  if (_filterStatus != 'all' && status != _filterStatus) return false;
                  if (_searchQuery.isEmpty) return true;
                  return email.contains(_searchQuery) || name.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Chưa có user nào'
                          : 'Không tìm thấy user nào',
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.white,
                            ),
                            headingTextStyle: headerStyle,
                            dataRowColor: MaterialStateProperty.resolveWith(
                              (states) => states.contains(MaterialState.hovered)
                                  ? Colors.blue.withOpacity(0.03)
                                  : Colors.white,
                            ),
                            dividerThickness: 0.4,
                            columnSpacing: 22,
                          ),
                        ),
                        child: DataTable(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 0.4,
                            ),
                          ),
                          columns: const [
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Tên')),
                            DataColumn(label: Text('Role')),
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
                            final createdAt =
                                (data['createdAt'] as Timestamp?)?.toDate();
                            final createdAtText = createdAt != null
                                ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                                : '—';

                            Color roleColor = role == 'admin'
                                ? const Color(0xFFFFE8C7)
                                : const Color(0xFFE5EDFF);
                            Color statusColor = status == 'active'
                                ? const Color(0xFFE7F8EF)
                                : const Color(0xFFFDEBEC);

                            final isCurrent = currentUser != null && doc.id == currentUser.uid;
                            final isAdmin = role == 'admin';

                            return DataRow(
                              cells: [
                                DataCell(Text(email)),
                                DataCell(Text(name)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      role == 'admin' ? 'Admin' : 'User',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status == 'active' ? 'Hoạt động' : 'Bị khóa',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(Text(createdAtText)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: isAdmin
                                            ? null
                                            : () => _updateStatus(
                                                context, doc.id, status),
                                        child: Text(
                                          status == 'active' ? 'Khóa' : 'Mở khóa',
                                          style: TextStyle(
                                            color: isAdmin
                                                ? Colors.grey
                                                : null,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isCurrent
                                            ? null
                                            : () =>
                                                _updateRole(context, doc.id, role),
                                        child: Text(
                                          role == 'admin'
                                              ? 'Thu hồi admin'
                                              : 'Cấp admin',
                                          style: TextStyle(
                                            color: isCurrent
                                                ? Colors.grey
                                                : null,
                                          ),
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
                  ),
                );
              },
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Text(
              items.firstWhere((e) => e.$1 == value).$2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

