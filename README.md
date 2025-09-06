
# Ứng Dụng Game Giáo Dục Kỹ Năng Sống Cho Trẻ

Đây là dự án ứng dụng di động được xây dựng bằng **Flutter**, nhằm mục tiêu giáo dục trẻ em trong độ tuổi từ 5-12 về các kỹ năng sống thiết yếu và nâng cao ý thức bảo vệ môi trường. Ứng dụng biến các bài học thành những trò chơi nhỏ vui nhộn, trực quan và dễ hiểu, giúp các bé học mà chơi, chơi mà học.

-----

## 🎯 Mục Tiêu Của Dự Án

  * **Xây dựng nền tảng kiến thức:** Trang bị cho trẻ những kỹ năng cơ bản về bảo vệ môi trường (phân loại rác, tiết kiệm nước), tự chăm sóc bản thân và an toàn (an toàn giao thông).
  * **Phương pháp học tập hiện đại:** Sử dụng hình thức "gamification" (trò chơi hóa) để tạo hứng thú, thay thế cho các phương pháp giáo dục truyền thống.
  * **Tăng cường tương tác gia đình:** Cung cấp công cụ cho phụ huynh để đồng hành, theo dõi và định hướng quá trình học tập của con em mình.

-----

## ✨ Các Tính Năng Nổi Bật

### Dành cho Trẻ Em

  * **Học Qua Trò Chơi:** Trẻ sẽ tiếp thu kiến thức thông qua một chuỗi các mini-game tương tác.
      * **Chăm Sóc Cây Trồng:** Tìm hiểu về các giai đoạn phát triển của cây và cách chăm sóc đúng cách.
      * **Phân Loại Rác:** Kéo thả các loại rác vào đúng thùng rác hữu cơ hoặc vô cơ.
      * **An Toàn Giao Thông:** Trả lời các câu hỏi tình huống về an toàn khi tham gia giao thông.
  * **Hệ Thống Phần Thưởng:** Sau mỗi màn chơi, trẻ sẽ được tích điểm và nhận huy hiệu, tạo động lực để tiếp tục khám phá.
  * **Giao Diện Trực Quan:** Thiết kế đồ họa sinh động, thân thiện với trẻ em, hạn chế tối đa chữ viết để tập trung vào hình ảnh.

### Dành cho Phụ Huynh

  * **Quản Lý Hồ Sơ Trẻ:** Dễ dàng tạo và quản lý nhiều hồ sơ cho các bé trong gia đình.
  * **Theo Dõi Tiến Độ:** Xem báo cáo chi tiết về kết quả học tập, số điểm thưởng và huy hiệu mà trẻ đã đạt được.
  * **Thiết Lập Giới Hạn Thời Gian:** Phụ huynh có thể cài đặt giờ tự động đăng xuất để kiểm soát thời gian sử dụng ứng dụng của trẻ.

-----

## 🛠️ Công Nghệ Sử Dụng

  * **Framework:** [Flutter](https://flutter.dev/)
  * **Ngôn ngữ:** [Dart](https://dart.dev/)
  * **Backend & Cơ sở dữ liệu:** [Firebase](https://firebase.google.com/)
      * **Firebase Authentication:** Xác thực người dùng (phụ huynh).
      * **Firebase Realtime Database:** Lưu trữ dữ liệu hồ sơ trẻ, tiến trình chơi game, và điểm thưởng.
  * **Quản lý State:** `StatefulWidget` / `setState`

-----

## 🚀 Cài Đặt và Chạy Dự Án

Để chạy dự án trên máy của bạn, hãy làm theo các bước sau:

1.  **Clone repository:**

    ```sh
    git clone https://github.com/tuyen52/ung_dung_giao_duc.git
    ```

2.  **Di chuyển vào thư mục dự án:**

    ```sh
    cd ung_dung_giao_duc
    ```

3.  **Cài đặt các dependency:**

    ```sh
    flutter pub get
    ```

4.  **Chạy ứng dụng:**

    ```sh
    flutter run
    ```

-----

## 📂 Cấu Trúc Thư Mục

Dự án được tổ chức theo cấu trúc module, giúp dễ dàng quản lý và mở rộng.

```
lib
├── game/                # Chứa logic và UI của các mini-game
│   ├── core/            # Các lớp cốt lõi (Game, GameProgress)
│   ├── plant_care/      # Game Chăm Sóc Cây Trồng
│   ├── recycle_sort/    # Game Phân Loại Rác
│   └── traffic_safety/  # Game An Toàn Giao Thông
│
├── models/              # Các lớp data model (Tre, Reward, PlayRecord)
│
├── screens/             # Các màn hình chính của ứng dụng
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── profile_screen.dart
│
├── services/            # Các lớp service để tương tác với Firebase
│   ├── auth_service.dart
│   ├── tre_service.dart
│   └── reward_service.dart
│
├── widgets/             # Các widget tái sử dụng
│
└── main.dart            # Điểm khởi đầu của ứng dụng
```
