## Kế hoạch triển khai Plan 3: Mục tiêu & Thống kê Chi tiết

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Mục tiêu", "Đặt mục tiêu", "Đang theo dõi", "Đã hoàn thành", "Tiến độ", "Thông báo", "Cài đặt", "BMR", "TDEE", v.v.

---

## ✅ Phase 1: Đặt mục tiêu (ĐÃ HOÀN THÀNH)

- **✅ 1.1 Tạo collection `goals`** trong Firestore:
  - userId, goalType, targetValue, currentValue, startDate, deadline, status, timeFrame, activityTypeFilter, direction, initialValue
- **✅ 1.2 Định nghĩa các loại mục tiêu:**
  - Weight goal: giảm/tăng X kg (với direction: 'increase' | 'decrease')
  - Distance goal: quãng đường theo timeFrame (daily/weekly/monthly/yearly)
  - Calories goal: kcal tiêu thụ theo timeFrame
  - Duration goal: thời gian tập theo timeFrame
- **✅ 1.3 Màn hình Create Goal:**
  - Chọn loại mục tiêu
  - Nhập giá trị mục tiêu
  - Chọn timeFrame (daily/weekly/monthly/yearly)
  - Chọn deadline (tùy chọn)
  - Chọn activity type filter (tùy chọn)
  - Validation (giá trị > 0, deadline > hôm nay)
- **✅ 1.4 Lưu mục tiêu vào Firestore:**
  - Tạo document trong `goals` collection
  - Status: 'active'
  - currentValue: 0 (ban đầu)

---

## ✅ Phase 2: Theo dõi tiến độ mục tiêu (ĐÃ HOÀN THÀNH)

- **✅ 2.1 Tạo `GoalService`** để quản lý mục tiêu:
  - Method `calculateProgress(goal)`: tính % hoàn thành tự động
  - Method `checkAndNotifyCompletedGoals(userId)`: kiểm tra và gửi notification khi goal completed
  - Method `setupGoalReminder(goal)`: setup reminder cho goal
  - Method `cancelExpiredGoalReminder(goal)`: hủy reminder cho goal đã hết hạn
- **✅ 2.2 Tính toán tiến độ tự động:**
  - Weight goal: so sánh weight hiện tại với target (có tính direction)
  - Distance/Calories/Duration: tổng hợp từ activities theo timeFrame và activityTypeFilter
  - Tự động cập nhật khi có activity session mới
- **✅ 2.3 Màn hình Goals với TabBar:**
  - **Lưu ý:** Màn hình Goals nằm trong Drawer Menu (không phải Bottom Navigation Bar)
  - Tab: "Đang theo dõi" (active goals)
  - Tab: "Đã hoàn thành" (completed goals)
  - Truy cập: Drawer → Mục tiêu
- **✅ 2.4 Hiển thị tiến độ:**
  - Card cho mỗi mục tiêu với `GoalCard` widget
  - CircularProgressIndicator hiển thị % hoàn thành
  - Hiển thị currentValue / targetValue
  - Hiển thị còn bao nhiêu để đạt mục tiêu
  - Hiển thị deadline và thời gian còn lại
- **✅ 2.5 Thông báo khi đạt mục tiêu:**
  - Kiểm tra tự động khi cập nhật dữ liệu
  - Nếu đạt mục tiêu → cập nhật status = 'completed'
  - Hiển thị thông báo "Chúc mừng bạn!" với tên hoạt động (không phải goal type)
  - Tự động cancel deadline notifications và daily reminder khi goal completed

---

## ✅ Phase 3: Thông báo nhắc nhở (ĐÃ HOÀN THÀNH)

- **✅ 3.1 Setup Scheduled Notifications:**
  - Dependencies: `flutter_local_notifications` và `timezone`
  - Khởi tạo timezone database khi app khởi động
  - Request notification permission (Android 13+)
  - Permissions trong AndroidManifest: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, WAKE_LOCK
- **✅ 3.2 Tạo `NotificationService`:**
  - Method `scheduleGoalDailyReminder(goalId, goalName, hour, minute, isDaily, deadline)`: Nhắc nhở mục tiêu hàng ngày
  - Method `showGoalCompletedNotification(goalName)`: Thông báo khi đạt mục tiêu
  - Method `scheduleGoalDeadlineWarningNotification(goalId, goalName, dateTime)`: Cảnh báo sắp hết hạn (6:00 AM 1 ngày trước)
  - Method `scheduleGoalDeadlineOverdueNotification(goalId, goalName, dateTime)`: Thông báo đã quá hạn (23:59:59 ngày deadline)
  - Method `cancelGoalDailyReminder(goalId)`: Hủy reminder
  - Method `cancelGoalDeadlineNotifications(goalId)`: Hủy deadline notifications
  - Method `getNotificationHistory(limit)`: Lấy lịch sử thông báo
  - Method `markAllAsRead()`: Đánh dấu tất cả đã đọc
  - Method `getUnreadCount()`: Đếm số thông báo chưa đọc
  - **Lưu ý**: Dùng scheduled notifications với `exactAllowWhileIdle` mode, fallback về `inexactAllowWhileIdle` nếu permission bị từ chối
- **✅ 3.3 Notification Popup trong Dashboard:**
  - Popup hiển thị tối đa 10 thông báo mới nhất
  - Badge đỏ hiển thị số thông báo chưa đọc
  - Tự động refresh mỗi 3 giây
  - Nút "Đánh dấu đã đọc" để xóa tất cả thông báo
  - Hiển thị relative time (ví dụ: "5 phút trước")
  - Icon và màu sắc theo loại thông báo
- **✅ 3.4 Màn hình Settings/Notifications:**
  - Toggle bật/tắt thông báo trong `GoalReminderDialog`
  - Chọn giờ nhắc nhở (TimePicker)
  - Reminder áp dụng cho tất cả goals (daily/weekly/monthly/yearly)
- **✅ 3.5 Xử lý thông báo:**
  - **Nhắc nhở mục tiêu**: Mỗi ngày vào giờ đã chọn (1 phút trước giờ đặt)
  - **Cảnh báo sắp hết hạn**: 6:00 AM 1 ngày trước deadline (chỉ cho weekly/monthly/yearly)
  - **Thông báo đã quá hạn**: 23:59:59 ngày deadline (cho tất cả goals)
  - **Thông báo đạt mục tiêu**: Ngay khi đạt (tự động từ Dashboard hoặc Goals page)
  - **Auto-cancel reminder**: Tự động hủy reminder khi deadline qua (với weekly/monthly/yearly goals)

---

## ✅ Phase 4: Tính toán chỉ số nâng cao (ĐÃ HOÀN THÀNH)

- **✅ 4.1 Tạo `AdvancedHealthCalculator` service:**
  - Method `calculateBMR(weight, height, age, gender)`: Tính BMR (Mifflin-St Jeor Equation)
  - Method `calculateTDEE(bmr, activityLevel)`: Tính TDEE dựa trên activity level
- **✅ 4.2 Xác định Activity Level:**
  - Tự động tính từ dữ liệu activities của user (weekly active minutes)
  - Phân loại: Sedentary, Lightly Active, Moderately Active, Very Active, Extremely Active
- **✅ 4.3 Hiển thị BMR và TDEE:**
  - Card "Chỉ số nâng cao" trong Statistics screen
  - Hiển thị: BMR (kcal/ngày), TDEE (kcal/ngày), Activity Level
  - Giải thích ngắn gọn về các chỉ số
- **✅ 4.4 Cập nhật tự động:**
  - Tính lại BMR khi cập nhật weight, height, age
  - Tính lại TDEE khi thay đổi activity level (tự động từ activities)

---

## ✅ Phase 5: Thống kê chi tiết theo thời gian (ĐÃ HOÀN THÀNH)

- **✅ 5.1 Tạo `StatisticsService`** để tính toán thống kê:
  - Method `getStats(userId, range, reference)`: Thống kê theo timeRange (day/week/month/year)
  - Tính toán cho cả kỳ hiện tại và kỳ trước để so sánh
- **✅ 5.2 Tính toán các chỉ số:**
  - Tổng quãng đường
  - Tổng kcal tiêu thụ
  - Tổng thời gian tập luyện
  - Trung bình mỗi ngày
  - Tỷ lệ tăng/giảm khi so sánh với kỳ liền trước (%)
- **✅ 5.3 Màn hình Statistics chi tiết:**
  - TabBar: Ngày, Tuần, Tháng, Năm
  - Card "So sánh với kỳ trước" hiển thị:
    - Chênh lệch tuyệt đối (+/-) cho Calories/Quãng đường/Thời gian tập
    - Phần trăm thay đổi (%)
    - Icon mũi tên lên/xuống để thể hiện xu hướng
  - Card "Thống kê trung bình" (đã đổi tên từ "Thống kê chi tiết") hiển thị:
    - Tổng và Trung bình mỗi ngày cho Calories/Quãng đường/Thời gian tập
    - Không hiển thị badge % (đã bỏ)
  - Biểu đồ (line/bar) thể hiện dữ liệu của kỳ đang chọn
  - Card "Tổng quan" hiển thị: Cao nhất, Thấp nhất (và Tổng, Trung bình cho các metric không phải weight)

---

## ✅ Phase 6: UI/UX và tối ưu (ĐÃ HOÀN THÀNH)

- **✅ 6.1 Animation:**
  - Smooth transition khi chuyển tab
  - Progress animation trong GoalCard
- **✅ 6.2 Empty states:**
  - Khi chưa có mục tiêu
  - Khi chưa có dữ liệu thống kê
- **✅ 6.3 Performance:**
  - Cache thống kê đã tính (`_detailedCache`)
  - Debounce `checkAndNotifyCompletedGoals` (chỉ check tối đa 1 lần mỗi 10 giây)
  - Tối ưu Timer.periodic (5 giây cho unread count, 3 giây cho popup refresh)
  - Chỉ update state khi history thực sự thay đổi
- **✅ 6.4 Error handling:**
  - Xử lý khi không có dữ liệu
  - Xử lý khi notification permission bị từ chối (fallback về inexact alarms)
  - Xử lý Firestore index errors (fetch tất cả goals rồi filter ở client)
- **✅ 6.5 Điều chỉnh phạm vi:**
  - ✅ Bỏ phần hiển thị "Cột mốc luyện tập" trong UI Statistics
  - ✅ Đổi tên "Thống kê chi tiết" thành "Thống kê trung bình"
  - ✅ Bỏ "Tổng" và "Trung bình" cho weight metric trong "Tổng quan"

---

## Cấu trúc File Đã Triển Khai

```
lib/
├── domain/
│   ├── entities/
│   │   └── goal.dart              # Entity Goal
│   └── repositories/
│       └── goal_repository.dart   # GoalRepository interface
├── data/
│   ├── models/
│   │   └── goal_model.dart        # GoalModel (Firestore)
│   └── repositories/
│       └── firestore_goal_repository.dart  # FirestoreGoalRepository
├── core/
│   ├── services/
│   │   ├── goal_service.dart      # GoalService ✅
│   │   ├── notification_service.dart  # NotificationService ✅
│   │   ├── advanced_health_calculator.dart  # AdvancedHealthCalculator ✅
│   │   └── statistics_service.dart  # StatisticsService ✅
│   └── helpers/
│       └── activity_type_helper.dart  # ActivityTypeHelper
├── presentation/
│   ├── pages/
│   │   ├── goals/
│   │   │   ├── goals_page.dart    # GoalsPage với TabBar ✅
│   │   │   ├── create_goal_page.dart  # CreateGoalPage ✅
│   │   │   └── goal_reminder_dialog.dart  # GoalReminderDialog ✅
│   │   ├── statistics/
│   │   │   └── statistics_page.dart  # StatisticsPage ✅
│   │   ├── dashboard/
│   │   │   └── dashboard_page.dart  # DashboardPage với notification popup ✅
│   │   └── settings/
│   │       └── notification_settings_page.dart  # NotificationSettingsPage ✅
│   ├── viewmodels/
│   │   ├── goal_list_view_model.dart  # GoalListViewModel ✅
│   │   ├── goal_form_view_model.dart  # GoalFormViewModel ✅
│   │   ├── statistics_view_model.dart  # StatisticsViewModel ✅
│   │   └── notification_settings_view_model.dart  # NotificationSettingsViewModel ✅
│   └── widgets/
│       └── goal_card.dart         # GoalCard widget ✅
```

---

## Schema Firestore

### Collection: `goals`
```dart
{
  id: string (document ID - auto),
  userId: string,
  goalType: string,  // 'weight' | 'distance' | 'calories' | 'duration'
  targetValue: double,  // Giá trị mục tiêu
  currentValue: double,  // Giá trị hiện tại (tự động tính)
  startDate: Timestamp,
  deadline: Timestamp?,  // Null nếu không có deadline
  timeFrame: string,  // 'daily' | 'weekly' | 'monthly' | 'yearly'
  activityTypeFilter: string?,  // Filter theo activity type (tùy chọn)
  direction: string?,  // 'increase' | 'decrease' (chỉ cho weight goal)
  initialValue: double?,  // Giá trị ban đầu (chỉ cho weight goal)
  status: string,  // 'active' | 'completed' | 'cancelled'
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
    // Goals collection
    match /goals/{goalId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Tính Năng Nâng Cao Đã Triển Khai

### 1. Notification System
- **Daily Reminder**: Nhắc nhở mỗi ngày theo giờ đã đặt (1 phút trước giờ đặt)
- **Deadline Warnings**: Cảnh báo sắp hết hạn (6:00 AM 1 ngày trước) và đã quá hạn (23:59:59 ngày deadline)
- **Goal Completed**: Thông báo ngay khi goal completed với tên hoạt động
- **Notification History**: Lưu lịch sử thông báo trong SharedPreferences
- **Unread Count Badge**: Badge đỏ hiển thị số thông báo chưa đọc
- **Auto-refresh Popup**: Popup tự động refresh mỗi 3 giây để catch notification mới

### 2. Goal Management
- **Auto Progress Calculation**: Tự động tính progress khi có activity session mới
- **Activity Type Filter**: Filter goals theo activity type cụ thể
- **Time Frame Support**: Hỗ trợ daily/weekly/monthly/yearly goals
- **Weight Goals**: Hỗ trợ tăng/giảm cân với direction và initialValue
- **Auto Cancel Reminders**: Tự động hủy reminder khi deadline qua hoặc goal completed

### 3. Statistics
- **Period Comparison**: So sánh với kỳ trước (ngày/tuần/tháng/năm)
- **Average Stats**: Hiển thị trung bình mỗi ngày
- **Chart Visualization**: Biểu đồ line/bar cho dữ liệu theo thời gian
- **Advanced Health Metrics**: BMR, TDEE, Activity Level

---

## Lưu Ý

- **Navigation:** Màn hình Goals nằm trong Drawer Menu, không phải Bottom Navigation Bar. Bottom Nav có 5 mục: Dashboard, Activity, Statistics, AI Coach, Profile.
- **Truy cập:** Người dùng mở Drawer và chọn "Mục tiêu" để xem và quản lý mục tiêu.
- **Tiến độ mục tiêu:** Tự động tính và cập nhật khi có activity session mới.
- **Notifications:** Hoạt động ngay cả khi app đóng (với exact alarm permission). Cần hướng dẫn user bật "Exact alarms" và "Unrestricted battery usage" trong Android settings.

---

## Trạng Thái Hoàn Thành

**✅ Plan 3: HOÀN THÀNH 100%**

Tất cả các phase đã được triển khai đầy đủ với các tính năng nâng cao:
- ✅ Goals management với đầy đủ tính năng
- ✅ Notification system hoàn chỉnh
- ✅ Statistics với so sánh kỳ trước
- ✅ Advanced health metrics (BMR, TDEE)
- ✅ UI/UX đã được tối ưu

> Có thể chuyển sang Plan 4: GPS Tracking Nâng Cao & Export.
