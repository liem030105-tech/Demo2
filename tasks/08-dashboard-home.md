# Task 08 - Dashboard (Home) tháng hiện tại

## Mục tiêu

- Home hiển thị tổng quan tháng hiện tại:
  - Tổng income, tổng expense, net
  - Top expense categories
  - Budget alerts (từ Task 07)

## Phạm vi

- UI Dashboard + các query cần thiết.
- Có month switcher (tháng hiện tại mặc định).

## Acceptance criteria

- Số liệu khớp với dữ liệu `transactions` trong tháng.
- Nếu không có data → trạng thái empty rõ ràng.
- Nếu category/account bị null (do delete) → vẫn render ổn với fallback.

## Test plan

- Tạo 5 transactions tháng hiện tại (income/expense mix) → dashboard đúng.
- Chuyển tháng khác không có data → empty state.

