-- C273 (c) : rectification d'une caisse fermée, et dépôts et retraits
-- (motif obligatoire ; après la première vente, titulaire seul).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c273_cash_rectification.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- C : caissier de Kaloum. T : titulaire de Kaloum. A : pharmacien d'une
-- autre officine.
insert into auth.users (id, email) values
  ('c2730000-0000-0000-0000-00000000000c', 'c273-c@test.local'),
  ('c2730000-0000-0000-0000-00000000000f', 'c273-t@test.local'),
  ('c2730000-0000-0000-0000-00000000000a', 'c273-a@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2730000-0000-0000-0000-00000000000c', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Caissier Kaloum'),
  ('c2730000-0000-0000-0000-00000000000f', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Titulaire Kaloum'),
  ('c2730000-0000-0000-0000-00000000000a', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien autre officine');
update public.pharmacies set manager_id = 'c2730000-0000-0000-0000-00000000000f'
  where id = '55555555-5555-5555-5555-555555550001';

\set C 'c2730000-0000-0000-0000-00000000000c'
\set T 'c2730000-0000-0000-0000-00000000000f'
\set A 'c2730000-0000-0000-0000-00000000000a'
\set PH '55555555-5555-5555-5555-555555550001'

create temp table t_out (c text primary key, state text, msg text);
create temp table t_ids (k text primary key, id uuid);
grant all on t_out, t_ids to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- Exécute [p_sql] ; enregistre « OK » ou le code d'erreur et son message.
create function pg_temp.run(p_case text, p_sql text) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
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

create function pg_temp.msg(p_case text) returns text language sql as $$
  select coalesce(msg, '') from t_out where c = p_case
$$;
create function pg_temp.sid() returns uuid language sql as $$
  select id from t_ids where k = 'session'
$$;
create function pg_temp.moves(p_type text) returns bigint language sql as $$
  select count(*) from public.cash_movements where cash_drawer_session_id = pg_temp.sid() and type = p_type
$$;

set local role authenticated;

-- 1 : le caissier ouvre sa caisse avec un fonds de 10 000.
select pg_temp.as_user(:'C');
insert into t_ids values ('session', public.open_cash_drawer(:'PH', :'C', 10000, null));
select pg_temp.verdict('1', pg_temp.sid() is not null, 'caisse ouverte, fonds 10 000');

-- 2 : dépôt sans motif : refusé (nouveau).
select pg_temp.run('2', format('select public.cash_add_movement(%L, %L, 2000, null)', pg_temp.sid(), 'deposit'));
select pg_temp.expect('2', '22023', pg_temp.msg('2') like '%motif obligatoire%', '; motif absent refuse');
select pg_temp.run('2b', format('select public.cash_add_movement(%L, %L, 2000, %L)', pg_temp.sid(), 'deposit', '   '));
select pg_temp.expect('2b', '22023', pg_temp.msg('2b') like '%motif obligatoire%', '; motif vide refuse');

-- 3 : avant la première vente, le caissier corrige le fonds (dépôt de 2 000).
select pg_temp.run('3', format('select public.cash_add_movement(%L, %L, 2000, %L)', pg_temp.sid(), 'deposit', 'Correction du fonds de caisse'));
select pg_temp.expect('3', 'OK', pg_temp.moves('deposit') = 1, '; correction du fonds par le caissier acceptee');

-- 4 : une vente en espèces de 1 500 est enregistrée dans la session.
reset role;
insert into public.cash_movements (cash_drawer_session_id, type, amount, payment_method, notes, created_by)
  values (pg_temp.sid(), 'sale', 1500, 'cash', 'Vente C273', :'C');
set local role authenticated;
select pg_temp.as_user(:'C');

-- 5 : après la vente, le caissier ne peut plus déposer ni retirer (nouveau).
select pg_temp.run('5', format('select public.cash_add_movement(%L, %L, 500, %L)', pg_temp.sid(), 'withdrawal', 'Monnaie'));
select pg_temp.expect('5', '42501', pg_temp.msg('5') like '%reserve au titulaire%' and pg_temp.moves('withdrawal') = 0,
  '; retrait du caissier apres une vente refuse');

-- 6 : le titulaire le peut, avec un motif.
select pg_temp.as_user(:'T');
select pg_temp.run('6', format('select public.cash_add_movement(%L, %L, 500, %L)', pg_temp.sid(), 'deposit', 'Erreur de saisie du caissier'));
select pg_temp.expect('6', 'OK', pg_temp.moves('deposit') = 2, '; depot du titulaire apres une vente accepte');

-- 7 : le titulaire aussi doit donner un motif.
select pg_temp.run('7', format('select public.cash_add_movement(%L, %L, 500, %L)', pg_temp.sid(), 'deposit', ''));
select pg_temp.expect('7', '22023', pg_temp.msg('7') like '%motif obligatoire%', '; motif vide refuse au titulaire');

-- 8 : pharmacien d'une autre officine : refusé (contrôle existant).
select pg_temp.as_user(:'A');
select pg_temp.run('8', format('select public.cash_add_movement(%L, %L, 500, %L)', pg_temp.sid(), 'deposit', 'Essai'));
select pg_temp.expect('8', '42501', true, '; autre officine refusee');

-- 9 : une caisse ouverte ne se rectifie pas.
select pg_temp.as_user(:'T');
select pg_temp.run('9', format('select public.cash_rectify_closing(%L, 14000, %L)', pg_temp.sid(), 'Essai'));
select pg_temp.expect('9', '22023', pg_temp.msg('9') like '%seule une caisse fermee%', '; rectification d''une caisse ouverte refusee');

-- 10 : le caissier ferme en saisissant 11 000 par erreur (attendu 14 000 :
-- 10 000 + 2 000 + 1 500 + 500).
select pg_temp.as_user(:'C');
select public.close_cash_drawer(pg_temp.sid(), 11000, null);
select pg_temp.verdict('10',
  (select status = 'closed' and closing_balance = 11000 and expected_balance = 14000 and difference = -3000
   from public.cash_drawer_sessions where id = pg_temp.sid()),
  'caisse fermee : compte 11 000, attendu 14 000, ecart -3 000');

-- 11 : le caissier ne peut pas rectifier.
select pg_temp.run('11', format('select public.cash_rectify_closing(%L, 14000, %L)', pg_temp.sid(), 'Erreur de saisie'));
select pg_temp.expect('11', '42501', pg_temp.msg('11') like '%reservee au titulaire%', '; rectification par le caissier refusee');

-- 12 : le titulaire, sans motif : refusé.
select pg_temp.as_user(:'T');
select pg_temp.run('12', format('select public.cash_rectify_closing(%L, 14000, %L)', pg_temp.sid(), ' '));
select pg_temp.expect('12', '22023', pg_temp.msg('12') like '%motif obligatoire%', '; rectification sans motif refusee');

-- 13 : montant négatif : refusé.
select pg_temp.run('13', format('select public.cash_rectify_closing(%L, -1, %L)', pg_temp.sid(), 'Erreur'));
select pg_temp.expect('13', '22023', pg_temp.msg('13') like '%montant compte invalide%', '; montant negatif refuse');

-- 14 : le titulaire rectifie à 14 000 ; la session n'est pas modifiée.
select pg_temp.run('14', format('select public.cash_rectify_closing(%L, 14000, %L)', pg_temp.sid(), 'Erreur de saisie a la fermeture'));
select pg_temp.expect('14', 'OK',
  (select previous_counted_balance = 11000 and counted_balance = 14000 and expected_balance = 14000
          and difference = 0 and created_by = :'T'::uuid and reason = 'Erreur de saisie a la fermeture'
     from public.cash_drawer_rectifications where cash_drawer_session_id = pg_temp.sid())
  and (select closing_balance = 11000 and difference = -3000 and status = 'closed'
         from public.cash_drawer_sessions where id = pg_temp.sid()),
  '; rectification 11 000 -> 14 000, ecart 0 ; session inchangee (11 000, -3 000)');

-- 15 : une deuxième rectification part de la précédente.
select pg_temp.run('15', format('select public.cash_rectify_closing(%L, 13900, %L)', pg_temp.sid(), 'Recompte'));
select pg_temp.expect('15', 'OK',
  (select previous_counted_balance = 14000 and difference = -100
     from public.cash_drawer_rectifications
    where cash_drawer_session_id = pg_temp.sid() and counted_balance = 13900),
  '; deuxieme rectification : 14 000 -> 13 900, ecart -100');

-- 16 : le résumé donne la dernière rectification ; le reste est inchangé.
select pg_temp.verdict('16',
  (select rectified_closing_balance = 13900 and rectified_difference = -100 and rectification_count = 2
          and closing_balance = 11000 and difference = -3000 and total_deposits = 2500
          and total_sales = 1500 and opening_balance = 10000
     from public.cash_summary where session_id = pg_temp.sid()),
  'cash_summary : rectifie 13 900 (ecart -100, 2 rectifications) ; fermeture d''origine 11 000 (-3 000) visible');

-- 17 : aucune écriture directe dans les rectifications, ni modification de
-- la session par le titulaire.
select pg_temp.run('17', format(
  'insert into public.cash_drawer_rectifications (cash_drawer_session_id, previous_counted_balance, counted_balance, expected_balance, difference, reason, created_by) values (%L, 0, 1, 0, 1, %L, %L)',
  pg_temp.sid(), 'Direct', :'T'));
select pg_temp.expect('17', '42501', true, '; insertion directe refusee');
select pg_temp.run('17b', format('update public.cash_drawer_rectifications set counted_balance = 0 where cash_drawer_session_id = %L', pg_temp.sid()));
select pg_temp.run('17c', format('delete from public.cash_drawer_rectifications where cash_drawer_session_id = %L', pg_temp.sid()));
select pg_temp.verdict('17b',
  (select state from t_out where c = '17b') = '42501' and (select state from t_out where c = '17c') = '42501'
  and (select count(*) = 2 from public.cash_drawer_rectifications where cash_drawer_session_id = pg_temp.sid()),
  'modification et suppression directes refusees ; les 2 rectifications restent');

-- 18 : pharmacien d'une autre officine : ne voit pas les rectifications.
select pg_temp.as_user(:'A');
select pg_temp.verdict('18',
  (select count(*) = 0 from public.cash_drawer_rectifications where cash_drawer_session_id = pg_temp.sid()),
  'rectifications invisibles depuis une autre officine');

-- 19 : sans compte : la fonction n'est pas appelable.
reset role;
set local role anon;
select pg_temp.run('19', format('select public.cash_rectify_closing(%L, 1, %L)', pg_temp.sid(), 'Anonyme'));
select pg_temp.expect('19', '42501', true, '; appel sans compte refuse');

reset role;
rollback;
