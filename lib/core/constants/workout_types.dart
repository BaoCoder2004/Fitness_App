import 'package:flutter/material.dart';

class IndoorWorkoutType {
  const IndoorWorkoutType({
    required this.id,
    required this.title,
    required this.met,
    required this.icon,
  });

  final String id;
  final String title;
  final double met;
  final IconData icon;
}

const indoorWorkoutTypes = [
  IndoorWorkoutType(
    id: 'aerobic',
    title: 'Aerobic',
    met: 7.0,
    icon: Icons.directions_run,
  ),
  IndoorWorkoutType(
    id: 'yoga',
    title: 'Yoga',
    met: 3.0,
    icon: Icons.self_improvement,
  ),
  IndoorWorkoutType(
    id: 'gym',
    title: 'Gym',
    met: 6.0,
    icon: Icons.fitness_center,
  ),
  IndoorWorkoutType(
    id: 'dance',
    title: 'Khiêu vũ',
    met: 4.8,
    icon: Icons.music_note,
  ),
  IndoorWorkoutType(
    id: 'calisthenics',
    title: 'Calisthenics',
    met: 8.0,
    icon: Icons.sports_martial_arts,
  ),
  IndoorWorkoutType(
    id: 'boxing',
    title: 'Boxing',
    met: 12.0,
    icon: Icons.sports_kabaddi,
  ),
  IndoorWorkoutType(
    id: 'rope',
    title: 'Nhảy dây',
    met: 10.0,
    icon: Icons.sports,
  ),
];

const outdoorWorkoutTypes = [
  {
    'id': 'running',
    'title': 'Chạy bộ',
    'icon': Icons.directions_run,
  },
  {
    'id': 'walking',
    'title': 'Đi bộ',
    'icon': Icons.directions_walk,
  },
  {
    'id': 'cycling',
    'title': 'Đạp xe',
    'icon': Icons.pedal_bike,
  },
];

