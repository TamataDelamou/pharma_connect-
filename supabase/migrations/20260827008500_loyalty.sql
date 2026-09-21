-- Loyalty module: rewards and loyalty program

-- Loyalty programs (configurable by pharmacy)
create table public.loyalty_programs (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  name text not null,
  description text,
  points_per_purchase integer default 1, -- points per 1000 GNF spent
  points_per_referral integer default 50,
  min_points_to_redeem integer default 100,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Customer loyalty accounts
create table public.loyalty_accounts (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  program_id uuid not null references public.loyalty_programs(id) on delete cascade,
  points_balance integer default 0,
  total_points_earned integer default 0,
  total_points_redeemed integer default 0,
  tier text default 'bronze' check (tier in ('bronze', 'silver', 'gold', 'platinum')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, pharmacy_id)
);

-- Loyalty transactions (earn/spend points)
create table public.loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.loyalty_accounts(id) on delete cascade,
  transaction_type text not null check (transaction_type in ('earn', 'redeem', 'adjust', 'expire', 'referral')),
  amount integer not null, -- positive for earn, negative for redeem
  points_balance_after integer not null,
  reference_id text, -- linked to order, prescription, etc.
  description text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Reward catalog (items that can be redeemed with points)
create table public.loyalty_rewards (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  name text not null,
  description text,
  points_required integer not null,
  type text not null check (type in ('discount', 'product', 'service', 'gift')),
  value text, -- e.g., '10% off' or 'product_id'
  image_url text,
  is_active boolean default true,
  stock_quantity integer default 999,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Rewards redemptions
create table public.loyalty_redemptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.loyalty_accounts(id) on delete cascade,
  reward_id uuid not null references public.loyalty_rewards(id) on delete cascade,
  points_spent integer not null,
  redeemed_at timestamptz not null default now(),
  status text not null check (status in ('pending', 'approved', 'fulfilled', 'cancelled')),
  fulfilled_at timestamptz,
  notes text,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Referrals tracking
create table public.loyalty_referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_patient_id uuid not null references public.profiles(id) on delete cascade,
  referred_patient_id uuid not null references public.profiles(id) on delete cascade,
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  status text not null check (status in ('pending', 'completed', 'rewarded')),
  referral_code text,
  completed_at timestamptz,
  rewarded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(referrer_patient_id, referred_patient_id)
);

-- Indexes
create index idx_loyalty_accounts_patient_id on public.loyalty_accounts(patient_id);
create index idx_loyalty_accounts_pharmacy_id on public.loyalty_accounts(pharmacy_id);
create index idx_loyalty_accounts_tier on public.loyalty_accounts(tier);
create index idx_loyalty_transactions_account_id on public.loyalty_transactions(account_id);
create index idx_loyalty_rewards_pharmacy_id on public.loyalty_rewards(pharmacy_id);
create index idx_loyalty_redemptions_account_id on public.loyalty_redemptions(account_id);
create index idx_loyalty_referrals_referrer_id on public.loyalty_referrals(referrer_patient_id);
create index idx_loyalty_referrals_referred_id on public.loyalty_referrals(referred_patient_id);

-- Triggers for updated_at
create trigger trigger_loyalty_programs_updated_at
before update on public.loyalty_programs
for each row execute function public.update_updated_at();

create trigger trigger_loyalty_accounts_updated_at
before update on public.loyalty_accounts
for each row execute function public.update_updated_at();

create trigger trigger_loyalty_rewards_updated_at
before update on public.loyalty_rewards
for each row execute function public.update_updated_at();

-- Function to update account balance after transaction
create or replace function update_loyalty_account_balance()
returns trigger as $$
begin
  update public.loyalty_accounts
  set 
    points_balance = points_balance + new.amount,
    total_points_earned = case when new.amount > 0 then total_points_earned + new.amount else total_points_earned end,
    total_points_redeemed = case when new.amount < 0 then total_points_redeemed + abs(new.amount) else total_points_redeemed end,
    tier = case 
      when points_balance >= 1000 then 'platinum'
      when points_balance >= 500 then 'gold'
      when points_balance >= 200 then 'silver'
      else 'bronze'
    end,
    updated_at = now()
  where id = new.account_id;
  return new;
end;
$$ language plpgsql;

create trigger trigger_loyalty_transaction_update_balance
after insert on public.loyalty_transactions
for each row execute function update_loyalty_account_balance();

-- RLS
alter table public.loyalty_programs enable row level security;
alter table public.loyalty_accounts enable row level security;
alter table public.loyalty_transactions enable row level security;
alter table public.loyalty_rewards enable row level security;
alter table public.loyalty_redemptions enable row level security;
alter table public.loyalty_referrals enable row level security;

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C86 :
-- les 8 policies ci-dessous référençaient `public.pharmacy_staff`, une
-- table qui n'existe nulle part dans le projet — déjà identifiée comme
-- telle dès l'audit Module 0 (29/08/2026) et corrigée dans la quasi-
-- totalité des autres fichiers du projet via `public.is_pharmacy_staff()`,
-- SAUF dans ce fichier (Module 16/FID, déjà clôturé), resté sur la
-- référence brute d'origine. Sur une base neuve, ces `create policy`
-- auraient échoué avec `relation "pharmacy_staff" does not exist`,
-- confirmé bloquant par exécution réelle contre un Postgres 16 local. 5 des
-- 8 occurrences comportaient en outre une auto-comparaison tautologique
-- (`pharmacy_id = pharmacy_id`, toujours vraie, sans rapport avec
-- `auth.uid()`) qui aurait de toute façon rendu la policy inopérante comme
-- garde-fou si la table avait existé — corrigée en même temps.
--
-- Programs: pharmacy staff manage, everyone can view
create policy "Everyone view loyalty programs" on public.loyalty_programs
  for select using (true);

create policy "Staff manage loyalty programs" on public.loyalty_programs
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Accounts: patients view own, staff view pharmacy customers
create policy "Patients view own accounts" on public.loyalty_accounts
  for select using (auth.uid() = patient_id);

create policy "Staff view pharmacy accounts" on public.loyalty_accounts
  for select using (public.is_pharmacy_staff(pharmacy_id));

create policy "Staff manage accounts" on public.loyalty_accounts
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Transactions: patients view own, staff view pharmacy
create policy "Patients view own transactions" on public.loyalty_transactions
  for select using (
    exists (
      select 1 from public.loyalty_accounts
      where id = account_id and patient_id = auth.uid()
    )
  );

create policy "Staff view pharmacy transactions" on public.loyalty_transactions
  for select using (
    exists (
      select 1 from public.loyalty_accounts a
      where a.id = account_id and public.is_pharmacy_staff(a.pharmacy_id)
    )
  );

create policy "Staff insert transactions" on public.loyalty_transactions
  for insert with check (
    exists (
      select 1 from public.loyalty_accounts a
      where a.id = account_id and public.is_pharmacy_staff(a.pharmacy_id)
    )
  );

-- Rewards: everyone view, staff manage
create policy "Everyone view rewards" on public.loyalty_rewards
  for select using (true);

create policy "Staff manage rewards" on public.loyalty_rewards
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Redemptions: patients view own, staff manage
create policy "Patients view own redemptions" on public.loyalty_redemptions
  for select using (
    exists (
      select 1 from public.loyalty_accounts
      where id = account_id and patient_id = auth.uid()
    )
  );

create policy "Staff manage redemptions" on public.loyalty_redemptions
  for all using (
    exists (
      select 1 from public.loyalty_accounts a
      where a.id = account_id and public.is_pharmacy_staff(a.pharmacy_id)
    )
  );

create policy "Patients create redemptions" on public.loyalty_redemptions
  for insert with check (
    exists (
      select 1 from public.loyalty_accounts
      where id = account_id and patient_id = auth.uid()
    )
  );

-- Referrals: patients view own, staff view
create policy "Patients view own referrals" on public.loyalty_referrals
  for select using (auth.uid() = referrer_patient_id or auth.uid() = referred_patient_id);

create policy "Patients create referrals" on public.loyalty_referrals
  for insert with check (auth.uid() = referrer_patient_id);

create policy "Staff view referrals" on public.loyalty_referrals
  for select using (public.is_pharmacy_staff(pharmacy_id));
