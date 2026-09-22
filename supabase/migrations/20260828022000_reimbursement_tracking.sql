-- Reimbursement tracking
create table public.reimbursement_tracking (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null references public.insurance_claims(id) on delete cascade,
  status text not null check (status in ('submitted', 'under_review', 'approved', 'reimbursed', 'rejected')),
  submitted_amount integer,
  approved_amount integer,
  reimbursed_amount integer,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reimbursed_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_reimbursement_tracking_claim_id on public.reimbursement_tracking(claim_id);
create index idx_reimbursement_tracking_status on public.reimbursement_tracking(status);

-- RLS
alter table public.reimbursement_tracking enable row level security;

-- Patients view own reimbursement tracking
create policy "Patients view own reimbursements" on public.reimbursement_tracking
  for select using (
    exists (
      select 1 from public.insurance_claims
      where id = claim_id and patient_id = auth.uid()
    )
  );

-- Staff manage reimbursements
create policy "Staff manage reimbursements" on public.reimbursement_tracking
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );
