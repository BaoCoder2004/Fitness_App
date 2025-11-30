import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';
import 'email_verification_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<AuthViewModel>();
    try {
      await viewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (_) {
      final message = viewModel.errorMessage;
      if (message != null && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email trước.')),
      );
      return;
    }
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.sendPasswordReset(email);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi email đặt lại mật khẩu.')),
      );
    } catch (_) {
      final message = authViewModel.errorMessage;
      if (message != null && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final isLoading = viewModel.isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: isLoading
                              ? null
                              : (value) => setState(
                                  () => _rememberMe = value ?? false),
                        ),
                        const Text('Ghi nhớ đăng nhập'),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : _onForgotPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isLoading || _isGoogleLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final authViewModel = context.read<AuthViewModel>();
                          setState(() => _isGoogleLoading = true);
                          try {
                            await authViewModel.signInWithGoogle();
                          } catch (_) {
                            final message = authViewModel.errorMessage;
                            if (message != null && mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isGoogleLoading = false);
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleLogo(),
                      const SizedBox(width: 12),
                      Text(
                        _isGoogleLoading
                            ? 'Đang kết nối...'
                            : 'Đăng nhập với Google',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa có tài khoản?'),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                    child: const Text('Đăng ký'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (viewModel.currentUser != null &&
                  !(viewModel.currentUser?.emailVerified ?? true))
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailVerificationPage(),
                      ),
                    );
                  },
                  child: const Text('Đã đăng ký? Xác thực email tại đây'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4); // Blue
    canvas.drawArc(rect, -math.pi / 4, math.pi / 2 + math.pi / 6, false, paint);

    paint.color = const Color(0xFF34A853); // Green
    canvas.drawArc(rect, math.pi / 3, math.pi / 3, false, paint);

    paint.color = const Color(0xFFFBBC05); // Yellow
    canvas.drawArc(rect, math.pi, math.pi / 3, false, paint);

    paint.color = const Color(0xFFEA4335); // Red
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, false, paint);

    // Horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.5),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

