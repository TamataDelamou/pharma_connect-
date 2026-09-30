-- C216 / C217 (décision D61) : accès aux données de santé limités au lien de
-- soin (dossiers), à l'officine destinataire (ordonnances), à l'hôpital
-- d'affiliation (triage) ; stupéfiants retirés aux livreurs ; journal d'audit
-- réservé à l'administration GSG.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c216_c217_care_scoped_access.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2160000-…-0000000000xx :
--   01 PAT1, 02 PAT2 patients ; 03 ADM admin GSG ;
--   10 PRO1 (consultation avec PAT1) ; 11 PRO2 (aucun lien) ;
--   12 PRO3 (interaction avec PAT2, antérieure à C219) ; 13 PRO4 (consultation annulée avec PAT1) ;
--   14 PRO5 (soin à domicile avec PAT2) ; 15 PRONV (non vérifié, consultation avec PAT1) ;
--   20 PH pharmacien de Kaloum ; 21 PHD pharmacien de Dixinn ;
--   30 NURSE (affiliée H1) ; 31 DOC1 (affilié H1) ; 32 DOC2 (affilié H2) ;
--   40 LIV livreur validé ; 41 GRO grossiste validé.
insert into auth.users (id, email)
  select ('c2160000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c216-' || n || '@test.local'
  from unnest(array[1,2,3,10,11,12,13,14,15,20,21,30,31,32,40,41]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2160000-0000-0000-0000-000000000001', 'patient', null, 'Patient PAT1'),
  ('c2160000-0000-0000-0000-000000000002', 'patient', null, 'Patient PAT2'),
  ('c2160000-0000-0000-0000-000000000003', 'patient', null, 'Admin C216'),
  ('c2160000-0000-0000-0000-000000000010', 'professionnel', null, 'PRO1'),
  ('c2160000-0000-0000-0000-000000000011', 'professionnel', null, 'PRO2'),
  ('c2160000-0000-0000-0000-000000000012', 'professionnel', null, 'PRO3'),
  ('c2160000-0000-0000-0000-000000000013', 'professionnel', null, 'PRO4'),
  ('c2160000-0000-0000-0000-000000000014', 'professionnel', null, 'PRO5'),
  ('c2160000-0000-0000-0000-000000000015', 'professionnel', null, 'PRONV'),
  ('c2160000-0000-0000-0000-000000000020', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH Kaloum'),
  ('c2160000-0000-0000-0000-000000000021', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'PHD Dixinn'),
  ('c2160000-0000-0000-0000-000000000030', 'professionnel', null, 'NURSE'),
  ('c2160000-0000-0000-0000-000000000031', 'professionnel', null, 'DOC1'),
  ('c2160000-0000-0000-0000-000000000032', 'professionnel', null, 'DOC2'),
  ('c2160000-0000-0000-0000-000000000040', 'livreur', null, 'LIV'),
  ('c2160000-0000-0000-0000-000000000041', 'grossiste', null, 'GRO');
update public.profiles set role_verified_at = now()
  where id in ('c2160000-0000-0000-0000-000000000040', 'c2160000-0000-0000-0000-000000000041');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2160000-0000-0000-0000-000000000003', 'c216-3@test.local', 'Admin C216', 'admin', true);
insert into public.professional_profiles (id, is_verified, verification_status)
  select ('c2160000-0000-0000-0000-0000000000' || n)::uuid, n <> '15', case when n = '15' then 'pending' else 'verified' end
  from unnest(array['10','11','12','13','14','15','30','31','32']) n;

-- Dossiers de santé de PAT1 et PAT2.
insert into public.health_records (id, patient_id, blood_type) values
  ('c2160000-0000-0000-0000-0000000000a1', 'c2160000-0000-0000-0000-000000000001', 'A+'),
  ('c2160000-0000-0000-0000-0000000000a2', 'c2160000-0000-0000-0000-000000000002', 'O-');
insert into public.health_record_summaries (health_record_id, summary) values
  ('c2160000-0000-0000-0000-0000000000a1', 'Synthese PAT1'),
  ('c2160000-0000-0000-0000-0000000000a2', 'Synthese PAT2');
insert into public.health_goals (patient_id, goal_type, target_value, start_date) values
  ('c2160000-0000-0000-0000-000000000001', 'steps', 8000, current_date),
  ('c2160000-0000-0000-0000-000000000002', 'steps', 6000, current_date);
insert into public.health_milestones (patient_id, milestone_type, achievement) values
  ('c2160000-0000-0000-0000-000000000001', 'steps', '10 jours'),
  ('c2160000-0000-0000-0000-000000000002', 'steps', '5 jours');

-- Liens de soin (créés par les patients dans l'application ; ici en postgres).
insert into public.consultations (id, patient_id, professional_id, scheduled_at, status) values
  ('c2160000-0000-0000-0000-0000000000c1', 'c2160000-0000-0000-0000-000000000001', 'c2160000-0000-0000-0000-000000000010', now() + interval '1 day', 'pending'),
  ('c2160000-0000-0000-0000-0000000000c2', 'c2160000-0000-0000-0000-000000000001', 'c2160000-0000-0000-0000-000000000013', now() - interval '1 day', 'cancelled'),
  ('c2160000-0000-0000-0000-0000000000c3', 'c2160000-0000-0000-0000-000000000001', 'c2160000-0000-0000-0000-000000000015', now() + interval '1 day', 'confirmed');
insert into public.homecare_interventions (patient_id, professional_id, scheduled_at, status, address) values
  ('c2160000-0000-0000-0000-000000000002', 'c2160000-0000-0000-0000-000000000014', now() + interval '2 days', 'confirmed', 'Conakry');

-- Hôpitaux et affiliations.
insert into public.hospitals (id, name, address) values
  ('c2160000-0000-0000-0000-0000000000e1', 'Hopital H1 (C216)', 'Conakry'),
  ('c2160000-0000-0000-0000-0000000000e2', 'Hopital H2 (C216)', 'Kindia');
insert into public.hospital_affiliations (professional_id, hospital_id, role, start_date, is_active, primary_affiliation) values
  ('c2160000-0000-0000-0000-000000000030', 'c2160000-0000-0000-0000-0000000000e1', 'nurse', current_date - 100, true, true),
  ('c2160000-0000-0000-0000-000000000031', 'c2160000-0000-0000-0000-0000000000e1', 'doctor', current_date - 100, true, true),
  ('c2160000-0000-0000-0000-000000000032', 'c2160000-0000-0000-0000-0000000000e2', 'doctor', current_date - 100, true, true);

-- Un stupéfiant au catalogue, une entrée au journal d'audit.
insert into public.products (id, name, generic_name, dosage, form, regulatory_class)
  values ('c2160000-0000-0000-0000-0000000000f1', 'Morphine C216', 'Morphine', '10 mg', 'injectable', 'stupefiant');
insert into public.audit_logs (user_id, user_name, action, resource, resource_id)
  values ('c2160000-0000-0000-0000-000000000003', 'Admin C216', 'test_c216', 'user', 'x');

\set PAT1 'c2160000-0000-0000-0000-000000000001'
\set PAT2 'c2160000-0000-0000-0000-000000000002'
\set ADM 'c2160000-0000-0000-0000-000000000003'
\set PRO1 'c2160000-0000-0000-0000-000000000010'
\set PRO2 'c2160000-0000-0000-0000-000000000011'
\set PRO3 'c2160000-0000-0000-0000-000000000012'
\set PRO4 'c2160000-0000-0000-0000-000000000013'
\set PRO5 'c2160000-0000-0000-0000-000000000014'
\set PRONV 'c2160000-0000-0000-0000-000000000015'
\set PH 'c2160000-0000-0000-0000-000000000020'
\set PHD 'c2160000-0000-0000-0000-000000000021'
\set NURSE 'c2160000-0000-0000-0000-000000000030'
\set DOC1 'c2160000-0000-0000-0000-000000000031'
\set DOC2 'c2160000-0000-0000-0000-000000000032'
\set LIV 'c2160000-0000-0000-0000-000000000040'
\set GRO 'c2160000-0000-0000-0000-000000000041'
\set H1 'c2160000-0000-0000-0000-0000000000e1'
\set H2 'c2160000-0000-0000-0000-0000000000e2'

create temp table t_out (c text primary key, state text, msg text);
create temp table t_ctx (k text primary key, v text);
create temp table t_seen (who text, what text, n integer);
grant all on t_out, t_ctx, t_seen to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

create function pg_temp.expect(p_case text, p_state text, p_extra boolean default true, p_detail text default '') returns void language plpgsql as $$
declare o record;
begin
  select * into o from t_out where c = p_case;
  if o is null then
    raise notice 'CAS % ECHEC : bloc non execute', p_case;
  elsif o.state = p_state and coalesce(p_extra, false) then
    raise notice 'CAS % OK : % %', p_case, o.state || coalesce(' « ' || o.msg || ' »', ''), p_detail;
  else
    raise notice 'CAS % ECHEC : obtenu % (attendu %) %', p_case, o.state || coalesce(' « ' || o.msg || ' »', ''), p_state, p_detail;
  end if;
end;
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then raise notice 'CAS % OK : %', p_case, p_detail;
  else raise notice 'CAS % ECHEC : %', p_case, p_detail; end if;
end;
$$;

-- Ce que voit chaque identité (lecture sous RLS).
create function pg_temp.seen(p_who text) returns void language plpgsql as $$
begin
  insert into t_seen values
    (p_who, 'rec_pat1', (select count(*) from public.health_records where patient_id = 'c2160000-0000-0000-0000-000000000001')),
    (p_who, 'rec_pat2', (select count(*) from public.health_records where patient_id = 'c2160000-0000-0000-0000-000000000002')),
    (p_who, 'sum_pat1', (select count(*) from public.health_record_summaries where health_record_id = 'c2160000-0000-0000-0000-0000000000a1')),
    (p_who, 'sum_pat2', (select count(*) from public.health_record_summaries where health_record_id = 'c2160000-0000-0000-0000-0000000000a2')),
    (p_who, 'goal_pat1', (select count(*) from public.health_goals where patient_id = 'c2160000-0000-0000-0000-000000000001')),
    (p_who, 'goal_pat2', (select count(*) from public.health_goals where patient_id = 'c2160000-0000-0000-0000-000000000002')),
    (p_who, 'mil_pat1', (select count(*) from public.health_milestones where patient_id = 'c2160000-0000-0000-0000-000000000001')),
    (p_who, 'mil_pat2', (select count(*) from public.health_milestones where patient_id = 'c2160000-0000-0000-0000-000000000002'));
end;
$$;
create function pg_temp.n(p_who text, p_what text) returns integer language sql as $$
  select n from t_seen where who = p_who and what = p_what
$$;

-- ==================== Dossiers de santé ====================
select pg_temp.as_user(:'PRO1'); set local role authenticated; select pg_temp.seen('PRO1'); reset role;
select pg_temp.as_user(:'PRO2'); set local role authenticated; select pg_temp.seen('PRO2'); reset role;
-- Depuis C219 (D63), un professionnel ne peut plus créer seul une interaction
-- sans lien de soin : l'interaction de PRO3 est insérée ici en postgres, comme
-- une interaction enregistrée avant C219.
do $$ begin
  insert into public.professional_patient_interactions (professional_id, patient_id, type)
    values ('c2160000-0000-0000-0000-000000000012', 'c2160000-0000-0000-0000-000000000002', 'consultation');
  insert into t_out values ('3-interaction', 'OK', null);
exception when others then insert into t_out values ('3-interaction', sqlstate, sqlerrm);
end $$;
select pg_temp.as_user(:'PRO3'); set local role authenticated;
select pg_temp.seen('PRO3'); reset role;
select pg_temp.as_user(:'PRO4'); set local role authenticated; select pg_temp.seen('PRO4'); reset role;
select pg_temp.as_user(:'PRO5'); set local role authenticated; select pg_temp.seen('PRO5'); reset role;
select pg_temp.as_user(:'PRONV'); set local role authenticated; select pg_temp.seen('PRONV'); reset role;
select pg_temp.as_user(:'PH'); set local role authenticated; select pg_temp.seen('PH'); reset role;
select pg_temp.as_user(:'PAT1'); set local role authenticated; select pg_temp.seen('PAT1'); reset role;

select pg_temp.verdict('1', pg_temp.n('PRO1', 'rec_pat1') = 1 and pg_temp.n('PRO1', 'rec_pat2') = 0,
  'PRO1 (consultation avec PAT1) voit le dossier de PAT1, pas celui de PAT2');
select pg_temp.verdict('1-annexes',
  pg_temp.n('PRO1', 'sum_pat1') = 1 and pg_temp.n('PRO1', 'sum_pat2') = 0
  and pg_temp.n('PRO1', 'goal_pat1') = 1 and pg_temp.n('PRO1', 'goal_pat2') = 0
  and pg_temp.n('PRO1', 'mil_pat1') = 1 and pg_temp.n('PRO1', 'mil_pat2') = 0,
  'PRO1 : synthese, objectifs et etapes de PAT1 seulement');
select pg_temp.verdict('2', (select sum(n) = 0 from t_seen where who = 'PRO2'), 'PRO2 (aucun lien) ne voit rien');
select pg_temp.expect('3-interaction', 'OK', pg_temp.n('PRO3', 'rec_pat2') = 0 and pg_temp.n('PRO3', 'sum_pat2') = 0,
  '; PRO3 a une interaction avec PAT2 (anterieure a C219) mais ne voit toujours pas son dossier');
select pg_temp.verdict('4', (select sum(n) = 0 from t_seen where who = 'PRO4'), 'PRO4 (consultation annulee) ne voit rien');
select pg_temp.verdict('5', pg_temp.n('PRO5', 'rec_pat2') = 1 and pg_temp.n('PRO5', 'rec_pat1') = 0 and pg_temp.n('PRO5', 'goal_pat2') = 1,
  'PRO5 (soin a domicile avec PAT2) voit le dossier de PAT2 seulement');
select pg_temp.verdict('6', (select sum(n) = 0 from t_seen where who = 'PRONV'), 'professionnel non verifie : rien, meme avec une consultation');
select pg_temp.verdict('7', (select sum(n) = 0 from t_seen where who = 'PH'), 'pharmacien : plus aucun acces aux dossiers de sante');
select pg_temp.verdict('8', pg_temp.n('PAT1', 'rec_pat1') = 1 and pg_temp.n('PAT1', 'rec_pat2') = 0 and pg_temp.n('PAT1', 'goal_pat1') = 1,
  'PAT1 voit toujours son propre dossier, pas celui de PAT2');

-- ==================== Lien de soin non falsifiable ====================
select pg_temp.as_user(:'PRO1'); set local role authenticated;
do $$ begin
  update public.consultations set patient_id = 'c2160000-0000-0000-0000-000000000002'
    where id = 'c2160000-0000-0000-0000-0000000000c1';
  insert into t_out values ('9a', 'OK', null);
exception when others then insert into t_out values ('9a', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.consultations set notes = 'Notes C216' where id = 'c2160000-0000-0000-0000-0000000000c1';
  insert into t_out values ('9b', 'OK', null);
exception when others then insert into t_out values ('9b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('9a', '42501',
  (select patient_id = :'PAT1' from public.consultations where id = 'c2160000-0000-0000-0000-0000000000c1'),
  '; changement de patient d''une consultation refuse');
select pg_temp.expect('9b', 'OK',
  (select notes = 'Notes C216' from public.consultations where id = 'c2160000-0000-0000-0000-0000000000c1'),
  '; mise a jour ordinaire toujours possible');

-- ==================== Ordonnances : officine destinataire ====================
select pg_temp.as_user(:'PAT1'); set local role authenticated;
do $$ begin
  insert into public.prescriptions (id, patient_id, patient_name, image_url, pharmacy_id) values
    ('c2160000-0000-0000-0000-0000000000b1', auth.uid(), 'PAT1', 'x.jpg', '55555555-5555-5555-5555-555555550001');
  insert into public.prescription_items (prescription_id, medication_name, dosage, frequency, duration, quantity)
    values ('c2160000-0000-0000-0000-0000000000b1', 'Amoxicilline', '500 mg', '3/j', '7 j', 21);
  insert into public.prescriptions (id, patient_id, patient_name, image_url) values
    ('c2160000-0000-0000-0000-0000000000b2', auth.uid(), 'PAT1', 'y.jpg');
  insert into t_out values ('10', 'OK', null);
exception when others then insert into t_out values ('10', sqlstate, sqlerrm);
end $$;
do $$ begin
  insert into public.prescriptions (id, patient_id, patient_name, image_url, pharmacy_id) values
    ('c2160000-0000-0000-0000-0000000000b3', auth.uid(), 'PAT1', 'z.jpg', '55555555-5555-5555-5555-555555550005');
  insert into t_out values ('10-pending', 'OK', null);
exception when others then insert into t_out values ('10-pending', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('10', 'OK', true, '; ordonnance adressee a Kaloum (avec une ligne) et ordonnance sans officine');
select pg_temp.expect('10-pending', '42501', true, '; officine non validee (Kipe, pending) refusee');

select pg_temp.as_user(:'PH'); set local role authenticated;
select count(*) filter (where id = 'c2160000-0000-0000-0000-0000000000b1') as ph_b1,
       count(*) filter (where id = 'c2160000-0000-0000-0000-0000000000b2') as ph_b2
  from public.prescriptions \gset
select count(*) as ph_items from public.prescription_items where prescription_id = 'c2160000-0000-0000-0000-0000000000b1' \gset
do $$ begin
  update public.prescriptions set status = 'validated', validated_at = now() where id = 'c2160000-0000-0000-0000-0000000000b1';
  insert into t_out values ('12', 'OK', null);
exception when others then insert into t_out values ('12', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.prescriptions set pharmacy_id = '55555555-5555-5555-5555-555555550002' where id = 'c2160000-0000-0000-0000-0000000000b1';
  insert into t_out values ('13', 'OK', null);
exception when others then insert into t_out values ('13', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PHD'); set local role authenticated;
select count(*) as phd_all from public.prescriptions where id::text like 'c2160000-%' \gset
select count(*) as phd_items from public.prescription_items where prescription_id = 'c2160000-0000-0000-0000-0000000000b1' \gset
update public.prescriptions set status = 'dispensed' where id = 'c2160000-0000-0000-0000-0000000000b1';
reset role;
select pg_temp.verdict('11', :'ph_b1' = '1' and :'ph_b2' = '0' and :'ph_items' = '1' and :'phd_all' = '0' and :'phd_items' = '0',
  format('Kaloum voit l''ordonnance qui lui est adressee et sa ligne (%s, %s), pas celle sans officine (%s) ; Dixinn ne voit rien (%s, %s)',
    :'ph_b1', :'ph_items', :'ph_b2', :'phd_all', :'phd_items'));
select pg_temp.expect('12', 'OK',
  (select status = 'validated' from public.prescriptions where id = 'c2160000-0000-0000-0000-0000000000b1'),
  '; Kaloum valide l''ordonnance ; la tentative de Dixinn (dispensed) n''a rien change');
select pg_temp.expect('13', '42501',
  (select pharmacy_id = '55555555-5555-5555-5555-555555550001' from public.prescriptions where id = 'c2160000-0000-0000-0000-0000000000b1'),
  '; Kaloum ne peut pas transferer l''ordonnance a Dixinn');

-- ==================== Triage : hôpital d'affiliation ====================
select pg_temp.as_user(:'NURSE'); set local role authenticated;
do $$ begin
  insert into public.triage_patients (id, patient_id, triage_nurse_id, status, priority_level, chief_complaint)
    values ('c2160000-0000-0000-0000-0000000000d1', 'c2160000-0000-0000-0000-000000000001', auth.uid(), 'waiting', 2, 'Douleur thoracique');
  insert into t_out values ('14', 'OK', null);
exception when others then insert into t_out values ('14', sqlstate, sqlerrm);
end $$;
do $$ begin
  insert into public.triage_patients (patient_id, triage_nurse_id, status, priority_level, chief_complaint)
    values ('c2160000-0000-0000-0000-000000000002', 'c2160000-0000-0000-0000-000000000031', 'waiting', 3, 'X');
  insert into t_out values ('16a', 'OK', null);
exception when others then insert into t_out values ('16a', sqlstate, sqlerrm);
end $$;
do $$ begin
  insert into public.triage_patients (patient_id, triage_nurse_id, status, priority_level, chief_complaint, hospital_id)
    values ('c2160000-0000-0000-0000-000000000002', auth.uid(), 'waiting', 3, 'X', 'c2160000-0000-0000-0000-0000000000e2');
  insert into t_out values ('16b', 'OK', null);
exception when others then insert into t_out values ('16b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('14', 'OK',
  (select hospital_id = :'H1' from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1'),
  '; triage enregistre, rattache automatiquement a H1 (affiliation de l''infirmiere)');
select pg_temp.expect('16a', '42501', true, '; infirmiere ne peut pas enregistrer au nom d''un autre');
select pg_temp.expect('16b', '42501', true, '; ni dans un hopital ou elle n''est pas affiliee');

select pg_temp.as_user(:'DOC1'); set local role authenticated;
select count(*) as doc1_sees from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1' \gset
do $$ begin
  update public.triage_patients set priority_level = 1 where id = 'c2160000-0000-0000-0000-0000000000d1';
  insert into public.triage_assessments (triage_patient_id, nurse_id, pain_score)
    values ('c2160000-0000-0000-0000-0000000000d1', auth.uid(), 6);
  insert into t_out values ('17', 'OK', null);
exception when others then insert into t_out values ('17', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'DOC2'); set local role authenticated;
select count(*) as doc2_sees from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1' \gset
update public.triage_patients set priority_level = 5 where id = 'c2160000-0000-0000-0000-0000000000d1';
do $$ begin
  insert into public.triage_assessments (triage_patient_id, nurse_id, pain_score)
    values ('c2160000-0000-0000-0000-0000000000d1', auth.uid(), 2);
  insert into t_out values ('18', 'OK', null);
exception when others then insert into t_out values ('18', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PRO2'); set local role authenticated;
select count(*) as pro2_sees from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1' \gset
reset role;
select pg_temp.verdict('15', :'doc1_sees' = '1' and :'doc2_sees' = '0' and :'pro2_sees' = '0',
  format('DOC1 (affilie H1) voit le triage (%s) ; DOC2 (H2) %s ; PRO2 (sans affiliation) %s', :'doc1_sees', :'doc2_sees', :'pro2_sees'));
select pg_temp.expect('17', 'OK',
  (select priority_level = 1 from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1')
  and (select count(*) = 1 from public.triage_assessments where triage_patient_id = 'c2160000-0000-0000-0000-0000000000d1'),
  '; DOC1 modifie la priorite et ajoute une evaluation ; la modification de DOC2 n''a rien change');
select pg_temp.expect('18', '42501', true, '; DOC2 ne peut pas evaluer un patient de H1');

-- Affiliation terminée : l'accès disparaît.
update public.hospital_affiliations set end_date = current_date - 1
  where professional_id = :'DOC1';
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select count(*) as doc1_after from public.triage_patients where id = 'c2160000-0000-0000-0000-0000000000d1' \gset
reset role;
select pg_temp.verdict('19', :'doc1_after' = '0', format('affiliation de DOC1 terminee : il voit %s triage', :'doc1_after'));

-- ==================== Stupéfiants ====================
select pg_temp.as_user(:'LIV'); set local role authenticated;
select count(*) as liv_sees from public.products where id = 'c2160000-0000-0000-0000-0000000000f1' \gset
reset role;
select pg_temp.as_user(:'GRO'); set local role authenticated;
select count(*) as gro_sees from public.products where id = 'c2160000-0000-0000-0000-0000000000f1' \gset
reset role;
select pg_temp.as_user(:'PH'); set local role authenticated;
select count(*) as ph_sees from public.products where id = 'c2160000-0000-0000-0000-0000000000f1' \gset
reset role;
select pg_temp.as_user(:'PAT1'); set local role authenticated;
select count(*) as pat_sees from public.products where id = 'c2160000-0000-0000-0000-0000000000f1' \gset
reset role;
select pg_temp.verdict('20', :'liv_sees' = '0' and :'gro_sees' = '1' and :'ph_sees' = '1' and :'pat_sees' = '0',
  format('stupefiant : livreur %s, grossiste %s, pharmacien %s, patient %s', :'liv_sees', :'gro_sees', :'ph_sees', :'pat_sees'));

-- ==================== C217 : journal d'audit ====================
select pg_temp.as_user(:'PAT1'); set local role authenticated;
select count(*) as pat_logs from public.audit_logs \gset
do $$ begin
  perform public.admin_log_action('forge', 'user', 'x', null);
  insert into t_out values ('22-patient', 'OK', null);
exception when others then insert into t_out values ('22-patient', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated;
select count(*) as adm_logs from public.audit_logs \gset
do $$ begin
  perform public.admin_log_action('update_pharmacy', 'pharmacy', '55555555-5555-5555-5555-555555550001', '{"status":"active"}'::jsonb);
  insert into t_out values ('22', 'OK', null);
exception when others then insert into t_out values ('22', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.verdict('21', :'pat_logs' = '0' and :'adm_logs'::int >= 1,
  format('journal : patient voit %s ligne, administrateur %s', :'pat_logs', :'adm_logs'));
select pg_temp.expect('22', 'OK',
  exists (select 1 from public.audit_logs where action = 'update_pharmacy' and user_id = :'ADM'
          and user_name = 'Admin C216' and changes->>'status' = 'active'),
  '; action journalisee, auteur fixe par le serveur');
select pg_temp.expect('22-patient', '42501', not exists (select 1 from public.audit_logs where action = 'forge'),
  '; un non-administrateur ne journalise rien');

-- ==================== Droits ====================
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform public.admin_log_action('x', 'user', 'x', null);
  insert into t_out values ('23', 'OK', null);
exception when others then insert into t_out values ('23', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('23', '42501', true, '; anon refuse');
select pg_temp.verdict('23-droits',
  not has_function_privilege('anon', 'public.has_care_relationship(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.is_hospital_professional(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.can_access_triage(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.admin_log_action(text, text, text, jsonb, boolean, text)', 'execute')
  and has_function_privilege('authenticated', 'public.admin_log_action(text, text, text, jsonb, boolean, text)', 'execute'),
  'execute : anon refuse sur les 4 fonctions, authenticated accorde');

rollback;
