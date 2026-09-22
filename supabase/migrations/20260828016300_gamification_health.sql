-- Personal health goals
create table public.health_goals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  goal_type text not null, -- 'steps', 'water', 'fruits', 'meditation', 'sleep'
  target_value numeric not null,
  current_value numeric default 0,
  period text default 'daily' check (period in ('daily', 'weekly', 'monthly')),
  start_date date not null,
  end_date date,
  status text default 'active' check (status in ('active', 'completed', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Health milestones (for health record achievements)
create table public.health_milestones (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  milestone_type text not null, -- 'blood_pressure', 'weight', 'cholesterol', 'glucose', 'exercise'
  achievement text not null,
  achieved_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_health_goals_patient_id on public.health_goals(patient_id);
create index idx_health_goals_status on public.health_goals(status);
create index idx_health_milestones_patient_id on public.health_milestones(patient_id);

-- Triggers for updated_at
create trigger trigger_health_goals_updated_at
before update on public.health_goals
for each row execute function public.update_updated_at();

-- RLS
alter table public.health_goals enable row level security;
alter table public.health_milestones enable row level security;

-- Patients manage own goals
create policy "Patients manage own health goals" on public.health_goals
  for all using (auth.uid() = patient_id);

-- Audit Module 20 (DSN), ouverture (30/08/2026), C94 (voir le même
-- correctif et sa justification complète dans
-- 20260828011000_healthrecord_ai.sql, découvert dans le même mouvement) :
-- 'admin'/'staff' inatteignables sur profiles.role, branche remplacée par
-- une vérification inlined sur admin_users (fichier antérieur à
-- is_gsg_admin(), même piège de non-antériorité que C90).
--
-- Staff view patient goals
create policy "Staff view health goals" on public.health_goals
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
    or exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );

-- Patients view own milestones
create policy "Patients view own milestones" on public.health_milestones
  for select using (auth.uid() = patient_id);

-- Audit Module 20 (DSN), ouverture (30/08/2026), C94, même correctif que
-- ci-dessus.
--
-- Staff view milestones
create policy "Staff view milestones" on public.health_milestones
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
    or exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );

-- System can insert milestones (via triggers or API)
create policy "System insert milestones" on public.health_milestones
  for insert with check (auth.uid() = patient_id);
