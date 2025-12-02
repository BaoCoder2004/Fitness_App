import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../domain/entities/gps_route.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/gps_route_repository.dart';
import 'activity_detail_page.dart';

class GpsRoutesTab extends StatefulWidget {
  const GpsRoutesTab({super.key});

  @override
  State<GpsRoutesTab> createState() => _GpsRoutesTabState();
}

class _GpsRoutesTabState extends State<GpsRoutesTab> {
  String _selectedActivityType = 'all';
  String _selectedRange = 'all'; // all, 7d, 30d

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    final user = authRepo.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Vui lòng đăng nhập để xem lộ trình GPS.'),
      );
    }

    final gpsRepo = context.watch<GpsRouteRepository>();
    final activityRepo = context.watch<ActivityRepository>();

    return StreamBuilder<List<GpsRoute>>(
      stream: gpsRepo.watchRoutes(userId: user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Không thể tải GPS Routes.\n${snapshot.error}'),
          );
        }
        final routes = snapshot.data ?? const [];
        print('GPS Routes tab: Loaded ${routes.length} routes from Firestore');

        return FutureBuilder<List<_RouteWithSession>>(
          future: _loadRoutesWithSessions(
            activityRepo: activityRepo,
            userId: user.uid,
            routes: routes,
          ),
          builder: (context, routesSnapshot) {
            if (routesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (routesSnapshot.hasError) {
              return Center(
                child: Text('Không thể tải buổi tập tương ứng.\n${routesSnapshot.error}'),
              );
            }
            final allRouteSessions = routesSnapshot.data ?? const [];
            if (allRouteSessions.isEmpty) {
              return const Center(
                child: Text('Chưa có lộ trình GPS hợp lệ.\nHãy bắt đầu một buổi tập ngoài trời!'),
              );
            }

            final filtered = _applyFilters(allRouteSessions);

            if (filtered.isEmpty) {
              return Column(
                children: [
                  _buildFilters(context),
                  const Expanded(
                    child: Center(
                      child: Text('Không có lộ trình phù hợp với bộ lọc hiện tại.'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildFilters(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _GpsRouteListItem(
                        route: item.route,
                        session: item.session,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_RouteWithSession> _applyFilters(List<_RouteWithSession> items) {
    final now = DateTime.now();
    DateTime? from;
    if (_selectedRange == '7d') {
      from = now.subtract(const Duration(days: 7));
    } else if (_selectedRange == '30d') {
      from = now.subtract(const Duration(days: 30));
    }

    return items.where((item) {
      // Chỉ giữ hoạt động outdoor dựa trên meta
      final meta = ActivityTypeHelper.resolve(item.session.activityType);
      if (!meta.isOutdoor) return false;

      if (from != null && item.session.date.isBefore(from)) {
        return false;
      }

      if (_selectedActivityType != 'all' &&
          item.session.activityType != _selectedActivityType) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _selectedRange == 'all',
                onSelected: (_) {
                  setState(() => _selectedRange = 'all');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('7 ngày'),
                selected: _selectedRange == '7d',
                onSelected: (_) {
                  setState(() => _selectedRange = '7d');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('30 ngày'),
                selected: _selectedRange == '30d',
                onSelected: (_) {
                  setState(() => _selectedRange = '30d');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityType,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả hoạt động'),
                  ),
                  DropdownMenuItem(
                    value: 'walking',
                    child: Text('Đi bộ'),
                  ),
                  DropdownMenuItem(
                    value: 'running',
                    child: Text('Chạy bộ'),
                  ),
                  DropdownMenuItem(
                    value: 'cycling',
                    child: Text('Đạp xe'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedActivityType = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsRouteListItem extends StatelessWidget {
  const _GpsRouteListItem({required this.route, required this.session});

  final GpsRoute route;
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final sessionDurationSeconds = session.durationSeconds;
    final sessionDistanceKm = session.distanceKm;
    final durationSeconds = sessionDurationSeconds > 0
        ? sessionDurationSeconds
        : route.totalDurationSeconds;
    final duration = Duration(seconds: durationSeconds);
    final durationStr =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';

    final distanceKm = sessionDistanceKm != null && sessionDistanceKm > 0
        ? sessionDistanceKm
        : route.totalDistanceKm;

    String? paceStr;
    if (distanceKm > 0 && durationSeconds > 0) {
      final paceMinutes = (durationSeconds / 60.0) / distanceKm;
      final paceMin = paceMinutes.floor();
      final paceSec = ((paceMinutes - paceMin) * 60).round();
      paceStr =
          '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')} /km';
    }

    final activityMeta =
        ActivityTypeHelper.resolve(session.activityType);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActivityDetailPage(
                session: session,
                routeOverride: route,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: _GpsRoutePreviewMap(route: route),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    df.format(session.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityMeta.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          label: 'Quãng đường',
                          value: '${distanceKm.toStringAsFixed(2)} km',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoChip(
                          label: 'Thời gian',
                          value: durationStr,
                        ),
                      ),
                      if (paceStr != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            label: 'Pace TB',
                            value: paceStr,
                          ),
                        ),
                      ],
                    ],
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

class _GpsRoutePreviewMap extends StatelessWidget {
  const _GpsRoutePreviewMap({required this.route});

  final GpsRoute route;

  @override
  Widget build(BuildContext context) {
    if (route.segments.isEmpty || route.startPoint == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: Text(
          'Không có dữ liệu GPS.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final center = LatLng(
      route.startPoint!.lat,
      route.startPoint!.lng,
    );

    final polylines = <Polyline>[];
    for (final segment in route.segments) {
      if (segment.points.length < 2) continue;
      polylines.add(
        Polyline(
          points: segment.points
              .map((p) => LatLng(p.lat, p.lng))
              .toList(growable: false),
          strokeWidth: 3,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final markers = <Marker>[];
    final start = route.startPoint;
    final end = route.endPoint;
    if (start != null) {
      markers.add(
        Marker(
          width: 32,
          height: 32,
          point: LatLng(start.lat, start.lng),
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 26,
          ),
        ),
      );
    }
    if (end != null) {
      markers.add(
        Marker(
          width: 32,
          height: 32,
          point: LatLng(end.lat, end.lng),
          child: const Icon(
            Icons.flag,
            color: Colors.green,
            size: 24,
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.fitness_app',
        ),
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: polylines,
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RouteWithSession {
  const _RouteWithSession({required this.route, required this.session});

  final GpsRoute route;
  final ActivitySession session;
}

Future<List<_RouteWithSession>> _loadRoutesWithSessions({
  required ActivityRepository activityRepo,
  required String userId,
  required List<GpsRoute> routes,
}) async {
  print('_loadRoutesWithSessions: Processing ${routes.length} routes');
  final validRoutes = routes.where((route) => route.activityId.isNotEmpty).toList();
  print('_loadRoutesWithSessions: ${validRoutes.length} routes with activityId');
  if (validRoutes.isEmpty) {
    print('_loadRoutesWithSessions: No valid routes, returning empty list');
    return [];
  }

  final futures = validRoutes.map((route) async {
    try {
      // Try to get activity by ID first
      ActivitySession? session;
      try {
        session = await activityRepo.getActivityById(
          oderId: route.userId.isNotEmpty ? route.userId : userId,
          sessionId: route.activityId,
        );
      } catch (e) {
        // If activityId is offline ID or not found, try to find by date
        print('Could not find activity by ID ${route.activityId}, trying by date: $e');
        if (route.segments.isNotEmpty) {
          final routeDate = route.segments.first.startTime;
          final startOfDay = DateTime(routeDate.year, routeDate.month, routeDate.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          
          try {
            final activitiesInRange = await activityRepo.getActivitiesInRange(
              userId: route.userId.isNotEmpty ? route.userId : userId,
              start: startOfDay,
              end: endOfDay,
            );
            // Find activity with matching date and similar metrics
            // Tìm activity gần nhất về thời gian với routeDate (không dùng firstWhere)
            ActivitySession? bestMatch;
            Duration? bestTimeDiff;
            
            for (final a in activitiesInRange) {
              // Match by date (same day)
              final sameDay = a.date.year == routeDate.year &&
                  a.date.month == routeDate.month &&
                  a.date.day == routeDate.day;
              if (!sameDay) continue;
              
              // Match by duration (within 10 seconds)
              if (route.totalDurationSeconds > 0) {
                final durationDiff = (a.durationSeconds - route.totalDurationSeconds).abs();
                if (durationDiff > 10) continue;
              }
              
              // Match by distance (within 0.05 km)
              if (a.distanceKm != null && route.totalDistanceKm > 0) {
                final distanceDiff = (a.distanceKm! - route.totalDistanceKm).abs();
                if (distanceDiff > 0.05) continue;
              }
              
              // Tính thời gian chênh lệch giữa routeDate và activity date
              final timeDiff = (a.date.difference(routeDate)).abs();
              
              // Chọn activity có thời gian gần nhất
              if (bestMatch == null || bestTimeDiff == null || timeDiff < bestTimeDiff) {
                bestMatch = a;
                bestTimeDiff = timeDiff;
              }
            }
            
            if (bestMatch != null) {
              print('Matched GPS route ${route.id} with activity ${bestMatch.id}: routeDate=$routeDate, activityDate=${bestMatch.date}, activityType=${bestMatch.activityType}, timeDiff=${bestTimeDiff?.inSeconds}s');
            } else {
              print('No matching activity found for GPS route ${route.id} with activityId ${route.activityId}: routeDate=$routeDate, duration=${route.totalDurationSeconds}s, distance=${route.totalDistanceKm}km');
            }
            
            session = bestMatch;
          } catch (e2) {
            print('Could not find activity by date: $e2');
          }
        }
      }
      
      if (session == null) {
        print('No matching activity found for GPS route ${route.id} with activityId ${route.activityId}');
        return null;
      }
      
      // Debug: Log matched activity
      print('Matched GPS route ${route.id} with activity ${session.id}: routeDate=${route.segments.isNotEmpty ? route.segments.first.startTime : "N/A"}, activityDate=${session.date}');
      
      return _RouteWithSession(route: route, session: session);
    } catch (e) {
      print('Error loading route with session: $e');
      return null;
    }
  }).toList();

  final results = await Future.wait(futures);
  final validResults = results.whereType<_RouteWithSession>().toList();

  // Deduplicate theo activity (mỗi activity chỉ nên có 1 GPS route)
  final deduped = <String, _RouteWithSession>{};
  for (final item in validResults) {
    final existing = deduped[item.session.id];
    if (existing == null) {
      deduped[item.session.id] = item;
    } else {
      final existingDate = existing.route.createdAt;
      final newDate = item.route.createdAt;
      if (newDate.isAfter(existingDate)) {
        deduped[item.session.id] = item;
      }
    }
  }

  final dedupedList = deduped.values.toList()
    ..sort((a, b) => b.session.date.compareTo(a.session.date));

  print('_loadRoutesWithSessions: Matched ${dedupedList.length} unique routes with activities');
  return dedupedList;
}


