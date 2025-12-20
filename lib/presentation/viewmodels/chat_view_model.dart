import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/services/gemini_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required ChatRepository chatRepository,
    required GeminiService geminiService,
    required String userId,
  })  : _chatRepository = chatRepository,
        _geminiService = geminiService,
        _userId = userId;

  final ChatRepository _chatRepository;
  final GeminiService _geminiService;
  final String _userId;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isTyping = false;
  String? _currentConversationId; // ID của cuộc hội thoại hiện tại

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTyping => _isTyping;
  String? get currentConversationId => _currentConversationId;

  /// Gợi ý câu hỏi thường gặp
  static const List<String> suggestedQuestions = [
    'Tôi nên ăn gì sau khi tập?',
    'Làm thế nào để tăng cơ bắp?',
    'Tôi cần bao nhiêu calo mỗi ngày?',
    'Bài tập nào tốt cho tim mạch?',
    'Cách giảm cân hiệu quả?',
    'Tôi nên nghỉ ngơi bao lâu giữa các buổi tập?',
  ];

  void init() {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load conversation mới nhất nếu có
      final conversations = await _chatRepository.getAllConversations(_userId);
      if (conversations.isNotEmpty) {
        final latest = conversations.first;
        _messages = latest.messages;
        _currentConversationId = latest.id;
      } else {
        _messages = [];
        _currentConversationId = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        _error = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else if (e.toString().contains('permission-denied')) {
        _error = 'Không có quyền xem lịch sử chat. Vui lòng đăng nhập lại.';
      } else {
        _error = 'Không thể tải lịch sử chat. Vui lòng thử lại sau.';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadCurrentConversation() async {
    try {
      final conversations = await _chatRepository.getAllConversations(_userId);
      if (conversations.isNotEmpty) {
        final latest = conversations.first;
        _currentConversationId = latest.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi khi reload conversation: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Thêm user message vào UI ngay
    _messages = [..._messages, userMessage];
    _error = null;
    notifyListeners();

    // Lưu user message (tạo conversation mới nếu chưa có)
    try {
      await _chatRepository.saveMessage(
        userId: _userId,
        conversationId: _currentConversationId,
        message: userMessage,
      );
      // Nếu là conversation mới, reload để lấy ID
      if (_currentConversationId == null) {
        await _reloadCurrentConversation();
      }
    } catch (e) {
      debugPrint('Lỗi khi lưu user message: $e');
    }

    // Gửi đến Gemini
    _isTyping = true;
    notifyListeners();

    try {
      // Kiểm tra xem GeminiService đã được khởi tạo chưa
      if (!_geminiService.isInitialized) {
        _isTyping = false;
        _error = 'Gemini API chưa được cấu hình. Vui lòng kiểm tra file .env và thêm GEMINI_API_KEY.';
        notifyListeners();
        return;
      }

      // Chuyển đổi chat history sang format của Gemini
      final chatHistory = _messages
          .where((msg) => msg != userMessage) // Bỏ message vừa thêm
          .map((msg) {
            if (msg.role == ChatRole.user) {
              return Content.text(msg.content);
            } else {
              return Content.model([TextPart(msg.content)]);
            }
          })
          .toList();

      // Gửi message đến Gemini
      final response = await _geminiService.sendMessage(
        prompt: text.trim(),
        chatHistory: chatHistory,
      );

      final assistantMessage = ChatMessage(
        role: ChatRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      );

      _messages = [..._messages, assistantMessage];
      _isTyping = false;
      _error = null;
      notifyListeners();

      // Lưu assistant message
      await _chatRepository.saveMessage(
        userId: _userId,
        conversationId: _currentConversationId,
        message: assistantMessage,
      );
    } catch (e, stack) {
      // Ghi log chi tiết để dễ debug (VD: lỗi mạng, lỗi rate limit, cấu hình API...)
      debugPrint('Lỗi khi gửi tin nhắn tới Gemini: $e');
      debugPrint('Stacktrace: $stack');

      _isTyping = false;
      // Kiểm tra loại lỗi cụ thể
      if (e.toString().contains('network') || e.toString().contains('Network') || e.toString().contains('SocketException')) {
        _error = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        _error = 'Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.';
      } else if (e.toString().contains('API') || e.toString().contains('api') || e.toString().contains('key')) {
        _error = 'Lỗi cấu hình AI. Vui lòng liên hệ hỗ trợ.';
      } else if (e.toString().contains('rate') || e.toString().contains('quota') || e.toString().contains('limit')) {
        _error = 'Đã vượt quá giới hạn yêu cầu. Vui lòng thử lại sau vài phút.';
      } else {
        _error = 'Không thể gửi tin nhắn. Vui lòng thử lại sau.';
      }
      notifyListeners();

      // Xóa user message nếu có lỗi (optional)
      // _messages.removeLast();
      // notifyListeners();
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _chatRepository.clearChatHistory(_userId);
      _messages = [];
      _currentConversationId = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        _error = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else if (e.toString().contains('permission-denied')) {
        _error = 'Không có quyền xóa lịch sử chat. Vui lòng đăng nhập lại.';
      } else {
        _error = 'Không thể xóa lịch sử chat. Vui lòng thử lại sau.';
      }
      notifyListeners();
    }
  }

  /// Load một cuộc hội thoại cụ thể
  Future<void> loadConversation(String conversationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final conversation = await _chatRepository.getConversation(
        userId: _userId,
        conversationId: conversationId,
      );

      if (conversation != null) {
        _messages = conversation.messages;
        _currentConversationId = conversationId;
      } else {
        _error = 'Không tìm thấy cuộc hội thoại';
        _messages = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        _error = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else if (e.toString().contains('permission-denied')) {
        _error = 'Không có quyền xem cuộc hội thoại. Vui lòng đăng nhập lại.';
      } else if (e.toString().contains('not-found')) {
        _error = 'Cuộc hội thoại không tồn tại hoặc đã bị xóa.';
      } else {
        _error = 'Không thể tải cuộc hội thoại. Vui lòng thử lại sau.';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo cuộc hội thoại mới
  void startNewConversation() {
    _messages = [];
    _currentConversationId = null;
    _error = null;
    notifyListeners();
  }

  /// Xóa một cuộc hội thoại
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _chatRepository.deleteConversation(
        userId: _userId,
        conversationId: conversationId,
      );
      // Nếu đang xem conversation này, đưa user về màn Chat rỗng
      if (_currentConversationId == conversationId) {
        startNewConversation();
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        _error = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else if (e.toString().contains('permission-denied')) {
        _error = 'Không có quyền xóa cuộc hội thoại. Vui lòng đăng nhập lại.';
      } else {
        _error = 'Không thể xóa cuộc hội thoại. Vui lòng thử lại sau.';
      }
      notifyListeners();
    }
  }

  void retryLastMessage() {
    if (_messages.isEmpty) return;

    final lastUserMessage = _messages.lastWhere(
      (msg) => msg.role == ChatRole.user,
      orElse: () => _messages.last,
    );

    // Xóa messages từ last user message đến cuối
    final lastIndex = _messages.indexOf(lastUserMessage);
    _messages = _messages.sublist(0, lastIndex + 1);
    notifyListeners();

    // Gửi lại
    sendMessage(lastUserMessage.content);
  }

}

