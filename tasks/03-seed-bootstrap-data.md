# Task 03 - Seed/Bootstrap dữ liệu cơ bản (sau Auth + RLS)

## Mục tiêu

- Sau khi user đăng nhập lần đầu, app có dữ liệu tối thiểu để dùng:
  - 1–2 `accounts` mặc định (ví dụ: “Tiền mặt”).
  - Một bộ `categories` mẫu cho `expense` và `income`.

## Phạm vi

- Seed theo từng user (data thuộc về user đó, tuân thủ RLS).
- Thực hiện seed từ Flutter (client) cho MVP.

## Acceptance criteria

- User mới đăng ký → vào app → có thể thấy danh sách account/category mặc định.
- Seed chạy **idempotent**: mở app lại không tạo trùng dữ liệu.
- Nếu seed lỗi (network/RLS) thì hiện thông báo, không crash.

## Implementation notes (Flutter + Supabase)

- Trigger seed ở `HomePage` (hoặc sau khi session có) bằng một hàm `ensureBootstrapData()`.
- Dùng `upsert` hoặc query + insert có điều kiện:
  - `accounts`: unique theo `(user_id, name)` ở app-level (MVP) hoặc thêm unique constraint sau.
  - `categories`: unique theo `(user_id, type, name)` ở app-level (MVP) hoặc thêm unique constraint sau.

## Test plan

- Đăng ký user mới → đăng nhập → kiểm tra có account/category.
- Kill app → mở lại → dữ liệu không bị nhân đôi.

