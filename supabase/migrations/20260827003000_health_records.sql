-- Health Records module
create table public.health_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  blood_type text,
  height integer,
  weight integer,
  allergies jsonb default '[]'::jsonb,
  medical_conditions jsonb default '[]'::jsonb,
  medications jsonb default '[]'::jsonb,
  vaccinations jsonb default '[]'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Index
create index idx_health_records_patient_id on public.health_records(patient_id);

-- Trigger updated_at
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trigger_health_records_updated_at
before update on public.health_records
for each row execute function public.update_updated_at();

-- RLS
alter table public.health_records enable row level security;

-- Patients can view/modify own records
create policy "Patients can view own records" on public.health_records
  for select using (auth.uid() = patient_id);

create policy "Patients can update own records" on public.health_records
  for update using (auth.uid() = patient_id);

create policy "Patients can insert own records" on public.health_records
  for insert with check (auth.uid() = patient_id);

-- Professionals (pharmacien, professionnel) can view all records (read-only)
create policy "Professionals can view all records" on public.health_records
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('pharmacien', 'professionnel')
    )
  );

-- (Future) Professionals can update with patient consent via separate policy
