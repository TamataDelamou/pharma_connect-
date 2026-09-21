-- Cash module: cash drawer management and cash movements

-- Cash drawer sessions
create table public.cash_drawer_sessions (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  cashier_id uuid not null references public.profiles(id) on delete cascade,
  opening_balance integer not null,
  closing_balance integer,
  expected_balance integer,
  difference integer,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  status text default 'open' check (status in ('open', 'closed', 'suspended')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Cash movements (in/out)
create table public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  cash_drawer_session_id uuid not null references public.cash_drawer_sessions(id) on delete cascade,
  type text not null check (type in ('sale', 'refund', 'deposit', 'withdrawal', 'adjustment', 'opening', 'closing')),
  amount integer not null,
  reference_id text,
  reference_type text,
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Cash summary view
create materialized view cash_summary as
select
  cds.pharmacy_id,
  cds.id as session_id,
  cds.opened_at,
  cds.closed_at,
  cds.opening_balance,
  cds.closing_balance,
  cds.expected_balance,
  cds.difference,
  coalesce(sum(cm.amount) filter (where cm.type = 'sale'), 0) as total_sales,
  coalesce(sum(cm.amount) filter (where cm.type = 'refund'), 0) as total_refunds,
  coalesce(sum(cm.amount) filter (where cm.type = 'deposit'), 0) as total_deposits,
  coalesce(sum(cm.amount) filter (where cm.type = 'withdrawal'), 0) as total_withdrawals
from cash_drawer_sessions cds
left join cash_movements cm on cm.cash_drawer_session_id = cds.id
group by cds.id, cds.pharmacy_id, cds.opened_at, cds.closed_at,
  cds.opening_balance, cds.closing_balance, cds.expected_balance, cds.difference;

-- Indexes
create index idx_cash_drawer_sessions_pharmacy_id on public.cash_drawer_sessions(pharmacy_id);
create index idx_cash_drawer_sessions_status on public.cash_drawer_sessions(status);
create index idx_cash_movements_session_id on public.cash_movements(cash_drawer_session_id);
create index idx_cash_movements_type on public.cash_movements(type);
create index idx_cash_movements_created_at on public.cash_movements(created_at);

-- Triggers for updated_at
create trigger trigger_cash_drawer_sessions_updated_at
before update on public.cash_drawer_sessions
for each row execute function public.update_updated_at();

-- RLS
alter table public.cash_drawer_sessions enable row level security;
alter table public.cash_movements enable row level security;

-- Pharmacy staff manage
-- (audit Module 0, 29/08/2026 : `public.pharmacy_staff` n'existe pas, voir
-- la même note dans 20260829006000_pos.sql — remplacé par is_pharmacy_staff().)
create policy "Pharmacy staff manage cash sessions" on public.cash_drawer_sessions
  for all using (public.is_pharmacy_staff(pharmacy_id));

create policy "Pharmacy staff manage cash movements" on public.cash_movements
  for all using (cash_drawer_session_id in (
    select id from public.cash_drawer_sessions
    where public.is_pharmacy_staff(pharmacy_id)
  ));

-- Network admins view all
create policy "Network admins view cash sessions" on public.cash_drawer_sessions
  for select using (exists (
    select 1 from public.network_admin_roles
    where user_id = auth.uid() and role in ('super_admin', 'network_admin')
  ));

-- Function to open cash drawer
create or replace function open_cash_drawer(
  p_pharmacy_id uuid,
  p_cashier_id uuid,
  p_opening_balance integer,
  p_notes text default null
)
returns uuid as $$
declare
  v_session_id uuid;
begin
  insert into public.cash_drawer_sessions (
    pharmacy_id,
    cashier_id,
    opening_balance,
    expected_balance,
    status,
    notes,
    created_by,
    updated_by
  ) values (
    p_pharmacy_id,
    p_cashier_id,
    p_opening_balance,
    p_opening_balance,
    'open',
    p_notes,
    auth.uid(),
    auth.uid()
  )
  returning id into v_session_id;

  insert into public.cash_movements (
    cash_drawer_session_id,
    type,
    amount,
    notes,
    created_by
  ) values (
    v_session_id,
    'opening',
    p_opening_balance,
    'Ouverture de caisse',
    auth.uid()
  );

  return v_session_id;
end;
$$ language plpgsql security definer;

-- Function to close cash drawer
create or replace function close_cash_drawer(
  p_session_id uuid,
  p_closing_balance integer,
  p_notes text default null
)
returns void as $$
declare
  v_expected_balance integer;
  v_difference integer;
begin
  select coalesce(sum(amount), 0) into v_expected_balance
  from public.cash_movements
  where cash_drawer_session_id = p_session_id;

  v_difference := p_closing_balance - v_expected_balance;

  update public.cash_drawer_sessions set
    closing_balance = p_closing_balance,
    expected_balance = v_expected_balance,
    difference = v_difference,
    status = 'closed',
    closed_at = now(),
    notes = coalesce(notes, '') || E'\n' || coalesce(p_notes, ''),
    updated_at = now(),
    updated_by = auth.uid()
  where id = p_session_id;

  insert into public.cash_movements (
    cash_drawer_session_id,
    type,
    amount,
    notes,
    created_by
  ) values (
    p_session_id,
    'closing',
    p_closing_balance,
    'Fermeture de caisse' || coalesce(' - ' || p_notes, ''),
    auth.uid()
  );
end;
$$ language plpgsql security definer;
