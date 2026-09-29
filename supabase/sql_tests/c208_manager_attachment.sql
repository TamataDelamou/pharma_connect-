-- C208 : rattachement du titulaire (pharmacies.manager_id) à son officine
-- (profiles.pharmacy_id). Chaque cas affiche « CAS n OK : … » ou
-- « CAS n ECHEC : … ».
--
-- Titulaires M1 à M7 : profils 'pharmacien' créés sans pharmacy_id.
-- Officines créées dans la transaction (en tant que postgres, comme le
-- back-office).
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c208_manager_attachment.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

insert into auth.users (id, email)
  select ('a2080000-0000-0000-0000-00000000000' || n)::uuid, 'c208-m' || n || '@test.local'
  from generate_series(1, 7) n;
insert into public.profiles (id, role, pharmacy_id, full_name)
  select ('a2080000-0000-0000-0000-00000000000' || n)::uuid, 'pharmacien', null, 'Titulaire M' || n
  from generate_series(1, 7) n;

\set M1 'a2080000-0000-0000-0000-000000000001'
\set M2 'a2080000-0000-0000-0000-000000000002'
\set M3 'a2080000-0000-0000-0000-000000000003'
\set M4 'a2080000-0000-0000-0000-000000000004'
\set M5 'a2080000-0000-0000-0000-000000000005'
\set M6 'a2080000-0000-0000-0000-000000000006'
\set M7 'a2080000-0000-0000-0000-000000000007'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set X 'c2080000-0000-0000-0000-00000000000a'
\set P 'c2080000-0000-0000-0000-00000000000b'
\set Y 'c2080000-0000-0000-0000-00000000000c'
\set Z 'c2080000-0000-0000-0000-00000000000d'
\set W 'c2080000-0000-0000-0000-00000000000e'

create temp table t_out (c text primary key, state text, msg text);
grant all on t_out to authenticated;

create function pg_temp.pid(u uuid) returns text language sql as $$
  select coalesce((select pharmacy_id::text from public.profiles where id = u), 'null')
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then
    raise notice 'CAS % OK : %', p_case, p_detail;
  else
    raise notice 'CAS % ECHEC : %', p_case, p_detail;
  end if;
end;
$$;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- ==================== Cas 1 : insertion directe 'active' ====================
insert into public.pharmacies (id, name, address, phone, status, manager_id)
  values (:'X', 'Officine X (C208)', 'Conakry', '+224620000001', 'active', :'M1');
select pg_temp.verdict('1', pg_temp.pid(:'M1') = :'X',
  format('officine X inseree active avec M1 : M1.pharmacy_id = %s (X)', pg_temp.pid(:'M1')));

-- ==================== Cas 2 : changement de titulaire ====================
update public.pharmacies set manager_id = :'M2' where id = :'X';
select pg_temp.verdict('2', pg_temp.pid(:'M2') = :'X' and pg_temp.pid(:'M1') = 'null',
  format('X : M1 -> M2 ; M2.pharmacy_id = %s, M1.pharmacy_id = %s', pg_temp.pid(:'M2'), pg_temp.pid(:'M1')));

-- ==================== Cas 3 : l'ancien titulaire est refusé par pos_create_sale ====================
select pg_temp.as_user(:'M1');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('c2080000-0000-0000-0000-00000000000a', 'cash', 1000, 0, 0, 1000,
    '[{"product_name":"Test C208","quantity":1,"unit_price":1000,"total_price":1000}]'::jsonb);
exception when others then insert into t_out values ('3', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.verdict('3',
  (select state = '42501' from t_out where c = '3') and (select count(*) = 0 from public.pos_sales where pharmacy_id = :'X'),
  coalesce((select format('M1 (ancien titulaire) : %s « %s », aucune vente', state, msg) from t_out where c = '3'), 'aucune exception'));

-- Contrôle complémentaire : le nouveau titulaire M2 est bien reconnu.
select pg_temp.as_user(:'M2');
select public.is_pharmacy_staff(:'X') as m2_staff \gset
select pg_temp.verdict('3-nouveau', :'m2_staff'::boolean, format('is_pharmacy_staff(X) pour M2 = %s', :'m2_staff'));
select set_config('request.jwt.claims', '', true);

-- ==================== Cas 4 : officine 'pending' ====================
insert into public.pharmacies (id, name, address, phone, status, manager_id)
  values (:'P', 'Officine P (C208)', 'Conakry', '+224620000002', 'pending', :'M3');
select pg_temp.pid(:'M3') as m3_after_insert \gset
update public.pharmacies set manager_id = :'M4' where id = :'P';
select pg_temp.verdict('4', :'m3_after_insert' = 'null' and pg_temp.pid(:'M3') = 'null' and pg_temp.pid(:'M4') = 'null',
  format('P pending : insertion avec M3 -> M3 = %s ; titulaire change en M4 -> M3 = %s, M4 = %s',
         :'m3_after_insert', pg_temp.pid(:'M3'), pg_temp.pid(:'M4')));

-- ==================== Cas 5 : pending -> active (comportement d'origine conservé) ====================
update public.pharmacies set status = 'active', license_verified_at = null where id = :'P';
select pg_temp.verdict('5',
  pg_temp.pid(:'M4') = :'P' and (select license_verified_at is not null from public.pharmacies where id = :'P'),
  format('P active : M4.pharmacy_id = %s, license_verified_at renseigne = %s', pg_temp.pid(:'M4'),
         (select license_verified_at is not null from public.pharmacies where id = :'P')));

-- ==================== Cas 6 : ancien titulaire rattaché ailleurs, non détaché ====================
insert into public.pharmacies (id, name, address, phone, status, manager_id)
  values (:'Y', 'Officine Y (C208)', 'Conakry', '+224620000003', 'active', :'M5');
update public.profiles set pharmacy_id = :'KALOUM' where id = :'M5';   -- M5 devenu personnel de Kaloum
update public.pharmacies set manager_id = :'M3' where id = :'Y';
select pg_temp.verdict('6', pg_temp.pid(:'M5') = :'KALOUM' and pg_temp.pid(:'M3') = :'Y',
  format('Y : M5 -> M3 ; M5 (rattache a Kaloum) garde %s, M3 = %s', pg_temp.pid(:'M5'), pg_temp.pid(:'M3')));

-- ==================== Cas 7 : rattrapage ====================
-- Base où un titulaire est non rattaché : officines insérées actives sans le
-- déclencheur d'insertion (situation d'avant C208).
alter table public.pharmacies disable trigger trigger_link_pharmacy_manager_insert;
insert into public.pharmacies (id, name, address, phone, status, manager_id) values
  (:'Z', 'Officine Z (C208)', 'Conakry', '+224620000004', 'active', :'M6'),
  (:'W', 'Officine W (C208)', 'Conakry', '+224620000005', 'verified', :'M7');
alter table public.pharmacies enable trigger trigger_link_pharmacy_manager_insert;
update public.profiles set pharmacy_id = :'KALOUM' where id = :'M7';   -- valeur différente, à ne pas écraser
select pg_temp.pid(:'M6') as m6_before \gset
select public.attach_unlinked_pharmacy_managers() as attached \gset
select pg_temp.verdict('7',
  :'m6_before' = 'null' and :attached = 1 and pg_temp.pid(:'M6') = :'Z' and pg_temp.pid(:'M7') = :'KALOUM',
  format('avant : M6 = %s ; rattrapage : %s rattache(s) ; M6 = %s (Z), M7 garde %s (Kaloum, signale par notice)',
         :'m6_before', :attached, pg_temp.pid(:'M6'), pg_temp.pid(:'M7')));

-- ==================== Cas 8 : rattrapage réservé à l'administration ====================
select pg_temp.verdict('8',
  not has_function_privilege('authenticated', 'public.attach_unlinked_pharmacy_managers()', 'execute')
  and not has_function_privilege('anon', 'public.attach_unlinked_pharmacy_managers()', 'execute'),
  'execute sur attach_unlinked_pharmacy_managers() : anon et authenticated refuses');

rollback;
