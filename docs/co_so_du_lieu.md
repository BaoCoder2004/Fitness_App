# Cơ sở dữ liệu & Mapping Firestore

## 1. Collections chính
- `users`
- `unlock_requests`

## 2. Subcollections (theo userId)
- `users/{userId}/activities`
- `users/{userId}/gps_routes`
- `users/{userId}/goals`
- `users/{userId}/streaks`
- `users/{userId}/weight_history`
- `users/{userId}/chat_history`
- `users/{userId}/ai_insights`

## 3. Bảng chính (9 bảng) và mapping

| Bảng | Collection | Entity | Model | Repo triển khai |
|------|------------|--------|-------|-----------------|
| User | `users` | `AppUser` | `UserProfileModel`/`AppUserModel` (tùy file) | `FirestoreUserProfileRepository`, Auth repo |
| Activity | `users/{uid}/activities` | `ActivitySession` | `ActivitySessionModel` | `FirestoreActivityRepository` |
| GPS Routes | `users/{uid}/gps_routes` | `GpsRoute` | `GpsRouteModel` | `FirestoreGpsRouteRepository` |
| Streak | `users/{uid}/streaks` | `Streak` | `StreakModel` | `FirestoreStreakRepository` |
| Weight Record | `users/{uid}/weight_history` | `WeightRecord` | `WeightRecordModel` | `FirestoreWeightHistoryRepository` |
| Goal | `users/{uid}/goals` | `Goal` | `GoalModel` | `FirestoreGoalRepository` |
| Chat Conversation | `users/{uid}/chat_history` | `ChatConversation` | `ChatConversationModel` | `FirestoreChatRepository` |
| AI Insights | `users/{uid}/ai_insights` | `AIInsight` | `AIInsightModel` | `FirestoreAIInsightRepository` |
| Unlock Request | `unlock_requests` | `UnlockRequest` | `UnlockRequestModel` | `FirestoreUnlockRequestRepository` |

## 4. Thuộc tính chính (tóm tắt)
- User: uid, email, name, role (user/admin), status (active/blocked), profile info.
- Activity: id, userId, type, duration, distance, calories, startTime, endTime.
- GPS Route: id, userId, activityId, polyline/points, distance, duration.
- Goal: id, userId, goalType (daily/weekly/monthly/yearly), targetType, targetValue, currentValue, deadline, reminder (hour/minute/enabled), status.
- Streak: id, userId, currentStreak, longestStreak, lastDate.
- Weight Record: id, userId, weight, recordedAt.
- Chat Conversation: id, userId, messages (embedded), createdAt, title/summary (nếu có).
- AI Insight: id, userId, title, content, score/priority (nếu có), createdAt.
- Unlock Request: id, userId, userEmail, userName, reason, note, status (pending/approved/rejected), createdAt.

### 4.1 Mẫu document (tham khảo)
- `users/{uid}`:
  ```json
  { "uid": "u1", "email": "a@b.com", "name": "A", "role": "user", "status": "active" }
  ```
- `users/{uid}/goals/{goalId}`:
  ```json
  { "goalType": "weekly", "targetType": "duration", "targetValue": 150, "currentValue": 40,
    "deadline": "<Timestamp>", "reminderEnabled": true, "reminderHour": 8, "reminderMinute": 0,
    "status": "in_progress" }
  ```
- `users/{uid}/activities/{id}`:
  ```json
  { "type": "run_outdoor", "duration": 1800, "distance": 5.2, "startTime": "<Timestamp>", "endTime": "<Timestamp>" }
  ```
- `users/{uid}/gps_routes/{id}`:
  ```json
  { "activityId": "<activityId>", "points": [ { "lat": 10.1, "lng": 106.7 }, ... ], "distance": 5.2, "duration": 1800 }
  ```
- `unlock_requests/{id}`:
  ```json
  { "userId": "u1", "userEmail": "a@b.com", "userName": "A",
    "reason": "Tôi bị khóa nhầm", "note": "Ghi chú tuỳ chọn",
    "status": "pending", "createdAt": "<Timestamp>" }
  ```

## 5. Firestore rules (tóm tắt phần unlock_requests)
```
match /unlock_requests/{requestId} {
  allow create: if request.resource.data.keys().hasAll(['userEmail', 'userName', 'createdAt'])
                && request.resource.data.status == 'pending';
  allow read, update, delete: if isAuthenticated(); // admin
}
```

## 6. Lý do dùng subcollection per-user
- Giảm fan-out, query nhanh theo userId.
- Bảo mật: rules dễ giới hạn theo `request.auth.uid == userId`.
- Dữ liệu lớn (activities, goals, routes) tách riêng từng user, tránh quét toàn bộ.

## 7. Ghi chú thực hành tốt
- Thời gian: dùng `Timestamp` của Firestore, convert tại Model (đã fix ở `unlock_request_model.dart` cho cả Timestamp/DateTime/String).
- Chỉ mục (nếu cần): tạo composite index cho các query lọc trạng thái + sắp xếp ngày (tuỳ nhu cầu thực tế).
- Kiểu dữ liệu: lưu loại hoạt động/goal ở dạng string enum (đủ cho phạm vi app).
- Query phổ biến và index gợi ý:
  - `unlock_requests` lọc `status` + `orderBy createdAt` → cần index nếu bật rule strict.
  - `goals` lọc `status` hoặc `deadline` có thể cần index nếu thêm `orderBy`.
  - Các subcollection theo user thường chỉ query trên `userId` (đường dẫn đã cố định) nên ít cần index phức tạp.

