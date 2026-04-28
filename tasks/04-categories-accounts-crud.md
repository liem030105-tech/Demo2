# Task 04 - CRUD Categories + Accounts (Flutter + Supabase)

## Mục tiêu

- Xây UI và luồng CRUD cho:
  - `categories` (expense/income)
  - `accounts`
- Mọi thao tác đi qua Supabase PostgREST và bị giới hạn bởi RLS (Task 02).

## Màn hình (đề xuất)

- **Settings / Manage** (tab hoặc page)
  - Section **Accounts**
    - List accounts
    - Add / Rename / Delete
  - Section **Categories**
    - Filter: expense / income
    - List categories
    - Add / Edit / Delete

## Acceptance criteria

- Tạo/sửa/xóa account hoạt động, list cập nhật đúng.
- Tạo/sửa/xóa category hoạt động, list cập nhật đúng.
- Dữ liệu của user A không lộ sang user B.
- Validation tối thiểu:
  - tên không rỗng
  - không tạo trùng (cùng name trong cùng type đối với category; cùng name đối với account)

## Backend assumptions

- Tables + RLS đã có từ `tasks/02-database-rls.md`.

## Test plan

- Tạo 2 accounts, 4 categories (2 expense, 2 income)
- Edit 1 cái, delete 1 cái
- Đăng nhập user khác → không thấy dữ liệu user trước

