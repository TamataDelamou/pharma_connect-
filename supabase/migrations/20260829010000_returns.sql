-- Returns module: customer returns and supplier returns

-- Return reasons catalog
create table public.return_reasons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  category text not null check (category in ('customer', 'supplier', 'both')),
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Customer returns
create table public.customer_returns (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  sale_id uuid references public.pos_sales(id) on delete set null,
  return_number text unique not null,
  return_date timestamptz not null default now(),
  reason_id uuid references public.return_reasons(id) on delete set null,
  reason_text text,
  status text not null check (status in ('pending', 'approved', 'rejected', 'completed', 'cancelled')),
  total_amount integer not null,
  refund_amount integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Customer return items
create table public.customer_return_items (
  id uuid primary key default gen_random_uuid(),
  return_id uuid not null references public.customer_returns(id) on delete cascade,
  sale_item_id uuid references public.pos_sale_items(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  reason_id uuid references public.return_reasons(id) on delete set null,
  reason_text text,
  condition text check (condition in ('new', 'used', 'damaged', 'expired')),
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Supplier returns (products returned to suppliers)
create table public.supplier_returns (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  supplier_order_id uuid references public.supplier_orders(id) on delete set null,
  return_number text unique not null,
  return_date timestamptz not null default now(),
  reason_id uuid references public.return_reasons(id) on delete set null,
  reason_text text,
  status text not null check (status in ('pending', 'approved', 'shipped', 'completed', 'cancelled')),
  total_amount integer not null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Supplier return items
create table public.supplier_return_items (
  id uuid primary key default gen_random_uuid(),
  return_id uuid not null references public.supplier_returns(id) on delete cascade,
  supplier_order_item_id uuid references public.supplier_order_items(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  reason_id uuid references public.return_reasons(id) on delete set null,
  reason_text text,
  condition text check (condition in ('new', 'damaged', 'expired')),
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Return tracking (audit trail)
create table public.return_tracking (
  id uuid primary key default gen_random_uuid(),
  return_type text not null check (return_type in ('customer', 'supplier')),
  return_id uuid not null,
  status text not null,
  changed_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_customer_returns_pharmacy_id on public.customer_returns(pharmacy_id);
create index idx_customer_returns_customer_id on public.customer_returns(customer_id);
create index idx_customer_returns_status on public.customer_returns(status);
create index idx_customer_return_items_return_id on public.customer_return_items(return_id);
create index idx_supplier_returns_pharmacy_id on public.supplier_returns(pharmacy_id);
create index idx_supplier_returns_supplier_id on public.supplier_returns(supplier_id);
create index idx_supplier_returns_status on public.supplier_returns(status);
create index idx_supplier_return_items_return_id on public.supplier_return_items(return_id);
create index idx_return_reasons_category on public.return_reasons(category);
create index idx_return_tracking_return_id on public.return_tracking(return_id);

-- Triggers for updated_at
create trigger trigger_customer_returns_updated_at
before update on public.customer_returns
for each row execute function public.update_updated_at();

create trigger trigger_supplier_returns_updated_at
before update on public.supplier_returns
for each row execute function public.update_updated_at();

create trigger trigger_return_reasons_updated_at
before update on public.return_reasons
for each row execute function public.update_updated_at();

-- Functions to generate return numbers
create or replace function generate_customer_return_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(return_number from '^CR([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.customer_returns;
  new.return_number := 'CR' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_customer_return_number
before insert on public.customer_returns
for each row execute function generate_customer_return_number();

create or replace function generate_supplier_return_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(return_number from '^SR([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.supplier_returns;
  new.return_number := 'SR' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_supplier_return_number
before insert on public.supplier_returns
for each row execute function generate_supplier_return_number();

-- Function to log return status changes
create or replace function log_return_status_change()
returns trigger as $$
begin
  if old.status is distinct from new.status then
    insert into public.return_tracking (
      return_type,
      return_id,
      status,
      changed_by,
      notes,
      created_at
    ) values (
      -- audit Module 0, 29/08/2026 : `cond ? a : b` n'est pas un opérateur
      -- PL/pgSQL valide (syntaxe C/JS) ; remplacé par un CASE WHEN.
      case when TG_TABLE_NAME = 'customer_returns' then 'customer' else 'supplier' end,
      new.id,
      new.status,
      auth.uid(),
      null,
      now()
    );
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_customer_return_status_log
after update of status on public.customer_returns
for each row execute function log_return_status_change();

create trigger trigger_supplier_return_status_log
after update of status on public.supplier_returns
for each row execute function log_return_status_change();

-- RLS
alter table public.return_reasons enable row level security;
alter table public.customer_returns enable row level security;
alter table public.customer_return_items enable row level security;
alter table public.supplier_returns enable row level security;
alter table public.supplier_return_items enable row level security;
alter table public.return_tracking enable row level security;

-- Everyone view return reasons
create policy "Everyone view return reasons" on public.return_reasons
  for select using (is_active = true);

-- Staff manage return reasons
-- (audit Module 0, 29/08/2026 : `role in ('admin','staff')` sur profiles est
-- inatteignable, voir 20260829003800_admin_helpers.sql ; remplacé par
-- is_gsg_admin(). Les policies "Pharmacy staff manage ... returns" ci-dessous
-- référençaient en outre `public.pharmacy_staff`, une table qui n'existe
-- pas — remplacé par is_pharmacy_staff().)
create policy "Staff manage return reasons" on public.return_reasons
  for all using (public.is_gsg_admin());

-- Pharmacy staff manage customer returns
create policy "Pharmacy staff manage customer returns" on public.customer_returns
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Pharmacy staff manage supplier returns
create policy "Pharmacy staff manage supplier returns" on public.supplier_returns
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Staff manage return tracking
create policy "Staff manage return tracking" on public.return_tracking
  for all using (public.is_gsg_admin());

-- Seed return reasons
insert into public.return_reasons (id, code, name, category, is_active)
values
  (gen_random_uuid(), 'DEFECTIVE', 'Produit défectueux', 'both', true),
  (gen_random_uuid(), 'WRONG_PRODUCT', 'Produit non conforme', 'both', true),
  (gen_random_uuid(), 'EXPIRED', 'Produit périmé', 'both', true),
  (gen_random_uuid(), 'CUSTOMER_CHANGE', 'Changement d''avis client', 'customer', true),
  (gen_random_uuid(), 'DAMAGED_IN_TRANSIT', 'Endommagé pendant le transport', 'customer', true),
  (gen_random_uuid(), 'SUPPLIER_ERROR', 'Erreur fournisseur', 'supplier', true),
  (gen_random_uuid(), 'QUALITY_ISSUE', 'Problème de qualité', 'supplier', true)
on conflict (code) do nothing;
