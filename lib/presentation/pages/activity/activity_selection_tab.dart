import 'package:flutter/material.dart';

import '../../../core/constants/workout_types.dart';
import 'indoor_tracking_page.dart';
import 'outdoor_tracking_page.dart';

class ActivitySelectionTab extends StatelessWidget {
  const ActivitySelectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Hoạt động ngoài trời (GPS)',
          caption: 'Theo dõi quãng đường, tốc độ và calories',
        ),
        const SizedBox(height: 12),
        _ActivityWrap(
          children: outdoorWorkoutTypes
              .map(
                (item) => _ActivityCard(
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: 'Theo dõi GPS',
                  color: const Color(0xFF4F77FF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OutdoorTrackingPage(
                          activityName: item['title'] as String,
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Hoạt động tại nhà',
          caption: 'Chọn bài tập indoor với MET tương ứng',
        ),
        const SizedBox(height: 12),
        _ActivityWrap(
          children: indoorWorkoutTypes
              .map(
                (type) => _ActivityCard(
                  icon: type.icon,
                  title: type.title,
                  subtitle: 'MET: ${type.met}',
                  color: const Color(0xFF4F77FF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IndoorTrackingPage(workoutType: type),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(31),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityWrap extends StatelessWidget {
  const _ActivityWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;
    final crossAxisCount = isWide ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isWide ? 1.4 : 1.2,
      children: children,
    );
  }
}
