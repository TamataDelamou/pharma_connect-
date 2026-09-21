-- Professionals module: healthcare professionals management

-- Professional profiles (extends profiles with healthcare-specific fields)
create table public.professional_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  specialty text,
  qualifications text[], -- array of qualifications
  license_number text,
  license_issuing_body text,
  license_expiry_date date,
  years_of_experience integer,
  consultation_fee integer, -- in minor unit (GNF)
  home_visit_fee integer, -- in minor unit (GNF)
  is_accepting_new_patients boolean default true,
  bio text,
  consultation_duration_minutes integer default 30,
  languages_spoken text[], -- array of languages
  emergency_contact_name text,
  emergency_contact_phone text,
  profile_photo_url text,
  is_verified boolean default false,
  verification_status text check (verification_status in ('pending', 'verified', 'rejected')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Specialties catalog (for Referential Engine integration)
create table public.specialties (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  category text, -- 'medical', 'pharmacy', 'nursing', 'paramedical', 'other'
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Qualifications catalog
create table public.qualifications (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  issuing_body text,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Professional availability (weekly recurring)
create table public.professional_availability (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  is_teleconsult boolean default false,
  is_break boolean default false,
  break_duration_minutes integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Professional-patient interactions
create table public.professional_patient_interactions (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  interaction_date timestamptz not null default now(),
  type text not null check (type in ('consultation', 'prescription', 'referral', 'follow_up', 'emergency', 'other')),
  notes text,
  outcome text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Professional ratings and reviews
create table public.professional_reviews (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  review_text text,
  is_anonymous boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(professional_id, patient_id)
);

-- Indexes
create index idx_professional_profiles_specialty on public.professional_profiles(specialty);
create index idx_professional_profiles_is_verified on public.professional_profiles(is_verified);
create index idx_professional_availability_professional_id on public.professional_availability(professional_id);
create index idx_professional_availability_day_of_week on public.professional_availability(day_of_week);
create index idx_professional_interactions_professional_id on public.professional_patient_interactions(professional_id);
create index idx_professional_interactions_patient_id on public.professional_patient_interactions(patient_id);
create index idx_professional_reviews_professional_id on public.professional_reviews(professional_id);
create index idx_professional_reviews_rating on public.professional_reviews(rating);

-- Triggers for updated_at
create trigger trigger_professional_profiles_updated_at
before update on public.professional_profiles
for each row execute function public.update_updated_at();

create trigger trigger_specialties_updated_at
before update on public.specialties
for each row execute function public.update_updated_at();

create trigger trigger_qualifications_updated_at
before update on public.qualifications
for each row execute function public.update_updated_at();

create trigger trigger_professional_availability_updated_at
before update on public.professional_availability
for each row execute function public.update_updated_at();

create trigger trigger_professional_interactions_updated_at
before update on public.professional_patient_interactions
for each row execute function public.update_updated_at();

create trigger trigger_professional_reviews_updated_at
before update on public.professional_reviews
for each row execute function public.update_updated_at();

-- RLS
alter table public.professional_profiles enable row level security;
alter table public.specialties enable row level security;
alter table public.qualifications enable row level security;
alter table public.professional_availability enable row level security;
alter table public.professional_patient_interactions enable row level security;
alter table public.professional_reviews enable row level security;

-- Professionals can view all professional profiles
create policy "Everyone can view professional profiles" on public.professional_profiles
  for select using (true);

-- Professionals can update own profile
create policy "Professionals can update own profile" on public.professional_profiles
  for update using (auth.uid() = id);

-- Admins can manage all profiles (handled via admin module later)
create policy "Admins can manage professional profiles" on public.professional_profiles
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Specialties and qualifications are read-only for authenticated users
create policy "Authenticated users can view specialties" on public.specialties
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can view qualifications" on public.qualifications
  for select using (auth.role() = 'authenticated');

-- Professionals manage own availability
create policy "Professionals manage own availability" on public.professional_availability
  for all using (auth.uid() = professional_id);

-- Everyone can view availability slots (for booking)
create policy "Everyone can view availability" on public.professional_availability
  for select using (true);

-- Interactions: professionals can view/manage their own, patients can view theirs
create policy "Professionals view own interactions" on public.professional_patient_interactions
  for all using (auth.uid() = professional_id);

create policy "Patients view own interactions" on public.professional_patient_interactions
  for select using (auth.uid() = patient_id);

-- Reviews: anyone can view, patients can create/update own
create policy "Everyone can view reviews" on public.professional_reviews
  for select using (true);

create policy "Patients can create reviews" on public.professional_reviews
  for insert with check (auth.uid() = patient_id);

create policy "Patients can update own reviews" on public.professional_reviews
  for update using (auth.uid() = patient_id);
