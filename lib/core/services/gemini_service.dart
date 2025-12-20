import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service để tương tác với Google Gemini API
/// Sử dụng model gemini-2.5-flash
class GeminiService {
  GeminiService() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint(
          '⚠️ GEMINI_API_KEY không được tìm thấy trong file .env. '
          'Chat AI sẽ không hoạt động. Vui lòng thêm GEMINI_API_KEY=your_api_key vào file .env',
        );
        _apiKey = '';
        _isInitialized = false;
        return;
      }
      _apiKey = apiKey;
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo GeminiService: $e');
      _apiKey = '';
      _isInitialized = false;
    }
  }

  String _apiKey = '';
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// System prompt mặc định cho AI Coach
  static const String _defaultSystemPrompt = '''
Bạn là một AI Coach chuyên về sức khỏe và tập luyện. 
Nhiệm vụ của bạn là:
- Trả lời các câu hỏi về dinh dưỡng, tập luyện, và sức khỏe
- Đưa ra lời khuyên dựa trên khoa học
- Trả lời bằng tiếng Việt, thân thiện và dễ hiểu
- Tập trung vào fitness, thể hình, và lối sống lành mạnh
''';

  /// Gửi message đến Gemini và nhận response
  /// 
  /// [prompt] - Câu hỏi/input từ user
  /// [chatHistory] - Lịch sử chat (optional) để có context
  /// [systemPrompt] - System prompt tùy chỉnh (optional)
  /// 
  /// Returns: Response text từ AI
  Future<String> sendMessage({
    required String prompt,
    List<Content>? chatHistory,
    String? systemPrompt,
  }) async {
    if (!_isInitialized || _apiKey.isEmpty) {
      throw Exception(
        'GeminiService chưa được khởi tạo. '
        'Vui lòng kiểm tra GEMINI_API_KEY trong file .env',
      );
    }
    try {
      final genAI = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          systemPrompt ?? _defaultSystemPrompt,
        ),
      );

      // Tạo chat session với lịch sử (nếu có)
      final chat = genAI.startChat(
        history: chatHistory ?? [],
      );

      final response = await chat.sendMessage(
        Content.text(prompt),
      );

      return response.text ?? 'Xin lỗi, tôi không thể tạo phản hồi lúc này.';
    } catch (e) {
      throw Exception('Lỗi khi gọi Gemini API: ${e.toString()}');
    }
  }

  /// Stream response từ Gemini (cho real-time typing effect)
  /// 
  /// [prompt] - Câu hỏi/input từ user
  /// [chatHistory] - Lịch sử chat (optional)
  /// [systemPrompt] - System prompt tùy chỉnh (optional)
  /// 
  /// Returns: Stream<String> - Từng phần của response
  Stream<String> streamMessage({
    required String prompt,
    List<Content>? chatHistory,
    String? systemPrompt,
  }) async* {
    if (!_isInitialized || _apiKey.isEmpty) {
      throw Exception(
        'GeminiService chưa được khởi tạo. '
        'Vui lòng kiểm tra GEMINI_API_KEY trong file .env',
      );
    }
    try {
      final genAI = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          systemPrompt ?? _defaultSystemPrompt,
        ),
      );

      final chat = genAI.startChat(
        history: chatHistory ?? [],
      );

      final response = chat.sendMessageStream(
        Content.text(prompt),
      );

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      throw Exception('Lỗi khi stream từ Gemini API: ${e.toString()}');
    }
  }

}

