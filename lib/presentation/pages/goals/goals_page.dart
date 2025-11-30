import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/goal_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/weight_history_repository.dart';
import '../../viewmodels/goal_list_view_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/goal_card.dart';
import 'create_goal_page.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final goalService = GoalService(
      activityRepository: context.read<ActivityRepository>(),
      weightHistoryRepository: context.read<WeightHistoryRepository>(),
      goalRepository: context.read<GoalRepository>(),
      notificationService: context.read<NotificationService>(),
    );

    return Provider<GoalService>.value(
      value: goalService,
      child: ChangeNotifierProvider(
        create: (_) => GoalListViewModel(
          authRepository: context.read<AuthRepository>(),
          goalRepository: context.read<GoalRepository>(),
          goalService: goalService,
        )..load(),
        child: const _GoalsView(),
      ),
    );
  }
}

class _GoalsView extends StatefulWidget {
  const _GoalsView();

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView>
    with SingleTickerProviderStateMixin {
  Future<void> _openEditGoal(BuildContext context, Goal goal) async {
    final vm = context.read<GoalListViewModel>();
    final navigator = Navigator.of(context);
    final updated = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => CreateGoalPage(goal: goal)),
    );
    if (!mounted) return;
    if (updated == true) {
      vm.load();
    }
  }

  Future<void> _confirmDelete(BuildContext context, Goal goal) async {
    final vm = context.read<GoalListViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mục tiêu'),
        content: Text(
          'Bạn chắc chắn muốn xóa mục tiêu "${goal.goalType.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldDelete == true) {
      final success = await vm.deleteGoal(goal);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Đã xóa mục tiêu' : 'Không thể xóa mục tiêu',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GoalListViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mục tiêu của bạn'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang theo dõi'),
              Tab(text: 'Đã hoàn thành'),
            ],
          ),
        ),
        body: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : vm.errorMessage != null
                ? ErrorState(
                    message: vm.errorMessage!,
                    onRetry: vm.load,
                  )
                : TabBarView(
                    children: [
                      _GoalList(
                        goals: vm.activeGoals,
                        emptyTitle: 'Chưa có mục tiêu nào',
                        emptyMessage:
                            'Bắt đầu bằng cách đặt mục tiêu đầu tiên của bạn!',
                        onEdit: (goal) => _openEditGoal(context, goal),
                        onDelete: (goal) => _confirmDelete(context, goal),
                      ),
                      _GoalList(
                        goals: vm.completedGoals,
                        emptyTitle: 'Chưa hoàn thành mục tiêu',
                        emptyMessage:
                            'Hãy tiếp tục luyện tập để đạt được mục tiêu.',
                        onEdit: (goal) => _openEditGoal(context, goal),
                        onDelete: (goal) => _confirmDelete(context, goal),
                      ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const CreateGoalPage()),
            );
            if (!mounted) return;
            if (created == true) {
              vm.load();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Đặt mục tiêu'),
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({
    required this.goals,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onEdit,
    required this.onDelete,
  });

  final List<GoalProgress> goals;
  final String emptyTitle;
  final String emptyMessage;
  final void Function(Goal goal) onEdit;
  final void Function(Goal goal) onDelete;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 120),
          child: EmptyState(
            icon: Icons.flag_circle_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<GoalListViewModel>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final progress = goals[index];
          return GoalCard(
            progress: progress,
            onEdit: () => onEdit(progress.goal),
            onDelete: () => onDelete(progress.goal),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: goals.length,
      ),
    );
  }
}
