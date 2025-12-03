import '../entities/chat_message.dart';
import '../entities/chat_conversation.dart';

abstract class ChatRepository {
  /// Lấy lịch sử chat hiện tại của user (cho backward compatibility)
  Future<List<ChatMessage>> getChatHistory(String userId);

  /// Lấy danh sách tất cả các cuộc hội thoại
  Future<List<ChatConversation>> getAllConversations(String userId);

  /// Lấy một cuộc hội thoại theo ID
  Future<ChatConversation?> getConversation({
    required String userId,
    required String conversationId,
  });

  /// Stream lịch sử chat để cập nhật real-time
  Stream<List<ChatMessage>> watchChatHistory(String userId);

  /// Lưu một message vào cuộc hội thoại
  Future<void> saveMessage({
    required String userId,
    required String? conversationId, // null = tạo mới
    required ChatMessage message,
  });

  /// Lưu nhiều messages cùng lúc (khi sync)
  Future<void> saveMessages({
    required String userId,
    required String? conversationId,
    required List<ChatMessage> messages,
  });

  /// Xóa một cuộc hội thoại
  Future<void> deleteConversation({
    required String userId,
    required String conversationId,
  });

  /// Xóa toàn bộ lịch sử chat (cho backward compatibility)
  Future<void> clearChatHistory(String userId);
}

