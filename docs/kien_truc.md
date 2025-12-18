# Kiến trúc & Tổ chức mã nguồn

## 1. Tổng quan kiến trúc
- **Clean Architecture (đa tầng)**
  - **Domain**: `lib/domain`
    - `entities`: Định nghĩa dữ liệu cốt lõi (User, ActivitySession, Goal, WeightRecord, GpsRoute, Streak, UnlockRequest, ChatConversation, AIInsight).
    - `repositories`: Interface (trừu tượng) cho tầng Data.
  - **Data**: `lib/data`
    - `models`: Map giữa Firestore ↔ Entity.
    - `repositories`: Triển khai repository (Firestore). Ví dụ: `firestore_goal_repository.dart`, `firestore_activity_repository.dart`, `firestore_unlock_request_repository.dart`.
  - **Core (Services/Helpers)**: `lib/core`
    - `services`: Nghiệp vụ phức tạp/đa nguồn dữ liệu. Ví dụ: `goal_service.dart`, `notification_service.dart`, `ai_coach_service.dart`, `gps_tracking_service.dart`.
    - `helpers`: Chuyển đổi/format dữ liệu.
  - **Presentation (UI + State)**: `lib/presentation`
    - `pages`: Màn hình Flutter.
    - `widgets`: Thành phần UI tái sử dụng.
    - `viewmodels`: `ChangeNotifier` quản lý state, gọi repositories/services.
    - `auth_gate.dart`: Kiểm tra trạng thái đăng nhập/khóa, điều hướng ban đầu.
  - **Admin**: `lib/admin`
    - `pages`: Dashboard, Users, Unlock Requests, Login, Profile.
    - `widgets`: `admin_layout.dart` (shell + sidebar).
    - `providers`: AuthProvider cho admin.

## 2. Nguyên tắc phụ thuộc
- UI (Presentation) **chỉ** biết tới ViewModel/Service/Repository interface.
- Service gọi Repository (interface) → Data layer triển khai (Firestore).
- Entity **không** phụ thuộc UI/Data.
- Hướng phụ thuộc: Presentation → Core/Domain → (interface) → Data.

## 3. State management
- **Provider + ChangeNotifier**: Đơn giản, dễ test.
- Mỗi màn hình có ViewModel riêng: `GoalListViewModel`, `StatisticsViewModel`, `ChatViewModel`, `InsightsViewModel`, `IndoorTrackingViewModel`, `OutdoorTrackingViewModel`, `NotificationSettingsViewModel`, `DashboardViewModel`, v.v.
- Admin dùng Provider tương tự (`AuthProvider`).
- **Dòng dữ liệu điển hình**: UI (Page) → ViewModel (notifyListeners) → Service/Repo → Firestore → stream/snapshot → Model → Entity → ViewModel → UI.
- **Cách lần dấu vết khi bị hỏi**:
  1) Tên màn hình? mở file trong `presentation/pages` (hoặc `admin/pages`).
  2) Tìm `ChangeNotifierProvider`/`context.watch` để biết ViewModel.
  3) Trong ViewModel, xem hàm public gọi Service hay Repository nào.
  4) Vào Service/Repository để thấy query Firestore (collection/subcollection).

## 4. Dịch vụ chính (Core Services)
- `goal_service.dart`: Logic mục tiêu, tính tiến độ, cảnh báo sắp hết hạn/đã quá hạn, lập lịch nhắc nhở.
- `notification_service.dart`: Local notifications, lên lịch nhắc nhở (daily + “gửi ngay nếu giờ đã qua” cho tuần/tháng/năm), log nội bộ.
- `ai_coach_service.dart` + `gemini_service.dart`: Sinh câu trả lời/insights từ dữ liệu người dùng.
- `gps_tracking_service.dart`: Theo dõi GPS, polyline, tính quãng đường/tốc độ.
- `unlock_request_service.dart`: Tạo/duyệt/từ chối yêu cầu mở khóa.

## 4.1 Một vài điểm sâu hay bị hỏi
- **Nhắc nhở non-daily**: nếu giờ đã qua → gửi ngay (delay 1 phút) + lên lịch lặp hằng ngày từ ngày mai; nếu chưa qua giờ → lên lịch từ hôm nay. File: `notification_service.dart`.
- **Cảnh báo hạn**: “sắp hết hạn” và “quá hạn” chỉ gửi 1 lần/goal (flag trong `goal_service.dart`).
- **Khóa/mở khóa**: UI gọi `UnlockRequestDialog` khi login bị blocked; admin duyệt ở `unlock_requests_page.dart`; cập nhật `users.status`. Service: `unlock_request_service.dart`.
- **GPS**: `gps_tracking_service.dart` tính quãng đường/tốc độ từ polyline; lưu route vào `gps_routes`.
- **AI**: `ai_coach_service.dart` + `gemini_service.dart` tạo câu trả lời; `data_summarizer.dart` gom dữ liệu user để sinh insight.

## 5. Luồng dữ liệu (tổng quát)
1) UI (Page/Widget) → ViewModel (ChangeNotifier)  
2) ViewModel → Service (business) hoặc Repository (CRUD)  
3) Repository → Firestore (Data source)  
4) Kết quả đổ ngược: Firestore snapshot → Model → Entity → ViewModel → UI

## 6. Firestore và collections chính
- Root:
  - `users`
  - `unlock_requests`
- Subcollections (theo `userId`):
  - `activities`, `gps_routes`, `goals`, `streaks`, `weight_history`, `chat_history`, `ai_insights`
- Mapping chi tiết xem `co_so_du_lieu.md`.

## 7. Thông báo & lịch nhắc
- Non-daily goals (tuần/tháng/năm): Nếu giờ nhắc đã qua → gửi 1 thông báo ngay (after 1 minute) + lên lịch nhắc hàng ngày từ ngày mai. Nếu chưa qua giờ → lên lịch từ hôm nay, lặp hàng ngày.
- Cảnh báo “sắp hết hạn” và “đã quá hạn”: Mỗi loại chỉ gửi **1 lần/goal** (dùng flag trong `GoalService`).

## 8. Quản lý khóa tài khoản & mở khóa
- Khi login/status = `blocked`: SnackBar đỏ + `UnlockRequestDialog` để gửi yêu cầu.  
- Admin xử lý ở trang Unlock Requests: duyệt/từ chối, mở khóa user (update `users.status`).
- Firestore rules cho `unlock_requests`: user chỉ được create; admin (authenticated) được read/update/delete.

## 9. Tổ chức UI chính
- **User app** (Flutter mobile):
  - Auth: Login/Register/Email verify/Change password.
  - Tabs/pages: Activity (3 tab), Goals, Dashboard, Statistics, AI Coach, Profile, Settings.
  - Dialogs: Goal reminder, Unlock request, Notifications.
- **Admin web** (Flutter web):
  - Dashboard: thống kê user, biểu đồ, top user mới.
  - Users: bảng full-width, search, filter trạng thái/vai trò, khóa/mở khóa, cấp/thu hồi admin.
  - Unlock Requests: bảng full-width, search, filter trạng thái, duyệt/từ chối/sửa/xóa.

## 10. Mẹo trình bày khi bảo vệ
- Giải thích theo trục: **Luồng nghiệp vụ** (flow) → **Service** → **Repository/Firestore** → **UI**.
- Chọn 2–3 flow tiêu biểu để nói kỹ: (1) Mục tiêu & nhắc nhở; (2) Khóa tài khoản & Unlock; (3) GPS tracking & lưu route; (4) AI Coach & insights (nếu cần show AI).

