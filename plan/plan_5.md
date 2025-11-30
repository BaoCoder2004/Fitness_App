## Kế hoạch triển khai Plan 5: Kế hoạch Tập luyện & Chatbot AI

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Kế hoạch Tập luyện", "Kế hoạch có sẵn", "Kế hoạch tùy chỉnh", "Chat với AI", "Gửi", "Lịch sử chat", "Xóa lịch sử", v.v.

### Phase 1: Kế hoạch tập luyện có sẵn
- **1.1 Tạo collection `training_plans`** trong Firestore:
  - id, name, description, duration (số tuần), difficulty, exercises
- **1.2 Định nghĩa các kế hoạch mặc định:**
  - Chạy 5K: 8 tuần, từ đi bộ đến chạy 5km
  - Giảm cân: 12 tuần, kết hợp cardio và strength
  - Tăng sức bền: 10 tuần, tăng dần cường độ
  - (Có thể thêm nhiều kế hoạch khác)
- **1.3 Schema cho kế hoạch:**
  - Mỗi kế hoạch có nhiều tuần
  - Mỗi tuần có nhiều ngày
  - Mỗi ngày có danh sách bài tập
- **1.4 Màn hình Workout Plans:**
  - Danh sách các kế hoạch có sẵn
  - Card hiển thị: tên, mô tả, số tuần, độ khó
  - Nút "Xem chi tiết"
- **1.5 Màn hình Plan Detail:**
  - Hiển thị tổng quan kế hoạch
  - Lịch tập theo tuần
  - Xem chi tiết từng ngày
  - Nút "Bắt đầu kế hoạch"

### Phase 2: Bắt đầu và theo dõi kế hoạch
- **2.1 Tạo collection `user_active_plans`** trong Firestore:
  - userId, planId, startDate, currentWeek, currentDay, status, progress
- **2.2 Khi user bắt đầu kế hoạch:**
  - Tạo document trong `user_active_plans`
  - Status: 'active'
  - currentWeek: 1, currentDay: 1
- **2.3 Màn hình My Workout Plan:**
  - Hiển thị kế hoạch đang thực hiện
  - Progress: Tuần X / Tổng số tuần
  - Lịch tập của tuần hiện tại
  - Đánh dấu ngày đã hoàn thành
- **2.4 Đánh dấu hoàn thành bài tập:**
  - Tap vào bài tập trong ngày
  - Đánh dấu "Hoàn thành"
  - Cập nhật progress
  - Tự động chuyển sang ngày tiếp theo

### Phase 3: Kế hoạch tập luyện tùy chỉnh
- **3.1 Tạo kế hoạch riêng:**
  - Màn hình Create Custom Plan
  - Nhập tên, mô tả
  - Chọn số tuần
- **3.2 Thêm/sửa/xóa bài tập:**
  - Màn hình Edit Plan
  - Thêm bài tập cho từng ngày
  - Chọn loại hoạt động, thời gian, số lần lặp
  - Sắp xếp lại thứ tự
- **3.3 Đặt lịch tập luyện:**
  - Chọn ngày trong tuần sẽ tập
  - Chọn giờ tập (tùy chọn)
  - Lưu vào Firestore
- **3.4 Nhắc nhở khi đến giờ tập:**
  - Sử dụng NotificationService
  - Nhắc nhở vào giờ đã đặt
  - Chỉ nhắc nhở vào các ngày đã chọn

### Phase 4: Tích hợp Chatbot AI (Gemini)
- **4.1 Setup Google Gemini API:**
  - Thêm dependency `google_generative_ai`
  - Cấu hình API key (dùng environment variable)
- **4.2 Tạo `GeminiService`:**
  - Method `sendMessage(prompt)`: Gửi câu hỏi đến Gemini
  - Method `streamMessage(prompt)`: Stream response (nếu cần)
  - Error handling: rate limit, network error
- **4.3 Prompt engineering:**
  - Tạo system prompt: "Bạn là AI coach về sức khỏe và tập luyện..."
  - Context: Trả lời bằng tiếng Việt, tập trung vào fitness
- **4.4 Màn hình AI Coach với TabBar:**
  - **TabBar với 2 tabs:** "Chat với AI" và "AI Insights" (Plan 6)
  - **Tab 1: Chat với AI:**
    - Giao diện giống messenger
    - ListView hiển thị messages
    - Input field ở dưới
    - Nút gửi
    - Loading indicator khi AI đang trả lời
  - **Lưu ý:** Tab 2 (AI Insights) sẽ được implement trong Plan 6

### Phase 5: Chatbot trả lời câu hỏi
- **5.1 Xử lý câu hỏi:**
  - Gửi prompt đến Gemini API
  - Nhận response
  - Format lại response cho dễ đọc
- **5.2 Các chủ đề hỗ trợ:**
  - Dinh dưỡng: calo, macro, meal plan
  - Tập luyện: bài tập, kỹ thuật, lịch tập
  - Sức khỏe: BMI, BMR, TDEE, recovery
- **5.3 Gợi ý câu hỏi thường gặp:**
  - Hiển thị các câu hỏi mẫu
  - User có thể tap để gửi nhanh
- **5.4 Xử lý lỗi:**
  - Khi không kết nối được API
  - Khi API trả về lỗi
  - Hiển thị message thân thiện

### Phase 6: Lưu lịch sử chat
- **6.1 Tạo collection `chat_history`** trong Firestore:
  - userId, messages, createdAt, updatedAt
- **6.2 Lưu mỗi cuộc hội thoại:**
  - Lưu cả user message và AI response
  - Timestamp cho mỗi message
  - Lưu khi kết thúc chat hoặc khi app đóng
- **6.3 Xem lại lịch sử:**
  - Trong Tab "Chat với AI" của AI Coach screen
  - Danh sách các cuộc hội thoại (có thể hiển thị trong sidebar hoặc dialog)
  - Tap vào để xem lại cuộc hội thoại cũ
- **6.4 Xóa lịch sử:**
  - Nút "Xóa lịch sử" trong Tab "Chat với AI"
  - Confirm dialog
  - Xóa từ Firestore

### Phase 7: Cải thiện trải nghiệm chat
- **7.1 Format câu trả lời:**
  - Markdown support (bold, italic, list)
  - Line breaks
  - Dễ đọc hơn
- **7.2 Typing indicator:**
  - Hiển thị khi AI đang "suy nghĩ"
  - Animation typing dots
- **7.3 Copy message:**
  - Long press để copy message
  - Toast "Đã sao chép"
- **7.4 Retry mechanism:**
  - Nút "Thử lại" khi có lỗi
  - Gửi lại câu hỏi

---

## Cấu trúc File Dự Kiến

```
lib/
├── models/
│   ├── training_plan.dart      # Model TrainingPlan
│   ├── user_active_plan.dart   # Model UserActivePlan
│   └── chat_message.dart       # Model ChatMessage
├── services/
│   ├── training_plan_service.dart  # TrainingPlanService
│   ├── gemini_service.dart    # GeminiService
│   └── chat_service.dart     # ChatService
├── screens/
│   ├── training_plans/
│   │   ├── training_plans_screen.dart
│   │   ├── plan_detail_screen.dart
│   │   ├── my_active_plan_screen.dart
│   │   └── create_custom_plan_screen.dart
│   └── ai/
│       ├── ai_coach_screen.dart    # Màn hình chính với TabBar
│       ├── chat_tab.dart           # Tab 1: Chat với AI
│       └── chat_history_screen.dart # Xem lịch sử chat (dialog hoặc bottom sheet)
└── widgets/
    ├── training_plan_card.dart  # Card kế hoạch
    ├── exercise_item.dart     # Item bài tập
    └── chat_bubble.dart       # Bubble tin nhắn
```

---

## Schema Firestore

### Collection: `training_plans` (Predefined)
```dart
{
  id: string (document ID),
  name: string,
  description: string,
  duration: int,  // số tuần
  difficulty: string,  // 'beginner' | 'intermediate' | 'advanced'
  weeks: array,  // [
    {
      weekNumber: int,
      days: [
        {
          dayNumber: int,
          exercises: [
            {
              name: string,
              type: string,  // 'running' | 'strength' | 'yoga' | ...
              duration: int?,  // seconds
              reps: int?,
              sets: int?,
              notes: string?
            }
          ]
        }
      ]
    }
  ],
  createdAt: Timestamp
}
```

### Collection: `user_active_plans`
```dart
{
  id: string (document ID - auto),
  userId: string,
  planId: string?,  // Null nếu là custom plan
  customPlanData: object?,  // Data nếu là custom plan
  startDate: Timestamp,
  currentWeek: int,
  currentDay: int,
  status: string,  // 'active' | 'completed' | 'paused' | 'cancelled'
  completedDays: array,  // [day1, day2, ...]
  progress: double,  // 0.0 - 1.0
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Collection: `chat_history`
```dart
{
  id: string (document ID - auto),
  userId: string,
  messages: array,  // [
    {
      role: 'user' | 'assistant',
      content: string,
      timestamp: Timestamp
    }
  ],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Security Rules Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Training Plans (read-only for users)
    match /training_plans/{planId} {
      allow read: if request.auth != null;
      allow write: if false;  // Chỉ admin mới có thể tạo
    }
    
    // User Active Plans
    match /user_active_plans/{planId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isOwner(request.resource.data.userId);
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    // Chat History
    match /chat_history/{chatId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isOwner(request.resource.data.userId);
      allow update, delete: if isOwner(resource.data.userId);
    }
  }
}
```

---

---

## Lưu Ý

- **AI Coach Screen:** Màn hình này có TabBar với 2 tabs. Tab 1 "Chat với AI" được implement trong Plan 5, Tab 2 "AI Insights" sẽ được implement trong Plan 6.
- **Navigation:** AI Coach screen nằm trong Bottom Navigation Bar (thay thế Mục tiêu), dễ truy cập từ mọi màn hình.

---

> Sau khi hoàn thành Plan 5, có thể chuyển sang Plan 6: AI Coaching & Phân tích Cá nhân hóa.

