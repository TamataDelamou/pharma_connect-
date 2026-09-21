-- Marketplace module: B2B offers and orders

-- B2B offers
create table b2b_offers (
  id uuid primary key default gen_random_uuid(),
  seller_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  description text,
  price integer not null, -- in minor unit
  quantity integer not null,
  unit text default 'unité',
  min_order_quantity integer default 1,
  expiry_date date,
  status text default 'active' check (status in ('active', 'expired', 'sold_out', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- B2B orders
create table b2b_orders (
  id uuid primary key default gen_random_uuid(),
  buyer_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  seller_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  status text not null check (status in ('draft', 'submitted', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  total_amount integer not null,
  notes text,
  submitted_at timestamptz,
  confirmed_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- B2B order items
create table b2b_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.b2b_orders(id) on delete cascade,
  offer_id uuid references public.b2b_offers(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- B2B negotiations
create table b2b_negotiations (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.b2b_offers(id) on delete cascade,
  buyer_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  proposed_price integer not null,
  proposed_quantity integer,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected', 'countered')),
  counter_offer_price integer,
  counter_offer_quantity integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_b2b_offers_seller_pharmacy on public.b2b_offers(seller_pharmacy_id);
create index idx_b2b_offers_product_id on public.b2b_offers(product_id);
create index idx_b2b_offers_status on public.b2b_offers(status);
create index idx_b2b_orders_buyer_pharmacy on public.b2b_orders(buyer_pharmacy_id);
create index idx_b2b_orders_seller_pharmacy on public.b2b_orders(seller_pharmacy_id);
create index idx_b2b_orders_status on public.b2b_orders(status);
create index idx_b2b_order_items_order_id on public.b2b_order_items(order_id);
create index idx_b2b_negotiations_offer_id on public.b2b_negotiations(offer_id);
create index idx_b2b_negotiations_buyer_pharmacy on public.b2b_negotiations(buyer_pharmacy_id);

-- Triggers for updated_at
create trigger trigger_b2b_offers_updated_at
before update on public.b2b_offers
for each row execute function public.update_updated_at();

create trigger trigger_b2b_orders_updated_at
before update on public.b2b_orders
for each row execute function public.update_updated_at();

create trigger trigger_b2b_negotiations_updated_at
before update on public.b2b_negotiations
for each row execute function public.update_updated_at();

-- RLS
alter table public.b2b_offers enable row level security;
alter table public.b2b_orders enable row level security;
alter table public.b2b_order_items enable row level security;
alter table public.b2b_negotiations enable row level security;

-- B2B offers: everyone can view active offers
create policy "Everyone view active offers" on public.b2b_offers
  for select using (status = 'active' and (expiry_date is null or expiry_date > now()));

-- Sellers manage their offers
create policy "Sellers manage offers" on public.b2b_offers
  for all using (auth.uid() = seller_pharmacy_id);

-- B2B orders: involved pharmacies can view
create policy "Involved pharmacies view orders" on public.b2b_orders
  for select using (auth.uid() in (buyer_pharmacy_id, seller_pharmacy_id));

-- Buyers create orders
create policy "Buyers create orders" on public.b2b_orders
  for insert with check (auth.uid() = buyer_pharmacy_id);

-- Sellers update orders (confirm, ship)
create policy "Sellers update orders" on public.b2b_orders
  for update using (auth.uid() = seller_pharmacy_id);

-- Order items: viewable with order
create policy "Order items viewable with order" on public.b2b_order_items
  for select using (
    exists (
      select 1 from public.b2b_orders
      where id = order_id and auth.uid() in (buyer_pharmacy_id, seller_pharmacy_id)
    )
  );

-- Order items: managed with order
create policy "Order items managed with order" on public.b2b_order_items
  for all using (
    exists (
      select 1 from public.b2b_orders
      where id = order_id and auth.uid() = buyer_pharmacy_id
    )
  );

-- Negotiations: involved pharmacies view
create policy "Involved pharmacies view negotiations" on public.b2b_negotiations
  for select using (
    exists (
      select 1 from public.b2b_offers
      where id = offer_id and auth.uid() = seller_pharmacy_id
    ) or auth.uid() = buyer_pharmacy_id
  );

-- Buyers create negotiations
create policy "Buyers create negotiations" on public.b2b_negotiations
  for insert with check (auth.uid() = buyer_pharmacy_id);

-- Sellers update negotiations (accept/reject/counter)
create policy "Sellers update negotiations" on public.b2b_negotiations
  for update using (
    exists (
      select 1 from public.b2b_offers
      where id = offer_id and auth.uid() = seller_pharmacy_id
    )
  );
