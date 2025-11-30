## Kế hoạch Index Cloud Firestore

> File này tổng hợp các index cần tạo dần theo từng plan. Khi code query mới mà Firestore báo thiếu index, ưu tiên dùng link **Create index** từ log để tránh sai field. Tuy nhiên, danh sách dưới giúp chuẩn bị trước đối với các truy vấn chắc chắn sẽ có.

### Nguyên tắc chung
- Mỗi collection đều filter theo `request.auth.uid`, vì vậy mọi index nên có `userId` là field đầu tiên.
- Thêm `createdAt` hoặc `date` để hỗ trợ `orderBy` mới nhất.
- Chỉ tạo composite index khi:
  - Query có đồng thời `where` + `orderBy` trên nhiều field.
  - Có nhiều điều kiện `where` với `==` và `>=`/`<=`.
- Không tạo thừa: theo dõi trong Firebase Console → Firestore Database → Indexes.

---

### Plan 1 – Users, Weight History, Activities

| Collection | Truy vấn tiêu biểu | Index đề nghị |
|------------|-------------------|---------------|
| `users` | `doc()` theo `uid` | Không cần composite |
| `users/{uid}/weight_history` hoặc `weight_history` | `where(userId==uid).orderBy(date, desc)` | `userId ASC, date DESC` |
| `activities` | `where(userId==uid).orderBy(date, desc)` | `userId ASC, date DESC` |
| `activities` | Filter loại + ngày: `where(userId==uid).where(activityType==x).orderBy(date, desc)` | `userId ASC, activityType ASC, date DESC` |

### Plan 2 – Streak & Statistics

| Collection | Truy vấn | Index |
|------------|---------|-------|
| `streaks` | `where(userId==uid).orderBy(updatedAt, desc)` | `userId ASC, updatedAt DESC` |
| `activities` (lọc phạm vi ngày) | `where(userId==uid).where(date>=start).where(date<=end).orderBy(date)` | Composite trên `userId ASC, date ASC` |

### Plan 3 – Goals & Notifications

| Collection | Truy vấn | Index |
|------------|---------|-------|
| `goals` | `where(userId==uid).where(status==active).orderBy(createdAt, desc)` | `userId ASC, status ASC, createdAt DESC` |
| `goals` | Lọc theo loại: `where(userId==uid).where(goalType==x).orderBy(updatedAt, desc)` | `userId ASC, goalType ASC, updatedAt DESC` |

### Plan 4 – GPS Routes

| Collection | Truy vấn | Index |
|------------|---------|-------|
| `gps_routes` | `where(userId==uid).orderBy(createdAt, desc)` | `userId ASC, createdAt DESC` |
| `gps_routes` | Nếu lọc theo activity: `where(userId==uid).where(activityId==x)` | Chỉ cần single-field (`activityId`) |

### Plan 5 – Training Plans & Chat

| Collection | Truy vấn | Index |
|------------|---------|-------|
| `training_plans` | Read-only, orderBy `difficulty` hoặc `duration` | Single-field indexes mặc định |
| `user_active_plans` | `where(userId==uid).orderBy(updatedAt, desc)` | `userId ASC, updatedAt DESC` |
| `chat_history` | `where(userId==uid).orderBy(updatedAt, desc)` | `userId ASC, updatedAt DESC` |

### Plan 6 – AI Insights

| Collection | Truy vấn | Index |
|------------|---------|-------|
| `ai_insights` | `where(userId==uid).orderBy(createdAt, desc)` | `userId ASC, createdAt DESC` |
| `ai_insights` | Filter theo loại insight: `where(userId==uid).where(insightType==x).orderBy(createdAt, desc)` | `userId ASC, insightType ASC, createdAt DESC` |

---

### Quy trình tạo index
1. Từ Firebase Console → Firestore Database → Indexes → **Create index** → Chọn collection.
2. Thêm fields theo bảng trên (Field, Order).
3. Region giữ mặc định (theo DB).
4. Đợi ~1-2 phút để index build xong (console hiển thị trạng thái).

### Theo dõi lỗi query
- Khi chạy app, nếu log báo `FAILED_PRECONDITION: The query requires an index`, nhấn link kèm theo. Firebase sẽ tự điền đúng field/order.
- Ghi chú lại index vừa tạo vào file này để dễ kiểm soát (thêm dòng `✅ Created: ...` nếu muốn).

---

> Hãy cập nhật file này mỗi khi phát sinh query mới cần index, tránh tạo thủ công lung tung. Điều này giúp kiểm soát chi phí và giữ Firestore gọn gàng.


