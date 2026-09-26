-- Offline sales queue
create table public.offline_sales_queue (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  cashier_id uuid not null references public.profiles(id) on delete cascade,
  sale_data jsonb not null,
  items_data jsonb not null,
  receipt_data jsonb,
  status text default 'pending' check (status in ('pending', 'syncing', 'completed', 'failed')),
  retry_count integer default 0,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Offline product catalog cache
create table public.offline_product_cache (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  price integer not null,
  stock_quantity integer not null,
  batch_id uuid,
  last_synced timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(pharmacy_id, product_id)
);

-- Offline transactions
create table public.offline_transactions (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  sale_id text,
  cashier_id uuid references public.profiles(id) on delete set null,
  amount integer not null,
  status text default 'pending' check (status in ('pending', 'synced', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_offline_sales_queue_pharmacy_id on public.offline_sales_queue(pharmacy_id);
create index idx_offline_sales_queue_status on public.offline_sales_queue(status);
create index idx_offline_product_cache_pharmacy_id on public.offline_product_cache(pharmacy_id);
create index idx_offline_product_cache_product_id on public.offline_product_cache(product_id);

-- RLS
alter table public.offline_sales_queue enable row level security;
alter table public.offline_product_cache enable row level security;
alter table public.offline_transactions enable row level security;

-- Pharmacy staff manage
-- (audit Module 0, 29/08/2026 : `public.pharmacy_staff` n'existe pas, voir
-- la même note dans 20260829006000_pos.sql — remplacé par is_pharmacy_staff().)
create policy "Pharmacy staff manage offline sales" on public.offline_sales_queue
  for all using (public.is_pharmacy_staff(pharmacy_id));

create policy "Pharmacy staff manage offline cache" on public.offline_product_cache
  for all using (public.is_pharmacy_staff(pharmacy_id));
