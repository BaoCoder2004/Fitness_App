import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../core/services/goal_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../activity/activity_detail_page.dart';
import '../activity/activity_page.dart';
import '../goals/goals_page.dart';
import '../profile/weight_history_page.dart';

/// Item hiển thị trong popup thông báo
class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.dateFormat,
  });

  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = _iconForType(type);
    final accentColor = _colorForType(colorScheme, type);
    final relativeTime = _relativeTime(timestamp, dateFormat);

    return Container(
      color: theme.colorScheme.primary.withOpacity(0.02),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar / icon tròn giống mẫu
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.15),
            ),
            child: Icon(iconData, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng tiêu đề đậm + nội dung ngắn giống layout mẫu
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relativeTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'goal_completed':
        return Icons.emoji_events_outlined;
      case 'goal_deadline_warning':
        return Icons.warning_amber_outlined;
      case 'goal_deadline':
        return Icons.timer_off_outlined;
      case 'goal_daily_reminder':
      default:
        return Icons.alarm_rounded;
    }
  }

  Color _colorForType(ColorScheme colorScheme, String type) {
    switch (type) {
      case 'goal_completed':
        return Colors.teal;
      case 'goal_deadline_warning':
        return Colors.orange;
      case 'goal_deadline':
        return Colors.redAccent;
      case 'goal_daily_reminder':
      default:
        return colorScheme.primary;
    }
  }

  String _relativeTime(DateTime time, DateFormat fallback) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s trước';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return fallback.format(time);
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  final GlobalKey _notificationButtonKey = GlobalKey();
  int _unreadCount = 0;
  Timer? _unreadCountTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardViewModel>().load();
      _updateUnreadCount();
      _checkAndNotifyCompletedGoals();
      // Cập nhật unread count định kỳ mỗi 5 giây để catch notification mới (giảm tần suất để tối ưu performance)
      _unreadCountTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          _updateUnreadCount();
        }
      });
    });
  }

  @override
  void dispose() {
    _unreadCountTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Khi app resume, cập nhật unread count và check goals
    if (state == AppLifecycleState.resumed) {
      _updateUnreadCount();
      _checkAndNotifyCompletedGoals();
    }
  }

  Future<void> _updateUnreadCount() async {
    final notificationService = context.read<NotificationService>();
    final count = await notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  DateTime? _lastGoalCheckTime;
  Future<void> _checkAndNotifyCompletedGoals() async {
    // Debounce: chỉ check tối đa 1 lần mỗi 10 giây để tránh gọi quá nhiều
    final now = DateTime.now();
    if (_lastGoalCheckTime != null &&
        now.difference(_lastGoalCheckTime!).inSeconds < 10) {
      return;
    }
    _lastGoalCheckTime = now;
    
    try {
      final goalService = context.read<GoalService>();
      final authRepository = context.read<AuthRepository>();
      final userId = authRepository.currentUser?.uid;
      if (userId != null) {
        await goalService.checkAndNotifyCompletedGoals(userId);
      }
    } catch (e) {
      // Ignore errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final stats = vm.stats;
    final userName =
        context.read<AuthRepository>().currentUser?.displayName ?? 'bạn';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Dịch icon sang trái một chút
            child: Stack(
              key: _notificationButtonKey,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'Thông báo',
                  onPressed: _showNotificationDropdown,
                ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _DashboardDrawer(
        onOpenGoals: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GoalsPage()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: vm.isLoading && stats.currentWeight == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _HeroBanner(
                    userName: userName,
                    stats: stats,
                    onStart: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ActivityPage(),
                        ),
                      );
                    },
                    onViewHistory: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ActivityPage(initialTabIndex: 1), // Tab "Lịch sử"
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _WeightCard(
                    weight: stats.currentWeight,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WeightHistoryPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _StatGrid(stats: stats),
                  const SizedBox(height: 24),
                  _QuickActions(
                    onOpenActivities: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ActivityPage(),
                        ),
                      );
                    },
                    onOpenWeightHistory: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WeightHistoryPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _RecentActivityCard(activity: stats.recentActivity),
                ],
              ),
      ),
    );
  }

  Future<void> _showNotificationDropdown() async {
    final buttonContext = _notificationButtonKey.currentContext;
    if (buttonContext == null) return;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlay == null) return;

    final buttonPosition =
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = buttonBox.size;

    final notificationService = context.read<NotificationService>();
    // Khi mở popup, tự động đánh dấu tất cả là đã đọc (badge sẽ biến mất)
    await notificationService.markAllAsRead();
    // Cập nhật unread count sau khi đánh dấu đã đọc
    await _updateUnreadCount();
    if (!mounted) return;

    final theme = Theme.of(context);
    final df = DateFormat('dd/MM HH:mm');

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => _NotificationPopupDialog(
        buttonPosition: buttonPosition,
        buttonSize: buttonSize,
        theme: theme,
        df: df,
        notificationService: notificationService,
        onUpdateUnreadCount: _updateUnreadCount,
      ),
    );
  }
}

/// Popup thông báo với khả năng tự refresh
class _NotificationPopupDialog extends StatefulWidget {
  const _NotificationPopupDialog({
    required this.buttonPosition,
    required this.buttonSize,
    required this.theme,
    required this.df,
    required this.notificationService,
    required this.onUpdateUnreadCount,
  });

  final Offset buttonPosition;
  final Size buttonSize;
  final ThemeData theme;
  final DateFormat df;
  final NotificationService notificationService;
  final Future<void> Function() onUpdateUnreadCount;

  @override
  State<_NotificationPopupDialog> createState() =>
      _NotificationPopupDialogState();
}

class _NotificationPopupDialogState extends State<_NotificationPopupDialog> {
  List<NotificationLogEntry> _history = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Tự động refresh history mỗi 3 giây để catch notification mới (giảm tần suất để tối ưu performance)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history =
        await widget.notificationService.getNotificationHistory(limit: 50);
    if (mounted) {
      // Chỉ update state nếu history thực sự thay đổi (tránh rebuild không cần thiết)
      if (_history.length != history.length ||
          (_history.isNotEmpty &&
              history.isNotEmpty &&
              _history.first.id != history.first.id)) {
        setState(() {
          _history = history;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showEntries = _history.take(10).toList();
    final screenHeight = MediaQuery.of(context).size.height;
    // Chiều cao tối đa của popup ~60% chiều cao màn hình, để tránh overflow
    final maxPopupHeight = screenHeight * 0.6;

    return Stack(
      children: [
        // Invisible tap area to close dialog
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Notification popup
        Positioned(
          // Sát ngay bên dưới icon chuông
          top: widget.buttonPosition.dy + widget.buttonSize.height - 40,
          // Căn mép phải popup đúng bằng mép phải icon chuông
          // để tam giác ở góc phải trên của popup nằm ngay dưới icon
          // Dịch sang trái thêm 20px để popup không quá sát mép
          right: () {
            final screenWidth = MediaQuery.of(context).size.width;
            final buttonRight =
                widget.buttonPosition.dx + widget.buttonSize.width;
            return screenWidth - buttonRight + 4; // Thêm 20px để dịch sang trái
          }(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Arrow indicator hình tam giác, dính liền với khung popup
              // và dịch nhẹ sang trái để nằm gần tâm icon chuông
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: CustomPaint(
                  size: const Size(18, 10),
                  painter: _NotificationTrianglePainter(
                    color: widget.theme.colorScheme.surface,
                    borderColor:
                        widget.theme.colorScheme.outline.withOpacity(0.12),
                  ),
                ),
              ),
              Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(18),
                // Nền popup nhạt hơn (gần trắng) cho cảm giác nhẹ, nổi trên nền xanh
                color: Colors.white,
                child: Container(
                  width: 340,
                  constraints: BoxConstraints(maxHeight: maxPopupHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header giống mẫu: tiêu đề nhỏ + "Mark all as read"
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Text(
                              'THÔNG BÁO',
                              style:
                                  widget.theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: widget.theme.colorScheme.onSurface
                                    .withOpacity(0.85),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                // Đánh dấu tất cả là đã đọc và xóa history
                                await widget.notificationService
                                    .markAllAsRead();
                                // Xóa tất cả history
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.remove('notifications.history');
                                // Cập nhật unread count
                                await widget.onUpdateUnreadCount();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Text(
                                'Đánh dấu đã đọc',
                                style:
                                    widget.theme.textTheme.bodySmall?.copyWith(
                                  color: widget.theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (_history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Chưa có thông báo',
                              style:
                                  widget.theme.textTheme.bodyMedium?.copyWith(
                                color: widget.theme.colorScheme.onSurface
                                    .withOpacity(0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: showEntries.length,
                            separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: widget.theme.colorScheme.outline
                                    .withOpacity(0.06)),
                            itemBuilder: (_, index) {
                              final item = showEntries[index];
                              return _NotificationListTile(
                                title: item.title,
                                body: item.body,
                                timestamp: item.timestamp,
                                type: item.type,
                                dateFormat: widget.df,
                              );
                            },
                          ),
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
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activity});

  final ActivitySession? activity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    if (activity == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colorScheme.outline.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoạt động gần đây', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Chưa có buổi tập nào được ghi nhận hôm nay. Bắt đầu ngay để xem thành tựu của bạn tại đây!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final meta = ActivityTypeHelper.resolve(activity!.activityType);
    final df = DateFormat('dd MMM, HH:mm');
    final duration = Duration(seconds: activity!.durationSeconds);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ActivityDetailPage(session: activity!),
          ),
        );
        if (deleted == true && context.mounted) {
          context.read<DashboardViewModel>().load();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoạt động gần đây',
              style: titleStyle,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(31),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    meta.icon,
                    color: colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.displayName,
                          style: titleStyle?.copyWith(fontSize: 20)),
                      Text(
                        df.format(activity!.date),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActivityStatTile(
                  label: 'Quãng đường',
                  value:
                      '${activity!.distanceKm?.toStringAsFixed(2) ?? '--'} km',
                ),
                _ActivityStatTile(
                  label: 'Năng lượng',
                  value: '${activity!.calories.toStringAsFixed(1)} kcal',
                ),
                _ActivityStatTile(
                  label: 'Thời gian',
                  value: _formatDuration(duration),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStatTile extends StatelessWidget {
  const _ActivityStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.userName,
    required this.stats,
    required this.onStart,
    required this.onViewHistory,
  });

  final String userName;
  final DashboardStats stats;
  final VoidCallback onStart;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final greeting = _greetingText();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(89),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${_capitalize(userName)} 👋',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sẵn sàng đạt mục tiêu hôm nay?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeroChip(
                  label: 'Calories hôm nay',
                  value: '${stats.totalCalories.toStringAsFixed(1)} kcal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroChip(
                  label: 'Thời gian tập',
                  value: _formatDuration(stats.totalDuration),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Bắt đầu ngay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewHistory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(128)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Lịch sử hôm nay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Quãng đường',
        'value': '${stats.totalDistanceKm.toStringAsFixed(2)} km',
        'subtitle': 'Trong ngày hôm nay',
        'icon': Icons.route,
        'background': const Color(0xFFE3F2FD),
        'iconBackground': const Color(0xFFD1E4FF),
        'iconColor': const Color(0xFF1E88E5),
        'horizontal': false,
      },
      {
        'title': 'Calories',
        'value': stats.totalCalories.toStringAsFixed(0),
        'subtitle': 'Tổng năng lượng',
        'icon': Icons.local_fire_department,
        'background': const Color(0xFFFFEBEE),
        'iconBackground': const Color(0xFFFFCDD2),
        'iconColor': const Color(0xFFD32F2F),
        'horizontal': false,
      },
      {
        'title': 'Thời gian tập',
        'value': _formatDuration(stats.totalDuration),
        'subtitle': 'Bao gồm mọi hoạt động',
        'icon': Icons.timer,
        'background': const Color(0xFFEDE7F6),
        'iconBackground': const Color(0xFFD1C4E9),
        'iconColor': const Color(0xFF6A1B9A),
        'horizontal': false,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumns = constraints.maxWidth >= 600;
        final double itemWidth = isTwoColumns
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: DashboardStatCard(
                title: item['title']! as String,
                value: item['value']! as String,
                subtitle: item['subtitle']! as String,
                icon: item['icon']! as IconData,
                background: item['background'] as Color?,
                iconColor: item['iconColor'] as Color?,
                iconBackground: item['iconBackground'] as Color?,
                horizontal: item['horizontal'] as bool? ?? false,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenActivities,
    required this.onOpenWeightHistory,
  });

  final VoidCallback onOpenActivities;
  final VoidCallback onOpenWeightHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hành động nhanh',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.directions_run,
                title: 'Theo dõi hoạt động',
                caption: 'Ghi lại buổi tập mới',
                color: Theme.of(context).colorScheme.primary,
                onTap: onOpenActivities,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.monitor_weight,
                title: 'Lịch sử cân nặng',
                caption: 'Kiểm tra tiến trình',
                color: Theme.of(context).colorScheme.tertiary,
                onTap: onOpenWeightHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withAlpha(31),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.onOpenGoals,
  });

  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                // Nền xanh đậm hơn để chữ trắng nổi rõ
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Fitness App',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded),
              title: const Text('Mục tiêu của tôi'),
              subtitle: const Text('Tạo và theo dõi tiến độ'),
              onTap: onOpenGoals,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.weight, required this.onTap});

  final double? weight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weightText =
        weight != null ? '${weight!.toStringAsFixed(1)} kg' : '--';
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFDDDBB)),
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC48E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.monitor_weight, color: Colors.white),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cân nặng hiện tại',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weightText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chạm để xem lịch sử',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours > 0) {
    return '$hours giờ ${minutes.toString().padLeft(2, '0')} phút';
  }
  if (minutes > 0) {
    return '$minutes phút';
  }
  return '${duration.inSeconds % 60} giây';
}

String _greetingText() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Chào buổi sáng';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String _capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

/// Vẽ mũi tên tam giác cho popup thông báo (trỏ lên trên)
class _NotificationTrianglePainter extends CustomPainter {
  _NotificationTrianglePainter({
    required this.color,
    required this.borderColor,
  });

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
