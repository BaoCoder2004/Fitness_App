# fitness_app

A Flutter fitness tracking application with AI coaching features.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Admin Panel

The project includes a web-based admin panel for managing users.

### Running the Admin Panel

**Cách dễ nhất - Chạy bằng IDE:**
1. **VS Code**: Mở file `lib/admin/main.dart`, nhấn `F5`, chọn Chrome
2. **Android Studio**: Xem [HUONG_DAN_ANDROID_STUDIO.md](HUONG_DAN_ANDROID_STUDIO.md)

**Chạy bằng Terminal (nếu cần):**
- Chạy: `flutter run -d chrome --target=lib/admin/main.dart`

**Build for Production:**
- Run `flutter build web --target=lib/admin/main.dart --release`
- Output will be in `build/web/`

📖 Xem chi tiết: [HUONG_DAN_CHAY_ADMIN.md](HUONG_DAN_CHAY_ADMIN.md)

### Admin Panel Features

- User management (view, search, block/unblock)
- Role management (assign/revoke admin role)
- Dashboard with user statistics
- Authentication with role-based access control
