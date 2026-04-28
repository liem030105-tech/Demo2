# Task 09 - Search & Filter Transactions

## Mục tiêu

- Tìm kiếm và lọc transactions theo:
  - khoảng thời gian (from/to hoặc tháng)
  - category
  - type (income/expense)
  - keyword trong note

## Phạm vi

- UI filter sheet / search bar.
- Query Supabase với filter kết hợp (AND).

## Acceptance criteria

- Kết quả filter đúng, không trễ/giật quá mức với data vừa phải (MVP).
- Có nút “Reset filters”.
- Lưu filter state khi quay lại màn hình (tối thiểu trong session).

## Test plan

- Tạo 10 transactions nhiều category/type/note.
- Lọc type=expense + category=X + keyword=“coffee” → ra đúng items.

