-- C240 : un lot rappelé n'est plus vendable (pos_create_sale), ne compte plus
-- dans le disponible de l'écran d'encaissement (pos_search_stock_products)
-- et ne peut pas être remis en stock par un remboursement (pos_refund_sale).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c240_pos_recalled_batch.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- A : pharmacien de Kaloum, caisse ouverte (C205).
insert into auth.users (id, email) values
  ('c2400000-0000-0000-0000-000000000001', 'c240-a@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2400000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum');
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', 'c2400000-0000-0000-0000-000000000001', 0, 'open');

-- Paracétamol à Kaloum : prix 1 500. Les lots du seed sont vidés pour que
-- seuls les deux lots de test soient vendables :
--   R1 (C240-R1, péremption la plus proche, 10 unités) : le lot visé par les rappels ;
--   B1 (C240-B1, 5 unités) : un lot sain.
update public.stock_items set unit_price = 1500
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001';
update public.stock_batches b set quantity = 0, quantity_reserved = 0
  from public.stock_items si
  where si.id = b.stock_item_id
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select v.id::uuid, si.id, v.num, current_date - 100, current_date + v.days, v.qty, 0, now()
  from public.stock_items si,
       (values ('c2400000-0000-0000-0000-0000000000a1', 'C240-R1', 20, 10),
               ('c2400000-0000-0000-0000-0000000000b1', 'C240-B1', 60, 5)) as v(id, num, days, qty)
  where si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';

\set A 'c2400000-0000-0000-0000-000000000001'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set PARA '33333333-3333-3333-3333-333333330001'
\set IBU '33333333-3333-3333-3333-333333330003'
\set R1 'c2400000-0000-0000-0000-0000000000a1'
\set B1 'c2400000-0000-0000-0000-0000000000b1'
\set RECALL 'c2400000-0000-0000-0000-0000000000c1'

create temp table t_out (c text primary key, state text, msg text);
grant all on t_out to authenticated, anon;
create temp table t_sale (c text primary key, id uuid);
grant all on t_sale to authenticated, anon;

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

-- Vente de p_qty Paracétamol : par produit (lots choisis par le serveur) ou
-- sur le lot R1 désigné.
create function pg_temp.sell(p_case text, p_qty int, p_by_batch boolean) returns void language plpgsql as $$
declare v_id uuid;
begin
  v_id := public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', p_qty * 1500, 0, 0, p_qty * 1500,
    jsonb_build_array(jsonb_build_object(
      'product_id', '33333333-3333-3333-3333-333333330001', 'product_name', 'Paracetamol',
      'quantity', p_qty, 'unit_price', 1500, 'total_price', p_qty * 1500,
      'batch_id', case when p_by_batch then 'c2400000-0000-0000-0000-0000000000a1' end)));
  insert into t_out values (p_case, 'OK', null);
  insert into t_sale values (p_case, v_id);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.refund(p_case text, p_sale text, p_disposition text) returns void language plpgsql as $$
begin
  perform public.pos_refund_sale((select id from t_sale where c = p_sale), 'Test C240', p_disposition);
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.qty(p_batch text) returns int language sql as $$
  select quantity from public.stock_batches where id = p_batch::uuid
$$;
create function pg_temp.sales() returns bigint language sql as $$
  select count(*) from public.pos_sales where pharmacy_id = '55555555-5555-5555-5555-555555550001'
$$;
create function pg_temp.msg(p_case text) returns text language sql as $$
  select coalesce(msg, '') from t_out where c = p_case
$$;

-- ==================== Avant tout rappel ====================
-- Deux ventes sur R1, gardées pour les remboursements (cas 11 et 12).
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('0a', 1, true);
select pg_temp.sell('0b', 1, true);
reset role;
select pg_temp.expect('0a', 'OK', pg_temp.qty(:'R1') = 8 and public.stock_batch_recall(:'R1') is null,
  '; sans rappel, le lot R1 se vend (R1 = 8) et stock_batch_recall rend null');

-- ==================== Source 1 : module rappels, rappel en cours ====================
insert into public.recalls (id, reference_number, title, description, severity, status, issued_by)
  values (:'RECALL', 'R-C240-001', 'Rappel de test C240', 'Lot C240-R1', 'classI', 'inProgress', 'Test C240');
insert into public.recall_affected_batches (id, recall_id, batch_number, product_id, product_name, status)
  values ('c2400000-0000-0000-0000-0000000000d1', :'RECALL', 'C240-R1', :'PARA', 'Paracétamol', 'pending');

select pg_temp.sales() as n0 \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('1', 1, true);
reset role;
select pg_temp.expect('1', '22023',
  pg_temp.msg('1') like '%le lot C240-R1 de Paracétamol%est rappele (rappel R-C240-001)%Retirez ce lot de la vente%'
  and pg_temp.sales() = :'n0'::int and pg_temp.qty(:'R1') = 8,
  '; lot designe rappele : vente refusee, rien d''ecrit');

select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('2', 2, false);
reset role;
select pg_temp.expect('2', 'OK',
  pg_temp.qty(:'R1') = 8 and pg_temp.qty(:'B1') = 3
  and (select bool_and(batch_id = :'B1'::uuid) from public.pos_sale_items where sale_id = (select id from t_sale where c = '2')),
  '; lots choisis par le serveur : R1 (peremption la plus proche) saute, B1 pris (R1 = 8, B1 = 3)');

select pg_temp.sales() as n0 \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('3', 5, false);
reset role;
select pg_temp.expect('3', 'P0001',
  pg_temp.msg('3') like '%stock insuffisant pour Paracetamol (demande 5, disponible 3) ; 8 unite(s) en lot rappele, a retirer de la vente%'
  and pg_temp.sales() = :'n0'::int and pg_temp.qty(:'B1') = 3 and pg_temp.qty(:'R1') = 8,
  '; il ne reste que le lot rappele pour completer : refus, unites rappelees annoncees, rien d''ecrit');

-- Recherche de l'écran d'encaissement.
select pg_temp.as_user(:'A'); set local role authenticated;
select available_quantity as avail, nearest_expiry as nearest
  from public.pos_search_stock_products(:'KALOUM', 'Paracétamol', 50) where product_id = :'PARA' \gset
reset role;
select pg_temp.verdict('4', :'avail'::int = 3 and :'nearest'::date = current_date + 60,
  'recherche : disponible ' || :'avail' || ' (lot rappele exclu), peremption la plus proche = celle de B1');

-- Remboursement d'une vente du lot rappelé.
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.refund('5', '0a', 'restock');
reset role;
select pg_temp.expect('5', '22023',
  pg_temp.msg('5') like '%le lot C240-R1 de Paracétamol%est rappele (rappel R-C240-001) : remise en stock impossible, choisissez la quarantaine%'
  and pg_temp.qty(:'R1') = 8
  and (select status from public.pos_sales where id = (select id from t_sale where c = '0a')) = 'completed',
  '; remise en stock d''un lot rappele refusee, vente toujours completee');

select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.refund('6', '0a', 'quarantine');
reset role;
select pg_temp.expect('6', 'OK',
  pg_temp.qty(:'R1') = 8
  and (select status from public.pos_sales where id = (select id from t_sale where c = '0a')) = 'refunded'
  and (select count(*) from public.pos_refund_quarantine where sale_id = (select id from t_sale where c = '0a')) = 1,
  '; quarantaine acceptee : vente remboursee, lot non remis en stock, une ligne de quarantaine');

-- ==================== Statuts du rappel ====================
update public.recalls set status = 'draft' where id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('7a', 1, true);
reset role;
select pg_temp.expect('7a', 'OK', pg_temp.qty(:'R1') = 7, '; rappel en brouillon : vente acceptee');

update public.recalls set status = 'cancelled' where id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('7b', 1, true);
reset role;
select pg_temp.expect('7b', 'OK', pg_temp.qty(:'R1') = 6, '; rappel annule : vente acceptee');

update public.recalls set status = 'completed' where id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('8', 1, true);
reset role;
select pg_temp.expect('8', '22023', pg_temp.qty(:'R1') = 6, '; rappel termine : le lot reste rappele, vente refusee');

update public.recalls set status = 'inProgress' where id = :'RECALL';
update public.recall_affected_batches set status = 'cancelled' where recall_id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('9', 1, true);
reset role;
select pg_temp.expect('9', 'OK', pg_temp.qty(:'R1') = 5, '; rappel en cours mais ligne du lot annulee : vente acceptee');

-- ==================== Rapprochement : produit et numéro de lot ====================
-- Même numéro de lot, autre produit.
update public.recall_affected_batches set status = 'pending', product_id = :'IBU', product_name = 'Ibuprofène'
  where recall_id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('10', 1, true);
reset role;
select pg_temp.expect('10', 'OK', pg_temp.qty(:'R1') = 4, '; meme numero de lot mais autre produit : vente acceptee');

-- Rappel sans produit renseigné : numéro de lot seul.
update public.recall_affected_batches set product_id = null where recall_id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('11', 1, true);
reset role;
select pg_temp.expect('11', '22023', pg_temp.qty(:'R1') = 4, '; rappel sans produit renseigne : refus sur le seul numero de lot');

-- Casse et espaces.
update public.recall_affected_batches set product_id = :'PARA', batch_number = '  c240 - r1 ' where recall_id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('12', 1, true);
reset role;
select pg_temp.expect('12', '22023', pg_temp.qty(:'R1') = 4, '; numero de lot ecrit «   c240 - r1  » : meme lot, vente refusee');

-- Numéro de lot voisin.
update public.recall_affected_batches set batch_number = 'C240-R10' where recall_id = :'RECALL';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('13', 1, true);
reset role;
select pg_temp.expect('13', 'OK', pg_temp.qty(:'R1') = 3, '; numero de lot voisin (C240-R10) : vente acceptee');

delete from public.recalls where id = :'RECALL';

-- ==================== Source 2 : module régulateur ====================
insert into public.product_recalls (id, product_id, product_name, batch_number, manufacturer, reason, recall_type, severity, status)
  values ('c2400000-0000-0000-0000-0000000000e1', :'PARA', 'Paracétamol', 'C240-R1', 'Fabricant test', 'Test C240', 'mandatory', 'class_i', 'draft');
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('14a', 1, true);
reset role;
select pg_temp.expect('14a', 'OK', pg_temp.qty(:'R1') = 2, '; rappel du regulateur en brouillon : vente acceptee');

update public.product_recalls set status = 'published' where id = 'c2400000-0000-0000-0000-0000000000e1';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('14b', 1, true);
reset role;
select pg_temp.expect('14b', '22023', pg_temp.msg('14b') like '%est rappele (rappel du regulateur du %' and pg_temp.qty(:'R1') = 2,
  '; rappel du regulateur publie : vente refusee');

update public.product_recalls set status = 'completed' where id = 'c2400000-0000-0000-0000-0000000000e1';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('14c', 1, true);
reset role;
select pg_temp.expect('14c', '22023', pg_temp.qty(:'R1') = 2, '; rappel du regulateur termine : vente refusee');

update public.product_recalls set status = 'cancelled' where id = 'c2400000-0000-0000-0000-0000000000e1';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('14d', 1, true);
reset role;
select pg_temp.expect('14d', 'OK', pg_temp.qty(:'R1') = 1, '; rappel du regulateur annule : vente acceptee');
delete from public.product_recalls where id = 'c2400000-0000-0000-0000-0000000000e1';

-- ==================== Source 3 : traçabilité ====================
insert into public.traceable_batches (id, product_id, product_name, batch_number, serial_number, gtin, manufacturing_date, expiry_date, manufacturer, is_recalled, recalled_at)
  values ('c2400000-0000-0000-0000-0000000000f1', :'PARA', 'Paracétamol', 'C240-R1', 'C240-SN-1', '00000000000000', current_date - 100, current_date + 20, 'Fabricant test', true, now());
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('15a', 1, true);
reset role;
select pg_temp.expect('15a', '22023', pg_temp.msg('15a') like '%est rappele (rappel signale en tracabilite)%' and pg_temp.qty(:'R1') = 1,
  '; unite du lot marquee rappelee en tracabilite : vente refusee');

update public.traceable_batches set is_recalled = false where id = 'c2400000-0000-0000-0000-0000000000f1';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('15b', 1, true);
reset role;
select pg_temp.expect('15b', 'OK', pg_temp.qty(:'R1') = 0, '; marque levee : vente acceptee');

-- ==================== Sans rappel : remboursement inchangé ====================
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.refund('16', '0b', 'restock');
reset role;
select pg_temp.expect('16', 'OK', pg_temp.qty(:'R1') = 1,
  '; lot non rappele : remise en stock acceptee comme avant (R1 = 1)');

-- ==================== Droits ====================
select pg_temp.as_user(:'A'); set local role authenticated;
do $$ begin
  perform public.stock_batch_recall('c2400000-0000-0000-0000-0000000000a1');
  insert into t_out values ('17', 'OK', null);
exception when others then insert into t_out values ('17', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('17', '42501', true, '; rapprochement interne non appelable par les clients');

select pg_temp.verdict('18',
  public.recall_norm_batch('  ab 12-c ') = 'AB12-C' and public.recall_norm_batch(null) = ''
  and public.stock_batch_recall('00000000-0000-0000-0000-000000000000') is null,
  'normalisation du numero de lot ; lot inconnu : pas de rappel');

rollback;
