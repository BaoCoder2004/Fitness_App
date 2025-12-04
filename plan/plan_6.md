## Kế hoạch triển khai Plan 6: AI Coaching & Phân tích Cá nhân hóa

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "AI Insights", "Phân tích", "Gợi ý", "Áp dụng gợi ý", "Xem chi tiết", v.v.

**⚠️ Phạm vi của Plan 6:**
- **AI chỉ PHÂN TÍCH dữ liệu và ĐƯA RA GỢI Ý**
- **KHÔNG tự động tạo mục tiêu mới** (chỉ gợi ý người dùng nên điều chỉnh)
- **KHÔNG tự động tạo kế hoạch tập luyện** (chỉ gợi ý bài tập phù hợp)

### Phase 1: Phân tích dữ liệu người dùng
- **1.1 Tạo `DataAnalyzer` service:**
  - Method `analyzeWeightTrend(userId, days)`: Phân tích xu hướng cân nặng
  - Method `analyzeActivityLevel(userId, days)`: Phân tích mức độ hoạt động
  - Method `analyzeWorkoutHabits(userId, days)`: Phân tích thói quen tập luyện
  - Method `analyzeGPSData(userId, days)`: Phân tích dữ liệu GPS
- **1.2 Phân tích xu hướng cân nặng:**
  - Lấy dữ liệu từ `weight_history`
  - Tính toán: tăng, giảm, hoặc ổn định
  - Tốc độ thay đổi (kg/tuần)
  - So sánh với mục tiêu
- **1.3 Phân tích mức độ hoạt động:**
  - Lấy dữ liệu từ `activities`
  - Tính tần suất tập luyện (số buổi/tuần)
  - Tính tổng quãng đường, kcal, thời gian
  - So sánh với tuần trước
- **1.4 Phân tích thói quen tập luyện:**
  - Loại hoạt động yêu thích
  - Thời gian tập luyện thường xuyên (sáng/chiều/tối)
  - Ngày trong tuần tập nhiều nhất
- **1.5 Phân tích dữ liệu GPS:**
  - Tốc độ trung bình, tốc độ cải thiện
  - Quãng đường trung bình mỗi buổi
  - Tần suất tập luyện ngoài trời

### Phase 2: Tổng hợp dữ liệu cho AI
- **2.1 Tạo `DataSummarizer` service:**
  - Method `summarizeUserData(userId)`: Tổng hợp tất cả dữ liệu
  - Format dữ liệu thành text context cho AI
- **2.2 Tạo context prompt:**
  - Thông tin user: age, height, weight, gender
  - Xu hướng cân nặng
  - Mức độ hoạt động
  - Thói quen tập luyện
  - Mục tiêu hiện tại
  - Dữ liệu GPS (nếu có)
- **2.3 Format context:**
  - Dễ đọc cho AI
  - Bao gồm số liệu cụ thể
  - Timestamp cho các sự kiện

### Phase 3: AI phân tích và đưa ra gợi ý
- **3.1 Tạo `AICoachService`:**
  - Method `analyzeAndSuggest(userId)`: Phân tích và đưa ra gợi ý
  - Kết hợp DataAnalyzer + DataSummarizer + Gemini API
- **3.2 Prompt engineering nâng cao:**
  - System prompt: "Bạn là AI fitness coach chuyên nghiệp..."
  - Đưa context dữ liệu user vào prompt
  - Yêu cầu AI phân tích và đưa ra gợi ý cụ thể
- **3.3 Phân tích và gợi ý:**
  - Phân tích xu hướng cân nặng → Gợi ý điều chỉnh
  - Phân tích mức độ hoạt động → Gợi ý tăng/giảm
  - Phân tích thói quen → Gợi ý cải thiện
  - Phân tích GPS → Gợi ý tăng tốc độ/quãng đường
- **3.4 Nhận diện vấn đề:**
  - Không đạt mục tiêu quãng đường
  - Chuỗi bị gián đoạn
  - Cân nặng không thay đổi
  - Hoạt động giảm dần
- **3.5 Đưa ra gợi ý cá nhân hóa:**
  - Gợi ý điều chỉnh mục tiêu dựa trên tiến độ (người dùng tự quyết định)
  - Lời khuyên dinh dưỡng
  - Gợi ý bài tập phù hợp (không tạo kế hoạch cụ thể)
  - Cảnh báo khi có dấu hiệu bất thường
  - **Lưu ý:** AI chỉ đưa ra gợi ý, KHÔNG tự động tạo mục tiêu hay kế hoạch mới

### Phase 4: Màn hình Insights từ AI
- **4.1 Tạo collection `ai_insights`** trong Firestore:
  - userId, insightType, title, content, analysis, suggestions, createdAt
- **4.2 Tích hợp vào AI Coach Screen (Tab 2):**
  - **TabBar:** Đã có từ Plan 5, thêm Tab 2 "AI Insights"
  - **Tab 2: AI Insights:**
    - Danh sách các insights
    - Card hiển thị: title, summary, ngày tạo
    - Tap để xem chi tiết
    - Empty state khi chưa có insights
- **4.3 Màn hình Insight Detail:**
  - Hiển thị phân tích chi tiết
  - Hiển thị các gợi ý
  - Nút "Áp dụng gợi ý" (nếu có)
  - Có thể mở từ Tab "AI Insights" hoặc từ notification
- **4.4 Lưu lịch sử insights:**
  - Lưu mỗi insight vào Firestore
  - Có thể xem lại insights cũ trong Tab "AI Insights"
  - Filter theo loại insight (dropdown hoặc chip)

### Phase 5: Tự động gợi ý
- **5.1 Tự động phân tích:**
  - Trigger khi có dữ liệu mới (buổi tập mới, cập nhật cân nặng)
  - Hoặc chạy, đi bộ, đạp xe định kỳ (hàng ngày/tuần)
- **5.2 Gửi thông báo insight mới:**
  - Sử dụng NotificationService
  - Thông báo khi có insight mới
  - Hiển thị preview insight
- **5.3 Gợi ý hàng tuần:**
  - Chạy vào cuối tuần
  - Phân tích dữ liệu cả tuần
  - Đưa ra gợi ý cho tuần tới
- **5.4 Background processing:**
  - Chạy phân tích khi user mở app (không cần background service)
  - Hoặc chạy khi user vào Tab "AI Insights"
  - Có thể cache kết quả để không phải tính lại mỗi lần
  - **Lưu ý**: Không cần WorkManager - phân tích AI có thể chạy khi user tương tác với app

### Phase 6: UI/UX và tối ưu
- **6.1 Loading states:**
  - Shimmer effect khi đang phân tích
  - Progress indicator
- **6.2 Error handling:**
  - Xử lý khi AI API lỗi
  - Retry mechanism
  - Fallback: Hiển thị insights cũ
- **6.3 Performance:**
  - Cache insights đã phân tích
  - Chỉ phân tích lại khi có dữ liệu mới
  - Debounce cho auto-analysis
- **6.4 Animation:**
  - Smooth transition khi hiển thị insights
  - Celebration khi có insight tích cực

---

## Cấu trúc File Dự Kiến

```
lib/
├── models/
│   └── ai_insight.dart         # Model AIInsight
├── services/
│   ├── data_analyzer.dart     # DataAnalyzer
│   ├── data_summarizer.dart   # DataSummarizer
│   └── ai_coach_service.dart  # AICoachService
├── screens/
│   └── ai/
│       ├── ai_coach_screen.dart    # Màn hình chính với TabBar (đã có từ Plan 5)
│       ├── insights_tab.dart      # Tab 2: AI Insights
│       └── insight_detail_screen.dart # Chi tiết insight
└── widgets/
    ├── insight_card.dart      # Card hiển thị insight
    └── suggestion_item.dart   # Item gợi ý
```

---

## Schema Firestore

### Collection: `ai_insights`
```dart
{
  id: string (document ID - auto),
  userId: string,
  insightType: string,  // 'weight' | 'activity' | 'goal' | 'gps' | 'general'
  title: string,
  content: string,  // Phân tích chi tiết
  analysis: object,  // {
    trend: string,  // 'increasing' | 'decreasing' | 'stable'
    currentValue: double,
    targetValue: double?,
    issues: array  // ['not_meeting_goal', 'streak_broken', ...]
  },
  suggestions: array,  // [
    {
      type: string,
      title: string,
      description: string,
      actionable: bool  // Có thể áp dụng ngay không
    }
  ],
  createdAt: Timestamp
}
```

---

## Security Rules Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // AI Insights collection
    match /ai_insights/{insightId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Prompt Templates

### System Prompt cho AI Coach:
```
Bạn là một AI fitness coach chuyên nghiệp. Nhiệm vụ của bạn là phân tích dữ liệu sức khỏe và tập luyện của người dùng, sau đó đưa ra các gợi ý cá nhân hóa để giúp họ đạt được mục tiêu.

Hãy trả lời bằng tiếng Việt, thân thiện và dễ hiểu. Đưa ra các gợi ý cụ thể, có thể thực hiện được.
```

### Prompt cho phân tích:
```
Dựa trên dữ liệu sau của người dùng:
[Context data từ DataSummarizer]

Hãy phân tích và đưa ra:
1. Xu hướng hiện tại (tăng/giảm/ổn định)
2. Các vấn đề cần chú ý
3. Gợi ý cụ thể để cải thiện
```

---

## Lưu Ý

- **AI Coach Screen:** Màn hình này đã được tạo trong Plan 5 với TabBar và Tab 1 "Chat với AI". Plan 6 sẽ thêm Tab 2 "AI Insights" vào màn hình này.
- **Tích hợp:** Tab "AI Insights" sẽ hiển thị danh sách insights từ collection `ai_insights`, có thể filter và xem chi tiết.

---

> Plan 6 là plan cuối cùng và quan trọng nhất. Sau khi hoàn thành, ứng dụng đã có đầy đủ các chức năng cơ bản đến nâng cao.

