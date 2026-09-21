-- Module 24 (ASR) — corrective migration, Étape 3
--
-- ASR-1 : motif « rôle inatteignable » — les 5 policies "Staff manage ..." de
-- insurance.sql (20260827007000, datée 27/08) et reimbursement_tracking.sql
-- (20260828022000, datée 28/08) testent role in ('admin','staff'), une valeur
-- que la contrainte CHECK de profiles.role n'autorise jamais. Les deux fichiers
-- d'origine sont ANTÉRIEURS à public.is_gsg_admin() (20260829003800, 29/08) :
-- les corriger en place casserait le rejeu chronologique de la chaîne de
-- migrations (même piège que HOP-1/Module 23, C90, C79) — corrigées ici par
-- une migration corrective postérieure, suivant le modèle de référence établi
-- à la clôture du Module 23 (20260830048000_hospitals_module_fixes.sql).
--
-- ASR-2 : insurance_companies et insurance_plans n'ont jamais eu de policy
-- d'écriture (insert/update/delete) pour aucun rôle — pas seulement un rôle
-- inatteignable, une absence totale. RG-ASR-01 exige que les règles de prise
-- en charge soient « paramétrées en back-office » ; sans policy d'écriture,
-- ce paramétrage est aujourd'hui impossible pour quiconque, y compris un
-- administrateur légitime. Corrigé ici par l'ajout de policies is_gsg_admin().

-- ASR-1 : remplacement des 5 policies "Staff manage ..." par is_gsg_admin()

drop policy if exists "Staff manage enrollments" on public.insurance_enrollments;
create policy "Staff manage enrollments" on public.insurance_enrollments
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage pre-auths" on public.pre_authorizations;
create policy "Staff manage pre-auths" on public.pre_authorizations
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage claims" on public.insurance_claims;
create policy "Staff manage claims" on public.insurance_claims
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage provider agreements" on public.provider_agreements;
create policy "Staff manage provider agreements" on public.provider_agreements
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage reimbursements" on public.reimbursement_tracking;
create policy "Staff manage reimbursements" on public.reimbursement_tracking
  for all using (public.is_gsg_admin());

-- ASR-2 : policies d'écriture manquantes sur insurance_companies / insurance_plans
-- (paramétrage back-office des assureurs/plans/barèmes de couverture)

create policy "Admins manage insurance companies" on public.insurance_companies
  for all using (public.is_gsg_admin());

create policy "Admins manage insurance plans" on public.insurance_plans
  for all using (public.is_gsg_admin());
