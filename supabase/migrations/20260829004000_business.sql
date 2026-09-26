-- Business module: Business Development & Strategic Partnerships

-- Business companies (hospitals, clinics, wholesalers, etc.)
create table public.business_companies (
  id uuid primary key default gen_random_uuid(),
  gsg_org_id text unique,
  name text not null,
  legal_name text,
  registration_number text,
  tax_id text,
  type text not null check (type in ('hospital', 'clinic', 'wholesaler', 'laboratory', 'pharmacy_chain', 'insurance', 'other')),
  status text default 'active' check (status in ('active', 'inactive', 'pending', 'suspended', 'archived')),
  address text,
  city text,
  country text default 'Guinée',
  phone text,
  email text,
  website text,
  contact_person_name text,
  contact_person_phone text,
  contact_person_email text,
  notes text,
  logo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text
);

-- Business KYC documents
create table public.business_kyc (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.business_companies(id) on delete cascade,
  document_type text not null check (document_type in ('license', 'registration', 'tax', 'insurance', 'quality_cert', 'other')),
  document_url text not null,
  document_name text not null,
  expiry_date date,
  status text default 'pending' check (status in ('pending', 'verified', 'rejected', 'expired')),
  verified_by uuid references public.profiles(id) on delete set null,
  verified_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Business contracts (agreements)
create table public.business_contracts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.business_companies(id) on delete cascade,
  contract_number text unique not null,
  title text not null,
  description text,
  type text not null check (type in ('supply', 'distribution', 'service', 'partnership', 'exclusivity')),
  start_date date not null,
  end_date date,
  status text default 'active' check (status in ('draft', 'active', 'expired', 'terminated', 'suspended')),
  terms text,
  signed_at timestamptz,
  signed_by uuid references public.profiles(id) on delete set null,
  contract_url text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Business contacts (people)
create table public.business_contacts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.business_companies(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  position text,
  department text,
  phone text,
  email text,
  is_primary boolean default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Business interactions / activities log
create table public.business_activities (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.business_companies(id) on delete cascade,
  contact_id uuid references public.business_contacts(id) on delete set null,
  type text not null check (type in ('call', 'email', 'meeting', 'visit', 'follow_up', 'proposal', 'negotiation', 'order', 'complaint')),
  subject text not null,
  description text,
  date timestamptz not null default now(),
  next_action_date timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Business pricing (preferential pricing by company)
create table public.business_pricing (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.business_companies(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  price integer not null, -- in minor unit (GNF)
  discount_percentage numeric default 0,
  effective_from date not null,
  effective_to date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(company_id, product_id)
);

-- Indexes
create index idx_business_companies_name on public.business_companies(name);
create index idx_business_companies_type on public.business_companies(type);
create index idx_business_companies_status on public.business_companies(status);
create index idx_business_companies_gsg_org_id on public.business_companies(gsg_org_id);
create index idx_business_kyc_company_id on public.business_kyc(company_id);
create index idx_business_kyc_status on public.business_kyc(status);
create index idx_business_contracts_company_id on public.business_contracts(company_id);
create index idx_business_contracts_status on public.business_contracts(status);
create index idx_business_contacts_company_id on public.business_contacts(company_id);
create index idx_business_activities_company_id on public.business_activities(company_id);
create index idx_business_pricing_company_id on public.business_pricing(company_id);
create index idx_business_pricing_product_id on public.business_pricing(product_id);

-- Triggers for updated_at
create trigger trigger_business_companies_updated_at
before update on public.business_companies
for each row execute function public.update_updated_at();

create trigger trigger_business_kyc_updated_at
before update on public.business_kyc
for each row execute function public.update_updated_at();

create trigger trigger_business_contracts_updated_at
before update on public.business_contracts
for each row execute function public.update_updated_at();

create trigger trigger_business_contacts_updated_at
before update on public.business_contacts
for each row execute function public.update_updated_at();

create trigger trigger_business_activities_updated_at
before update on public.business_activities
for each row execute function public.update_updated_at();

create trigger trigger_business_pricing_updated_at
before update on public.business_pricing
for each row execute function public.update_updated_at();

-- Function to generate contract number
create or replace function generate_contract_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(contract_number from '^CON-([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.business_contracts;
  new.contract_number := 'CON-' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_business_contracts_number
before insert on public.business_contracts
for each row execute function generate_contract_number();

-- RLS
alter table public.business_companies enable row level security;
alter table public.business_kyc enable row level security;
alter table public.business_contracts enable row level security;
alter table public.business_contacts enable row level security;
alter table public.business_activities enable row level security;
alter table public.business_pricing enable row level security;

-- Everyone can view active companies (public info)
create policy "Everyone view active business companies" on public.business_companies
  for select using (status = 'active');

-- Staff manage all business data
create policy "Staff manage business companies" on public.business_companies
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Staff manage KYC
create policy "Staff manage business KYC" on public.business_kyc
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Staff manage contracts
create policy "Staff manage business contracts" on public.business_contracts
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Staff manage contacts
create policy "Staff manage business contacts" on public.business_contacts
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Staff manage activities
create policy "Staff manage business activities" on public.business_activities
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Staff manage pricing
create policy "Staff manage business pricing" on public.business_pricing
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Seed sample business types (via migration only, no data insert)
