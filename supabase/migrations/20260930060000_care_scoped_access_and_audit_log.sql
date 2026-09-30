-- Correctifs C216 (accès trop larges aux données de santé) et C217 (journal
-- d'audit), décision D61 (30/09/2026).
--
-- C216 — constat (inventaire C211) : tout professionnel ou pharmacien
-- vérifié lisait tous les dossiers de santé ; tout pharmacien rattaché lisait
-- et modifiait toutes les ordonnances déposées, quelle que soit l'officine ;
-- tout professionnel vérifié voyait, modifiait et supprimait tous les
-- patients de triage ; les livreurs voyaient les stupéfiants et psychotropes.
--
-- Décision D61 :
--   1. Dossiers de santé (health_records, synthèses, objectifs, étapes) :
--      accès par LIEN DE SOIN. Un professionnel vérifié accède au dossier
--      d'un patient avec qui il a une consultation ou un soin à domicile non
--      annulés. Ces rendez-vous sont créés par le patient lui-même
--      (policies INSERT existantes) : le lien ne peut pas être fabriqué par le
--      professionnel. Les interactions professionnel-patient
--      (professional_patient_interactions) ne sont PAS retenues : le
--      professionnel peut en créer seul pour n'importe quel patient. Pour la
--      même raison, patient_id et professional_id d'une consultation ou d'un
--      soin à domicile deviennent non modifiables hors administration GSG.
--      Les pharmaciens n'ont plus accès aux dossiers de santé.
--   2. Ordonnances déposées (prescriptions, prescription_items) : le patient
--      choisit l'OFFICINE DESTINATAIRE (nouvelle colonne pharmacy_id) ; seul
--      le personnel de cette officine la voit et la traite. Les ordonnances
--      sans officine ne sont visibles que du patient.
--   3. Triage : rattaché à un HÔPITAL (nouvelle colonne hospital_id, remplie
--      par défaut avec l'hôpital d'affiliation de l'infirmier qui enregistre).
--      Accès : professionnels vérifiés affiliés (hospital_affiliations
--      active) à cet hôpital, plus l'infirmier de triage et le médecin
--      assigné.
--   4. Stupéfiants et psychotropes : les livreurs ne les voient plus.
--
-- C217 — constat : audit_logs était lisible par tout utilisateur connecté,
-- et sans policy d'insertion, AdminService.logAction() échouait toujours.
-- Correctif : lecture réservée à l'administration GSG ; journalisation par
-- la RPC admin_log_action() (auteur fixé par le serveur).
--
-- Aucune migration existante modifiée.

-- ============================================================
-- 1. Dossiers de santé : lien de soin
-- ============================================================

create or replace function public.has_care_relationship(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_verified_role(array['professionnel'])
    and (
      exists (select 1 from public.consultations c
               where c.professional_id = auth.uid()
                 and c.patient_id = p_patient_id
                 and c.status <> 'cancelled')
      or exists (select 1 from public.homecare_interventions h
                  where h.professional_id = auth.uid()
                    and h.patient_id = p_patient_id
                    and h.status <> 'cancelled')
    );
$$;

comment on function public.has_care_relationship(uuid) is
  'C216 / D61 : vrai si l''utilisateur courant est un professionnel vérifié ayant, avec ce patient, une consultation ou un soin à domicile non annulés (rendez-vous créés par le patient). Les interactions professional_patient_interactions ne comptent pas (créables par le professionnel seul).';

revoke all on function public.has_care_relationship(uuid) from public, anon;
grant execute on function public.has_care_relationship(uuid) to authenticated;

drop policy if exists "Professionals can view all records" on public.health_records;
create policy "Care team can view records" on public.health_records
  for select to authenticated
  using (public.has_care_relationship(patient_id));

drop policy if exists "Staff view summaries" on public.health_record_summaries;
create policy "Staff view summaries" on public.health_record_summaries
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (select 1 from public.health_records hr
                where hr.id = health_record_id
                  and public.has_care_relationship(hr.patient_id))
  );

drop policy if exists "Staff generate summaries" on public.health_record_summaries;
create policy "Staff generate summaries" on public.health_record_summaries
  for insert to authenticated
  with check (
    public.is_gsg_admin()
    or exists (select 1 from public.health_records hr
                where hr.id = health_record_id
                  and public.has_care_relationship(hr.patient_id))
  );

drop policy if exists "Staff view health goals" on public.health_goals;
create policy "Staff view health goals" on public.health_goals
  for select to authenticated
  using (public.is_gsg_admin() or public.has_care_relationship(patient_id));

drop policy if exists "Staff view milestones" on public.health_milestones;
create policy "Staff view milestones" on public.health_milestones
  for select to authenticated
  using (public.is_gsg_admin() or public.has_care_relationship(patient_id));

-- Le lien de soin ne doit pas pouvoir être fabriqué : patient et
-- professionnel d'un rendez-vous ne changent plus hors administration GSG.
create or replace function public.protect_care_link_parties()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('authenticated', 'anon') or public.is_gsg_admin() then
    return new;
  end if;
  if new.patient_id is distinct from old.patient_id
     or new.professional_id is distinct from old.professional_id then
    raise exception 'SOIN: patient et professionnel d''un rendez-vous ne sont pas modifiables'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

comment on function public.protect_care_link_parties() is
  'C216 / D61 : empêche un utilisateur de changer le patient ou le professionnel d''une consultation ou d''un soin à domicile (le lien de soin ouvre l''accès au dossier de santé).';

create trigger trigger_protect_consultation_parties
  before update on public.consultations
  for each row execute function public.protect_care_link_parties();
create trigger trigger_protect_homecare_parties
  before update on public.homecare_interventions
  for each row execute function public.protect_care_link_parties();

-- ============================================================
-- 2. Ordonnances déposées : officine destinataire
-- ============================================================

alter table public.prescriptions
  add column pharmacy_id uuid references public.pharmacies(id) on delete set null;
create index if not exists idx_prescriptions_pharmacy_id on public.prescriptions(pharmacy_id);

comment on column public.prescriptions.pharmacy_id is
  'C216 / D61 : officine destinataire choisie par le patient au dépôt. Seul le personnel de cette officine voit et traite l''ordonnance ; sans officine, seul le patient la voit.';

drop policy if exists prescriptions_insert_own on public.prescriptions;
create policy prescriptions_insert_own on public.prescriptions
  for insert to authenticated
  with check (
    auth.uid() = patient_id
    and (pharmacy_id is null
         or exists (select 1 from public.pharmacies ph
                     where ph.id = pharmacy_id and ph.status in ('verified', 'active')))
  );

drop policy if exists prescriptions_staff_select on public.prescriptions;
create policy prescriptions_staff_select on public.prescriptions
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists prescriptions_staff_update on public.prescriptions;
create policy prescriptions_staff_update on public.prescriptions
  for update to authenticated
  using (public.is_pharmacy_staff(pharmacy_id))
  with check (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists prescription_items_staff_select on public.prescription_items;
create policy prescription_items_staff_select on public.prescription_items
  for select to authenticated
  using (exists (select 1 from public.prescriptions p
                  where p.id = prescription_id
                    and public.is_pharmacy_staff(p.pharmacy_id)));

drop policy if exists prescription_items_staff_update on public.prescription_items;
create policy prescription_items_staff_update on public.prescription_items
  for update to authenticated
  using (exists (select 1 from public.prescriptions p
                  where p.id = prescription_id
                    and public.is_pharmacy_staff(p.pharmacy_id)))
  with check (exists (select 1 from public.prescriptions p
                       where p.id = prescription_id
                         and public.is_pharmacy_staff(p.pharmacy_id)));

-- ============================================================
-- 3. Triage : hôpital d'affiliation
-- ============================================================

alter table public.triage_patients
  add column hospital_id uuid references public.hospitals(id) on delete set null;
create index if not exists idx_triage_patients_hospital_id on public.triage_patients(hospital_id);

comment on column public.triage_patients.hospital_id is
  'C216 / D61 : hôpital du triage. Rempli par défaut avec l''hôpital d''affiliation (active, principale d''abord) de l''infirmier qui enregistre.';

-- Vrai si l'utilisateur courant est un professionnel vérifié avec une
-- affiliation active à cet hôpital.
create or replace function public.is_hospital_professional(p_hospital_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_hospital_id is not null
    and public.has_verified_role(array['professionnel'])
    and exists (
      select 1 from public.hospital_affiliations a
      where a.professional_id = auth.uid()
        and a.hospital_id = p_hospital_id
        and a.is_active
        and (a.end_date is null or a.end_date >= current_date)
    );
$$;

comment on function public.is_hospital_professional(uuid) is
  'C216 / D61 : professionnel vérifié avec une affiliation active (non terminée) à l''hôpital.';

revoke all on function public.is_hospital_professional(uuid) from public, anon;
grant execute on function public.is_hospital_professional(uuid) to authenticated;

-- Accès à un dossier de triage : infirmier de triage, médecin assigné ou
-- professionnel affilié à l'hôpital du triage.
create or replace function public.can_access_triage(p_triage_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_verified_role(array['professionnel'])
    and exists (
      select 1 from public.triage_patients t
      where t.id = p_triage_patient_id
        and (t.triage_nurse_id = auth.uid()
             or t.assigned_doctor_id = auth.uid()
             or public.is_hospital_professional(t.hospital_id))
    );
$$;

comment on function public.can_access_triage(uuid) is
  'C216 / D61 : vrai si l''utilisateur courant est un professionnel vérifié qui est l''infirmier de triage, le médecin assigné, ou affilié à l''hôpital de ce triage.';

revoke all on function public.can_access_triage(uuid) from public, anon;
grant execute on function public.can_access_triage(uuid) to authenticated;

-- Hôpital par défaut : affiliation active de l'infirmier (principale d'abord).
create or replace function public.set_triage_default_hospital()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.hospital_id is null then
    select a.hospital_id into new.hospital_id
      from public.hospital_affiliations a
      where a.professional_id = coalesce(new.triage_nurse_id, auth.uid())
        and a.is_active
        and (a.end_date is null or a.end_date >= current_date)
      order by a.primary_affiliation desc nulls last, a.start_date desc nulls last
      limit 1;
  end if;
  return new;
end;
$$;

create trigger trigger_set_triage_default_hospital
  before insert on public.triage_patients
  for each row execute function public.set_triage_default_hospital();

drop policy if exists "Nurses can view all triage patients" on public.triage_patients;
create policy "Care team can view triage patients" on public.triage_patients
  for select to authenticated
  using (
    public.has_verified_role(array['professionnel'])
    and (triage_nurse_id = auth.uid()
         or assigned_doctor_id = auth.uid()
         or public.is_hospital_professional(hospital_id))
  );

drop policy if exists "Nurses can insert triage patients" on public.triage_patients;
create policy "Nurses can insert triage patients" on public.triage_patients
  for insert to authenticated
  with check (
    public.has_verified_role(array['professionnel'])
    and triage_nurse_id = auth.uid()
    and (hospital_id is null or public.is_hospital_professional(hospital_id))
  );

drop policy if exists "Nurses can update triage patients" on public.triage_patients;
create policy "Care team can update triage patients" on public.triage_patients
  for update to authenticated
  using (
    public.has_verified_role(array['professionnel'])
    and (triage_nurse_id = auth.uid()
         or assigned_doctor_id = auth.uid()
         or public.is_hospital_professional(hospital_id))
  )
  with check (
    public.has_verified_role(array['professionnel'])
    and (hospital_id is null or public.is_hospital_professional(hospital_id)
         or triage_nurse_id = auth.uid())
  );

drop policy if exists "Nurses can delete triage patients" on public.triage_patients;
create policy "Care team can delete triage patients" on public.triage_patients
  for delete to authenticated
  using (
    public.has_verified_role(array['professionnel'])
    and (triage_nurse_id = auth.uid()
         or assigned_doctor_id = auth.uid()
         or public.is_hospital_professional(hospital_id))
  );

drop policy if exists "Nurses can manage assessments" on public.triage_assessments;
create policy "Care team can manage assessments" on public.triage_assessments
  for all to authenticated
  using (public.can_access_triage(triage_patient_id))
  with check (public.can_access_triage(triage_patient_id));

drop policy if exists "Staff manage triage AI analyses" on public.triage_ai_analyses;
create policy "Staff manage triage AI analyses" on public.triage_ai_analyses
  for all to authenticated
  using (public.is_gsg_admin() or public.can_access_triage(triage_patient_id))
  with check (public.is_gsg_admin() or public.can_access_triage(triage_patient_id));

-- ============================================================
-- 4. Stupéfiants et psychotropes : plus visibles des livreurs
-- ============================================================

drop policy if exists products_select_scoped on public.products;
create policy products_select_scoped on public.products
  for select to authenticated
  using (
    regulatory_class not in ('stupefiant', 'psychotrope')
    or public.is_gsg_admin()
    or public.has_verified_role(array['pharmacien', 'grossiste', 'professionnel', 'regulateur'])
  );

-- ============================================================
-- 5. C217 : journal d'audit
-- ============================================================

drop policy if exists audit_logs_select_authenticated on public.audit_logs;
create policy audit_logs_select_gsg_admin on public.audit_logs
  for select to authenticated
  using (public.is_gsg_admin());

create or replace function public.admin_log_action(
  p_action text,
  p_resource text,
  p_resource_id text,
  p_changes jsonb default null,
  p_is_success boolean default true,
  p_error_message text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;
  if nullif(btrim(p_action), '') is null or nullif(btrim(p_resource), '') is null then
    raise exception 'PROFIL: action et ressource obligatoires' using errcode = '22023';
  end if;
  insert into public.audit_logs (
    user_id, user_name, action, resource, resource_id, changes,
    user_agent, is_success, error_message
  ) values (
    auth.uid(),
    coalesce(
      (select au.full_name from public.admin_users au
        where au.user_id = auth.uid() and au.is_active limit 1),
      'Administrateur GSG'
    ),
    p_action, p_resource, coalesce(p_resource_id, ''), p_changes,
    'Application (admin_log_action)', coalesce(p_is_success, true), p_error_message
  );
end;
$$;

comment on function public.admin_log_action(text, text, text, jsonb, boolean, text) is
  'C217 : journalise une action du back-office GSG dans audit_logs ; l''auteur (user_id, user_name) est fixé par le serveur. Réservée à is_gsg_admin().';

revoke all on function public.admin_log_action(text, text, text, jsonb, boolean, text) from public, anon;
grant execute on function public.admin_log_action(text, text, text, jsonb, boolean, text) to authenticated;
