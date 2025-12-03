import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _conversationsCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('chat_history');

  DocumentReference<Map<String, dynamic>> _conversationDoc(
    String userId,
    String conversationId,
  ) =>
      _conversationsCollection(userId).doc(conversationId);

  // Backward compatibility: document 'current'
  DocumentReference<Map<String, dynamic>> _chatDoc(String userId) =>
      _conversationsCollection(userId).doc('current');

  @override
  Future<List<ChatMessage>> getChatHistory(String userId) async {
    final doc = await _chatDoc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return [];
    }

    final data = doc.data()!;
    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages
        .map((msg) => ChatMessageModel.fromMap(msg as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<ChatMessage>> watchChatHistory(String userId) {
    return _chatDoc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return <ChatMessage>[];
      }

      final data = doc.data()!;
      final messages = data['messages'] as List<dynamic>? ?? [];
      return messages
          .map((msg) => ChatMessageModel.fromMap(msg as Map<String, dynamic>))
          .toList();
    });
  }


  @override
  Future<List<ChatConversation>> getAllConversations(String userId) async {
    final snapshot = await _conversationsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ChatConversationModel.fromDoc(doc))
        .toList();
  }

  @override
  Future<ChatConversation?> getConversation({
    required String userId,
    required String conversationId,
  }) async {
    final doc = await _conversationDoc(userId, conversationId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return ChatConversationModel.fromDoc(doc);
  }

  @override
  Future<void> saveMessage({
    required String userId,
    required String? conversationId,
    required ChatMessage message,
  }) async {
    final messageMap = ChatMessageModel(
      role: message.role,
      content: message.content,
      timestamp: message.timestamp,
    ).toMap();

    if (conversationId == null) {
      // Tạo cuộc hội thoại mới
      final title = message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content;
      final newDocRef = _conversationsCollection(userId).doc();
      
      await newDocRef.set({
        'userId': userId,
        'title': title,
        'messages': [messageMap],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Thêm vào cuộc hội thoại hiện có
      final conversationDoc = _conversationDoc(userId, conversationId);
      final doc = await conversationDoc.get();
      
      if (doc.exists && doc.data() != null) {
        final existingMessages = (doc.data()!['messages'] as List<dynamic>? ?? []);
        await conversationDoc.update({
          'messages': FieldValue.arrayUnion([messageMap]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Nếu không tồn tại, tạo mới
        final title = message.content.length > 50
            ? '${message.content.substring(0, 50)}...'
            : message.content;
        await conversationDoc.set({
          'userId': userId,
          'title': title,
          'messages': [messageMap],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Future<void> saveMessages({
    required String userId,
    required String? conversationId,
    required List<ChatMessage> messages,
  }) async {
    final messagesList = messages
        .map((msg) => ChatMessageModel(
              role: msg.role,
              content: msg.content,
              timestamp: msg.timestamp,
            ).toMap())
        .toList();

    if (conversationId == null) {
      // Tạo cuộc hội thoại mới
      final title = messages.isNotEmpty && messages.first.role == ChatRole.user
          ? (messages.first.content.length > 50
              ? '${messages.first.content.substring(0, 50)}...'
              : messages.first.content)
          : 'Cuộc trò chuyện';
      final newDocRef = _conversationsCollection(userId).doc();
      
      await newDocRef.set({
        'userId': userId,
        'title': title,
        'messages': messagesList,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Cập nhật cuộc hội thoại hiện có
      final conversationDoc = _conversationDoc(userId, conversationId);
      await conversationDoc.set({
        'userId': userId,
        'messages': messagesList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteConversation({
    required String userId,
    required String conversationId,
  }) async {
    await _conversationDoc(userId, conversationId).delete();
  }

  @override
  Future<void> clearChatHistory(String userId) async {
    // Xóa tất cả cuộc hội thoại
    final snapshot = await _conversationsCollection(userId).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

