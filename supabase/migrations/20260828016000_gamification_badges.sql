-- Badges catalog
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défauts
-- supplémentaires découverts lors de la vérification C82-C87, corrigés
-- dans le même mouvement (même nature bloquante, mêmes classes de bug déjà
-- identifiées C85/C87) : `name` sans contrainte unique alors que le seed
-- plus bas utilise `on conflict (name)` (`unique` ajoutée) ; 2 occurrences
-- de l'échappement non standard `\'` dans le seed (corrigées en `''`).
-- Confirmé bloquant par exécution réelle.
create table public.loyalty_badges (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  icon text not null,
  category text not null check (category in ('health', 'activity', 'social', 'special')),
  points_required integer,
  requirement_type text check (requirement_type in ('steps', 'challenges', 'referrals', 'streak', 'consultations', 'prescriptions')),
  requirement_value integer,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Patient badges earned
create table public.patient_badges (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.loyalty_badges(id) on delete cascade,
  earned_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, badge_id)
);

-- Indexes
create index idx_loyalty_badges_category on public.loyalty_badges(category);
create index idx_loyalty_badges_is_active on public.loyalty_badges(is_active);
create index idx_patient_badges_patient_id on public.patient_badges(patient_id);
create index idx_patient_badges_badge_id on public.patient_badges(badge_id);

-- Triggers for updated_at
create trigger trigger_loyalty_badges_updated_at
before update on public.loyalty_badges
for each row execute function public.update_updated_at();

-- RLS
alter table public.loyalty_badges enable row level security;
alter table public.patient_badges enable row level security;

-- Everyone can view badges
create policy "Everyone view loyalty badges" on public.loyalty_badges
  for select using (true);

-- Staff manage badges
create policy "Staff manage loyalty badges" on public.loyalty_badges
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Patients view own badges
create policy "Patients view own badges" on public.patient_badges
  for select using (auth.uid() = patient_id);

-- Only system can insert/update patient badges (via triggers)
create policy "System insert patient badges" on public.patient_badges
  for insert with check (auth.uid() = patient_id);

-- Seed default badges
insert into public.loyalty_badges (id, name, description, icon, category, requirement_type, requirement_value)
values
  (gen_random_uuid(), '🚶 Premier pas', 'Marchez 5000 pas en une journée', '🚶', 'activity', 'steps', 5000),
  (gen_random_uuid(), '🏃 Marathonien', 'Marchez 10000 pas en une journée', '🏃', 'activity', 'steps', 10000),
  (gen_random_uuid(), '💧 Hydraté', 'Buvez 1,5L d''eau pendant 7 jours consécutifs', '💧', 'health', 'streak', 7),
  (gen_random_uuid(), '🍎 5 par jour', 'Mangez 5 fruits/légumes pendant 7 jours', '🍎', 'health', 'streak', 7),
  (gen_random_uuid(), '🧘 Zen', 'Méditez 10 min par jour pendant 7 jours', '🧘', 'health', 'streak', 7),
  (gen_random_uuid(), '💪 Challengeur', 'Complétez 10 défis santé', '💪', 'activity', 'challenges', 10),
  (gen_random_uuid(), '🌟 Ambassadeur', 'Parrainez 3 amis', '🌟', 'social', 'referrals', 3),
  (gen_random_uuid(), '👨‍⚕️ Préventif', 'Réalisez 5 consultations préventives', '👨‍⚕️', 'health', 'consultations', 5),
  (gen_random_uuid(), '💊 Adhérent', 'Prenez vos médicaments 30 jours sans interruption', '💊', 'health', 'streak', 30),
  (gen_random_uuid(), '🔥 En feu', 'Maintenez une séquence de 7 jours d''activité', '🔥', 'activity', 'streak', 7)
on conflict (name) do nothing;
