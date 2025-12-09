## Mục tiêu
- Xây lại tính năng yêu cầu mở khóa tài khoản từ đầu cho cả app mobile và admin panel.

## Phân rã chức năng (phases)
- **Phase 1 – Thiết kế luồng & API**
  - Xác định luồng người dùng bị khóa: phát hiện trạng thái, hiển thị dialog, gửi yêu cầu, xử lý trạng thái chờ.
  - Định nghĩa schema `unlock_requests` (fields: id, userId, email, name, reason, status, createdAt, processedAt, processedBy, adminNote).
  - Quy ước status: `pending`, `approved`, `rejected`.

- **Phase 2 – Backend/Firestore**
  - Model + repository unlock request (domain + data + Firestore).
  - Service xử lý submit từ user (có/không đăng nhập) và kiểm tra pending.
  - Firestore rules cho `unlock_requests` (cho phép create công khai với field bắt buộc, read/update cho admin).
  - Indexes cho `unlock_requests` (createdAt desc, status+createdAt, userId+createdAt).

- **Phase 3 – Mobile App**
  - UI dialog yêu cầu mở khóa (email, họ tên, lý do), validation, loading, đóng sau khi gửi.
  - Logic hiển thị dialog khi login bị từ chối do blocked (email/pass và Google) và khi AuthGate phát hiện blocked.
  - Bắt buộc: nếu user bị blocked, mỗi lần bấm Đăng nhập đều phải hiện dialog, kể cả sau khi đã bấm Huỷ/đóng ngoài dialog trước đó.
  - Logging và chặn SnackBar trùng lặp; đảm bảo dialog xuất hiện mỗi lần user blocked đăng nhập.

- **Phase 4 – Admin Panel**
  - Trang “Yêu cầu mở khóa”: danh sách, lọc theo trạng thái, action approve/reject kèm ghi chú.
  - Cập nhật trạng thái user về `active` khi approve; lưu adminNote khi reject.
  - Bổ sung menu/route vào sidebar, router, layout.
  - (Email notify: đã bỏ theo yêu cầu; chỉ log tại Cloud Function, không gửi mail.)

- **Phase 5 – Tích hợp & Bảo vệ**
  - Kiểm thử luồng end-to-end: gửi yêu cầu (blocked, chưa đăng nhập), hiển thị admin, xử lý approve/reject, cập nhật user.
  - Đảm bảo hành vi sign-out và SnackBar không chặn dialog.
  - Kiểm tra lại rules và indexes đã deploy.

- **Phase 6 – Kiểm thử & QA**
  - Test trên thiết bị/thời gian thực: dialog hiển thị lại khi user nhấn Huỷ rồi đăng nhập lại.
  - Test ngoại lệ: đóng dialog bằng tap ra ngoài (nếu cho phép) hoặc back, sau đó bấm Đăng nhập lại vẫn phải hiện dialog.
  - Test lỗi mạng, thiếu quyền Firestore, và thông báo lỗi rõ ràng.
  - Viết checklist regression: login, logout, admin sidebar, dashboard không ảnh hưởng.

## Ghi chú
- Mặc định code hiện tại đã gỡ toàn bộ phần unlock; đã thêm lại theo thứ tự phases trên.
- Ưu tiên đảm bảo không hiển thị SnackBar “blocked” che mất dialog.
- Email: đã tắt; Cloud Function chỉ log khi status đổi.

