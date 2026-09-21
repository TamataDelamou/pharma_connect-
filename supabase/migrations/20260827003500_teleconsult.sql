-- Teleconsult module: availability slots and consultations

-- Availability slots (recurring weekly slots for professionals)
create table public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6), -- 0=Sunday, 6=Saturday
  start_time time not null,
  end_time time not null,
  duration_minutes integer default 30,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Consultations
create table public.consultations (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_at timestamptz not null,
  duration_minutes integer default 30,
  status text not null check (status in ('pending', 'confirmed', 'completed', 'cancelled', 'missed')),
  reason text,
  notes text,
  meeting_url text, -- generated link for video call
  patient_feedback text,
  professional_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_consultations_patient_id on public.consultations(patient_id);
create index idx_consultations_professional_id on public.consultations(professional_id);
create index idx_consultations_scheduled_at on public.consultations(scheduled_at);
create index idx_consultations_status on public.consultations(status);
create index idx_availability_slots_professional_id on public.availability_slots(professional_id);
create index idx_availability_slots_day_of_week on public.availability_slots(day_of_week);

-- Trigger updated_at
create trigger trigger_consultations_updated_at
before update on public.consultations
for each row execute function public.update_updated_at();

create trigger trigger_availability_slots_updated_at
before update on public.availability_slots
for each row execute function public.update_updated_at();

-- RLS
alter table public.consultations enable row level security;
alter table public.availability_slots enable row level security;

-- Patients can view and manage their own consultations
create policy "Patients can view own consultations" on public.consultations
  for select using (auth.uid() = patient_id);

create policy "Patients can update own consultations" on public.consultations
  for update using (auth.uid() = patient_id)
  with check (status in ('cancelled'));

create policy "Patients can insert own consultations" on public.consultations
  for insert with check (auth.uid() = patient_id);

-- Professionals can view and manage consultations assigned to them
create policy "Professionals can view assigned consultations" on public.consultations
  for select using (auth.uid() = professional_id);

create policy "Professionals can update assigned consultations" on public.consultations
  for update using (auth.uid() = professional_id);

-- Professionals manage their own availability slots
create policy "Professionals can manage own availability" on public.availability_slots
  for all using (auth.uid() = professional_id);

-- Patients can view availability slots of all professionals (to book)
create policy "Anyone can view availability slots" on public.availability_slots
  for select using (true);
