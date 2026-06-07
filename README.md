# 🚗 Smart Parking App (Hệ Thống Quản Lý Bãi Đỗ Xe Thông Minh)

Dự án ứng dụng di động Flutter trong hệ thống IoT quản lý bãi đỗ xe thông minh. Ứng dụng kết nối trực tiếp với phần cứng (ESP32/các cảm biến) thông qua giao thức truyền tin thời gian thực **MQTT** và sử dụng **Firebase** làm cơ sở dữ liệu dự phòng cũng như lưu trữ lịch sử hoạt động và đẩy thông báo (Push Notifications).

Demo: https://www.youtube.com/watch?v=pj0VzO3RjyQ

---

## 🌟 Tính Năng Chính

*   **Theo Dõi Chỗ Đỗ Thời Gian Thực (Realtime Slots):** Hiển thị sơ đồ trực quan của 3 vị trí đỗ xe (`Slot 1`, `Slot 2`, `Slot 3`) kèm trạng thái (Đầy/Trống).
*   **Giám Sát Cổng Vào/Ra:** Theo dõi trạng thái đóng/mở của cổng vào (Entry Gate) và cổng ra (Exit Gate).
*   **Điều Khiển Cổng Bảo Mật (Biometric Auth):**
    *   Yêu cầu xác thực vân tay/khuôn mặt (`local_auth`) để mở cổng vào khi có xe chờ.
    *   Hỗ trợ cơ chế nhập mã PIN dự phòng (mặc định: `1234`) nếu thiết bị không hỗ trợ vân tay hoặc chưa cài đặt vân tay.
*   **Cảnh Báo Nhiệt Độ Bãi Xe:** Giám sát nhiệt độ thời gian thực và tự động đưa ra cảnh báo khẩn cấp trên giao diện nếu nhiệt độ vượt ngưỡng an toàn.
*   **Thông Báo Đẩy (Local & Push Notifications):**
    *   Tự động gửi thông báo khi có xe đang chờ ở cổng vào.
    *   Cảnh báo cháy/nhiệt độ quá cao.
    *   Thông báo khi cổng mở/đóng hoặc bãi xe hết chỗ.
*   **Nhật Ký Hoạt Động (History Log):** Xem lại toàn bộ lịch sử các sự kiện như: xe vào bãi, xe ra bãi, thay đổi trạng thái chỗ đỗ, cảnh báo nhiệt độ kèm mốc thời gian chi tiết.

---

## 🏗️ Kiến Trúc Hệ Thống & Công Nghệ Sử Dụng

### Giao Thức & Dịch Vụ
*   **MQTT Broker:** Kết nối với broker công cộng `broker.hivemq.com` qua cổng TCP `1883` để giao tiếp với thiết bị phần cứng (ESP32) với độ trễ cực thấp.
*   **Firebase Realtime Database:** Lưu trữ trạng thái hệ thống đồng bộ để dự phòng khi kết nối MQTT gặp sự cố và lưu giữ logs lịch sử hoạt động.
*   **Firebase Cloud Messaging (FCM) & Flutter Local Notifications:** Đảm nhận vai trò gửi và hiển thị thông báo tức thời cho người dùng.

### Công Nghệ Mobile
*   **Framework:** Flutter (Dart SDK `>=3.11.5`).
*   **State Management:** `Provider` để quản lý luồng dữ liệu realtime từ MQTT và Firebase.
*   **Bảo Mật:** `local_auth` để tích hợp API sinh trắc học của hệ điều hành (Android/iOS).

---

## 📂 Cấu Trúc Thư Mục Dự Án (`/lib`)

```text
lib/
├── firebase_options.dart         # Cấu hình kết nối Firebase tự động sinh bởi Flutterfire CLI
├── main.dart                     # Điểm khởi chạy ứng dụng, thiết lập Provider & Notifications
├── screens/
│   ├── home_screen.dart          # Giao diện giám sát tổng quan, bản đồ bãi đỗ & điều khiển cổng
│   └── history_screen.dart       # Giao diện hiển thị danh sách nhật ký hoạt động của bãi đỗ
├── services/
│   ├── firebase_service.dart     # Quản lý luồng dữ liệu & lịch sử từ Firebase Realtime DB
│   ├── mqtt_service.dart         # Kết nối, Subscribe & Publish lệnh thông qua MQTT Broker
│   └── notification_service.dart # Khởi tạo và xử lý hiển thị thông báo cục bộ và FCM
└── widgets/
    └── slot_card.dart            # Thành phần hiển thị trực quan từng ô đỗ xe
```

---

## 📡 Danh Sách MQTT Topics

| Topic | Hướng | Mô tả |
| :--- | :--- | :--- |
| `smart-parking/status/entry` | Subscribe | Trạng thái cổng vào (`OPEN` / `CLOSED`) |
| `smart-parking/status/exit` | Subscribe | Trạng thái cổng ra (`OPEN` / `CLOSED`) |
| `smart-parking/status/slots` | Subscribe | Chuỗi trạng thái 3 slot, ví dụ `100` (Slot 1 có xe, Slot 2 và 3 trống) |
| `smart-parking/status/temp` | Subscribe | Giá trị nhiệt độ hiện tại (dạng số thực) |
| `smart-parking/status/carwaiting`| Subscribe | Trạng thái có xe chờ ở cổng hay không (`YES` / `NO`) |
| `smart-parking/alert/temp` | Subscribe | Trạng thái cảnh báo cháy (`ALERT` / `NORMAL`) |
| `smart-parking/cmd/entry` | Publish | Gửi lệnh mở cổng vào (`OPEN`) |

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu Cầu Hệ Thống
*   Đã cài đặt **Flutter SDK** và **Dart SDK**.
*   Thiết bị Android/iOS hoặc trình giả lập để chạy thử (Khuyên dùng điện thoại Android thật để test tính năng vân tay).

### Các Bước Thực Hiện

1.  **Clone dự án về máy:**
    ```bash
    git clone https://github.com/Jralik/Smart-Parking-App.git
    cd Smart-Parking-App
    ```

2.  **Cài đặt các gói phụ thuộc (Dependencies):**
    ```bash
    flutter pub get
    ```

3.  **Cấu hình Firebase (Nếu cấu hình lại):**
    *   Tạo một dự án trên [Firebase Console](https://firebase.google.com/).
    *   Kích hoạt **Realtime Database** và cấu hình rules cho phép đọc/ghi.
    *   Thêm ứng dụng Android/iOS vào dự án Firebase của bạn.
    *   Tải file `google-services.json` đặt vào thư mục `android/app/`.
    *   (Tùy chọn) Chạy lệnh `flutterfire configure` để cập nhật lại file `lib/firebase_options.dart`.

4.  **Chạy ứng dụng:**
    *   Kết nối thiết bị hoặc khởi động trình giả lập.
    *   Khởi chạy chế độ Debug:
        ```bash
        flutter run
        ```

---

## 📝 Giấy Phép
Dự án được phát triển phục vụ cho mục đích học tập môn **Internet of Things (IoT)**. Bạn có thể tự do tham khảo, chỉnh sửa và phát triển thêm các tính năng mới.
