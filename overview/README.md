# Quản lý chi tiêu cá nhân (Flutter + Supabase)

Ứng dụng giúp bạn ghi lại **thu/chi**, theo dõi **ngân sách**, và xem **báo cáo** theo tháng/danh mục — tối ưu cho thao tác nhanh hằng ngày.

## Tech stack (đề xuất)

- **Flutter** (UI)
- **Supabase**:
  - Auth (Email/Password cho MVP)
  - Postgres (data)
  - RLS (bảo mật theo user)
  - Storage (tuỳ chọn, cho hóa đơn)
- **Flutter packages** (gợi ý):
  - `supabase_flutter` (kết nối Supabase + auth helpers)
  - `flutter_riverpod` (MVVM ViewModels + DI/providers)
  - `go_router` (routing + App shell)
  - `intl` (format tiền/ngày)

## Overview kỹ thuật

### Phiên bản Flutter / Dart (đề xuất)

Để tránh “lệch môi trường” giữa các máy, dự án này dùng phiên bản cố định:

- **Flutter**: `3.41.2` (stable)
- **Dart**: `3.11.0`

Khuyến nghị khoá SDK trong `pubspec.yaml`:
- `environment: sdk: ">=3.11.0 <4.0.0"`

### Thư viện (packages) đề xuất theo nhóm

**Supabase / Auth / Data**
- `supabase_flutter`: auth + client + session management.

**State management**
- **Riverpod (bạn chọn)**:
  - `flutter_riverpod`: state management + DI theo provider
  - (tuỳ chọn) `hooks_riverpod`: nếu bạn thích dùng Flutter Hooks cho UI

**Routing**
- `go_router`: điều hướng declarative + deep link (hữu ích nếu làm thêm Flutter Web).

### Kiến trúc UI: MVVM + Riverpod + go_router (chuẩn dự án)

Dự án Flutter dùng **MVVM** để tách trách nhiệm rõ ràng giữa UI và logic:

- **View (UI)**: `Widget`/`Page` chỉ lo layout + bind state + gọi action trên ViewModel.
- **ViewModel**: lớp `ChangeNotifier` chứa state + side-effects (gọi Supabase, validate, orchestration).
- **Model**: DTO/entity (map JSON ↔ Dart) — thường nằm ở `features/*/data/models/` khi feature lớn dần.

**Riverpod** đóng vai trò “DI + reactive glue” cho MVVM:

- ViewModel được expose qua provider (ví dụ `ChangeNotifierProvider.autoDispose`).
- `SupabaseClient` được inject qua provider (`supabaseClientProvider`) để ViewModel không “hard-code singleton”.

**go_router** đóng vai trò navigation layer:

- `ShellRoute` cho **App shell** (bottom navigation).
- `redirect` theo `auth` session + `refreshListenable` theo `onAuthStateChange` để route luôn đồng bộ trạng thái đăng nhập.

**Quy ước đặt tên / file**

- Page: `*_page.dart` trong `features/<feature>/presentation/`
- ViewModel: `*_view_model.dart` trong `features/<feature>/presentation/`
- Router: `lib/core/routing/app_router.dart`

**Models / (De)serialization**
- `freezed` + `json_serializable`: giảm boilerplate cho model, immutable, copyWith.

**Local storage (cache/offline tối thiểu)**
- `shared_preferences`: lưu setting đơn giản (currency, theme, v.v.)
- `hive` (hoặc `isar`): lưu cache giao dịch/danh mục để mở app nhanh hơn (tối ưu sau MVP).

**Utilities**
- `intl`: format tiền tệ/ngày giờ theo locale.
- `collection`: tiện ích cho list/map.

**UI**
- `flutter_svg`: dùng icon SVG cho danh mục.
- `google_fonts` (tuỳ chọn): font đẹp, nhất quán.

**Charts / Reports**
- `fl_chart`: biểu đồ donut/bar/line cho báo cáo.

**Quality**
- `flutter_lints`: lint cơ bản.
- `mocktail` + `test` + `integration_test`: test unit/widget/integration (thêm dần).

### Cấu trúc thư mục (Clean Architecture theo feature + Riverpod)

Giữ Clean Architecture theo feature, nhưng ở tầng presentation dùng **MVVM**:

- `presentation/*_page.dart` (View)
- `presentation/*_view_model.dart` (ViewModel, thường là `ChangeNotifier`)
- (tuỳ chọn) `presentation/providers.dart` hoặc `presentation/providers/` nếu bạn muốn tách file khai báo Riverpod ra khỏi ViewModel

```text
lib/
  core/
    constants/
    theme/
    utils/
    widgets/
  features/
    auth/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        view_models/
    transactions/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        view_models/
  l10n/
  main.dart
test/
  unit/
  widget/
  integration/
```

### Ghi chú cấu hình đa nền tảng

- **Android/iOS**: MVP ưu tiên mobile; Supabase hoạt động tốt với `supabase_flutter`.
- **Web** (tuỳ chọn): cần cấu hình redirect/callback URL cho Auth và cân nhắc CORS khi gọi edge functions.

### Quy ước dự án (gợi ý)

- **Amount**: luôn dùng `amount_minor` (int) + `currency_code` để hiển thị.
- **Time**:
  - Nếu chỉ cần theo ngày: dùng `date` (`occurred_at`) cho đơn giản.
  - Nếu cần theo giờ: dùng `timestamptz` + lưu UTC, hiển thị theo local.

## Mục tiêu

- Ghi giao dịch trong vài giây (ít bước, ít nhập).
- Nhìn được bức tranh chi tiêu theo tháng và theo danh mục.
- Thiết kế dữ liệu an toàn theo người dùng bằng **Supabase Auth + RLS**.

## Tính năng

### MVP

- **Đăng nhập/đăng ký** (Supabase Auth).
- **Giao dịch**: tạo/sửa/xóa thu/chi (số tiền, ngày, danh mục, ghi chú, phương thức thanh toán).
- **Danh mục**: quản lý danh mục (tên + màu + icon).
- **Ngân sách theo tháng**: đặt hạn mức theo danh mục, cảnh báo khi vượt.
- **Báo cáo cơ bản**:
  - Tổng thu/chi theo tháng
  - Chi theo danh mục (top categories)
- **Tìm kiếm & lọc**: theo thời gian, danh mục, loại (thu/chi), từ khóa ghi chú.

### Next (sau MVP)

- **Giao dịch định kỳ** (recurring).
- **Import/Export CSV**.
- **Đa tiền tệ** + tỷ giá.
- **Chia sẻ “ví gia đình”** (multi-user workspace) với quyền truy cập.
- **Đính kèm hóa đơn** (Supabase Storage) + OCR.

## Luồng màn hình (đề xuất)

- **Auth** → **Home (Dashboard)**  
- Dashboard:
  - Tổng quan tháng hiện tại (thu/chi, số dư)
  - Biểu đồ chi theo danh mục
  - Cảnh báo ngân sách
- **Transactions** (Danh sách giao dịch) → **Add/Edit Transaction**
- **Categories** (Danh mục)
- **Budget** (Ngân sách)
- **Reports** (Báo cáo)
- **Settings** (Cài đặt)

## Thiết kế dữ liệu (Supabase / Postgres)

> Quy ước quan trọng: **amount lưu kiểu integer theo “minor units”** (ví dụ VND = đồng, USD = cents) để tránh sai số số thực.

### Bảng đề xuất

- `profiles`
  - `id uuid` (PK, trùng `auth.users.id`)
  - `display_name text`
  - `currency_code text` (vd: `VND`)
  - `created_at timestamptz`
- `accounts` (tài khoản/nguồn tiền)
  - `id uuid` (PK)
  - `user_id uuid` (FK → `profiles.id`)
  - `name text` (vd: Tiền mặt, Ngân hàng)
  - `created_at timestamptz`
- `categories`
  - `id uuid` (PK)
  - `user_id uuid` (FK)
  - `name text`
  - `type text` (`expense` | `income`)
  - `color text` (hex)
  - `icon text` (key/icon name)
  - `created_at timestamptz`
- `transactions`
  - `id uuid` (PK)
  - `user_id uuid` (FK)
  - `account_id uuid` (FK → `accounts.id`)
  - `category_id uuid` (FK → `categories.id`)
  - `type text` (`expense` | `income`)
  - `amount_minor bigint`
  - `occurred_at date` (hoặc `timestamptz` nếu cần giờ)
  - `note text`
  - `payment_method text` (vd: cash, card, bank_transfer, ewallet)
  - `created_at timestamptz`
- `budgets`
  - `id uuid` (PK)
  - `user_id uuid` (FK)
  - `category_id uuid` (FK)
  - `month date` (ngày 01 của tháng, vd: 2026-04-01)
  - `limit_minor bigint`
  - `created_at timestamptz`

### Quan hệ

- `profiles (1) ── (n) accounts/categories/transactions/budgets`
- `accounts (1) ── (n) transactions`
- `categories (1) ── (n) transactions` và `categories (1) ── (n) budgets`

## RLS (Row Level Security) – nguyên tắc

- Bật RLS cho các bảng user-owned.
- Mọi policy đều giới hạn theo `auth.uid()`:
  - `SELECT`: chỉ thấy dữ liệu của mình
  - `INSERT`: `user_id = auth.uid()`
  - `UPDATE/DELETE`: chỉ sửa/xóa bản ghi của mình

Ví dụ điều kiện logic (mô tả):
- `using (user_id = auth.uid())`
- `with check (user_id = auth.uid())`

## Setup dự án

### 1) Tạo Supabase project

- Tạo project trên Supabase
- Bật Auth provider bạn muốn (Email/Password là đủ cho MVP)
- Tạo các bảng theo thiết kế phía trên (SQL editor / migrations)
- Lấy:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`

### 2) Cấu hình Flutter

Bạn có 2 cách phổ biến để đưa key vào app.

**Cách A: `--dart-define` (khuyến nghị cho MVP, không cần thêm package)**

- Chạy app với biến compile-time (an toàn hơn việc hard-code):

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

**Cách B: `.env`**

- Dùng package đọc env (vd: `flutter_dotenv`) rồi nạp `.env` khi khởi động (tiện cho local dev).

### 3) Khởi tạo Supabase trong app (gợi ý)

- Với `supabase_flutter`, thường sẽ init ở `main()` trước khi chạy app (chi tiết tuỳ codebase).

### 4) Chạy app

```bash
flutter pub get
flutter run
```

### Gợi ý dev workflow (tuỳ chọn)

- Dùng Supabase Dashboard để tạo bảng/policy nhanh trong giai đoạn MVP.
- Nếu dùng Supabase CLI/migrations, bạn có thể quản lý schema bằng SQL migrations để dễ versioning.

## Cấu trúc thư mục (đề xuất)

```text
lib/
  core/            # config, constants, routing, error handling
  shared/          # widgets dùng chung, theme, utils
  features/
    auth/
    dashboard/
    transactions/
    categories/
    budgets/
    reports/
    settings/
```

## Test plan (tối thiểu)

- **Auth**: đăng ký → đăng nhập → đăng xuất → đăng nhập lại.
- **Transactions**: tạo thu/chi, sửa, xóa; kiểm tra lọc theo tháng/danh mục/thu-chi.
- **Budgets**: đặt ngân sách tháng cho 1 danh mục; tạo giao dịch để vượt hạn mức; kiểm tra cảnh báo.
- **Reports**: xem tổng thu/chi tháng và breakdown theo danh mục.

## Ghi chú kỹ thuật

- Nếu cần số dư theo tài khoản, cân nhắc:
  - Tính tổng realtime theo `transactions`, hoặc
  - Dùng view/materialized view (tối ưu sau).

