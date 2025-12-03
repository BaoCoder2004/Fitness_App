import 'chat_message.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title; // Tiêu đề cuộc hội thoại (có thể là câu hỏi đầu tiên)
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
}

