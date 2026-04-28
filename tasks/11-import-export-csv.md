# Task 11 - Import / Export CSV

## Mục tiêu

- Export transactions ra CSV theo khoảng thời gian.
- Import transactions từ CSV (tối thiểu: date, type, amount, note, category_name, account_name).

## Phạm vi

- Export: tạo file CSV và chia sẻ/lưu.
- Import: parse CSV, map category/account theo name (tạo mới nếu chưa có), insert batch.

## Acceptance criteria

- Export tạo CSV đúng format, mở được bằng Excel/Google Sheets.
- Import 100–500 dòng không crash; báo số dòng thành công/thất bại.
- RLS vẫn đảm bảo dữ liệu import thuộc user hiện tại.

## Test plan

- Export 1 tháng → import vào user khác → data vào đúng user khác (không trùng id).

