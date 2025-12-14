# TỔNG HỢP CHỨC NĂNG HỆ THỐNG FITNESS APP

## MỤC LỤC

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Chức năng dành cho User (Người dùng)](#2-chức-năng-dành-cho-user-người-dùng)
3. [Chức năng dành cho Admin (Quản trị viên)](#3-chức-năng-dành-cho-admin-quản-trị-viên)
4. [Công nghệ và Kiến trúc](#4-công-nghệ-và-kiến-trúc)
5. [Cơ sở dữ liệu](#5-cơ-sở-dữ-liệu)

---

## 1. TỔNG QUAN HỆ THỐNG

### 1.1. Giới thiệu
Hệ thống Fitness App là một ứng dụng di động được xây dựng bằng Flutter, hỗ trợ người dùng theo dõi và quản lý các hoạt động thể thao, mục tiêu fitness, và nhận tư vấn từ AI Coach. Hệ thống bao gồm 2 phần chính:
- **Mobile App (Flutter)**: Dành cho người dùng cuối
- **Admin Panel (Web Flutter)**: Dành cho quản trị viên

### 1.2. Đối tượng sử dụng
- **User (Người dùng)**: Người dùng cuối sử dụng ứng dụng di động để theo dõi fitness
- **Admin (Quản trị viên)**: Quản lý người dùng và hệ thống thông qua web panel

---

## 2. CHỨC NĂNG DÀNH CHO USER (NGƯỜI DÙNG)

### 2.1. Xác thực và Quản lý Tài khoản

#### 2.1.1. Đăng ký tài khoản
- **Mô tả**: Người dùng có thể tạo tài khoản mới bằng email và mật khẩu
- **Chi tiết**:
  - Nhập email, mật khẩu, xác nhận mật khẩu
  - Nhập thông tin cá nhân: Họ tên, ngày sinh, giới tính, chiều cao, cân nặng
  - Xác thực email qua email verification
  - Validation đầy đủ các trường nhập liệu
  - Hiển thị lỗi rõ ràng khi đăng ký thất bại
- **File liên quan**: `lib/presentation/pages/auth/register_page.dart`

#### 2.1.2. Đăng nhập
- **Mô tả**: Người dùng đăng nhập vào hệ thống bằng email và mật khẩu
- **Chi tiết**:
  - Đăng nhập bằng email/password
  - Xử lý trường hợp tài khoản bị khóa (hiển thị dialog yêu cầu mở khóa)
  - Lưu trạng thái đăng nhập (auto-login)
  - Quên mật khẩu (nếu có)
  - Validation email và mật khẩu
- **File liên quan**: `lib/presentation/pages/auth/login_page.dart`

#### 2.1.3. Xác thực email
- **Mô tả**: Xác thực email sau khi đăng ký
- **Chi tiết**:
  - Gửi email xác thực tự động sau đăng ký
  - Trang xác thực email với nút gửi lại email
  - Kiểm tra trạng thái xác thực
- **File liên quan**: `lib/presentation/pages/auth/email_verification_page.dart`

#### 2.1.4. Đổi mật khẩu
- **Mô tả**: Người dùng có thể đổi mật khẩu của mình
- **Chi tiết**:
  - Nhập mật khẩu cũ, mật khẩu mới, xác nhận mật khẩu mới
  - Validation mật khẩu mới (độ dài, độ mạnh)
  - Xác nhận trước khi đổi
- **File liên quan**: `lib/presentation/pages/auth/change_password_page.dart`

#### 2.1.5. Đăng xuất
- **Mô tả**: Người dùng có thể đăng xuất khỏi hệ thống
- **Chi tiết**:
  - Xóa session và quay về màn hình đăng nhập
  - Xóa dữ liệu local (nếu cần)

---

### 2.2. Dashboard (Tổng quan)

#### 2.2.1. Màn hình tổng quan
- **Mô tả**: Hiển thị tổng quan các thông tin quan trọng của người dùng
- **Chi tiết**:
  - **Thống kê nhanh**:
    - Tổng số hoạt động hôm nay
    - Tổng số mục tiêu đang theo dõi
    - Chuỗi ngày liên tiếp (Streak) hiện tại
    - Cân nặng hiện tại và BMI
  - **Hoạt động gần đây**: Danh sách các hoạt động thể thao gần nhất
  - **Mục tiêu sắp hết hạn**: Cảnh báo các mục tiêu sắp đến deadline
  - **Thông báo**: Hiển thị các thông báo quan trọng (mục tiêu sắp hết hạn, mục tiêu đã quá hạn, nhắc nhở)
  - **Refresh**: Kéo xuống để làm mới dữ liệu
- **File liên quan**: `lib/presentation/pages/dashboard/dashboard_page.dart`, `lib/presentation/viewmodels/dashboard_view_model.dart`

#### 2.2.2. Thông báo
- **Mô tả**: Hệ thống thông báo tích hợp trong Dashboard
- **Chi tiết**:
  - Thông báo mục tiêu sắp hết hạn
  - Thông báo mục tiêu đã quá hạn
  - Thông báo nhắc nhở mục tiêu (theo giờ đã đặt)
  - Hiển thị icon và màu sắc phân biệt theo loại thông báo
  - Xem chi tiết thông báo

---

### 2.3. Quản lý Hoạt động (Activity)

#### 2.3.1. Bắt đầu hoạt động
- **Mô tả**: Người dùng có thể bắt đầu theo dõi một hoạt động thể thao
- **Chi tiết**:
  - **Chọn loại hoạt động**:
    - Hoạt động trong nhà: Chạy bộ, Đạp xe, Đi bộ, Nhảy dây, Plank, Gập bụng, Chống đẩy, Yoga, v.v.
    - Hoạt động ngoài trời: Chạy bộ, Đạp xe, Đi bộ (với GPS tracking)
  - **Thiết lập mục tiêu**:
    - Thời gian (phút)
    - Quãng đường (km) - cho hoạt động ngoài trời
    - Số lần/số hiệp - cho một số hoạt động
  - **Bắt đầu tracking**: Bấm nút bắt đầu để bắt đầu theo dõi
- **File liên quan**: `lib/presentation/pages/activity/activity_selection_tab.dart`

#### 2.3.2. Theo dõi hoạt động trong nhà (Indoor Tracking)
- **Mô tả**: Theo dõi các hoạt động thể thao trong nhà
- **Chi tiết**:
  - **Timer**: Đếm ngược/đếm lên thời gian
  - **Thông tin hiển thị**:
    - Thời gian đã tập
    - Quãng đường (nếu có)
    - Số lần/số hiệp (nếu có)
    - Nhịp tim (nếu có thiết bị)
  - **Điều khiển**:
    - Tạm dừng/Tiếp tục
    - Kết thúc hoạt động
  - **Lưu tự động**: Tự động lưu khi kết thúc
- **File liên quan**: `lib/presentation/pages/activity/indoor_tracking_page.dart`, `lib/presentation/viewmodels/indoor_tracking_view_model.dart`

#### 2.3.3. Theo dõi hoạt động ngoài trời (Outdoor Tracking với GPS)
- **Mô tả**: Theo dõi các hoạt động ngoài trời với GPS tracking
- **Chi tiết**:
  - **GPS Tracking**:
    - Theo dõi vị trí real-time
    - Vẽ bản đồ tuyến đường đã đi
    - Tính toán quãng đường tự động
    - Hiển thị tốc độ trung bình, tốc độ hiện tại
  - **Thông tin hiển thị**:
    - Thời gian đã tập
    - Quãng đường (km)
    - Tốc độ trung bình (km/h)
    - Tốc độ hiện tại (km/h)
    - Độ cao (nếu có)
  - **Bản đồ**:
    - Hiển thị bản đồ với marker vị trí hiện tại
    - Vẽ polyline tuyến đường đã đi
    - Zoom in/out
  - **Điều khiển**:
    - Tạm dừng/Tiếp tục
    - Kết thúc hoạt động
  - **Lưu GPS Route**: Tự động lưu tuyến đường GPS khi kết thúc
- **File liên quan**: `lib/presentation/pages/activity/outdoor_tracking_page.dart`, `lib/presentation/viewmodels/outdoor_tracking_view_model.dart`, `lib/core/services/gps_tracking_service.dart`

#### 2.3.4. Xem chi tiết hoạt động
- **Mô tả**: Xem thông tin chi tiết của một hoạt động đã lưu
- **Chi tiết**:
  - Thông tin cơ bản: Loại hoạt động, thời gian, quãng đường, ngày giờ
  - Bản đồ GPS (nếu có): Hiển thị tuyến đường đã đi
  - Chỉnh sửa: Có thể chỉnh sửa thông tin hoạt động
  - Xóa: Có thể xóa hoạt động
- **File liên quan**: `lib/presentation/pages/activity/activity_detail_page.dart`

#### 2.3.5. Lịch sử hoạt động
- **Mô tả**: Xem danh sách tất cả các hoạt động đã thực hiện
- **Chi tiết**:
  - **Lọc và sắp xếp**:
    - Lọc theo loại hoạt động
    - Lọc theo khoảng thời gian (hôm nay, tuần này, tháng này, tùy chọn)
    - Sắp xếp theo ngày (mới nhất/cũ nhất)
  - **Hiển thị**:
    - Danh sách dạng card hoặc list
    - Thông tin: Loại hoạt động, thời gian, quãng đường, ngày giờ
    - Icon phân biệt loại hoạt động
  - **Tìm kiếm**: Tìm kiếm theo loại hoạt động
  - **Xem chi tiết**: Tap vào item để xem chi tiết
- **File liên quan**: `lib/presentation/pages/activity/activity_history_tab.dart`, `lib/presentation/viewmodels/activity_history_view_model.dart`

#### 2.3.6. Quản lý GPS Routes
- **Mô tả**: Xem và quản lý các tuyến đường GPS đã lưu
- **Chi tiết**:
  - **Danh sách routes**:
    - Hiển thị tất cả các tuyến đường GPS
    - Thông tin: Ngày giờ, quãng đường, thời gian, loại hoạt động
  - **Xem chi tiết route**:
    - Bản đồ hiển thị tuyến đường
    - Thống kê: Quãng đường, thời gian, tốc độ trung bình, tốc độ tối đa
    - Xóa route
  - **Lọc**: Lọc theo loại hoạt động, khoảng thời gian
- **File liên quan**: `lib/presentation/pages/activity/gps_routes_tab.dart`

---

### 2.4. Quản lý Mục tiêu (Goals)

#### 2.4.1. Tạo mục tiêu mới
- **Mô tả**: Người dùng có thể tạo các mục tiêu fitness mới
- **Chi tiết**:
  - **Loại mục tiêu**:
    - **Theo ngày**: Mục tiêu cần hoàn thành trong 1 ngày
    - **Theo tuần**: Mục tiêu cần hoàn thành trong 1 tuần
    - **Theo tháng**: Mục tiêu cần hoàn thành trong 1 tháng
    - **Theo năm**: Mục tiêu cần hoàn thành trong 1 năm
  - **Loại chỉ tiêu**:
    - Tổng thời gian tập (phút)
    - Tổng quãng đường (km)
    - Tổng số lần tập
    - Giảm cân (kg)
    - Tăng cân (kg)
    - Giữ cân (kg)
  - **Thiết lập**:
    - Tên mục tiêu
    - Mô tả (tùy chọn)
    - Giá trị mục tiêu (ví dụ: 30 phút, 5km, 10kg)
    - Ngày bắt đầu
    - Ngày kết thúc (tự động tính theo loại mục tiêu)
  - **Nhắc nhở**:
    - Bật/tắt nhắc nhở
    - Thiết lập giờ nhắc nhở (giờ:phút)
    - Nhắc nhở mỗi ngày vào giờ đã đặt (cho mục tiêu tuần/tháng/năm)
- **File liên quan**: `lib/presentation/pages/goals/create_goal_page.dart`, `lib/presentation/viewmodels/goal_form_view_model.dart`

#### 2.4.2. Xem danh sách mục tiêu
- **Mô tả**: Xem tất cả các mục tiêu đang theo dõi
- **Chi tiết**:
  - **Lọc**:
    - Tất cả mục tiêu
    - Mục tiêu đang thực hiện
    - Mục tiêu đã hoàn thành
    - Mục tiêu đã quá hạn
  - **Hiển thị**:
    - Card mục tiêu với thông tin:
      - Tên mục tiêu
      - Loại mục tiêu và chỉ tiêu
      - Tiến độ (progress bar)
      - Giá trị hiện tại / Giá trị mục tiêu
      - Ngày bắt đầu và kết thúc
      - Trạng thái (đang thực hiện, đã hoàn thành, quá hạn)
    - Màu sắc phân biệt trạng thái
  - **Thao tác**:
    - Xem chi tiết
    - Chỉnh sửa mục tiêu
    - Xóa mục tiêu
- **File liên quan**: `lib/presentation/pages/goals/goals_page.dart`, `lib/presentation/viewmodels/goal_list_view_model.dart`

#### 2.4.3. Chỉnh sửa mục tiêu
- **Mô tả**: Cập nhật thông tin mục tiêu đã tạo
- **Chi tiết**:
  - Chỉnh sửa tất cả các thông tin (tương tự tạo mới)
  - Cập nhật tiến độ tự động dựa trên hoạt động
  - Lưu thay đổi
- **File liên quan**: `lib/presentation/pages/goals/create_goal_page.dart` (dùng chung với tạo mới)

#### 2.4.4. Xóa mục tiêu
- **Mô tả**: Xóa mục tiêu không còn cần thiết
- **Chi tiết**:
  - Xác nhận trước khi xóa
  - Xóa mục tiêu và tất cả dữ liệu liên quan
- **File liên quan**: `lib/presentation/pages/goals/goals_page.dart`

#### 2.4.5. Nhắc nhở mục tiêu
- **Mô tả**: Hệ thống tự động nhắc nhở người dùng về mục tiêu
- **Chi tiết**:
  - **Nhắc nhở theo giờ đã đặt**:
    - Cho mục tiêu tuần/tháng/năm
    - Nhắc nhở mỗi ngày vào đúng giờ đã thiết lập
    - Chỉ nhắc nhở nếu mục tiêu chưa hoàn thành
  - **Thông báo**:
    - Local notification
    - Hiển thị dialog khi mở app
    - Thông báo trong Dashboard
  - **Dialog nhắc nhở**:
    - Hiển thị thông tin mục tiêu
    - Tiến độ hiện tại
    - Nút "Đã hiểu"
- **File liên quan**: `lib/presentation/pages/goals/goal_reminder_dialog.dart`, `lib/core/services/goal_service.dart`, `lib/core/services/notification_service.dart`

---

### 2.5. Thống kê (Statistics)

#### 2.5.1. Thống kê tổng quan
- **Mô tả**: Xem các thống kê và phân tích về hoạt động fitness
- **Chi tiết**:
  - **BMI Card**:
    - Chỉ số BMI hiện tại
    - Phân loại (Thiếu cân, Bình thường, Thừa cân, Béo phì)
    - Cân nặng và chiều cao
    - Mục tiêu BMI (nếu có)
  - **Advanced Health Metrics**:
    - BMR (Basal Metabolic Rate)
    - TDEE (Total Daily Energy Expenditure)
    - Body Fat Percentage (ước tính)
    - Lean Body Mass
  - **Streak Card**:
    - Chuỗi ngày liên tiếp hiện tại
    - Chuỗi ngày dài nhất
    - Lịch sử streak
- **File liên quan**: `lib/presentation/pages/statistics/statistics_page.dart`, `lib/presentation/viewmodels/statistics_view_model.dart`

#### 2.5.2. Biểu đồ thống kê
- **Mô tả**: Hiển thị dữ liệu dưới dạng biểu đồ
- **Chi tiết**:
  - **Chọn khoảng thời gian**:
    - Tuần (chọn tuần cụ thể)
    - Tháng (chọn tháng cụ thể)
    - Năm (chọn năm cụ thể)
  - **Chọn chỉ số**:
    - Tổng thời gian tập (phút)
    - Tổng quãng đường (km)
    - Tổng số lần tập
    - Cân nặng (kg)
    - BMI
  - **Biểu đồ**:
    - Line chart (đường)
    - Bar chart (cột)
    - Hiển thị giá trị trên mỗi điểm
    - Zoom và pan
  - **Thống kê**:
    - Giá trị trung bình
    - Giá trị tối đa
    - Giá trị tối thiểu
    - Tổng giá trị
- **File liên quan**: `lib/presentation/pages/statistics/statistics_page.dart`, `lib/core/services/chart_service.dart`, `lib/core/services/statistics_service.dart`

#### 2.5.3. Lịch sử cân nặng
- **Mô tả**: Xem và quản lý lịch sử cân nặng
- **Chi tiết**:
  - **Xem lịch sử**:
    - Danh sách tất cả các lần ghi nhận cân nặng
    - Sắp xếp theo ngày (mới nhất/cũ nhất)
    - Biểu đồ xu hướng cân nặng
  - **Thêm cân nặng mới**:
    - Nhập cân nặng (kg)
    - Chọn ngày (mặc định hôm nay)
    - Lưu
  - **Chỉnh sửa/Xóa**: Có thể chỉnh sửa hoặc xóa bản ghi
- **File liên quan**: `lib/presentation/pages/profile/weight_history_page.dart`

---

### 2.6. AI Coach

#### 2.6.1. Chat với AI
- **Mô tả**: Trò chuyện với AI Coach để nhận tư vấn về fitness
- **Chi tiết**:
  - **Giao diện chat**:
    - Danh sách tin nhắn (user và AI)
    - Input field để nhập câu hỏi
    - Nút gửi
  - **Tính năng**:
    - AI phân tích dữ liệu người dùng (hoạt động, mục tiêu, cân nặng)
    - Đưa ra lời khuyên cá nhân hóa
    - Trả lời câu hỏi về fitness, dinh dưỡng, tập luyện
    - Gợi ý bài tập phù hợp
  - **Lịch sử chat**:
    - Lưu lịch sử hội thoại
    - Xem lại các cuộc hội thoại trước
    - Tạo cuộc hội thoại mới
  - **Context-aware**: AI hiểu được ngữ cảnh dựa trên dữ liệu người dùng
- **File liên quan**: `lib/presentation/pages/ai_coach/chat_tab.dart`, `lib/presentation/viewmodels/chat_view_model.dart`, `lib/core/services/ai_coach_service.dart`, `lib/core/services/gemini_service.dart`

#### 2.6.2. AI Insights
- **Mô tả**: Nhận các insights tự động từ AI dựa trên dữ liệu người dùng
- **Chi tiết**:
  - **Tự động phân tích**:
    - AI phân tích dữ liệu hoạt động, mục tiêu, cân nặng
    - Tạo insights tự động
    - Lưu vào database
  - **Hiển thị insights**:
    - Danh sách insights
    - Tiêu đề và nội dung
    - Ngày tạo
    - Xem chi tiết
  - **Loại insights**:
    - Phân tích xu hướng hoạt động
    - Đánh giá tiến độ mục tiêu
    - Gợi ý cải thiện
    - Cảnh báo sức khỏe
  - **Thông báo**: Thông báo khi có insight mới
- **File liên quan**: `lib/presentation/pages/ai_coach/insights_tab.dart`, `lib/presentation/viewmodels/insights_view_model.dart`, `lib/core/services/data_analyzer.dart`, `lib/core/services/data_summarizer.dart`

#### 2.6.3. Xem chi tiết Insight
- **Mô tả**: Xem nội dung chi tiết của một insight
- **Chi tiết**:
  - Hiển thị đầy đủ nội dung insight
  - Ngày tạo
  - Đánh dấu đã đọc
  - Xóa insight
- **File liên quan**: `lib/presentation/pages/ai_coach/insight_detail_screen.dart`

---

### 2.7. Hồ sơ cá nhân (Profile)

#### 2.7.1. Xem hồ sơ
- **Mô tả**: Xem thông tin cá nhân của người dùng
- **Chi tiết**:
  - **Thông tin cơ bản**:
    - Họ tên
    - Email
    - Ngày sinh
    - Giới tính
    - Chiều cao
    - Cân nặng hiện tại
    - Ảnh đại diện (nếu có)
  - **Thống kê nhanh**:
    - Tổng số hoạt động
    - Tổng số mục tiêu
    - Streak hiện tại
    - BMI
  - **Thao tác**:
    - Chỉnh sửa hồ sơ
    - Đổi mật khẩu
    - Đăng xuất
- **File liên quan**: `lib/presentation/pages/profile/profile_page.dart`, `lib/presentation/viewmodels/user_profile_view_model.dart`

#### 2.7.2. Chỉnh sửa hồ sơ
- **Mô tả**: Cập nhật thông tin cá nhân
- **Chi tiết**:
  - Chỉnh sửa: Họ tên, ngày sinh, giới tính, chiều cao, cân nặng
  - Upload ảnh đại diện (nếu có)
  - Lưu thay đổi
  - Validation các trường
- **File liên quan**: `lib/presentation/pages/profile/edit_profile_page.dart`

#### 2.7.3. Lịch sử cân nặng
- **Mô tả**: Xem và quản lý lịch sử cân nặng (đã mô tả ở phần Thống kê)
- **File liên quan**: `lib/presentation/pages/profile/weight_history_page.dart`

---

### 2.8. Cài đặt (Settings)

#### 2.8.1. Cài đặt thông báo
- **Mô tả**: Quản lý các cài đặt thông báo
- **Chi tiết**:
  - Bật/tắt thông báo mục tiêu
  - Bật/tắt thông báo nhắc nhở
  - Cài đặt giờ nhắc nhở mặc định
  - Quyền thông báo (yêu cầu quyền từ hệ thống)
- **File liên quan**: `lib/presentation/pages/settings/notification_settings_page.dart`, `lib/presentation/viewmodels/notification_settings_view_model.dart`

---

### 2.9. Xử lý Tài khoản bị khóa

#### 2.9.1. Yêu cầu mở khóa
- **Mô tả**: Khi tài khoản bị khóa, người dùng có thể gửi yêu cầu mở khóa
- **Chi tiết**:
  - **Dialog hiển thị khi đăng nhập**:
    - Thông báo tài khoản đã bị khóa
    - Nút "Gửi yêu cầu mở khóa"
  - **Form yêu cầu mở khóa**:
    - Nhập lý do yêu cầu mở khóa
    - Nhập ghi chú (tùy chọn)
    - Gửi yêu cầu
  - **Trạng thái yêu cầu**:
    - Đang chờ duyệt
    - Đã duyệt
    - Đã từ chối
  - **Thông báo**: Thông báo khi yêu cầu được duyệt/từ chối
- **File liên quan**: `lib/presentation/pages/auth/login_page.dart`, `lib/core/services/unlock_request_service.dart`

---

## 3. CHỨC NĂNG DÀNH CHO ADMIN (QUẢN TRỊ VIÊN)

### 3.1. Xác thực Admin

#### 3.1.1. Đăng nhập Admin
- **Mô tả**: Admin đăng nhập vào hệ thống quản trị
- **Chi tiết**:
  - Đăng nhập bằng email/password
  - Kiểm tra quyền admin (role = 'admin')
  - Chỉ cho phép admin đăng nhập
  - Lưu trạng thái đăng nhập
- **File liên quan**: `lib/admin/pages/login_page.dart`, `lib/admin/providers/auth_provider.dart`

#### 3.1.2. Đăng xuất
- **Mô tả**: Admin đăng xuất khỏi hệ thống
- **Chi tiết**:
  - Xóa session
  - Quay về màn hình đăng nhập

---

### 3.2. Dashboard Admin (Tổng quan)

#### 3.2.1. Thống kê tổng quan
- **Mô tả**: Hiển thị các thống kê tổng quan về hệ thống
- **Chi tiết**:
  - **Thẻ thống kê**:
    - Tổng số user
    - User mới (7 ngày gần nhất)
    - Số user đang hoạt động
    - Số user đã khóa
    - Số admin
  - **Biểu đồ**:
    - Biểu đồ tròn (Donut chart) phân bổ trạng thái user (Active, Blocked, Admin)
    - Màu sắc phân biệt
  - **Danh sách user mới nhất**:
    - Top 5 user mới đăng ký gần nhất
    - Thông tin: Tên, email, ngày đăng ký
    - Link đến trang quản lý user
- **File liên quan**: `lib/admin/pages/dashboard_page.dart`

---

### 3.3. Quản lý Người dùng (Users Management)

#### 3.3.1. Danh sách người dùng
- **Mô tả**: Xem danh sách tất cả người dùng trong hệ thống
- **Chi tiết**:
  - **Hiển thị**:
    - Bảng danh sách user với các cột:
      - Tên
      - Email
      - Trạng thái (Active/Blocked)
      - Vai trò (User/Admin)
      - Ngày đăng ký
      - Thao tác
  - **Tìm kiếm**:
    - Tìm kiếm theo tên hoặc email
    - Tìm kiếm real-time
  - **Lọc**:
    - Lọc theo trạng thái (Tất cả, Đang hoạt động, Đã khóa)
    - Lọc theo vai trò (Tất cả, User, Admin)
  - **Sắp xếp**: Sắp xếp theo ngày đăng ký (mới nhất/cũ nhất)
- **File liên quan**: `lib/admin/pages/users_page.dart`

#### 3.3.2. Khóa/Mở khóa tài khoản
- **Mô tả**: Admin có thể khóa hoặc mở khóa tài khoản người dùng
- **Chi tiết**:
  - **Khóa tài khoản**:
    - Chọn user cần khóa
    - Xác nhận trước khi khóa
    - Cập nhật trạng thái = 'blocked'
    - User không thể đăng nhập sau khi bị khóa
  - **Mở khóa tài khoản**:
    - Chọn user cần mở khóa
    - Xác nhận trước khi mở khóa
    - Cập nhật trạng thái = 'active'
    - User có thể đăng nhập lại
  - **Thông báo**: Hiển thị thông báo thành công/thất bại
- **File liên quan**: `lib/admin/pages/users_page.dart`

#### 3.3.3. Cấp/Thu hồi quyền Admin
- **Mô tả**: Admin có thể cấp hoặc thu hồi quyền admin cho user
- **Chi tiết**:
  - **Cấp quyền Admin**:
    - Chọn user cần cấp quyền
    - Xác nhận (có cảnh báo bảo mật)
    - Cập nhật role = 'admin'
    - User có thể đăng nhập vào admin panel
  - **Thu hồi quyền Admin**:
    - Chọn admin cần thu hồi quyền
    - Xác nhận
    - Cập nhật role = 'user'
    - User không thể đăng nhập vào admin panel nữa
  - **Cảnh báo**: Cảnh báo về rủi ro bảo mật khi cấp quyền admin
- **File liên quan**: `lib/admin/pages/users_page.dart`

#### 3.3.4. Xem chi tiết người dùng
- **Mô tả**: Xem thông tin chi tiết của một người dùng
- **Chi tiết**:
  - Thông tin cá nhân: Tên, email, ngày sinh, giới tính, chiều cao, cân nặng
  - Thống kê: Tổng số hoạt động, tổng số mục tiêu, streak
  - Lịch sử: Các hoạt động gần đây, mục tiêu đang theo dõi
  - (Có thể mở rộng thêm trong tương lai)

---

### 3.4. Quản lý Yêu cầu Mở khóa (Unlock Requests)

#### 3.4.1. Danh sách yêu cầu mở khóa
- **Mô tả**: Xem tất cả các yêu cầu mở khóa từ người dùng
- **Chi tiết**:
  - **Hiển thị**:
    - Bảng danh sách yêu cầu với các cột:
      - Tên người dùng
      - Email
      - Lý do
      - Ghi chú
      - Trạng thái (Đang chờ, Đã duyệt, Đã từ chối)
      - Ngày gửi
      - Thao tác
  - **Tìm kiếm**:
    - Tìm kiếm theo email hoặc tên người dùng
    - Tìm kiếm real-time
  - **Lọc**:
    - Lọc theo trạng thái (Tất cả, Đang chờ, Đã duyệt, Đã từ chối)
  - **Màu sắc phân biệt**:
    - Đang chờ: Màu vàng/cam
    - Đã duyệt: Màu xanh lá
    - Đã từ chối: Màu đỏ
- **File liên quan**: `lib/admin/pages/unlock_requests_page.dart`

#### 3.4.2. Duyệt yêu cầu mở khóa
- **Mô tả**: Admin duyệt yêu cầu mở khóa và tự động mở khóa tài khoản
- **Chi tiết**:
  - **Xem chi tiết yêu cầu**:
    - Hiển thị đầy đủ thông tin yêu cầu
    - Lý do yêu cầu mở khóa
    - Ghi chú từ người dùng
  - **Duyệt yêu cầu**:
    - Xác nhận trước khi duyệt
    - Cập nhật trạng thái yêu cầu = 'approved'
    - Tự động mở khóa tài khoản (status = 'active')
    - Gửi email thông báo cho người dùng (nếu có)
  - **Thông báo**: Hiển thị thông báo thành công
- **File liên quan**: `lib/admin/pages/unlock_requests_page.dart`, `lib/core/services/unlock_request_service.dart`

#### 3.4.3. Từ chối yêu cầu mở khóa
- **Mô tả**: Admin từ chối yêu cầu mở khóa
- **Chi tiết**:
  - **Từ chối yêu cầu**:
    - Xác nhận trước khi từ chối
    - Cập nhật trạng thái yêu cầu = 'rejected'
    - Tài khoản vẫn bị khóa
    - Gửi email thông báo cho người dùng (nếu có)
  - **Thông báo**: Hiển thị thông báo thành công
- **File liên quan**: `lib/admin/pages/unlock_requests_page.dart`, `lib/core/services/unlock_request_service.dart`

---

### 3.5. Hồ sơ Admin

#### 3.5.1. Xem hồ sơ Admin
- **Mô tả**: Admin xem thông tin cá nhân của mình
- **Chi tiết**:
  - Thông tin: Tên, email, vai trò (Admin)
  - Đăng xuất
- **File liên quan**: `lib/admin/pages/profile_page.dart`

---

## 4. CÔNG NGHỆ VÀ KIẾN TRÚC

### 4.1. Công nghệ sử dụng

#### 4.1.1. Frontend
- **Flutter**: Framework chính cho cả mobile app và admin panel
- **Dart**: Ngôn ngữ lập trình
- **Provider**: State management
- **Material Design**: UI/UX framework

#### 4.1.2. Backend
- **Firebase Authentication**: Xác thực người dùng
- **Cloud Firestore**: Cơ sở dữ liệu NoSQL
- **Firebase Storage**: Lưu trữ file (nếu có)
- **Firebase Cloud Functions**: Serverless functions (nếu có)

#### 4.1.3. Services
- **Google Maps API**: Hiển thị bản đồ và GPS tracking
- **Google Gemini API**: AI Coach service
- **Local Notifications**: Thông báo local

### 4.2. Kiến trúc

#### 4.2.1. Clean Architecture
- **Domain Layer**: Entities, Repositories (interfaces)
- **Data Layer**: Repositories implementations, Data sources
- **Presentation Layer**: UI, ViewModels, Widgets
- **Core Layer**: Services, Helpers, Utils

#### 4.2.2. State Management
- **Provider**: Quản lý state toàn cục
- **ChangeNotifier**: ViewModels
- **StreamBuilder**: Real-time data

---

## 5. CƠ SỞ DỮ LIỆU

### 5.1. Cấu trúc Firestore Collections

#### 5.1.1. Collections chính
- `users`: Thông tin người dùng
- `unlock_requests`: Yêu cầu mở khóa

#### 5.1.2. Subcollections (theo user)
- `users/{userId}/activities`: Hoạt động thể thao
- `users/{userId}/gps_routes`: Tuyến đường GPS
- `users/{userId}/goals`: Mục tiêu fitness
- `users/{userId}/streaks`: Chuỗi ngày liên tiếp
- `users/{userId}/weight_history`: Lịch sử cân nặng
- `users/{userId}/chat_history`: Lịch sử chat với AI
- `users/{userId}/ai_insights`: AI insights

### 5.2. Các bảng dữ liệu

#### 5.2.1. User
- Thông tin cá nhân, xác thực, trạng thái, vai trò

#### 5.2.2. Activity
- Hoạt động thể thao: loại, thời gian, quãng đường, ngày giờ

#### 5.2.3. GPS Routes
- Tuyến đường GPS: tọa độ, quãng đường, thời gian, loại hoạt động

#### 5.2.4. Goal
- Mục tiêu fitness: loại, chỉ tiêu, tiến độ, thời hạn, nhắc nhở

#### 5.2.5. Streak
- Chuỗi ngày liên tiếp: số ngày, ngày bắt đầu, ngày kết thúc

#### 5.2.6. Weight Record
- Lịch sử cân nặng: cân nặng, ngày ghi nhận

#### 5.2.7. Chat Conversation
- Hội thoại với AI: tin nhắn (embedded), ngày tạo

#### 5.2.8. AI Insight
- Insights từ AI: tiêu đề, nội dung, ngày tạo

#### 5.2.9. Unlock Request
- Yêu cầu mở khóa: lý do, ghi chú, trạng thái, ngày gửi

---

## 6. TỔNG KẾT

### 6.1. Chức năng User
- ✅ Xác thực và quản lý tài khoản (5 chức năng)
- ✅ Dashboard tổng quan (2 chức năng)
- ✅ Quản lý hoạt động (6 chức năng)
- ✅ Quản lý mục tiêu (5 chức năng)
- ✅ Thống kê (3 chức năng)
- ✅ AI Coach (3 chức năng)
- ✅ Hồ sơ cá nhân (3 chức năng)
- ✅ Cài đặt (1 chức năng)
- ✅ Xử lý tài khoản bị khóa (1 chức năng)

**Tổng: 29 chức năng chính**

### 6.2. Chức năng Admin
- ✅ Xác thực Admin (2 chức năng)
- ✅ Dashboard Admin (1 chức năng)
- ✅ Quản lý người dùng (4 chức năng)
- ✅ Quản lý yêu cầu mở khóa (3 chức năng)
- ✅ Hồ sơ Admin (1 chức năng)

**Tổng: 11 chức năng chính**

### 6.3. Tổng số chức năng hệ thống
**40 chức năng chính** được phân chia rõ ràng giữa User và Admin, đáp ứng đầy đủ nhu cầu quản lý fitness và quản trị hệ thống.

---

**Tài liệu này được tạo tự động dựa trên codebase hiện tại và có thể được cập nhật khi có thay đổi trong hệ thống.**

