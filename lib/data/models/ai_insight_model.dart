import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ai_insight.dart';

/// Model để convert AIInsight entity với Firestore
class AIInsightModel {
  AIInsightModel({
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
  final String content;
  final Map<String, dynamic> analysis;
  final List<Suggestion> suggestions;
  final DateTime createdAt;

  /// Tạo từ Firestore document
  factory AIInsightModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AIInsightModel(
      id: doc.id,
      userId: data['userId'] as String,
      insightType: _parseInsightType(data['insightType'] as String),
      title: data['title'] as String,
      content: data['content'] as String,
      analysis: Map<String, dynamic>.from(data['analysis'] as Map? ?? {}),
      suggestions: (data['suggestions'] as List<dynamic>?)
              ?.map((s) => Suggestion(
                    type: s['type'] as String? ?? 'other',
                    title: s['title'] as String? ?? '',
                    description: s['description'] as String? ?? '',
                    actionable: s['actionable'] as bool? ?? false,
                  ))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert sang Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'insightType': _insightTypeToString(insightType),
      'title': title,
      'content': content,
      'analysis': analysis,
      'suggestions': suggestions.map((s) => {
            'type': s.type,
            'title': s.title,
            'description': s.description,
            'actionable': s.actionable,
          }).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert sang entity
  AIInsight toEntity() {
    return AIInsight(
      id: id,
      userId: userId,
      insightType: insightType,
      title: title,
      content: content,
      analysis: analysis,
      suggestions: suggestions,
      createdAt: createdAt,
    );
  }

  /// Tạo từ entity
  factory AIInsightModel.fromEntity(AIInsight entity) {
    return AIInsightModel(
      id: entity.id,
      userId: entity.userId,
      insightType: entity.insightType,
      title: entity.title,
      content: entity.content,
      analysis: entity.analysis,
      suggestions: entity.suggestions,
      createdAt: entity.createdAt,
    );
  }

  static InsightType _parseInsightType(String type) {
    switch (type) {
      case 'weight':
        return InsightType.weight;
      case 'activity':
        return InsightType.activity;
      case 'goal':
        return InsightType.goal;
      case 'gps':
        return InsightType.gps;
      case 'general':
      default:
        return InsightType.general;
    }
  }

  static String _insightTypeToString(InsightType type) {
    switch (type) {
      case InsightType.weight:
        return 'weight';
      case InsightType.activity:
        return 'activity';
      case InsightType.goal:
        return 'goal';
      case InsightType.gps:
        return 'gps';
      case InsightType.general:
        return 'general';
    }
  }
}

