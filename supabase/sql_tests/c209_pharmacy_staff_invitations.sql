-- C209 : rattachement du personnel non titulaire (décision D59) —
-- invitation par le titulaire, acceptation par l'employé, annulation,
-- retrait, départ, liste du personnel.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c209_pharmacy_staff_invitations.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2090000-…-0000000000xx : 01 T titulaire de Kaloum ; 02 E1 pharmacien libre ;
-- 03 E2 pharmacien libre (téléphone seulement dans auth.users) ; 04 PAT patient ;
-- 05 B pharmacien rattaché à Dixinn ; 06 TK titulaire de Kipé (officine pending) ;
-- 07 E3 pharmacien libre ; 08 TD titulaire de Dixinn ; 09 E4 pharmacien libre.
insert into auth.users (id, email, phone) values
  ('c2090000-0000-0000-0000-000000000001', 'c209-1@test.local', null),
  ('c2090000-0000-0000-0000-000000000002', 'c209-2@test.local', null),
  ('c2090000-0000-0000-0000-000000000003', 'c209-3@test.local', '224620209003'),
  ('c2090000-0000-0000-0000-000000000004', 'c209-4@test.local', null),
  ('c2090000-0000-0000-0000-000000000005', 'c209-5@test.local', null),
  ('c2090000-0000-0000-0000-000000000006', 'c209-6@test.local', null),
  ('c2090000-0000-0000-0000-000000000007', 'c209-7@test.local', null),
  ('c2090000-0000-0000-0000-000000000008', 'c209-8@test.local', null),
  ('c2090000-0000-0000-0000-000000000009', 'c209-9@test.local', null);
insert into public.profiles (id, role, pharmacy_id, full_name, phone) values
  ('c2090000-0000-0000-0000-000000000001', 'pharmacien', null, 'Titulaire T Kaloum', '+224620209001'),
  ('c2090000-0000-0000-0000-000000000002', 'pharmacien', null, 'Employe E1', '+224620209002'),
  ('c2090000-0000-0000-0000-000000000003', 'pharmacien', null, 'Employe E2', null),
  ('c2090000-0000-0000-0000-000000000004', 'patient', null, 'Patient PAT', '+224620209004'),
  ('c2090000-0000-0000-0000-000000000005', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn', '+224620209005'),
  ('c2090000-0000-0000-0000-000000000006', 'pharmacien', null, 'Titulaire TK Kipe', '+224620209006'),
  ('c2090000-0000-0000-0000-000000000007', 'pharmacien', null, 'Employe E3', '+224620209007'),
  ('c2090000-0000-0000-0000-000000000008', 'pharmacien', null, 'Titulaire TD Dixinn', '+224620209008'),
  ('c2090000-0000-0000-0000-000000000009', 'pharmacien', null, 'Employe E4', '+224620209009');
-- Titulaires : le déclencheur C208 rattache T et TD (officines actives), pas TK (pending).
update public.pharmacies set manager_id = 'c2090000-0000-0000-0000-000000000001' where id = '55555555-5555-5555-5555-555555550001';
update public.pharmacies set manager_id = 'c2090000-0000-0000-0000-000000000006' where id = '55555555-5555-5555-5555-555555550005';
update public.pharmacies set manager_id = 'c2090000-0000-0000-0000-000000000008' where id = '55555555-5555-5555-5555-555555550002';

\set T 'c2090000-0000-0000-0000-000000000001'
\set E1 'c2090000-0000-0000-0000-000000000002'
\set E2 'c2090000-0000-0000-0000-000000000003'
\set PAT 'c2090000-0000-0000-0000-000000000004'
\set B 'c2090000-0000-0000-0000-000000000005'
\set TK 'c2090000-0000-0000-0000-000000000006'
\set E3 'c2090000-0000-0000-0000-000000000007'
\set TD 'c2090000-0000-0000-0000-000000000008'
\set E4 'c2090000-0000-0000-0000-000000000009'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set DIXINN '55555555-5555-5555-5555-555555550002'
\set KIPE '55555555-5555-5555-5555-555555550005'

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

create function pg_temp.pid(u uuid) returns text language sql as $$
  select coalesce((select pharmacy_id::text from public.profiles where id = u), 'null')
$$;

create function pg_temp.inv_status(p_pharmacy uuid, u uuid) returns text language sql as $$
  select coalesce(string_agg(status, ',' order by created_at), 'aucune')
    from public.pharmacy_staff_invitations where pharmacy_id = p_pharmacy and invited_user_id = u
$$;

select pg_temp.verdict('0', pg_temp.pid(:'T') = :'KALOUM' and pg_temp.pid(:'TD') = :'DIXINN' and pg_temp.pid(:'TK') = 'null',
  'prealable : T et TD rattaches par C208, TK (officine pending) non rattache');

-- ==================== Cas 1 : invitation de E1 (numéro saisi avec espaces et tirets) ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E1', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224 620-209-002')::text);
  insert into t_out values ('1', 'OK', null);
exception when others then insert into t_out values ('1', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('1', 'OK',
  pg_temp.inv_status(:'KALOUM', :'E1') = 'pending' and pg_temp.pid(:'E1') = 'null',
  format('; invitation %s, E1 pas encore rattache', pg_temp.inv_status(:'KALOUM', :'E1')));

-- ==================== Cas 2 : invitations refusées ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209002');
  insert into t_out values ('2a', 'OK', null);
exception when others then insert into t_out values ('2a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209004');
  insert into t_out values ('2b', 'OK', null);
exception when others then insert into t_out values ('2b', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209005');
  insert into t_out values ('2c', 'OK', null);
exception when others then insert into t_out values ('2c', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224699999999');
  insert into t_out values ('2d', 'OK', null);
exception when others then insert into t_out values ('2d', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209001');
  insert into t_out values ('2e', 'OK', null);
exception when others then insert into t_out values ('2e', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '12');
  insert into t_out values ('2f', 'OK', null);
exception when others then insert into t_out values ('2f', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('2a', '22023', true, '; deja en attente');
select pg_temp.expect('2b', '22023', true, '; patient');
select pg_temp.expect('2c', '22023', true, '; deja rattache a Dixinn');
select pg_temp.expect('2d', 'P0002', true, '; numero inconnu');
select pg_temp.expect('2e', '22023', true, '; le titulaire lui-meme');
select pg_temp.expect('2f', '22023', true, '; numero invalide');

-- ==================== Cas 3 : seuls les titulaires d'une officine validée invitent ====================
select pg_temp.as_user(:'E1');
set local role authenticated;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209007');
  insert into t_out values ('3a', 'OK', null);
exception when others then insert into t_out values ('3a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'TK');
set local role authenticated;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550005', '+224620209007');
  insert into t_out values ('3b', 'OK', null);
exception when others then insert into t_out values ('3b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('3a', '42501', true, '; employe non titulaire');
select pg_temp.expect('3b', '42501', pg_temp.inv_status(:'KIPE', :'E3') = 'aucune', '; titulaire d''une officine pending');

-- ==================== Cas 4 : E1 voit son invitation, puis l'accepte ====================
select pg_temp.as_user(:'E1');
set local role authenticated;
select count(*) as e1_inv, max(pharmacy_name) as e1_ph, max(invited_by_name) as e1_by
  from public.pharmacy_my_invitations() \gset
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E1'), true);
  insert into t_out values ('4', 'OK', null);
exception when others then insert into t_out values ('4', sqlstate, sqlerrm);
end $$;
select public.is_pharmacy_staff('55555555-5555-5555-5555-555555550001') as e1_staff,
       public.has_verified_role(array['pharmacien']) as e1_verified \gset
reset role;
select pg_temp.verdict('4-liste', :'e1_inv' = '1' and :'e1_ph' = 'Pharmacie Kaloum Centrale' and :'e1_by' = 'Titulaire T Kaloum',
  format('E1 voit %s invitation : %s, par %s', :'e1_inv', :'e1_ph', :'e1_by'));
select pg_temp.expect('4', 'OK',
  pg_temp.pid(:'E1') = :'KALOUM' and :'e1_staff'::boolean and :'e1_verified'::boolean
  and pg_temp.inv_status(:'KALOUM', :'E1') = 'accepted',
  format('; E1 rattache a Kaloum, is_pharmacy_staff = %s, has_verified_role(pharmacien) = %s', :'e1_staff', :'e1_verified'));

-- ==================== Cas 5 : une réponse ne se donne qu'une fois, et seulement par l'invité ====================
select pg_temp.as_user(:'E1');
set local role authenticated;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E1'), true);
  insert into t_out values ('5a', 'OK', null);
exception when others then insert into t_out values ('5a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E2', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '224620209003')::text);
end $$;
reset role;
select pg_temp.as_user(:'E3');
set local role authenticated;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E2'), true);
  insert into t_out values ('5b', 'OK', null);
exception when others then insert into t_out values ('5b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('5a', '22023', true, '; deja acceptee');
select pg_temp.expect('5b', 'P0002',
  pg_temp.pid(:'E3') = 'null' and pg_temp.inv_status(:'KALOUM', :'E2') = 'pending',
  '; E3 ne peut pas repondre a l''invitation de E2 (retrouve par le telephone de auth.users)');

-- ==================== Cas 6 : E2 refuse ====================
select pg_temp.as_user(:'E2');
set local role authenticated;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E2'), false);
  insert into t_out values ('6', 'OK', null);
exception when others then insert into t_out values ('6', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('6', 'OK', pg_temp.pid(:'E2') = 'null' and pg_temp.inv_status(:'KALOUM', :'E2') = 'declined',
  '; E2 non rattache, invitation declined');

-- ==================== Cas 7 : annulation par le titulaire ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E2B', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '224620209003')::text);
  perform public.pharmacy_cancel_invitation((select v::uuid from t_ctx where k = 'INV_E2B'));
  insert into t_out values ('7', 'OK', null);
exception when others then insert into t_out values ('7', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'E2');
set local role authenticated;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E2B'), true);
  insert into t_out values ('7-apres', 'OK', null);
exception when others then insert into t_out values ('7-apres', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('7', 'OK', pg_temp.inv_status(:'KALOUM', :'E2') = 'declined,cancelled', '; nouvelle invitation annulee');
select pg_temp.expect('7-apres', '22023', pg_temp.pid(:'E2') = 'null', '; acceptation d''une invitation annulee refusee');

-- ==================== Cas 8 : liste du personnel ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E3', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209007')::text);
end $$;
create temp table t_staff as select * from public.pharmacy_list_staff('55555555-5555-5555-5555-555555550001');
reset role;
select pg_temp.verdict('8',
  (select count(*) = 1 from t_staff where kind = 'member' and user_id = :'T' and is_manager)
  and (select count(*) = 1 from t_staff where kind = 'member' and user_id = :'E1' and not is_manager and invitation_id is not null)
  and (select count(*) = 1 from t_staff where kind = 'invitation' and user_id = :'E3' and status = 'pending')
  and (select count(*) = 3 from t_staff)
  and (select kind = 'member' and is_manager from t_staff limit 1),
  format('titulaire en tete, E1 membre, E3 invite (%s lignes)', (select count(*) from t_staff)));

-- ==================== Cas 9 : cloisonnement ====================
select pg_temp.as_user(:'B');
set local role authenticated;
do $$ begin
  perform * from public.pharmacy_list_staff('55555555-5555-5555-5555-555555550001');
  insert into t_out values ('9a', 'OK', null);
exception when others then insert into t_out values ('9a', sqlstate, sqlerrm);
end $$;
select count(*) as b_sees from public.pharmacy_staff_invitations where pharmacy_id = :'KALOUM' \gset
do $$ begin
  insert into public.pharmacy_staff_invitations (pharmacy_id, invited_user_id, status)
    values ('55555555-5555-5555-5555-555555550001', 'c2090000-0000-0000-0000-000000000005', 'accepted');
  insert into t_out values ('9b', 'OK', null);
exception when others then insert into t_out values ('9b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'E1');
set local role authenticated;
select count(*) as e1_sees from public.pharmacy_staff_invitations \gset
reset role;
select pg_temp.expect('9a', '42501', true, '; B (autre officine) ne liste pas le personnel de Kaloum');
select pg_temp.verdict('9-lecture', :'b_sees' = '0' and :'e1_sees' = '1',
  format('lecture directe : B voit %s invitation(s) de Kaloum, E1 voit seulement la sienne (%s)', :'b_sees', :'e1_sees'));
select pg_temp.expect('9b', '42501', true, '; insertion directe refusee (aucune policy d''ecriture)');

-- ==================== Cas 10 : accepter annule les autres invitations ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E4_K', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209009')::text);
end $$;
reset role;
select pg_temp.as_user(:'TD');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('INV_E4_D', public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550002', '+224620209009')::text);
end $$;
reset role;
select pg_temp.as_user(:'E4');
set local role authenticated;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E4_K'), true);
  insert into t_out values ('10', 'OK', null);
exception when others then insert into t_out values ('10', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_respond_invitation((select v::uuid from t_ctx where k = 'INV_E4_D'), true);
  insert into t_out values ('10-dixinn', 'OK', null);
exception when others then insert into t_out values ('10-dixinn', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('10', 'OK',
  pg_temp.pid(:'E4') = :'KALOUM' and pg_temp.inv_status(:'DIXINN', :'E4') = 'cancelled',
  '; E4 rattache a Kaloum, invitation de Dixinn annulee');
select pg_temp.expect('10-dixinn', '22023', pg_temp.pid(:'E4') = :'KALOUM', '; invitation de Dixinn plus acceptable');

-- ==================== Cas 11 : retrait par le titulaire ====================
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  perform public.pharmacy_remove_staff('55555555-5555-5555-5555-555555550001', 'c2090000-0000-0000-0000-000000000002');
  insert into t_out values ('11', 'OK', null);
exception when others then insert into t_out values ('11', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_remove_staff('55555555-5555-5555-5555-555555550001', 'c2090000-0000-0000-0000-000000000001');
  insert into t_out values ('11-soi', 'OK', null);
exception when others then insert into t_out values ('11-soi', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pharmacy_remove_staff('55555555-5555-5555-5555-555555550001', 'c2090000-0000-0000-0000-000000000005');
  insert into t_out values ('11-autre', 'OK', null);
exception when others then insert into t_out values ('11-autre', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'E1');
set local role authenticated;
select public.is_pharmacy_staff('55555555-5555-5555-5555-555555550001') as e1_staff_after \gset
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1000, 0, 0, 1000,
    '[{"product_name":"X","quantity":1,"unit_price":1000,"total_price":1000}]'::jsonb);
  insert into t_out values ('11-vente', 'OK', null);
exception when others then insert into t_out values ('11-vente', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('11', 'OK',
  pg_temp.pid(:'E1') = 'null' and not :'e1_staff_after'::boolean and pg_temp.inv_status(:'KALOUM', :'E1') = 'revoked',
  '; E1 detache, invitation revoked');
select pg_temp.expect('11-soi', '22023', pg_temp.pid(:'T') = :'KALOUM', '; le titulaire ne se retire pas');
select pg_temp.expect('11-autre', 'P0002', pg_temp.pid(:'B') = :'DIXINN', '; B ne fait pas partie de Kaloum');
select pg_temp.expect('11-vente', '42501', true, '; E1 retire ne vend plus pour Kaloum');

-- ==================== Cas 12 : départ volontaire ====================
select pg_temp.as_user(:'E4');
set local role authenticated;
do $$ begin
  perform public.pharmacy_leave();
  insert into t_out values ('12', 'OK', null);
exception when others then insert into t_out values ('12', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'T');
set local role authenticated;
do $$ begin
  perform public.pharmacy_leave();
  insert into t_out values ('12-titulaire', 'OK', null);
exception when others then insert into t_out values ('12-titulaire', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('12', 'OK', pg_temp.pid(:'E4') = 'null' and pg_temp.inv_status(:'KALOUM', :'E4') = 'left', '; E4 a quitte Kaloum');
select pg_temp.expect('12-titulaire', '22023', pg_temp.pid(:'T') = :'KALOUM', '; le titulaire ne quitte pas son officine');

-- ==================== Cas 13 : le verrou C211 tient toujours ====================
select pg_temp.as_user(:'E2');
set local role authenticated;
do $$ begin
  update public.profiles set pharmacy_id = '55555555-5555-5555-5555-555555550001' where id = auth.uid();
  insert into t_out values ('13', 'OK', null);
exception when others then insert into t_out values ('13', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('13', '42501', pg_temp.pid(:'E2') = 'null', '; rattachement direct toujours refuse');

-- ==================== Cas 14 : droits ====================
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform public.pharmacy_invite_staff('55555555-5555-5555-5555-555555550001', '+224620209003');
  insert into t_out values ('14', 'OK', null);
exception when others then insert into t_out values ('14', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('14', '42501', true, '; anon refuse');
select pg_temp.verdict('14-droits',
  not has_function_privilege('anon', 'public.pharmacy_invite_staff(uuid, text)', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_respond_invitation(uuid, boolean)', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_cancel_invitation(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_remove_staff(uuid, uuid)', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_leave()', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_list_staff(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.pharmacy_my_invitations()', 'execute')
  and has_function_privilege('authenticated', 'public.pharmacy_invite_staff(uuid, text)', 'execute')
  and has_function_privilege('authenticated', 'public.pharmacy_respond_invitation(uuid, boolean)', 'execute'),
  'execute : anon refuse sur les 7 fonctions, authenticated accorde');

rollback;
