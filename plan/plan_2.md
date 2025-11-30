  ## Kế hoạch triển khai Plan 2: Biểu đồ & Phân tích Sức khỏe

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Thống kê", "Biểu đồ", "Cân nặng", "Quãng đường", "Kcal", "Thời gian tập", "BMI", "Chuỗi", v.v.

### Phase 1: Lưu trữ dữ liệu vào Firestore
- **1.1 Tạo collection `activities`** trong Firestore:
  - userId, activityType, date, duration, distance, calories, notes
  - Lưu tất cả buổi tập từ Plan 1
- **1.2 Tạo collection `weight_history`** (nếu chưa có từ Plan 1):
  - userId, weight, date, createdAt
- **1.3 Đảm bảo dữ liệu được lưu tự động** khi hoàn thành buổi tập
- **1.4 Xử lý offline**: Cache dữ liệu local, sync khi có internet

### Phase 2: Lọc và tìm kiếm dữ liệu
- **2.1 Tạo `HistoryService`** để query dữ liệu từ Firestore:
  - Get activities theo userId
  - Get weight history theo userId
  - Filter theo date range
- **2.2 Màn hình Lịch sử với filter:**
  - Dropdown chọn: Ngày/Tuần/Tháng/Năm
  - Date picker để chọn khoảng thời gian
  - Search bar để tìm kiếm
- **2.3 Sắp xếp dữ liệu:**
  - Mặc định: Mới nhất trước
  - Có thể sắp xếp: Cũ nhất trước, theo loại hoạt động
- **2.4 Hiển thị danh sách:**
  - ListView/GridView các buổi tập
  - Card hiển thị: ngày, loại hoạt động, quãng đường, kcal, thời gian

### Phase 3: Tích hợp biểu đồ
- **3.1 Setup thư viện `fl_chart`:**
  - Thêm dependency vào pubspec.yaml
  - Import package
- **3.2 Tạo `ChartService`** để xử lý dữ liệu cho biểu đồ:
  - Aggregate data theo ngày/tuần/tháng/năm
  - Tính tổng/trung bình cho từng kỳ
- **3.3 Màn hình Statistics với TabBar:**
  - Tab: Ngày, Tuần, Tháng, Năm
  - Dropdown chọn loại biểu đồ: Cân nặng, Quãng đường, Kcal, Thời gian tập
- **3.4 Tạo các biểu đồ:**
  - Biểu đồ xu hướng cân nặng (LineChart)
  - Biểu đồ tổng quãng đường (LineChart)
  - Biểu đồ tổng kcal tiêu thụ (LineChart)
  - Biểu đồ tổng thời gian tập luyện (LineChart)
- **3.5 Tùy chỉnh biểu đồ:**
  - Màu sắc đẹp, dễ nhìn
  - Tooltip khi tap vào điểm
  - Zoom/Pan (nếu cần)

### Phase 4: Tính toán chỉ số sức khỏe
- **4.1 Tạo `HealthCalculator` service:**
  - Method tính BMI: `calculateBMI(weight, height)`
  - Method phân loại BMI: `getBMICategory(bmi)`
- **4.2 Hiển thị BMI trong Statistics screen:**
  - Card hiển thị BMI và phân loại
  - Màu sắc theo phân loại (xanh = bình thường, đỏ = cảnh báo)
- **4.3 Cảnh báo BMI bất thường:**
  - Nếu BMI < 18.5 hoặc > 30 → hiển thị cảnh báo
  - Gợi ý điều chỉnh (tăng/giảm cân)

### Phase 5: Theo dõi chuỗi (Streak)
- **5.1 Tạo `StreakService`** để tính toán streak:
  - Method `calculateStreak(userId, goalType, startDate)`
  - Kiểm tra số ngày liên tiếp đạt mục tiêu
- **5.2 Lưu streak vào Firestore:**
  - Collection `streaks`: userId, goalType, currentStreak, longestStreak, lastDate
- **5.3 Hiển thị streak:**
  - Card trong Dashboard hoặc Statistics
  - Hiển thị: Chuỗi hiện tại, Chuỗi dài nhất
  - Circular progress hoặc số ngày lớn
- **5.4 Cảnh báo và thông báo:**
  - Cảnh báo khi sắp mất chuỗi (chưa đạt mục tiêu hôm nay)
  - Thông báo khi đạt milestone: 7 ngày, 30 ngày, 100 ngày
  - Celebration animation khi đạt milestone

### Phase 6: UI/UX và tối ưu
- **6.1 Tối ưu performance:**
  - Cache dữ liệu đã query
  - Lazy loading cho danh sách dài
  - Debounce cho search
- **6.2 Empty states:**
  - Hiển thị khi chưa có dữ liệu
  - Icon và message thân thiện
- **6.3 Loading states:**
  - Shimmer effect khi đang load
  - Progress indicator cho biểu đồ
- **6.4 Error handling:**
  - Xử lý khi không có internet
  - Retry mechanism
  - Error message thân thiện

---

## Cấu trúc File Dự Kiến

```
lib/
├── models/
│   ├── activity.dart          # Model Activity
│   └── streak.dart            # Model Streak
├── services/
│   ├── history_service.dart   # HistoryService
│   ├── chart_service.dart     # ChartService
│   ├── health_calculator.dart  # HealthCalculator
│   └── streak_service.dart    # StreakService
├── screens/
│   ├── history/
│   │   └── history_screen.dart
│   └── statistics/
│       └── statistics_screen.dart
└── widgets/
    ├── chart_widget.dart       # Widget biểu đồ
    ├── bmi_card.dart          # Card hiển thị BMI
    └── streak_card.dart       # Card hiển thị streak
```

---

## Schema Firestore

### Collection: `activities`
```dart
{
  id: string (document ID - auto),
  userId: string,
  activityType: string,  // 'running' | 'walking' | 'cycling' | 'aerobic' | 'yoga' | ...
  date: Timestamp,
  duration: int,  // seconds
  distance: double?,  // km (null nếu hoạt động tại nhà)
  calories: double,  // kcal
  averageSpeed: double?,  // km/h (null nếu hoạt động tại nhà)
  notes: string?,
  // Lưu ý: GPS route chi tiết (segments) sẽ được lưu trong Plan 4 vào collection `gps_routes` riêng
  createdAt: Timestamp
}
```

### Collection: `streaks`
```dart
{
  id: string (document ID - auto),
  userId: string,
  goalType: string,  // 'distance' | 'calories' | 'duration'
  currentStreak: int,  // Số ngày liên tiếp hiện tại
  longestStreak: int,  // Chuỗi dài nhất từ trước
  lastDate: Timestamp,  // Ngày cuối cùng đạt mục tiêu
  updatedAt: Timestamp
}
```

---

## Security Rules Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Activities collection
    match /activities/{activityId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Streaks collection
    match /streaks/{streakId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

> Sau khi hoàn thành Plan 2, có thể chuyển sang Plan 3: Mục tiêu & Thống kê Chi tiết.

