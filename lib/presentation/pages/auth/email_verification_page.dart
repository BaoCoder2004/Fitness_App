import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../widgets/auth_gate.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _checking = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    final viewModel = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await viewModel.reloadCurrentUser();
    if (!mounted) return;
    setState(() => _checking = false);
    final isVerified = viewModel.currentUser?.emailVerified ?? false;
    if (isVerified) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email đã được xác thực.')),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra email và thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xác thực email'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                final authViewModel = context.read<AuthViewModel>();
                final navigator = Navigator.of(context);
                await authViewModel.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chúng tôi đã gửi email xác thực đến:\n$email',
                style: Theme.of(context).textTheme.titleMedium,
            ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng kiểm tra hộp thư (cả mục Spam) và nhấn vào liên kết xác nhận.',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _checking ? null : _checkVerification,
                    child: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đã xác thực? Kiểm tra'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final authViewModel = context.read<AuthViewModel>();
                      await authViewModel.resendVerificationEmail();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi lại email xác thực.'),
                        ),
                      );
                    },
                    child: const Text('Gửi lại email'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final authViewModel = context.read<AuthViewModel>();
                  final navigator = Navigator.of(context);
                  await authViewModel.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Quay lại đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

