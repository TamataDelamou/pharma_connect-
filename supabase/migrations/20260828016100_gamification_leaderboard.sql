-- Leaderboard per pharmacy
create table public.loyalty_leaderboard (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid references public.pharmacies(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  period text not null check (period in ('daily', 'weekly', 'monthly', 'all_time')),
  points integer default 0,
  rank integer,
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(pharmacy_id, patient_id, period)
);

-- Indexes
create index idx_loyalty_leaderboard_pharmacy_id on public.loyalty_leaderboard(pharmacy_id);
create index idx_loyalty_leaderboard_period on public.loyalty_leaderboard(period);
create index idx_loyalty_leaderboard_points on public.loyalty_leaderboard(points desc);

-- RLS
alter table public.loyalty_leaderboard enable row level security;

-- Everyone can view leaderboard (for their pharmacy)
create policy "Everyone view leaderboard" on public.loyalty_leaderboard
  for select using (true);

-- Staff update leaderboard
create policy "Staff update leaderboard" on public.loyalty_leaderboard
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Function to update leaderboard
create or replace function update_loyalty_leaderboard()
returns trigger as $$
begin
  -- Update all-time
  insert into public.loyalty_leaderboard (pharmacy_id, patient_id, period, points, updated_at)
  values (
    (select pharmacy_id from public.loyalty_accounts where id = new.account_id),
    (select patient_id from public.loyalty_accounts where id = new.account_id),
    'all_time',
    (select points_balance from public.loyalty_accounts where id = new.account_id),
    now()
  )
  on conflict (pharmacy_id, patient_id, period) do update
  set points = (select points_balance from public.loyalty_accounts where id = new.account_id),
      updated_at = now();

  -- Update monthly
  insert into public.loyalty_leaderboard (pharmacy_id, patient_id, period, points, updated_at)
  values (
    (select pharmacy_id from public.loyalty_accounts where id = new.account_id),
    (select patient_id from public.loyalty_accounts where id = new.account_id),
    'monthly',
    (select points_balance from public.loyalty_accounts where id = new.account_id),
    now()
  )
  on conflict (pharmacy_id, patient_id, period) do update
  set points = (select points_balance from public.loyalty_accounts where id = new.account_id),
      updated_at = now();

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_loyalty_leaderboard
after insert on public.loyalty_transactions
for each row execute function update_loyalty_leaderboard();
