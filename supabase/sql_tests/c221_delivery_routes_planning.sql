-- C221 (décision D66) : planification des tournées de livraison.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c221_delivery_routes_planning.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- c2210000-…-0000000000xx : 01 PAT patient ; 03 ADM admin GSG ;
--   10 PH pharmacien de Kaloum ; 11 PHD pharmacien de Dixinn ;
--   20 DRV1 (livreur D1, sans chaîne du froid) ; 21 DRV2 (livreur D2, certifié).
insert into auth.users (id, email)
  select ('c2210000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c221-' || n || '@test.local'
  from unnest(array[1,3,10,11,20,21]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2210000-0000-0000-0000-000000000001', 'patient', null, 'PAT'),
  ('c2210000-0000-0000-0000-000000000003', 'patient', null, 'ADM'),
  ('c2210000-0000-0000-0000-000000000010', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH Kaloum'),
  ('c2210000-0000-0000-0000-000000000011', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'PHD Dixinn'),
  ('c2210000-0000-0000-0000-000000000020', 'livreur', null, 'DRV1'),
  ('c2210000-0000-0000-0000-000000000021', 'livreur', null, 'DRV2');
update public.profiles set role_verified_at = now()
  where id in ('c2210000-0000-0000-0000-000000000020', 'c2210000-0000-0000-0000-000000000021');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2210000-0000-0000-0000-000000000003', 'c221-3@test.local', 'Admin C221', 'admin', true);
insert into public.delivery_drivers (id, user_id, name, phone, is_cold_chain_certified) values
  ('c2210000-0000-0000-0000-0000000000d1', 'c2210000-0000-0000-0000-000000000020', 'DRV1', '+224600000120', false),
  ('c2210000-0000-0000-0000-0000000000d2', 'c2210000-0000-0000-0000-000000000021', 'DRV2', '+224600000121', true);
insert into public.reservations (id, patient_id, patient_name, patient_phone, pharmacy_id, pharmacy_name, pharmacy_address, status) values
  ('c2210000-0000-0000-0000-0000000000b1', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101',
   '55555555-5555-5555-5555-555555550001', 'Kaloum', 'Kaloum', 'ready'),
  ('c2210000-0000-0000-0000-0000000000b2', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101',
   '55555555-5555-5555-5555-555555550002', 'Dixinn', 'Dixinn', 'ready');
-- E1, E2, E3 : Kaloum (E3 chaîne du froid) ; E4 : Dixinn ; E5 : Kaloum déjà livrée.
insert into public.deliveries (id, reservation_id, patient_id, patient_name, patient_phone, delivery_address, latitude, longitude, scheduled_at, status, is_cold_chain_required) values
  ('c2210000-0000-0000-0000-0000000000e1', 'c2210000-0000-0000-0000-0000000000b1', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101', 'Adresse 1', 9.61, -13.61, now(), 'scheduled', false),
  ('c2210000-0000-0000-0000-0000000000e2', 'c2210000-0000-0000-0000-0000000000b1', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101', 'Adresse 2', null, null, now(), 'preparing', false),
  ('c2210000-0000-0000-0000-0000000000e3', 'c2210000-0000-0000-0000-0000000000b1', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101', 'Adresse 3', 9.63, -13.63, now(), 'scheduled', true),
  ('c2210000-0000-0000-0000-0000000000e4', 'c2210000-0000-0000-0000-0000000000b2', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101', 'Adresse 4', 9.64, -13.64, now(), 'scheduled', false),
  ('c2210000-0000-0000-0000-0000000000e5', 'c2210000-0000-0000-0000-0000000000b1', 'c2210000-0000-0000-0000-000000000001', 'PAT', '+224600000101', 'Adresse 5', 9.65, -13.65, now(), 'delivered', false);

\set PAT 'c2210000-0000-0000-0000-000000000001'
\set ADM 'c2210000-0000-0000-0000-000000000003'
\set PH 'c2210000-0000-0000-0000-000000000010'
\set PHD 'c2210000-0000-0000-0000-000000000011'
\set DRV1 'c2210000-0000-0000-0000-000000000020'
\set DRV2 'c2210000-0000-0000-0000-000000000021'
\set D1 'c2210000-0000-0000-0000-0000000000d1'
\set D2 'c2210000-0000-0000-0000-0000000000d2'

create temp table t_out (c text primary key, state text, msg text, v uuid);
grant all on t_out to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then raise notice 'CAS % OK : %', p_case, p_detail;
  else raise notice 'CAS % ECHEC : %', p_case, p_detail; end if;
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

create function pg_temp.plan(p_case text, p_driver uuid, p_ids uuid[]) returns void language plpgsql as $$
declare v uuid;
begin
  v := public.delivery_create_route(p_driver, current_date, p_ids);
  insert into t_out values (p_case, 'OK', null, v);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm, null);
end;
$$;

create function pg_temp.cancel(p_case text, p_route uuid) returns void language plpgsql as $$
begin
  perform public.delivery_cancel_route(p_route);
  insert into t_out values (p_case, 'OK', null, null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm, null);
end;
$$;

create function pg_temp.route(p_case text) returns uuid language sql as $$
  select v from t_out where c = p_case
$$;

-- ==================== Création ====================
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.plan('1', :'D1', array['c2210000-0000-0000-0000-0000000000e2', 'c2210000-0000-0000-0000-0000000000e1']::uuid[]);
select pg_temp.plan('2a', :'D1', array['c2210000-0000-0000-0000-0000000000e4']::uuid[]);
select pg_temp.plan('2b', :'D1', array['c2210000-0000-0000-0000-0000000000e1', 'c2210000-0000-0000-0000-0000000000e4']::uuid[]);
select pg_temp.plan('2c', :'D1', array['c2210000-0000-0000-0000-00000000dead']::uuid[]);
select pg_temp.plan('3', :'D1', array['c2210000-0000-0000-0000-0000000000e3']::uuid[]);
select pg_temp.plan('4', :'D2', array['c2210000-0000-0000-0000-0000000000e5']::uuid[]);
select pg_temp.plan('5', :'D2', array['c2210000-0000-0000-0000-0000000000e1']::uuid[]);
select pg_temp.plan('6', :'D2', array['c2210000-0000-0000-0000-0000000000e3', 'c2210000-0000-0000-0000-0000000000e3']::uuid[]);
select pg_temp.plan('7', :'D2', array['c2210000-0000-0000-0000-0000000000e3']::uuid[]);
reset role;

select pg_temp.expect('1', 'OK',
  (select status = 'planned' and driver_id = :'D1' from public.delivery_routes where id = pg_temp.route('1'))
  and (select string_agg(address || '@' || stop_order, ',' order by stop_order) = 'Adresse 2@1,Adresse 1@2'
         from public.route_stops where route_id = pg_temp.route('1'))
  and (select latitude = 9.5 and longitude = -13.7 from public.route_stops
        where route_id = pg_temp.route('1') and delivery_id = 'c2210000-0000-0000-0000-0000000000e2')
  and (select bool_and(driver_id = :'D1') from public.deliveries
        where id in ('c2210000-0000-0000-0000-0000000000e1', 'c2210000-0000-0000-0000-0000000000e2')),
  '; officine : tournee creee dans l''ordre donne, coordonnees inconnues remplacees, livraisons confiees au livreur');
select pg_temp.expect('2a', '42501', true, '; livraison d''une autre officine refusee');
select pg_temp.expect('2b', '42501', true, '; melange avec une livraison d''une autre officine refuse');
select pg_temp.expect('2c', '42501',
  (select msg from t_out where c = '2c') = (select msg from t_out where c = '2a'),
  '; livraison inconnue : meme refus');
select pg_temp.expect('3', '22023', true, '; chaine du froid : livreur non certifie refuse');
select pg_temp.expect('4', '22023', true, '; livraison deja livree refusee');
select pg_temp.expect('5', '22023', true, '; livraison confiee a un autre livreur refusee');
select pg_temp.expect('6', '22023', true, '; livraison en double refusee');
select pg_temp.expect('7', 'OK',
  (select count(*) = 2 from public.delivery_routes),
  '; chaine du froid : livreur certifie accepte');

select pg_temp.as_user(:'PHD'); set local role authenticated;
select pg_temp.plan('8', :'D1', array['c2210000-0000-0000-0000-0000000000e4']::uuid[]);
select pg_temp.plan('8b', :'D1', array['c2210000-0000-0000-0000-0000000000e1']::uuid[]);
reset role;
select pg_temp.expect('8', 'OK', true, '; Dixinn planifie sa propre livraison');
select pg_temp.expect('8b', '42501', true, '; Dixinn ne planifie pas une livraison de Kaloum');

select pg_temp.as_user(:'ADM'); set local role authenticated;
select pg_temp.plan('9', :'D2', array['c2210000-0000-0000-0000-0000000000e1']::uuid[]);
select pg_temp.plan('9b', :'D1', array['c2210000-0000-0000-0000-0000000000e1']::uuid[]);
reset role;
select pg_temp.expect('9b', '22023', (select msg like '%deja dans une tournee en cours%' from t_out where c = '9b'),
  '; meme livreur : livraison deja dans une tournee en cours refusee');
select pg_temp.expect('9', '22023', true, '; livraison deja dans une tournee en cours (et confiee a D1) : refusee, meme pour GSG');

select pg_temp.as_user(:'PAT'); set local role authenticated; select pg_temp.plan('10a', :'D1', array['c2210000-0000-0000-0000-0000000000e4']::uuid[]); reset role;
select pg_temp.as_user(:'DRV1'); set local role authenticated; select pg_temp.plan('10b', :'D1', array['c2210000-0000-0000-0000-0000000000e4']::uuid[]); reset role;
set local role anon;
do $$ begin
  perform public.delivery_create_route('c2210000-0000-0000-0000-0000000000d1', current_date, array['c2210000-0000-0000-0000-0000000000e4']::uuid[]);
  insert into t_out values ('10c', 'OK', null, null);
exception when others then insert into t_out values ('10c', sqlstate, sqlerrm, null);
end $$;
reset role;
select pg_temp.expect('10a', '42501', true, '; patient refuse');
select pg_temp.expect('10b', '42501', true, '; livreur refuse (ne cree pas de tournee)');
select pg_temp.expect('10c', '42501', true, '; anon refuse');

-- ==================== Écritures directes et livreur ====================
select pg_temp.as_user(:'PH'); set local role authenticated;
do $$ begin
  insert into public.delivery_routes (driver_id, date) values ('c2210000-0000-0000-0000-0000000000d1', current_date);
  insert into t_out values ('11a', 'OK', null, null);
exception when others then insert into t_out values ('11a', sqlstate, sqlerrm, null);
end $$;
reset role;
select pg_temp.as_user(:'DRV1'); set local role authenticated;
do $$ begin
  update public.route_stops set address = 'Ailleurs' where route_id = (select v from t_out where c = '1');
  insert into t_out values ('11b', 'OK', null, null);
exception when others then insert into t_out values ('11b', sqlstate, sqlerrm, null);
end $$;
do $$ begin
  update public.route_stops set is_completed = true
   where route_id = (select v from t_out where c = '1') and stop_order = 1;
  update public.delivery_routes set status = 'inProgress' where id = (select v from t_out where c = '1');
  insert into t_out values ('12', 'OK', null, null);
exception when others then insert into t_out values ('12', sqlstate, sqlerrm, null);
end $$;
reset role;
select pg_temp.expect('11a', '42501', true, '; insertion directe d''une tournee refusee');
select pg_temp.expect('11b', '42501', true, '; le livreur ne modifie pas l''adresse d''un arret');
select pg_temp.expect('12', 'OK',
  (select is_completed from public.route_stops where route_id = pg_temp.route('1') and stop_order = 1)
  and (select status = 'inProgress' from public.delivery_routes where id = pg_temp.route('1')),
  '; le livreur coche un arret et demarre sa tournee');

-- ==================== Annulation ====================
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.cancel('13a', pg_temp.route('1'));
select pg_temp.cancel('13b', pg_temp.route('8'));
select pg_temp.cancel('13c', pg_temp.route('7'));
reset role;
select pg_temp.expect('13a', '22023', true, '; tournee commencee : annulation refusee');
select pg_temp.expect('13b', '42501', true, '; tournee d''une autre officine : refus');
select pg_temp.expect('13c', 'OK', (select status = 'cancelled' from public.delivery_routes where id = pg_temp.route('7')),
  '; l''officine annule sa tournee planifiee');

select pg_temp.as_user(:'DRV2'); set local role authenticated;
do $$ begin
  update public.delivery_routes set status = 'planned' where id = (select v from t_out where c = '7');
  insert into t_out values ('13d', 'OK', null, null);
exception when others then insert into t_out values ('13d', sqlstate, sqlerrm, null);
end $$;
reset role;
select pg_temp.verdict('13d', (select status = 'cancelled' from public.delivery_routes where id = pg_temp.route('7')),
  'le livreur ne reactive pas une tournee annulee');

select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.plan('14', :'D2', array['c2210000-0000-0000-0000-0000000000e3']::uuid[]);
reset role;
select pg_temp.expect('14', 'OK', true, '; apres annulation, la livraison peut entrer dans une nouvelle tournee');

select pg_temp.as_user(:'ADM'); set local role authenticated;
select pg_temp.cancel('15', pg_temp.route('8'));
reset role;
select pg_temp.expect('15', 'OK', true, '; GSG annule la tournee de Dixinn');

rollback;
