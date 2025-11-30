# Danh Sách Chức Năng - Ứng Dụng Theo Dõi Rèn Luyện Sức Khỏe với AI Coaching

## Tổng Quan
Ứng dụng Android theo dõi sức khỏe với chatbot AI Coaching sử dụng Gemini API. Các chức năng được chia thành 6 plan từ dễ đến khó, phù hợp với phạm vi đồ án tốt nghiệp 8 điểm.

**⚠️ Lưu ý quan trọng về UI:**
- **TẤT CẢ tên chức năng, nút bấm, label, thông báo trên giao diện phải bằng TIẾNG VIỆT**
- Các tên tiếng Anh trong tài liệu này (như "Dashboard", "Activity", "Statistics") chỉ là tên biến/tên file trong code
- Trên giao diện người dùng phải hiển thị: "Trang chủ", "Hoạt động", "Thống kê", "Hồ sơ", v.v.
- Ngoại lệ: Tên hoạt động cụ thể như "Gym", "Yoga", "Calisthenics", "Boxing" có thể giữ nguyên

---

## Plan 1: Authentication, Profile & Activity Tracking (Dễ)
**Mục tiêu**: Xây dựng nền tảng xác thực, quản lý profile và theo dõi hoạt động cơ bản

### Chức năng:
1. **Đăng nhập/Đăng ký**
   - Form đăng nhập với email/password
   - Form đăng ký tài khoản mới
   - Validation cơ bản (email format, password độ dài tối thiểu)
   - Đăng nhập với Google Sign-In (tích hợp Firebase Authentication)

2. **Màn hình Profile người dùng**
   - Hiển thị thông tin cá nhân 
   - Cho phép chỉnh sửa: tên, tuổi, chiều cao, cân nặng, avatar
   - Lưu thông tin người dùng vào Firestore
   - Cập nhật cân nặng và tự động lưu lịch sử theo thời gian (để vẽ biểu đồ xu hướng)

3. **Màn hình Dashboard/Trang chủ**
   - Hiển thị tổng quan các chỉ số sức khỏe cơ bản (lấy từ UserProfile và tổng hợp ActivityRecord trong ngày)
   - Card hiển thị: cân nặng hiện tại (từ UserProfile), quãng đường hôm nay (tổng từ hoạt động ngoài trời), kcal tiêu thụ hôm nay (tổng từ tất cả hoạt động), thời gian tập luyện (tổng từ tất cả hoạt động)
   - Navigation đến các màn hình khác

4. **Theo dõi Hoạt động (Activity Tracking)**
   - **Hoạt động ngoài trời (có GPS):**
     - Danh sách hoạt động cố định: Chạy, Đi bộ, Đạp xe
     - Bắt đầu/dừng/tiếp tục/hoàn thành theo dõi hoạt động
     - Tự động đếm quãng đường đã đi được (sử dụng GPS)
     - Tự động tính thời gian tập luyện
     - Tự động tính tốc độ trung bình
     - Tự động tính số kcal tiêu thụ dựa trên quãng đường, thời gian, cân nặng và loại hoạt động (công thức tính từ quãng đường và MET value)
     - Hiển thị thông tin real-time trong khi đang tập
   
   - **Hoạt động tại nhà (không có GPS):**
     - Danh sách hoạt động cố định:
       * Aerobic
       * Yoga
       * Gym 
       * Khiêu vũ
       * Calisthenics 
       * Boxing 
       * Nhảy dây
     - Chọn hoạt động từ danh sách
     - Bắt đầu/dừng/tiếp tục/hoàn thành đếm thời gian tập luyện
     - **Tính thời gian**: Chỉ tính thời gian di chuyển (không tính thời gian pause)
       * Khi bấm "Tạm dừng": Dừng đếm thời gian
       * Khi bấm "Tiếp tục": Tiếp tục đếm thời gian từ thời điểm hiện tại
     - **Tự động tính số kcal tiêu thụ**: 
       * Công thức: `Kcal = MET × thời gian di chuyển (giờ) × cân nặng (kg)`
       * Chỉ tính dựa trên thời gian di chuyển (không tính thời gian pause)
       * Cập nhật real-time khi thời gian thay đổi (chỉ khi đang di chuyển)
       * MET values: Aerobic (7.0), Yoga (3.0), Gym (6.0), Khiêu vũ (4.8), Calisthenics (8.0), Boxing (12.0), Nhảy dây (10.0)
     - **Không có**: Quãng đường, tốc độ (vì không có GPS)
     - **Theo dõi nhịp tim (Tùy chọn)**:
       * Kết nối với thiết bị đo nhịp tim qua Bluetooth (BLE)
       * Hiển thị nhịp tim real-time trong khi đang tập
       * Tính toán Heart Rate Zones:
         - Fat Burn Zone (50-60% max HR)
         - Cardio Zone (60-70% max HR)
         - Peak Zone (70-85% max HR)
       * Lưu dữ liệu nhịp tim vào Firestore (nhịp tim trung bình, nhịp tim tối đa, thời gian trong từng zone)
       * Hiển thị biểu đồ nhịp tim theo thời gian trong Activity Detail
       * Cải thiện tính toán kcal dựa trên nhịp tim (nếu có dữ liệu)
     - Có thể ghi chú thêm về bài tập cụ thể
   
   - **Chung:**
     - Khi bấm "Hoàn thành": Hiển thị popup xác nhận với 2 option:
       * **Xóa**: Không lưu buổi tập, quay lại màn hình trước (dữ liệu sẽ bị mất)
       * **Lưu**: Lưu buổi tập vào Firestore, có thể chuyển đến màn hình Activity Summary để xem lại và chỉnh sửa
     - Xem lại danh sách và chi tiết các buổi tập đã lưu

5. **Hiển thị lịch sử dữ liệu**
   - Danh sách các buổi tập đã lưu
   - Lịch sử thay đổi cân nặng
   - Hiển thị theo ngày
   - Có thể xem chi tiết từng bản ghi

---

## Plan 2: Biểu đồ & Phân tích Sức khỏe (Dễ-Trung bình)
**Mục tiêu**: Hiển thị dữ liệu trực quan qua biểu đồ và tính toán các chỉ số sức khỏe

### Chức năng:
1. **Lưu trữ dữ liệu**
   - Lưu tất cả dữ liệu vào Cloud Firestore (Firebase)
   - Dữ liệu được lưu trên cloud, vẫn còn khi đóng app hoặc cài đặt lại
   - Có thể xóa/sửa dữ liệu cũ từ giao diện

2. **Lọc và tìm kiếm dữ liệu**
   - Lọc dữ liệu theo ngày/tuần/tháng/năm
   - Tìm kiếm trong lịch sử
   - Sắp xếp dữ liệu theo thời gian

3. **Biểu đồ đơn giản**
   - Biểu đồ đường thể hiện xu hướng cân nặng theo thời gian
   - Biểu đồ đường thể hiện tổng quãng đường (tất cả hoạt động ngoài trời) theo thời gian
   - Biểu đồ đường thể hiện tổng số kcal tiêu thụ (tất cả hoạt động) theo thời gian
   - Biểu đồ đường thể hiện tổng thời gian tập luyện (tất cả hoạt động) theo thời gian
   - Có thể xem theo ngày/tuần/tháng/năm
   - Có thể chọn loại biểu đồ để xem (cân nặng, quãng đường, kcal, thời gian tập)

4. **Tính toán chỉ số sức khỏe cơ bản**
   - Tự động tính BMI (Body Mass Index)
   - Hiển thị BMI và phân loại (gầy/bình thường/thừa cân/béo phì)
   - Cảnh báo khi BMI bất thường

5. **Theo dõi chuỗi (Streak)**
   - Đếm số ngày liên tiếp đạt mục tiêu (ví dụ: quãng đường/ngày, thời gian tập/ngày) - mục tiêu có thể là mục tiêu người dùng đặt hoặc mục tiêu mặc định
   - Hiển thị chuỗi hiện tại và chuỗi dài nhất (lưu trong Firestore)
   - Cảnh báo khi sắp mất chuỗi (chưa đạt mục tiêu trong ngày)
   - Thông báo khi đạt milestone (7 ngày, 30 ngày, 100 ngày...)

---

## Plan 3: Mục tiêu & Thống kê Chi tiết (Trung bình)
**Mục tiêu**: Đặt mục tiêu, theo dõi tiến độ và thống kê chi tiết theo thời gian

### Chức năng:
1. **Đặt mục tiêu**
   - Đặt mục tiêu cân nặng (giảm/tăng X kg)
   - Đặt mục tiêu quãng đường/ngày hoặc kcal tiêu thụ/ngày
   - Đặt mục tiêu thời gian tập luyện/tuần
   - Có deadline cho mục tiêu

2. **Theo dõi tiến độ mục tiêu**
   - Hiển thị % hoàn thành mục tiêu
   - Progress bar hoặc circular progress
   - Hiển thị còn bao nhiêu để đạt mục tiêu
   - Thông báo khi đạt mục tiêu

3. **Thông báo nhắc nhở**
   - Nhắc nhở tập luyện hàng ngày
   - Nhắc nhở tập luyện theo lịch
   - Nhắc nhở kiểm tra tiến độ mục tiêu
   - Có thể tắt/bật thông báo

4. **Tính toán chỉ số nâng cao**
   - Tính BMR (Basal Metabolic Rate) - tỷ lệ trao đổi chất cơ bản (dựa trên công thức Harris-Benedict hoặc Mifflin-St Jeor, sử dụng: cân nặng, chiều cao, tuổi, giới tính)
   - Tính TDEE (Total Daily Energy Expenditure) - tổng năng lượng tiêu hao hàng ngày (BMR × hệ số hoạt động + kcal từ hoạt động tập luyện)
   - Hiển thị các chỉ số này trong màn hình thống kê/Profile

5. **Thống kê chi tiết theo thời gian**
   - Thống kê theo ngày: tổng quãng đường, tổng kcal tiêu thụ, thời gian tập luyện
   - Thống kê theo tuần: trung bình, tổng, so sánh với tuần trước
   - Thống kê theo tháng: tổng hợp, xu hướng, so sánh tháng
   - Thống kê theo năm: tổng quan cả năm, các milestone
   - Biểu đồ so sánh giữa các kỳ (tuần này vs tuần trước, tháng này vs tháng trước)

---

## Plan 4: GPS Tracking Nâng Cao & Export (Trung bình-Khó)
**Mục tiêu**: GPS tracking chi tiết với bản đồ, đồng bộ dữ liệu và xuất báo cáo

### Chức năng:
1. **GPS Tracking Nâng Cao - Theo dõi hoạt động chi tiết**
   - Bắt đầu/bắt đầu lại/dừng buổi tập (chạy, đi bộ, đạp xe)
   - Theo dõi quãng đường thực tế bằng GPS với độ chính xác cao
   - Theo dõi tốc độ trung bình
   - Tự động tính số kcal tiêu thụ dựa trên quãng đường, thời gian, cân nặng và loại hoạt động (cập nhật real-time)
   - Hiển thị bản đồ OpenStreetMap:
     * **Chỉ có 2 marker:**
       - Điểm bắt đầu: Marker tại vị trí khi bấm "Bắt đầu" (màu xanh dương) - cố định
       - Điểm hiện tại/kết thúc: 
         * Khi đang tracking: Marker tại vị trí GPS hiện tại, cập nhật real-time (màu xanh lục)
         * Khi hoàn thành: Marker này trở thành điểm kết thúc (màu xanh lục) - cố định
     * Polyline segments: Vẽ từng segment riêng biệt (màu xanh dương, cập nhật real-time)
       - Mỗi segment là một polyline riêng, KHÔNG nối các segment lại với nhau
       - Segment 1: Từ điểm bắt đầu đến điểm dừng lần 1
       - Segment 2: Từ điểm tiếp tục lần 1 đến điểm dừng lần 2 (nếu có)
       - Segment N: Từ điểm tiếp tục cuối đến điểm kết thúc
   - Khi tạm dừng: Segment hiện tại đóng lại, không vẽ thêm, marker điểm hiện tại vẫn còn
   - Khi tiếp tục: Bắt đầu segment MỚI từ vị trí hiện tại (KHÔNG nối với segment cũ, vì người dùng có thể đã di chuyển)
   - Khi hoàn thành: Đóng segment cuối, marker điểm hiện tại trở thành điểm kết thúc (đổi màu xanh lục)
   - **Tính toán chỉ khi đang di chuyển:**
     * Quãng đường: Chỉ tính TRONG các segment (không tính khoảng cách giữa các segment)
     * Thời gian: Chỉ tính thời gian di chuyển (không tính thời gian pause)
     * Tốc độ trung bình: Dựa trên quãng đường và thời gian di chuyển
     * Kcal: Dựa trên quãng đường và thời gian di chuyển (không tính pause)
   - Lưu tất cả các segment (route) vào Firestore để xem lại sau

2. **Thống kê buổi tập GPS**
   - Thời gian tập luyện (tổng thời gian)
   - Quãng đường (km) - tính từ tổng khoảng cách giữa các điểm GPS
   - Tốc độ trung bình (km/h)
   - Calories đã đốt (tính từ quãng đường, thời gian, cân nặng và loại hoạt động)
   - Xem lại route trên bản đồ với polyline thực tế

3. **Đồng bộ dữ liệu**
   - Đồng bộ dữ liệu local với Cloud Firestore (tự động khi có internet)
   - Dữ liệu có thể truy cập từ nhiều thiết bị (đăng nhập cùng tài khoản)
   - Xử lý khi mất kết nối internet (lưu tạm local, đồng bộ khi có mạng)

4. **Xuất dữ liệu**
   - Xuất báo cáo sức khỏe ra file PDF
   - Hoặc xuất ra Excel để phân tích
   - Có thể chia sẻ file

---

## Plan 5: Kế hoạch Tập luyện & Chatbot AI (Trung bình-Khó)
**Mục tiêu**: Kế hoạch tập luyện có sẵn/tùy chỉnh và chatbot AI trả lời câu hỏi

### Chức năng:
1. **Kế hoạch tập luyện có sẵn**
   - Danh sách các chương trình training có sẵn (ví dụ: Chạy 5K, Giảm cân, Tăng sức bền) - lưu trong Firestore hoặc hardcode trong app
   - Xem chi tiết từng kế hoạch (số tuần, bài tập mỗi ngày, mô tả)
   - Bắt đầu một kế hoạch 
   - Theo dõi tiến độ kế hoạch đang thực hiện (hiển thị % hoàn thành, ngày đã tập)
   - Đánh dấu hoàn thành bài tập trong ngày

2. **Kế hoạch tập luyện tùy chỉnh**
   - Tạo kế hoạch tập luyện riêng
   - Thêm/sửa/xóa bài tập trong kế hoạch
   - Đặt lịch tập luyện (ngày nào tập gì)
   - Nhắc nhở khi đến giờ tập

3. **Màn hình Chat với AI**
   - Giao diện chat giống messenger
   - Input để nhập câu hỏi
   - Hiển thị lịch sử chat
   - Loading khi AI đang trả lời

4. **Chatbot trả lời câu hỏi chung**
   - Trả lời câu hỏi về dinh dưỡng
   - Trả lời câu hỏi về tập luyện
   - Trả lời câu hỏi về sức khỏe tổng quát
   - Trả lời bằng tiếng Việt

5. **Lưu lịch sử chat**
   - Lưu các cuộc hội thoại vào Firestore (theo userId)
   - Có thể xem lại lịch sử chat (hiển thị danh sách các cuộc hội thoại)
   - Có thể xóa lịch sử (xóa từng cuộc hội thoại hoặc toàn bộ)

6. **Cải thiện trải nghiệm chat**
   - Gợi ý câu hỏi thường gặp
   - Format lại câu trả lời cho dễ đọc
   - Xử lý lỗi khi không kết nối được AI

---

## Plan 6: AI Coaching & Phân tích Cá nhân hóa (Khó)
**Mục tiêu**: AI phân tích dữ liệu cá nhân, đưa ra gợi ý và tạo kế hoạch tập luyện tự động

### Chức năng:
1. **AI phân tích dữ liệu người dùng**
   - Phân tích xu hướng cân nặng (tăng/giảm/ổn định)
   - Phân tích mức độ hoạt động (đang tích cực hay không) - dựa trên tần suất và tổng hoạt động
   - Phân tích thói quen tập luyện (thời gian tập thường xuyên, loại hoạt động ưa thích)
   - Phân tích dữ liệu GPS (tốc độ, quãng đường, tần suất)
   - Nhận diện các vấn đề (ví dụ: không đạt mục tiêu quãng đường, chuỗi bị gián đoạn)

2. **AI đưa ra gợi ý cá nhân hóa**
   - Gợi ý điều chỉnh mục tiêu dựa trên tiến độ thực tế
   - Lời khuyên về dinh dưỡng phù hợp với mục tiêu
   - Gợi ý bài tập phù hợp với thể trạng
   - Gợi ý cải thiện dựa trên dữ liệu GPS (tăng tốc độ, tăng quãng đường)
   - Cảnh báo khi có dấu hiệu bất thường

3. **Màn hình Insights từ AI**
   - Hiển thị các phân tích của AI
   - Hiển thị các gợi ý được đề xuất
   - Có thể xem chi tiết từng insight
   - Lưu lịch sử insights

4. **Tự động gợi ý**
   - AI tự động phân tích khi có dữ liệu mới (sau mỗi buổi tập, sau khi cập nhật cân nặng)
   - Gửi thông báo (push notification) khi có insight mới
   - Gợi ý hàng tuần dựa trên dữ liệu (tự động chạy phân tích vào cuối tuần)

5. **AI tạo kế hoạch tập luyện tự động**
   - AI tạo lịch tập luyện dựa trên mục tiêu và thể trạng
   - Gợi ý bài tập cụ thể cho từng ngày
   - Điều chỉnh kế hoạch dựa trên tiến độ thực tế
   - Tạo kế hoạch dựa trên dữ liệu GPS (ví dụ: tăng dần quãng đường chạy)

---

## Tóm Tắt Các Plan

- **Plan 1**: Authentication, Profile & Activity Tracking (Đăng nhập/Đăng ký, Profile, Dashboard, Theo dõi hoạt động GPS/trong nhà, Lịch sử)
- **Plan 2**: Biểu đồ & Phân tích Sức khỏe (Biểu đồ xu hướng, Tính toán BMI, Theo dõi chuỗi, Lọc/Tìm dữ liệu)
- **Plan 3**: Mục tiêu & Thống kê Chi tiết (Đặt mục tiêu, Theo dõi tiến độ, Notifications, BMR/TDEE, Thống kê theo ngày/tuần/tháng/năm)
- **Plan 4**: GPS Tracking Nâng Cao & Export (GPS tracking với bản đồ, Thống kê buổi tập, Đồng bộ cloud, Xuất PDF/Excel)
- **Plan 5**: Kế hoạch Tập luyện & Chatbot AI (Kế hoạch có sẵn/tùy chỉnh, Chat UI với Gemini, Trả lời câu hỏi, Lưu lịch sử)
- **Plan 6**: AI Coaching & Phân tích Cá nhân hóa (Phân tích dữ liệu, Gợi ý cá nhân hóa, Insights, AI tạo kế hoạch tự động)

---

## Lưu Ý

- Thực hiện tuần tự từ Plan 1 đến Plan 6
- Mỗi plan nên hoàn thành và test kỹ trước khi chuyển sang plan tiếp theo
- Plan 6 là phần quan trọng nhất để đạt điểm cao, cần đầu tư thời gian
- Có thể bỏ qua một số chức năng trong Plan 4 nếu thời gian không đủ
- Ưu tiên hoàn thành các plan cơ bản trước khi làm các tính năng nâng cao

