import 'package:flutter/material.dart';

import 'activity_history_tab.dart';
import 'activity_selection_tab.dart';
import 'gps_routes_tab.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoạt động'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withAlpha(128),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorPadding: const EdgeInsets.all(3),
                    indicator: BoxDecoration(
                      color: colorScheme.primary.withAlpha(200),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    tabs: const [
                      _FilledTab(label: 'Bắt đầu'),
                      _FilledTab(label: 'Lịch sử'),
                      _FilledTab(label: 'GPS Routes'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActivitySelectionTab(),
          ActivityHistoryTab(),
          GpsRoutesTab(),
        ],
      ),
    );
  }
}

class _FilledTab extends StatelessWidget {
  const _FilledTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
