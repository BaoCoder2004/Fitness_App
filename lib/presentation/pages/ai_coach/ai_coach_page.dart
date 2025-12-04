import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_coach_service.dart';
import '../../../core/services/data_analyzer.dart';
import '../../../core/services/data_summarizer.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/ai_insight_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/gps_route_repository.dart';
import '../../../domain/repositories/user_profile_repository.dart';
import '../../../domain/repositories/weight_history_repository.dart';
import '../../../presentation/viewmodels/chat_view_model.dart';
import '../../../presentation/viewmodels/insights_view_model.dart';
import 'chat_tab.dart';
import 'insights_tab.dart';

class AICoachPage extends StatelessWidget {
  const AICoachPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final chatRepository = context.read<ChatRepository>();
    final geminiService = context.read<GeminiService>();

    final currentUser = authRepository.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = currentUser.uid;

    // Get required services and repositories
    final weightHistoryRepository = context.read<WeightHistoryRepository>();
    final activityRepository = context.read<ActivityRepository>();
    final gpsRouteRepository = context.read<GpsRouteRepository>();
    final goalRepository = context.read<GoalRepository>();
    final userProfileRepository = context.read<UserProfileRepository>();
    final aiInsightRepository = context.read<AIInsightRepository>();
    final notificationService = context.read<NotificationService>();

    // Create services
    final dataAnalyzer = DataAnalyzer(
      weightHistoryRepository: weightHistoryRepository,
      activityRepository: activityRepository,
      gpsRouteRepository: gpsRouteRepository,
      goalRepository: goalRepository,
    );

    final dataSummarizer = DataSummarizer(
      dataAnalyzer: dataAnalyzer,
      userProfileRepository: userProfileRepository,
      goalRepository: goalRepository,
    );

    final aiCoachService = AICoachService(
      dataAnalyzer: dataAnalyzer,
      dataSummarizer: dataSummarizer,
      geminiService: geminiService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            chatRepository: chatRepository,
            geminiService: geminiService,
            userId: userId,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InsightsViewModel(
            aiCoachService: aiCoachService,
            insightRepository: aiInsightRepository,
            userId: userId,
            notificationService: notificationService,
          ),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('AI Coach'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Chat với AI'),
                Tab(text: 'AI Insights'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ChatTab(),
              InsightsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
