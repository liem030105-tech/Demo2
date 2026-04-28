# Task 06 - App Shell + Routing + Navigation

## Mục tiêu

- Chuẩn hoá “khung app” sau Auth:
  - Điều hướng rõ ràng giữa: Dashboard, Transactions, Reports, Manage (Accounts/Categories), Settings.
- Đảm bảo back stack hợp lý (đăng xuất quay về Login, không back vào màn hình đã auth).

## Phạm vi

- Tạo routing + bottom nav (hoặc nav rail nếu tablet).
- Tách cấu trúc thư mục `features/` theo hướng trong `overview/README.md` (mức tối thiểu để mở rộng).

## Acceptance criteria

- Sau khi login → vào AppShell, có navigation đến tất cả màn hình MVP.
- Logout ở mọi nơi → về Login và không back lại được vào AppShell.
- Deep link nội bộ (navigate tới form add transaction) hoạt động ổn.

## Test plan

- Login → chuyển tab qua lại → state không bị reset vô lý.
- Vào Add Transaction → back → về đúng tab Transactions.
- Logout → back → vẫn ở Login.

