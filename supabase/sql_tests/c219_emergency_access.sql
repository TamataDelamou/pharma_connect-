-- C219 (décision D63) : accès d'urgence au dossier de santé (bris de glace,
-- 24 heures, tracé) et interactions professionnelles limitées au lien de soin.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c219_emergency_access.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2190000-…-0000000000xx :
--   01 PAT1, 02 PAT2 patients ; 03 ADM admin GSG ;
--   10 PRO1 (consultation avec PAT1) ; 11 PRO2 (vérifié, sans affiliation) ;
--   15 PRONV (non vérifié, affilié H1) ; 20 PH pharmacien de Kaloum ;
--   31 DOC1 (affilié H1) ; 32 DOC2 (affilié H2).
insert into auth.users (id, email)
  select ('c2190000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c219-' || n || '@test.local'
  from unnest(array[1,2,3,10,11,15,20,31,32]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2190000-0000-0000-0000-000000000001', 'patient', null, 'Patient PAT1'),
  ('c2190000-0000-0000-0000-000000000002', 'patient', null, 'Patient PAT2'),
  ('c2190000-0000-0000-0000-000000000003', 'patient', null, 'Admin C219'),
  ('c2190000-0000-0000-0000-000000000010', 'professionnel', null, 'PRO1'),
  ('c2190000-0000-0000-0000-000000000011', 'professionnel', null, 'PRO2'),
  ('c2190000-0000-0000-0000-000000000015', 'professionnel', null, 'PRONV'),
  ('c2190000-0000-0000-0000-000000000020', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH Kaloum'),
  ('c2190000-0000-0000-0000-000000000031', 'professionnel', null, 'DOC1'),
  ('c2190000-0000-0000-0000-000000000032', 'professionnel', null, 'DOC2');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2190000-0000-0000-0000-000000000003', 'c219-3@test.local', 'Admin C219', 'admin', true);
insert into public.professional_profiles (id, is_verified, verification_status)
  select ('c2190000-0000-0000-0000-0000000000' || n)::uuid, n <> '15', case when n = '15' then 'pending' else 'verified' end
  from unnest(array['10','11','15','31','32']) n;

insert into public.health_records (id, patient_id, blood_type) values
  ('c2190000-0000-0000-0000-0000000000a1', 'c2190000-0000-0000-0000-000000000001', 'A+'),
  ('c2190000-0000-0000-0000-0000000000a2', 'c2190000-0000-0000-0000-000000000002', 'O-');
insert into public.consultations (patient_id, professional_id, scheduled_at, status) values
  ('c2190000-0000-0000-0000-000000000001', 'c2190000-0000-0000-0000-000000000010', now() + interval '1 day', 'confirmed');

insert into public.hospitals (id, name, address) values
  ('c2190000-0000-0000-0000-0000000000e1', 'Hopital H1 (C219)', 'Conakry'),
  ('c2190000-0000-0000-0000-0000000000e2', 'Hopital H2 (C219)', 'Kindia');
insert into public.hospital_affiliations (id, professional_id, hospital_id, role, start_date, is_active, primary_affiliation) values
  ('c2190000-0000-0000-0000-0000000000f1', 'c2190000-0000-0000-0000-000000000031', 'c2190000-0000-0000-0000-0000000000e1', 'doctor', current_date - 100, true, true),
  ('c2190000-0000-0000-0000-0000000000f2', 'c2190000-0000-0000-0000-000000000032', 'c2190000-0000-0000-0000-0000000000e2', 'doctor', current_date - 100, true, true),
  ('c2190000-0000-0000-0000-0000000000f3', 'c2190000-0000-0000-0000-000000000015', 'c2190000-0000-0000-0000-0000000000e1', 'doctor', current_date - 100, true, true);

-- Triage : T1 PAT1 en cours à H1 ; T2 PAT2 sorti de H1 ; T3 PAT2 en attente à H2.
insert into public.triage_patients (id, patient_id, status, priority_level, chief_complaint, hospital_id) values
  ('c2190000-0000-0000-0000-0000000000d1', 'c2190000-0000-0000-0000-000000000001', 'in_assessment', 1, 'Detresse respiratoire', 'c2190000-0000-0000-0000-0000000000e1'),
  ('c2190000-0000-0000-0000-0000000000d2', 'c2190000-0000-0000-0000-000000000002', 'discharged', 3, 'Entorse', 'c2190000-0000-0000-0000-0000000000e1'),
  ('c2190000-0000-0000-0000-0000000000d3', 'c2190000-0000-0000-0000-000000000002', 'waiting', 2, 'Fievre', 'c2190000-0000-0000-0000-0000000000e2');

\set PAT1 'c2190000-0000-0000-0000-000000000001'
\set PAT2 'c2190000-0000-0000-0000-000000000002'
\set ADM 'c2190000-0000-0000-0000-000000000003'
\set PRO1 'c2190000-0000-0000-0000-000000000010'
\set PRO2 'c2190000-0000-0000-0000-000000000011'
\set PRONV 'c2190000-0000-0000-0000-000000000015'
\set PH 'c2190000-0000-0000-0000-000000000020'
\set DOC1 'c2190000-0000-0000-0000-000000000031'
\set DOC2 'c2190000-0000-0000-0000-000000000032'
\set T1 'c2190000-0000-0000-0000-0000000000d1'
\set T2 'c2190000-0000-0000-0000-0000000000d2'
\set T3 'c2190000-0000-0000-0000-0000000000d3'
\set REASON 'Patient inconscient, recherche d''allergies et traitements en cours'

create temp table t_out (c text primary key, state text, msg text);
create temp table t_ctx (k text primary key, v text);
grant all on t_out, t_ctx to authenticated, anon;

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

-- Déclaration d'urgence par l'utilisateur courant ; l'identifiant obtenu est
-- rangé dans t_ctx sous p_case.
create function pg_temp.declare(p_case text, p_triage uuid, p_reason text) returns void language plpgsql as $$
declare v uuid;
begin
  v := public.declare_emergency_access(p_triage, p_reason);
  insert into t_out values (p_case, 'OK', null);
  insert into t_ctx values (p_case, v::text);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.end_grant(p_case text, p_grant uuid) returns void language plpgsql as $$
begin
  perform public.end_emergency_access(p_grant);
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

-- Nombre de dossiers de santé d'un patient visibles par l'utilisateur courant.
create function pg_temp.records(p_patient uuid) returns bigint language sql as $$
  select count(*) from public.health_records where patient_id = p_patient
$$;

create function pg_temp.ctx(k text) returns uuid language sql as $$
  select v::uuid from t_ctx where t_ctx.k = ctx.k
$$;

-- ==================== Bris de glace ====================
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.records(:'PAT1') as doc1_before \gset
select pg_temp.declare('2', :'T1', 'urgent');
reset role;
select count(*) as grants_after_2 from public.emergency_access_grants \gset
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.declare('3', :'T1', :'REASON');
select pg_temp.records(:'PAT1') as doc1_after, pg_temp.records(:'PAT2') as doc1_pat2 \gset
reset role;

select pg_temp.verdict('1', :'doc1_before' = '0', 'DOC1 (H1, sans lien de soin) ne voit pas le dossier de PAT1 avant la declaration');
select pg_temp.expect('2', '22023', :'grants_after_2' = '0', '; motif trop court refuse, rien d''ecrit');
select pg_temp.expect('3', 'OK',
  :'doc1_after' = '1' and :'doc1_pat2' = '0'
  and (select expires_at - granted_at = interval '24 hours' and patient_id = :'PAT1' and hospital_id = 'c2190000-0000-0000-0000-0000000000e1'
         from public.emergency_access_grants where id = pg_temp.ctx('3')),
  '; urgence declaree : DOC1 voit le dossier de PAT1 (pas celui de PAT2), acces de 24 heures');
select pg_temp.verdict('3-audit',
  (select count(*) = 1 from public.audit_logs
    where action = 'emergency_access_granted' and resource = 'health_record' and resource_id = :'PAT1'
      and user_id = :'DOC1' and changes->>'reason' = :'REASON' and changes->>'grant_id' = pg_temp.ctx('3')::text),
  'declaration inscrite au journal d''audit (professionnel, patient, motif)');

-- Refus : autre hôpital, sans affiliation, non vérifié, pharmacien, triage inconnu, prise en charge terminée.
select pg_temp.as_user(:'DOC2'); set local role authenticated; select pg_temp.declare('4a', :'T1', :'REASON'); reset role;
select pg_temp.as_user(:'PRO2'); set local role authenticated; select pg_temp.declare('4b', :'T1', :'REASON'); reset role;
select pg_temp.as_user(:'PRONV'); set local role authenticated; select pg_temp.declare('4c', :'T1', :'REASON'); reset role;
select pg_temp.as_user(:'PH'); set local role authenticated; select pg_temp.declare('4d', :'T1', :'REASON'); reset role;
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.declare('4e', 'c2190000-0000-0000-0000-00000000dead', :'REASON');
select pg_temp.declare('5', :'T2', :'REASON');
reset role;
select pg_temp.expect('4a', '42501', true, '; DOC2 (affilie a H2) refuse sur un triage de H1');
select pg_temp.expect('4b', '42501', true, '; professionnel sans affiliation refuse');
select pg_temp.expect('4c', '42501', true, '; professionnel non verifie refuse');
select pg_temp.expect('4d', '42501', true, '; pharmacien refuse');
select pg_temp.expect('4e', '42501',
  (select msg from t_out where c = '4e') = (select msg from t_out where c = '4a'),
  '; triage inconnu : meme refus qu''un triage d''un autre hopital');
select pg_temp.expect('5', '22023', (select count(*) = 1 from public.emergency_access_grants),
  '; prise en charge terminee (patient sorti) : refus ; seule la declaration du cas 3 existe');

-- Anonyme.
set local role anon;
do $$ begin
  perform public.declare_emergency_access('c2190000-0000-0000-0000-0000000000d1', 'Patient inconscient, test anonyme');
  insert into t_out values ('6a', 'OK', null);
exception when others then insert into t_out values ('6a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform * from public.list_emergency_access();
  insert into t_out values ('6b', 'OK', null);
exception when others then insert into t_out values ('6b', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform count(*) from public.emergency_access_grants;
  insert into t_out values ('6c', 'OK', null);
exception when others then insert into t_out values ('6c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('6a', '42501', true, '; anon ne declare pas d''urgence');
select pg_temp.expect('6b', '42501', true, '; anon ne liste pas les acces');
select pg_temp.expect('6c', '42501', true, '; anon ne lit pas la table');

-- Écritures directes interdites (même au professionnel concerné).
select pg_temp.as_user(:'DOC1'); set local role authenticated;
do $$ begin
  insert into public.emergency_access_grants (patient_id, professional_id, hospital_id, reason, expires_at)
    values ('c2190000-0000-0000-0000-000000000002', auth.uid(), 'c2190000-0000-0000-0000-0000000000e1', 'Insertion directe sans passer par la fonction', now() + interval '10 days');
  insert into t_out values ('7a', 'OK', null);
exception when others then insert into t_out values ('7a', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.emergency_access_grants set expires_at = now() + interval '30 days';
  insert into t_out values ('7b', 'OK', null);
exception when others then insert into t_out values ('7b', sqlstate, sqlerrm);
end $$;
do $$ begin
  delete from public.emergency_access_grants;
  insert into t_out values ('7c', 'OK', null);
exception when others then insert into t_out values ('7c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('7a', '42501', true, '; insertion directe refusee');
select pg_temp.expect('7b', '42501',
  (select expires_at - granted_at = interval '24 hours' from public.emergency_access_grants where id = pg_temp.ctx('3')),
  '; prolongation directe refusee');
select pg_temp.expect('7c', '42501', (select count(*) = 1 from public.emergency_access_grants), '; suppression directe refusee (trace conservee)');

-- ==================== Visibilité ====================
select pg_temp.as_user(:'PAT1'); set local role authenticated;
select count(*) as pat1_rows,
       (select count(*) from public.list_emergency_access()
         where professional_name = 'DOC1' and hospital_name = 'Hopital H1 (C219)' and reason = :'REASON' and is_active) as pat1_list
  from public.emergency_access_grants \gset
reset role;
select pg_temp.as_user(:'PAT2'); set local role authenticated;
select (select count(*) from public.emergency_access_grants) + (select count(*) from public.list_emergency_access()) as pat2_n \gset
reset role;
select pg_temp.as_user(:'DOC2'); set local role authenticated;
select (select count(*) from public.emergency_access_grants) + (select count(*) from public.list_emergency_access()) as doc2_n \gset
reset role;
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select count(*) as doc1_list from public.list_emergency_access() where patient_name = 'Patient PAT1' \gset
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated;
select count(*) as adm_n from public.list_emergency_access() \gset
reset role;
select pg_temp.verdict('8', :'pat1_rows' = '1' and :'pat1_list' = '1',
  'PAT1 voit l''acces d''urgence a son dossier (DOC1, H1, motif, en cours)');
select pg_temp.verdict('8-cloisonnement', :'pat2_n' = '0' and :'doc2_n' = '0', 'PAT2 et DOC2 ne voient rien');
select pg_temp.verdict('8-parties', :'doc1_list' = '1' and :'adm_n' = '1', 'DOC1 voit sa declaration ; l''administration GSG la voit aussi');

-- ==================== Échéance, affiliation, renouvellement ====================
update public.emergency_access_grants
   set granted_at = now() - interval '25 hours', expires_at = now() - interval '1 hour'
 where id = pg_temp.ctx('3');
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.records(:'PAT1') as doc1_expired,
       (select count(*) from public.list_emergency_access() where not is_active) as doc1_inactive \gset
select pg_temp.end_grant('9-fin', pg_temp.ctx('3'));
select pg_temp.declare('10', :'T1', 'Renouvellement : patient toujours inconscient, bilan en cours');
select pg_temp.records(:'PAT1') as doc1_renewed \gset
reset role;
select pg_temp.verdict('9', :'doc1_expired' = '0' and :'doc1_inactive' = '1', 'apres 24 heures : dossier de PAT1 de nouveau invisible, acces liste comme termine');
select pg_temp.expect('9-fin', '22023', true, '; un acces echu ne peut plus etre termine');
select pg_temp.expect('10', 'OK', :'doc1_renewed' = '1' and (select count(*) = 2 from public.emergency_access_grants),
  '; nouvelle declaration (nouveau motif) : acces rouvert, deux traces');

update public.hospital_affiliations set is_active = false where id = 'c2190000-0000-0000-0000-0000000000f1';
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.records(:'PAT1') as doc1_unaffiliated \gset
reset role;
update public.hospital_affiliations set is_active = true where id = 'c2190000-0000-0000-0000-0000000000f1';
select pg_temp.verdict('11', :'doc1_unaffiliated' = '0', 'affiliation a H1 terminee : l''acces d''urgence en cours ne donne plus rien');

-- ==================== Interactions ====================
select pg_temp.as_user(:'DOC1'); set local role authenticated;
do $$ begin
  insert into public.professional_patient_interactions (id, professional_id, patient_id, type, notes)
    values ('c2190000-0000-0000-0000-0000000000b1', auth.uid(), 'c2190000-0000-0000-0000-000000000001', 'emergency', 'Prise en charge urgences');
  insert into t_out values ('12a', 'OK', null);
exception when others then insert into t_out values ('12a', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.professional_patient_interactions set patient_id = 'c2190000-0000-0000-0000-000000000002'
   where id = 'c2190000-0000-0000-0000-0000000000b1';
  insert into t_out values ('12d', 'OK', null);
exception when others then insert into t_out values ('12d', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PRO2'); set local role authenticated;
do $$ begin
  insert into public.professional_patient_interactions (professional_id, patient_id, type)
    values (auth.uid(), 'c2190000-0000-0000-0000-000000000001', 'consultation');
  insert into t_out values ('12b', 'OK', null);
exception when others then insert into t_out values ('12b', sqlstate, sqlerrm);
end $$;
do $$ begin
  insert into public.professional_patient_interactions (professional_id, patient_id, type)
    values ('c2190000-0000-0000-0000-000000000010', 'c2190000-0000-0000-0000-000000000001', 'consultation');
  insert into t_out values ('12e', 'OK', null);
exception when others then insert into t_out values ('12e', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PRO1'); set local role authenticated;
do $$ begin
  insert into public.professional_patient_interactions (professional_id, patient_id, type)
    values (auth.uid(), 'c2190000-0000-0000-0000-000000000001', 'follow_up');
  insert into t_out values ('12c', 'OK', null);
exception when others then insert into t_out values ('12c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('12a', 'OK', true, '; DOC1 (urgence en cours) enregistre une interaction avec PAT1');
select pg_temp.expect('12b', '42501', true, '; PRO2 (aucun lien de soin) ne cree plus d''interaction avec PAT1');
select pg_temp.expect('12c', 'OK', true, '; PRO1 (consultation avec PAT1) enregistre un suivi');
select pg_temp.expect('12d', '42501',
  (select patient_id = :'PAT1' from public.professional_patient_interactions where id = 'c2190000-0000-0000-0000-0000000000b1'),
  '; interaction deplacee vers un patient sans lien de soin : refus');
select pg_temp.expect('12e', '42501', true, '; creation au nom d''un autre professionnel refusee');

-- ==================== Fin anticipée ====================
select pg_temp.as_user(:'PAT2'); set local role authenticated; select pg_temp.end_grant('13a', pg_temp.ctx('10')); reset role;
select ended_at is null as still_open_13a from public.emergency_access_grants where id = pg_temp.ctx('10') \gset
select pg_temp.as_user(:'PAT1'); set local role authenticated; select pg_temp.end_grant('13b', pg_temp.ctx('10')); reset role;
select pg_temp.as_user(:'DOC1'); set local role authenticated;
select pg_temp.records(:'PAT1') as doc1_ended \gset
select pg_temp.end_grant('13c', pg_temp.ctx('10'));
select pg_temp.declare('14', :'T1', 'Troisieme declaration pour tester la fin par le medecin');
select pg_temp.end_grant('14-fin', pg_temp.ctx('14'));
select pg_temp.declare('15', :'T1', 'Quatrieme declaration pour tester la fin par GSG');
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated; select pg_temp.end_grant('15-fin', pg_temp.ctx('15')); reset role;

select pg_temp.expect('13a', '42501', :'still_open_13a'::boolean,
  '; PAT2 ne peut pas mettre fin a l''acces au dossier de PAT1');
select pg_temp.expect('13b', 'OK',
  :'doc1_ended' = '0'
  and (select ended_by = :'PAT1' from public.emergency_access_grants where id = pg_temp.ctx('10'))
  and (select count(*) = 1 from public.audit_logs where action = 'emergency_access_ended' and changes->>'grant_id' = pg_temp.ctx('10')::text
         and changes->>'ended_by_role' = 'patient'),
  '; PAT1 met fin a l''acces : DOC1 ne voit plus le dossier ; fin tracee au journal');
select pg_temp.expect('13c', '22023', true, '; un acces deja termine ne se termine pas deux fois');
select pg_temp.expect('14-fin', 'OK', (select ended_by = :'DOC1' from public.emergency_access_grants where id = pg_temp.ctx('14')),
  '; le medecin met fin a son propre acces');
select pg_temp.expect('15-fin', 'OK', (select ended_by = :'ADM' from public.emergency_access_grants where id = pg_temp.ctx('15')),
  '; l''administration GSG met fin a un acces');

-- ==================== Droits ====================
select pg_temp.verdict('16',
  not has_function_privilege('anon', 'public.declare_emergency_access(uuid, text)', 'execute')
  and not has_function_privilege('anon', 'public.end_emergency_access(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.list_emergency_access()', 'execute')
  and has_function_privilege('authenticated', 'public.declare_emergency_access(uuid, text)', 'execute')
  and not has_table_privilege('authenticated', 'public.emergency_access_grants', 'insert')
  and not has_table_privilege('authenticated', 'public.emergency_access_grants', 'update')
  and not has_table_privilege('authenticated', 'public.emergency_access_grants', 'delete'),
  'droits : fonctions fermees a anon ; table en lecture seule pour les utilisateurs');

rollback;
