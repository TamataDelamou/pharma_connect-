-- Module coldchain (lib/modules/coldchain). Équipements frigorifiques,
-- relevés de température et incidents de chaîne du froid.

create table if not exists public.cold_equipment (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null check (type in (
    'refrigerator', 'freezer', 'coldRoom', 'transportBox', 'coolBox'
  )),
  status text not null default 'operational' check (status in (
    'operational', 'maintenance', 'alarm', 'offline'
  )),
  serial_number text not null,
  model text not null,
  manufacturer text not null,
  min_temperature numeric not null,
  max_temperature numeric not null,
  current_temperature numeric not null,
  last_calibration_date date,
  next_calibration_date date,
  location text,
  pharmacy_id uuid references public.pharmacies(id),
  is_active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.cold_equipment is 'Équipements de chaîne du froid (coldchain/models/cold_equipment.dart).';

create index if not exists idx_cold_equipment_pharmacy_id on public.cold_equipment(pharmacy_id);

create trigger set_updated_at
  before update on public.cold_equipment
  for each row execute function public.set_updated_at();

create table if not exists public.temperature_records (
  id uuid primary key default gen_random_uuid(),
  equipment_id uuid not null references public.cold_equipment(id) on delete cascade,
  temperature numeric not null,
  min_temperature numeric,
  max_temperature numeric,
  type text not null default 'automatic' check (type in ('manual', 'automatic', 'sensor')),
  recorded_by text,
  notes text,
  is_alert boolean not null default false,
  alert_id uuid,
  "timestamp" timestamptz not null default now()
);

comment on table public.temperature_records is 'Relevés de température (coldchain/models/temperature_record.dart).';

create index if not exists idx_temperature_records_equipment_id on public.temperature_records(equipment_id);
create index if not exists idx_temperature_records_timestamp on public.temperature_records("timestamp" desc);

create table if not exists public.cold_incidents (
  id uuid primary key default gen_random_uuid(),
  equipment_id uuid not null references public.cold_equipment(id),
  equipment_name text not null,
  batch_id uuid references public.traceable_batches(id),
  batch_number text,
  product_name text,
  occurred_at timestamptz not null default now(),
  resolved_at timestamptz,
  temperature_recorded numeric not null,
  min_temperature numeric not null,
  max_temperature numeric not null,
  severity text not null check (severity in ('critical', 'major', 'minor')),
  resolution_notes text,
  reported_by text,
  is_resolved boolean not null default false,
  affected_products text
);

comment on table public.cold_incidents is 'Incidents de rupture de chaîne du froid (coldchain/models/cold_incident.dart).';

create index if not exists idx_cold_incidents_equipment_id on public.cold_incidents(equipment_id);
create index if not exists idx_cold_incidents_batch_id on public.cold_incidents(batch_id);

alter table public.cold_equipment enable row level security;
alter table public.temperature_records enable row level security;
alter table public.cold_incidents enable row level security;

create policy "cold_equipment_select_authenticated" on public.cold_equipment
  for select to authenticated using (true);

create policy "temperature_records_select_authenticated" on public.temperature_records
  for select to authenticated using (true);

create policy "cold_incidents_select_authenticated" on public.cold_incidents
  for select to authenticated using (true);
