# Task 07 - Budgets theo tháng + cảnh báo vượt ngân sách

## Mục tiêu

- Cho phép user đặt **ngân sách theo tháng** cho từng category (expense).
- Hiển thị cảnh báo khi tổng chi theo category trong tháng vượt `limit_minor`.

## Phạm vi

- UI CRUD budgets:
  - Set budget cho tháng (month picker)
  - Set limit cho category
  - Update/delete budget
- Tính toán tổng chi theo category trong tháng từ `transactions`.

## Acceptance criteria

- Tạo budget (month + category + limit) thành công.
- Không tạo trùng cùng `(user_id, category_id, month)` (theo unique constraint trong Task 02).
- Dashboard/Reports hiển thị trạng thái:
  - % đã dùng
  - vượt ngân sách → highlight rõ

## Test plan

- Set budget 1,000,000 cho “Ăn uống” tháng hiện tại.
- Tạo giao dịch expense 2 lần tổng > 1,000,000 → thấy cảnh báo vượt.
- Xoá budget → cảnh báo biến mất.

