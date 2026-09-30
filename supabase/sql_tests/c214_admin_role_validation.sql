-- C214 : validation des rôles et vérification des professionnels par
-- l'administration GSG (admin_list_verification_requests, admin_review_role,
-- admin_verify_professional, admin_set_user_role journalisée).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Les comptes sont créés en tant que postgres ; les appels testés sont faits
-- sous le rôle authenticated (claims JWT) ou anon.
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c214_admin_role_validation.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2140000-…-0000000000xx : 01 ADM admin GSG ; 02 PAT patient ;
-- 03 GRO grossiste non validé ; 04 GRO2 grossiste non validé (refusé) ;
-- 05 LIV livreur validé ; 06 PRO professionnel en attente ;
-- 07 PROV professionnel vérifié ; 08 PRO0 professionnel sans fiche ;
-- 09 PH pharmacien titulaire d'une officine en attente ; 10 REG2 régulateur non validé.
insert into auth.users (id, email)
  select ('c2140000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c214-' || n || '@test.local'
  from generate_series(1, 10) n;

insert into public.profiles (id, role, full_name, phone) values
  ('c2140000-0000-0000-0000-000000000001', 'patient', 'Admin C214', '+224620214001'),
  ('c2140000-0000-0000-0000-000000000002', 'patient', 'Patiente Recherche C214', '+224620214002'),
  ('c2140000-0000-0000-0000-000000000003', 'grossiste', 'Grossiste C214', '+224620214003'),
  ('c2140000-0000-0000-0000-000000000004', 'grossiste', 'Grossiste Refuse C214', '+224620214004'),
  ('c2140000-0000-0000-0000-000000000005', 'livreur', 'Livreur Valide C214', '+224620214005'),
  ('c2140000-0000-0000-0000-000000000006', 'professionnel', 'Pro Attente C214', '+224620214006'),
  ('c2140000-0000-0000-0000-000000000007', 'professionnel', 'Pro Verifie C214', '+224620214007'),
  ('c2140000-0000-0000-0000-000000000008', 'professionnel', 'Pro Sans Fiche C214', '+224620214008'),
  ('c2140000-0000-0000-0000-000000000009', 'pharmacien', 'Titulaire C214', '+224620214009'),
  ('c2140000-0000-0000-0000-000000000010', 'regulateur', 'Regulateur C214', '+224620214010');
update public.profiles set role_verified_at = now() where id = 'c2140000-0000-0000-0000-000000000005';
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2140000-0000-0000-0000-000000000001', 'c214-1@test.local', 'Admin C214', 'admin', true);
insert into public.professional_profiles (id, is_verified, verification_status, license_number) values
  ('c2140000-0000-0000-0000-000000000006', false, 'pending', 'LIC-C214-PRO'),
  ('c2140000-0000-0000-0000-000000000007', true, 'verified', 'LIC-C214-PROV');
insert into public.pharmacies (id, name, address, phone, status, manager_id) values
  ('c2140000-0000-0000-0000-0000000000f1', 'Officine C214', 'Conakry', '+224620214099', 'pending',
   'c2140000-0000-0000-0000-000000000009');

\set ADM 'c2140000-0000-0000-0000-000000000001'
\set PAT 'c2140000-0000-0000-0000-000000000002'
\set GRO 'c2140000-0000-0000-0000-000000000003'
\set GRO2 'c2140000-0000-0000-0000-000000000004'
\set LIV 'c2140000-0000-0000-0000-000000000005'
\set PRO 'c2140000-0000-0000-0000-000000000006'
\set PROV 'c2140000-0000-0000-0000-000000000007'
\set PRO0 'c2140000-0000-0000-0000-000000000008'
\set PH 'c2140000-0000-0000-0000-000000000009'
\set REG2 'c2140000-0000-0000-0000-000000000010'

create temp table t_out (c text primary key, state text, msg text);
grant all on t_out to authenticated, anon;

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

-- Résultats de liste, remplis sous l'identité admin.
create temp table t_list (c text, user_id uuid, declared_role text, verification_state text,
  pharmacy_name text, pharmacy_status text, professional_status text, rejection_reason text);
grant all on t_list to authenticated;

-- ==================== Cas 1 : un non-admin est refusé partout ====================
select pg_temp.as_user(:'PAT');
set local role authenticated;
do $$ begin
  perform * from public.admin_list_verification_requests('pending', null);
  insert into t_out values ('1a', 'OK', null);
exception when others then insert into t_out values ('1a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.admin_review_role('c2140000-0000-0000-0000-000000000003', true, null);
  insert into t_out values ('1b', 'OK', null);
exception when others then insert into t_out values ('1b', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000006', true, null);
  insert into t_out values ('1c', 'OK', null);
exception when others then insert into t_out values ('1c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('1a', '42501', true, '; liste refusee');
select pg_temp.expect('1b', '42501',
  (select role_verified_at is null from public.profiles where id = :'GRO'), '; grossiste toujours non valide');
select pg_temp.expect('1c', '42501',
  (select not is_verified from public.professional_profiles where id = :'PRO'), '; professionnel toujours non verifie');

-- ==================== Cas 2 : anon ====================
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform * from public.admin_list_verification_requests('pending', null);
  insert into t_out values ('2', 'OK', null);
exception when others then insert into t_out values ('2', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('2', '42501', true, '; anon refuse');

-- ==================== Cas 3 : liste « à valider » ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
insert into t_list
  select '3', user_id, declared_role, verification_state, pharmacy_name, pharmacy_status, professional_status, rejection_reason
  from public.admin_list_verification_requests('pending', null)
  where user_id::text like 'c2140000-%';
reset role;
select pg_temp.verdict('3',
  (select count(*) filter (where user_id in (:'GRO', :'GRO2', :'PRO', :'PRO0', :'PH', :'REG2')) = 6
      and count(*) filter (where user_id in (:'PAT', :'ADM', :'LIV', :'PROV')) = 0
      and bool_and(verification_state = 'pending')
   from t_list where c = '3')
  and (select pharmacy_name = 'Officine C214' and pharmacy_status = 'pending'
       from t_list where c = '3' and user_id = :'PH')
  and (select professional_status = 'pending' from t_list where c = '3' and user_id = :'PRO')
  and (select professional_status is null from t_list where c = '3' and user_id = :'PRO0'),
  format('%s compte(s) C214 a valider : grossistes, regulateur, professionnels, pharmacien (officine en attente) ; ni patients ni comptes valides',
    (select count(*) from t_list where c = '3')));

-- ==================== Cas 4 : liste « validés » ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
insert into t_list
  select '4', user_id, declared_role, verification_state, pharmacy_name, pharmacy_status, professional_status, rejection_reason
  from public.admin_list_verification_requests('verified', null)
  where user_id::text like 'c2140000-%';
reset role;
select pg_temp.verdict('4',
  (select count(*) = 2 and bool_and(user_id in (:'LIV', :'PROV')) from t_list where c = '4'),
  'livreur valide et professionnel verifie uniquement');

-- ==================== Cas 5 : validation d'un grossiste ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_review_role('c2140000-0000-0000-0000-000000000003', true, null);
  insert into t_out values ('5', 'OK', null);
exception when others then insert into t_out values ('5', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'GRO');
set local role authenticated;
select public.has_verified_role(array['grossiste']) as gro_ok \gset
reset role;
select pg_temp.expect('5', 'OK',
  (select role_verified_at is not null and role_verified_by = :'ADM' from public.profiles where id = :'GRO')
  and :'gro_ok'::boolean
  and exists (select 1 from public.audit_logs where action = 'approve_role' and resource = 'user'
              and resource_id = :'GRO' and user_id = :'ADM' and user_name = 'Admin C214'),
  format('; role_verified_by = ADM, has_verified_role(grossiste) = %s, journal approve_role', :'gro_ok'));

-- ==================== Cas 6 : refus d'un grossiste ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_review_role('c2140000-0000-0000-0000-000000000004', false, '  ');
  insert into t_out values ('6a', 'OK', null);
exception when others then insert into t_out values ('6a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.admin_review_role('c2140000-0000-0000-0000-000000000004', false, 'Agrement introuvable');
  insert into t_out values ('6b', 'OK', null);
exception when others then insert into t_out values ('6b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('6a', '22023', true, '; motif vide refuse');
select pg_temp.expect('6b', 'OK',
  (select role = 'patient' and role_verified_at is null from public.profiles where id = :'GRO2')
  and exists (select 1 from public.audit_logs where action = 'reject_role' and resource_id = :'GRO2'
              and changes->>'role' = 'grossiste' and changes->>'reason' = 'Agrement introuvable'),
  '; compte redevenu patient, role et motif dans le journal');

-- ==================== Cas 7 : review_role sur un rôle non concerné ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_review_role('c2140000-0000-0000-0000-000000000006', true, null);
  insert into t_out values ('7', 'OK', null);
exception when others then insert into t_out values ('7', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('7', '22023',
  (select role_verified_at is null from public.profiles where id = :'PRO'), '; professionnel non concerne');

-- ==================== Cas 8 : vérification d'un professionnel ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000006', true, null);
  insert into t_out values ('8', 'OK', null);
exception when others then insert into t_out values ('8', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PRO');
set local role authenticated;
select public.has_verified_role(array['professionnel']) as pro_ok \gset
reset role;
select pg_temp.expect('8', 'OK',
  (select is_verified and verification_status = 'verified' and rejection_reason is null and updated_by = :'ADM'
     from public.professional_profiles where id = :'PRO')
  and :'pro_ok'::boolean
  and exists (select 1 from public.audit_logs where action = 'verify_professional' and resource_id = :'PRO'),
  format('; is_verified, status verified, has_verified_role(professionnel) = %s, journal', :'pro_ok'));

-- ==================== Cas 9 : rejet d'un professionnel vérifié ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000007', false, null);
  insert into t_out values ('9a', 'OK', null);
exception when others then insert into t_out values ('9a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('9a', '22023',
  (select is_verified from public.professional_profiles where id = :'PROV'), '; rejet sans motif refuse, toujours verifie');
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000007', false, 'Licence expiree');
  insert into t_out values ('9b', 'OK', null);
exception when others then insert into t_out values ('9b', sqlstate, sqlerrm);
end $$;
insert into t_list
  select '9', user_id, declared_role, verification_state, pharmacy_name, pharmacy_status, professional_status, rejection_reason
  from public.admin_list_verification_requests('rejected', null)
  where user_id::text like 'c2140000-%';
reset role;
select pg_temp.expect('9b', 'OK',
  (select not is_verified and verification_status = 'rejected' and rejection_reason = 'Licence expiree'
     from public.professional_profiles where id = :'PROV')
  and (select count(*) = 1 and bool_and(user_id = :'PROV' and rejection_reason = 'Licence expiree')
         from t_list where c = '9'),
  '; verification retiree, motif enregistre, visible dans la liste « refuses »');

-- ==================== Cas 10 : vérification sur un non-professionnel ou sans fiche ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000003', true, null);
  insert into t_out values ('10a', 'OK', null);
exception when others then insert into t_out values ('10a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.admin_verify_professional('c2140000-0000-0000-0000-000000000008', true, null);
  insert into t_out values ('10b', 'OK', null);
exception when others then insert into t_out values ('10b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('10a', '22023', true, '; grossiste : pas un professionnel');
select pg_temp.expect('10b', 'P0002', true, '; professionnel sans fiche');

-- ==================== Cas 11 : recherche d'un patient et attribution du rôle régulateur ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
insert into t_list
  select '11', user_id, declared_role, verification_state, pharmacy_name, pharmacy_status, professional_status, rejection_reason
  from public.admin_list_verification_requests('pending', 'Recherche C214');
do $$ begin
  perform public.admin_set_user_role('c2140000-0000-0000-0000-000000000002', 'regulateur', true);
  insert into t_out values ('11', 'OK', null);
exception when others then insert into t_out values ('11', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'PAT');
set local role authenticated;
select public.has_verified_role(array['regulateur']) as reg_ok \gset
reset role;
select pg_temp.expect('11', 'OK',
  (select count(*) = 1 and bool_and(user_id = :'PAT' and declared_role = 'patient' and verification_state = 'none')
     from t_list where c = '11')
  and :'reg_ok'::boolean
  and exists (select 1 from public.audit_logs where action = 'set_role' and resource_id = :'PAT'
              and changes->>'old_role' = 'patient' and changes->>'role' = 'regulateur'),
  format('; patient trouve par la recherche, regulateur valide (has_verified_role = %s), journal set_role', :'reg_ok'));

-- ==================== Cas 12 : filtre inconnu ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform * from public.admin_list_verification_requests('tous', null);
  insert into t_out values ('12', 'OK', null);
exception when others then insert into t_out values ('12', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('12', '22023', true, '; filtre refuse');

-- ==================== Cas 13 : journal interne non appelable ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  perform public.admin_audit_log('forge', 'x', null);
  insert into t_out values ('13', 'OK', null);
exception when others then insert into t_out values ('13', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('13', '42501',
  not exists (select 1 from public.audit_logs where action = 'forge'), '; admin_audit_log non executable par les clients');

-- ==================== Cas 14 : droits ====================
select pg_temp.verdict('14',
  not has_function_privilege('anon', 'public.admin_list_verification_requests(text, text)', 'execute')
  and not has_function_privilege('anon', 'public.admin_review_role(uuid, boolean, text)', 'execute')
  and not has_function_privilege('anon', 'public.admin_verify_professional(uuid, boolean, text)', 'execute')
  and has_function_privilege('authenticated', 'public.admin_list_verification_requests(text, text)', 'execute')
  and has_function_privilege('authenticated', 'public.admin_review_role(uuid, boolean, text)', 'execute')
  and has_function_privilege('authenticated', 'public.admin_verify_professional(uuid, boolean, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.admin_audit_log(text, text, jsonb)', 'execute'),
  'execute : anon refuse, authenticated accorde (admin_audit_log refuse a tous)');

rollback;
