-- C242 : disponibilité montrée aux patients (patient_stock_availability) :
-- lots rappelés et périmés exclus, quantité réservée déduite, officines
-- actives seulement, aucun détail de lot révélé.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c242_patient_stock_availability.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- P : patient, sans officine.
insert into auth.users (id, email) values
  ('c2420000-0000-0000-0000-000000000001', 'c242-p@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2420000-0000-0000-0000-000000000001', 'patient', null, 'Patient P');

-- Paracétamol à Kaloum : prix 1 500. Lots du seed vidés ; trois lots de test :
--   R1 (C242-R1, 10 unités) : le lot visé par les rappels ;
--   B1 (C242-B1, 5 unités dont 2 réservées) : un lot sain ;
--   E1 (C242-E1, 7 unités) : un lot périmé depuis hier.
update public.stock_items set unit_price = 1500, status = 'inStock'
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001';
update public.stock_batches b set quantity = 0, quantity_reserved = 0
  from public.stock_items si
  where si.id = b.stock_item_id
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select v.id::uuid, si.id, v.num, current_date - 100, current_date + v.days, v.qty, v.res, now()
  from public.stock_items si,
       (values ('c2420000-0000-0000-0000-0000000000a1', 'C242-R1', 20, 10, 0),
               ('c2420000-0000-0000-0000-0000000000b1', 'C242-B1', 60, 5, 2),
               ('c2420000-0000-0000-0000-0000000000e1', 'C242-E1', -1, 7, 0)) as v(id, num, days, qty, res)
  where si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';

\set P 'c2420000-0000-0000-0000-000000000001'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set DIXINN '55555555-5555-5555-5555-555555550002'
\set PARA '33333333-3333-3333-3333-333333330001'
\set RECALL 'c2420000-0000-0000-0000-0000000000c1'

create temp table t_out (c text primary key, state text, msg text);
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

create function pg_temp.expect(p_case text, p_state text, p_detail text default '') returns void language plpgsql as $$
declare o record;
begin
  select * into o from t_out where c = p_case;
  if o is null then
    raise notice 'CAS % ECHEC : bloc non execute', p_case;
  elsif o.state = p_state then
    raise notice 'CAS % OK : % %', p_case, o.state || coalesce(' « ' || o.msg || ' »', ''), p_detail;
  else
    raise notice 'CAS % ECHEC : obtenu % (attendu %) %', p_case, o.state || coalesce(' « ' || o.msg || ' »', ''), p_state, p_detail;
  end if;
end;
$$;

-- Disponible vu par le patient P pour le Paracétamol à Kaloum ; -1 si
-- l'officine n'apparaît pas dans le résultat.
create function pg_temp.avail() returns int language sql as $$
  select coalesce((
    select available_quantity
      from public.patient_stock_availability(array['33333333-3333-3333-3333-333333330001']::uuid[])
      where pharmacy_id = '55555555-5555-5555-5555-555555550001'), -1)
$$;

-- ==================== Sans rappel ====================
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a1 \gset
select unit_price as price1 from public.patient_stock_availability(array[:'PARA']::uuid[]) where pharmacy_id = :'KALOUM' \gset
select count(*) as lots_vus from public.stock_batches where batch_number like 'C242-%' \gset
reset role;
select pg_temp.verdict('1', :a1 = 13 and :price1 = 1500,
  'sans rappel : disponible ' || :a1 || ' (R1 10 + B1 5 - 2 reserves ; lot perime E1 exclu), prix ' || :price1);
select pg_temp.verdict('2', :lots_vus = 0,
  'le patient ne lit toujours aucun lot dans stock_batches (' || :lots_vus || ' ligne) : seul le total vendable lui est rendu');

-- ==================== Lot rappelé (module rappels) ====================
insert into public.recalls (id, reference_number, title, description, severity, status, issued_by)
  values (:'RECALL', 'R-C242-001', 'Rappel de test C242', 'Lot C242-R1', 'classI', 'inProgress', 'Test C242');
insert into public.recall_affected_batches (recall_id, batch_number, product_id, product_name, status)
  values (:'RECALL', 'C242-R1', :'PARA', 'Paracétamol', 'pending');

select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a3 \gset
reset role;
select pg_temp.verdict('3', :a3 = 3, 'lot R1 rappele : disponible ' || :a3 || ' (B1 seul, hors reserve)');

-- Il ne reste que le lot rappelé.
update public.stock_batches set quantity = 2 where id = 'c2420000-0000-0000-0000-0000000000b1';
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a4 \gset
reset role;
select pg_temp.verdict('4', :a4 = 0,
  'seul le lot rappele reste (B1 entierement reserve) : disponible ' || :a4 || ', l''officine reste listee, en rupture');
update public.stock_batches set quantity = 5 where id = 'c2420000-0000-0000-0000-0000000000b1';

-- Rappel annulé : le lot redevient disponible.
update public.recalls set status = 'cancelled' where id = :'RECALL';
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a5 \gset
reset role;
select pg_temp.verdict('5', :a5 = 13, 'rappel annule : disponible ' || :a5);
delete from public.recalls where id = :'RECALL';

-- ==================== Autres sources de rappel ====================
insert into public.product_recalls (id, product_id, product_name, batch_number, manufacturer, reason, recall_type, severity, status)
  values ('c2420000-0000-0000-0000-0000000000d1', null, 'Paracétamol', 'c242-r1', 'Fabricant test', 'Test C242', 'mandatory', 'class_i', 'published');
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a6 \gset
reset role;
select pg_temp.verdict('6', :a6 = 3, 'rappel du regulateur publie, sans produit, numero en minuscules : disponible ' || :a6);
delete from public.product_recalls where id = 'c2420000-0000-0000-0000-0000000000d1';

insert into public.traceable_batches (id, product_id, product_name, batch_number, serial_number, gtin, manufacturing_date, expiry_date, manufacturer, is_recalled, recalled_at)
  values ('c2420000-0000-0000-0000-0000000000f1', :'PARA', 'Paracétamol', 'C242-R1', 'C242-SN-1', '00000000000000', current_date - 100, current_date + 20, 'Fabricant test', true, now());
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a7 \gset
reset role;
select pg_temp.verdict('7', :a7 = 3, 'unite marquee rappelee en tracabilite : disponible ' || :a7);
delete from public.traceable_batches where id = 'c2420000-0000-0000-0000-0000000000f1';

-- ==================== Officine et produit ====================
select pg_temp.as_user(:'P'); set local role authenticated;
select (select count(*) from public.patient_stock_availability(array[:'PARA']::uuid[], :'KALOUM')) as n_kaloum,
       (select count(*) from public.patient_stock_availability(array[:'PARA']::uuid[], :'DIXINN') where pharmacy_id = :'KALOUM') as n_autre,
       (select count(*) from public.patient_stock_availability(array[]::uuid[])) as n_vide,
       (select count(*) from public.patient_stock_availability(null)) as n_null \gset
reset role;
select pg_temp.verdict('8', :n_kaloum = 1 and :n_autre = 0 and :n_vide = 0 and :n_null = 0,
  'filtre par officine : ' || :n_kaloum || ' ligne pour Kaloum, ' || :n_autre || ' ligne de Kaloum en demandant Dixinn ; liste vide ou nulle : aucune ligne');

update public.pharmacies set status = 'suspended' where id = :'KALOUM';
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a9 \gset
reset role;
select pg_temp.verdict('9', :a9 = -1, 'officine suspendue : absente du resultat');
update public.pharmacies set status = 'active' where id = :'KALOUM';

update public.stock_items set status = 'discontinued'
  where pharmacy_id = :'KALOUM' and product_id = :'PARA';
select pg_temp.as_user(:'P'); set local role authenticated;
select pg_temp.avail() as a10 \gset
reset role;
select pg_temp.verdict('10', :a10 = -1, 'produit arrete dans l''officine : absent du resultat');
update public.stock_items set status = 'inStock'
  where pharmacy_id = :'KALOUM' and product_id = :'PARA';

-- ==================== Droits ====================
set local role anon;
do $$ begin
  perform * from public.patient_stock_availability(array['33333333-3333-3333-3333-333333330001']::uuid[]);
  insert into t_out values ('11', 'OK', null);
exception when others then insert into t_out values ('11', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('11', '42501', '; anonyme : refuse');

select pg_temp.verdict('12',
  (select prosecdef and provolatile = 's' from pg_proc where oid = 'public.patient_stock_availability(uuid[], uuid)'::regprocedure)
  and not has_function_privilege('anon', 'public.patient_stock_availability(uuid[], uuid)', 'execute')
  and has_function_privilege('authenticated', 'public.patient_stock_availability(uuid[], uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.stock_batch_recall(uuid)', 'execute'),
  'fonction en lecture (stable), ouverte aux seuls utilisateurs connectes ; stock_batch_recall toujours fermee aux clients');

-- ==================== Constat hors C242 (aucune correction ici) ====================
-- La réservation patient écrit le stock depuis l'application
-- (StockService.reserveStock). Sous les règles d'accès actuelles, un patient
-- ne peut modifier ni stock_items ni stock_batches : l'écriture ne touche
-- aucune ligne, sans erreur.
select pg_temp.as_user(:'P'); set local role authenticated;
with u as (
  update public.stock_items set reserved_quantity = reserved_quantity + 1
    where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001'
    returning 1
), b as (
  update public.stock_batches set quantity_reserved = quantity_reserved + 1
    where id = 'c2420000-0000-0000-0000-0000000000b1'
    returning 1
)
select (select count(*) from u) as maj_items, (select count(*) from b) as maj_lots \gset
reset role;
select pg_temp.verdict('CONSTAT',
  :maj_items = 0 and :maj_lots = 0,
  'un patient qui reserve ne retient aucun stock : ' || :maj_items || ' ligne de stock_items et ' || :maj_lots || ' lot modifies, sans erreur (voir registre)');

rollback;
