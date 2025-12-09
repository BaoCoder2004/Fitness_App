import 'package:flutter/material.dart';

import '../../core/services/unlock_request_service.dart';

class UnlockRequestDialog extends StatefulWidget {
  const UnlockRequestDialog({
    super.key,
    required this.userId,
    required this.unlockRequestService,
    this.defaultEmail = '',
    this.defaultName = '',
  });

  final String userId;
  final UnlockRequestService unlockRequestService;
  final String defaultEmail;
  final String defaultName;

  @override
  State<UnlockRequestDialog> createState() => _UnlockRequestDialogState();
}

class _UnlockRequestDialogState extends State<UnlockRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.defaultEmail;
    _nameController.text = widget.defaultName;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final reason = _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim();

      if (widget.userId.isNotEmpty) {
        await widget.unlockRequestService.submitUnlockRequest(
          userId: widget.userId,
          email: email,
          name: name,
          reason: reason,
        );
      } else {
        await widget.unlockRequestService.submitUnlockRequestByEmail(
          email: email,
          name: name,
          reason: reason,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu mở khóa. Vui lòng chờ quản trị viên xử lý.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi yêu cầu thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yêu cầu mở khóa tài khoản',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vui lòng để lại thông tin để quản trị viên xem xét.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!v.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _nameController,
                label: 'Họ tên',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _reasonController,
                label: 'Ghi chú (tuỳ chọn)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Gửi yêu cầu'),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

