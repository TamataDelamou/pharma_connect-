-- C213 (décision D64) : état du compte (my_account_status), calculé avec la
-- même règle que les droits serveur (has_verified_role).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c213_account_status.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2130000-…-0000000000xx :
--   01 PAT patient ; 02 PATREJ patient dont le rôle grossiste a été refusé ;
--   10 GRO grossiste ; 11 LIV livreur ;
--   20 PRO_NOFICHE, 21 PRO_PENDING, 22 PRO_REJ, 23 PRO_OK professionnels ;
--   30 PH_NONE pharmacien sans rien ; 31 PH_APP candidature en attente ;
--   32 PH_REJ candidature refusée ; 33 PH_STAFF personnel de Kaloum.
insert into auth.users (id, email)
  select ('c2130000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c213-' || n || '@test.local'
  from unnest(array[1,2,10,11,20,21,22,23,30,31,32,33]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2130000-0000-0000-0000-000000000001', 'patient', null, 'PAT'),
  ('c2130000-0000-0000-0000-000000000002', 'patient', null, 'PATREJ'),
  ('c2130000-0000-0000-0000-000000000010', 'grossiste', null, 'GRO'),
  ('c2130000-0000-0000-0000-000000000011', 'livreur', null, 'LIV'),
  ('c2130000-0000-0000-0000-000000000020', 'professionnel', null, 'PRO_NOFICHE'),
  ('c2130000-0000-0000-0000-000000000021', 'professionnel', null, 'PRO_PENDING'),
  ('c2130000-0000-0000-0000-000000000022', 'professionnel', null, 'PRO_REJ'),
  ('c2130000-0000-0000-0000-000000000023', 'professionnel', null, 'PRO_OK'),
  ('c2130000-0000-0000-0000-000000000030', 'pharmacien', null, 'PH_NONE'),
  ('c2130000-0000-0000-0000-000000000031', 'pharmacien', null, 'PH_APP'),
  ('c2130000-0000-0000-0000-000000000032', 'pharmacien', null, 'PH_REJ'),
  ('c2130000-0000-0000-0000-000000000033', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH_STAFF');
insert into public.professional_profiles (id, is_verified, verification_status, rejection_reason) values
  ('c2130000-0000-0000-0000-000000000021', false, 'pending', null),
  ('c2130000-0000-0000-0000-000000000022', false, 'rejected', 'Numero d''ordre illisible'),
  ('c2130000-0000-0000-0000-000000000023', true, 'verified', null);
insert into public.pharmacies (id, name, address, phone, manager_id, status, created_at) values
  ('c2130000-0000-0000-0000-0000000000a1', 'Pharmacie Candidate', 'Ratoma', '+224600000001', 'c2130000-0000-0000-0000-000000000031', 'pending', now()),
  ('c2130000-0000-0000-0000-0000000000a2', 'Pharmacie Refusee', 'Matoto', '+224600000002', 'c2130000-0000-0000-0000-000000000032', 'rejected', now());
-- Refus du rôle grossiste de PATREJ (journal C214) : un récent, un ancien.
insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, "timestamp") values
  (null, 'Admin', 'reject_role', 'user', 'c2130000-0000-0000-0000-000000000002',
   '{"role": "grossiste", "reason": "Agrement DNPM absent"}', now() - interval '2 days'),
  (null, 'Admin', 'reject_role', 'user', 'c2130000-0000-0000-0000-000000000001',
   '{"role": "livreur", "reason": "Ancien refus"}', now() - interval '40 days');

create temp table t_status (who text primary key, s jsonb, active_check boolean);
create temp table t_out (c text primary key, state text, msg text);
grant all on t_status, t_out to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then raise notice 'CAS % OK : %', p_case, p_detail;
  else raise notice 'CAS % ECHEC : %', p_case, p_detail; end if;
end;
$$;

-- Lit l'état de chaque compte, en tant que ce compte, avec le contrôle
-- has_verified_role du rôle déclaré (référence des droits serveur).
create function pg_temp.snap(p_who text, p_uid uuid) returns void language plpgsql as $$
declare v jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v := public.my_account_status();
  insert into t_status values (p_who, v,
    (v->>'role') = 'patient' or public.has_verified_role(array[v->>'role']));
  reset role;
end;
$$;

create function pg_temp.st(p_who text) returns jsonb language sql as $$
  select s from t_status where who = p_who
$$;

create function pg_temp.take_all(p_suffix text) returns void language plpgsql as $$
begin
  perform pg_temp.snap('PAT' || p_suffix, 'c2130000-0000-0000-0000-000000000001');
  perform pg_temp.snap('PATREJ' || p_suffix, 'c2130000-0000-0000-0000-000000000002');
  perform pg_temp.snap('GRO' || p_suffix, 'c2130000-0000-0000-0000-000000000010');
  perform pg_temp.snap('LIV' || p_suffix, 'c2130000-0000-0000-0000-000000000011');
  perform pg_temp.snap('PRO_NOFICHE' || p_suffix, 'c2130000-0000-0000-0000-000000000020');
  perform pg_temp.snap('PRO_PENDING' || p_suffix, 'c2130000-0000-0000-0000-000000000021');
  perform pg_temp.snap('PRO_REJ' || p_suffix, 'c2130000-0000-0000-0000-000000000022');
  perform pg_temp.snap('PRO_OK' || p_suffix, 'c2130000-0000-0000-0000-000000000023');
  perform pg_temp.snap('PH_NONE' || p_suffix, 'c2130000-0000-0000-0000-000000000030');
  perform pg_temp.snap('PH_APP' || p_suffix, 'c2130000-0000-0000-0000-000000000031');
  perform pg_temp.snap('PH_REJ' || p_suffix, 'c2130000-0000-0000-0000-000000000032');
  perform pg_temp.snap('PH_STAFF' || p_suffix, 'c2130000-0000-0000-0000-000000000033');
end;
$$;

-- ==================== Premier relevé ====================
select pg_temp.take_all('');

select pg_temp.verdict('1',
  pg_temp.st('PAT')->>'state' = 'patient' and (pg_temp.st('PAT')->>'role_active')::boolean
  and pg_temp.st('PAT')->'last_role_rejection' = 'null'::jsonb,
  'patient : etat patient, actif ; un refus de plus de 30 jours n''est pas rappele');
select pg_temp.verdict('2',
  pg_temp.st('PATREJ')->>'state' = 'patient'
  and pg_temp.st('PATREJ')->'last_role_rejection'->>'role' = 'grossiste'
  and pg_temp.st('PATREJ')->'last_role_rejection'->>'reason' = 'Agrement DNPM absent',
  'role refuse par GSG il y a 2 jours : le compte (redevenu patient) voit le role refuse et le motif');
select pg_temp.verdict('3',
  pg_temp.st('GRO')->>'state' = 'pending_review' and not (pg_temp.st('GRO')->>'role_active')::boolean
  and pg_temp.st('LIV')->>'state' = 'pending_review' and not (pg_temp.st('LIV')->>'role_active')::boolean,
  'grossiste et livreur non valides : en attente de verification, role inactif');
select pg_temp.verdict('4',
  pg_temp.st('PRO_NOFICHE')->>'state' = 'professional_profile_missing'
  and pg_temp.st('PRO_PENDING')->>'state' = 'pending_review'
  and pg_temp.st('PRO_REJ')->>'state' = 'professional_rejected'
  and pg_temp.st('PRO_REJ')->>'professional_rejection_reason' = 'Numero d''ordre illisible'
  and pg_temp.st('PRO_OK')->>'state' = 'verified' and (pg_temp.st('PRO_OK')->>'role_active')::boolean
  and not (pg_temp.st('PRO_PENDING')->>'role_active')::boolean,
  'professionnels : fiche absente, en attente, refusee (motif rendu), verifiee');
select pg_temp.verdict('5',
  pg_temp.st('PH_NONE')->>'state' = 'no_pharmacy' and not (pg_temp.st('PH_NONE')->>'role_active')::boolean
  and (pg_temp.st('PH_NONE')->>'pending_invitations')::int = 0
  and pg_temp.st('PH_APP')->>'state' = 'pharmacy_application_pending'
  and pg_temp.st('PH_APP')->'application'->>'name' = 'Pharmacie Candidate'
  and pg_temp.st('PH_REJ')->>'state' = 'pharmacy_application_rejected'
  and pg_temp.st('PH_STAFF')->>'state' = 'verified' and (pg_temp.st('PH_STAFF')->>'role_active')::boolean
  and pg_temp.st('PH_STAFF')->'pharmacy'->>'id' = '55555555-5555-5555-5555-555555550001',
  'pharmaciens : sans officine, candidature en attente (nom), candidature refusee, personnel d''une officine active');

-- ==================== Changements d'état ====================
-- Invitation reçue par PH_NONE ; validation du grossiste et du livreur par
-- GSG ; Kaloum suspendue.
insert into public.pharmacy_staff_invitations (pharmacy_id, invited_user_id, status)
  values ('55555555-5555-5555-5555-555555550001', 'c2130000-0000-0000-0000-000000000030', 'pending');
update public.profiles set role_verified_at = now()
  where id in ('c2130000-0000-0000-0000-000000000010', 'c2130000-0000-0000-0000-000000000011');
update public.pharmacies set status = 'suspended' where id = '55555555-5555-5555-5555-555555550001';
select pg_temp.take_all('-2');

select pg_temp.verdict('6', (pg_temp.st('PH_NONE-2')->>'pending_invitations')::int = 1,
  'invitation d''un titulaire : comptee pour le pharmacien sans officine');
select pg_temp.verdict('7',
  pg_temp.st('GRO-2')->>'state' = 'verified' and (pg_temp.st('GRO-2')->>'role_active')::boolean
  and pg_temp.st('LIV-2')->>'state' = 'verified',
  'grossiste et livreur valides par GSG : verifies, role actif');
select pg_temp.verdict('8',
  pg_temp.st('PH_STAFF-2')->>'state' = 'pharmacy_inactive' and not (pg_temp.st('PH_STAFF-2')->>'role_active')::boolean
  and pg_temp.st('PH_STAFF-2')->'pharmacy'->>'status' = 'suspended',
  'officine suspendue : etat pharmacy_inactive, role inactif');

-- ==================== Cohérence avec les droits serveur ====================
select pg_temp.verdict('9',
  (select bool_and(((s->>'role_active')::boolean = active_check)
                   and (((s->>'state') in ('patient', 'verified')) = active_check))
     from t_status),
  format('%s releves : role_active et l''etat concordent avec has_verified_role pour tous les comptes', (select count(*) from t_status)));

-- ==================== Droits ====================
set local role anon;
do $$ begin
  perform public.my_account_status();
  insert into t_out values ('10', 'OK', null);
exception when others then insert into t_out values ('10', sqlstate, sqlerrm);
end $$;
reset role;
select set_config('request.jwt.claims', '', true);
set local role authenticated;
do $$ begin
  perform public.my_account_status();
  insert into t_out values ('10b', 'OK', null);
exception when others then insert into t_out values ('10b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.verdict('10',
  (select state = '42501' from t_out where c = '10') and (select state = '42501' from t_out where c = '10b')
  and not has_function_privilege('anon', 'public.my_account_status()', 'execute'),
  'anon refuse ; sans identite, refus « connexion requise »');

rollback;
