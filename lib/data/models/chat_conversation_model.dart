import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_conversation.dart';
import 'chat_message_model.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.messages,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatConversationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final messages = (data['messages'] as List<dynamic>? ?? [])
        .map((msg) => ChatMessageModel.fromMap(msg as Map<String, dynamic>))
        .toList();

    return ChatConversationModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String? ?? 'Cuộc trò chuyện',
      messages: messages,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'messages': messages
          .map((msg) => ChatMessageModel(
                role: msg.role,
                content: msg.content,
                timestamp: msg.timestamp,
              ).toMap())
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

