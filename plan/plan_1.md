## Kế hoạch triển khai Plan 1: Authentication, Profile & Activity Tracking

**⚠️ Lưu ý về UI Text:**
- **TẤT CẢ tên chức năng, nút bấm, label, thông báo trên giao diện phải bằng TIẾNG VIỆT**
- Ví dụ: "Đăng nhập", "Đăng ký", "Trang chủ", "Hoạt động", "Hồ sơ", "Bắt đầu tập", "Lịch sử", "Lưu", "Xóa", v.v.
- Ngoại lệ: Tên hoạt động như "Gym", "Yoga", "Calisthenics", "Boxing" có thể giữ nguyên

### Phase 1: Thiết lập Firebase Auth + Users collection
- **1.1 Bật Email/Password Auth** trong Firebase console, kiểm tra SHA1 nếu cần.
- **1.2 Bật Google Sign-In** trong Firebase console (nếu cần).
- **1.3 Rà soát dependencies** (`firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`).
- **1.4 Định nghĩa mô hình `AppUser`** (uid, email, displayName, photoUrl, createdAt, lastLogin).
- **1.5 Chuẩn bị `UserProfile` schema** cho collection `users`:
  - Thông tin cơ bản: name, age, height (cm), weight (kg), gender
  - Avatar URL
  - Preferences: theme, language
  - Timestamps: createdAt, updatedAt
- **1.6 Khởi tạo `AuthService` + `UserProfileService`:**
  - AuthService: `signIn`, `signUp`, `signOut`, `signInWithGoogle`, `sendPasswordReset`, `updateDisplayName`, `sendEmailVerification`, `isEmailVerified`.
  - UserProfileService: CRUD với Firestore (`users/<uid>`), đồng bộ metadata.

### Phase 2: UI/UX cho luồng Auth & Profile cơ bản
- **2.1 AuthGate/Splash**: Lắng nghe `authStateChanges()` để điều hướng Dashboard ↔ AuthStack. Kiểm tra `emailVerified` để điều hướng đến màn hình xác thực email nếu chưa xác thực.
- **2.2 Màn Đăng nhập**: 
  - Email, password
  - "Quên mật khẩu"
  - Nút "Đăng nhập với Google"
  - Chuyển sang SignUp
  - Hiển thị thông báo lỗi nếu email chưa được xác thực
- **2.3 Màn Đăng ký**: 
  - Email, password, confirm password
  - Tên hiển thị
  - Chọn avatar mặc định (hoặc upload sau)
  - Sau khi đăng ký thành công, tự động điều hướng đến màn hình xác thực email
- **2.4 Màn hình Xác thực Email**:
  - Hiển thị thông báo đã gửi email xác thực đến địa chỉ email của người dùng
  - Nút "Đã xác thực? Kiểm tra ngay": Kiểm tra trạng thái xác thực và tự động đăng nhập nếu đã xác thực
  - Nút "Gửi lại email xác thực": Gửi lại email nếu chưa nhận được
  - Hộp thông tin với lưu ý về email spam và thời hạn liên kết
  - Nút "Quay lại đăng nhập": Đăng xuất và quay lại màn hình đăng nhập
- **2.5 Validation realtime** + hiển thị lỗi thân thiện:
  - Email không hợp lệ
  - Mật khẩu yếu (tối thiểu 6 ký tự)
  - Password không khớp
- **2.6 Loading states/disable button** + toast/snackbar phản hồi.

### Phase 3: Tích hợp logic Auth & User Profile
- **3.1 Kết nối form với AuthService**, xử lý exception cụ thể:
  - Email đã tồn tại
  - Mật khẩu sai
  - Email không hợp lệ
  - Mạng không kết nối
  - Email chưa được xác thực (khi đăng nhập)
- **3.2 Sau `signUp`:** 
  - Tạo document `users/<uid>` với profile mặc định
  - Lưu: name, email, createdAt, updatedAt
  - Các field khác (age, height, weight) để null, user sẽ nhập sau
  - **Tự động gửi email xác thực** đến địa chỉ email của người dùng
- **3.3 Sau `signIn`:** 
  - Kiểm tra `emailVerified` của user
  - Nếu email chưa được xác thực → throw exception với thông báo rõ ràng
  - Nếu email đã xác thực → Lấy profile từ Firestore (`users/<uid>`)
  - Cache vào `UserProvider` (ChangeNotifier)
  - Nếu chưa có profile → tạo mặc định
- **3.4 Cho phép cập nhật profile cơ bản:**
  - name, age, height, weight, avatar
  - Sync cả Auth (updateDisplayName) + Firestore
- **3.5 Forgot password:** gọi API và hiển thị thông báo đã gửi email.

### Phase 4: Màn hình Profile & Cập nhật cân nặng
- **4.1 Tạo màn hình Profile:**
  - Hiển thị thông tin: name, age, height, weight, avatar
  - Nút "Chỉnh sửa"
- **4.2 Màn hình Edit Profile:**
  - Form chỉnh sửa: name, age, height, weight
  - Upload/Chọn avatar
  - Validation (age > 0, height > 0, weight > 0)
- **4.3 Cập nhật cân nặng với lịch sử:**
  - Khi cập nhật weight trong Profile, tự động lưu vào collection `weight_history`
  - Lưu: userId, weight, date, createdAt
  - Cho phép chọn ngày (có thể cập nhật cân nặng của ngày trước)
- **4.4 Hiển thị lịch sử cân nặng:**
  - Danh sách các lần cập nhật cân nặng
  - Sắp xếp theo ngày (mới nhất trước)
  - Có thể xem chi tiết từng bản ghi

### Phase 5: Bảo mật, trải nghiệm & route protection
- **5.1 Route guard:** 
  - Dashboard, Profile, Activity Tracking... yêu cầu user đăng nhập
  - Nếu chưa đăng nhập → redirect về Auth screen
- **5.2 Persist session:** 
  - Lắng nghe `authStateChanges()` để tự động điều hướng
  - Lưu trạng thái đăng nhập vào SharedPreferences (tạm thời)
- **5.3 Error logging** (tùy chọn): log login/logout, thất bại
- **5.4 Security rules Firestore:** 
  - Chỉ cho phép user đọc/ghi document `users/<uid>` của chính họ
  - Chỉ cho phép user đọc/ghi `weight_history` của chính họ
  - Rules mẫu: `match /users/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }`
- **5.5 UI polish:** 
  - Animation nhẹ khi chuyển màn hình
  - Loading state khi đang xử lý
  - Empty state khi chưa có profile hoặc chưa có lịch sử cân nặng

### Phase 6: Kiểm thử & mở rộng
- **6.1 Unit test AuthService & UserProfileService** (mock Firebase/Auth).
- **6.2 Widget test form login/register** (validation, loading states).
- **6.3 Test Google Sign-In** (nếu đã implement).
- **6.4 Test cập nhật cân nặng và lưu lịch sử.**
- **6.5 Checklist bảo mật:** 
  - Password policy (tối thiểu 6 ký tự)
  - Giới hạn retry đăng nhập (tùy chọn)
  - Bảo vệ dữ liệu nhạy cảm (không log password)

### Phase 7: Màn hình Dashboard/Trang chủ
- **7.1 Tạo `DashboardService`** để tổng hợp dữ liệu:
  - Method `getTodayStats(userId)`: Lấy tổng hợp dữ liệu hôm nay
  - Method `getWeight(userId)`: Lấy cân nặng hiện tại từ UserProfile
  - Method `getTodayDistance(userId)`: Tổng quãng đường từ hoạt động ngoài trời hôm nay
  - Method `getTodayCalories(userId)`: Tổng kcal từ tất cả hoạt động hôm nay
  - Method `getTodayDuration(userId)`: Tổng thời gian tập luyện hôm nay (giờ:phút)
  - Method `getRecentActivity(userId)`: Lấy hoạt động gần nhất (1 buổi tập mới nhất)
- **7.2 Màn hình Dashboard/Trang chủ - Tổng hợp nhanh:**
  - **AppBar:** "Trang chủ" hoặc "Hôm nay"
  - **Phần tổng hợp chỉ số hôm nay (Cards):**
    - **Card Cân nặng:** Hiển thị cân nặng hiện tại (kg) từ UserProfile
    - **Card Quãng đường:** Tổng quãng đường (km) từ hoạt động ngoài trời hôm nay
    - **Card Kcal:** Tổng kcal tiêu thụ từ tất cả hoạt động hôm nay
    - **Card Thời gian:** Tổng thời gian tập luyện hôm nay (giờ:phút)
  - **Nút "Bắt đầu tập":**
    - Button lớn, nổi bật ở giữa màn hình
    - Navigation đến Activity Selection Screen (Tab "Bắt đầu tập" trong Activity Tab)
  - **Hoạt động gần nhất:**
    - Card hiển thị 1 buổi tập gần nhất
    - Thông tin: ngày, loại hoạt động, quãng đường (nếu có), kcal, thời gian
    - Tap để xem chi tiết
    - Nếu chưa có hoạt động nào: Hiển thị empty state với message khuyến khích
- **7.3 Pull to refresh:**
  - Refresh dữ liệu khi kéo xuống
  - Loading indicator khi đang tải

### Phase 8: Theo dõi Hoạt động (Activity Tracking)
- **Lưu ý về Navigation:** Activity Tracking nằm trong Bottom Navigation Bar với TabBar có 3 tabs:
  - Tab 1: Bắt đầu tập (Activity Selection) - Plan 1
  - Tab 2: Lịch sử (Activity History) - Plan 1
  - Tab 3: GPS Routes (xem lại route trên bản đồ) - Plan 4
- **8.1 Setup dependencies:**
  - `geolocator`: Cho GPS tracking
  - `permission_handler`: Request location permission
- **8.2 Tạo collection `activities`** trong Firestore:
  - Schema: userId, activityType, date, duration, distance, calories, averageSpeed, notes, averageHeartRate, maxHeartRate, heartRateZones, heartRateData, createdAt
  - **Lưu ý**: GPS route chi tiết (segments) sẽ được lưu trong Plan 4 vào collection `gps_routes` riêng
- **8.3 Tạo `ActivityService`:**
  - Method `saveActivity(activity)`: Lưu buổi tập vào Firestore
  - Method `getActivities(userId, dateRange)`: Lấy danh sách buổi tập
  - Method `calculateCalories(activityType, duration, weight, distance?)`: Tính kcal
- **8.4 Hoạt động ngoài trời (có GPS):**
  - Danh sách hoạt động cố định: Chạy, Đi bộ, Đạp xe
  - Màn hình Activity Selection: Chọn loại hoạt động
  - Màn hình GPS Tracking:
    - Request location permission
    - Bắt đầu tracking: `startTracking()`
    - Dừng/Tiếp tục tracking
    - Hiển thị real-time: quãng đường, thời gian, tốc độ trung bình
    - Tính kcal tự động dựa trên quãng đường, thời gian, cân nặng
  - **Lưu ý**: Chỉ lưu thông tin cơ bản (distance, duration, averageSpeed) vào `activities`
  - GPS route chi tiết (segments) sẽ được lưu trong Plan 4 vào collection `gps_routes` riêng
  - **Khi bấm "Hoàn thành":**
    * Hiển thị popup/dialog xác nhận với 2 nút:
      - **Xóa**: Không lưu buổi tập, quay lại màn hình trước (dữ liệu sẽ bị mất)
      - **Lưu**: Lưu buổi tập vào Firestore collection `activities`, chuyển đến màn hình Activity Summary
    * Popup hiển thị thông tin tóm tắt: thời gian, quãng đường, kcal (để người dùng quyết định)
- **8.5 Hoạt động tại nhà (không có GPS):**
  - Danh sách hoạt động cố định: Aerobic, Yoga, Gym, Khiêu vũ, Calisthenics, Boxing, Nhảy dây
  - Màn hình Activity Selection: Chọn loại hoạt động
  - Màn hình Indoor Tracking:
    - Timer: Bắt đầu/Dừng/Tiếp tục/Hoàn thành
    - **Tính thời gian**: Chỉ tính thời gian di chuyển (không tính thời gian pause)
      * Khi bấm "Bắt đầu": Bắt đầu đếm thời gian
      * Khi bấm "Tạm dừng": Dừng đếm thời gian (giữ nguyên thời gian hiện tại)
      * Khi bấm "Tiếp tục": Tiếp tục đếm thời gian từ thời điểm hiện tại
      * Khi bấm "Hoàn thành": Dừng đếm và lưu tổng thời gian di chuyển
    - Hiển thị thời gian tập luyện real-time (chỉ khi đang di chuyển)
    - **Tính kcal tự động**: 
      * Công thức: `Kcal = MET × thời gian (giờ) × cân nặng (kg)`
      * Chỉ tính dựa trên thời gian di chuyển (không tính thời gian pause)
      * Cập nhật real-time khi thời gian thay đổi
      * MET values: Aerobic (7.0), Yoga (3.0), Gym (6.0), Khiêu vũ (4.8), Calisthenics (8.0), Boxing (12.0), Nhảy dây (10.0)
      * **Cải thiện tính toán kcal dựa trên nhịp tim** (nếu có dữ liệu nhịp tim)
    - **Theo dõi nhịp tim (Tùy chọn)**:
      * Kết nối với thiết bị đo nhịp tim qua Bluetooth (BLE) - sử dụng `flutter_blue_plus`
      * Hiển thị nhịp tim real-time trên màn hình tracking
      * Hiển thị Heart Rate Zone hiện tại (Fat Burn/Cardio/Peak)
      * Lưu nhịp tim mỗi 5-10 giây vào list (để vẽ biểu đồ sau)
      * Tính nhịp tim trung bình, nhịp tim tối đa trong buổi tập
      * Tính thời gian trong từng zone
    - Field ghi chú (tùy chọn)
  - **Khi bấm "Hoàn thành":**
    * Hiển thị popup/dialog xác nhận với 2 nút:
      - **Xóa**: Không lưu buổi tập, quay lại màn hình trước (dữ liệu sẽ bị mất)
      - **Lưu**: Lưu buổi tập vào Firestore collection `activities` với duration (chỉ tính thời gian di chuyển) và dữ liệu nhịp tim (nếu có), chuyển đến màn hình Activity Summary
    * Popup hiển thị thông tin tóm tắt: thời gian, kcal, nhịp tim trung bình (nếu có) (để người dùng quyết định)
- **8.6 Tính toán kcal:**
  - Tạo `CalorieCalculator` service:
    - Method `calculateGPSActivityCalories(distance, duration, weight, activityType)`: Cho hoạt động ngoài trời
      * duration: Thời gian di chuyển (không tính pause)
    - Method `calculateIndoorActivityCalories(activityType, duration, weight, heartRateData?)`: Cho hoạt động tại nhà
      * duration: Thời gian di chuyển (không tính pause), đơn vị: giờ
      * heartRateData: Dữ liệu nhịp tim (tùy chọn)
      * Nếu có nhịp tim: Sử dụng công thức cải thiện dựa trên nhịp tim
      * Nếu không có: Công thức: `Kcal = MET × duration (hours) × weight (kg)`
    - Bảng MET values cho từng loại hoạt động:
      * Aerobic: 7.0
      * Yoga: 3.0
      * Gym: 6.0
      * Khiêu vũ: 4.8
      * Calisthenics: 8.0
      * Boxing: 12.0
      * Nhảy dây: 10.0    
- **8.7 Theo dõi nhịp tim (Tùy chọn - chỉ cho Indoor activities):**
  - Setup dependencies: `flutter_blue_plus` cho kết nối BLE
  - Request Bluetooth permission
  - Tạo `HeartRateService`:
    - Method `scanDevices()`: Quét các thiết bị BLE hỗ trợ Heart Rate Service
    - Method `connectDevice(deviceId)`: Kết nối với thiết bị đo nhịp tim
    - Method `disconnectDevice()`: Ngắt kết nối
    - Stream `heartRateStream`: Nhận dữ liệu nhịp tim real-time
    - Method `calculateMaxHR(age)`: Tính nhịp tim tối đa (220 - age)
    - Method `getHeartRateZone(heartRate, maxHR)`: Xác định zone hiện tại
  - Tích hợp vào Indoor Tracking:
    - Hiển thị nhịp tim real-time trên màn hình tracking
    - Hiển thị Heart Rate Zone hiện tại (Fat Burn/Cardio/Peak)
    - Lưu nhịp tim mỗi 5-10 giây vào list (để vẽ biểu đồ sau)
    - Tính nhịp tim trung bình, nhịp tim tối đa trong buổi tập
    - Tính thời gian trong từng zone
  - Hiển thị trong Activity Detail (chỉ cho indoor activities):
    - Biểu đồ nhịp tim theo thời gian (LineChart)
    - Hiển thị nhịp tim trung bình, nhịp tim tối đa
    - Hiển thị thời gian trong từng zone
    - Chỉ hiển thị nếu có dữ liệu nhịp tim
- **8.8 Màn hình Activity Summary:**
  - **Chỉ hiển thị khi người dùng chọn "Lưu" trong popup xác nhận** (sau khi bấm "Hoàn thành")
  - Hiển thị thống kê buổi tập: thời gian, quãng đường (nếu có), tốc độ trung bình (nếu có), kcal, nhịp tim (nếu có), ghi chú
  - Cho phép chỉnh sửa: thời gian, ghi chú (trước khi lưu vào Firestore)
  - Nút "Lưu": Lưu vào Firestore collection `activities` và quay lại màn hình trước (Dashboard hoặc Activity History)
  - Nút "Hủy": Hủy bỏ, không lưu (quay lại màn hình tracking, dữ liệu sẽ bị mất)

#### Ghi chú về công thức Calories (Outdoor & Indoor)

- **Nguồn tham chiếu**: Dựa trên phương trình của **ACSM – American College of Sports Medicine** và bảng MET chuẩn.
- **Outdoor (Chạy bộ / Đi bộ với GPS)**  
  - Chỉ tính calories khi **đã có quãng đường thực tế**: nếu `distanceKm <= 0` hoặc thời gian = 0 ⇒ `calories = 0`.  
  - Tốc độ:  
    \[
    v = \frac{\text{distanceKm}}{\text{time (giờ)}} \quad (\text{km/h})
    \]  
  - Đổi sang mét/phút:  
    \[
    v_{\text{m/phút}} = v \times \frac{1000}{60}
    \]  
  - Phân loại: nếu \(v < 7.2\) km/h ⇒ coi là **đi bộ**, ngược lại là **chạy**.  
  - Phương trình ACSM cho \(\mathrm{VO_2}\) (mL/kg/phút):  
    - Đi bộ: \(VO_2 = 0.1 \times v_{\text{m/phút}} + 3.5\)  
    - Chạy: \(VO_2 = 0.2 \times v_{\text{m/phút}} + 3.5\)  
  - Đổi sang kcal/phút rồi nhân thời gian (phút), với \(w\) là cân nặng (kg):  
    \[
    \text{kcal/phút} = \frac{VO_2 \times w}{200}
    \]  
    \[
    \text{Calories} = \text{kcal/phút} \times \text{thời gian (phút)}
    \]

- **Outdoor (Đạp xe với GPS)**  
  - Tốc độ trung bình \(v\) (km/h) được dùng để chọn **MET**:  
    - \(v < 16\) km/h → MET ≈ 4  
    - \(16 \le v < 19\) km/h → MET ≈ 6  
    - \(19 \le v < 23\) km/h → MET ≈ 8  
    - \(v \ge 23\) km/h → MET ≈ 10  
  - Công thức tổng quát: với \(h\) là thời gian (giờ), \(w\) là cân nặng (kg):  
    \[
    \text{Calories} = \text{MET} \times w \times h
    \]
  - Nếu chưa có quãng đường (`distanceKm <= 0`) ⇒ calories = 0.

- **Indoor (Aerobic, Yoga, Gym, Nhảy dây, …)**  
  - Không dùng GPS, chỉ dựa trên MET của từng bài tập:  
    \[
    \text{Calories} = \text{MET(activity)} \times w \times \text{thời gian (giờ)}
    \]  
  - MET được cấu hình sẵn trong `workout_types.dart`, ví dụ:  
    - Aerobic: 7.0  
    - Yoga: 3.0  
    - Gym: 6.0  
    - Khiêu vũ: 4.8  
    - Calisthenics: 8.0  
    - Boxing: 12.0  
    - Nhảy dây: 10.0

> Các công thức trên đều mang tính ước lượng (giống phần lớn app chạy bộ hiện nay), nhưng đủ nhất quán cho việc theo dõi lâu dài và vẽ biểu đồ ở các plan sau.

### Phase 9: Hiển thị lịch sử dữ liệu
- **Lưu ý:** Màn hình Activity History là Tab 2 trong Activity Tab (Bottom Navigation Bar)
- **9.1 Màn hình Activity History:**
  - Danh sách tất cả buổi tập đã lưu
  - Sắp xếp theo ngày (mới nhất trước)
  - Card hiển thị: ngày, loại hoạt động, quãng đường (nếu có), kcal, thời gian
- **9.2 Filter và tìm kiếm:**
  - Filter theo loại hoạt động
  - Filter theo khoảng thời gian (ngày/tuần/tháng/năm)
  - Search bar (tìm trong ghi chú)
- **9.3 Màn hình Activity Detail:**
  - Hiển thị chi tiết buổi tập
  - Thông tin: ngày, loại hoạt động, thời gian, quãng đường, tốc độ trung bình, kcal, ghi chú
  - Nút "Xóa" (với confirm dialog)
- **9.4 Hiển thị lịch sử cân nặng:**
  - Tích hợp vào màn hình Profile hoặc tạo màn hình riêng
  - Danh sách các lần cập nhật cân nặng
  - Hiển thị: ngày, cân nặng, thay đổi so với lần trước
- **9.5 Empty states:**
  - Hiển thị khi chưa có buổi tập nào
  - Icon và message khuyến khích bắt đầu tập luyện

---

## Cấu trúc File Dự Kiến

```
lib/
├── models/
│   ├── app_user.dart          # Model AppUser
│   ├── user_profile.dart      # Model UserProfile
│   ├── weight_record.dart     # Model WeightRecord (cho lịch sử cân nặng)
│   └── activity.dart          # Model Activity (cho buổi tập)
├── services/
│   ├── auth_service.dart      # AuthService
│   ├── user_profile_service.dart  # UserProfileService
│   ├── weight_service.dart   # WeightService (quản lý lịch sử cân nặng)
│   ├── dashboard_service.dart # DashboardService (tổng hợp dữ liệu)
│   ├── activity_service.dart  # ActivityService (quản lý buổi tập)
│   ├── calorie_calculator.dart # CalorieCalculator (tính kcal)
│   └── heart_rate_service.dart # HeartRateService (kết nối BLE với thiết bị đo nhịp tim - chỉ cho Indoor)
│   └── gps_tracking_service.dart  # GPSTrackingService (theo dõi GPS)
├── providers/
│   ├── user_provider.dart     # UserProvider (ChangeNotifier)
│   └── activity_provider.dart # ActivityProvider (quản lý state tracking)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── email_verification_screen.dart  # Màn hình xác thực email
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── weight_history_screen.dart
│   ├── activity/
│   │   ├── activity_selection_screen.dart
│   │   ├── gps_tracking_screen.dart
│   │   ├── indoor_tracking_screen.dart
│   │   ├── activity_summary_screen.dart
│   │   ├── activity_history_screen.dart
│   │   └── activity_detail_screen.dart
└── widgets/
    ├── auth_gate.dart         # AuthGate để điều hướng
    ├── dashboard_card.dart    # Card hiển thị chỉ số trên Dashboard
    └── activity_card.dart     # Card hiển thị buổi tập
```

---

## Schema Firestore

### Collection: `users`
```dart
{
  uid: string (document ID),
  email: string,
  name: string,
  age: int?,
  height: double?,  // cm
  weight: double?,  // kg (cân nặng hiện tại)
  gender: string?,  // 'male' | 'female' | 'other'
  avatarUrl: string?,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  preferences: {
    theme: 'light' | 'dark',
    language: 'vi' | 'en'
  }
}
```

### Collection: `weight_history`
```dart
{
  id: string (document ID - auto),
  userId: string,  // Reference to users/<uid>
  weight: double,  // kg
  date: Timestamp,  // Ngày của bản ghi (có thể là ngày trong quá khứ)
  createdAt: Timestamp,  // Thời điểm tạo bản ghi
  note: string?  // Ghi chú (tùy chọn)
}
```

### Collection: `activities`
```dart
{
  id: string (document ID - auto),
  userId: string,
  activityType: string,  // 'running' | 'walking' | 'cycling' | 'aerobic' | 'yoga' | 'gym' | 'dancing' | 'calisthenics' | 'boxing' | 'jump_rope'
  date: Timestamp,
  duration: int,  // seconds (chỉ tính thời gian di chuyển, không tính pause)
  distance: double?,  // km (null nếu hoạt động tại nhà)
  calories: double,  // kcal
  averageSpeed: double?,  // km/h (null nếu hoạt động tại nhà)
  notes: string?,  // Ghi chú
  // Lưu ý: GPS route chi tiết (segments) sẽ được lưu trong Plan 4 vào collection `gps_routes` riêng
  // Nhịp tim (tùy chọn - chỉ có nếu kết nối thiết bị đo nhịp tim)
  averageHeartRate: int?,  // bpm (beats per minute)
  maxHeartRate: int?,  // bpm
  heartRateZones: {
    fatBurn: int?,  // seconds (thời gian trong Fat Burn zone)
    cardio: int?,  // seconds (thời gian trong Cardio zone)
    peak: int?  // seconds (thời gian trong Peak zone)
  },
  heartRateData: array?,  // Array of {heartRate: int, timestamp: Timestamp} (mỗi 5-10 giây)
  createdAt: Timestamp
}
```

---

## Security Rules Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Weight history collection
    match /weight_history/{recordId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Activities collection
    match /activities/{activityId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

> Sau khi hoàn thành Plan 1, có thể chuyển sang Plan 2: Biểu đồ & Phân tích Sức khỏe.
