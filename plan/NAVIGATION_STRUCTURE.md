# Cấu Trúc Navigation - Ứng Dụng Fitness

## Tổng Quan
Thiết kế cấu trúc điều hướng và giao diện cho ứng dụng fitness với các chức năng chính, phù hợp với 6 plan đã định nghĩa.

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Các tên tiếng Anh trong tài liệu này (như "Dashboard", "Activity", "Statistics") chỉ là tên biến/tên file trong code
- Trên giao diện người dùng phải hiển thị: "Trang chủ", "Hoạt động", "Thống kê", "Hồ sơ", "Mục tiêu", "Kế hoạch Tập luyện", "Xuất dữ liệu", "Cài đặt", v.v.

---

## Cấu Trúc Navigation Chính

### Bottom Navigation Bar (5 mục chính - Khuyến nghị)
**Lý do**: Dễ truy cập, phù hợp với mobile, bao quát tất cả chức năng chính

#### 5 mục chính:
1. **🏠 Dashboard** (Trang chủ)
   - Hiển thị tổng quan các chỉ số hôm nay
   - Card: cân nặng, quãng đường, kcal, thời gian tập
   - Quick actions: Bắt đầu tập ngay (FAB hoặc Button lớn)
   - Hoạt động gần đây (danh sách ngắn)

2. **🏃 Hoạt động** (Activity)
   - **Tab 1: Bắt đầu tập** (Activity Selection)
     - Chọn loại hoạt động: Ngoài trời (Chạy, Đi bộ, Đạp xe) hoặc Tại nhà (Aerobic, Yoga, Gym, ...)
     - Mở màn hình Activity Tracking tương ứng
   - **Tab 2: Lịch sử** (Activity History) 
     - Danh sách tất cả buổi tập đã lưu
     - Lọc theo ngày/tuần/tháng
     - Xem chi tiết từng buổi tập
     - Xem lại route GPS (nếu có) - Plan 4
   - **Tab 3: GPS Routes** (Chỉ hiển thị khi có dữ liệu GPS - Plan 4)
     - Xem lại các route GPS trên bản đồ
     - Thống kê buổi tập GPS

3. **📊 Thống kê** (Statistics)
   - Biểu đồ xu hướng (cân nặng, quãng đường, kcal, thời gian tập)
   - Lọc theo ngày/tuần/tháng/năm
   - Chỉ số sức khỏe: BMI, BMR, TDEE
   - Streak (chuỗi)
   - Thống kê chi tiết theo thời gian (Plan 3)

4. **💬 AI Coach** (Plan 5 & 6)
   - **Tab 1: Chat với AI**
     - Giao diện messenger
     - Input nhập câu hỏi
     - Loading khi AI đang trả lời
     - Trả lời về dinh dưỡng, tập luyện, sức khỏe (Gemini API)
     - Lưu lịch sử chat vào Firestore
   - **Tab 2: AI Insights** (Plan 6)
     - Phân tích dữ liệu người dùng
     - Gợi ý cá nhân hóa
     - Lịch sử insights
     - Thông báo khi có insight mới

5. **👤 Profile** (Hồ sơ)
   - Thông tin cá nhân (tên, tuổi, chiều cao, cân nặng, avatar)
   - Chỉnh sửa thông tin
   - Lịch sử cân nặng (biểu đồ xu hướng)
   - Cài đặt (mở Drawer)

---

## Drawer Menu (Sidebar)

**Lý do**: Chứa các chức năng phụ, không cần truy cập thường xuyên, và các chức năng nâng cao

### Các mục trong Drawer:
- **🎯 Mục tiêu** (Goals - Plan 3)
  - Danh sách mục tiêu đang theo dõi
  - Tiến độ hoàn thành (%)
  - Đặt mục tiêu mới
  - Mục tiêu đã hoàn thành
- **📋 Kế hoạch Tập luyện** (Plan 5)
  - Kế hoạch có sẵn (Chạy 5K, Giảm cân, Tăng sức bền, ...)
  - Kế hoạch tùy chỉnh (tạo mới, chỉnh sửa)
  - Kế hoạch đang thực hiện (theo dõi tiến độ)
- **📤 Xuất dữ liệu** (Plan 4)
  - Xuất báo cáo PDF
  - Xuất dữ liệu Excel/CSV
  - Chia sẻ file
- **⚙️ Cài đặt**
  - Theme (Dark/Light)
  - Ngôn ngữ (tiếng Việt)
  - Thông báo (nhắc nhở tập luyện, mục tiêu)
  - Đồng bộ dữ liệu (kiểm tra trạng thái)
  - Đăng xuất

---

## Cấu Trúc Màn Hình Chi Tiết

### 1. Dashboard Screen
```
┌─────────────────────────┐
│  AppBar: "Hôm nay"      │
├─────────────────────────┤
│  Card: Cân nặng hiện tại│ ← Từ UserProfile
│  Card: Quãng đường      │ ← Tổng từ hoạt động ngoài trời hôm nay
│  Card: Kcal tiêu thụ    │ ← Tổng từ tất cả hoạt động hôm nay
│  Card: Thời gian tập    │ ← Tổng từ tất cả hoạt động hôm nay
├─────────────────────────┤
│  [Bắt đầu tập ngay]     │ ← FAB hoặc Button lớn → Activity Selection
├─────────────────────────┤
│  Hoạt động gần đây      │
│  - Buổi tập 1           │ ← Click để xem chi tiết
│  - Buổi tập 2           │
│  [Xem tất cả →]         │ → Activity History
└─────────────────────────┘
```

### 2. Statistics Screen
```
┌─────────────────────────┐
│  AppBar: "Thống kê"     │
├─────────────────────────┤
│  [Tab: Ngày/Tuần/Tháng] │ ← TabBar
├─────────────────────────┤
│  [Chọn loại biểu đồ]    │ ← Dropdown
│  - Cân nặng             │
│  - Quãng đường          │
│  - Kcal                 │
│  - Thời gian tập        │
├─────────────────────────┤
│  [Biểu đồ đường]        │
├─────────────────────────┤
│  Chỉ số sức khỏe:       │
│  - BMI: 22.5            │
│  - BMR: 1500 kcal       │
│  - TDEE: 2000 kcal      │
│  - Streak: 7 ngày       │
└─────────────────────────┘
```

### 3. AI Coach Screen
```
┌─────────────────────────┐
│  AppBar: "AI Coach"     │
├─────────────────────────┤
│  [Tab: Chat / Insights] │ ← TabBar
├─────────────────────────┤
│  Tab 1: Chat với AI      │
│  ┌─────────────────────┐│
│  │ [Lịch sử chat]       ││
│  │ User: Câu hỏi 1     ││
│  │ AI: Trả lời 1       ││
│  │ User: Câu hỏi 2     ││
│  │ AI: Trả lời 2       ││
│  └─────────────────────┘│
│  [Input: Nhập câu hỏi]  │
│  [Gửi]                  │
├─────────────────────────┤
│  Tab 2: AI Insights     │
│  - Phân tích xu hướng   │
│  - Gợi ý cá nhân hóa   │
│  - Lịch sử insights    │
└─────────────────────────┘
```

### 4. Goals Screen (trong Drawer)
```
┌─────────────────────────┐
│  AppBar: "Mục tiêu"     │
├─────────────────────────┤
│  [Tab: Đang theo dõi/   │ ← TabBar
│        Đã hoàn thành]   │
├─────────────────────────┤
│  Card: Mục tiêu 1       │
│  [Progress: 75%]        │
│  Còn 2kg để đạt mục tiêu│
├─────────────────────────┤
│  Card: Mục tiêu 2       │
│  [Progress: 50%]        │
├─────────────────────────┤
│  [+ Đặt mục tiêu mới]   │ ← FAB
└─────────────────────────┘
```

### 5. Profile Screen
```
┌─────────────────────────┐
│  AppBar: "Hồ sơ"        │
├─────────────────────────┤
│  [Avatar]               │
│  Tên người dùng          │
│  Email                   │
├─────────────────────────┤
│  Thông tin:             │
│  - Tuổi: 25             │
│  - Chiều cao: 170 cm    │
│  - Cân nặng: 65 kg      │
│  [Chỉnh sửa]            │
├─────────────────────────┤
│  Lịch sử cân nặng       │
│  [Xem tất cả →]         │
├─────────────────────────┤
│  Cài đặt                │
│  [Mở Drawer]            │
└─────────────────────────┘
```

---

## Navigation Flow

### Luồng chính:
```
Splash/AuthGate
    ↓
┌─────────────────┐
│  Bottom Nav Bar │
├─────────────────┤
│  Dashboard      │ ← Màn hình chính
│  Activity       │
│  Statistics     │
│  AI Coach       │
│  Profile        │
└─────────────────┘
```

### Luồng Activity Tracking:
```
Dashboard / Activity Tab
    ↓ (Bắt đầu tập)
Activity Selection Screen
    ├─→ Ngoài trời: Chạy, Đi bộ, Đạp xe
    │   ↓
    │   GPS Tracking Screen (Plan 1 cơ bản / Plan 4 nâng cao)
    │   - Hiển thị bản đồ (Plan 4)
    │   - Marker: Start (xanh dương), Current (xanh lục), End (xanh lục)
    │   - Polyline segments (Plan 4)
    │   - Thông tin real-time: quãng đường, thời gian, tốc độ TB, kcal
    │   ↓ (Hoàn thành)
    │   Popup: [Xóa] [Lưu]
    │   ↓ (Lưu)
    │   Activity Summary Screen (xem lại, chỉnh sửa)
    │
    └─→ Tại nhà: Aerobic, Yoga, Gym, ...
        ↓
        Indoor Tracking Screen (Timer)
        - Đếm thời gian (chỉ khi đang tập, không tính pause)
        - Tính kcal theo MET × thời gian × cân nặng
        - Theo dõi nhịp tim (nếu có thiết bị BLE) - Plan 1
        - Ghi chú bài tập
        ↓ (Hoàn thành)
        Popup: [Xóa] [Lưu]
        ↓ (Lưu)
        Activity Summary Screen (xem lại, chỉnh sửa)

Activity Summary Screen
    ↓ (Quay lại)
Dashboard / Activity History (cập nhật)
```

### Luồng AI Coach (Plan 5 & 6):
```
Bottom Nav → AI Coach Tab
    ↓
AI Coach Screen
    ├─→ Tab 1: Chat với AI
    │   - Giao diện messenger
    │   - Input nhập câu hỏi
    │   - Loading khi AI đang trả lời
    │   - Lịch sử chat (lưu vào Firestore)
    │   ↓ (Gửi câu hỏi)
    │   AI Response (Gemini API)
    │   - Trả lời về dinh dưỡng, tập luyện, sức khỏe
    │   - Format dễ đọc
    │
    └─→ Tab 2: AI Insights (Plan 6)
        - Phân tích dữ liệu người dùng
        - Gợi ý cá nhân hóa
        - Lịch sử insights
        - Thông báo khi có insight mới
```

### Luồng Mục tiêu (Plan 3):
```
Drawer → Mục tiêu
    ↓
Goals Screen
    - Tab: Đang theo dõi / Đã hoàn thành
    - Danh sách mục tiêu với progress
    - [Đặt mục tiêu mới] → Create Goal Screen
    - Thông báo khi đạt mục tiêu
```

### Luồng Kế hoạch Tập luyện (Plan 5):
```
Drawer → Kế hoạch Tập luyện
    ↓
Workout Plans Screen
    ├─→ Tab: Kế hoạch có sẵn
    │   - Danh sách: Chạy 5K, Giảm cân, Tăng sức bền, ...
    │   - Xem chi tiết (số tuần, bài tập mỗi ngày)
    │   - Bắt đầu kế hoạch
    │
    ├─→ Tab: Kế hoạch tùy chỉnh
    │   - Danh sách kế hoạch tự tạo
    │   - Tạo mới / Chỉnh sửa
    │   - Đặt lịch tập luyện
    │
    └─→ Tab: Đang thực hiện
        - Theo dõi tiến độ (% hoàn thành)
        - Đánh dấu hoàn thành bài tập trong ngày
        - Nhắc nhở khi đến giờ tập
```

### Luồng GPS Tracking nâng cao (Plan 4):
```
Activity Tab → GPS Routes
    ↓
GPS Routes List
    - Danh sách các buổi tập GPS đã lưu
    ↓ (Chọn một route)
GPS Route Detail Screen
    - Hiển thị bản đồ với polyline segments
    - Marker: Start (xanh dương), End (xanh lục)
    - Thống kê: thời gian, quãng đường, tốc độ TB, kcal
    - [Xuất PDF/Excel] → Drawer → Xuất dữ liệu
```

---

## Đề Xuất Cuối Cùng

### Bottom Navigation Bar (5 mục - Khuyến nghị)
**5 mục chính:**
1. 🏠 Dashboard
   - Tổng quan chỉ số hôm nay
   - Quick action: Bắt đầu tập
   - Hoạt động gần đây

2. 🏃 Hoạt động
   - Tab 1: Bắt đầu tập (Activity Selection)
   - Tab 2: Lịch sử (Activity History)
   - Tab 3: GPS Routes (Plan 4 - xem lại route trên bản đồ)

3. 📊 Thống kê
   - Biểu đồ xu hướng
   - BMI, BMR, TDEE
   - Streak
   - Thống kê chi tiết theo thời gian

4. 💬 AI Coach
   - Tab 1: Chat với AI (Plan 5)
   - Tab 2: AI Insights (Plan 6)

5. 👤 Profile
   - Thông tin cá nhân
   - Lịch sử cân nặng
   - Cài đặt (mở Drawer)

**Drawer Menu:**
- 🎯 Mục tiêu (Plan 3)
- 📋 Kế hoạch Tập luyện (Plan 5)
- 📤 Xuất dữ liệu (Plan 4)
- ⚙️ Cài đặt

**Ưu điểm:**
- ✅ Bao quát tất cả chức năng chính
- ✅ Activity Tracking dễ truy cập (tab riêng)
- ✅ Phù hợp với mobile
- ✅ Tách biệt rõ ràng giữa chức năng chính và phụ

---

## Lưu Ý

1. **Bottom Navigation Bar**: 
   - Giữ nguyên khi chuyển màn hình (không rebuild)
   - Mỗi tab có navigation stack riêng
   - Tab "Hoạt động" có TabBar bên trong (Bắt đầu tập / Lịch sử / GPS Routes)

2. **Drawer**: 
   - Mở từ AppBar hoặc gesture swipe
   - Chứa các chức năng nâng cao (Plan 4, 5, 6)

3. **FAB**: 
   - Có thể dùng trên Dashboard để "Bắt đầu tập ngay"
   - Hoặc Button lớn trong Dashboard

4. **TabBar**: 
   - Statistics screen: Ngày/Tuần/Tháng/Năm
   - Activity screen: Bắt đầu tập / Lịch sử / GPS Routes
   - AI Coach screen: Chat với AI / AI Insights
   - Goals screen (trong Drawer): Đang theo dõi / Đã hoàn thành

5. **Activity Tracking Flow**:
   - Activity Selection → GPS/Indoor Tracking → Popup (Xóa/Lưu) → Summary
   - Có thể quay lại Dashboard hoặc Activity History sau khi lưu

6. **GPS Tracking (Plan 4)**:
   - Tab "GPS Routes" chỉ hiển thị khi có dữ liệu GPS
   - Xem lại route trên bản đồ với polyline segments
   - Xuất PDF/Excel từ Drawer

7. **AI Coach (Plan 5 & 6)**:
   - Nằm trong Bottom Navigation Bar (dễ truy cập)
   - Tab 1: Chat với AI - Giao diện messenger, lưu lịch sử
   - Tab 2: AI Insights - Phân tích cá nhân hóa, gợi ý tự động

8. **Mục tiêu (Plan 3)**:
   - Chuyển vào Drawer Menu (không cần truy cập thường xuyên)
   - Có thể xem tiến độ mục tiêu trong Dashboard hoặc Statistics

---

> **Khuyến nghị**: Dùng **Bottom Navigation Bar 5 mục** + **Drawer menu** để bao quát tất cả chức năng từ Plan 1-6.

