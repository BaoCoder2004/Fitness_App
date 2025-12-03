import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../core/services/gemini_service.dart';
import '../../../presentation/viewmodels/chat_view_model.dart';
import 'chat_tab.dart';

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

    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        chatRepository: chatRepository,
        geminiService: geminiService,
        userId: userId,
      ),
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
              _AIInsightsPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder cho Tab AI Insights (sẽ implement trong Plan 6)
class _AIInsightsPlaceholder extends StatelessWidget {
  const _AIInsightsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'AI Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Tính năng đang được phát triển'),
        ],
      ),
    );
  }
}
