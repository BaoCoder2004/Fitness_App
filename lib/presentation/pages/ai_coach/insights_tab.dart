import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/ai_insight.dart';
import '../../../presentation/viewmodels/insights_view_model.dart';
import 'insight_detail_screen.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  @override
  void initState() {
    super.initState();
    // Load insights khi tab được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsViewModel>().loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsightsViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.insights.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải insights...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (viewModel.error != null && viewModel.insights.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  viewModel.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadInsights(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => viewModel.loadInsights(),
              child: Column(
                children: [
                  _buildFilterChips(viewModel),
                  Expanded(
                    child: viewModel.insights.isEmpty
                        ? _buildEmptyState(context, viewModel)
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: viewModel.insights.length,
                      itemBuilder: (context, index) {
                        final insight = viewModel.insights[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _InsightCard(
                            insight: insight,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      InsightDetailScreen(insight: insight),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            onDelete: () => _showDeleteDialog(context, viewModel, insight),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Floating Action Button
            // Chỉ hiển thị khi danh sách đang hiển thị KHÔNG rỗng
            // (nếu filter hiện tại không có insight thì để user dùng button trong empty state)
            if (viewModel.insights.isNotEmpty)
              Positioned(
                bottom: 32,
                right: 16,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: FloatingActionButton.extended(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _generateInsight(
                              context,
                              viewModel,
                              focusType: viewModel.selectedFilter,
                            ),
                    icon: viewModel.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    // Giảm mạnh khoảng cách giữa icon và text
                    extendedIconLabelSpacing: 4,
                    label: Padding(
                      // Tiếp tục giảm padding ngang để icon & text gần nhau hơn nữa
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: Text(viewModel.isLoading ? 'Đang tạo...' : 'Tạo insight'),
                    ),
                  ),
                ),
              ),
            // Loading overlay khi đang tạo insight
            if (viewModel.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Đang phân tích dữ liệu và tạo insight...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng đợi trong giây lát',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, InsightsViewModel viewModel) {
    final hasFilter = viewModel.selectedFilter != null;
    final filterLabel = hasFilter ? _getInsightTypeLabel(viewModel.selectedFilter!) : null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_alt_outlined : Icons.insights_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Chưa có insight loại "$filterLabel"' : 'Chưa có insights',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Hãy tạo insight loại này để xem phân tích từ AI'
                : 'Hãy tạo insight đầu tiên để xem phân tích từ AI',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: viewModel.isLoading
                ? null
                : () => _generateInsight(
                      context,
                      viewModel,
                      focusType: viewModel.selectedFilter,
                    ),
            icon: viewModel.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Padding(
              // Giảm thêm chút padding ngang
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: Text(viewModel.isLoading ? 'Đang tạo...' : 'Tạo insight'),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(InsightsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FilterChip(
              label: const Text('Tất cả'),
              selected: viewModel.selectedFilter == null,
              onSelected: (_) => viewModel.clearFilter(),
            ),
            const SizedBox(width: 8),
            ...InsightType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getInsightTypeLabel(type)),
                  selected: viewModel.selectedFilter == type,
                  onSelected: (_) => viewModel.setFilter(type),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getInsightTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.weight:
        return 'Cân nặng';
      case InsightType.activity:
        return 'Hoạt động';
      case InsightType.goal:
        return 'Mục tiêu';
      case InsightType.gps:
        return 'GPS';
      case InsightType.general:
        return 'Tổng quát';
    }
  }

  Future<void> _generateInsight(
    BuildContext context,
    InsightsViewModel viewModel, {
    InsightType? focusType,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang phân tích dữ liệu...'),
              SizedBox(height: 8),
              Text(
                'Quá trình này có thể mất vài giây',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Người dùng bấm nút => luôn cho phép force để tạo lại insight, không bị cache chặn
      final insight = await viewModel.generateInsight(
        focusType: focusType,
        force: true,
      );
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (insight != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã tạo insight thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${viewModel.error ?? "Không thể tạo insight"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    InsightsViewModel viewModel,
    AIInsight insight,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa insight'),
        content: const Text('Bạn có chắc chắn muốn xóa insight này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteInsight(insight.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.onTap,
    required this.onDelete,
  });

  final AIInsight insight;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getInsightIcon(insight.insightType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getInsightTypeLabel(insight.insightType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showMenu(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.content.length > 150
                    ? '${insight.content.substring(0, 150)}...'
                    : insight.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(insight.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (insight.suggestions.isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.lightbulb_outline,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${insight.suggestions.length} gợi ý',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getInsightIcon(InsightType type) {
    IconData icon;
    Color color;

    switch (type) {
      case InsightType.weight:
        icon = Icons.monitor_weight;
        color = Colors.blue;
        break;
      case InsightType.activity:
        icon = Icons.fitness_center;
        color = Colors.green;
        break;
      case InsightType.goal:
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case InsightType.gps:
        icon = Icons.route;
        color = Colors.purple;
        break;
      case InsightType.general:
        icon = Icons.insights;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getInsightTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.weight:
        return 'Cân nặng';
      case InsightType.activity:
        return 'Hoạt động';
      case InsightType.goal:
        return 'Mục tiêu';
      case InsightType.gps:
        return 'GPS';
      case InsightType.general:
        return 'Tổng quát';
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa insight'),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

