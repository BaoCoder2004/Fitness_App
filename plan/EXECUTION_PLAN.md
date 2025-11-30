## Roadmap triển khai từng Plan & Phase

> Mục tiêu: đảm bảo khi bắt đầu coding luôn biết bước tiếp theo là gì, bám sát các plan đã mô tả. Với mỗi plan, ưu tiên hoàn thành Phase theo thứ tự, chỉ chuyển sang Phase mới khi Phase trước ổn định (đã test cơ bản).

---

### Plan 1 – Authentication, Profile & Activity Tracking

1. **Phase 1 – Firebase Auth + Users collection**
   - ✅ Bật Email/Password, Google Sign-In.
   - ✅ Hoàn thiện models (`AppUser`, `UserProfile`), service `AuthService`, `UserProfileRepository`.
   - ✅ Viết Firestore rules cho `users`, `weight_history`, `activities`.
2. **Phase 2 – UI Auth & Profile Form** ✅
   - Tạo `AuthGate`, màn hình Đăng nhập/Đăng ký/Xác thực email, validation.
   - Kết nối Provider/viewmodel cho form state.
3. **Phase 3 – Tích hợp logic Auth + Profile** ✅
   - Liên kết form với `AuthService`, handle exceptions, tạo document `users/<uid>` sau signUp.
   - Đồng bộ profile (update DisplayName, avatar).
4. **Phase 4 – Profile screen & weight history** ✅
   - UI Hồ sơ, Edit profile, Weight history list.
   - Service `WeightHistoryRepository`, auto append khi update cân nặng.
5. **Phase 5 – Route guard & trải nghiệm** ✅
   - Bảo vệ route, persist session, SharedPreferences cho settings.
6. **Phase 6 – Testing** ✅
   - Unit test services, widget test form.
7. **Phase 7 – Dashboard cơ bản** ✅
   - `DashboardService`, cards thống kê hôm nay, nút “Bắt đầu tập”, hoạt động gần đây.
8. **Phase 8 – Activity tracking (basic)** ✅
   - Outdoor GPS (geolocator), indoor timer, calorie calc, heart rate optional.
9. **Phase 9 – Activity history**
   - Lịch sử buổi tập, filter cơ bản, Activity detail.

> **Checklist trước khi sang Plan 2**: Auth hoàn chỉnh, profile chỉnh sửa được, dashboard hiển thị dữ liệu cơ bản, lưu hoạt động & cân nặng vào Firestore.

---

### Plan 2 – Biểu đồ & Phân tích Sức khỏe

1. Phase 1: Đảm bảo dữ liệu `activities`, `weight_history` đã đồng bộ.
2. Phase 2: `HistoryService`, filter ngày/tuần/tháng, search.
3. Phase 3: Biểu đồ (`fl_chart`) cho cân nặng/quãng đường/kcal/thời gian.
4. Phase 4: BMI calculator + cảnh báo.
5. Phase 5: Streak logic, lưu `streaks` collection.
6. Phase 6: Tối ưu UI & loading/empty state.

> Checklist: Statistics screen có đủ tab, BMI hiển thị, streak hoạt động.

---

### Plan 3 – Mục tiêu & Thống kê chi tiết

1. Phase 1: CRUD `goals`, form đặt mục tiêu.
2. Phase 2: Tính tiến độ, hiển thị card goals (tab Đang theo dõi/Đã hoàn thành).
3. Phase 3: NotificationService (local notifications), settings cho nhắc nhở.
4. Phase 4: BMR/TDEE calculator.
5. Phase 5: Statistics detail theo ngày/tuần/tháng/năm, milestone.
6. Phase 6: UI/UX polish.

> Checklist: Drawer “Mục tiêu” hoạt động, notifications nhắc nhở, stats so sánh kỳ trước.

---

### Plan 4 – GPS Tracking nâng cao & Export

1. Phase 1: GPSTrackingService với segments, flutter_map, polyline realtime.
2. Phase 2: Lưu route vào `gps_routes`, xem lại route (tab GPS Routes).
3. Phase 3: Activity detail với map, stats GPS.
4. Phase 4: SyncService offline → online.
5. Phase 5: ExportService (PDF/Excel) + chia sẻ.
6. Phase 6: Tối ưu performance, battery, error handling.

> Checklist: GPS route tab hiển thị, export PDF/Excel chạy được.

---

### Plan 5 – Kế hoạch tập luyện & Chatbot AI

1. Phase 1: `training_plans` predefined, list & detail.
2. Phase 2: `user_active_plans`, progress tracking, đánh dấu hoàn thành.
3. Phase 3: Custom plans (create/edit), schedule.
4. Phase 4: Tích hợp Gemini API (`GeminiService`), chat UI (tab Chat AI).
5. Phase 5: Chat logic, gợi ý câu hỏi, error handling.
6. Phase 6: Lưu lịch sử chat (`chat_history`), xem/xóa.
7. Phase 7: Format reply, typing indicator, retry.

> Checklist: Drawer “Kế hoạch Tập luyện” hoàn chỉnh, AI chat tab dùng được và lưu lịch sử.

---

### Plan 6 – AI Coaching & Insights

1. Phase 1: DataAnalyzer (weight trend, activity level, habits, GPS).
2. Phase 2: DataSummarizer → context cho AI.
3. Phase 3: AICoachService gọi Gemini để phân tích và gợi ý.
4. Phase 4: Tab “AI Insights” (list/detail, lưu `ai_insights`).
5. Phase 5: Auto insights khi có dữ liệu mới, notification.
6. Phase 6: AI tạo kế hoạch tự động, điều chỉnh theo tiến độ.
7. Phase 7: UX hoàn thiện, cache & error handling.

> Checklist: Tab Insights hiển thị phân tích, có thể trigger phân tích mới và lưu lịch sử.

---

### Quy trình làm việc đề xuất
1. **Trước mỗi plan**: Đọc lại checklist trên, đảm bảo dependency/permission cần thiết đã thêm.
2. **Mỗi phase**:
   - Tạo task nhỏ trong tracker (vd. Trello/Jira) nếu cần.
   - Xây dựng service/domain trước, sau đó UI.
   - Viết test cơ bản khi xong phase.
3. **Sau mỗi plan**:
   - Regression test các tính năng trước đó.
   - Rà soát security rules + indexes liên quan (xem `plan/FIRESTORE_INDEXES.md`).
   - Cập nhật tài liệu (README, CHANGELOG, đây).

Giữ file này cập nhật khi phát sinh thay đổi trong yêu cầu hoặc khi bạn quyết định điều chỉnh thứ tự phase.


