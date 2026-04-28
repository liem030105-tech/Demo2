# Task 02 - Database + RLS (schema nền tảng)

## Mục tiêu

- Tạo schema Postgres cho MVP: `profiles`, `accounts`, `categories`, `transactions`, `budgets`.
- Bật **RLS** và policy chuẩn để mỗi user chỉ thấy/sửa dữ liệu của mình.
- Tự động tạo `profiles` record khi user đăng ký (trigger).

## Phạm vi

- Chỉ làm schema + RLS + trigger.
- Chưa làm UI CRUD trong Flutter (để Task 3+).

## Acceptance criteria

- Có đủ bảng như thiết kế.
- RLS bật cho các bảng user-owned.
- Policy `SELECT/INSERT/UPDATE/DELETE` hoạt động theo `auth.uid()`.
- `profiles` được auto-create khi có user mới trong `auth.users`.
- Kiểm tra nhanh: user A không đọc/ghi được dữ liệu user B.

## SQL (chạy trong Supabase SQL editor)

> Gợi ý: chạy theo thứ tự. Nếu bạn đã có bảng nào rồi thì bỏ qua phần tạo bảng tương ứng.

### 1) Extensions cần dùng (nếu chưa có)

```sql
create extension if not exists "pgcrypto";
```

### 2) Bảng `profiles`

```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  currency_code text not null default 'VND',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
on public.profiles for select
using (id = auth.uid());

create policy "profiles_update_own"
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());
```

### 3) Trigger auto-create profile khi signup

```sql
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
```

### 4) Bảng `accounts`

```sql
create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.accounts enable row level security;

create policy "accounts_select_own"
on public.accounts for select
using (user_id = auth.uid());

create policy "accounts_insert_own"
on public.accounts for insert
with check (user_id = auth.uid());

create policy "accounts_update_own"
on public.accounts for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "accounts_delete_own"
on public.accounts for delete
using (user_id = auth.uid());
```

### 5) Bảng `categories`

```sql
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  type text not null check (type in ('expense','income')),
  color text,
  icon text,
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;

create policy "categories_select_own"
on public.categories for select
using (user_id = auth.uid());

create policy "categories_insert_own"
on public.categories for insert
with check (user_id = auth.uid());

create policy "categories_update_own"
on public.categories for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "categories_delete_own"
on public.categories for delete
using (user_id = auth.uid());
```

### 6) Bảng `transactions`

```sql
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  account_id uuid references public.accounts (id) on delete set null,
  category_id uuid references public.categories (id) on delete set null,
  type text not null check (type in ('expense','income')),
  amount_minor bigint not null,
  occurred_at date not null,
  note text,
  payment_method text,
  created_at timestamptz not null default now()
);

alter table public.transactions enable row level security;

create policy "transactions_select_own"
on public.transactions for select
using (user_id = auth.uid());

create policy "transactions_insert_own"
on public.transactions for insert
with check (user_id = auth.uid());

create policy "transactions_update_own"
on public.transactions for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "transactions_delete_own"
on public.transactions for delete
using (user_id = auth.uid());
```

### 7) Bảng `budgets`

```sql
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete cascade,
  month date not null,
  limit_minor bigint not null,
  created_at timestamptz not null default now(),
  unique (user_id, category_id, month)
);

alter table public.budgets enable row level security;

create policy "budgets_select_own"
on public.budgets for select
using (user_id = auth.uid());

create policy "budgets_insert_own"
on public.budgets for insert
with check (user_id = auth.uid());

create policy "budgets_update_own"
on public.budgets for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "budgets_delete_own"
on public.budgets for delete
using (user_id = auth.uid());
```

## Test plan (nhanh)

- Đăng ký 2 user khác nhau.
- Dùng Table Editor hoặc query:
  - User A insert 1 category/account/transaction.
  - Đăng nhập User B thử select/update/delete record của A → phải bị chặn.

