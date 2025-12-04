import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_insight.dart';
import 'data_analyzer.dart';
import 'data_summarizer.dart';
import 'gemini_service.dart';

/// Service AI Coach - Phân tích dữ liệu và đưa ra gợi ý
class AICoachService {
  AICoachService({
    required DataAnalyzer dataAnalyzer,
    required DataSummarizer dataSummarizer,
    required GeminiService geminiService,
  })  : _dataAnalyzer = dataAnalyzer,
        _dataSummarizer = dataSummarizer,
        _geminiService = geminiService;

  final DataAnalyzer _dataAnalyzer;
  final DataSummarizer _dataSummarizer;
  final GeminiService _geminiService;

  /// System prompt cho AI Coach
  static const String _systemPrompt = '''
Bạn là một AI fitness coach chuyên nghiệp. Nhiệm vụ của bạn là phân tích dữ liệu sức khỏe và tập luyện của người dùng, sau đó đưa ra các gợi ý cá nhân hóa để giúp họ đạt được mục tiêu.

Hãy trả lời bằng tiếng Việt, thân thiện và dễ hiểu. Đưa ra các gợi ý cụ thể, có thể thực hiện được.

Khi phân tích, hãy:
1. Nhận diện xu hướng (tăng/giảm/ổn định)
2. Phát hiện các vấn đề cần chú ý (không đạt mục tiêu, streak bị gián đoạn, v.v.)
3. Đưa ra 3-5 gợi ý cụ thể để cải thiện

Format response của bạn phải theo JSON:
{
  "title": "Tiêu đề insight (ngắn gọn, dễ hiểu)",
  "content": "Phân tích chi tiết (2-3 đoạn văn)",
  "trend": "increasing" | "decreasing" | "stable",
  "issues": ["vấn đề 1", "vấn đề 2"],
  "suggestions": [
    {
      "type": "nutrition" | "exercise" | "goal" | "habit" | "other",
      "title": "Tiêu đề gợi ý",
      "description": "Mô tả chi tiết gợi ý",
      "actionable": true/false
    }
  ]
}
''';

  /// Phân tích và đưa ra gợi ý tổng quát
  Future<AIInsight> analyzeAndSuggest(
    String userId, {
    int days = 30,
    InsightType? focusType,
  }) async {
    if (!_geminiService.isInitialized) {
      throw Exception(
        'GeminiService chưa được khởi tạo. '
        'Vui lòng kiểm tra GEMINI_API_KEY trong file .env',
      );
    }

    try {
      // 1. Tổng hợp dữ liệu
      final userDataSummary = await _dataSummarizer.summarizeUserData(
        userId,
        days: days,
      );

      // 2. Tạo prompt cho AI
      String prompt = '''
Dựa trên dữ liệu sau của người dùng:

$userDataSummary

Hãy phân tích và đưa ra:
1. Xu hướng hiện tại (tăng/giảm/ổn định)
2. Các vấn đề cần chú ý
3. Gợi ý cụ thể để cải thiện

${focusType != null ? 'Tập trung vào: ${_translateInsightType(focusType)}' : ''}

Trả lời bằng JSON format như đã hướng dẫn.
''';

      // 3. Gọi Gemini API
      final response = await _geminiService.sendMessage(
        prompt: prompt,
        model: GeminiModel.flash, // Dùng Flash để tiết kiệm chi phí và nhanh hơn
        systemPrompt: _systemPrompt,
      );

      // 4. Parse response
      final insight = _parseAIResponse(
        response,
        focusType ?? InsightType.general,
        userId,
      );

      return insight;
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi phân tích AI: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Nếu lỗi do thiếu dữ liệu, trả về insight thông báo
      if (e.toString().contains('Không có dữ liệu') || 
          e.toString().contains('Không đủ dữ liệu')) {
        return AIInsight(
          id: '',
          userId: userId,
          insightType: focusType ?? InsightType.general,
          title: 'Chưa có đủ dữ liệu',
          content: 'Bạn cần thêm dữ liệu về ${focusType != null ? _translateInsightType(focusType).toLowerCase() : "hoạt động"} để AI có thể phân tích và đưa ra gợi ý.',
          analysis: {},
          suggestions: [],
          createdAt: DateTime.now(),
        );
      }
      
      rethrow;
    }
  }

  /// Phân tích xu hướng cân nặng và đưa ra gợi ý
  Future<AIInsight> analyzeWeightTrend(String userId, {int days = 30}) async {
    try {
      final weightAnalysis = await _dataAnalyzer.analyzeWeightTrend(userId, days);
      final userDataSummary = await _dataSummarizer.summarizeUserData(
        userId,
        days: days,
      );

      String prompt = '''
Dựa trên phân tích cân nặng sau:

Xu hướng: ${_translateTrend(weightAnalysis.trend)}
Cân nặng hiện tại: ${weightAnalysis.currentWeight.toStringAsFixed(1)} kg
${weightAnalysis.weightChange != null ? 'Thay đổi: ${weightAnalysis.weightChange!.toStringAsFixed(1)} kg' : ''}
${weightAnalysis.targetWeight != null ? 'Mục tiêu: ${weightAnalysis.targetWeight!.toStringAsFixed(1)} kg' : ''}

$userDataSummary

Hãy phân tích xu hướng cân nặng và đưa ra gợi ý cụ thể về dinh dưỡng và tập luyện.

Trả lời bằng JSON format như đã hướng dẫn.
''';

      final response = await _geminiService.sendMessage(
        prompt: prompt,
        model: GeminiModel.flash,
        systemPrompt: _systemPrompt,
      );

      final analysis = {
        'trend': weightAnalysis.trend,
        'currentValue': weightAnalysis.currentWeight,
        'targetValue': weightAnalysis.targetWeight,
        'weightChange': weightAnalysis.weightChange,
        'weightChangePerWeek': weightAnalysis.weightChangePerWeek,
        'isOnTrack': weightAnalysis.isOnTrack,
      };

      return _parseAIResponse(
        response,
        InsightType.weight,
        userId,
        analysis: analysis,
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi phân tích cân nặng: $e');
      
      // Nếu không có dữ liệu cân nặng, trả về insight thông báo
      if (e.toString().contains('Không có dữ liệu cân nặng')) {
        return AIInsight(
          id: '',
          userId: userId,
          insightType: InsightType.weight,
          title: 'Chưa có dữ liệu cân nặng',
          content: 'Bạn chưa có dữ liệu cân nặng trong hệ thống. Hãy thêm cân nặng của bạn để AI có thể phân tích và đưa ra gợi ý về xu hướng cân nặng.',
          analysis: {
            'trend': 'no_data',
            'issues': ['missing_weight_data'],
          },
          suggestions: [
            const Suggestion(
              type: 'data',
              title: 'Thêm cân nặng',
              description: 'Hãy vào phần Hồ sơ và thêm cân nặng hiện tại của bạn để bắt đầu theo dõi.',
              actionable: true,
            ),
          ],
          createdAt: DateTime.now(),
        );
      }
      
      rethrow;
    }
  }

  /// Phân tích mức độ hoạt động và đưa ra gợi ý
  Future<AIInsight> analyzeActivityLevel(String userId, {int days = 30}) async {
    try {
      final activityAnalysis =
          await _dataAnalyzer.analyzeActivityLevel(userId, days);
      final userDataSummary = await _dataSummarizer.summarizeUserData(
        userId,
        days: days,
      );

      String prompt = '''
Dựa trên phân tích hoạt động sau:

Tổng số buổi tập: ${activityAnalysis.totalSessions}
Tần suất: ${activityAnalysis.sessionsPerWeek.toStringAsFixed(1)} buổi/tuần
Tổng calories: ${activityAnalysis.totalCalories.toStringAsFixed(0)} kcal
${activityAnalysis.activityChange != null ? 'Thay đổi so với tuần trước: ${activityAnalysis.activityChange!.toStringAsFixed(1)}%' : ''}

$userDataSummary

Hãy phân tích mức độ hoạt động và đưa ra gợi ý để cải thiện.

Trả lời bằng JSON format như đã hướng dẫn.
''';

      final response = await _geminiService.sendMessage(
        prompt: prompt,
        model: GeminiModel.flash,
        systemPrompt: _systemPrompt,
      );

      final analysis = {
        'totalSessions': activityAnalysis.totalSessions,
        'sessionsPerWeek': activityAnalysis.sessionsPerWeek,
        'totalCalories': activityAnalysis.totalCalories,
        'activityChange': activityAnalysis.activityChange,
      };

      return _parseAIResponse(
        response,
        InsightType.activity,
        userId,
        analysis: analysis,
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi phân tích hoạt động: $e');
      
      // Nếu không có dữ liệu hoạt động, trả về insight thông báo
      if (e.toString().contains('Không có dữ liệu') || 
          e.toString().contains('empty')) {
        return AIInsight(
          id: '',
          userId: userId,
          insightType: InsightType.activity,
          title: 'Chưa có dữ liệu hoạt động',
          content: 'Bạn chưa có dữ liệu hoạt động trong hệ thống. Hãy thêm các buổi tập luyện để AI có thể phân tích và đưa ra gợi ý.',
          analysis: {
            'trend': 'no_data',
            'issues': ['missing_activity_data'],
          },
          suggestions: [
            const Suggestion(
              type: 'data',
              title: 'Thêm buổi tập',
              description: 'Hãy vào phần Hoạt động và thêm các buổi tập luyện của bạn để bắt đầu theo dõi.',
              actionable: true,
            ),
          ],
          createdAt: DateTime.now(),
        );
      }
      
      rethrow;
    }
  }

  /// Parse response từ AI thành AIInsight
  AIInsight _parseAIResponse(
    String response,
    InsightType insightType,
    String userId, {
    Map<String, dynamic>? analysis,
  }) {
    try {
      // Tìm JSON trong response (có thể có text trước/sau JSON)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('Không tìm thấy JSON trong response');
      }

      final jsonString = response.substring(jsonStart, jsonEnd);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final title = json['title'] as String? ?? 'Phân tích từ AI';
      final content = json['content'] as String? ?? response;
      final trend = json['trend'] as String? ?? 'stable';
      final issues = (json['issues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final suggestionsJson = json['suggestions'] as List<dynamic>? ?? [];
      final suggestions = suggestionsJson.map((s) {
        final sMap = s as Map<String, dynamic>;
        return Suggestion(
          type: sMap['type'] as String? ?? 'other',
          title: sMap['title'] as String? ?? '',
          description: sMap['description'] as String? ?? '',
          actionable: sMap['actionable'] as bool? ?? false,
        );
      }).toList();

      final finalAnalysis = {
        'trend': trend,
        'issues': issues,
        if (analysis != null) ...analysis,
      };

      return AIInsight(
        id: '', // Sẽ được set khi lưu vào Firestore
        userId: userId,
        insightType: insightType,
        title: title,
        content: content,
        analysis: finalAnalysis,
        suggestions: suggestions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi parse AI response: $e');
      // Fallback: Trả về insight đơn giản từ response text
      return AIInsight(
        id: '',
        userId: userId,
        insightType: insightType,
        title: 'Phân tích từ AI',
        content: response,
        analysis: analysis ?? {},
        suggestions: [],
        createdAt: DateTime.now(),
      );
    }
  }

  String _translateTrend(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Đang tăng';
      case 'decreasing':
        return 'Đang giảm';
      case 'stable':
        return 'Ổn định';
      default:
        return trend;
    }
  }

  String _translateInsightType(InsightType type) {
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
}

