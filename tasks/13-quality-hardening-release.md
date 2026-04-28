# Task 13 - Hardening (DX/UX) + Testing tối thiểu + Release checklist

## Mục tiêu

- Ổn định app trước khi dùng thật:
  - Loading/empty/error states chuẩn
  - Không crash phổ biến (null FK, network error)
  - Tối thiểu widget/integration tests cho luồng chính
  - Chuẩn bị build release (Android)

## Phạm vi

- Error handling nhất quán (SnackBar/Inline error).
- Test tối thiểu:
  - Auth screen (missing config)
  - CRUD transaction basic (smoke)
- Release checklist:
  - app icon/name
  - build apk/aab

## Acceptance criteria

- `flutter analyze` pass, `flutter test` pass.
- App chạy ổn với mạng chập chờn (retry cơ bản hoặc hướng dẫn).
- Build release Android thành công.

## Test plan

- Tắt mạng → mở Transactions/Reports → thấy error state, bật mạng lại → refresh ok.
- Build: `flutter build apk` (hoặc `appbundle`) chạy thành công.

