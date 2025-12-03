import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Enum để chọn model Gemini
enum GeminiModel {
  flash, // gemini-2.5-flash (nhanh, ít tốn token)
  pro,   // gemini-2.5-pro (chính xác hơn, tốn token hơn)
}

extension GeminiModelExtension on GeminiModel {
  String get modelName {
    switch (this) {
      case GeminiModel.flash:
        return 'gemini-2.5-flash';
      case GeminiModel.pro:
        return 'gemini-2.5-pro';
    }
  }
}

/// Service để tương tác với Google Gemini API
/// Hỗ trợ cả 2 model: Flash (nhanh) và Pro (chính xác)
class GeminiService {
  GeminiService() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      debugPrint('🔍 Đang kiểm tra GEMINI_API_KEY...');
      debugPrint('🔍 dotenv.env keys: ${dotenv.env.keys.toList()}');
      debugPrint('🔍 GEMINI_API_KEY value: ${apiKey != null ? "${apiKey.substring(0, 10)}..." : "null"}');
      
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
      debugPrint('✅ GeminiService đã được khởi tạo thành công');
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
  /// [model] - Chọn model: Flash (mặc định, nhanh) hoặc Pro (chính xác hơn)
  /// [systemPrompt] - System prompt tùy chỉnh (optional)
  /// 
  /// Returns: Response text từ AI
  Future<String> sendMessage({
    required String prompt,
    List<Content>? chatHistory,
    GeminiModel model = GeminiModel.flash,
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
        model: model.modelName,
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
  /// [model] - Chọn model: Flash hoặc Pro
  /// [systemPrompt] - System prompt tùy chỉnh (optional)
  /// 
  /// Returns: Stream<String> - Từng phần của response
  Stream<String> streamMessage({
    required String prompt,
    List<Content>? chatHistory,
    GeminiModel model = GeminiModel.flash,
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
        model: model.modelName,
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

  /// Tự động chọn model dựa trên độ phức tạp của câu hỏi
  /// 
  /// **Lưu ý về chi phí:**
  /// - Flash: Miễn phí hoặc rất rẻ, phù hợp cho hầu hết câu hỏi
  /// - Pro: Có thể mất phí, chỉ dùng cho câu hỏi phức tạp thực sự
  /// 
  /// Mặc định ưu tiên Flash để tiết kiệm chi phí.
  GeminiModel selectModelForPrompt(String prompt) {
    // Mặc định dùng Flash để tiết kiệm chi phí
    // Chỉ dùng Pro cho các câu hỏi thực sự phức tạp
    
    // Tắt tự động chọn Pro để tiết kiệm chi phí
    // Nếu muốn dùng Pro, có thể bỏ comment phần dưới
    return GeminiModel.flash;
    
    // Uncomment để bật tự động chọn Pro cho câu hỏi phức tạp:
    /*
    final complexKeywords = [
      'phân tích chi tiết',
      'so sánh kỹ lưỡng',
      'kế hoạch tổng thể',
      'tư vấn chuyên sâu',
    ];

    final isComplex = complexKeywords.any(
      (keyword) => prompt.toLowerCase().contains(keyword),
    ) || prompt.length > 500; // Chỉ dùng Pro cho prompt rất dài

    return isComplex ? GeminiModel.pro : GeminiModel.flash;
    */
  }
}

