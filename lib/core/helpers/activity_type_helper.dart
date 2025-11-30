import 'package:flutter/material.dart';

import '../constants/workout_types.dart';

class ActivityTypeMeta {
  const ActivityTypeMeta({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.isOutdoor,
  });

  final String key;
  final String displayName;
  final IconData icon;
  final bool isOutdoor;
}

class ActivityTypeHelper {
  static final Map<String, ActivityTypeMeta> _metaByKey = {
    for (final type in indoorWorkoutTypes)
      type.id: ActivityTypeMeta(
        key: type.id,
        displayName: type.title,
        icon: type.icon,
        isOutdoor: false,
      ),
    for (final type in outdoorWorkoutTypes)
      type['id'] as String: ActivityTypeMeta(
        key: type['id'] as String,
        displayName: type['title'] as String,
        icon: type['icon'] as IconData,
        isOutdoor: true,
      ),
  };

  static final Map<String, String> _aliasToKey = {
    for (final entry in _metaByKey.entries) entry.key: entry.key,
    for (final type in indoorWorkoutTypes)
      type.title.toLowerCase(): type.id,
    for (final type in outdoorWorkoutTypes)
      (type['title'] as String).toLowerCase(): type['id'] as String,
    'chay bo': 'running',
    'di bo': 'walking',
    'dap xe': 'cycling',
    'chạy bộ': 'running',
    'đi bộ': 'walking',
    'đạp xe': 'cycling',
  };

  static ActivityTypeMeta resolve(String? rawType) {
    if (rawType == null || rawType.isEmpty) {
      return _fallbackMeta();
    }
    final normalized = rawType.trim().toLowerCase();
    final key = _aliasToKey[normalized] ?? normalized;
    return _metaByKey[key] ??
        ActivityTypeMeta(
          key: rawType,
          displayName: rawType,
          icon: Icons.fitness_center,
          isOutdoor: false,
        );
  }

  static ActivityTypeMeta _fallbackMeta() => const ActivityTypeMeta(
        key: 'unknown',
        displayName: 'Hoạt động',
        icon: Icons.fitness_center,
        isOutdoor: false,
      );
}

