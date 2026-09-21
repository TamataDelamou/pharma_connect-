-- HomeCare module

-- Availability slots for homecare professionals
create table public.homecare_availability_slots (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  duration_minutes integer default 60,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Homecare interventions
create table public.homecare_interventions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_at timestamptz not null,
  duration_minutes integer default 60,
  status text not null check (status in ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'missed')),
  reason text,
  address text not null,
  notes text,
  report text, -- compte-rendu de la visite
  patient_feedback text,
  patient_rating integer check (patient_rating between 1 and 5),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Equipment used during intervention (optional, many-to-many)
create table public.homecare_equipment (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.homecare_intervention_equipment (
  intervention_id uuid references public.homecare_interventions(id) on delete cascade,
  equipment_id uuid references public.homecare_equipment(id) on delete cascade,
  quantity integer default 1,
  notes text,
  primary key (intervention_id, equipment_id)
);

-- Indexes
create index idx_homecare_interventions_patient_id on public.homecare_interventions(patient_id);
create index idx_homecare_interventions_professional_id on public.homecare_interventions(professional_id);
create index idx_homecare_interventions_scheduled_at on public.homecare_interventions(scheduled_at);
create index idx_homecare_interventions_status on public.homecare_interventions(status);
create index idx_homecare_availability_professional on public.homecare_availability_slots(professional_id);

-- Triggers for updated_at
create trigger trigger_homecare_interventions_updated_at
before update on public.homecare_interventions
for each row execute function public.update_updated_at();

create trigger trigger_homecare_availability_updated_at
before update on public.homecare_availability_slots
for each row execute function public.update_updated_at();

-- RLS
alter table public.homecare_interventions enable row level security;
alter table public.homecare_availability_slots enable row level security;
alter table public.homecare_equipment enable row level security;
alter table public.homecare_intervention_equipment enable row level security;

-- Patients: view and manage own interventions
create policy "Patients can view own interventions" on public.homecare_interventions
  for select using (auth.uid() = patient_id);

create policy "Patients can update own interventions" on public.homecare_interventions
  for update using (auth.uid() = patient_id)
  with check (status in ('cancelled'));

create policy "Patients can insert own interventions" on public.homecare_interventions
  for insert with check (auth.uid() = patient_id);

-- Professionals: view and manage assigned interventions
create policy "Professionals can view assigned interventions" on public.homecare_interventions
  for select using (auth.uid() = professional_id);

create policy "Professionals can update assigned interventions" on public.homecare_interventions
  for update using (auth.uid() = professional_id);

-- Professionals manage own availability slots
create policy "Professionals manage own availability" on public.homecare_availability_slots
  for all using (auth.uid() = professional_id);

-- Everyone can view availability slots (to book)
create policy "Anyone can view availability slots" on public.homecare_availability_slots
  for select using (true);

-- Equipment is read-only for all authenticated users (admin can manage later)
create policy "Authenticated users can view equipment" on public.homecare_equipment
  for select using (auth.role() = 'authenticated');

create policy "Professionals can manage equipment on interventions" on public.homecare_intervention_equipment
  for all using (
    exists (
      select 1 from public.homecare_interventions
      where id = intervention_id and professional_id = auth.uid()
    )
  );
