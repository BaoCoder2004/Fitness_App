import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.gradient,
    this.background,
    this.iconColor,
    this.iconBackground,
    this.horizontal = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final Color? background;
  final Color? iconColor;
  final Color? iconBackground;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = background ?? colorScheme.surface;
    final decoration = BoxDecoration(
      gradient: gradient != null
          ? LinearGradient(
              colors: gradient!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: gradient == null ? surfaceColor : null,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: (gradient != null
                  ? gradient!.last
                  : Colors.black.withAlpha(13))
              .withAlpha(46),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
      border: gradient == null
          ? Border.all(color: colorScheme.outline.withAlpha(51))
          : null,
    );

    final iconBg = iconBackground ??
        (gradient != null
            ? Colors.white.withAlpha(64)
            : colorScheme.primary.withAlpha(31));
    final iconDisplayColor =
        iconColor ?? (gradient != null ? Colors.white : colorScheme.primary);
    final titleColor = gradient != null
        ? Colors.white.withAlpha(204)
        : Theme.of(context).textTheme.bodyMedium?.color;
    final valueColor = gradient != null ? Colors.white : colorScheme.onSurface;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 28, color: iconDisplayColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: titleColor,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: content,
      ),
    );
  }
}

