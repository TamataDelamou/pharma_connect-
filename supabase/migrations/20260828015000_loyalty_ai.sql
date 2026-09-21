-- AI Health Challenges
create table health_challenges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  type text not null check (type in ('daily', 'weekly', 'monthly')),
  difficulty text default 'easy' check (difficulty in ('easy', 'medium', 'hard')),
  points integer default 10,
  requirements jsonb default '{}'::jsonb,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Patient challenge progress
create table challenge_progress (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  challenge_id uuid not null references public.health_challenges(id) on delete cascade,
  progress integer default 0,
  target integer not null,
  completed boolean default false,
  completed_at timestamptz,
  streak integer default 0,
  last_activity_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, challenge_id)
);

-- Reward earnings from challenges
create table reward_earnings (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  challenge_id uuid references public.health_challenges(id) on delete set null,
  points_earned integer not null,
  reward_type text check (reward_type in ('points', 'badge', 'discount', 'free_item')),
  description text,
  earned_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Patient health actions (for recommendations)
create table health_actions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  action_type text not null, -- 'walk', 'water_intake', 'fruits', 'sleep', 'meditation', 'steps'
  value numeric,
  recorded_at date not null,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table health_challenges enable row level security;
alter table challenge_progress enable row level security;
alter table reward_earnings enable row level security;
alter table health_actions enable row level security;

-- Everyone view challenges (active)
create policy "Everyone view active challenges" on health_challenges
  for select using (is_active = true);

-- Staff manage challenges
create policy "Staff manage challenges" on health_challenges
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Patients manage own progress
create policy "Patients manage own challenge progress" on challenge_progress
  for all using (auth.uid() = patient_id);

-- Staff view all progress
create policy "Staff view all progress" on challenge_progress
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Patients view own reward earnings
create policy "Patients view own reward earnings" on reward_earnings
  for select using (auth.uid() = patient_id);

-- Staff view all earnings
create policy "Staff view all earnings" on reward_earnings
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Patients manage own health actions
create policy "Patients manage own health actions" on health_actions
  for all using (auth.uid() = patient_id);

-- Staff view health actions
create policy "Staff view health actions" on health_actions
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut C85
-- (mêmes occurrences supplémentaires) : `\'` corrigé en `''` (4
-- occurrences), confirmé bloquant par exécution réelle.
--
-- Seed default challenges
insert into health_challenges (name, description, type, difficulty, points, requirements)
values
  ('🚶 Marche quotidienne', 'Marchez 30 minutes aujourd''hui', 'daily', 'easy', 10, '{"target": 30, "unit": "minutes"}'),
  ('💧 Eau', 'Buvez 1,5 litres d''eau aujourd''hui', 'daily', 'easy', 10, '{"target": 1.5, "unit": "liters"}'),
  ('🍎 5 fruits/légumes', 'Mangez 5 portions de fruits ou légumes', 'daily', 'easy', 15, '{"target": 5, "unit": "portions"}'),
  ('🧘 Méditation', 'Pratiquez 10 minutes de méditation', 'daily', 'medium', 20, '{"target": 10, "unit": "minutes"}'),
  ('🏋️ Exercice modéré', '30 minutes d''activité modérée', 'daily', 'medium', 20, '{"target": 30, "unit": "minutes"}'),
  ('💪 7 jours d''activité', 'Bougez au moins 30 minutes par jour pendant 7 jours', 'weekly', 'hard', 100, '{"target": 7, "unit": "days"}');
