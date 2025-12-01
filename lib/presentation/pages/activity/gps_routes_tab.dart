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
    final duration = Duration(seconds: route.totalDurationSeconds);
    final durationStr =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';

    String? paceStr;
    if (route.totalDistanceKm > 0 && route.totalDurationSeconds > 0) {
      final paceMinutes =
          (route.totalDurationSeconds / 60.0) / route.totalDistanceKm;
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
                          value: '${route.totalDistanceKm.toStringAsFixed(2)} km',
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
  final validRoutes = routes.where((route) => route.activityId.isNotEmpty).toList();
  if (validRoutes.isEmpty) return [];

  final futures = validRoutes.map((route) async {
    try {
      final session = await activityRepo.getActivityById(
        oderId: route.userId.isNotEmpty ? route.userId : userId,
        sessionId: route.activityId,
      );
      if (session == null) return null;
      return _RouteWithSession(route: route, session: session);
    } catch (_) {
      return null;
    }
  }).toList();

  final results = await Future.wait(futures);
  return results.whereType<_RouteWithSession>().toList();
}


