/// Loại insight
enum InsightType {
  weight,
  activity,
  goal,
  gps,
  general,
}

/// Gợi ý từ AI
class Suggestion {
  const Suggestion({
    required this.type,
    required this.title,
    required this.description,
    this.actionable = false,
  });

  final String type;
  final String title;
  final String description;
  final bool actionable; // Có thể áp dụng ngay không
}

/// Entity AI Insight
class AIInsight {
  const AIInsight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.content,
    required this.analysis,
    required this.suggestions,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final InsightType insightType;
  final String title;
  final String content; // Phân tích chi tiết
  final Map<String, dynamic> analysis; // Dữ liệu phân tích
  final List<Suggestion> suggestions;
  final DateTime createdAt;
}

