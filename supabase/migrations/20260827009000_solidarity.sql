-- Solidarity module: humanitarian access to healthcare

-- Solidarity programs (e.g., free medication distribution, subsidized care)
create table public.solidarity_programs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  type text not null check (type in ('free_medication', 'subsidized_care', 'emergency_aid', 'health_education')),
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  start_date date not null,
  end_date date,
  budget integer, -- in minor unit
  used_budget integer default 0,
  is_active boolean default true,
  eligibility_criteria jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Solidarity beneficiaries (patients enrolled in programs)
create table public.solidarity_beneficiaries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  program_id uuid not null references public.solidarity_programs(id) on delete cascade,
  enrollment_date date not null default now(),
  status text not null check (status in ('active', 'completed', 'suspended', 'expired')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, program_id)
);

-- Solidarity distributions (medication or aid given)
create table public.solidarity_distributions (
  id uuid primary key default gen_random_uuid(),
  beneficiary_id uuid not null references public.solidarity_beneficiaries(id) on delete cascade,
  program_id uuid not null references public.solidarity_programs(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  value integer, -- in minor unit
  distribution_date timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Donations (from individuals, organizations, or pharmacies)
create table public.solidarity_donations (
  id uuid primary key default gen_random_uuid(),
  donor_type text not null check (donor_type in ('individual', 'organization', 'pharmacy', 'company')),
  donor_id uuid references public.profiles(id) on delete set null,
  donor_name text not null,
  donor_email text,
  donor_phone text,
  donation_type text not null check (donation_type in ('money', 'medication', 'supplies', 'other')),
  amount integer, -- in minor unit (for money)
  product_id uuid references public.products(id) on delete set null,
  product_name text,
  quantity integer,
  value integer, -- estimated value
  notes text,
  received_date timestamptz not null default now(),
  allocated_to_program_id uuid references public.solidarity_programs(id) on delete set null,
  status text not null check (status in ('pending', 'received', 'allocated', 'distributed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Solidarity impact metrics (aggregated)
create view solidarity_impact as
select
  sp.id as program_id,
  sp.name as program_name,
  count(distinct sb.id) as beneficiaries_count,
  count(distinct sd.id) as distributions_count,
  coalesce(sum(sd.quantity), 0) as total_items_distributed,
  coalesce(sum(sd.value), 0) as total_value_distributed,
  coalesce(sum(sd.value * sd.quantity), 0) as total_items_value,
  coalesce(sum(d.amount), 0) as total_donations_received
from solidarity_programs sp
left join solidarity_beneficiaries sb on sb.program_id = sp.id and sb.status = 'active'
left join solidarity_distributions sd on sd.program_id = sp.id
left join solidarity_donations d on d.allocated_to_program_id = sp.id and d.status = 'received'
group by sp.id, sp.name;

-- Indexes
create index idx_solidarity_beneficiaries_patient_id on public.solidarity_beneficiaries(patient_id);
create index idx_solidarity_beneficiaries_program_id on public.solidarity_beneficiaries(program_id);
create index idx_solidarity_beneficiaries_status on public.solidarity_beneficiaries(status);
create index idx_solidarity_distributions_beneficiary_id on public.solidarity_distributions(beneficiary_id);
create index idx_solidarity_distributions_program_id on public.solidarity_distributions(program_id);
create index idx_solidarity_donations_status on public.solidarity_donations(status);
create index idx_solidarity_donations_donor_type on public.solidarity_donations(donor_type);

-- Triggers for updated_at
create trigger trigger_solidarity_programs_updated_at
before update on public.solidarity_programs
for each row execute function public.update_updated_at();

create trigger trigger_solidarity_beneficiaries_updated_at
before update on public.solidarity_beneficiaries
for each row execute function public.update_updated_at();

create trigger trigger_solidarity_donations_updated_at
before update on public.solidarity_donations
for each row execute function public.update_updated_at();

-- RLS
alter table public.solidarity_programs enable row level security;
alter table public.solidarity_beneficiaries enable row level security;
alter table public.solidarity_distributions enable row level security;
alter table public.solidarity_donations enable row level security;

-- Everyone can view programs
create policy "Everyone view solidarity programs" on public.solidarity_programs
  for select using (true);

-- Staff manage programs
create policy "Staff manage solidarity programs" on public.solidarity_programs
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Beneficiaries: patients view own, staff view all
create policy "Patients view own beneficiaries" on public.solidarity_beneficiaries
  for select using (auth.uid() = patient_id);

create policy "Staff manage beneficiaries" on public.solidarity_beneficiaries
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Patients can enroll themselves (if program allows self-enrollment)
create policy "Patients enroll themselves" on public.solidarity_beneficiaries
  for insert with check (auth.uid() = patient_id);

-- Distributions: patients view own, staff manage
create policy "Patients view own distributions" on public.solidarity_distributions
  for select using (
    exists (
      select 1 from public.solidarity_beneficiaries
      where id = beneficiary_id and patient_id = auth.uid()
    )
  );

create policy "Staff manage distributions" on public.solidarity_distributions
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Donations: donors can view their own, staff manage all
create policy "Donors view own donations" on public.solidarity_donations
  for select using (auth.uid() = donor_id);

create policy "Staff manage donations" on public.solidarity_donations
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

create policy "Anyone can create donations" on public.solidarity_donations
  for insert with check (auth.role() = 'authenticated');
