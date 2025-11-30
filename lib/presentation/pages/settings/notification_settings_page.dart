import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/notification_settings_view_model.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  static const _weekdayLabels = {
    DateTime.monday: 'Thứ 2',
    DateTime.tuesday: 'Thứ 3',
    DateTime.wednesday: 'Thứ 4',
    DateTime.thursday: 'Thứ 5',
    DateTime.friday: 'Thứ 6',
    DateTime.saturday: 'Thứ 7',
    DateTime.sunday: 'Chủ nhật',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo & nhắc nhở'),
      ),
      body: Consumer<NotificationSettingsViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _IntroCard(),
              if (vm.permissionDenied) ...[
                const SizedBox(height: 16),
                const _PermissionWarningCard(),
              ] else
                const SizedBox(height: 20),
              if (vm.exactAlarmWarning) ...[
                const SizedBox(height: 8),
                _ExactAlarmWarningCard(
                  onOpenSettings: () {
                    vm.openExactAlarmSettings();
                  },
                ),
              ],
              _SectionCard(
                title: 'Nhắc luyện tập hằng ngày',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật nhắc mỗi ngày'),
                      subtitle: const Text(
                          'Nhận thông báo vào một khung giờ cố định'),
                      value: vm.dailyEnabled,
                      onChanged: (value) {
                        vm.setDailyEnabled(value).then((granted) {
                          if (!granted && context.mounted) {
                            _showPermissionSnack(context);
                          }
                        });
                      },
                    ),
                    if (vm.dailyEnabled)
                      _TimePickerTile(
                        label: 'Giờ nhắc',
                        time: vm.dailyTime,
                        onPick: () async {
                          final time = await _pickTime(context, vm.dailyTime);
                          if (time != null) {
                            await vm.setDailyTime(time);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Lịch nhắc luyện tập',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật nhắc theo ngày cố định'),
                      subtitle: const Text(
                        'Tùy chọn các ngày trong tuần muốn được nhắc',
                      ),
                      value: vm.weeklyEnabled,
                      onChanged: (value) {
                        vm.setWeeklyEnabled(value).then((granted) {
                          if (!granted && context.mounted) {
                            _showPermissionSnack(context);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    IgnorePointer(
                      ignoring: !vm.weeklyEnabled,
                      child: Opacity(
                        opacity: vm.weeklyEnabled ? 1 : 0.5,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _weekdayLabels.entries
                              .map(
                                (entry) => ChoiceChip(
                                  label: Text(entry.value),
                                  selected: vm.weeklyDays.contains(entry.key),
                                  onSelected: (_) {
                                    vm.toggleWeeklyDay(entry.key);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (vm.weeklyEnabled)
                      _TimePickerTile(
                        label: 'Giờ nhắc lịch tập',
                        time: vm.weeklyTime,
                        onPick: () async {
                          final time = await _pickTime(context, vm.weeklyTime);
                          if (time != null) {
                            await vm.setWeeklyTime(time);
                          }
                        },
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn các ngày bạn muốn được nhắc luyện tập.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Kiểm tra mục tiêu mỗi tuần',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật thông báo kiểm tra mục tiêu'),
                      subtitle: const Text(
                        'Nhắc bạn xem lại tiến độ vào một ngày cố định',
                      ),
                      value: vm.goalCheckEnabled,
                      onChanged: (value) {
                        vm.setGoalCheckEnabled(value).then((granted) {
                          if (!granted && context.mounted) {
                            _showPermissionSnack(context);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: !vm.goalCheckEnabled,
                      child: Opacity(
                        opacity: vm.goalCheckEnabled ? 1 : 0.5,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Ngày nhắc'),
                              trailing: DropdownButton<int>(
                                value: vm.goalCheckDay,
                                onChanged: (value) {
                                  if (value != null) {
                                    vm.setGoalCheckDay(value);
                                  }
                                },
                                items: _weekdayLabels.entries
                                    .map(
                                      (entry) => DropdownMenuItem<int>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            _TimePickerTile(
                              label: 'Giờ nhắc',
                              time: vm.goalCheckTime,
                              onPick: () async {
                                final time =
                                    await _pickTime(context, vm.goalCheckTime);
                                if (time != null) {
                                  await vm.setGoalCheckTime(time);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<TimeOfDay?> _pickTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: 'Chọn giờ',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
  }

  void _showPermissionSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hãy cấp quyền thông báo để kích hoạt tính năng này.'),
      ),
    );
  }
}

class _PermissionWarningCard extends StatelessWidget {
  const _PermissionWarningCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa được cấp quyền thông báo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng cho phép quyền thông báo trong cài đặt hệ thống để nhận nhắc nhở đúng giờ.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }
}

class _ExactAlarmWarningCard extends StatelessWidget {
  const _ExactAlarmWarningCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withAlpha(32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.tertiary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.alarm_on, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bật quyền “Báo thức & lời nhắc”',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Để nhận thông báo đúng giờ, hãy cho phép ứng dụng đặt báo thức chính xác trong cài đặt hệ thống.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.notifications_active,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không bỏ lỡ lịch tập',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thiết lập lịch nhắc nhở linh hoạt để duy trì thói quen luyện tập và theo dõi mục tiêu.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onPick,
  });

  final String label;
  final TimeOfDay time;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final timeText = time.format(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('Hiện tại: $timeText'),
      trailing: const Icon(Icons.schedule),
      onTap: () {
        onPick();
      },
    );
  }
}
