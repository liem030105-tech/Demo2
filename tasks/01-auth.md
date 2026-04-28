# Task 01 - Auth (Đăng nhập / Đăng ký)

## Mục tiêu

- Có **màn hình Đăng nhập** và **màn hình Đăng ký**.
- Người dùng có thể **đăng ký tài khoản** và **đăng nhập** bằng Email/Password qua **Supabase Auth**.
- Sau khi đăng nhập, vào **Home**; có nút **Đăng xuất** để quay lại màn hình đăng nhập.

## Phạm vi

- Email/Password (MVP).
- Không làm social login trong task này.
- Không làm reset password trong task này (có thể là task sau).

## Acceptance criteria

- Đăng ký với email + mật khẩu → thành công (hoặc hiển thị lỗi hợp lệ).
- Đăng nhập với email + mật khẩu → vào Home.
- Đăng xuất → quay về Login.
- Nếu thiếu cấu hình Supabase khi chạy app, hiển thị màn hình hướng dẫn (không crash).

## Hướng dẫn chạy (Flutter)

App Flutter nằm ở `app/`.

1) Cài dependencies:

```bash
cd app
flutter pub get
```

2) Chạy app với Supabase config:

```bash
cd app
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Ghi chú Supabase

- Bật Email provider trong Supabase Auth.
- Nếu bạn bật “Confirm email”, sau khi sign up có thể cần verify email trước khi sign in (tuỳ setting).

