-- Hospitals module: healthcare facilities management

-- Hospital types catalog
create table public.hospital_types (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  category text, -- 'hospital', 'clinic', 'laboratory', 'imaging', 'pharmacy', 'other'
  requires_license boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Hospitals/healthcare facilities
create table public.hospitals (
  id uuid primary key default gen_random_uuid(),
  gsg_org_id text unique, -- Kernel Org Registry ID
  name text not null,
  type_id uuid references public.hospital_types(id),
  code text unique, -- internal code
  address text not null,
  city text,
  postal_code text,
  country text default 'Guinée',
  phone text,
  email text,
  website text,
  latitude numeric(10, 8),
  longitude numeric(11, 8),
  emergency_phone text,
  capacity integer, -- number of beds
  is_active boolean default true,
  is_emergency_available boolean default false,
  is_lab_available boolean default false,
  is_imaging_available boolean default false,
  is_pharmacy_available boolean default false,
  description text,
  logo_url text,
  license_number text,
  license_issuing_body text,
  license_expiry_date date,
  accreditation text, -- e.g., 'JCI', 'ISO', 'national'
  accreditation_expiry_date date,
  opening_hours jsonb default '{}'::jsonb, -- { 'monday': { 'open': '08:00', 'close': '18:00' }, ... }
  contact_person_name text,
  contact_person_phone text,
  contact_person_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text
);

-- Hospital departments/services
create table public.hospital_departments (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  name text not null,
  code text,
  description text,
  head_of_department_name text,
  head_of_department_phone text,
  head_of_department_email text,
  phone text,
  is_active boolean default true,
  capacity integer, -- beds in this department
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Professional affiliations to hospitals/departments
create table public.hospital_affiliations (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.profiles(id) on delete cascade,
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  department_id uuid references public.hospital_departments(id) on delete cascade,
  role text not null, -- 'head', 'staff', 'consultant', 'intern', 'volunteer', 'other'
  start_date date not null,
  end_date date,
  is_active boolean default true,
  primary_affiliation boolean default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(professional_id, hospital_id, department_id)
);

-- Hospital patient referrals
create table public.hospital_referrals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  from_hospital_id uuid not null references public.hospitals(id) on delete cascade,
  to_hospital_id uuid not null references public.hospitals(id) on delete cascade,
  reason text not null,
  referral_date timestamptz not null default now(),
  status text not null check (status in ('pending', 'accepted', 'completed', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_hospitals_gsg_org_id on public.hospitals(gsg_org_id);
create index idx_hospitals_type_id on public.hospitals(type_id);
create index idx_hospitals_name on public.hospitals(name);
create index idx_hospitals_city on public.hospitals(city);
create index idx_hospitals_is_active on public.hospitals(is_active);
create index idx_hospital_departments_hospital_id on public.hospital_departments(hospital_id);
create index idx_hospital_affiliations_professional_id on public.hospital_affiliations(professional_id);
create index idx_hospital_affiliations_hospital_id on public.hospital_affiliations(hospital_id);
create index idx_hospital_referrals_patient_id on public.hospital_referrals(patient_id);
create index idx_hospital_referrals_from_hospital on public.hospital_referrals(from_hospital_id);
create index idx_hospital_referrals_to_hospital on public.hospital_referrals(to_hospital_id);

-- Triggers for updated_at
create trigger trigger_hospitals_updated_at
before update on public.hospitals
for each row execute function public.update_updated_at();

create trigger trigger_hospital_departments_updated_at
before update on public.hospital_departments
for each row execute function public.update_updated_at();

create trigger trigger_hospital_affiliations_updated_at
before update on public.hospital_affiliations
for each row execute function public.update_updated_at();

create trigger trigger_hospital_referrals_updated_at
before update on public.hospital_referrals
for each row execute function public.update_updated_at();

-- RLS
alter table public.hospitals enable row level security;
alter table public.hospital_types enable row level security;
alter table public.hospital_departments enable row level security;
alter table public.hospital_affiliations enable row level security;
alter table public.hospital_referrals enable row level security;

-- Everyone can view hospital information (public data)
create policy "Everyone can view hospitals" on public.hospitals
  for select using (true);

-- Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-1 : les 5 policies
-- « Admins .../Staff ... » de ce module (4 dans ce fichier, 1 dans
-- 20260828021000_hospital_wait_times.sql) gatent l'écriture avec
-- `role in ('admin', 'staff')` — motif « rôle inatteignable » déjà
-- documenté et outillé par `is_gsg_admin()`. **Correction NON appliquée
-- directement ici** (contrairement à la convention habituelle de ce
-- projet pour un défaut trouvé dans la migration propre au module en
-- cours d'audit) : `is_gsg_admin()` est définie par
-- 20260829003800_admin_helpers.sql, datée du 29/08/2026, donc
-- POSTÉRIEURE à cette migration (27/08/2026) — un appel direct ici
-- casse le rejeu chronologique complet de la chaîne (`function
-- public.is_gsg_admin() does not exist`, vérifié par exécution réelle).
-- Correctif appliqué dans 20260830048000_hospitals_module_fixes.sql
-- (DROP POLICY / CREATE POLICY, après que la fonction existe), plutôt
-- que par édition en place — seul cas de ce type rencontré dans cet
-- audit où le motif « migration en cours d'audit » et la contrainte
-- d'ordre chronologique entrent en conflit.
create policy "Admins can manage hospitals" on public.hospitals
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Hospital types are read-only for all authenticated users
create policy "Authenticated users can view hospital types" on public.hospital_types
  for select using (auth.role() = 'authenticated');

-- Departments visible to everyone, managed by admins/staff
create policy "Everyone can view departments" on public.hospital_departments
  for select using (true);

create policy "Admins can manage departments" on public.hospital_departments
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Affiliations: professionals can view their own, admins view all
create policy "Professionals view own affiliations" on public.hospital_affiliations
  for select using (auth.uid() = professional_id);

create policy "Admins manage affiliations" on public.hospital_affiliations
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Referrals: patients and professionals can view, admins manage
create policy "Patients view own referrals" on public.hospital_referrals
  for select using (auth.uid() = patient_id);

create policy "Professionals view referrals" on public.hospital_referrals
  for select using (
    exists (
      select 1 from public.hospital_affiliations
      where professional_id = auth.uid() and hospital_id in (from_hospital_id, to_hospital_id)
    )
  );

create policy "Admins manage referrals" on public.hospital_referrals
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Seed hospital types
insert into public.hospital_types (id, code, name, category, description)
values
  (gen_random_uuid(), 'GEN_HOSP', 'Hôpital Général', 'hospital', 'Hôpital généraliste avec services complets'),
  (gen_random_uuid(), 'UNI_HOSP', 'Hôpital Universitaire', 'hospital', 'Hôpital universitaire avec formation'),
  (gen_random_uuid(), 'SPEC_HOSP', 'Hôpital Spécialisé', 'hospital', 'Hôpital spécialisé dans un domaine particulier'),
  (gen_random_uuid(), 'CLINIC', 'Clinique', 'clinic', 'Clinique privée'),
  (gen_random_uuid(), 'HEALTH_CTR', 'Centre de Santé', 'clinic', 'Centre de santé communautaire'),
  (gen_random_uuid(), 'LAB', 'Laboratoire d''Analyses', 'laboratory', 'Laboratoire d''analyses médicales'),
  (gen_random_uuid(), 'IMAGING', 'Centre d''Imagerie', 'imaging', 'Centre d''imagerie médicale'),
  (gen_random_uuid(), 'PHARMACY', 'Pharmacie', 'pharmacy', 'Pharmacie officinale')
on conflict (code) do nothing;
