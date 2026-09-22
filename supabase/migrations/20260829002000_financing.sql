-- Financing module: supplier financing

-- Financing requests
create table financing_requests (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  b2b_order_id uuid references public.b2b_orders(id) on delete set null,
  amount integer not null,
  purpose text,
  repayment_period_months integer default 3,
  interest_rate numeric default 5.0,
  status text default 'pending' check (status in ('pending', 'approved', 'rejected', 'active', 'completed', 'defaulted')),
  approved_at timestamptz,
  disbursed_at timestamptz,
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Financing repayments
create table financing_repayments (
  id uuid primary key default gen_random_uuid(),
  financing_request_id uuid not null references public.financing_requests(id) on delete cascade,
  due_date date not null,
  amount integer not null,
  status text default 'pending' check (status in ('pending', 'paid', 'overdue', 'defaulted')),
  paid_at timestamptz,
  transaction_id uuid references public.transactions(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Credit scores
create table credit_scores (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  score integer not null check (score between 0 and 1000),
  rating text not null check (rating in ('excellent', 'good', 'fair', 'poor', 'bad')),
  last_updated timestamptz not null default now(),
  factors jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(pharmacy_id)
);

-- Indexes
create index idx_financing_requests_pharmacy_id on public.financing_requests(pharmacy_id);
create index idx_financing_requests_status on public.financing_requests(status);
create index idx_financing_repayments_request_id on public.financing_repayments(financing_request_id);
create index idx_financing_repayments_status on public.financing_repayments(status);
create index idx_financing_repayments_due_date on public.financing_repayments(due_date);
create index idx_credit_scores_pharmacy_id on public.credit_scores(pharmacy_id);

-- Triggers for updated_at
create trigger trigger_financing_requests_updated_at
before update on public.financing_requests
for each row execute function public.update_updated_at();

create trigger trigger_financing_repayments_updated_at
before update on public.financing_repayments
for each row execute function public.update_updated_at();

create trigger trigger_credit_scores_updated_at
before update on public.credit_scores
for each row execute function public.update_updated_at();

-- RLS
alter table public.financing_requests enable row level security;
alter table public.financing_repayments enable row level security;
alter table public.credit_scores enable row level security;

-- Pharmacy own requests
create policy "Pharmacy own financing" on public.financing_requests
  for all using (auth.uid() = pharmacy_id);

-- Staff manage all requests
create policy "Staff manage financing requests" on public.financing_requests
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Repayments: pharmacy view own, staff manage
create policy "Pharmacy view own repayments" on public.financing_repayments
  for select using (
    exists (
      select 1 from public.financing_requests
      where id = financing_request_id and pharmacy_id = auth.uid()
    )
  );

create policy "Staff manage repayments" on public.financing_repayments
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Credit scores: pharmacy view own, staff manage
create policy "Pharmacy view own credit score" on public.credit_scores
  for select using (pharmacy_id = auth.uid());

create policy "Staff manage credit scores" on public.credit_scores
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );
