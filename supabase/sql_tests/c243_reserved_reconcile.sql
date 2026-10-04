-- C243 (suite) : remise de la quantité réservée au total réellement retenu
-- (stock_reconcile_reserved), sauvegarde, et fermeture de l'écriture directe
-- de la quantité réservée.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Le jeu de données local (seed, chargé après les migrations) porte des
-- quantités réservées sans réservation : le fichier rejoue la remise sur ce
-- jeu, avant et après.
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c243_reserved_reconcile.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

\set P1 'c2430000-0000-0000-0000-0000000000e1'
\set A 'c2430000-0000-0000-0000-0000000000ea'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set ASPI '33333333-3333-3333-3333-333333330004'
\set PARA '33333333-3333-3333-3333-333333330001'

insert into auth.users (id, email) values
  (:'P1', 'c243r-p1@test.local'),
  (:'A', 'c243r-a@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  (:'P1', 'patient', null, 'Patient Un'),
  (:'A', 'pharmacien', :'KALOUM', 'Pharmacien A Kaloum');
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  (:'KALOUM', :'A', 0, 'open');

create temp table t_out (c text primary key, state text, msg text, id uuid);
grant all on t_out to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;
create function pg_temp.try(p_case text, p_sql text) returns void language plpgsql as $$
declare v_txt text;
begin
  execute p_sql into v_txt;
  insert into t_out values (p_case, 'OK', null, nullif(v_txt, '')::uuid);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm, null);
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
-- Vente au comptoir d'Aspirine, par produit.
create function pg_temp.sale(p_qty int, p_price int) returns text language sql as $$
  select format('select public.pos_create_sale(%L, ''cash'', %s, 0, 0, %s, %L::jsonb)', '55555555-5555-5555-5555-555555550001',
    p_qty * p_price, p_qty * p_price,
    jsonb_build_array(jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330004', 'product_name', 'Aspirine',
      'quantity', p_qty, 'unit_price', p_price, 'total_price', p_qty * p_price))::text)
$$;

-- Aspirine à Kaloum : un seul lot du jeu de données. Une boîte « réservée »
-- sans réservation y est garantie (le jeu de données tire ses valeurs au
-- hasard).
update public.products set regulatory_class = 'libre', is_prescription_required = false where id in (:'ASPI', :'PARA');
update public.stock_batches b set quantity_reserved = greatest(b.quantity_reserved, 1)
  from public.stock_items si
  where si.id = b.stock_item_id and si.pharmacy_id = :'KALOUM' and si.product_id = :'ASPI';
update public.stock_items si set reserved_quantity = (select sum(b.quantity_reserved) from public.stock_batches b where b.stock_item_id = si.id)
  where si.pharmacy_id = :'KALOUM' and si.product_id = :'ASPI';

-- Une vraie réservation, pour vérifier que ses boîtes restent retenues.
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('0', format('select public.reservation_create(%L, %L::jsonb)', :'KALOUM',
  jsonb_build_array(jsonb_build_object('product_id', :'PARA', 'quantity', 2))::text));
reset role;
select pg_temp.expect('0', 'OK', true, '; une vraie reservation de 2 boites de Paracetamol, avant la remise');

-- ==================== Avant ====================
create temp table t_before as
  select b.id, b.stock_item_id, b.quantity, b.quantity_reserved,
         coalesce((select sum(h.quantity) from public.reservation_item_batches h where h.batch_id = b.id and h.released_at is null), 0)::int as held
    from public.stock_batches b;
create temp table t_items_before as
  select si.id, si.total_quantity, si.reserved_quantity,
         coalesce((select sum(t.held) from t_before t where t.stock_item_id = si.id), 0)::int as held
    from public.stock_items si;

select count(*) filter (where quantity_reserved <> held) as lots_fantomes,
       coalesce(sum(quantity_reserved - held) filter (where quantity_reserved <> held), 0) as boites_fantomes,
       count(*) as lots_total
  from t_before \gset
select count(*) filter (where reserved_quantity <> held) as articles_fantomes from t_items_before \gset
select (select count(*) from public.stock_reserved_backup_20261004) as sauvegarde_avant \gset

select si.unit_price as prix, si.id as aspi_item,
       (select sum(b.quantity) from public.stock_batches b where b.stock_item_id = si.id) as aspi_qte,
       (select sum(b.quantity_reserved) from public.stock_batches b where b.stock_item_id = si.id) as aspi_res
  from public.stock_items si where si.pharmacy_id = :'KALOUM' and si.product_id = :'ASPI' \gset

select pg_temp.as_user(:'P1'); set local role authenticated;
select available_quantity as dispo_avant from public.patient_stock_availability(array[:'ASPI']::uuid[], :'KALOUM') \gset
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('1b', pg_temp.sale(:aspi_qte, :prix));
reset role;

select pg_temp.verdict('1', :lots_fantomes > 0 and :articles_fantomes > 0 and :sauvegarde_avant = 0,
  'avant : ' || :lots_fantomes || ' lots sur ' || :lots_total || ' et ' || :articles_fantomes || ' articles portent une quantite reservee non retenue par une reservation (' || :boites_fantomes || ' boites) ; table de sauvegarde vide');
select pg_temp.verdict('1a', :dispo_avant = :aspi_qte - :aspi_res,
  'avant : Aspirine a Kaloum, ' || :aspi_qte || ' boites en stock, ' || :aspi_res || ' « reservee(s) » sans reservation ; disponible patient ' || :dispo_avant);
select pg_temp.expect('1b', 'P0001', (select msg like '%stock insuffisant%' from t_out where c = '1b'),
  '; avant : vente au comptoir de tout le stock d''Aspirine refusee');

-- ==================== Remise ====================
select batches_fixed as lots_corriges, items_fixed as articles_corriges from public.stock_reconcile_reserved() \gset

select pg_temp.verdict('2', :lots_corriges = :lots_fantomes and :articles_corriges = :articles_fantomes
  and (select count(*) from public.stock_batches b where b.quantity_reserved <> (select held from t_before t where t.id = b.id)) = 0
  and (select count(*) from public.stock_items si where si.reserved_quantity <> (select held from t_items_before t where t.id = si.id)) = 0,
  'remise : ' || :lots_corriges || ' lots et ' || :articles_corriges || ' articles corriges ; plus aucun lot ni article avec une quantite reservee non retenue par une reservation');

select pg_temp.verdict('3',
  (select count(*) from public.stock_reserved_backup_20261004 where source_table = 'stock_batches') = :lots_fantomes
  and (select count(*) from public.stock_reserved_backup_20261004 where source_table = 'stock_items') = :articles_fantomes
  and (select count(*) from public.stock_reserved_backup_20261004 s join t_before t on t.id = s.row_id
        where s.source_table = 'stock_batches' and s.reserved = t.quantity_reserved and s.quantity = t.quantity and t.quantity_reserved <> t.held) = :lots_fantomes
  and (select count(*) from public.stock_reserved_backup_20261004 s join t_items_before t on t.id = s.row_id
        where s.source_table = 'stock_items' and s.reserved = t.reserved_quantity and s.quantity = t.total_quantity) = :articles_fantomes,
  'sauvegarde complete : ' || :lots_fantomes || ' lignes de lots et ' || :articles_fantomes || ' lignes d''articles, chacune avec la valeur d''avant');

select pg_temp.verdict('4',
  (select count(*) from public.stock_batches b join t_before t on t.id = b.id where b.quantity <> t.quantity) = 0
  and (select count(*) from public.stock_batches) = :lots_total
  and (select count(*) from public.stock_items si join t_items_before t on t.id = si.id where si.total_quantity <> t.total_quantity) = 0,
  'quantites physiques identiques, lot par lot et article par article');

select pg_temp.verdict('5',
  (select sum(b.quantity_reserved) from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
     where si.pharmacy_id = :'KALOUM' and si.product_id = :'PARA') = 2
  and (select reserved_quantity from public.stock_items where pharmacy_id = :'KALOUM' and product_id = :'PARA') = 2
  and (select status from public.reservations where id = (select id from t_out where c = '0')) = 'pending',
  'la vraie reservation garde ses 2 boites retenues (lot et article a 2)');

-- Seconde exécution : rien à corriger, sauvegarde inchangée.
select batches_fixed as lots2, items_fixed as articles2 from public.stock_reconcile_reserved() \gset
select pg_temp.verdict('6', :lots2 = 0 and :articles2 = 0
  and (select count(*) from public.stock_reserved_backup_20261004) = :lots_fantomes + :articles_fantomes,
  'seconde execution : 0 lot et 0 article corriges, sauvegarde inchangee');

-- ==================== Après : les boîtes sont retrouvées ====================
select pg_temp.as_user(:'P1'); set local role authenticated;
select available_quantity as dispo_apres from public.patient_stock_availability(array[:'ASPI']::uuid[], :'KALOUM') \gset
select pg_temp.try('7c', 'select row_id from public.stock_reserved_backup_20261004 limit 1');
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select available_quantity as comptoir_apres from public.pos_search_stock_products(:'KALOUM', 'Aspirine', 5) where product_id = :'ASPI' \gset
select pg_temp.try('7b', pg_temp.sale(:aspi_qte, :prix));
select count(*) as sauvegarde_personnel from public.stock_reserved_backup_20261004 \gset
reset role;
select pg_temp.verdict('7a', :dispo_apres = :aspi_qte and :comptoir_apres = :aspi_qte,
  'apres : disponible patient ' || :dispo_apres || ' (avant ' || :dispo_avant || '), disponible au comptoir ' || :comptoir_apres);
select pg_temp.expect('7b', 'OK',
  (select sum(b.quantity) from public.stock_batches b where b.stock_item_id = :'aspi_item') = 0,
  '; apres : vente au comptoir de tout le stock d''Aspirine acceptee');
select pg_temp.verdict('7c', (select id is null and state = 'OK' from t_out where c = '7c') and :sauvegarde_personnel = 0,
  'table de sauvegarde : aucune ligne lisible par un patient ni par le personnel d''une officine');

-- ==================== Écriture directe de la quantité réservée fermée ====================
select b.id as lot_para from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
  where si.pharmacy_id = :'KALOUM' and si.product_id = :'PARA' order by b.id limit 1 \gset
select id as item_para from public.stock_items where pharmacy_id = :'KALOUM' and product_id = :'PARA' \gset
select quantity as lot_para_qte from public.stock_batches where id = :'lot_para' \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('8a', format('update public.stock_batches set quantity_reserved = quantity_reserved + 5 where id = %L returning null::uuid', :'lot_para'));
select pg_temp.try('8b', format('update public.stock_items set reserved_quantity = 9 where id = %L returning null::uuid', :'item_para'));
select pg_temp.try('8c', format('update public.stock_batches set quantity = quantity + 1 where id = %L returning null::uuid', :'lot_para'));
select pg_temp.try('8d', format('insert into public.stock_batches (stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at) values (%L, ''C243R-X'', current_date - 10, current_date + 90, 5, 2, now()) returning null::uuid', :'item_para'));
select pg_temp.try('8e', format('insert into public.stock_batches (stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, received_at) values (%L, ''C243R-Y'', current_date - 10, current_date + 90, 5, now()) returning null::uuid', :'item_para'));
select pg_temp.try('8f', format('update public.stock_items set threshold_low = threshold_low where id = %L returning null::uuid', :'item_para'));
reset role;
select pg_temp.expect('8a', '42501', (select msg like '%geree par les reservations%' from t_out where c = '8a'),
  '; personnel : ecriture directe de la quantite reservee d''un lot refusee');
select pg_temp.expect('8b', '42501', true, '; personnel : ecriture directe de la quantite reservee d''un article refusee');
select pg_temp.expect('8c', 'OK', (select quantity from public.stock_batches where id = :'lot_para') = :lot_para_qte + 1,
  '; personnel : la quantite physique d''un lot reste modifiable');
select pg_temp.expect('8d', '42501', true, '; personnel : creation d''un lot avec une quantite reservee non nulle refusee');
select pg_temp.expect('8e', 'OK', true, '; personnel : creation d''un lot sans quantite reservee acceptee');
select pg_temp.expect('8f', 'OK', true, '; personnel : les autres champs d''un article restent modifiables');

-- Les fonctions de réservation écrivent toujours la quantité réservée.
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('9', format('select public.reservation_cancel(%L)', (select id from t_out where c = '0')));
reset role;
select pg_temp.expect('9', 'OK',
  (select reserved_quantity from public.stock_items where id = :'item_para') = 0
  and (select sum(quantity_reserved) from public.stock_batches where stock_item_id = :'item_para') = 0,
  '; annulation par le patient : les fonctions de reservation liberent toujours les boites (retenue a 0)');

select pg_temp.verdict('10',
  not has_function_privilege('authenticated', 'public.stock_reconcile_reserved()', 'execute')
  and not has_function_privilege('anon', 'public.stock_reconcile_reserved()', 'execute')
  and not has_table_privilege('anon', 'public.stock_reserved_backup_20261004', 'select')
  and (select count(*) = 1 and bool_and(cmd = 'SELECT') from pg_policies where tablename = 'stock_reserved_backup_20261004'),
  'remise fermee aux clients ; table de sauvegarde : une seule regle, de lecture, pour GSG');

rollback;
