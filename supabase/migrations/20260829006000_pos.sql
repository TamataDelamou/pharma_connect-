-- Point of Sale module: counter sales and receipts

-- POS sales transactions
create table public.pos_sales (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  sale_number text unique not null,
  patient_id uuid references public.profiles(id) on delete set null,
  cashier_id uuid not null references public.profiles(id) on delete cascade,
  total_amount integer not null, -- in minor unit (GNF)
  discount_amount integer default 0,
  tax_amount integer default 0,
  final_amount integer not null,
  payment_method text not null check (payment_method in ('cash', 'mobile_money', 'card', 'insurance', 'credit')),
  status text default 'completed' check (status in ('completed', 'refunded', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- POS sale items
create table public.pos_sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.pos_sales(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  batch_id uuid references public.stock_batches(id) on delete set null,
  discount_percentage numeric default 0,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Printed receipts
create table public.pos_receipts (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.pos_sales(id) on delete cascade,
  receipt_number text unique not null,
  receipt_url text,
  printed_at timestamptz not null default now(),
  printed_by uuid references public.profiles(id) on delete set null,
  gsg_id text,
  gsg_org_id text
);

-- POS cash drawer sessions (for cash management)
create table public.pos_cash_sessions (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  cashier_id uuid not null references public.profiles(id) on delete cascade,
  opening_balance integer not null,
  closing_balance integer,
  expected_balance integer,
  difference integer,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  status text default 'open' check (status in ('open', 'closed', 'suspended')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_pos_sales_pharmacy_id on public.pos_sales(pharmacy_id);
create index idx_pos_sales_created_at on public.pos_sales(created_at);
create index idx_pos_sales_status on public.pos_sales(status);
create index idx_pos_sales_sale_number on public.pos_sales(sale_number);
create index idx_pos_sale_items_sale_id on public.pos_sale_items(sale_id);
create index idx_pos_sale_items_product_id on public.pos_sale_items(product_id);
create index idx_pos_receipts_sale_id on public.pos_receipts(sale_id);
create index idx_pos_cash_sessions_pharmacy_id on public.pos_cash_sessions(pharmacy_id);

-- Triggers for updated_at
create trigger trigger_pos_sales_updated_at
before update on public.pos_sales
for each row execute function public.update_updated_at();

create trigger trigger_pos_cash_sessions_updated_at
before update on public.pos_cash_sessions
for each row execute function public.update_updated_at();

-- Functions to generate numbers
create or replace function generate_sale_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(sale_number from '^S([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.pos_sales;
  new.sale_number := 'S' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create or replace function generate_receipt_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(receipt_number from '^R([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.pos_receipts;
  new.receipt_number := 'R' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_pos_sales_number
before insert on public.pos_sales
for each row execute function generate_sale_number();

create trigger trigger_pos_receipts_number
before insert on public.pos_receipts
for each row execute function generate_receipt_number();

-- RLS
alter table public.pos_sales enable row level security;
alter table public.pos_sale_items enable row level security;
alter table public.pos_receipts enable row level security;
alter table public.pos_cash_sessions enable row level security;

-- Pharmacy staff manage POS
-- (audit Module 0, 29/08/2026 : `public.pharmacy_staff` n'existe pas — la
-- table de rattachement personnel/officine s'appelle `public.profiles`
-- [colonne pharmacy_id] et le test correct est déjà centralisé dans
-- `public.is_pharmacy_staff()`, cf. 20260827002000_staff_write_policies.sql.
-- La version d'origine comparait aussi `pharmacy_id = pharmacy_id`, soit la
-- même colonne des deux côtés : toujours vraie dès que la colonne n'est pas
-- nulle, quel que soit l'utilisateur.)
create policy "Pharmacy staff manage POS" on public.pos_sales
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Cashiers can create sales
create policy "Cashiers create sales" on public.pos_sales
  for insert with check (public.is_pharmacy_staff(pharmacy_id));

-- Sale items managed with sale
create policy "Sale items managed with sale" on public.pos_sale_items
  for all using (
    exists (
      select 1 from public.pos_sales
      where id = sale_id and public.is_pharmacy_staff(pharmacy_id)
    )
  );

-- Receipts: pharmacy staff manage
create policy "Pharmacy staff manage receipts" on public.pos_receipts
  for all using (
    exists (
      select 1 from public.pos_sales
      where id = sale_id and public.is_pharmacy_staff(pharmacy_id)
    )
  );

-- Cash sessions: pharmacy staff manage
create policy "Pharmacy staff manage cash sessions" on public.pos_cash_sessions
  for all using (public.is_pharmacy_staff(pharmacy_id));
