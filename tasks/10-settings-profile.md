# Task 10 - Settings + Profile (display name, currency)

## Mục tiêu

- Cho user chỉnh:
  - `display_name`
  - `currency_code`
- Hiển thị email hiện tại + nút logout.

## Phạm vi

- Đọc/ghi `profiles` theo RLS.
- UI Settings page.

## Acceptance criteria

- Update profile thành công, reload app vẫn thấy giá trị mới.
- Validation tối thiểu (currency_code không rỗng).
- Nếu profile chưa tồn tại (edge case) → app tự tạo hoặc hướng dẫn hợp lý.

## Test plan

- Đổi display name, currency_code → thấy áp dụng ở Home/Reports.

