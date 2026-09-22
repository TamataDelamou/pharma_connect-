-- Module recall (pharmacovigilance) : correctifs RLS, découverts lors de la
-- clôture du Module 12 (TRC) — le porteur du projet a demandé l'unification
-- du rappel déclaré depuis traceability (flag is_recalled) avec ce module,
-- déjà construit (workflow riche : sévérité Classe I/II/III, statut de
-- rappel, statut par lot affecté, numéro de référence, action corrective,
-- diffusion publique) mais jamais audité (hors-cahier, comme pos/sales/
-- cash/business/returns, voir registre D3) et jamais actionnable en
-- pratique : AUCUNE policy INSERT/UPDATE n'existait sur `recalls` ni sur
-- `recall_affected_batches`, seulement `for select to authenticated using
-- (true)` — 12ème occurrence confirmée du motif « migration de base
-- incomplète en écriture » (après C39/traceability et les occurrences
-- antérieures).
--
-- La policy SELECT elle-même était trop large dans l'autre sens : un rappel
-- non public (is_public = false, ex. un rappel interne déclenché par un
-- pharmacien avant confirmation régulateur) était lisible par N'IMPORTE
-- QUEL compte authentifié, patient compris — alors que `is_public` existe
-- précisément pour distinguer un avis de rappel public (que le cahier
-- attend visible de tous, un patient devant pouvoir vérifier son propre
-- lot) d'un dossier encore interne. Corrigé : `is_public = true` reste
-- ouvert à tous ; le reste est réservé au staff de la chaîne
-- d'approvisionnement et à l'admin GSG, sur le même modèle que
-- `traceable_batches_write_staff` (migration 20260829023000).

-- ---- Écriture (staff chaîne d'approvisionnement ou admin GSG) ----
create policy "recalls_write_staff" on public.recalls
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

create policy "recall_affected_batches_write_staff" on public.recall_affected_batches
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

-- ---- Lecture publique restreinte aux rappels effectivement publics ----
-- (additive vis-à-vis de recalls_write_staff ci-dessus : le staff/l'admin
-- voient tout via son `using`, combiné en OR avec la policy ci-dessous pour
-- le SELECT — c'est le même mécanisme que traceable_batches côté écriture.)
drop policy if exists "recalls_select_authenticated" on public.recalls;
create policy "recalls_select_public" on public.recalls
  for select to authenticated
  using (is_public = true);

drop policy if exists "recall_affected_batches_select_authenticated" on public.recall_affected_batches;
create policy "recall_affected_batches_select_public" on public.recall_affected_batches
  for select to authenticated
  using (
    exists (
      select 1 from public.recalls r
      where r.id = recall_id and r.is_public = true
    )
  );
