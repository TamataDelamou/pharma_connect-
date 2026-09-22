-- Triage module: urgent care intake and assessment

-- Patients awaiting triage
create table public.triage_patients (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  triage_nurse_id uuid references public.profiles(id) on delete set null,
  arrival_time timestamptz not null default now(),
  status text not null check (status in ('waiting', 'in_assessment', 'assigned', 'discharged', 'transferred')),
  priority_level integer not null check (priority_level between 1 and 5), -- 1=immediate, 5=non-urgent
  chief_complaint text not null,
  symptoms text,
  vital_signs jsonb default '{}'::jsonb,
  notes text,
  assigned_department text, -- e.g., 'cardiology', 'trauma', 'pediatrics'
  assigned_doctor_id uuid references public.profiles(id) on delete set null,
  triage_result text,
  discharged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Triage assessments (the actual triage evaluation)
create table public.triage_assessments (
  id uuid primary key default gen_random_uuid(),
  triage_patient_id uuid not null references public.triage_patients(id) on delete cascade,
  nurse_id uuid not null references public.profiles(id) on delete cascade,
  assessment_time timestamptz not null default now(),
  pain_score integer check (pain_score between 0 and 10),
  respiratory_rate integer,
  heart_rate integer,
  blood_pressure_systolic integer,
  blood_pressure_diastolic integer,
  temperature numeric,
  oxygen_saturation integer,
  consciousness_level text check (consciousness_level in ('alert', 'verbal', 'pain', 'unresponsive')),
  triage_category text check (triage_category in ('resuscitation', 'emergency', 'urgent', 'semi-urgent', 'non-urgent')),
  recommendations text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_triage_patients_patient_id on public.triage_patients(patient_id);
create index idx_triage_patients_status on public.triage_patients(status);
create index idx_triage_patients_priority_level on public.triage_patients(priority_level);
create index idx_triage_patients_arrival_time on public.triage_patients(arrival_time);
create index idx_triage_assessments_triage_patient_id on public.triage_assessments(triage_patient_id);

-- Triggers for updated_at
create trigger trigger_triage_patients_updated_at
before update on public.triage_patients
for each row execute function public.update_updated_at();

create trigger trigger_triage_assessments_updated_at
before update on public.triage_assessments
for each row execute function public.update_updated_at();

-- RLS
alter table public.triage_patients enable row level security;
alter table public.triage_assessments enable row level security;

-- Patients can view their own triage records
create policy "Patients can view own triage records" on public.triage_patients
  for select using (auth.uid() = patient_id);

-- Nurses can view and manage all triage patients (role = 'professionnel' or 'pharmacien' with permission)
-- In a real system, you'd have a specific 'triage_nurse' role; we'll use 'professionnel' for demo
create policy "Nurses can view all triage patients" on public.triage_patients
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

create policy "Nurses can update triage patients" on public.triage_patients
  for update using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

create policy "Nurses can insert triage patients" on public.triage_patients
  for insert with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

-- Nurses can manage assessments
create policy "Nurses can manage assessments" on public.triage_assessments
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

-- Patients can view their own assessments (through join)
create policy "Patients can view own assessments" on public.triage_assessments
  for select using (
    exists (
      select 1 from public.triage_patients
      where id = triage_patient_id and patient_id = auth.uid()
    )
  );
