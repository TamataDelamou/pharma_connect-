-- Correctif C211 : les droits fondes sur un role exigent un role VERIFIE.
--
-- Suite de 20260930010000_verified_roles_and_locked_columns.sql (decision
-- D58). Pour chaque objet de categorie (a) de l'inventaire
-- docs/audit/C211_inventaire_roles.md (droit ouvert sur un role declare, non
-- verifie), la condition de role est remplacee par
-- public.has_verified_role(...). Meme nom, meme commande, meme portee (TO),
-- reste de la condition inchange : rien d'autre n'est elargi ni restreint.
--
-- Policies recreees (20) :
--   batch_movements : batch_movements_select_staff, batch_movements_write_staff
--   certificates : certificates_select_staff
--   cold_chain_records : cold_chain_records_select_staff
--   health_goals : « Staff view health goals »
--   health_milestones : « Staff view milestones »
--   health_record_summaries : « Staff generate summaries », « Staff view summaries »
--   health_records : « Professionals can view all records »
--   products : products_select_scoped (role <> 'patient' devient les cinq
--     roles non patients, verifies)
--   recall_affected_batches : recall_affected_batches_write_staff
--   recalls : recalls_write_staff
--   traceable_batches : traceable_batches_write_staff
--   triage_ai_analyses : « Staff manage triage AI analyses »
--   triage_assessments : « Nurses can manage assessments »
--   triage_patients : « Nurses can view all / insert / update / delete triage patients »
--   verification_scans : verification_scans_select_own_or_staff
--
-- Fonctions recreees (meme signature, memes droits d'execution) :
--   is_pharmacist() : pharmacien rattache a une officine
--     (policies prescriptions_staff_*, prescription_items_staff_*) ;
--   is_regulator() : regulateur valide par GSG (policies « GSG admin or
--     regulator manage ... » de product_recalls, regulatory_inspections,
--     marketing_authorizations).
--
-- Non modifies : notifications_history « Staff view notifications »
-- (categorie b, roles admin/staff hors contrainte, condition toujours
-- fausse) ; is_pharmacy_staff(), is_any_pharmacy_staff(),
-- is_verified_professional_account() (categorie c, securises par le
-- verrouillage de pharmacy_id et de is_verified).
--
-- Aucune migration existante modifiee.

-- ==================== Fonctions ====================

create or replace function public.is_pharmacist()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_verified_role(array['pharmacien']);
$$;

comment on function public.is_pharmacist() is
  'C211 / D58 : pharmacien vérifié (rattaché à une officine validée). Auparavant : rôle déclaré seul.';

create or replace function public.is_regulator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_verified_role(array['regulateur']);
$$;

comment on function public.is_regulator() is
  'C211 / D58 : régulateur validé par l''administration GSG. Auparavant : rôle déclaré seul.';

-- ==================== Policies ====================

-- batch_movements.batch_movements_select_staff (SELECT)
drop policy if exists batch_movements_select_staff on public.batch_movements;
create policy batch_movements_select_staff on public.batch_movements
  as permissive
  for SELECT
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- batch_movements.batch_movements_write_staff (ALL)
drop policy if exists batch_movements_write_staff on public.batch_movements;
create policy batch_movements_write_staff on public.batch_movements
  as permissive
  for ALL
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])))
  with check ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- certificates.certificates_select_staff (SELECT)
drop policy if exists certificates_select_staff on public.certificates;
create policy certificates_select_staff on public.certificates
  as permissive
  for SELECT
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- cold_chain_records.cold_chain_records_select_staff (SELECT)
drop policy if exists cold_chain_records_select_staff on public.cold_chain_records;
create policy cold_chain_records_select_staff on public.cold_chain_records
  as permissive
  for SELECT
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- health_goals.Staff view health goals (SELECT)
drop policy if exists "Staff view health goals" on public.health_goals;
create policy "Staff view health goals" on public.health_goals
  as permissive
  for SELECT
  to public
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['professionnel'::text])));

-- health_milestones.Staff view milestones (SELECT)
drop policy if exists "Staff view milestones" on public.health_milestones;
create policy "Staff view milestones" on public.health_milestones
  as permissive
  for SELECT
  to public
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['professionnel'::text])));

-- health_record_summaries.Staff generate summaries (INSERT)
drop policy if exists "Staff generate summaries" on public.health_record_summaries;
create policy "Staff generate summaries" on public.health_record_summaries
  as permissive
  for INSERT
  to public
  with check ((public.has_verified_role(ARRAY['professionnel'::text]) OR (EXISTS ( SELECT 1 FROM admin_users WHERE ((admin_users.user_id = auth.uid()) AND (admin_users.is_active = true))))));

-- health_record_summaries.Staff view summaries (SELECT)
drop policy if exists "Staff view summaries" on public.health_record_summaries;
create policy "Staff view summaries" on public.health_record_summaries
  as permissive
  for SELECT
  to public
  using ((public.has_verified_role(ARRAY['professionnel'::text]) OR (EXISTS ( SELECT 1 FROM admin_users WHERE ((admin_users.user_id = auth.uid()) AND (admin_users.is_active = true))))));

-- health_records.Professionals can view all records (SELECT)
drop policy if exists "Professionals can view all records" on public.health_records;
create policy "Professionals can view all records" on public.health_records
  as permissive
  for SELECT
  to public
  using (public.has_verified_role(ARRAY['pharmacien'::text, 'professionnel'::text]));

-- products.products_select_scoped (SELECT)
drop policy if exists products_select_scoped on public.products;
create policy products_select_scoped on public.products
  as permissive
  for SELECT
  to authenticated
  using (((regulatory_class <> ALL (ARRAY['stupefiant'::text, 'psychotrope'::text])) OR is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'livreur'::text, 'professionnel'::text, 'regulateur'::text])));

-- recall_affected_batches.recall_affected_batches_write_staff (ALL)
drop policy if exists recall_affected_batches_write_staff on public.recall_affected_batches;
create policy recall_affected_batches_write_staff on public.recall_affected_batches
  as permissive
  for ALL
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])))
  with check ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- recalls.recalls_write_staff (ALL)
drop policy if exists recalls_write_staff on public.recalls;
create policy recalls_write_staff on public.recalls
  as permissive
  for ALL
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])))
  with check ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- traceable_batches.traceable_batches_write_staff (ALL)
drop policy if exists traceable_batches_write_staff on public.traceable_batches;
create policy traceable_batches_write_staff on public.traceable_batches
  as permissive
  for ALL
  to authenticated
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])))
  with check ((is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

-- triage_ai_analyses.Staff manage triage AI analyses (ALL)
drop policy if exists "Staff manage triage AI analyses" on public.triage_ai_analyses;
create policy "Staff manage triage AI analyses" on public.triage_ai_analyses
  as permissive
  for ALL
  to public
  using ((is_gsg_admin() OR public.has_verified_role(ARRAY['professionnel'::text])));

-- triage_assessments.Nurses can manage assessments (ALL)
drop policy if exists "Nurses can manage assessments" on public.triage_assessments;
create policy "Nurses can manage assessments" on public.triage_assessments
  as permissive
  for ALL
  to public
  using (public.has_verified_role(ARRAY['professionnel'::text]));

-- triage_patients.Nurses can delete triage patients (DELETE)
drop policy if exists "Nurses can delete triage patients" on public.triage_patients;
create policy "Nurses can delete triage patients" on public.triage_patients
  as permissive
  for DELETE
  to public
  using (public.has_verified_role(ARRAY['professionnel'::text]));

-- triage_patients.Nurses can insert triage patients (INSERT)
drop policy if exists "Nurses can insert triage patients" on public.triage_patients;
create policy "Nurses can insert triage patients" on public.triage_patients
  as permissive
  for INSERT
  to public
  with check (public.has_verified_role(ARRAY['professionnel'::text]));

-- triage_patients.Nurses can update triage patients (UPDATE)
drop policy if exists "Nurses can update triage patients" on public.triage_patients;
create policy "Nurses can update triage patients" on public.triage_patients
  as permissive
  for UPDATE
  to public
  using (public.has_verified_role(ARRAY['professionnel'::text]));

-- triage_patients.Nurses can view all triage patients (SELECT)
drop policy if exists "Nurses can view all triage patients" on public.triage_patients;
create policy "Nurses can view all triage patients" on public.triage_patients
  as permissive
  for SELECT
  to public
  using (public.has_verified_role(ARRAY['professionnel'::text]));

-- verification_scans.verification_scans_select_own_or_staff (SELECT)
drop policy if exists verification_scans_select_own_or_staff on public.verification_scans;
create policy verification_scans_select_own_or_staff on public.verification_scans
  as permissive
  for SELECT
  to authenticated
  using (((auth.uid() = verified_by) OR is_gsg_admin() OR public.has_verified_role(ARRAY['pharmacien'::text, 'grossiste'::text, 'regulateur'::text])));

