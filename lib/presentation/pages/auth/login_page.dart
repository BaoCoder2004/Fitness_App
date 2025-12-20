import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../widgets/unlock_request_dialog.dart';
import 'email_verification_page.dart';
import 'register_page.dart';
import '../../../core/services/unlock_request_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _lastDisplayedError; // Track error đã hiển thị để tránh hiển thị lại

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // Reset last displayed error khi dispose để tránh hiển thị lại khi quay lại page
    _lastDisplayedError = null;
    super.dispose();
  }

  void _showBlockedNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ admin để mở khóa.',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    // Load email đã lưu nếu có
    _loadSavedEmail();
    // Clear error message khi vào LoginPage để tránh hiển thị thông báo lỗi cũ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<AuthViewModel>();
        viewModel.clearError();
        _lastDisplayedError = null;
      }
    });
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remembered_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignore errors when loading saved email
    }
  }

  Future<void> _saveEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }
    } catch (e) {
      // Ignore errors when saving email
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    // Cho phép hiển thị lại dialog mỗi lần thử đăng nhập
    _lastDisplayedError = null;
    
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    
    try {
      await viewModel.signIn(
        email,
        _passwordController.text,
      );
      // Lưu email nếu đã chọn "Ghi nhớ đăng nhập"
      await _saveEmail();
    } catch (e) {
      final message = viewModel.errorMessage;
      bool isBlocked = message?.toLowerCase().contains('khóa') == true ||
          e.toString().toLowerCase().contains('blocked') ||
          (e is FirebaseAuthException && e.code == 'user-disabled');

      // Fallback: nếu chưa xác định, kiểm tra profile theo email
      if (!isBlocked && email.isNotEmpty) {
        try {
          final users = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (users.docs.isNotEmpty) {
            final data = users.docs.first.data();
            if ((data['status'] ?? '') == 'blocked') {
              isBlocked = true;
            }
          }
        } catch (_) {
          // bỏ qua lỗi check
        }
      }

      if (isBlocked && mounted) {
        _showBlockedNotice();
        final unlockService = context.read<UnlockRequestService>();
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => UnlockRequestDialog(
            userId: 'temp_${email.hashCode}',
            unlockRequestService: unlockService,
            defaultEmail: email,
          ),
        );
        viewModel.clearError();
        _lastDisplayedError = null;
        return;
      }

      // Lỗi khác
      if (message != null && mounted && message != _lastDisplayedError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        _lastDisplayedError = message;
        viewModel.clearError();
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
    final errorMessage = viewModel.errorMessage;
    
    // Hiển thị lại dialog nếu error từ lần trước là blocked
    if (errorMessage != null &&
        errorMessage != _lastDisplayedError &&
        mounted &&
        !isLoading) {
      final lower = errorMessage.toLowerCase();
      final isBlocked = lower.contains('khóa') || lower.contains('blocked');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            viewModel.errorMessage != errorMessage ||
            errorMessage == _lastDisplayedError) return;

        if (isBlocked) {
          final unlockService = context.read<UnlockRequestService>();
          final email = _emailController.text.trim();
          _showBlockedNotice();
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => UnlockRequestDialog(
              userId: 'temp_${email.hashCode}',
              unlockRequestService: unlockService,
              defaultEmail: email,
            ),
          );
          _lastDisplayedError = errorMessage;
          viewModel.clearError();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
          _lastDisplayedError = errorMessage;
          viewModel.clearError();
        }
      });
    }
    
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
                  final trimmedValue = value.trim();
                  // Kiểm tra định dạng email đúng (chặt chẽ hơn)
                  // Không cho phép dấu chấm ở đầu/cuối phần local, không cho phép dấu chấm liên tiếp
                  // Không cho phép dấu chấm/gạch ngang ở đầu/cuối domain
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(trimmedValue)) {
                    return 'Email không đúng định dạng';
                  }
                  // Kiểm tra thêm: không được có dấu chấm liên tiếp
                  if (trimmedValue.contains('..') || 
                      trimmedValue.startsWith('.') || 
                      trimmedValue.endsWith('.') ||
                      trimmedValue.contains('@.') ||
                      trimmedValue.contains('.@')) {
                    return 'Email không đúng định dạng';
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
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  if (value.length > 128) {
                    return 'Mật khẩu không được vượt quá 128 ký tự';
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
                              : (value) async {
                                  setState(() => _rememberMe = value ?? false);
                                  // Xóa email đã lưu nếu bỏ chọn
                                  if (!(value ?? false)) {
                                    try {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove('remembered_email');
                                    } catch (e) {
                                      // Ignore errors
                                    }
                                  }
                                },
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
                          // Cho phép hiển thị lại dialog mỗi lần thử đăng nhập
                          _lastDisplayedError = null;
                          final messenger = ScaffoldMessenger.of(context);
                          final authViewModel = context.read<AuthViewModel>();
                          setState(() => _isGoogleLoading = true);
                          try {
                            await authViewModel.signInWithGoogle();
                            // Lưu email nếu đã chọn "Ghi nhớ đăng nhập"
                            final googleEmail = authViewModel.currentUser?.email;
                            if (googleEmail != null && _rememberMe) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('remembered_email', googleEmail);
                            }
                          } catch (e) {
                            final message = authViewModel.errorMessage;
                            bool isBlocked = message?.toLowerCase().contains('khóa') == true ||
                                e.toString().toLowerCase().contains('blocked') ||
                                (e is FirebaseAuthException && e.code == 'user-disabled');

                            // Fallback: nếu chưa xác định, thử lấy email hiện tại check Firestore
                            if (!isBlocked) {
                              final email = authViewModel.currentUser?.email ?? _emailController.text.trim();
                              if (email.isNotEmpty) {
                                try {
                                  final users = await FirebaseFirestore.instance
                                      .collection('users')
                                      .where('email', isEqualTo: email)
                                      .limit(1)
                                      .get();
                                  if (users.docs.isNotEmpty) {
                                    final data = users.docs.first.data();
                                    if ((data['status'] ?? '') == 'blocked') {
                                      isBlocked = true;
                                    }
                                  }
                                } catch (_) {
                                  // ignore
                                }
                              }
                            }

                            if (isBlocked && mounted) {
                              final unlockService = context.read<UnlockRequestService>();
                              _showBlockedNotice();
                              await showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => UnlockRequestDialog(
                                  userId: 'temp_google_${DateTime.now().millisecondsSinceEpoch}',
                                  unlockRequestService: unlockService,
                                  defaultEmail: authViewModel.currentUser?.email ?? '',
                                ),
                              );
                              authViewModel.clearError();
                              _lastDisplayedError = null;
                            } else if (message != null && mounted && message != _lastDisplayedError) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  duration: const Duration(seconds: 5),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              _lastDisplayedError = message;
                              authViewModel.clearError();
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

