-- SOS alerts
create table public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  family_member_id uuid not null references public.profiles(id) on delete cascade,
  alert_type text not null check (alert_type in ('medical_emergency', 'accident', 'panic', 'location_share')),
  message text,
  location_lat numeric(10, 8),
  location_lon numeric(11, 8),
  status text default 'active' check (status in ('active', 'acknowledged', 'resolved')),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- SOS alert acknowledgements
create table public.sos_acknowledgements (
  id uuid primary key default gen_random_uuid(),
  sos_alert_id uuid not null references public.sos_alerts(id) on delete cascade,
  family_member_id uuid not null references public.profiles(id) on delete cascade,
  acknowledged_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(sos_alert_id, family_member_id)
);

-- Indexes
create index idx_sos_alerts_patient_id on public.sos_alerts(patient_id);
create index idx_sos_alerts_family_member_id on public.sos_alerts(family_member_id);
create index idx_sos_alerts_status on public.sos_alerts(status);
create index idx_sos_acknowledgements_sos_alert_id on public.sos_acknowledgements(sos_alert_id);

-- RLS
alter table public.sos_alerts enable row level security;
alter table public.sos_acknowledgements enable row level security;

-- Patients view own alerts
create policy "Patients view own SOS alerts" on public.sos_alerts
  for select using (auth.uid() = patient_id);

-- Family members view alerts addressed to them
create policy "Family members view SOS alerts" on public.sos_alerts
  for select using (auth.uid() = family_member_id);

-- Patients create SOS alerts
create policy "Patients create SOS alerts" on public.sos_alerts
  for insert with check (auth.uid() = patient_id);

-- Patients update own alerts
create policy "Patients update own SOS alerts" on public.sos_alerts
  for update using (auth.uid() = patient_id);

-- Family members can acknowledge
create policy "Family members acknowledge SOS" on public.sos_acknowledgements
  for insert with check (auth.uid() = family_member_id);

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-2 : RLS activée sur
-- `sos_acknowledgements` mais SEULE une policy `insert` existait — un
-- accusé de réception s'enregistrait avec succès mais ne pouvait ensuite
-- être relu par personne (ni le patient concerné, ni le proche qui vient
-- de l'écrire) via l'application. Corrigé : le proche qui a acquitté peut
-- relire son propre accusé ; le patient dont l'alerte est concernée peut
-- voir qui a acquitté.
create policy "Family members view own acknowledgements" on public.sos_acknowledgements
  for select using (auth.uid() = family_member_id);

create policy "Patients view acknowledgements of their alerts" on public.sos_acknowledgements
  for select using (
    exists (
      select 1 from public.sos_alerts
      where id = sos_alert_id and patient_id = auth.uid()
    )
  );
