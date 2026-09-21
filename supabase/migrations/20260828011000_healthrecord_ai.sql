-- AI summaries for health records
create table health_record_summaries (
  id uuid primary key default gen_random_uuid(),
  health_record_id uuid not null references public.health_records(id) on delete cascade,
  summary text not null,
  structured_data jsonb default '{}'::jsonb,
  critical_points jsonb default '[]'::jsonb,
  generated_at timestamptz not null default now(),
  expires_at timestamptz, -- optional expiry for temporary summaries
  created_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table health_record_summaries enable row level security;

-- Patients can view their own summaries
create policy "Patients view own summaries" on health_record_summaries
  for select using (
    exists (
      select 1 from public.health_records
      where id = health_record_id and patient_id = auth.uid()
    )
  );

-- Audit Module 20 (DSN), ouverture (30/08/2026), C94 : motif « rôle
-- inatteignable » déjà rencontré à de nombreuses reprises dans l'audit
-- (C49/C54/C63/C67/C70b/C79...) — `profiles.role` n'admet jamais 'admin' ni
-- 'staff' (contrainte CHECK, voir 20260827000000_profiles.sql), seules les
-- branches 'professionnel' de ces policies étaient donc jamais mortes.
-- Non bloquant pour `supabase db push` (pas une erreur de type/syntaxe,
-- juste une condition OR partiellement inatteignable), mais laisse un accès
-- administrateur réel inatteignable : remplacé par `public.is_gsg_admin()`
-- normalement, mais ce fichier (28/08, 11h00) est ANTÉRIEUR à la définition
-- de cette fonction (20260829003800_admin_helpers.sql) — même piège de
-- non-antériorité que C90 (offline_sync.sql) — donc vérification inlined
-- sur `admin_users`, comme pour ce même correctif ailleurs dans le projet.
--
-- Staff view all summaries (for consultation)
create policy "Staff view summaries" on health_record_summaries
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

-- Staff can generate summaries
create policy "Staff generate summaries" on health_record_summaries
  for insert with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
    or exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );
