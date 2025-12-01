## Kế hoạch triển khai Plan 4: GPS Tracking Nâng Cao & Export

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Bắt đầu", "Tạm dừng", "Tiếp tục", "Hoàn thành", "Lưu", "Xóa", "Quãng đường", "Tốc độ trung bình", "Xuất dữ liệu", "PDF", "Excel", v.v.

### Phase 1: GPS Tracking nâng cao với bản đồ
- **1.1 Setup dependencies:**
  - `geolocator`: Lấy vị trí GPS
  - `flutter_map`: Hiển thị bản đồ OpenStreetMap
  - `latlong2`: Xử lý tọa độ
- **1.2 Request permissions:**
  - Location permission (foreground)
  - Xử lý khi user từ chối permission
- **1.3 Tạo `GPSTrackingService`:**
  - Method `startTracking()`: Bắt đầu theo dõi GPS, tạo segment mới, lưu điểm bắt đầu
  - Method `pauseTracking()`: Tạm dừng segment hiện tại, lưu điểm dừng, đóng segment hiện tại
  - Method `resumeTracking()`: Bắt đầu segment MỚI (không nối với segment cũ), lưu điểm tiếp tục
  - Method `stopTracking()`: Dừng và đóng segment cuối cùng, lưu điểm kết thúc
  - Stream vị trí GPS real-time: Mỗi 3-5 giây thêm một điểm GPS vào segment hiện tại
  - Quản lý segments: List các segment, mỗi segment là một list các điểm GPS
  - **Quan trọng**: Khi resume, KHÔNG nối điểm dừng với điểm tiếp tục (vì người dùng có thể đã di chuyển)
- **1.4 Màn hình GPS Tracking:**
  - Hiển thị bản đồ OpenStreetMap
  - **Chỉ có 2 marker:**
    * **Marker điểm bắt đầu**: Hiển thị khi bấm "Bắt đầu" (màu xanh dương) - cố định
    * **Marker điểm hiện tại/kết thúc**: 
      - Khi đang tracking: Marker tại vị trí GPS hiện tại, cập nhật real-time (màu xanh lục)
      - Khi hoàn thành: Marker này trở thành điểm kết thúc (màu xanh lục) - cố định
  - **Polyline segments**: Vẽ từng segment riêng biệt (màu xanh dương)
    * Mỗi segment là một polyline riêng (không nối các segment lại với nhau)
    * Segment 1: Từ điểm bắt đầu đến điểm dừng lần 1
    * Segment 2: Từ điểm tiếp tục lần 1 đến điểm dừng lần 2 (nếu có)
    * Segment N: Từ điểm tiếp tục cuối đến điểm kết thúc
  - Polyline cập nhật real-time khi có điểm GPS mới trong segment hiện tại
  - Khi tạm dừng: Segment hiện tại đóng lại, không vẽ thêm, marker điểm hiện tại vẫn còn
  - Khi tiếp tục: Bắt đầu segment mới từ vị trí hiện tại (KHÔNG nối với segment cũ)
  - **Khi bấm "Hoàn thành":**
    * Đóng segment cuối, marker điểm hiện tại trở thành điểm kết thúc (đổi màu xanh lục)
    * Hiển thị popup/dialog xác nhận với 2 nút:
      - **Xóa**: Không lưu buổi tập, quay lại màn hình trước (dữ liệu sẽ bị mất)
      - **Lưu**: Lưu buổi tập vào Firestore, chuyển đến màn hình Activity Summary
    * Popup hiển thị thông tin tóm tắt: thời gian, quãng đường, tốc độ trung bình, kcal (để người dùng quyết định)
  - Hiển thị thông tin real-time: quãng đường, thời gian, tốc độ trung bình, kcal tiêu thụ
    * **Chỉ tính khi đang di chuyển** (trong các segment), không tính thời gian pause
  - Nút: Bắt đầu, Tạm dừng, Tiếp tục, Hoàn thành
- **1.5 Tính toán quãng đường, tốc độ và kcal:**
  - **Quãng đường**: Tính tổng khoảng cách TRONG TỪNG SEGMENT (không tính khoảng cách giữa các segment)
    * Với mỗi segment: Tính tổng khoảng cách giữa các điểm GPS liên tiếp trong segment đó
    * Tổng quãng đường = Tổng quãng đường của tất cả các segment
    * Sử dụng công thức Haversine để tính khoảng cách giữa 2 điểm
    * **Chỉ tính khi đang di chuyển** (trong các segment)
  - **Thời gian**: Chỉ tính thời gian di chuyển (tổng thời gian trong tất cả các segment)
    * Không tính thời gian pause (khoảng thời gian giữa các segment)
    * Ví dụ: Segment 1: 10 phút, pause 5 phút, Segment 2: 15 phút → Tổng thời gian = 25 phút
  - **Tốc độ trung bình**: Tổng quãng đường (trong các segment) / tổng thời gian di chuyển (không tính thời gian pause)
  - **Tính kcal tiêu thụ** (cho hoạt động GPS - Chạy, Đi bộ, Đạp xe):
    * Sử dụng công thức dựa trên quãng đường (chỉ tính trong segments), thời gian di chuyển (không tính pause), cân nặng và loại hoạt động
    * Cập nhật real-time khi quãng đường và thời gian thay đổi (chỉ khi đang di chuyển)
    * Công thức: Dựa trên MET value và quãng đường (tương tự Plan 1)

### Phase 2: Lưu route GPS vào Firestore
- **Lưu ý về Navigation:** GPS Routes sẽ là Tab 3 trong Activity Tab (Bottom Navigation Bar), chỉ hiển thị khi có dữ liệu GPS
- **2.1 Lưu route GPS vào Firestore:**
  - **Collection `gps_routes` riêng** (không lưu trong `activities`):
    * userId, activityId, segments, startPoint, endPoint, totalDistance, totalDuration
    * **Lưu ý**: Đây là nâng cấp từ Plan 1, Plan 1 chỉ lưu thông tin cơ bản (distance, duration, averageSpeed) trong `activities`
    * Plan 4 mới bắt đầu lưu GPS route chi tiết với segments vào collection riêng
  - segments: Array of segments, mỗi segment là một array các điểm GPS
    * Segment structure: {points: [{lat, lng, timestamp}, ...], startTime: Timestamp, endTime: Timestamp}
  - startPoint: {lat, lng, timestamp} - Điểm đầu tiên của segment đầu tiên
  - endPoint: {lat, lng, timestamp} - Điểm cuối cùng của segment cuối cùng
  - Chỉ lưu khi hoàn thành buổi tập
  - Tối ưu: Mỗi segment lưu tối đa 500-1000 điểm (nếu nhiều hơn, chỉ lưu mỗi điểm thứ N)
- **2.2 Xem lại buổi tập trên bản đồ:**
  - Màn hình Activity Detail
  - **Chỉ hiển thị 2 marker**: điểm bắt đầu (màu xanh dương) và điểm kết thúc (màu xanh lục)
  - Vẽ từng segment riêng biệt: Mỗi segment là một polyline riêng (màu xanh dương)
  - **KHÔNG nối** các segment lại với nhau (giữ khoảng trống giữa các segment)
  - Zoom tự động để hiển thị toàn bộ route (tất cả các segment)
  - Hiển thị thông tin: quãng đường (tổng trong các segment), thời gian (chỉ tính di chuyển), tốc độ trung bình, kcal tiêu thụ

### Phase 3: Thống kê buổi tập GPS chi tiết
- **3.1 Màn hình Activity Detail:**
  - Hiển thị thông tin buổi tập:
    - Thời gian tập luyện (chỉ tính thời gian di chuyển, không tính thời gian pause)
    - Quãng đường (km) - tính từ GPS (tổng khoảng cách trong các segment, không tính khoảng cách giữa segment)
    - Tốc độ trung bình (km/h) - dựa trên quãng đường và thời gian di chuyển
    - Calories đã đốt (kcal) - tính từ quãng đường, thời gian di chuyển, cân nặng và loại hoạt động
    - Pace trung bình (phút/km)
- **3.2 Hiển thị bản đồ với segments:**
  - **Chỉ hiển thị 2 marker**: điểm bắt đầu (màu xanh dương) và điểm kết thúc (màu xanh lục)
  - Vẽ từng segment riêng biệt: Mỗi segment là một polyline riêng (màu xanh dương)
  - **KHÔNG nối** các segment lại với nhau (giữ khoảng trống giữa các segment để tránh sai lệch dữ liệu)
  - Zoom tự động để hiển thị toàn bộ route (tất cả các segment)

### Phase 3.3: Lưu ý về Hoạt động tại chỗ (Indoor Activities)
- **Hoạt động tại chỗ** (Aerobic, Yoga, Gym, Khiêu vũ, Calisthenics, Boxing, Nhảy dây):
  - **KHÔNG** sử dụng GPS tracking
  - **KHÔNG** có bản đồ hoặc route
  - **Tính thời gian**: Chỉ tính thời gian di chuyển (không tính thời gian pause)
    * Khi bấm "Bắt đầu": Bắt đầu đếm thời gian
    * Khi bấm "Tạm dừng": Dừng đếm thời gian (giữ nguyên thời gian hiện tại)
    * Khi bấm "Tiếp tục": Tiếp tục đếm thời gian từ thời điểm hiện tại
    * Khi bấm "Hoàn thành": Dừng đếm và lưu tổng thời gian di chuyển
  - **Tính toán kcal**: 
    * Công thức: `Kcal = MET × thời gian di chuyển (giờ) × cân nặng (kg)`
    * Chỉ tính dựa trên thời gian di chuyển (không tính thời gian pause)
    * Cập nhật real-time khi thời gian thay đổi (chỉ khi đang di chuyển)
    * MET values: Aerobic (7.0), Yoga (3.0), Gym (6.0), Khiêu vũ (4.8), Calisthenics (8.0), Boxing (12.0), Nhảy dây (10.0)
  - **Không có**: Quãng đường, tốc độ (vì không có GPS)
  - Lưu vào collection `activities` với `activityType` là indoor activity, `duration` (chỉ tính thời gian di chuyển)
  - Màn hình Activity Detail cho indoor activities: Chỉ hiển thị thông tin (thời gian di chuyển, kcal, ghi chú), không có bản đồ

### Phase 4: Đồng bộ dữ liệu
- **4.1 Xử lý offline:**
  - Lưu dữ liệu local khi mất internet
  - Queue các thao tác chưa sync
- **4.2 Tạo `SyncService`:**
  - Method `syncPendingData()`: Đồng bộ dữ liệu chưa sync
  - Method `checkSyncStatus()`: Kiểm tra trạng thái sync
- **4.3 Tự động sync:**
  - Sync khi có internet trở lại
  - Sync khi app mở
  - Hiển thị indicator khi đang sync
- **4.4 Xử lý conflict:**
  - Nếu có dữ liệu trên nhiều thiết bị
  - Ưu tiên dữ liệu mới nhất
  - Hoặc merge nếu có thể

### Phase 5: UI/UX và tối ưu
- **5.1 Tối ưu GPS tracking:**
  - Cập nhật vị trí GPS mỗi 3-5 giây để thêm điểm vào segment hiện tại
  - Filter các điểm GPS không hợp lệ (loại bỏ điểm quá xa hoặc không hợp lý)
  - Tối ưu hiển thị polyline segments (smooth line, không quá nhiều điểm gây lag)
  - Giới hạn số điểm lưu vào Firestore: Mỗi segment tối đa 500-1000 điểm (nếu nhiều hơn, chỉ lưu mỗi điểm thứ N)
  - Khi pause/resume: Đảm bảo không nối các segment lại với nhau (tính quãng đường chính xác)
- **5.2 Battery optimization:**
  - Sử dụng location accuracy phù hợp
  - Tắt GPS khi không cần
- **5.3 Error handling:**
  - Xử lý khi GPS không khả dụng
  - Xử lý khi mất kết nối internet
  - Retry mechanism cho sync

---

## Cấu trúc File Dự Kiến

```
lib/
├── models/
│   └── gps_route.dart         # Model GPSRoute
├── services/
│   ├── gps_tracking_service.dart  # GPSTrackingService
│   ├── heart_rate_service.dart  # HeartRateService (kết nối BLE)
│   ├── sync_service.dart      # SyncService
│   └── export_service.dart    # ExportService
├── screens/
│   ├── gps_tracking/
│   │   ├── gps_tracking_screen.dart
│   │   └── activity_detail_screen.dart
│   └── export/
│       └── export_screen.dart
└── widgets/
    ├── map_widget.dart        # Widget bản đồ với polyline segments
    ├── gps_marker.dart        # Marker điểm bắt đầu/kết thúc
    ├── route_segments.dart    # Widget vẽ nhiều polyline segments (mỗi segment riêng biệt)
    └── heart_rate_widget.dart # Widget hiển thị nhịp tim real-time
```

---

## Schema Firestore

### Collection: `gps_routes`
```dart
{
  id: string (document ID - auto),
  userId: string,
  activityId: string,  // Reference to activities/<id>
  startPoint: {
    lat: double,
    lng: double,
    timestamp: Timestamp
  },
  endPoint: {
    lat: double,
    lng: double,
    timestamp: Timestamp
  },
  segments: array,  // [{points: [{lat, lng, timestamp}, ...], startTime, endTime}, ...]
  totalDistance: double,  // km (tính từ tổng khoảng cách TRONG các segment, không tính khoảng cách giữa các segment)
  totalDuration: int,  // seconds (CHỈ tính thời gian di chuyển trong các segment, KHÔNG tính thời gian pause)
  averageSpeed: double,  // km/h (dựa trên totalDistance và totalDuration - chỉ tính di chuyển)
  calories: double,  // kcal (tính từ quãng đường trong segments, thời gian di chuyển, cân nặng, loại hoạt động)
  createdAt: Timestamp
}
```

---

## Security Rules Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // GPS Routes collection
    match /gps_routes/{routeId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

> Sau khi hoàn thành Plan 4, có thể chuyển sang Plan 5: Kế hoạch Tập luyện & Chatbot AI.

