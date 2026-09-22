-- AI triage analyses
create table triage_ai_analyses (
  id uuid primary key default gen_random_uuid(),
  triage_patient_id uuid not null references public.triage_patients(id) on delete cascade,
  symptoms text not null,
  priority_score int not null check (priority_score between 1 and 5),
  suggested_department text,
  is_critical boolean default false,
  analysis_details jsonb default '{}'::jsonb,
  actual_priority int, -- feedback from doctor
  actual_department text, -- feedback from doctor
  doctor_feedback text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Triage rules (configurable business rules)
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C87 :
-- `keyword` ne portait aucune contrainte unique/exclusion, alors que le
-- seed plus bas utilise `on conflict (keyword) do nothing` — `on conflict`
-- sans cible valide est une erreur Postgres bloquante (« there is no
-- unique or exclusion constraint matching the ON CONFLICT specification »),
-- confirmée par exécution réelle contre un Postgres 16 local. `unique`
-- ajoutée ici, sur la colonne, dans la migration d'origine de ce module
-- (Module 11/IA, déjà clôturé) plutôt que dans une migration corrective
-- séparée — la contrainte doit exister AVANT le seed du même fichier.
create table triage_rules (
  id uuid primary key default gen_random_uuid(),
  keyword text not null unique,
  priority_score int not null check (priority_score between 1 and 5),
  department text,
  is_critical boolean default false,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table triage_ai_analyses enable row level security;
alter table triage_rules enable row level security;

-- Patients view their own analyses
create policy "Patients view own triage AI analyses" on triage_ai_analyses
  for select using (
    exists (
      select 1 from public.triage_patients
      where id = triage_patient_id and patient_id = auth.uid()
    )
  );

-- Staff view all and manage
create policy "Staff manage triage AI analyses" on triage_ai_analyses
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'professionnel')
    )
  );

-- Rules: staff manage, everyone view
create policy "Everyone view triage rules" on triage_rules
  for select using (true);

create policy "Staff manage triage rules" on triage_rules
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Seed default triage rules
insert into triage_rules (keyword, priority_score, department, is_critical)
values
  ('thoracique', 1, 'Cardiologie', true),
  ('cardiaque', 1, 'Cardiologie', true),
  ('respiratoire', 1, 'Urgences', true),
  ('suffoc', 1, 'Urgences', true),
  ('hemorragie', 1, 'Traumatologie', true),
  ('saignement', 1, 'Traumatologie', true),
  ('perte de connaissance', 1, 'Urgences', true),
  ('trouble neurologique', 2, 'Neurologie', false),
  ('douleur abdominale', 2, 'Chirurgie', false),
  ('fievre', 2, 'Médecine interne', false),
  ('vomissement', 2, 'Médecine interne', false),
  ('diarrhée', 3, 'Médecine interne', false),
  ('douleur', 3, 'Généraliste', false),
  ('infection', 3, 'Médecine interne', false),
  ('toux', 4, 'Pneumologie', false),
  ('fatigue', 4, 'Généraliste', false),
  ('grippe', 4, 'Généraliste', false),
  ('dermatologique', 4, 'Dermatologie', false),
  ('blessure', 5, 'Traumatologie', false)
on conflict (keyword) do nothing;
