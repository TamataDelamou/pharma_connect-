-- Insurance module: health insurance and third-party payment

-- Insurance companies
create table public.insurance_companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  type text not null check (type in ('private', 'public', 'mutual', 'international')),
  logo_url text,
  website text,
  phone text,
  email text,
  address text,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Insurance plans / policies
create table public.insurance_plans (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.insurance_companies(id) on delete cascade,
  name text not null,
  code text,
  description text,
  coverage_type text not null check (coverage_type in ('individual', 'family', 'group', 'corporate')),
  coverage_details jsonb default '{}'::jsonb, -- { 'inpatient': 80, 'outpatient': 70, 'drugs': 60, ... }
  max_coverage_per_year integer, -- in minor unit (GNF)
  max_coverage_per_visit integer,
  deductible integer, -- in minor unit
  waiting_period_days integer,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Patient insurance enrollments
create table public.insurance_enrollments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.insurance_plans(id) on delete cascade,
  policy_number text not null,
  member_number text,
  start_date date not null,
  end_date date,
  status text not null check (status in ('active', 'suspended', 'expired', 'cancelled')),
  coverage_percentage integer, -- override plan default
  annual_limit integer, -- override plan default
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, plan_id)
);

-- Pre-authorization requests
create table public.pre_authorizations (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.insurance_enrollments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid references public.profiles(id) on delete set null,
  hospital_id uuid references public.hospitals(id) on delete set null,
  procedure_type text not null, -- 'consultation', 'surgery', 'hospitalization', 'imaging', 'laboratory', 'drugs', 'other'
  procedure_description text not null,
  estimated_cost integer, -- in minor unit
  status text not null check (status in ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'expired')),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  approved_at timestamptz,
  approved_amount integer,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Insurance claims
create table public.insurance_claims (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.insurance_enrollments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  transaction_id uuid references public.transactions(id) on delete set null,
  pre_authorization_id uuid references public.pre_authorizations(id) on delete set null,
  claim_number text unique,
  total_amount integer not null, -- in minor unit
  covered_amount integer,
  patient_responsibility integer,
  status text not null check (status in ('draft', 'submitted', 'under_review', 'approved', 'partially_approved', 'rejected', 'paid')),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  approved_at timestamptz,
  paid_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Provider agreements (hospitals/professionals with insurance companies)
create table public.provider_agreements (
  id uuid primary key default gen_random_uuid(),
  provider_type text not null check (provider_type in ('hospital', 'professional', 'pharmacy')),
  provider_id uuid not null,
  company_id uuid not null references public.insurance_companies(id) on delete cascade,
  agreement_date date not null,
  expiration_date date,
  status text not null check (status in ('active', 'expired', 'terminated', 'pending')),
  terms text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(provider_type, provider_id, company_id)
);

-- Indexes
create index idx_insurance_companies_name on public.insurance_companies(name);
create index idx_insurance_plans_company_id on public.insurance_plans(company_id);
create index idx_insurance_enrollments_patient_id on public.insurance_enrollments(patient_id);
create index idx_insurance_enrollments_plan_id on public.insurance_enrollments(plan_id);
create index idx_insurance_enrollments_status on public.insurance_enrollments(status);
create index idx_pre_authorizations_enrollment_id on public.pre_authorizations(enrollment_id);
create index idx_pre_authorizations_patient_id on public.pre_authorizations(patient_id);
create index idx_pre_authorizations_status on public.pre_authorizations(status);
create index idx_insurance_claims_enrollment_id on public.insurance_claims(enrollment_id);
create index idx_insurance_claims_patient_id on public.insurance_claims(patient_id);
create index idx_insurance_claims_status on public.insurance_claims(status);
create index idx_provider_agreements_company_id on public.provider_agreements(company_id);
create index idx_provider_agreements_provider_id on public.provider_agreements(provider_id);

-- Triggers for updated_at
create trigger trigger_insurance_companies_updated_at
before update on public.insurance_companies
for each row execute function public.update_updated_at();

create trigger trigger_insurance_plans_updated_at
before update on public.insurance_plans
for each row execute function public.update_updated_at();

create trigger trigger_insurance_enrollments_updated_at
before update on public.insurance_enrollments
for each row execute function public.update_updated_at();

create trigger trigger_pre_authorizations_updated_at
before update on public.pre_authorizations
for each row execute function public.update_updated_at();

create trigger trigger_insurance_claims_updated_at
before update on public.insurance_claims
for each row execute function public.update_updated_at();

create trigger trigger_provider_agreements_updated_at
before update on public.provider_agreements
for each row execute function public.update_updated_at();

-- RLS
alter table public.insurance_companies enable row level security;
alter table public.insurance_plans enable row level security;
alter table public.insurance_enrollments enable row level security;
alter table public.pre_authorizations enable row level security;
alter table public.insurance_claims enable row level security;
alter table public.provider_agreements enable row level security;

-- Everyone can view insurance companies and plans
create policy "Everyone can view insurance companies" on public.insurance_companies
  for select using (true);

create policy "Everyone can view insurance plans" on public.insurance_plans
  for select using (true);

-- Patients can view their own enrollments
create policy "Patients view own enrollments" on public.insurance_enrollments
  for select using (auth.uid() = patient_id);

-- Staff can manage enrollments
create policy "Staff manage enrollments" on public.insurance_enrollments
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Pre-authorizations: patients view own, staff manage all
create policy "Patients view own pre-auths" on public.pre_authorizations
  for select using (auth.uid() = patient_id);

create policy "Staff manage pre-auths" on public.pre_authorizations
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Claims: patients view own, staff manage all
create policy "Patients view own claims" on public.insurance_claims
  for select using (auth.uid() = patient_id);

create policy "Staff manage claims" on public.insurance_claims
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Provider agreements: staff manage
create policy "Staff manage provider agreements" on public.provider_agreements
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Seed sample insurance companies
insert into public.insurance_companies (id, name, code, type, is_active)
values
  (gen_random_uuid(), 'Axa Assurances Guinée', 'AXA', 'private', true),
  (gen_random_uuid(), 'La Mutuelle Générale', 'MGEN', 'mutual', true),
  (gen_random_uuid(), 'CNSS Guinée', 'CNSS', 'public', true),
  (gen_random_uuid(), 'Allianz Guinée', 'ALLIANZ', 'private', true)
on conflict (code) do nothing;

-- Seed sample insurance plans
insert into public.insurance_plans (id, company_id, name, code, coverage_type, coverage_details, is_active)
select
  gen_random_uuid(),
  (select id from public.insurance_companies where code = 'AXA'),
  'AXA Santé Plus',
  'AXA-SP',
  'individual',
  '{"inpatient": 80, "outpatient": 70, "drugs": 60, "surgery": 75, "imaging": 65}'::jsonb,
  true
where exists (select 1 from public.insurance_companies where code = 'AXA');
