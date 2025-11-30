# Firestore Indexes Configuration

File `firestore.indexes.json` chứa tất cả các composite indexes cần thiết cho ứng dụng Fitness.

## Cấu trúc Indexes theo Plan

### ✅ Plan 1 - Activities (Đang sử dụng)
- `activities` - date DESC: Sắp xếp activities mới nhất
- `activities` - date ASC: Range query (>= và <)
- `activities` - activityType + date DESC: Lọc theo loại hoạt động

### 📋 Plan 2 - Streaks & Statistics (Chưa triển khai)
- `streaks` - userId + updatedAt DESC: Hiển thị streaks

### 📋 Plan 3 - Goals (Chưa triển khai)
- `goals` - userId + status + createdAt DESC: Lọc goals đang active
- `goals` - userId + goalType + updatedAt DESC: Lọc theo loại mục tiêu

### 📋 Plan 4 - GPS Routes (Chưa triển khai)
- `gps_routes` - userId + createdAt DESC: Hiển thị routes

### 📋 Plan 5 - Training Plans & Chat (Chưa triển khai)
- `user_active_plans` - userId + updatedAt DESC: Plans đang active
- `chat_history` - userId + updatedAt DESC: Lịch sử chat

### 📋 Plan 6 - AI Insights (Chưa triển khai)
- `ai_insights` - userId + createdAt DESC: Insights mới nhất
- `ai_insights` - userId + insightType + createdAt DESC: Lọc theo loại

## Lưu ý

1. **Chỉ deploy indexes khi cần**: Không nên deploy tất cả indexes ngay, chỉ deploy khi bắt đầu triển khai tính năng tương ứng.

2. **Deploy từng phần**:
   ```bash
   # Deploy tất cả
   firebase deploy --only firestore:indexes
   
   # Hoặc tạo thủ công trong Firebase Console khi có lỗi
   ```

3. **Theo dõi chi phí**: Mỗi index tốn storage và có chi phí duy trì. Chỉ tạo khi thực sự cần.

4. **Khi có lỗi query**: Firestore sẽ báo lỗi và cung cấp link tạo index tự động. Ưu tiên dùng link đó để đảm bảo đúng fields.

## Quy trình

1. Khi bắt đầu Plan mới → Kiểm tra indexes cần thiết trong file này
2. Deploy indexes tương ứng (hoặc để Firestore tự báo lỗi)
3. Test query để đảm bảo hoạt động
4. Cập nhật file này nếu có thay đổi

