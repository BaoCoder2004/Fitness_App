import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/user_profile_view_model.dart';
import '../../../domain/entities/user_profile.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String? _selectedGender;
  bool _saving = false;
  String? _avatarBase64;
  bool _avatarChanged = false;
  bool _processingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.profile.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.profile.weightKg?.toString() ?? '',
    );
    _selectedGender = _normalizeIncomingGender(widget.profile.gender);
    _avatarBase64 = widget.profile.avatarBase64;
  }

  String? _normalizeIncomingGender(String? gender) {
    if (gender == null) return null;
    switch (gender.toLowerCase()) {
      case 'male':
      case 'nam':
        return 'male';
      case 'female':
      case 'nu':
      case 'nữ':
        return 'female';
      case 'khac':
      case 'khác':
      case 'other':
        return 'other';
      default:
        return null;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      _processingAvatar = true;
    });

    try {
      final base64 = await _encodeImage(file);
      if (base64 == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xử lý ảnh đại diện.')),
        );
        return;
      }
      setState(() {
        _avatarBase64 = base64;
        _avatarChanged = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh, thử lại sau.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingAvatar = false;
        });
      }
    }
  }

  Future<String?> _encodeImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = img.copyResize(
      decoded,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    );
    final jpg = img.encodeJpg(resized, quality: 75);
    return base64Encode(jpg);
  }

  void _removeAvatar() {
    setState(() {
      _avatarBase64 = null;
      _avatarChanged = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<UserProfileViewModel>().saveProfile(
            name: _nameController.text.trim(),
            age: _ageController.text.isNotEmpty
                ? int.parse(_ageController.text)
                : null,
            heightCm: _heightController.text.isNotEmpty
                ? double.parse(_heightController.text)
                : null,
            weightKg: _weightController.text.isNotEmpty
                ? double.parse(_weightController.text)
                : null,
            gender: _selectedGender,
            avatarBase64: _avatarBase64,
            avatarChanged: _avatarChanged,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu hồ sơ, thử lại sau.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _AvatarPreview(
                base64Data: _avatarBase64,
                processing: _processingAvatar,
                onPick: _pickAvatar,
                onRemove: _avatarBase64 != null ? _removeAvatar : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Tuổi'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age <= 0) {
                      return 'Tuổi không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                decoration:
                    const InputDecoration(labelText: 'Chiều cao (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Chiều cao không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Cân nặng không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.base64Data,
    required this.processing,
    required this.onPick,
    this.onRemove,
  });

  final String? base64Data;
  final bool processing;
  final Future<void> Function() onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final imageProvider = base64Data != null
        ? MemoryImage(base64Decode(base64Data!))
        : null;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            if (processing)
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: processing ? null : onPick,
              icon: const Icon(Icons.photo),
              label: const Text('Chọn ảnh'),
            ),
            if (onRemove != null)
              TextButton.icon(
                onPressed: processing ? null : onRemove,
                icon: const Icon(Icons.delete),
                label: const Text('Xóa ảnh'),
              ),
          ],
        ),
      ],
    );
  }
}

