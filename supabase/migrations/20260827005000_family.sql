-- Family module: manage family members and shared health information

-- Family links between patients and their family members
create table public.family_links (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  family_member_id uuid not null references public.profiles(id) on delete cascade,
  relationship text not null, -- 'parent', 'child', 'spouse', 'sibling', 'cousin', 'friend', 'other'
  can_view_records boolean default true,
  can_view_prescriptions boolean default true,
  can_book_consultations boolean default false,
  can_receive_alerts boolean default true,
  status text not null check (status in ('pending', 'active', 'revoked')),
  invited_at timestamptz not null default now(),
  activated_at timestamptz,
  revoked_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(patient_id, family_member_id)
);

-- Family alerts (shared notifications)
create table public.family_alerts (
  id uuid primary key default gen_random_uuid(),
  family_link_id uuid not null references public.family_links(id) on delete cascade,
  type text not null check (type in ('health_record', 'prescription', 'consultation', 'medication_refill', 'general')),
  title text not null,
  message text not null,
  is_read boolean default false,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Family activity log (audit trail)
create table public.family_activity_log (
  id uuid primary key default gen_random_uuid(),
  family_link_id uuid not null references public.family_links(id) on delete cascade,
  action text not null, -- 'viewed_record', 'viewed_prescription', 'booked_consultation', 'received_alert'
  details jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_family_links_patient_id on public.family_links(patient_id);
create index idx_family_links_family_member_id on public.family_links(family_member_id);
create index idx_family_links_status on public.family_links(status);
create index idx_family_alerts_family_link_id on public.family_alerts(family_link_id);
create index idx_family_alerts_is_read on public.family_alerts(is_read);
create index idx_family_activity_log_family_link_id on public.family_activity_log(family_link_id);

-- Triggers for updated_at
create trigger trigger_family_links_updated_at
before update on public.family_links
for each row execute function public.update_updated_at();

create trigger trigger_family_alerts_updated_at
before update on public.family_alerts
for each row execute function public.update_updated_at();

-- RLS
alter table public.family_links enable row level security;
alter table public.family_alerts enable row level security;
alter table public.family_activity_log enable row level security;

-- Patients can view and manage their own family links
create policy "Patients can manage own family links" on public.family_links
  for all using (auth.uid() = patient_id);

-- Family members can view links where they are the family member
create policy "Family members can view links" on public.family_links
  for select using (auth.uid() = family_member_id);

-- Family members can update their status (accept/revoke)
create policy "Family members can update status" on public.family_links
  for update using (auth.uid() = family_member_id)
  with check (status in ('active', 'revoked'));

-- Family members can view alerts for active links
create policy "Family members can view alerts" on public.family_alerts
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and family_member_id = auth.uid()
      and status = 'active'
    )
  );

-- Family members can mark alerts as read
create policy "Family members can update alerts" on public.family_alerts
  for update using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and family_member_id = auth.uid()
      and status = 'active'
    )
  )
  with check (true);

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-1 : `family_alerts` et
-- `family_activity_log` n'avaient chacune QUE des policies de lecture
-- (et de mise à jour pour les alertes) — aucune policy `insert`/`delete`
-- n'existait, alors que `FamilyService.createAlert()`/`.deleteAlert()`/
-- `.logActivity()` sont des écritures réelles côté client. Motif déjà
-- rencontré ≥11 fois dans cet audit (« migration incomplète en écriture »,
-- C35/C37/C41/TRC). L'échec de `logActivity()` était de surcroît avalé en
-- silence côté Dart (`catch (e) { // Log silently }`) — le journal
-- d'activité n'était donc jamais alimenté, sans qu'aucune erreur ne soit
-- jamais visible. Corrigé : le patient (source de l'événement partagé)
-- peut créer/supprimer une alerte sur un lien actif ; toute partie liée
-- (patient ou proche) peut journaliser une action sur un lien qui la
-- concerne.
create policy "Patients can create alerts" on public.family_alerts
  for insert with check (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and patient_id = auth.uid()
      and status = 'active'
    )
  );

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-1 (complément découvert
-- par le harnais de test réel) : `family_alerts` n'avait, AVANT ce
-- correctif, AUCUNE policy `select` pour le PATIENT (seul le proche
-- pouvait lire les alertes) — le patient ne pouvait donc même pas voir les
-- alertes générées sur son propre compte. Vérifié par exécution réelle que
-- cette absence bloquait aussi silencieusement la policy `delete`
-- (`DELETE 0`, aucune ligne affectée) ajoutée ci-dessus, alors que son
-- propre USING clause était pourtant satisfaite en isolation — la
-- visibilité de la ligne pour la commande dépend de l'ensemble des
-- policies applicables au rôle, pas seulement de la policy de la commande
-- en cours.
create policy "Patients can view alerts" on public.family_alerts
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and patient_id = auth.uid()
    )
  );

create policy "Patients can delete alerts" on public.family_alerts
  for delete using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and patient_id = auth.uid()
    )
  );

-- Family members can view activity log (lecture, motif déjà en place)
create policy "Family members can view activity log" on public.family_activity_log
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and family_member_id = auth.uid()
    )
  );

-- Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-1 (complément) : les
-- `action` journalisées (`viewed_record`, `viewed_prescription`,
-- `booked_consultation`, `received_alert`) décrivent ce que le PROCHE a
-- fait avec l'accès accordé — le journal existe donc, par nature, pour la
-- transparence envers le PATIENT (propriétaire de la donnée partagée), pas
-- pour le proche lui-même. Or seule une policy de lecture pour le proche
-- existait ; le patient, qui a le besoin de supervision le plus direct
-- (RG-FAM-01), n'avait aucun moyen de consulter ce journal. Corrigé.
create policy "Patients can view activity log" on public.family_activity_log
  for select using (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and patient_id = auth.uid()
    )
  );

-- FAM-1 (voir commentaire ci-dessus) : policy d'écriture manquante sur le
-- journal d'activité lui-même.
create policy "Linked parties can log activity" on public.family_activity_log
  for insert with check (
    exists (
      select 1 from public.family_links
      where id = family_link_id
      and (patient_id = auth.uid() or family_member_id = auth.uid())
    )
  );
