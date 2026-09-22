-- Module 12 (TRC — Traçabilité & Lutte contre les médicaments contrefaits) :
-- correctifs RLS + nouvelle table counterfeit_reports (RG-TRC-02).
--
-- Audit Module 12 (29/08/2026).
--
-- 1) `traceable_batches`/`batch_movements` n'avaient AUCUNE policy
--    INSERT/UPDATE (seulement SELECT `using (true)`) — 11ème occurrence
--    confirmée du motif « migration de base incomplète en écriture » (après
--    C37/forecasting, C35/alerts et les occurrences antérieures). Cela
--    bloquait silencieusement les deux seules écritures déjà codées
--    (`recallBatch`, `updateBatchStatus`) et bloquerait toute future
--    écriture de mouvement.
--
-- 2) `batch_movements`/`cold_chain_records`/`certificates`/`verification_scans`
--    avaient une policy SELECT `using (true)` — tout compte authentifié, y
--    compris `patient`, pouvait lire l'intégralité des mouvements internes
--    (utilisateur, numéro de suivi, notes), les relevés chaîne du froid, les
--    certificats, et surtout l'historique de scan de VERIFICATION de
--    N'IMPORTE QUEL AUTRE UTILISATEUR — même motif que C1 (Module 2/4,
--    stock_movements) déjà corrigé en restreignant au staff. `traceable_batches`
--    reste volontairement ouvert : c'est la table que le parcours patient
--    « Vérifier un produit » doit pouvoir lire pour confirmer l'authenticité.

-- ---- Écriture sur traceable_batches / batch_movements ----
-- Scopé aux rôles de la chaîne d'approvisionnement (pharmacien, grossiste,
-- régulateur) ou à l'admin GSG — un patient ne doit jamais pouvoir modifier
-- un lot ou insérer un mouvement. `traceable_batches` n'étant pas rattachée
-- à une officine précise (un lot traverse plusieurs officines/grossistes au
-- fil de sa vie), le scope ne peut pas être `is_pharmacy_staff` comme pour
-- les autres modules — d'où un test sur `profiles.role` directement, sur le
-- modèle déjà documenté par is_gsg_admin() pour les valeurs CHECK valides.
create policy "traceable_batches_write_staff" on public.traceable_batches
  for all to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  )
  with check (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

create policy "batch_movements_write_staff" on public.batch_movements
  for all to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  )
  with check (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

-- ---- Restriction des lectures internes (remplace `using (true)`) ----
drop policy if exists "batch_movements_select_authenticated" on public.batch_movements;
create policy "batch_movements_select_staff" on public.batch_movements
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

drop policy if exists "cold_chain_records_select_authenticated" on public.cold_chain_records;
create policy "cold_chain_records_select_staff" on public.cold_chain_records
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

drop policy if exists "certificates_select_authenticated" on public.certificates;
create policy "certificates_select_staff" on public.certificates
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

-- verification_scans : chacun lit ses propres scans (un patient qui vérifie
-- un produit doit revoir son propre résultat) ; le staff/l'admin lisent tout
-- (pharmacovigilance, RG-TRC-02).
drop policy if exists "verification_scans_select_authenticated" on public.verification_scans;
create policy "verification_scans_select_own_or_staff" on public.verification_scans
  for select to authenticated
  using (
    auth.uid() = verified_by
    or public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('pharmacien', 'grossiste', 'regulateur')
    )
  );

-- ---- RG-TRC-02 : signalement produit suspect ----
create table if not exists public.counterfeit_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users(id),
  batch_id uuid references public.traceable_batches(id),
  serial_number text,
  pharmacy_id uuid references public.pharmacies(id),
  description text not null,
  aspect_suspect boolean not null default false,
  packaging_suspect boolean not null default false,
  unexpected_effect boolean not null default false,
  status text not null default 'open' check (status in (
    'open', 'investigating', 'confirmed', 'dismissed'
  )),
  alert_id uuid references public.alerts(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.counterfeit_reports is
  'Signalements patient/pharmacien de produit suspect (RG-TRC-02) — traceability/models/counterfeit_report.dart. Ouvre automatiquement une alerte type ''counterfeit'' vers l''officine concernée et l''admin GSG.';

create index if not exists idx_counterfeit_reports_batch_id on public.counterfeit_reports(batch_id);
create index if not exists idx_counterfeit_reports_pharmacy_id on public.counterfeit_reports(pharmacy_id);

create trigger set_updated_at
  before update on public.counterfeit_reports
  for each row execute function public.set_updated_at();

alter table public.counterfeit_reports enable row level security;

create policy "counterfeit_reports_insert_own" on public.counterfeit_reports
  for insert to authenticated
  with check (auth.uid() = reporter_id);

create policy "counterfeit_reports_select_own" on public.counterfeit_reports
  for select to authenticated
  using (auth.uid() = reporter_id);

create policy "counterfeit_reports_select_staff" on public.counterfeit_reports
  for select to authenticated
  using (
    public.is_gsg_admin()
    or (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  );

create policy "counterfeit_reports_update_staff" on public.counterfeit_reports
  for update to authenticated
  using (
    public.is_gsg_admin()
    or (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  )
  with check (
    public.is_gsg_admin()
    or (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  );

-- ---- Visibilité admin sur les alertes (nécessaire pour RG-TRC-02 : « alerte
-- l'officine concernée AINSI QUE l'administrateur GSG ») ----
-- Audit Module 10 (`alerts`) n'avait ajouté que des policies staff-d'officine
-- (`is_pharmacy_staff`) ; aucune policy ne permettait à l'admin GSG de lire
-- les alertes des officines. Additif, ne retire rien.
create policy "alerts_admin_select_all" on public.alerts
  for select to authenticated
  using (public.is_gsg_admin());
