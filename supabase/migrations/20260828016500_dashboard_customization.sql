-- Dashboard customization for analytics

-- User dashboards
create table public.user_dashboards (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  layout jsonb default '{"panels": []}'::jsonb,
  is_default boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Available dashboard widgets (catalog)
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défauts
-- supplémentaires découverts lors de la vérification C82-C87, corrigés
-- dans le même mouvement : `name` sans contrainte unique alors que le seed
-- plus bas utilise `on conflict (name)` (`unique` ajoutée) ; échappement
-- non standard `\'` dans le seed (corrigé en `''`). Confirmé bloquant par
-- exécution réelle.
create table public.dashboard_widgets (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  type text not null, -- 'kpi', 'chart', 'table', 'list', 'calendar'
  config_schema jsonb,
  icon text,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_user_dashboards_patient_id on public.user_dashboards(patient_id);
create index idx_dashboard_widgets_type on public.dashboard_widgets(type);

-- RLS
alter table public.user_dashboards enable row level security;
alter table public.dashboard_widgets enable row level security;

-- Patients manage own dashboards
create policy "Patients manage own dashboards" on public.user_dashboards
  for all using (auth.uid() = patient_id);

-- Staff view all dashboards
create policy "Staff view user dashboards" on public.user_dashboards
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Everyone view available widgets
create policy "Everyone view dashboard widgets" on public.dashboard_widgets
  for select using (is_active = true);

-- Staff manage dashboard widgets
create policy "Staff manage dashboard widgets" on public.dashboard_widgets
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Seed default widgets
insert into public.dashboard_widgets (id, name, description, type, icon, is_active)
values
  (gen_random_uuid(), 'KPI Consultations', 'Nombre de consultations', 'kpi', '📊', true),
  (gen_random_uuid(), 'KPI Prescriptions', 'Nombre de prescriptions', 'kpi', '💊', true),
  (gen_random_uuid(), 'KPI CA', 'Chiffre d''affaires', 'kpi', '💰', true),
  (gen_random_uuid(), 'Graphique activité', 'Activité quotidienne', 'chart', '📈', true),
  (gen_random_uuid(), 'Top produits', 'Produits les plus vendus', 'list', '📋', true),
  (gen_random_uuid(), 'Top pharmacies', 'Pharmacies les plus actives', 'list', '🏥', true),
  (gen_random_uuid(), 'Alertes récentes', 'Alertes de stock et rappels', 'list', '🔔', true),
  (gen_random_uuid(), 'Calendrier', 'Rendez-vous à venir', 'calendar', '📅', true)
on conflict (name) do nothing;
