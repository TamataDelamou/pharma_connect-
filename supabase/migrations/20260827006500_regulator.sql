-- Regulator module: pharmaceutical regulation and pharmacovigilance

-- Adverse drug reactions / side effects reports
create table public.adverse_reactions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reporter_type text not null check (reporter_type in ('patient', 'pharmacist', 'doctor', 'nurse', 'other')),
  medication_id uuid references public.products(id) on delete set null,
  medication_name text not null,
  reaction_date timestamptz not null,
  reported_at timestamptz not null default now(),
  symptoms text not null,
  severity text not null check (severity in ('mild', 'moderate', 'severe', 'life_threatening')),
  outcome text check (outcome in ('recovered', 'recovering', 'ongoing', 'permanent_damage', 'death')),
  treatment_required boolean default false,
  hospitalization_required boolean default false,
  notes text,
  status text not null check (status in ('pending', 'under_review', 'investigating', 'closed', 'rejected')),
  follow_up_notes text,
  regulatory_action text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Product recalls (from pharmaceutical market)
create table public.product_recalls (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  batch_number text not null,
  manufacturer text not null,
  reason text not null,
  recall_type text not null check (recall_type in ('voluntary', 'mandatory', 'customer')),
  severity text not null check (severity in ('class_i', 'class_ii', 'class_iii')),
  status text not null check (status in ('draft', 'published', 'in_progress', 'completed', 'cancelled')),
  announcement_date timestamptz not null default now(),
  completion_date timestamptz,
  distributed_quantity integer,
  recalled_quantity integer,
  destruction_date timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Regulatory inspections
create table public.regulatory_inspections (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('pharmacy', 'hospital', 'laboratory', 'manufacturer', 'wholesaler')),
  entity_id uuid not null,
  inspector_id uuid references public.profiles(id) on delete set null,
  inspection_date timestamptz not null,
  type text not null check (type in ('routine', 'complaint', 'follow_up', 'emergency')),
  status text not null check (status in ('scheduled', 'in_progress', 'completed', 'cancelled')),
  findings text,
  violations text[],
  recommendations text,
  action_taken text,
  follow_up_date timestamptz,
  report_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Marketing authorizations (for pharmaceuticals)
create table public.marketing_authorizations (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  manufacturer text not null,
  authorization_number text not null,
  issuing_body text not null,
  status text not null check (status in ('pending', 'approved', 'suspended', 'revoked', 'expired')),
  approved_at timestamptz,
  expiry_date timestamptz,
  indications text,
  contraindications text,
  side_effects text,
  dosage_instructions text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_adverse_reactions_patient_id on public.adverse_reactions(patient_id);
create index idx_adverse_reactions_medication_id on public.adverse_reactions(medication_id);
create index idx_adverse_reactions_status on public.adverse_reactions(status);
create index idx_adverse_reactions_severity on public.adverse_reactions(severity);
create index idx_product_recalls_product_id on public.product_recalls(product_id);
create index idx_product_recalls_batch_number on public.product_recalls(batch_number);
create index idx_product_recalls_status on public.product_recalls(status);
create index idx_regulatory_inspections_entity_id on public.regulatory_inspections(entity_id);
create index idx_regulatory_inspections_inspector_id on public.regulatory_inspections(inspector_id);
create index idx_regulatory_inspections_status on public.regulatory_inspections(status);
create index idx_marketing_authorizations_product_id on public.marketing_authorizations(product_id);
create index idx_marketing_authorizations_status on public.marketing_authorizations(status);

-- Triggers for updated_at
create trigger trigger_adverse_reactions_updated_at
before update on public.adverse_reactions
for each row execute function public.update_updated_at();

create trigger trigger_product_recalls_updated_at
before update on public.product_recalls
for each row execute function public.update_updated_at();

create trigger trigger_regulatory_inspections_updated_at
before update on public.regulatory_inspections
for each row execute function public.update_updated_at();

create trigger trigger_marketing_authorizations_updated_at
before update on public.marketing_authorizations
for each row execute function public.update_updated_at();

-- RLS
alter table public.adverse_reactions enable row level security;
alter table public.product_recalls enable row level security;
alter table public.regulatory_inspections enable row level security;
alter table public.marketing_authorizations enable row level security;

-- Anyone can report adverse reactions (patients, professionals)
create policy "Anyone can report adverse reactions" on public.adverse_reactions
  for insert with check (true);

-- Patients can view their own reports
create policy "Patients view own reports" on public.adverse_reactions
  for select using (auth.uid() = patient_id);

-- Professionals can view reports they submitted
create policy "Professionals view own reports" on public.adverse_reactions
  for select using (auth.uid() = reporter_id);

-- Regulator staff can view all (admin role)
create policy "Regulator staff manage reports" on public.adverse_reactions
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'regulator')
    )
  );

-- Product recalls: public can view published ones
create policy "Public view published recalls" on public.product_recalls
  for select using (status = 'published');

-- Admin/regulator manage recalls
create policy "Regulator staff manage recalls" on public.product_recalls
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'regulator')
    )
  );

-- Inspections: regulator staff manage
create policy "Regulator staff manage inspections" on public.regulatory_inspections
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'regulator')
    )
  );

-- Marketing authorizations: public view approved ones
create policy "Public view approved authorizations" on public.marketing_authorizations
  for select using (status = 'approved');

-- Regulator staff manage authorizations
create policy "Regulator staff manage authorizations" on public.marketing_authorizations
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'regulator')
    )
  );
