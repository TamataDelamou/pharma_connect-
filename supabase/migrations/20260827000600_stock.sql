-- Module stock (lib/modules/stock). `pharmacy_id` sur stock_items est ajouté
-- ici sans équivalent direct dans StockItem (Dart) : le modèle actuel ne
-- porte qu'un `defaultLocation` texte libre, mais un stock persisté doit
-- nécessairement être scopé par officine (deux pharmacies ne partagent pas
-- le même stock d'un même produit) — sans quoi le module Multi-officines
-- n'a pas de fondation. De même, `unit_price` n'existe dans aucun modèle
-- Dart de ce module ; c'est pourtant le seul endroit logique où stocker le
-- prix de vente d'un produit par officine (recherche/disponibilité en a
-- besoin — voir search/models/availability_result.dart : PharmacyStock.price
-- côté Dart est aujourd'hui une valeur mockée, pas persistée).

create table if not exists public.stock_items (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id),
  product_id uuid not null references public.products(id),
  total_quantity integer not null default 0,
  reserved_quantity integer not null default 0,
  threshold_low integer not null default 20,
  threshold_critical integer not null default 5,
  default_location text,
  unit_price integer not null default 0,
  status text not null default 'inStock' check (status in (
    'inStock', 'lowStock', 'critical', 'outOfStock', 'discontinued'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pharmacy_id, product_id)
);

comment on table public.stock_items is 'Niveau de stock d''un produit dans une officine (stock/models/stock_item.dart).';
comment on column public.stock_items.unit_price is 'Prix de vente unitaire, unité mineure (KER-REF-05). Absent du modèle Dart StockItem actuel ; ajouté pour que la recherche/disponibilité ait une source de prix persistée.';

create index if not exists idx_stock_items_pharmacy_id on public.stock_items(pharmacy_id);
create index if not exists idx_stock_items_product_id on public.stock_items(product_id);

create trigger set_updated_at
  before update on public.stock_items
  for each row execute function public.set_updated_at();

create table if not exists public.stock_batches (
  id uuid primary key default gen_random_uuid(),
  stock_item_id uuid not null references public.stock_items(id) on delete cascade,
  batch_number text not null,
  manufacturing_date date not null,
  expiry_date date not null,
  quantity integer not null default 0,
  quantity_reserved integer not null default 0,
  purchase_price integer not null default 0,
  received_at timestamptz,
  supplier_id text,
  supplier_name text,
  location text,
  created_at timestamptz not null default now()
);

comment on table public.stock_batches is 'Lots FEFO d''un article de stock (stock/models/stock_batch.dart).';
comment on column public.stock_batches.purchase_price is 'Prix d''achat unitaire, unité mineure (KER-REF-05) — correspond à StockBatch.purchasePriceInt côté Dart.';

create index if not exists idx_stock_batches_stock_item_id on public.stock_batches(stock_item_id);
create index if not exists idx_stock_batches_expiry_date on public.stock_batches(expiry_date);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  stock_item_id uuid not null references public.stock_items(id) on delete cascade,
  batch_id uuid references public.stock_batches(id),
  type text not null check (type in (
    'purchase', 'sale', 'adjustment', 'expiry', 'breakage',
    'supplierReturn', 'transfer', 'reservation', 'unreservation'
  )),
  quantity integer not null,
  user_id uuid references auth.users(id),
  user_name text,
  reference_id text,
  reason text,
  notes text,
  "timestamp" timestamptz not null default now()
);

comment on table public.stock_movements is 'Historique des mouvements de stock (stock/models/stock_movement.dart). quantity positif = entrée, négatif = sortie.';

create index if not exists idx_stock_movements_stock_item_id on public.stock_movements(stock_item_id);
create index if not exists idx_stock_movements_timestamp on public.stock_movements("timestamp" desc);

create table if not exists public.stock_adjustments (
  id uuid primary key default gen_random_uuid(),
  stock_item_id uuid not null references public.stock_items(id) on delete cascade,
  batch_id uuid references public.stock_batches(id),
  reason text not null check (reason in (
    'inventoryCorrection', 'damage', 'theft', 'returnToSupplier', 'sample', 'other'
  )),
  quantity integer not null,
  user_id uuid references auth.users(id),
  user_name text,
  notes text,
  "timestamp" timestamptz not null default now()
);

comment on table public.stock_adjustments is 'Ajustements manuels de stock (stock/models/stock_adjustment.dart).';

create index if not exists idx_stock_adjustments_stock_item_id on public.stock_adjustments(stock_item_id);

alter table public.stock_items enable row level security;
alter table public.stock_batches enable row level security;
alter table public.stock_movements enable row level security;
alter table public.stock_adjustments enable row level security;

create policy "stock_items_select_authenticated" on public.stock_items
  for select to authenticated using (true);

create policy "stock_batches_select_authenticated" on public.stock_batches
  for select to authenticated using (true);

create policy "stock_movements_select_authenticated" on public.stock_movements
  for select to authenticated using (true);

create policy "stock_adjustments_select_authenticated" on public.stock_adjustments
  for select to authenticated using (true);
