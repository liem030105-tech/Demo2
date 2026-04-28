# Task 12 - Đính kèm hoá đơn (Supabase Storage)

## Mục tiêu

- Cho phép attach ảnh hoá đơn cho một transaction.

## Phạm vi

- Supabase Storage bucket (ví dụ: `receipts`).
- Lưu metadata link vào `transactions` (thêm cột hoặc bảng `transaction_receipts`).
- UI: chọn ảnh, upload, hiển thị preview, xoá attachment.

## Acceptance criteria

- Upload ảnh thành công, chỉ user sở hữu transaction mới truy cập được file.
- Xoá transaction → attachment không “rác” (xoá file hoặc có cleanup strategy).

## Test plan

- Upload 1 ảnh → mở lại app vẫn xem được.
- User B không truy cập được file của user A.

