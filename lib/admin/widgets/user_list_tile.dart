import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserListTile extends StatelessWidget {
  final String userId;
  final String email;
  final String name;
  final String role;
  final String status;
  final DateTime? createdAt;

  const UserListTile({
    super.key,
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.createdAt,
  });

  Future<void> _updateStatus(BuildContext context) async {
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

  Future<void> _updateRole(BuildContext context) async {
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
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAtText = createdAt != null
        ? dateFormat.format(createdAt!)
        : 'Không rõ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text(status == 'active'
                                ? 'Khóa tài khoản'
                                : 'Mở khóa tài khoản'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _updateStatus(context),
                            ),
                          ),
                          PopupMenuItem(
                            child: Text(role == 'admin'
                                ? 'Thu hồi quyền Admin'
                                : 'Cấp quyền Admin'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _updateRole(context),
                            ),
                          ),
                        ],
                        tooltip: 'Thao tác',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(role == 'admin' ? 'Admin' : 'User'),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: role == 'admin'
                            ? const Color(0xFFFFF4E5)
                            : const Color(0xFFE5EDFF),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Chip(
                        label: Text(status == 'active' ? 'Hoạt động' : 'Bị khóa'),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: status == 'active'
                            ? const Color(0xFFE7F8EF)
                            : const Color(0xFFFDEBEC),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Chip(
                        label: Text('Ngày tạo: $createdAtText'),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

