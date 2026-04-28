# Task 05 - CRUD Transactions + Report tháng (basic)

## Mục tiêu

- Làm luồng giao dịch thu/chi end-to-end:
  - List transactions theo tháng (mặc định tháng hiện tại)
  - Add / Edit / Delete transaction
- Làm báo cáo cơ bản cho tháng:
  - Tổng income, tổng expense, net
  - Breakdown expense theo category (top categories)

## Màn hình (đề xuất)

- **TransactionsPage**
  - Month picker (tháng/năm)
  - List transaction (date, category, amount, note)
  - FAB “+” để Add
- **TransactionFormPage**
  - type (income/expense)
  - amount (minor units)
  - occurred_at (date)
  - account_id (dropdown)
  - category_id (dropdown, theo type)
  - note (optional)
- **ReportsPage (basic)**
  - Tổng quan tháng: income/expense/net
  - List breakdown theo category (chỉ expense)

## Acceptance criteria

- CRUD transaction hoạt động đầy đủ.
- Filter theo tháng đúng.
- Report tháng đúng theo dữ liệu transaction hiện có.
- Không crash khi category/account bị xoá (FK set null): UI hiển thị “(đã xoá)” hoặc fallback hợp lý.
- RLS đảm bảo user chỉ thấy dữ liệu của mình.

## Backend assumptions

- Tables + RLS đã có từ `tasks/02-database-rls.md`.

## Query notes (Supabase)

- List theo tháng: filter `occurred_at` giữa `[month_start, month_end]`.
- Report:
  - Sum income/expense theo `type`
  - Group expense by `category_id` (có thể join categories để lấy name)

## Test plan

- Tạo 10 giao dịch rải trong 2 tháng khác nhau
- Chuyển tháng → list đổi đúng
- Báo cáo tháng hiện tại khớp tổng các giao dịch

