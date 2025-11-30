import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../viewmodels/activity_history_view_model.dart';
import '../../widgets/empty_state.dart';
import 'activity_detail_page.dart';

class ActivityHistoryTab extends StatelessWidget {
  const ActivityHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ActivityHistoryViewModel(
        authRepository: context.read<AuthRepository>(),
        activityRepository: context.read<ActivityRepository>(),
      )..loadHistory(),
      child: const _HistoryContent(),
    );
  }
}

class _HistoryContent extends StatefulWidget {
  const _HistoryContent();

  @override
  State<_HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<_HistoryContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityHistoryViewModel>();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm trong ghi chú...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
              vm.setSearchQuery(value);
            },
          ),
        ),
        // Time filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChip(
                label: 'Ngày',
                selected: vm.filter == HistoryFilter.day,
                onTap: () => vm.setFilter(HistoryFilter.day),
              ),
              _FilterChip(
                label: 'Tuần',
                selected: vm.filter == HistoryFilter.week,
                onTap: () => vm.setFilter(HistoryFilter.week),
              ),
              _FilterChip(
                label: 'Tháng',
                selected: vm.filter == HistoryFilter.month,
                onTap: () => vm.setFilter(HistoryFilter.month),
              ),
              _FilterChip(
                label: 'Năm',
                selected: vm.filter == HistoryFilter.year,
                onTap: () => vm.setFilter(HistoryFilter.year),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: vm.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    vm.setSelectedDate(picked);
                  }
                },
              ),
            ],
          ),
        ),
        // Activity type filter
        if (vm.availableActivityTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    selected: vm.activityTypeFilter == null,
                    onTap: () => vm.setActivityTypeFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...vm.availableActivityTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label:
                              ActivityTypeHelper.resolve(type).displayName,
                          selected: vm.activityTypeFilter == type,
                          onTap: () => vm.setActivityTypeFilter(type),
                        ),
                      )),
                ],
              ),
            ),
          ),
        // Date label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _getDateRangeLabel(vm.filter, vm.selectedDate),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // List
        Expanded(
          child: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.sessions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: vm.loadHistory,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyState(
                          icon: Icons.fitness_center,
                          title: 'Chưa có hoạt động nào',
                          message: 'Bắt đầu tập luyện để xem lịch sử hoạt động của bạn!',
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: vm.loadHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final session = vm.sessions[index];
                          return _ActivityTile(session: session);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: vm.sessions.length,
                      ),
                    ),
        ),
      ],
    );
  }

  String _getDateRangeLabel(HistoryFilter filter, DateTime date) {
    final df = DateFormat('dd/MM/yyyy');
    switch (filter) {
      case HistoryFilter.day:
        return df.format(date);
      case HistoryFilter.week:
        final weekday = date.weekday;
        final start = date.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${df.format(start)} - ${df.format(end)}';
      case HistoryFilter.month:
        return DateFormat('MM/yyyy').format(date);
      case HistoryFilter.year:
        return 'Năm ${date.year}';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.session});

  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm');
    final duration = Duration(seconds: session.durationSeconds);
    final durationStr =
        '${duration.inMinutes} phút ${duration.inSeconds % 60} giây';
    final meta = ActivityTypeHelper.resolve(session.activityType);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ActivityDetailPage(session: session),
          ),
        );
        if (deleted == true && context.mounted) {
          context
              .read<ActivityHistoryViewModel>()
              .removeSessionById(session.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(meta.icon,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    df.format(session.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(durationStr,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.calories.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (session.distanceKm != null)
                  Text(
                    '${session.distanceKm!.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

