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
  GeminiModel _selectedModel = GeminiModel.flash; // Mặc định dùng Flash
  String? _currentConversationId; // ID của cuộc hội thoại hiện tại

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTyping => _isTyping;
  GeminiModel get selectedModel => _selectedModel;
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
      _error = 'Không thể tải lịch sử chat: ${e.toString()}';
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

      // Sử dụng model được người dùng chọn (mặc định là Flash)
      final response = await _geminiService.sendMessage(
        prompt: text.trim(),
        chatHistory: chatHistory,
        model: _selectedModel,
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
    } catch (e) {
      _isTyping = false;
      _error = 'Không thể gửi tin nhắn. Vui lòng thử lại.';
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
      _error = 'Không thể xóa lịch sử chat: ${e.toString()}';
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
      _error = 'Không thể tải cuộc hội thoại: ${e.toString()}';
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
      // Nếu đang xem conversation này, clear messages
      if (_currentConversationId == conversationId) {
        startNewConversation();
      }
    } catch (e) {
      _error = 'Không thể xóa cuộc hội thoại: ${e.toString()}';
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

  /// Thay đổi model được chọn
  void setModel(GeminiModel model) {
    _selectedModel = model;
    notifyListeners();
  }
}

