# Projexy Frontend

Repository này chứa ứng dụng client Flutter của hệ thống Projexy. README này chỉ tập trung vào cài đặt, cấu hình, phát triển và build frontend.

Tổng quan sản phẩm và mô tả tính năng nằm tại repository tổng: [Projexy](https://github.com/VuongVladimir/projexy).

## Tech stack

| Nhóm | Công nghệ |
| --- | --- |
| Framework | Flutter, Dart |
| State management | Provider, ChangeNotifier |
| Networking | Dio, http |
| Auth | JWT backend auth, Firebase Auth, Google Sign-In |
| Realtime chat | Stream Chat Flutter |
| Notification | Firebase Messaging, flutter_local_notifications |
| Local storage | SharedPreferences, encrypt_shared_preferences |
| Localization | easy_localization |
| UI/Data visualization | fl_chart, table_calendar, flutter_svg, cached_network_image |
| Native integration | home_widget, file_picker, permission_handler, url_launcher |

## Yêu cầu môi trường

- Flutter SDK tương thích Dart `^3.8.1`.
- Android Studio hoặc VS Code có Flutter/Dart plugin.
- Android SDK nếu chạy Android.
- Xcode/CocoaPods nếu build iOS/macOS.
- Chrome nếu chạy Flutter Web.
- Backend Projexy đang chạy local hoặc endpoint production khả dụng.
- Firebase project đã cấu hình nếu dùng Google Sign-In, Firebase Auth và FCM.

Kiểm tra môi trường:

```bash
flutter doctor
```

## Cài đặt

```bash
git clone https://github.com/VuongVladimir/projexy-frontend.git
cd projexy-frontend
flutter pub get
```

Nếu dependency native bị lỗi sau khi đổi branch hoặc nâng Flutter SDK:

```bash
flutter clean
flutter pub get
```

## Cấu hình backend API

API base URL hiện được khai báo tại:

```dart
// lib/common/constants/global_variables.dart
String uri = "https://projexy-backend.me";
```

Khi chạy với backend local, đổi sang URL backend đang chạy:

```dart
String uri = "http://localhost:3000";
```

Lưu ý khi chạy trên Android emulator:

```dart
String uri = "http://10.0.2.2:3000";
```

Nếu chạy trên thiết bị thật, dùng IP LAN của máy chạy backend:

```dart
String uri = "http://192.168.x.x:3000";
```

## Cấu hình Firebase và Google Sign-In

Android:

- Đặt file `google-services.json` tại `android/app/google-services.json`.
- Đảm bảo package name trong Firebase khớp với Android app.
- Bật Google Sign-In trong Firebase Authentication nếu dùng đăng nhập Google.

iOS:

- Thêm file cấu hình Firebase tương ứng vào `ios/Runner`.
- Cấu hình URL schemes theo hướng dẫn Firebase/Google Sign-In.
- Chạy `pod install` trong thư mục `ios` nếu cần.

Push notification:

- Cần cấu hình Firebase Cloud Messaging ở Firebase Console.
- Trên thiết bị thật, cấp quyền notification khi app yêu cầu.
- Backend cần endpoint FCM token hoạt động để lưu token người dùng.

## Cấu hình Stream Chat

Frontend không lưu Stream Chat secret. App lấy token và API key từ backend qua các endpoint Stream Chat.

Điều kiện để chat hoạt động:

- Backend đã cấu hình `STREAM_API_KEY` và `STREAM_API_SECRET`.
- User đã đăng nhập và có access token hợp lệ.
- Project/direct channel đã được backend tạo hoặc đồng bộ.

## Chạy ứng dụng

Chạy trên device mặc định:

```bash
flutter run
```

Chọn device cụ thể:

```bash
flutter devices
flutter run -d <device-id>
```

Chạy Flutter Web:

```bash
flutter run -d chrome
```

## Lệnh phát triển

```bash
# Phân tích static code
flutter analyze

# Chạy test
flutter test

# Cập nhật launcher icon nếu thay logo
dart run flutter_launcher_icons
```

## Build

Android APK:

```bash
flutter build apk
```

Android App Bundle:

```bash
flutter build appbundle
```

Web:

```bash
flutter build web
```

iOS:

```bash
flutter build ios
```

## Cấu trúc thư mục

```text
lib/
├── common/
│   ├── constants/          # API URL, theme, helper, HTTP handling
│   ├── services/           # FCM, Stream Chat và service dùng chung
│   └── widgets/            # Widget tái sử dụng
├── features/
│   ├── account/
│   ├── auth/
│   ├── chat/
│   ├── home/
│   ├── notifications/
│   ├── onboarding/
│   ├── projects/
│   ├── responsive/
│   ├── tasks/
│   └── teams/
├── models/                 # Client-side data models
├── providers/              # UserProvider, ThemeProvider
├── main.dart               # App bootstrap
└── router.dart             # Route generation
```

## Assets và localization

Assets được khai báo trong `pubspec.yaml`:

- `assets/images/`
- `assets/onboarding/`
- `assets/fonts/`
- `assets/translations/`
- `assets/icons/`

Ngôn ngữ hỗ trợ:

- `assets/translations/en.json`
- `assets/translations/vi.json`

Khi thêm key mới, cập nhật cả hai file để tránh thiếu bản dịch.

## Kiểm tra trước khi push

```bash
flutter pub get
flutter analyze
flutter test
```

Nếu thay đổi native config, nên chạy thêm trên device/emulator liên quan.

## Ghi chú bảo mật

- Không commit secret, token hoặc credential production.
- Không hard-code API secret ở frontend.
- Kiểm tra kỹ Firebase config trước khi public repository.
- Secret của Stream Chat, PayOS, JWT và email phải nằm ở backend.
