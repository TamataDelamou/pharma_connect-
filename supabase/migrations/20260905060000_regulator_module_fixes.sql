-- Audit Module 27 (REG), Étape 2 (05/09/2026)
-- Correctifs SQL/RLS du Module 27 — Régulateur & Reporting Pharmacovigilance.
--
-- REG-1 : les policies "Regulator staff manage X" des 4 tables du module
-- (adverse_reactions, product_recalls, regulatory_inspections,
-- marketing_authorizations) testaient `profiles.role in ('admin',
-- 'regulator')` — aucune des deux valeurs n'est autorisée par la contrainte
-- CHECK de `public.profiles.role` (seules 'patient', 'pharmacien',
-- 'grossiste', 'livreur', 'professionnel', 'regulateur' sont valides), et
-- 'admin' n'a jamais été un rôle métier dans ce projet (motif "rôle
-- inatteignable", même famille que CHN-5, PRE-1, HOM-1, etc.). Remplacé par
-- `public.is_gsg_admin()` (gestion de cas, staff GSG) et un nouveau helper
-- `public.is_regulator()` (rôle métier 'regulateur', accès superviseur).
--
-- REG-5 : RG-REG-02 (Critique) exige qu'aucune donnée nominative de patient
-- ne soit transmise au régulateur sans base légale explicite. La table brute
-- `adverse_reactions` contient patient_id/reporter_id et des jointures vers
-- les noms complets. Un compte 'regulateur' ne doit donc jamais lire cette
-- table directement : création d'une vue `adverse_reactions_anonymized`,
-- appartenant au rôle propriétaire des migrations (contourne RLS pour sa
-- propre requête interne, motif "vue security-definer" déjà utilisé dans le
-- projet), qui expose uniquement des colonnes agrégées/non-nominatives et
-- est accessible en lecture aux comptes 'regulateur' ET aux admins GSG.

begin;

-- ---------------------------------------------------------------------
-- 1. Helper is_regulator() : rôle métier 'regulateur' (table profiles),
--    à ne jamais utiliser pour du contrôle d'accès autre que la lecture
--    de données déjà agrégées/anonymisées (RG-REG-02).
-- ---------------------------------------------------------------------
create or replace function public.is_regulator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'regulateur'
  );
$$;

comment on function public.is_regulator() is
  'Audit Module 27 (REG), Étape 2 (05/09/2026) : vrai si le compte connecté '
  'a le rôle métier ''regulateur''. Ne donne accès qu''à des données déjà '
  'agrégées ou anonymisées (RG-REG-02) — jamais aux tables nominatives brutes.';

-- ---------------------------------------------------------------------
-- 2. adverse_reactions : REG-1. Gestion de cas (prise en charge, statut,
--    suppression) réservée au staff GSG (is_gsg_admin()) — pas au
--    régulateur, qui ne doit voir que la vue anonymisée (REG-5).
-- ---------------------------------------------------------------------
drop policy if exists "Regulator staff manage reports" on public.adverse_reactions;

create policy "GSG admin manage reports" on public.adverse_reactions
  for all
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ---------------------------------------------------------------------
-- 3. product_recalls : REG-1. RLS corrigée pour cohérence, mais aucune
--    UI n'est reconstruite sur cette table dans le cadre du Module 27
--    (cf. rapport d'audit REG, note de périmètre : table dupliquée avec
--    `recalls`/module recall, à traiter au Module 30/RCL — D46).
-- ---------------------------------------------------------------------
drop policy if exists "Regulator staff manage recalls" on public.product_recalls;

create policy "GSG admin or regulator manage recalls" on public.product_recalls
  for all
  using (public.is_gsg_admin() or public.is_regulator())
  with check (public.is_gsg_admin() or public.is_regulator());

-- ---------------------------------------------------------------------
-- 4. regulatory_inspections : REG-1 + REG-4 (table orpheline désormais
--    raccordée à une UI en Étape 3).
-- ---------------------------------------------------------------------
drop policy if exists "Regulator staff manage inspections" on public.regulatory_inspections;

create policy "GSG admin or regulator manage inspections" on public.regulatory_inspections
  for all
  using (public.is_gsg_admin() or public.is_regulator())
  with check (public.is_gsg_admin() or public.is_regulator());

-- ---------------------------------------------------------------------
-- 5. marketing_authorizations : REG-1 + REG-4 (table orpheline désormais
--    raccordée à une UI en Étape 3). La policy publique de lecture des
--    AMM approuvées ("Public view approved authorizations") est
--    inchangée.
-- ---------------------------------------------------------------------
drop policy if exists "Regulator staff manage authorizations" on public.marketing_authorizations;

create policy "GSG admin or regulator manage authorizations" on public.marketing_authorizations
  for all
  using (public.is_gsg_admin() or public.is_regulator())
  with check (public.is_gsg_admin() or public.is_regulator());

-- ---------------------------------------------------------------------
-- 6. Vue anonymisée (REG-5 / RG-REG-02) : aucune colonne nominative
--    (patient_id, reporter_id, noms joints, notes libres pouvant
--    contenir des éléments nominatifs) — uniquement des données
--    agrégeables utiles à un superviseur (médicament, sévérité, statut,
--    dates, région si disponible via le produit).
-- ---------------------------------------------------------------------
create or replace view public.adverse_reactions_anonymized as
select
  ar.id,
  ar.medication_id,
  p.generic_name as medication_generic_name,
  ar.severity,
  ar.status,
  ar.reaction_date,
  ar.outcome,
  ar.reporter_type,
  ar.created_at
from public.adverse_reactions ar
left join public.products p on p.id = ar.medication_id
-- Garde d'accès au niveau de la vue elle-même : la vue est propriété du
-- rôle des migrations et contourne donc de fait le RLS de
-- adverse_reactions/products pour sa propre requête interne (motif "vue
-- security-definer"). Sans cette clause WHERE, le GRANT ci-dessous
-- ouvrirait la vue à N'IMPORTE QUEL compte authentifié (patient, livreur,
-- etc.) via PostgREST — un filtrage uniquement côté application (masquer
-- le bouton dans l'UI) ne serait pas une garantie de sécurité réelle. La
-- clause référence les mêmes helpers SECURITY DEFINER que les policies
-- ci-dessus : seuls le staff GSG et les comptes régulateur obtiennent des
-- lignes.
where public.is_gsg_admin() or public.is_regulator();

comment on view public.adverse_reactions_anonymized is
  'Audit Module 27 (REG), Étape 2 (05/09/2026) : vue anonymisée de '
  'adverse_reactions pour RG-REG-02 — aucune colonne nominative de patient '
  'ou de déclarant. Accès restreint au niveau de la vue elle-même via une '
  'clause WHERE is_gsg_admin()/is_regulator() (voir commentaire ci-dessus) ; '
  'le GRANT authenticated ne suffirait pas seul à protéger ces lignes.';

-- Supabase ne propage pas automatiquement les grants sur les nouveaux
-- objets : accès explicite requis pour le rôle applicatif authenticated.
-- Le filtrage réel des lignes est assuré par la clause WHERE de la vue
-- (ci-dessus), pas par ce GRANT — qui ne fait qu'autoriser la requête à
-- s'exécuter.
grant select on public.adverse_reactions_anonymized to authenticated;

commit;
