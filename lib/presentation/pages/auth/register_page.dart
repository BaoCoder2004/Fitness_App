import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<AuthViewModel>();
    try {
      await viewModel.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EmailVerificationPage(),
        ),
      );
    } catch (_) {
      final message = viewModel.errorMessage;
      if (message != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  final trimmedValue = value.trim();
                  // Kiểm tra độ dài tối thiểu
                  if (trimmedValue.length < 6) {
                    return 'Họ và tên phải có ít nhất 6 ký tự';
                  }
                  // Kiểm tra độ dài tối đa
                  if (trimmedValue.length > 25) {
                    return 'Họ và tên không được vượt quá 25 ký tự';
                  }
                  // Kiểm tra không được toàn số
                  if (RegExp(r'^\d+$').hasMatch(trimmedValue)) {
                    return 'Họ và tên không được toàn số';
                  }
                  // Kiểm tra không được chứa ký tự đặc biệt (chỉ cho phép chữ cái, dấu cách, và ký tự tiếng Việt)
                  if (!RegExp(r'^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵýỷỹ\s]+$').hasMatch(trimmedValue)) {
                    return 'Họ và tên không được chứa ký tự đặc biệt hoặc số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                        () => _confirmPasswordVisible = !_confirmPasswordVisible),
                  ),
                ),
                obscureText: !_confirmPasswordVisible,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading ? null : _onSubmit,
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

