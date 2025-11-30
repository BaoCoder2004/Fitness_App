# Công Nghệ Sử Dụng - Ứng Dụng Fitness với AI Coaching

## Tổng Quan
Danh sách các công nghệ, framework, thư viện và API sẽ được sử dụng trong dự án.

**Lưu ý quan trọng**: Tất cả dữ liệu chính của ứng dụng sẽ được lưu trữ trong **Cloud Firestore**. SharedPreferences chỉ dùng cho cài đặt và preferences nhỏ.

---

## 📱 Framework & Ngôn Ngữ

### Flutter
- **Version**: 3.10.0+ (hoặc mới hơn)
- **Lý do**: Framework cross-platform, phát triển nhanh, hiệu năng tốt
- **Sử dụng cho**: Toàn bộ ứng dụng Android

### Dart
- **Version**: Tương thích với Flutter SDK
- **Lý do**: Ngôn ngữ chính của Flutter
- **Sử dụng cho**: Logic nghiệp vụ, xử lý dữ liệu

---

## 🔥 Backend & Database

### Firebase Core
- **Package**: `firebase_core: ^2.24.2`
- **Lý do**: Package cơ bản để khởi tạo Firebase
- **Sử dụng cho**: Setup và cấu hình Firebase

### Firebase Authentication
- **Package**: `firebase_auth: ^4.15.3`
- **Lý do**: Xác thực người dùng nhanh, bảo mật, hỗ trợ Google Sign-In
- **Sử dụng cho**: 
  - Đăng nhập/Đăng ký với email/password
  - Đăng nhập với Google

### Cloud Firestore (Database chính)
- **Package**: `cloud_firestore: ^4.13.6`
- **Lý do**: 
  - Database NoSQL real-time
  - Tự động sync giữa các thiết bị
  - Dễ sử dụng, không cần quản lý server
  - Hỗ trợ offline với cache
- **Lưu trữ tất cả dữ liệu chính**:
  - ✅ Thông tin người dùng (Profile)
  - ✅ Lịch sử buổi tập (Activity sessions)
  - ✅ Lịch sử thay đổi cân nặng
  - ✅ Mục tiêu và tiến độ  
  - ✅ Lịch sử chat với AI
  - ✅ Kế hoạch tập luyện
  - ✅ Insights từ AI
  - ✅ Route GPS (các điểm GPS của buổi tập)

---

## 🎯 State Management

### Provider
- **Package**: `provider: ^6.1.1`
- **Lý do**: State management đơn giản, dễ học, phù hợp với Flutter
- **Sử dụng cho**:
  - Quản lý state của authentication
  - Quản lý state của dữ liệu sức khỏe
  - Quản lý state của chat với AI
  - Quản lý state của GPS tracking

---

## 📍 Location & GPS

### Geolocator
- **Package**: `geolocator: ^10.1.0`
- **Lý do**: Package phổ biến và ổn định cho GPS tracking
- **Sử dụng cho**:
  - Lấy vị trí GPS
  - Theo dõi quãng đường
  - Tính tốc độ
  - Lưu route (sau đó lưu vào Firestore)

### OpenStreetMap
- **Package**: `flutter_map: ^6.1.0`
- **Package phụ**: `latlong2: ^0.9.1` (cần thiết cho flutter_map)
- **Lý do**: 
  - ✅ Miễn phí hoàn toàn, không cần API key
  - ✅ Mã nguồn mở, tùy chỉnh cao
  - ✅ Hỗ trợ offline tốt
  - ✅ Đủ tính năng cho đồ án tốt nghiệp
- **Sử dụng cho**:
  - Hiển thị bản đồ real-time khi đang tập
  - Vẽ route đã chạy (polyline)
  - Xem lại các buổi tập trên bản đồ
  - Hiển thị marker vị trí hiện tại
- **Tile Provider**: OpenStreetMap tiles (miễn phí, mặc định)
- **Tài liệu**: [flutter_map documentation](https://docs.flettermap.com/)

---

## 📊 UI & Visualization

### Biểu Đồ
- **Package**: `fl_chart: ^0.65.0`
- **Lý do**: Thư viện biểu đồ mạnh, đẹp, dễ tùy chỉnh, miễn phí
- **Sử dụng cho**:
  - Biểu đồ xu hướng cân nặng
  - Biểu đồ quãng đường
  - Biểu đồ kcal tiêu thụ
  - Biểu đồ thời gian tập luyện
  - Biểu đồ so sánh các kỳ
  - Biểu đồ nhịp tim theo thời gian (cho indoor activities với heart rate monitor)

### Material Design 3
- **Built-in Flutter**
- **Lý do**: Design system hiện đại, đẹp
- **Sử dụng cho**: Toàn bộ UI của ứng dụng

---

## 🤖 AI & Machine Learning

### Google Gemini API
- **Package**: `google_generative_ai: ^0.2.2` (hoặc mới hơn)
- **Lý do**: 
  - API AI mạnh, hỗ trợ tiếng Việt tốt
  - Miễn phí với giới hạn (đủ cho đồ án)
  - Dễ tích hợp
- **Sử dụng cho**:
  - Chatbot trả lời câu hỏi về sức khỏe
  - Phân tích dữ liệu người dùng
  - Đưa ra gợi ý cá nhân hóa
  - Tạo kế hoạch tập luyện tự động
- **Lưu ý**: Cần API key (miễn phí), không commit vào git

### HTTP Client
- **Package**: `http: ^1.1.2`
- **Lý do**: Gọi API HTTP (backup nếu package trên không đủ)
- **Sử dụng cho**: Gọi Gemini API (nếu cần)

---

## 💾 Local Storage (Chỉ cho Settings)

### SharedPreferences
- **Package**: `shared_preferences: ^2.2.2`
- **Lý do**: Lưu trữ dữ liệu đơn giản local
- **Lưu ý**: Chỉ dùng cho settings, KHÔNG lưu dữ liệu chính
- **Sử dụng cho**:
  - Lưu cài đặt người dùng (theme, ngôn ngữ)
  - Lưu trạng thái đăng nhập (tạm thời)
  - Các preferences nhỏ khác

### Path Provider
- **Package**: `path_provider: ^2.1.1`
- **Lý do**: Lấy đường dẫn thư mục trên thiết bị
- **Sử dụng cho**: Lưu file PDF, Excel khi export

---

## 🔔 Notifications

### Local Notifications (Scheduled)
- **Package**: `flutter_local_notifications: ^17.2.0`
- **Package phụ**: `timezone: ^0.9.4` (cần cho scheduled notifications)
- **Lý do**: Hiển thị thông báo local và scheduled notifications
- **Sử dụng cho**: 
  - Thông báo nhắc nhở tập luyện hàng ngày (scheduled)
  - Thông báo nhắc nhở theo lịch (scheduled)
  - Thông báo nhắc nhở kiểm tra tiến độ mục tiêu (scheduled)
  - Thông báo đạt mục tiêu
  - Thông báo có insight mới từ AI
---

## 🛠️ Utilities & Helpers

### Intl
- **Package**: `intl: ^0.19.0`
- **Lý do**: Format ngày tháng, số, tiền tệ
- **Sử dụng cho**:
  - Format ngày tháng trong lịch sử
  - Format số (cân nặng, quãng đường, kcal)

### Path
- **Package**: `path: ^1.8.3`
- **Lý do**: Xử lý đường dẫn file
- **Sử dụng cho**: Tạo file PDF, Excel

---

## 📤 Export & Sharing

### PDF Generation
- **Package**: `pdf: ^3.10.0` hoặc `printing: ^5.12.0`
- **Lý do**: Tạo file PDF
- **Sử dụng cho**: Xuất báo cáo sức khỏe ra PDF

### Excel/CSV Export
- **Package**: `excel: ^2.1.0` hoặc `csv: ^5.0.2`
- **Lý do**: Tạo file Excel/CSV
- **Sử dụng cho**: Xuất dữ liệu ra Excel để phân tích

### Share Plus
- **Package**: `share_plus: ^7.2.1`
- **Lý do**: Chia sẻ file
- **Sử dụng cho**: Chia sẻ báo cáo PDF/Excel

---

## 🧪 Testing

### Flutter Test
- **Built-in Flutter**
- **Lý do**: Unit testing và widget testing
- **Sử dụng cho**: Test các chức năng cơ bản

### Mockito (Optional)
- **Package**: `mockito: ^5.4.4`
- **Lý do**: Tạo mock objects cho testing
- **Sử dụng cho**: Test với Firebase, API calls

---

## 🧮 Tính Toán & Công Thức

### BMI Calculation
- **Công thức**: `BMI = weight (kg) / (height (m))²`
- **Implementation**: Custom Dart code
- **Sử dụng cho**: Tính chỉ số BMI

### BMR Calculation (Harris-Benedict)
- **Công thức**: 
  - **Nam**: `BMR = 10 × weight + 6.25 × height - 5 × age + 5`
  - **Nữ**: `BMR = 10 × weight + 6.25 × height - 5 × age - 161`
- **Implementation**: Custom Dart code
- **Sử dụng cho**: Tính tỷ lệ trao đổi chất cơ bản

### TDEE Calculation
- **Công thức**: `TDEE = BMR × Activity Factor`
- **Activity Factor**: 
  - Ít vận động: 1.2
  - Vận động nhẹ: 1.375
  - Vận động vừa: 1.55
  - Vận động nhiều: 1.725
  - Rất nhiều: 1.9
- **Implementation**: Custom Dart code
- **Sử dụng cho**: Tính tổng năng lượng tiêu hao

### MET (Metabolic Equivalent)
- **Nguồn**: Compendium of Physical Activities
- **Implementation**: Custom Dart code với bảng MET values
- **Sử dụng cho**: Tính kcal tiêu thụ cho hoạt động tại nhà
- **Công thức**: `Kcal = MET × weight (kg) × time (hours)`

### Calories từ GPS
- **Công thức**: Dựa trên quãng đường, thời gian, cân nặng và loại hoạt động
- **Implementation**: Custom Dart code
- **Sử dụng cho**: Tính kcal tiêu thụ cho hoạt động ngoài trời

### Calories với Heart Rate (Cải thiện)
- **Công thức**: Cải thiện tính toán kcal dựa trên nhịp tim (nếu có dữ liệu heart rate)
- **Implementation**: Custom Dart code
- **Sử dụng cho**: Tính kcal chính xác hơn cho indoor activities khi có thiết bị đo nhịp tim
- **Lưu ý**: Chỉ áp dụng cho indoor activities, không áp dụng cho GPS activities

---

## 💓 Heart Rate Monitor (Tùy chọn)

### Flutter Blue Plus
- **Package**: `flutter_blue_plus: ^1.30.0` (hoặc `flutter_blue: ^0.8.0`)
- **Lý do**: Kết nối Bluetooth Low Energy (BLE) với thiết bị đo nhịp tim
- **Sử dụng cho**:
  - Quét và kết nối với thiết bị đo nhịp tim (heart rate monitor, smartwatch, fitness tracker)
  - Đọc dữ liệu nhịp tim real-time qua BLE
  - Hỗ trợ Heart Rate Service (UUID: 0x180D)
  - Hiển thị nhịp tim real-time trong khi tập (chỉ cho indoor activities)
  - Tính toán Heart Rate Zones (Fat Burn, Cardio, Peak)
- **Heart Rate Zones**:
  - **Fat Burn Zone**: 50-60% max HR
  - **Cardio Zone**: 60-70% max HR
  - **Peak Zone**: 70-85% max HR
  - **Max HR**: 220 - age
- **Lưu ý**: 
  - Tính năng tùy chọn, người dùng có thể không có thiết bị đo nhịp tim
  - Chỉ áp dụng cho indoor activities, không áp dụng cho GPS activities

## 🔐 Permissions

### Permission Handler
- **Package**: `permission_handler: ^11.0.1`
- **Lý do**: Quản lý permissions trên Android
- **Sử dụng cho**:
  - Location permission (GPS) - **Bắt buộc**
  - Bluetooth permission - **Tùy chọn** (nếu sử dụng heart rate monitor)
  - Notification permission - **Tùy chọn**

---

## 📦 Tóm Tắt Dependencies

### Dependencies chính (từ pubspec.yaml):
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase (Backend chính)
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6  # Database chính - lưu TẤT CẢ dữ liệu
  
  # State Management
  provider: ^6.1.1
  
  # Location & Maps
  geolocator: ^10.1.0
  flutter_map: ^6.1.0
  latlong2: ^0.9.1
  
  # Heart Rate Monitor (Tùy chọn)
  flutter_blue_plus: ^1.30.0  # Kết nối BLE với thiết bị đo nhịp tim
  
  # Charts
  fl_chart: ^0.65.0
  
  # AI
  google_generative_ai: ^0.2.2
  http: ^1.1.2
  
  # Local Storage (chỉ cho settings)
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Notifications
  # workmanager: ^0.5.2  # Tạm thời comment - không tương thích với Flutter embedding mới
  flutter_local_notifications: ^17.2.0
  
  # Utilities
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0  # Đọc file .env
  
  # Export
  pdf: ^3.10.0
  excel: ^2.1.0
  share_plus: ^7.2.1
  
  # Permissions
  permission_handler: ^11.0.1
```

---

## ⚠️ Lưu Ý Quan Trọng

1. **Database**: 
   - ✅ **TẤT CẢ dữ liệu chính lưu vào Firestore** (buổi tập, cân nặng, mục tiêu, chat, v.v.)
   - ✅ SharedPreferences CHỈ dùng cho settings/preferences nhỏ
   - ✅ Firestore tự động sync giữa các thiết bị

2. **API Keys**: 
   - Cần API key cho **Google Gemini** (miễn phí)
   - **KHÔNG** cần API key cho OpenStreetMap
   - ⚠️ **KHÔNG commit API keys vào git**, dùng environment variables

3. **Firebase Setup**: 
   - Cần tạo Firebase project
   - Cấu hình Android app trong Firebase Console
   - Tải file `google-services.json`

4. **Permissions**: 
   - Cần khai báo Location permission trong `AndroidManifest.xml`
   - Request permission runtime khi cần

5. **Testing**: 
   - Nên test trên thiết bị thật để kiểm tra GPS
   - Test notifications trên thiết bị thật

6. **Version numbers**: 
   - Các version trên là tham khảo
   - Nên kiểm tra version mới nhất trên [pub.dev](https://pub.dev)

---

## 📚 Tham Khảo

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Google Gemini API](https://ai.google.dev/docs)
- [flutter_map Documentation](https://docs.flettermap.com/)
- [pub.dev](https://pub.dev) - Package repository
