import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/advanced_health_calculator.dart';
import '../../../core/services/chart_service.dart';
import '../../../core/services/health_calculator.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/streak.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/streak_repository.dart';
import '../../../domain/repositories/weight_history_repository.dart';
import '../../viewmodels/statistics_view_model.dart';
import '../../viewmodels/user_profile_view_model.dart';
import '../../widgets/activity_chart.dart';
import '../../widgets/bmi_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/streak_card.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatisticsViewModel(
        authRepository: context.read<AuthRepository>(),
        activityRepository: context.read<ActivityRepository>(),
        weightHistoryRepository: context.read<WeightHistoryRepository>(),
        goalRepository: context.read<GoalRepository>(),
        streakRepository: context.read<StreakRepository>(),
        notificationService: context.read<NotificationService>(),
      )..load(),
      child: const _StatisticsContent(),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null
              ? ErrorState(
                  message: vm.errorMessage!,
                  onRetry: vm.load,
                )
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BMI Card
                        _BMISection(),
                        const SizedBox(height: 24),
                        // Advanced health metrics
                        const _AdvancedHealthSection(),
                        const SizedBox(height: 24),
                        // Streak Card
                        _StreakSection(),
                        const SizedBox(height: 24),
                        // Time range selector
                        _TimeRangeSelector(
                          selectedRange: vm.selectedRange,
                          selectedDate: vm.selectedDate,
                          availableWeeks: vm.availableWeeks,
                          availableMonths: vm.availableMonths,
                          availableYears: vm.availableYears,
                          onRangeChanged: vm.setRange,
                          onDateChanged: vm.setSelectedDate,
                        ),
                        const SizedBox(height: 24),
                        // Metric selector
                        _MetricSelector(
                          selectedMetric: vm.selectedMetric,
                          onMetricChanged: vm.setMetric,
                        ),
                        const SizedBox(height: 24),
                        // Chart
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: vm.sortedDataPoints.isEmpty
                              ? Container(
                                  key: const ValueKey('empty-chart'),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withAlpha(51),
                                    ),
                                  ),
                                  child: EmptyState(
                                    icon: Icons.show_chart,
                                    title: 'Chưa có dữ liệu',
                                    message:
                                        'Chưa có dữ liệu trong khoảng thời gian này. Hãy tập luyện để xem biểu đồ!',
                                  ),
                                )
                              : Container(
                                  key: ValueKey(
                                      'chart-${vm.selectedRange}-${vm.selectedMetric}'),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withAlpha(51),
                                    ),
                                  ),
                                  child: ActivityChart(
                                    dataPoints: vm.sortedDataPoints,
                                    getXAxisLabel: vm.getXAxisLabel,
                                    metricLabel: vm.getMetricLabel(),
                                    color: _getMetricColor(
                                        vm.selectedMetric, context),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        // Summary stats
                        _SummaryStats(viewModel: vm),
                        const SizedBox(height: 24),
                        // Comparison with previous period
                        _PeriodComparisonCard(),
                        const SizedBox(height: 24),
                        // Detailed stats
                        _DetailedStatsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Color _getMetricColor(ChartMetric metric, BuildContext context) {
    switch (metric) {
      case ChartMetric.calories:
        return const Color(0xFFE64A19);
      case ChartMetric.distance:
        return const Color(0xFF1E88E5);
      case ChartMetric.duration:
        return const Color(0xFF5E35B1);
      case ChartMetric.weight:
        return const Color(0xFFFF6584);
    }
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selectedRange,
    required this.selectedDate,
    required this.availableWeeks,
    required this.availableMonths,
    required this.availableYears,
    required this.onRangeChanged,
    required this.onDateChanged,
  });

  final TimeRange selectedRange;
  final DateTime selectedDate;
  final List<DateTime> availableWeeks;
  final List<DateTime> availableMonths;
  final List<DateTime> availableYears;
  final ValueChanged<TimeRange> onRangeChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng thời gian',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RangeChip(
              label: 'Ngày',
              range: TimeRange.day,
              selected: selectedRange == TimeRange.day,
              onTap: () => onRangeChanged(TimeRange.day),
            ),
            _RangeChip(
              label: 'Tuần',
              range: TimeRange.week,
              selected: selectedRange == TimeRange.week,
              onTap: () => onRangeChanged(TimeRange.week),
            ),
            _RangeChip(
              label: 'Tháng',
              range: TimeRange.month,
              selected: selectedRange == TimeRange.month,
              onTap: () => onRangeChanged(TimeRange.month),
            ),
            _RangeChip(
              label: 'Năm',
              range: TimeRange.year,
              selected: selectedRange == TimeRange.year,
              onTap: () => onRangeChanged(TimeRange.year),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dropdown để chọn tuần/tháng/năm cụ thể
        // Period dropdown (chỉ hiển thị khi không phải "Ngày")
        if (selectedRange != TimeRange.day)
          _PeriodDropdown(
            selectedRange: selectedRange,
            selectedDate: selectedDate,
            availableWeeks: availableWeeks,
            availableMonths: availableMonths,
            availableYears: availableYears,
            onDateChanged: onDateChanged,
          ),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.selectedRange,
    required this.selectedDate,
    required this.availableWeeks,
    required this.availableMonths,
    required this.availableYears,
    required this.onDateChanged,
  });

  final TimeRange selectedRange;
  final DateTime selectedDate;
  final List<DateTime> availableWeeks;
  final List<DateTime> availableMonths;
  final List<DateTime> availableYears;
  final ValueChanged<DateTime> onDateChanged;

  String _formatWeek(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.day}/${monday.month}/${monday.year} - ${sunday.day}/${sunday.month}/${sunday.year}';
  }

  String _formatMonth(DateTime month) {
    return '${month.month}/${month.year}';
  }

  String _formatYear(DateTime year) {
    return '${year.year}';
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> availablePeriods;
    String Function(DateTime) formatter;
    String? currentValue;

    switch (selectedRange) {
      case TimeRange.week:
        availablePeriods = availableWeeks;
        formatter = _formatWeek;
        // Tìm tuần hiện tại được chọn
        for (final week in availableWeeks) {
          final weekEnd = week.add(const Duration(days: 6));
          if (selectedDate.isAfter(week.subtract(const Duration(days: 1))) &&
              selectedDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
            currentValue = formatter(week);
            break;
          }
        }
        if (currentValue == null && availableWeeks.isNotEmpty) {
          currentValue = formatter(availableWeeks.first);
        }
        break;
      case TimeRange.month:
        availablePeriods = availableMonths;
        formatter = _formatMonth;
        // Tìm tháng hiện tại được chọn
        for (final month in availableMonths) {
          if (selectedDate.year == month.year &&
              selectedDate.month == month.month) {
            currentValue = formatter(month);
            break;
          }
        }
        if (currentValue == null && availableMonths.isNotEmpty) {
          currentValue = formatter(availableMonths.first);
        }
        break;
      case TimeRange.year:
        availablePeriods = availableYears;
        formatter = _formatYear;
        // Tìm năm hiện tại được chọn
        for (final year in availableYears) {
          if (selectedDate.year == year.year) {
            currentValue = formatter(year);
            break;
          }
        }
        if (currentValue == null && availableYears.isNotEmpty) {
          currentValue = formatter(availableYears.first);
        }
        break;
      case TimeRange.day:
      case TimeRange.custom:
        return const SizedBox.shrink();
    }

    // Nếu không có period nào, hiển thị thông báo "Chưa có dữ liệu"
    if (availablePeriods.isEmpty) {
      return Text(
        'Chưa có dữ liệu',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
      );
    }

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: selectedRange == TimeRange.week
            ? 'Chọn tuần'
            : selectedRange == TimeRange.month
                ? 'Chọn tháng'
                : 'Chọn năm',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: availablePeriods.map((period) {
        final label = formatter(period);
        return DropdownMenuItem<String>(
          value: label,
          child: Text(label),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        // Tìm DateTime tương ứng với value được chọn
        for (final period in availablePeriods) {
          if (formatter(period) == value) {
            onDateChanged(period);
            break;
          }
        }
      },
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.range,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TimeRange range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  final ChartMetric selectedMetric;
  final ValueChanged<ChartMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chỉ số',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ChartMetric>(
          initialValue: selectedMetric,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(
              value: ChartMetric.calories,
              child: Text('Calories'),
            ),
            DropdownMenuItem(
              value: ChartMetric.distance,
              child: Text('Quãng đường'),
            ),
            DropdownMenuItem(
              value: ChartMetric.duration,
              child: Text('Thời gian tập'),
            ),
            DropdownMenuItem(
              value: ChartMetric.weight,
              child: Text('Cân nặng'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onMetricChanged(value);
          },
        ),
      ],
    );
  }
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({required this.viewModel});

  final StatisticsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final dataPoints = viewModel.sortedDataPoints;
    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = dataPoints.map((e) => e.value).reduce((a, b) => a + b);
    final average = total / dataPoints.length;
    // Sử dụng maxValue và minValue từ viewModel để lấy giá trị chính xác từ dữ liệu gốc
    final max = viewModel.maxValue ??
        dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final min = viewModel.minValue ??
        dataPoints.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${viewModel.selectedRange}-${viewModel.selectedMetric}'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (viewModel.selectedMetric != ChartMetric.weight) ...[
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Tổng',
                      value: total.toStringAsFixed(1),
                      unit: viewModel.getMetricLabel(),
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Trung bình',
                      value: average.toStringAsFixed(1),
                      unit: viewModel.getMetricLabel(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Cao nhất',
                    value: max.toStringAsFixed(1),
                    unit: viewModel.getMetricLabel(),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Thấp nhất',
                    value: min.toStringAsFixed(1),
                    unit: viewModel.getMetricLabel(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final stats = vm.detailedStats;
    final theme = Theme.of(context);

    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So sánh với kỳ trước',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Cần thêm dữ liệu ở kỳ hiện tại và kỳ trước để hiển thị phần này.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final comparison = stats.comparison;
    final current = stats.current;
    final previous = stats.previous;
    final rangeLabel = _rangeLabel(vm.selectedRange);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'So sánh với $rangeLabel trước',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              Icon(
                Icons.timeline,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Giúp bạn xem mức độ thay đổi giữa hai kỳ liên tiếp.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonRow(
            icon: Icons.local_fire_department,
            color: const Color(0xFFE64A19),
            label: 'Calories',
            currentValue: current.totalCalories,
            previousValue: previous.totalCalories,
            unit: 'kcal',
            decimals: 0,
            percent: comparison.caloriesPercent,
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            icon: Icons.route,
            color: const Color(0xFF1E88E5),
            label: 'Quãng đường',
            currentValue: current.totalDistanceKm,
            previousValue: previous.totalDistanceKm,
            unit: 'km',
            decimals: 2,
            percent: comparison.distancePercent,
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            icon: Icons.schedule_outlined,
            color: const Color(0xFF5E35B1),
            label: 'Thời gian tập',
            currentValue: current.totalDurationHours,
            previousValue: previous.totalDurationHours,
            unit: 'giờ',
            decimals: 1,
            percent: comparison.durationPercent,
          ),
        ],
      ),
    );
  }

  String _rangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return 'ngày';
      case TimeRange.week:
        return 'tuần';
      case TimeRange.month:
        return 'tháng';
      case TimeRange.year:
        return 'năm';
      case TimeRange.custom:
        return 'chu kỳ';
    }
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.decimals,
    required this.percent,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double currentValue;
  final double previousValue;
  final String unit;
  final int decimals;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = currentValue - previousValue;
    final hasPrevious = previousValue > 0;
    final isPositive = diff >= 0;
    final trendColor = isPositive ? Colors.green : Colors.orange;
    final percentText = _formatPercent(percent);
    final diffText = _formatDifference(diff, hasPrevious);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Kỳ này: ${_formatValue(currentValue)} $unit',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                diffText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: trendColor.withAlpha(30),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                percentText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(decimals);
  }

  String _formatDifference(double diff, bool hasPrevious) {
    if (!hasPrevious) {
      if (diff == 0) {
        return 'Không thay đổi so với kỳ trước';
      }
      final direction = diff > 0 ? 'Tăng từ 0' : 'Giảm xuống 0';
      return '$direction, hiện tại ${_formatValue(diff.abs())} $unit';
    }
    if (diff == 0) return 'Không thay đổi so với kỳ trước';
    final sign = diff > 0 ? '+' : '-';
    return '$sign${_formatValue(diff.abs())} $unit so với kỳ trước';
  }

  String _formatPercent(double value) {
    if (value == 0) return '0%';
    return '${value > 0 ? '+' : '-'}${value.abs().toStringAsFixed(1)}%';
  }
}

class _DetailedStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsViewModel>().detailedStats;
    final theme = Theme.of(context);

    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê trung bình',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa đủ dữ liệu để so sánh với kỳ trước.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final current = stats.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê trung bình',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DetailedMetricCard(
              title: 'Calories',
              icon: Icons.local_fire_department,
              color: const Color(0xFFE64A19),
              totalText: '${current.totalCalories.toStringAsFixed(0)} kcal',
              averageText:
                  '${current.averageCaloriesPerDay.toStringAsFixed(0)} kcal/ngày',
            ),
            _DetailedMetricCard(
              title: 'Quãng đường',
              icon: Icons.route,
              color: const Color(0xFF1E88E5),
              totalText: '${current.totalDistanceKm.toStringAsFixed(2)} km',
              averageText:
                  '${current.averageDistancePerDay.toStringAsFixed(2)} km/ngày',
            ),
            _DetailedMetricCard(
              title: 'Thời gian tập',
              icon: Icons.schedule_outlined,
              color: const Color(0xFF5E35B1),
              totalText: '${current.totalDurationHours.toStringAsFixed(1)} giờ',
              averageText:
                  '${current.averageDurationMinutesPerDay.toStringAsFixed(0)} phút/ngày',
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailedMetricCard extends StatelessWidget {
  const _DetailedMetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.totalText,
    required this.averageText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String totalText;
  final String averageText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            averageText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BMISection extends StatelessWidget {
  const _BMISection();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileViewModel>().profile;

    if (profile == null) {
      return const BMICard(bmi: 0);
    }

    final weightKg = profile.weightKg;
    final heightCm = profile.heightCm;

    if (weightKg == null || heightCm == null) {
      return const BMICard(bmi: 0);
    }

    final bmi = HealthCalculator.calculateBMI(weightKg, heightCm);

    return BMICard(
      bmi: bmi,
      weightKg: weightKg,
      heightCm: heightCm,
    );
  }
}

class _AdvancedHealthSection extends StatelessWidget {
  const _AdvancedHealthSection();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileViewModel>().profile;
    final statsVm = context.watch<StatisticsViewModel>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
      ),
      child: profile == null
          ? _buildMissingData(context)
          : _buildMetrics(context, profile, statsVm),
    );
  }

  Widget _buildMissingData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context),
        const SizedBox(height: 12),
        Text(
          'Cần thông tin cơ bản',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng cập nhật cân nặng, chiều cao, tuổi và giới tính trong hồ sơ để tính BMR/TDEE chính xác.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    UserProfile profile,
    StatisticsViewModel statsVm,
  ) {
    final weight = profile.weightKg;
    final height = profile.heightCm;
    final age = profile.age;
    final gender = profile.gender?.toLowerCase();

    if (weight == null || height == null || age == null || gender == null) {
      return _buildMissingData(context);
    }

    final isMale =
        gender == 'male' || gender == 'nam' || gender == 'm' || gender == 'man';

    final bmr = AdvancedHealthCalculator.calculateBMR(
      weightKg: weight,
      heightCm: height,
      age: age,
      isMale: isMale,
    );
    final tdee = AdvancedHealthCalculator.calculateTDEE(
      bmr: bmr,
      intensity: statsVm.activityLevel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'BMR',
                value: bmr.toStringAsFixed(0),
                unit: 'kcal/ngày',
                caption: 'Năng lượng duy trì cơ bản',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'TDEE',
                value: tdee.toStringAsFixed(0),
                unit: 'kcal/ngày',
                caption: 'Tổng năng lượng tiêu hao',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mức độ vận động: ${statsVm.activityLevel.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                statsVm.activityLevel.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.timer,
                      label: 'Phút/tuần',
                      value: statsVm.weeklyActiveMinutes.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.fitness_center,
                      label: 'Buổi/tuần',
                      value: statsVm.weeklySessions.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.eco,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Chỉ số nâng cao',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });

  final String label;
  final String value;
  final String unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final streak = vm.streak;

    if (streak == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có chuỗi ngày',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Bắt đầu tập luyện để tạo chuỗi ngày của bạn!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Kiểm tra xem có sắp mất chuỗi không
    final isWarning = _checkIfWarning(streak);

    return StreakCard(
      streak: streak,
      isWarning: isWarning,
    );
  }

  bool _checkIfWarning(Streak streak) {
    // Nếu streak = 0 thì không cảnh báo
    if (streak.currentStreak == 0) return false;

    // Kiểm tra xem hôm nay đã đạt mục tiêu chưa
    final today = DateTime.now();
    final lastDate = streak.lastDate;

    // Nếu lastDate không phải hôm nay và streak > 0 -> cảnh báo
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);

    return lastDateOnly.isBefore(todayDate);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

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
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: ' $unit',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
