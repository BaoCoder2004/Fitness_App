import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_activity_repository.dart';
import 'data/repositories/firestore_goal_repository.dart';
import 'data/repositories/firestore_gps_route_repository.dart';
import 'data/repositories/firestore_streak_repository.dart';
import 'data/repositories/firestore_user_profile_repository.dart';
import 'data/repositories/firestore_weight_history_repository.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/viewmodels/auth_view_model.dart';
import 'presentation/viewmodels/dashboard_view_model.dart';
import 'presentation/viewmodels/user_profile_view_model.dart';
import 'domain/repositories/activity_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/goal_repository.dart';
import 'domain/repositories/streak_repository.dart';
import 'domain/repositories/gps_route_repository.dart';
import 'domain/repositories/user_profile_repository.dart';
import 'domain/repositories/weight_history_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final notificationService =
      NotificationService(FlutterLocalNotificationsPlugin());
  await notificationService.init();
  
  // Initialize sync service
  final syncService = SyncService();
  await syncService.init();
  
  // Initialize local storage service
  final localStorageService = LocalStorageService();
  
  runApp(FitnessApp(
    notificationService: notificationService,
    syncService: syncService,
    localStorageService: localStorageService,
  ));
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({
    super.key,
    required this.notificationService,
    required this.syncService,
    required this.localStorageService,
  });

  final NotificationService notificationService;
  final SyncService syncService;
  final LocalStorageService localStorageService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(
          value: notificationService,
        ),
        Provider<AuthRepository>(
          create: (_) => FirebaseAuthRepository(),
        ),
        Provider<UserProfileRepository>(
          create: (_) => FirestoreUserProfileRepository(),
        ),
        Provider<WeightHistoryRepository>(
          create: (_) => FirestoreWeightHistoryRepository(),
        ),
        Provider<SyncService>.value(
          value: syncService,
        ),
        Provider<LocalStorageService>.value(
          value: localStorageService,
        ),
        Provider<ActivityRepository>(
          create: (context) {
            final repo = FirestoreActivityRepository(
              syncService: syncService,
              localStorageService: localStorageService,
            );
            repo.registerSyncHandler(syncService);
            return repo;
          },
        ),
        Provider<StreakRepository>(
          create: (_) => FirestoreStreakRepository(),
        ),
        Provider<GoalRepository>(
          create: (context) {
            final repo = FirestoreGoalRepository(
              syncService: syncService,
              localStorageService: localStorageService,
            );
            repo.registerSyncHandler(syncService);
            return repo;
          },
        ),
        Provider<GpsRouteRepository>(
          create: (context) {
            final repo = FirestoreGpsRouteRepository(
              syncService: syncService,
              localStorageService: localStorageService,
            );
            repo.registerSyncHandler(syncService);
            return repo;
          },
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
            userProfileRepository: context.read<UserProfileRepository>(),
          ),
        ),
        ChangeNotifierProvider<UserProfileViewModel>(
          create: (context) => UserProfileViewModel(
            authRepository: context.read<AuthRepository>(),
            userProfileRepository: context.read<UserProfileRepository>(),
            weightHistoryRepository: context.read<WeightHistoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            authRepository: context.read<AuthRepository>(),
            userProfileRepository: context.read<UserProfileRepository>(),
            activityRepository: context.read<ActivityRepository>(),
          )..load(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ứng dụng Fitness',
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
