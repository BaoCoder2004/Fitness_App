import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/user_profile_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import 'edit_profile_page.dart';
import 'weight_history_page.dart';
import '../auth/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProfileViewModel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserProfileViewModel>();
    final profile = viewModel.profile;

    if (viewModel.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không thể tải hồ sơ. Vui lòng đăng nhập lại.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final profileVm = context.read<UserProfileViewModel>();
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(profile: profile),
                ),
              );
              if (!mounted) return;
              if (updated == true) {
                await profileVm.loadProfile();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authViewModel = context.read<AuthViewModel>();
              final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text(
                          'Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!mounted || !confirm) return;
              await authViewModel.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: profile.avatarBase64 != null
                      ? MemoryImage(base64Decode(profile.avatarBase64!))
                      : null,
                  child: profile.avatarBase64 == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(profile.email),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'Tuổi', value: profile.age?.toString() ?? '--'),
            _InfoRow(
                label: 'Chiều cao',
                value: profile.heightCm != null
                    ? '${profile.heightCm!.toStringAsFixed(1)} cm'
                    : '--'),
            _InfoRow(
                label: 'Cân nặng',
                value: profile.weightKg != null
                    ? '${profile.weightKg!.toStringAsFixed(1)} kg'
                    : '--'),
            _InfoRow(
                label: 'Giới tính', value: _genderDisplay(profile.gender)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ProfileActionButton(
                    title: 'Lịch sử cân nặng',
                    subtitle: 'Theo dõi tiến trình',
                    icon: Icons.monitor_weight,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WeightHistoryPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileActionButton(
                    title: 'Đổi mật khẩu',
                    subtitle: 'Bảo vệ tài khoản',
                    icon: Icons.lock,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _genderDisplay(String? gender) {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return 'Chưa cập nhật';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 120,
        child: Container(
          padding: const EdgeInsets.all(8), // Giảm padding thêm để cả subtitle cũng không bị xuống hàng
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Giảm padding icon thêm
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 18), // Giảm size icon thêm
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12, // Giảm font size thêm
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11, // Giảm font size subtitle
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

