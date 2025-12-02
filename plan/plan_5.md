## Kế hoạch triển khai Plan 5: Chatbot AI

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Chat với AI", "Gửi", "Lịch sử chat", "Xóa lịch sử", "AI Insights", v.v.

### Phase 1: Tích hợp Chatbot AI (Gemini)
- **1.1 Setup Google Gemini API:**
  - Thêm dependency `google_generative_ai` (đã có trong pubspec.yaml)
  - Cấu hình API key (dùng environment variable hoặc secure storage)
- **1.2 Tạo `GeminiService`:**
  - Method `sendMessage(prompt, chatHistory?)`: Gửi câu hỏi đến Gemini
  - Method `streamMessage(prompt, chatHistory?)`: Stream response (nếu cần)
  - Error handling: rate limit, network error, API key invalid
- **1.3 Prompt engineering:**
  - Tạo system prompt: "Bạn là AI coach về sức khỏe và tập luyện..."
  - Context: Trả lời bằng tiếng Việt, tập trung vào fitness
  - Hỗ trợ context từ lịch sử chat
- **1.4 Màn hình AI Coach với TabBar:**
  - **TabBar với 2 tabs:** "Chat với AI" và "AI Insights" (Plan 6)
  - **Tab 1: Chat với AI:**
    - Giao diện giống messenger
    - ListView hiển thị messages
    - Input field ở dưới
    - Nút gửi
    - Loading indicator khi AI đang trả lời
  - **Lưu ý:** Tab 2 (AI Insights) sẽ được implement trong Plan 6

### Phase 2: Chatbot trả lời câu hỏi
- **2.1 Xử lý câu hỏi:**
  - Gửi prompt đến Gemini API
  - Nhận response
  - Format lại response cho dễ đọc
- **2.2 Các chủ đề hỗ trợ:**
  - Dinh dưỡng: calo, macro, meal plan
  - Tập luyện: bài tập, kỹ thuật, lịch tập
  - Sức khỏe: BMI, BMR, TDEE, recovery
- **2.3 Gợi ý câu hỏi thường gặp:**
  - Hiển thị các câu hỏi mẫu khi chưa có tin nhắn
  - User có thể tap để gửi nhanh
- **2.4 Xử lý lỗi:**
  - Khi không kết nối được API
  - Khi API trả về lỗi
  - Hiển thị message thân thiện

### Phase 3: Lưu lịch sử chat
- **3.1 Tạo collection `users/{userId}/chat_history`** trong Firestore:
  - userId, messages (array), createdAt, updatedAt
- **3.2 Lưu mỗi cuộc hội thoại:**
  - Lưu cả user message và AI response
  - Timestamp cho mỗi message
  - Lưu khi kết thúc chat hoặc khi app đóng
  - Mỗi user có một document chat_history duy nhất (hoặc nhiều documents nếu muốn lưu nhiều cuộc hội thoại)
- **3.3 Xem lại lịch sử:**
  - Trong Tab "Chat với AI" của AI Coach screen
  - Nút "Lịch sử" trong AppBar
  - Dialog/BottomSheet hiển thị danh sách các cuộc hội thoại (nếu lưu nhiều)
  - Tap vào để xem lại cuộc hội thoại cũ
- **3.4 Xóa lịch sử:**
  - Nút "Xóa lịch sử" trong Tab "Chat với AI"
  - Confirm dialog
  - Xóa từ Firestore

### Phase 4: Cải thiện trải nghiệm chat
- **4.1 Format câu trả lời:**
  - Markdown support (bold, italic, list)
  - Line breaks
  - Dễ đọc hơn
- **4.2 Typing indicator:**
  - Hiển thị khi AI đang "suy nghĩ"
  - Animation typing dots
- **4.3 Copy message:**
  - Long press để copy message
  - Toast "Đã sao chép"
- **4.4 Retry mechanism:**
  - Nút "Thử lại" khi có lỗi
  - Gửi lại câu hỏi

---

## Cấu trúc File Dự Kiến

```
lib/
├── domain/
│   ├── entities/
│   │   └── chat_message.dart       # Entity ChatMessage
│   └── repositories/
│       └── chat_repository.dart    # Interface ChatRepository
├── data/
│   ├── models/
│   │   └── chat_message_model.dart  # Model ChatMessage
│   └── repositories/
│       └── firestore_chat_repository.dart  # FirestoreChatRepository
├── core/
│   └── services/
│       └── gemini_service.dart     # GeminiService
└── presentation/
    ├── pages/
    │   └── ai_coach/
    │       ├── ai_coach_page.dart    # Màn hình chính với TabBar
    │       ├── chat_tab.dart         # Tab 1: Chat với AI
    │       └── chat_history_dialog.dart # Dialog xem lịch sử chat
    └── widgets/
        └── chat_bubble.dart         # Bubble tin nhắn
```

---

## Schema Firestore

### Collection: `users/{userId}/chat_history`
```dart
{
  id: string (document ID - auto, có thể dùng 'current' cho cuộc hội thoại hiện tại),
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

**Lưu ý:** Có thể lưu một document duy nhất với id = 'current' cho mỗi user, hoặc lưu nhiều documents để có nhiều cuộc hội thoại. Tùy vào yêu cầu UX.

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
    
    // Chat History
    match /users/{userId}/chat_history/{chatId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update, delete: if isOwner(userId);
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

