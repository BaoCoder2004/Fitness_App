## Kế hoạch xây dựng Web Admin (Flutter Web + Firebase)

> Mục tiêu: Tạo một web admin đơn giản để quản lý tài khoản người dùng (user list, tìm kiếm, khóa/mở, phân quyền cơ bản, dashboard tổng quan), **không truy cập sâu vào dữ liệu riêng tư** (insight, lịch sử tập, v.v.).

---

## 0. Phạm vi & Nguyên tắc

- **Phạm vi**
  - Xem danh sách người dùng.
  - Tìm kiếm người dùng theo tên hoặc email.
  - Khóa / mở khóa tài khoản người dùng.
  - Phân quyền: `user` / `admin`.
  - Dashboard tổng quan: tổng số user, user mới, số user bị khóa, số admin.

- **Nguyên tắc**
  - Không xem chi tiết dữ liệu nhạy cảm (insight, lịch sử tập, GPS, v.v.).
  - Chỉ tài khoản có `role = admin` mới truy cập được web admin.
  - Ưu tiên đơn giản, dễ dùng, dễ mở rộng sau này.

---

## 1. Kiến trúc tổng thể

- **Công nghệ**
  - Flutter Web (project riêng, cùng Firebase project với app chính).
  - Firebase Auth (email/password) cho admin.
  - Firestore cho dữ liệu user & metadata.
  - Firebase Hosting để deploy web admin.

- **Dữ liệu / Field cần chuẩn hóa**
  - Collection user (hoặc profile chính, tùy cấu trúc hiện tại):
    - `uid`: string
    - `email`: string
    - `displayName`: string (nếu có)
    - `createdAt`: Timestamp
    - `role`: `"user"` / `"admin"`
    - `status`: `"active"` / `"blocked"`

---

## Phase 1 – Chuẩn bị & tích hợp Firebase

### 1.1. Tạo project Flutter Web admin

- Tạo project Flutter mới (ví dụ: `admin_panel/` trong repo hiện tại).
- Bật hỗ trợ web: `flutter config --enable-web`.
- Cấu hình:
  - `firebase_options.dart` riêng cho admin (cùng Firebase project với app chính).
  - Kết nối Firebase (Auth + Firestore).

### 1.2. Thiết kế routing & layout cơ bản

- Routing:
  - `/login` – Trang đăng nhập admin.
  - `/dashboard` – Trang tổng quan + shell layout (AppBar + Sidebar).
  - `/users` – Trang quản lý user.
- Layout:
  - AppBar: tiêu đề app, nút logout.
  - Sidebar/Menu: Dashboard, Users (các mục khác để sau).

---

## Phase 2 – Xác thực & phân quyền admin

### 2.1. Đăng nhập admin

- Sử dụng Firebase Auth (email/password).
- Form:
  - Input email, password.
  - Nút "Đăng nhập".
- Xử lý:
  - Sau khi login thành công → kiểm tra `role` trong Firestore.

### 2.2. Kiểm tra role & chặn truy cập

- Cấu trúc:
  - Sau khi `FirebaseAuth.currentUser` != null:
    - Lấy document user/profile theo `uid`.
    - Đọc field `role`.
  - Nếu `role != 'admin'`:
    - Không cho truy cập, hiển thị thông báo "Bạn không có quyền truy cập admin".
    - Tự động logout hoặc chặn ở route guard.

- Bảo mật:
  - Firestore Security Rules: chỉ cho phép đọc dữ liệu admin-sensitive nếu `request.auth.uid != null` và user tương ứng có `role = admin`.
  - Đảm bảo user thường không thể truy cập collection/tài liệu dành riêng cho admin (nếu có).

---

## Phase 3 – Quản lý danh sách user

### 3.1. Hiển thị danh sách user

- Giao diện:
  - Bảng/List user với các cột:
    - Tên hiển thị (`displayName` nếu có, fallback email).
    - Email.
    - Ngày tạo (`createdAt`).
    - `role` (user/admin).
    - `status` (active/blocked).
    - Action (nút chi tiết, khóa/mở, đổi role).

- Chức năng:
  - Phân trang (paging) hoặc lazy load (scroll) nếu số user lớn.
  - Sắp xếp theo `createdAt` (mới nhất lên trên).

### 3.2. Tìm kiếm user theo tên/email

- Search bar:
  - Input text, search theo:
    - `email` (ưu tiên).
    - `displayName` (nếu có field này).
- Cách thực hiện:
  - Với số lượng user chưa quá lớn: có thể load 1 lần và filter client-side.
  - Nếu sau này user nhiều:
    - Dùng query Firestore với index theo `email` (ví dụ: where + startAt/endAt).

---

## Phase 4 – Khóa/Mở tài khoản & phân quyền

### 4.1. Khóa / Mở khóa tài khoản

- Mô hình:
  - Field `status`: `"active"` / `"blocked"`.
- UI:
  - Nút toggle trên mỗi dòng user:
    - Nếu đang `active` → hiện nút "Khóa".
    - Nếu đang `blocked` → hiện nút "Mở khóa".
- Logic:
  - Khi admin bấm "Khóa":
    - Hiện dialog xác nhận.
    - Update Firestore: `status = 'blocked'`.
  - Ứng dụng mobile cần:
    - Khi user login / thực hiện action, check `status`.
    - Nếu `blocked` → chặn hành động, thông báo: "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ."

### 4.2. Phân quyền user / admin

- Mô hình:
  - Field `role`: `"user"` / `"admin"`.
- UI:
  - Trong bảng user:
    - Cho phép đổi `role` bằng dropdown hoặc menu action (chỉ nên làm cho 1 số ít tài khoản).
- Bảo mật & UX:
  - Khi chuyển `user` → `admin`:
    - Bắt buộc hiện dialog xác nhận, cảnh báo rủi ro.
  - Có thể hạn chế:
    - Không cho tự downgrade chính mình (không tự chuyển `admin` → `user`).

---

## Phase 5 – Dashboard tổng quan

### 5.1. Thống kê chính

- Số liệu hiển thị:
  - Tổng số user.
  - Số user mới trong 7 ngày gần nhất.
  - Số user đang `active`.
  - Số user đang `blocked`.
  - Số user có `role = admin`.

- UI:
  - Các card nhỏ (stat card) trên `DashboardPage`.
  - Có thể thêm biểu đồ đơn giản (để sau, nếu cần).

### 5.2. Tối ưu truy vấn

- Cách đơn giản (MVP):
  - Query trực tiếp Firestore để đếm (chấp nhận tạm chi phí đọc).
- Sau này (nếu cần tối ưu):
  - Tạo collection `stats` hoặc document `app_stats` lưu sẵn các count (update bằng Cloud Functions hoặc batch).

---

## Phase 6 – Hoàn thiện, bảo mật & mở rộng sau này

### 6.1. Hoàn thiện & polish

- Thêm loading state, error state rõ ràng.
- Thêm thông báo (snackbar/dialog) khi:
  - Khóa/mở user thành công / thất bại.
  - Đổi role thành công / thất bại.
- Responsive cơ bản cho màn hình nhỏ (nếu cần).

### 6.2. Bảo mật & triển khai

- Xem lại Firestore Security Rules:
  - Chỉ `role = admin` mới đọc được danh sách tất cả user.
  - User thường chỉ đọc/ghi được dữ liệu của chính họ trên app mobile.
- Deploy:
  - Build Flutter Web.
  - Deploy lên Firebase Hosting (ví dụ: `/admin` trên domain hiện có hoặc subdomain riêng).

### 6.3. Các ý tưởng mở rộng (để sau)

- Bộ lọc nâng cao:
  - Lọc theo `status`, theo `role`, theo ngày tạo.
- Log hoạt động admin:
  - Lưu lại khi admin khóa/mở user, đổi role (ai làm, lúc nào).
- Dashboard nâng cao:
  - Biểu đồ user active theo ngày/tuần.

---

## Ghi chú triển khai

- Ưu tiên làm lần lượt:
  - Phase 1 → 2 (Auth + role) trước để chốt khung bảo mật.
  - Sau đó Phase 3 → 4 (user list + action).
  - Cuối cùng Phase 5 (dashboard) để có cảm giác "admin thực sự".
- Trong quá trình triển khai, có thể điều chỉnh phạm vi cho phù hợp với dữ liệu thực tế trong Firestore hiện tại.


