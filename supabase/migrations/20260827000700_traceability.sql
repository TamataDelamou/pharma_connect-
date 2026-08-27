-- Module traceability (lib/modules/traceability). Traçabilité anti-
-- contrefaçon des lots, du fabricant au patient.

create table if not exists public.traceable_batches (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id),
  product_name text not null,
  batch_number text not null,
  serial_number text not null,
  gtin text not null,
  manufacturing_date date not null,
  expiry_date date not null,
  status text not null default 'manufactured' check (status in (
    'manufactured', 'inTransit', 'atDistributor', 'atPharmacy',
    'sold', 'dispensed', 'returned', 'recalled', 'destroyed'
  )),
  manufacturer text not null,
  manufacturer_id text,
  distributor text,
  distributor_id text,
  is_authenticated boolean not null default false,
  is_counterfeit boolean not null default false,
  last_verified_at timestamptz,
  is_recalled boolean not null default false,
  recalled_at timestamptz,
  recall_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.traceable_batches is 'Lots tracés (traceability/models/traceable_batch.dart).';

create index if not exists idx_traceable_batches_product_id on public.traceable_batches(product_id);
create index if not exists idx_traceable_batches_serial_number on public.traceable_batches(serial_number);
create index if not exists idx_traceable_batches_gtin on public.traceable_batches(gtin);

create trigger set_updated_at
  before update on public.traceable_batches
  for each row execute function public.set_updated_at();

create table if not exists public.batch_movements (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.traceable_batches(id) on delete cascade,
  type text not null check (type in (
    'shipment', 'receipt', 'sale', 'dispensation',
    'customerReturn', 'recall', 'transfer', 'destruction'
  )),
  from_location text not null,
  to_location text not null,
  from_location_type text not null,
  to_location_type text not null,
  user_id uuid references auth.users(id),
  user_name text,
  tracking_number text,
  notes text,
  temperature integer,
  is_cold_chain_required boolean not null default false,
  "timestamp" timestamptz not null default now()
);

comment on table public.batch_movements is 'Mouvements d''un lot (traceability/models/batch_movement.dart).';

create index if not exists idx_batch_movements_batch_id on public.batch_movements(batch_id);

create table if not exists public.cold_chain_records (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.traceable_batches(id) on delete cascade,
  temperature numeric not null,
  min_temperature numeric not null,
  max_temperature numeric not null,
  location text,
  device_id text,
  is_breach boolean not null default false,
  breach_reason text,
  "timestamp" timestamptz not null default now()
);

comment on table public.cold_chain_records is 'Relevés chaîne du froid liés à un lot tracé (traceability/models/cold_chain_record.dart).';

create index if not exists idx_cold_chain_records_batch_id on public.cold_chain_records(batch_id);

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.traceable_batches(id) on delete cascade,
  type text not null,
  title text not null,
  url text,
  issued_at timestamptz not null,
  expires_at timestamptz,
  issued_by text not null,
  verification_url text,
  is_valid boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.certificates is 'Certificats (CoA/CoO/CoC...) d''un lot (traceability/models/certificate.dart).';

create index if not exists idx_certificates_batch_id on public.certificates(batch_id);

create table if not exists public.verification_scans (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid references public.traceable_batches(id),
  serial_number text not null,
  gtin text not null,
  is_authentic boolean not null default false,
  is_counterfeit boolean not null default false,
  is_recalled boolean not null default false,
  is_valid boolean not null default false,
  status text not null check (status in (
    'authentic', 'counterfeit', 'recalled', 'unknown', 'invalid'
  )),
  message text,
  verified_by uuid references auth.users(id),
  "timestamp" timestamptz not null default now()
);

comment on table public.verification_scans is
  'Journal des scans de vérification anti-contrefaçon (traceability/models/verification_result.dart). Chaque scan est conservé : c''est la donnée de pharmacovigilance, pas seulement un résultat d''écran.';

create index if not exists idx_verification_scans_batch_id on public.verification_scans(batch_id);

alter table public.traceable_batches enable row level security;
alter table public.batch_movements enable row level security;
alter table public.cold_chain_records enable row level security;
alter table public.certificates enable row level security;
alter table public.verification_scans enable row level security;

create policy "traceable_batches_select_authenticated" on public.traceable_batches
  for select to authenticated using (true);

create policy "batch_movements_select_authenticated" on public.batch_movements
  for select to authenticated using (true);

create policy "cold_chain_records_select_authenticated" on public.cold_chain_records
  for select to authenticated using (true);

create policy "certificates_select_authenticated" on public.certificates
  for select to authenticated using (true);

create policy "verification_scans_select_authenticated" on public.verification_scans
  for select to authenticated using (true);

create policy "verification_scans_insert_authenticated" on public.verification_scans
  for insert to authenticated with check (true);
