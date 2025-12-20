import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/workout_types.dart';
import '../../../core/helpers/activity_type_helper.dart';
import '../../../core/services/goal_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/weight_history_repository.dart';
import '../../viewmodels/goal_form_view_model.dart';

class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({super.key, this.goal});

  final Goal? goal;

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();

  late GoalType _selectedType;
  bool _weightLossMode = true;
  String? _selectedActivityType;
  GoalTimeFrame? _selectedTimeFrame;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.goal?.goalType ?? GoalType.calories;
    _targetController.text = widget.goal?.targetValue.toStringAsFixed(1) ?? '';
    if (widget.goal?.goalType == GoalType.weight) {
      _weightLossMode = widget.goal?.direction != 'increase';
    }
    _selectedActivityType = widget.goal?.activityTypeFilter;
    _selectedTimeFrame = widget.goal?.timeFrame ?? GoalTimeFrame.daily;
  }

  bool get isEditing => widget.goal != null;
  
  bool get _isOverdue {
    if (widget.goal == null) return false;
    if (widget.goal!.status == GoalStatus.completed) return false;
    if (widget.goal!.deadline == null) return false;
    final now = DateTime.now();
    final deadlineEnd = DateTime(
      widget.goal!.deadline!.year,
      widget.goal!.deadline!.month,
      widget.goal!.deadline!.day,
      23,
      59,
      59,
    );
    return now.isAfter(deadlineEnd);
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tạo GoalService giống như GoalsPage
    final goalService = GoalService(
      activityRepository: context.read<ActivityRepository>(),
      weightHistoryRepository: context.read<WeightHistoryRepository>(),
      goalRepository: context.read<GoalRepository>(),
      notificationService: context.read<NotificationService>(),
    );

    return ChangeNotifierProvider(
      create: (_) => GoalFormViewModel(
        authRepository: context.read<AuthRepository>(),
        goalRepository: context.read<GoalRepository>(),
        weightHistoryRepository: context.read<WeightHistoryRepository>(),
        goalService: goalService,
      ),
      child: Consumer<GoalFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title:
                  Text(isEditing ? 'Chỉnh sửa mục tiêu' : 'Đặt mục tiêu mới'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cảnh báo nếu goal đã quá deadline
                      if (isEditing && _isOverdue)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withAlpha(100),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mục tiêu đã hết hạn',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mục tiêu này đã quá deadline. Bạn không thể chỉnh sửa các thông tin quan trọng.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.orange.shade700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      _SectionTitle('Loại hoạt động'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedActivityType,
                        decoration: _inputDecoration(),
                        items: _buildActivityTypeItems(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn loại hoạt động';
                          }
                          return null;
                        },
                        onChanged: vm.isSubmitting || (isEditing && _isOverdue)
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedActivityType = value;
                                  // Nếu chọn indoor activity và đang chọn distance, đổi sang calories
                                  if (value != null) {
                                    final meta =
                                        ActivityTypeHelper.resolve(value);
                                    if (!meta.isOutdoor &&
                                        _selectedType == GoalType.distance) {
                                      _selectedType = GoalType.calories;
                                    }
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Khung thời gian'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GoalTimeFrame>(
                        initialValue: _selectedTimeFrame,
                        decoration: _inputDecoration(),
                        items: GoalTimeFrame.values.map((tf) {
                          return DropdownMenuItem(
                            value: tf,
                            child: Text(tf.displayName),
                          );
                        }).toList(),
                        onChanged: vm.isSubmitting || (isEditing && _isOverdue)
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedTimeFrame = value);
                              },
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Loại mục tiêu'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GoalType>(
                        key: ValueKey(_selectedType),
                        initialValue: _selectedType,
                        decoration: _inputDecoration(),
                        items: _buildGoalTypeItems(),
                        onChanged: vm.isSubmitting || (isEditing && _isOverdue)
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedType = value);
                              },
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        'Giá trị mục tiêu (${_selectedType.unitLabel})',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration().copyWith(
                          hintText: _getTargetHint(),
                        ),
                        enabled: !(isEditing && _isOverdue),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập giá trị mục tiêu';
                          }
                          final number =
                              double.tryParse(value.replaceAll(',', '.'));
                          if (number == null || number <= 0) {
                            return 'Giá trị phải lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      if (_selectedType == GoalType.weight) ...[
                        const SizedBox(height: 20),
                        _SectionTitle('Bạn muốn thay đổi thế nào?'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Giảm cân'),
                              selected: _weightLossMode,
                              onSelected: (vm.isSubmitting || (isEditing && _isOverdue))
                                  ? null
                                  : (_) =>
                                      setState(() => _weightLossMode = true),
                            ),
                            ChoiceChip(
                              label: const Text('Tăng cân'),
                              selected: !_weightLossMode,
                              onSelected: (vm.isSubmitting || (isEditing && _isOverdue))
                                  ? null
                                  : (_) =>
                                      setState(() => _weightLossMode = false),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (vm.errorMessage != null) ...[
                        Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (vm.isSubmitting || 
                                     (isEditing && _isOverdue) ||
                                     (_selectedActivityType == null || _selectedActivityType!.isEmpty))
                              ? null
                              : () => _submit(vm),
                          child: vm.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isEditing
                                  ? 'Cập nhật mục tiêu'
                                  : 'Lưu mục tiêu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case GoalType.weight:
        return 'Ví dụ: 5 (kg cần giảm)';
      case GoalType.distance:
        return 'Ví dụ: 30 (km)';
      case GoalType.calories:
        return 'Ví dụ: 3500 (kcal)';
      case GoalType.duration:
        return 'Ví dụ: 600 (phút)';
    }
  }

  List<DropdownMenuItem<String>> _buildActivityTypeItems() {
    final items = <DropdownMenuItem<String>>[
      // Indoor activities
      for (final type in indoorWorkoutTypes)
        DropdownMenuItem(
          value: type.id,
          child: Row(
            children: [
              Icon(type.icon, size: 20),
              const SizedBox(width: 8),
              Text(type.title),
            ],
          ),
        ),
      // Outdoor activities
      for (final type in outdoorWorkoutTypes)
        DropdownMenuItem(
          value: type['id'] as String,
          child: Row(
            children: [
              Icon(type['icon'] as IconData, size: 20),
              const SizedBox(width: 8),
              Text(type['title'] as String),
            ],
          ),
        ),
    ];
    return items;
  }

  List<DropdownMenuItem<GoalType>> _buildGoalTypeItems() {
    final isIndoor = _selectedActivityType != null &&
        !ActivityTypeHelper.resolve(_selectedActivityType).isOutdoor;

    return GoalType.values.map((type) {
      // Ẩn "Quãng đường" nếu chọn indoor activity
      if (type == GoalType.distance && isIndoor) {
        return DropdownMenuItem<GoalType>(
          value: type,
          enabled: false,
          child: Text(
            type.displayName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
          ),
        );
      }
      return DropdownMenuItem(
        value: type,
        child: Text(type.displayName),
      );
    }).toList();
  }

  Future<void> _submit(GoalFormViewModel vm) async {
    // Chặn submit nếu goal đã quá deadline
    if (isEditing && _isOverdue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật mục tiêu đã hết hạn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivityType == null || _selectedActivityType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại hoạt động cho mục tiêu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedTimeFrame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khung thời gian cho mục tiêu.'),
        ),
      );
      return;
    }

    final target = double.parse(_targetController.text.replaceAll(',', '.'));
    final direction = _selectedType == GoalType.weight
        ? (_weightLossMode ? 'decrease' : 'increase')
        : null;

    bool success;
    if (isEditing) {
      success = await vm.updateGoal(
        goal: widget.goal!,
        targetValue: target,
        direction: direction,
        activityTypeFilter: _selectedActivityType,
        timeFrame: _selectedTimeFrame,
      );
    } else {
      success = await vm.submitGoal(
        goalType: _selectedType,
        targetValue: target,
        direction: direction,
        activityTypeFilter: _selectedActivityType,
        timeFrame: _selectedTimeFrame,
      );
    }

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Đã cập nhật mục tiêu'
              : 'Đã tạo mục tiêu thành công'),
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
