# Luồng nghiệp vụ chính (User + Admin)

## Cách đọc
- Mỗi luồng tóm tắt: Mục tiêu → Các bước chính → File quan trọng → Điểm cần nhớ (để giải thích nhanh).

---

## 1) Đăng ký / Đăng nhập / Xác thực email
- **Mục tiêu**: Tạo tài khoản, đăng nhập, đảm bảo email hợp lệ.
- **Bước chính**:
  1. User nhập email/password (+ thông tin hồ sơ) → `register_page.dart`.
  2. Gọi `AuthViewModel` → `AuthRepository` → Firebase Auth tạo user.
  3. Gửi email verify, chuyển sang `email_verification_page.dart`.
  4. Đăng nhập: `login_page.dart` → `AuthViewModel.signIn()`; kiểm tra `status`.
- **File**: `lib/presentation/pages/auth/*.dart`, `lib/presentation/viewmodels/auth_view_model.dart`.
- **Điểm nhớ**: Nếu `status == blocked` → SnackBar đỏ + `UnlockRequestDialog`.
**Hỏi nhanh - trả lời gọn**:
- Email verify ở đâu? → `email_verification_page.dart`, gửi lại qua AuthViewModel.
- Chặn login blocked thế nào? → check status trong `AuthViewModel.signIn()`, UI `login_page.dart` show SnackBar + dialog.

## 2) Khóa tài khoản & Yêu cầu mở khóa
- **Mục tiêu**: Khi user bị khóa, cho phép gửi yêu cầu; admin duyệt.
- **User flow**:
  1. Login thấy `status = blocked` → `login_page.dart` hiển thị SnackBar đỏ + mở `UnlockRequestDialog`.
  2. Dialog gửi request → `UnlockRequestService.createRequest()` → `unlock_requests` (Firestore).
  3. Clear error để tránh lặp thông báo.
- **Admin flow**:
  1. `unlock_requests_page.dart`: bảng full-width, search, filter trạng thái.
  2. Duyệt/Từ chối/Sửa/Xóa: update `UnlockRequest` + (nếu duyệt) mở khóa user (`users.status = active`).
  3. Firestore rules: user chỉ create; admin read/update/delete.
- **File**: `lib/presentation/pages/auth/login_page.dart`, `lib/presentation/widgets/unlock_request_dialog.dart`, `lib/admin/pages/unlock_requests_page.dart`, `lib/core/services/unlock_request_service.dart`.
- **Điểm nhớ**: SnackBar đỏ trước dialog; rule cho phép delete bởi admin.
**Hỏi nhanh - trả lời gọn**:
- User gửi request bằng gì? → `UnlockRequestDialog` → `UnlockRequestService.createRequest()`.
- Admin duyệt ở đâu? → `unlock_requests_page.dart`, gọi service cập nhật request + mở khóa user.
- Rules? → User chỉ create; admin read/update/delete (`firestore.rules` đoạn unlock_requests).

## 3) Mục tiêu & Nhắc nhở (Goal + Notifications)
- **Mục tiêu**: Tạo mục tiêu, nhắc nhở đúng giờ, cảnh báo sắp hết hạn/quá hạn 1 lần.
- **Bước chính**:
  1. Tạo/Chỉnh sửa mục tiêu → `create_goal_page.dart` + `GoalFormViewModel`.
  2. Lưu mục tiêu → `GoalRepository` (Firestore).
  3. Lập lịch nhắc nhở → `goal_service.dart` + `notification_service.dart`.
     - Nếu giờ nhắc đã qua (tuần/tháng/năm) → gửi 1 thông báo ngay (sau 1 phút) + lên lịch hằng ngày từ ngày mai.
     - Nếu chưa qua giờ → lên lịch từ hôm nay, lặp hằng ngày.
  4. Cảnh báo “sắp hết hạn” / “quá hạn” chỉ 1 lần/goal (flag trong GoalService).
- **Hiển thị**:
  - `goals_page.dart` (danh sách, filter trạng thái, edit/delete).
  - `dashboard_page.dart` (user) hiển thị tiến độ, cảnh báo.
- **File**: `lib/core/services/goal_service.dart`, `lib/core/services/notification_service.dart`, `lib/presentation/pages/goals/*.dart`, `lib/presentation/viewmodels/goal_list_view_model.dart`.
- **Điểm nhớ**: One-shot cảnh báo; nhắc nhở daily cho non-daily goals khi chưa hoàn thành.
**Hỏi nhanh - trả lời gọn**:
- Nếu giờ đã qua? → Gửi ngay (delay 1 phút) + lên lịch lặp hằng ngày từ ngày mai.
- Gửi bao nhiêu lần cảnh báo hạn? → Mỗi loại “sắp hết hạn”/“quá hạn” chỉ 1 lần/goal (flag trong GoalService).
- File chính? → `goal_service.dart`, `notification_service.dart`.

## 4) Theo dõi hoạt động & GPS
- **Mục tiêu**: Theo dõi hoạt động trong/ngoài trời, lưu GPS route.
- **Bước chính**:
  1. Chọn hoạt động → `activity_selection_tab.dart`.
  2. Indoor tracking → `indoor_tracking_page.dart` + `IndoorTrackingViewModel` (timer, pause/resume, finish).
  3. Outdoor tracking → `outdoor_tracking_page.dart` + `OutdoorTrackingViewModel` + `GpsTrackingService` (polyline, quãng đường, tốc độ).
  4. Lưu `ActivitySession` + `GpsRoute` vào subcollections Firestore.
- **Xem lại**:
  - Lịch sử: `activity_history_tab.dart` (filter theo loại/thời gian).
  - Chi tiết: `activity_detail_page.dart` (thông tin + bản đồ route).
  - Routes: `gps_routes_tab.dart`.
- **File**: `lib/presentation/pages/activity/*.dart`, `lib/core/services/gps_tracking_service.dart`, `lib/data/repositories/firestore_activity_repository.dart`, `firestore_gps_route_repository.dart`.
- **Điểm nhớ**: Route lưu cùng userId; query theo user, không quét toàn bộ.
**Hỏi nhanh - trả lời gọn**:
- GPS tính quãng đường ở đâu? → `gps_tracking_service.dart` (polyline → distance/speed).
- Lưu route thế nào? → `FirestoreGpsRouteRepository` trong subcollection `gps_routes`.

## 5) Thống kê & Lịch sử cân nặng
- **Mục tiêu**: Cho user xem phân tích, biểu đồ, BMI, streak.
- **Bước chính**:
  1. `statistics_page.dart` dùng `StatisticsViewModel` lấy dữ liệu từ Activity/Goal/Streak/WeightHistory.
  2. Tính BMI, BMR/TDEE, streak, chọn khoảng thời gian (tuần/tháng/năm), chọn metric.
  3. Vẽ biểu đồ (ChartService) và hiển thị cards (BMI, streak, advanced metrics).
- **File**: `lib/presentation/pages/statistics/statistics_page.dart`, `lib/core/services/statistics_service.dart`, `chart_service.dart`, `history_service.dart`.
- **Điểm nhớ**: Tất cả query theo userId (subcollections) → tránh fan-out.
**Hỏi nhanh - trả lời gọn**:
- BMI/BMR/TDEE tính ở đâu? → `statistics_service.dart` (+ `health_calculator/advanced_health_calculator`).
- Chọn khoảng thời gian thế nào? → ViewModel lưu range (tuần/tháng/năm) và ngày chọn, truyền vào ChartService.

## 6) AI Coach (Chat + Insights)
- **Mục tiêu**: Tư vấn cá nhân hóa và sinh insights tự động.
- **Chat flow**:
  1. `ai_coach_page.dart` thiết lập providers cho `ChatViewModel` và `InsightsViewModel`.
  2. Chat tab: gửi tin nhắn → `ChatViewModel` → `GeminiService` → lưu vào `chat_history` (subcollection).
  3. Lịch sử chat: đọc từ `chat_history`; có thể tạo cuộc trò chuyện mới.
- **Insights flow**:
  1. `InsightsViewModel` dùng `AIInsightRepository` + `AICoachService` + `DataSummarizer`.
  2. Sinh insights dựa trên Activity/Goals/Weight → lưu `ai_insights`.
  3. Thông báo khi có insight mới (local notification).
- **File**: `lib/presentation/pages/ai_coach/*.dart`, `lib/presentation/viewmodels/chat_view_model.dart`, `insights_view_model.dart`, `lib/core/services/ai_coach_service.dart`, `data_summarizer.dart`, `gemini_service.dart`.
- **Điểm nhớ**: Tin nhắn đang embed trong `ChatConversation` (không tách bảng ChatMessage vì chưa cần query riêng).
**Hỏi nhanh - trả lời gọn**:
- AI lấy dữ liệu gì? → Activity, Goals, Weight, Profile (qua DataSummarizer/DataAnalyzer).
- Gọi AI ở đâu? → `AICoachService` sử dụng `GeminiService`.
- Lưu chat/insight ở đâu? → `chat_history`, `ai_insights` (subcollections).

## 7) Admin – Quản lý người dùng
- **Mục tiêu**: Search/filter user, khóa/mở khóa, cấp/thu hồi admin.
- **Bước chính**:
  1. `users_page.dart`: bảng full-width, search, filter trạng thái/vai trò.
  2. Thao tác:
     - Khóa/Mở khóa: update `users.status` (blocked/active).
     - Cấp/Thu hồi admin: update `users.role` (admin/user).
  3. Snackbar thông báo kết quả.
- **File**: `lib/admin/pages/users_page.dart`, `lib/admin/providers/auth_provider.dart`.
- **Điểm nhớ**: Confirm dialog trước khi khóa/mở/cấp/thu; màu badge phân biệt trạng thái/role.
**Hỏi nhanh - trả lời gọn**:
- Khóa/mở khóa hàm nào? → `_updateStatus` trong `users_page.dart` (update `users.status`).
- Cấp/thu admin hàm nào? → `_updateRole` trong `users_page.dart` (update `users.role`).

## 8) Admin – Quản lý yêu cầu mở khóa
- **Mục tiêu**: Duyệt/từ chối/sửa/xóa yêu cầu, mở khóa user khi duyệt.
- **Bước chính**:
  1. `unlock_requests_page.dart`: bảng full-width, search + filter trạng thái.
  2. Action:
     - Approve: set `UnlockRequest.status = approved`, đồng thời mở khóa user.
     - Reject: set `status = rejected`.
     - Edit: chỉnh ghi chú admin (note admin), trường “Ghi chú (user)” chỉ đọc.
     - Delete: xóa yêu cầu (rules cho phép admin delete).
  3. Snackbar thông báo thành công/thất bại.
- **File**: `lib/admin/pages/unlock_requests_page.dart`, `lib/core/services/unlock_request_service.dart`.
- **Điểm nhớ**: Menu filter offset xuống, nền trắng, rộng; bảng full-width không để khoảng trắng thừa.
**Hỏi nhanh - trả lời gọn**:
- Approve làm gì? → set request `approved` + mở khóa user.
- Edit dialog? → Cho sửa ghi chú admin, “Ghi chú (user)” read-only.
- Delete? → Cho phép admin xóa (rules đã mở).

## 9) Admin – Dashboard
- **Mục tiêu**: Quan sát nhanh tình trạng user hệ thống.
- **Bước chính**:
  1. `dashboard_page.dart`: Stream users → tính tổng user, user mới 7 ngày, active, blocked, admin.
  2. Hiển thị cards + donut chart + danh sách user mới nhất.
- **File**: `lib/admin/pages/dashboard_page.dart`.
- **Điểm nhớ**: Sắp xếp user mới theo `createdAt` (Timestamp) giảm dần.
**Hỏi nhanh - trả lời gọn**:
- Lấy số liệu ở đâu? → Stream `users` Firestore, tính toán ngay trong `dashboard_page.dart`.

---

## Checklist trình bày khi bảo vệ
- Luồng ưa thích để demo:  
  (1) Mục tiêu & nhắc nhở; (2) Khóa tài khoản & Unlock; (3) GPS tracking; (4) AI Coach (nếu có thời gian).
- Trục giải thích: **Flow → Service → Repository → Firestore → UI**.
- Nhấn mạnh:  
  - Nhắc nhở non-daily: gửi ngay nếu giờ đã qua + lặp hàng ngày.  
  - Cảnh báo sắp hết hạn/quá hạn: 1 lần/goal.  
  - Filter/search bảng admin (full-width, dropdown chỉnh lại offset/nền).  
  - Rules cho `unlock_requests`: user chỉ create; admin read/update/delete.

