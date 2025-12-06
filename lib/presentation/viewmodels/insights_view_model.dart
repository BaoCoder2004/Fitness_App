import 'package:flutter/foundation.dart';

import '../../core/services/ai_coach_service.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/repositories/ai_insight_repository.dart';

class InsightsViewModel extends ChangeNotifier {
  InsightsViewModel({
    required AICoachService aiCoachService,
    required AIInsightRepository insightRepository,
    required String userId,
    NotificationService? notificationService,
  })  : _aiCoachService = aiCoachService,
        _insightRepository = insightRepository,
        _userId = userId,
        _notificationService = notificationService;

  final AICoachService _aiCoachService;
  final AIInsightRepository _insightRepository;
  final String _userId;
  final NotificationService? _notificationService;

  List<AIInsight> _insights = [];
  bool _isLoading = false;
  String? _error;
  InsightType? _selectedFilter;
  DateTime? _lastAnalysisDate; // Cache: Lần cuối phân tích
  static const Duration _analysisCooldown = Duration(hours: 1); // Chỉ phân tích lại sau 1 giờ
  DateTime? _lastWeeklyInsightDate; // Lần cuối tạo insight hàng tuần

  List<AIInsight> get insights {
    if (_selectedFilter != null) {
      return _insights
          .where((insight) => insight.insightType == _selectedFilter)
          .toList();
    }
    return _insights;
  }

  /// Lấy tất cả insights (không filter)
  List<AIInsight> get allInsights => _insights;

  bool get isLoading => _isLoading;
  String? get error => _error;
  InsightType? get selectedFilter => _selectedFilter;
  
  /// Kiểm tra xem có insight nào không (kể cả khi filter)
  bool get hasAnyInsights => _insights.isNotEmpty;

  /// Load insights từ Firestore
  Future<void> loadInsights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await _insightRepository.getInsights(_userId);
      _insights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Kiểm tra và tự động tạo insight hàng tuần nếu cần (chạy async, không block)
      _checkAndCreateWeeklyInsight().catchError((e) {
        debugPrint('❌ Lỗi khi check weekly insight: $e');
      });
    } catch (e) {
      _error = 'Không thể tải insights: $e';
      debugPrint('❌ Lỗi khi load insights: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kiểm tra và tự động tạo insight hàng tuần vào Chủ nhật
  Future<void> _checkAndCreateWeeklyInsight() async {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    
    // Chỉ tạo vào Chủ nhật (cuối tuần)
    if (weekday != 7) {
      return; // Chưa đến Chủ nhật
    }

    // Kiểm tra xem đã có insight tuần này chưa (từ Thứ 2 tuần này đến hôm nay)
    // Tính Thứ 2 tuần này 00:00:00
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: weekday - 1));
    final hasWeeklyInsightThisWeek = _insights.any((insight) {
      if (insight.insightType != InsightType.general) return false;
      final insightDate = DateTime(
        insight.createdAt.year,
        insight.createdAt.month,
        insight.createdAt.day,
      );
      // Kiểm tra xem insight có được tạo từ Thứ 2 tuần này trở đi không
      return !insightDate.isBefore(thisWeekStart);
    });

    if (hasWeeklyInsightThisWeek) {
      debugPrint('✅ Đã có insight tuần này, bỏ qua');
      return;
    }

    // Kiểm tra cooldown: Không tạo lại nếu đã tạo gần đây (trong 24h)
    if (_lastWeeklyInsightDate != null) {
      final timeSinceLastWeekly = now.difference(_lastWeeklyInsightDate!);
      if (timeSinceLastWeekly < const Duration(hours: 24)) {
        debugPrint('⏭️ Đã tạo insight hàng tuần gần đây, bỏ qua');
        return;
      }
    }

    // Tự động tạo insight hàng tuần
    debugPrint('📅 Tự động tạo insight hàng tuần...');
    try {
      final insight = await _aiCoachService.analyzeAndSuggest(
        _userId,
        days: 7, // Phân tích dữ liệu 7 ngày qua
        focusType: InsightType.general,
      );

      // Lưu vào Firestore
      await _insightRepository.saveInsight(insight);
      _lastWeeklyInsightDate = DateTime.now();

      // Gửi thông báo
      final notificationService = _notificationService;
      if (notificationService != null) {
        await notificationService.showAIInsightNotification(
          insightId: insight.id,
          title: '📊 Báo cáo tuần: ${insight.title}',
          preview: insight.content.length > 100
              ? insight.content.substring(0, 100)
              : insight.content,
        );
      }

      // Reload insights
      _insights = await _insightRepository.getInsights(_userId);
      _insights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      
      debugPrint('✅ Đã tạo insight hàng tuần thành công');
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo insight hàng tuần: $e');
      // Không hiển thị lỗi cho user vì đây là tự động
    }
  }

  /// Tạo insight mới bằng AI
  Future<AIInsight?> generateInsight({
    InsightType? focusType,
    int days = 30,
    bool force = false, // Bỏ qua cache nếu true
  }) async {
    // Kiểm tra cache: Nếu đã phân tích gần đây và không force, không phân tích lại
    // NHƯNG: Nếu có focusType khác với lần trước, vẫn cho phép tạo
    if (!force &&
        _lastAnalysisDate != null &&
        DateTime.now().difference(_lastAnalysisDate!) < _analysisCooldown) {
      // Kiểm tra xem đã có insight loại này chưa
      final hasThisTypeInsight = _insights.any(
        (insight) => focusType != null && insight.insightType == focusType,
      );
      if (hasThisTypeInsight) {
        debugPrint('⏭️ Bỏ qua phân tích (đã có insight loại này)');
        return null;
      }
      // Nếu chưa có insight loại này, vẫn cho phép tạo
      debugPrint('✅ Cho phép tạo insight loại mới: $focusType');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AIInsight insight;
      
      // Nếu có focusType cụ thể, dùng method riêng để có phân tích chi tiết hơn
      if (focusType == InsightType.weight) {
        insight = await _aiCoachService.analyzeWeightTrend(_userId, days: days);
      } else if (focusType == InsightType.activity) {
        insight = await _aiCoachService.analyzeActivityLevel(_userId, days: days);
      } else {
        // Dùng method chung cho các loại khác
        insight = await _aiCoachService.analyzeAndSuggest(
          _userId,
          days: days,
          focusType: focusType,
        );
      }

      // Lưu vào Firestore
      await _insightRepository.saveInsight(insight);

      // Cập nhật cache
      _lastAnalysisDate = DateTime.now();

      // Gửi thông báo
      final notificationService = _notificationService;
      if (notificationService != null) {
        await notificationService.showAIInsightNotification(
          insightId: insight.id,
          title: insight.title,
          preview: insight.content.length > 100
              ? insight.content.substring(0, 100)
              : insight.content,
        );
      }

      // Reload insights
      await loadInsights();

      return insight;
    } catch (e, stackTrace) {
      // Log chi tiết lỗi để debug
      debugPrint('❌ Lỗi khi tạo insight: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Tạo error message thân thiện hơn
      String errorMessage = 'Không thể tạo insight';
      if (e.toString().contains('JSON')) {
        errorMessage = 'Lỗi định dạng dữ liệu từ AI. Vui lòng thử lại.';
      } else if (e.toString().contains('API')) {
        errorMessage = 'Lỗi kết nối với AI. Vui lòng kiểm tra kết nối mạng.';
      } else if (e.toString().contains('GEMINI_API_KEY')) {
        errorMessage = 'API key chưa được cấu hình. Vui lòng kiểm tra file .env';
      } else {
        errorMessage = 'Lỗi: ${e.toString()}';
      }
      
      _error = errorMessage;
      
      // Fallback: Hiển thị insights cũ nếu có
      if (_insights.isEmpty) {
        await loadInsights();
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa insight
  Future<void> deleteInsight(String insightId) async {
    try {
      await _insightRepository.deleteInsight(_userId, insightId);
      _insights.removeWhere((insight) => insight.id == insightId);
      notifyListeners();
    } catch (e) {
      _error = 'Không thể xóa insight: $e';
      debugPrint('❌ Lỗi khi xóa insight: $e');
      notifyListeners();
    }
  }

  /// Set filter
  void setFilter(InsightType? type) {
    _selectedFilter = type;
    notifyListeners();
  }

  /// Clear filter
  void clearFilter() {
    _selectedFilter = null;
    notifyListeners();
  }
}

