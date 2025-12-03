import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.role,
    required super.content,
    required super.timestamp,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      role: ChatRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => ChatRole.user,
      ),
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

