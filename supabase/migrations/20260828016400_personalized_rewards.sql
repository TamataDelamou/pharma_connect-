-- Personalized rewards for loyalty program

create table public.personalized_rewards (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  reward_type text not null check (reward_type in ('discount', 'bonus_points', 'free_item', 'premium_access')),
  title text not null,
  description text,
  points_cost integer,
  discount_percentage integer,
  is_active boolean default true,
  expires_at timestamptz,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_personalized_rewards_patient_id on public.personalized_rewards(patient_id);
create index idx_personalized_rewards_is_active on public.personalized_rewards(is_active);
create index idx_personalized_rewards_expires_at on public.personalized_rewards(expires_at);

-- RLS
alter table public.personalized_rewards enable row level security;

-- Patients view own rewards
create policy "Patients view own rewards" on public.personalized_rewards
  for select using (auth.uid() = patient_id);

-- Patients update own rewards (mark as used)
create policy "Patients update own rewards" on public.personalized_rewards
  for update using (auth.uid() = patient_id);

-- Staff manage rewards
create policy "Staff manage personalized rewards" on public.personalized_rewards
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );
