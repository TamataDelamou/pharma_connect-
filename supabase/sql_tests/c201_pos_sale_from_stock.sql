-- C201 : vente au comptoir sur le vrai stock (décision D60) — recherche en
-- stock, lots choisis par le serveur (péremption la plus proche, périmés et
-- réservés exclus, répartition sur plusieurs lots), lots périmés refusés,
-- ordonnance tracée sans blocage, remboursement d'une vente répartie.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c201_pos_sale_from_stock.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes et stock de test ====================
-- A : pharmacien de Kaloum ; B : pharmacien de Dixinn.
insert into auth.users (id, email) values
  ('c2010000-0000-0000-0000-000000000001', 'c201-a@test.local'),
  ('c2010000-0000-0000-0000-000000000002', 'c201-b@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2010000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum'),
  ('c2010000-0000-0000-0000-000000000002', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn');
-- C205 : une vente ou un remboursement en especes exige une caisse ouverte du
-- vendeur ; caisses ouvertes ici pour les identites qui vendent ou remboursent.
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', 'c2010000-0000-0000-0000-000000000001', 0, 'open');

\set A 'c2010000-0000-0000-0000-000000000001'
\set B 'c2010000-0000-0000-0000-000000000002'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set PARA '33333333-3333-3333-3333-333333330001'
\set DOLI '33333333-3333-3333-3333-333333330002'
\set AMOX '33333333-3333-3333-3333-333333330005'

-- Paracétamol à Kaloum : prix 1 500 ; lots du seed périmés ; trois lots de test :
--   NEAR : péremption J+30, 5 unités dont 1 réservée (4 vendables)
--   FAR  : péremption J+200, 10 unités (10 vendables)
--   RES  : péremption J+10, 2 unités toutes réservées (0 vendable)
update public.stock_items set unit_price = 1500
  where pharmacy_id = :'KALOUM' and product_id = :'PARA';
update public.stock_batches b set expiry_date = current_date - 1
  from public.stock_items si
  where si.id = b.stock_item_id and si.pharmacy_id = :'KALOUM' and si.product_id = :'PARA';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select v.id, si.id, v.num, current_date - 100, current_date + v.days, v.qty, v.res, now() - v.recv * interval '1 day'
  from public.stock_items si,
       (values ('c2010000-0000-0000-0000-0000000000b1'::uuid, 'C201-NEAR', 30, 5, 1, 5),
               ('c2010000-0000-0000-0000-0000000000b2'::uuid, 'C201-FAR', 200, 10, 0, 1),
               ('c2010000-0000-0000-0000-0000000000b3'::uuid, 'C201-RES', 10, 2, 2, 3)) as v(id, num, days, qty, res, recv)
  where si.pharmacy_id = :'KALOUM' and si.product_id = :'PARA';
-- Doliprane à Kaloum : tous les lots périmés.
update public.stock_batches b set expiry_date = current_date - 1, quantity = greatest(b.quantity, 5)
  from public.stock_items si
  where si.id = b.stock_item_id and si.pharmacy_id = :'KALOUM' and si.product_id = :'DOLI';
-- Amoxicilline à Kaloum (sur ordonnance) : un lot sûr.
update public.stock_items set unit_price = 4500
  where pharmacy_id = :'KALOUM' and product_id = :'AMOX';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select 'c2010000-0000-0000-0000-0000000000b4', si.id, 'C201-AMOX', current_date - 100, current_date - 400 + 800, 20, 0, now()
  from public.stock_items si where si.pharmacy_id = :'KALOUM' and si.product_id = :'AMOX';
-- Un produit absent du stock de Kaloum.
insert into public.products (id, name, generic_name, dosage, form)
  values ('c2010000-0000-0000-0000-0000000000f1', 'Produit hors stock C201', 'Hors stock', '1 mg', 'comprime');

\set NEAR 'c2010000-0000-0000-0000-0000000000b1'
\set FAR 'c2010000-0000-0000-0000-0000000000b2'
\set RES 'c2010000-0000-0000-0000-0000000000b3'

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

create function pg_temp.qty(b uuid) returns integer language sql as $$
  select quantity from public.stock_batches where id = b
$$;

create function pg_temp.snap() returns text language sql as $$
  select format('ventes=%s lignes=%s mvts=%s NEAR=%s FAR=%s RES=%s',
    (select count(*) from public.pos_sales), (select count(*) from public.pos_sale_items),
    (select count(*) from public.stock_movements),
    pg_temp.qty('c2010000-0000-0000-0000-0000000000b1'), pg_temp.qty('c2010000-0000-0000-0000-0000000000b2'),
    pg_temp.qty('c2010000-0000-0000-0000-0000000000b3'))
$$;

-- ==================== Cas 1 : recherche en stock ====================
select pg_temp.as_user(:'A');
set local role authenticated;
create temp table t_search as select * from public.pos_search_stock_products('55555555-5555-5555-5555-555555550001', 'parac', 10);
create temp table t_search_all as select * from public.pos_search_stock_products('55555555-5555-5555-5555-555555550001', null, 100);
reset role;
select pg_temp.verdict('1',
  (select count(*) = 2 and bool_or(product_id = '33333333-3333-3333-3333-333333330002') from t_search)
  and (select unit_price = 1500 and available_quantity = 14 and nearest_expiry = current_date + 30
          and not prescription_required from t_search where product_id = :'PARA'),
  (select format('« parac » trouve Paracetamol et Doliprane (DCI) ; Paracetamol : prix %s, vendable %s (NEAR 4 + FAR 10 ; RES reserve et lots perimes exclus), peremption la plus proche J+%s',
     unit_price, available_quantity, nearest_expiry - current_date) from t_search where product_id = '33333333-3333-3333-3333-333333330001'));
select pg_temp.verdict('1-liste',
  (select available_quantity = 0 from t_search_all where product_id = :'DOLI')
  and (select prescription_required from t_search_all where product_id = :'AMOX')
  and (select count(*) = 0 from t_search_all where product_id = 'c2010000-0000-0000-0000-0000000000f1'),
  'Doliprane (lots perimes) vendable 0, Amoxicilline sur ordonnance, produit hors stock absent');

-- ==================== Cas 2 : vente de 6 Paracétamol, lots choisis par le serveur ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('S2', public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 9000, 0, 0, 9000,
    jsonb_build_array(jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330001',
      'product_name', 'Paracetamol', 'quantity', 6, 'unit_price', 1500, 'total_price', 9000)))::text);
  insert into t_out values ('2', 'OK', null);
exception when others then insert into t_out values ('2', sqlstate, sqlerrm);
end $$;
reset role;
select v as s2 from t_ctx where k = 'S2' \gset
select pg_temp.expect('2', 'OK',
  (select count(*) = 2 from public.pos_sale_items where sale_id = :'s2')
  and (select quantity = 4 and total_price = 6000 from public.pos_sale_items where sale_id = :'s2' and batch_id = :'NEAR')
  and (select quantity = 2 and total_price = 3000 from public.pos_sale_items where sale_id = :'s2' and batch_id = :'FAR')
  and pg_temp.qty(:'NEAR') = 1 and pg_temp.qty(:'FAR') = 8 and pg_temp.qty(:'RES') = 2
  and (select count(*) = 2 from public.stock_movements where reference_id = :'s2' and type = 'sale'),
  '; 2 lignes : NEAR x4 (peremption la plus proche, reserve laisse) puis FAR x2 ; RES et lots perimes intacts ; ' || pg_temp.snap());

-- ==================== Cas 3 : stock insuffisant ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 30000, 0, 0, 30000,
    jsonb_build_array(jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330001',
      'product_name', 'Paracetamol', 'quantity', 20, 'unit_price', 1500, 'total_price', 30000)));
  insert into t_out values ('3', 'OK', null);
exception when others then insert into t_out values ('3', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('3', 'P0001', pg_temp.snap() = :'before', '; rien d''ecrit (' || pg_temp.snap() || ')');

-- ==================== Cas 4 : tous les lots périmés ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 3500, 0, 0, 3500,
    jsonb_build_array(jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330002',
      'product_name', 'Doliprane', 'quantity', 1, 'unit_price', 3500, 'total_price', 3500)));
  insert into t_out values ('4', 'OK', null);
exception when others then insert into t_out values ('4', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('4', 'P0001', true, '; aucun lot vendable');

-- ==================== Cas 5 : lot périmé désigné explicitement ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 0, 1500,
    jsonb_build_array(jsonb_build_object('product_name', 'Paracetamol', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500,
      'batch_id', (select b.id from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
                    where si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
                      and si.product_id = '33333333-3333-3333-3333-333333330001'
                      and b.expiry_date < current_date limit 1))));
  insert into t_out values ('5', 'OK', null);
exception when others then insert into t_out values ('5', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('5', '22023', true, '; lot perime refuse');

-- ==================== Cas 6 : ligne sans produit ni lot ; produit hors stock ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1000, 0, 0, 1000,
    '[{"product_name":"Article libre","quantity":1,"unit_price":1000,"total_price":1000}]'::jsonb);
  insert into t_out values ('6a', 'OK', null);
exception when others then insert into t_out values ('6a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1000, 0, 0, 1000,
    '[{"product_id":"c2010000-0000-0000-0000-0000000000f1","product_name":"Hors stock","quantity":1,"unit_price":1000,"total_price":1000}]'::jsonb);
  insert into t_out values ('6b', 'OK', null);
exception when others then insert into t_out values ('6b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('6a', '22023', true, '; ligne « catalogue » refusee');
select pg_temp.expect('6b', '22023', true, '; produit absent du stock de l''officine');

-- ==================== Cas 7 : ordonnance tracée, non bloquante ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  insert into t_ctx values ('S7', public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 9000, 0, 0, 9000,
    jsonb_build_array(
      jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330005', 'product_name', 'Amoxicilline',
        'quantity', 1, 'unit_price', 4500, 'total_price', 4500, 'prescription_checked', true),
      jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330005', 'product_name', 'Amoxicilline',
        'quantity', 1, 'unit_price', 4500, 'total_price', 4500)))::text);
  insert into t_out values ('7', 'OK', null);
exception when others then insert into t_out values ('7', sqlstate, sqlerrm);
end $$;
reset role;
select v as s7 from t_ctx where k = 'S7' \gset
select pg_temp.expect('7', 'OK',
  (select count(*) = 2 and bool_and(prescription_required) and count(*) filter (where prescription_checked) = 1
          and count(*) filter (where not prescription_checked) = 1
     from public.pos_sale_items where sale_id = :'s7')
  and (select coalesce(bool_and(not prescription_required), true) from public.pos_sale_items where sale_id = :'s2'),
  '; lignes Amoxicilline : prescription_required, une confirmee, une non confirmee (vente acceptee) ; Paracetamol non concerne');

-- ==================== Cas 8 : cloisonnement de la recherche ====================
select pg_temp.as_user(:'B');
set local role authenticated;
do $$ begin
  perform * from public.pos_search_stock_products('55555555-5555-5555-5555-555555550001', null, 10);
  insert into t_out values ('8a', 'OK', null);
exception when others then insert into t_out values ('8a', sqlstate, sqlerrm);
end $$;
reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform * from public.pos_search_stock_products('55555555-5555-5555-5555-555555550001', null, 10);
  insert into t_out values ('8b', 'OK', null);
exception when others then insert into t_out values ('8b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('8a', '42501', true, '; B (Dixinn) ne consulte pas le stock de Kaloum');
select pg_temp.expect('8b', '42501', true, '; anon refuse');

-- ==================== Cas 9 : remboursement d'une vente répartie sur deux lots ====================
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S2'), 'Erreur de produit', 'restock');
  insert into t_out values ('9', 'OK', null);
exception when others then insert into t_out values ('9', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('9', 'OK',
  pg_temp.qty(:'NEAR') = 5 and pg_temp.qty(:'FAR') = 10
  and (select status = 'refunded' from public.pos_sales where id = :'s2'),
  '; NEAR revient a 5, FAR a 10 (' || pg_temp.snap() || ')');

-- ==================== Cas 10 : droits ====================
select pg_temp.verdict('10',
  not has_function_privilege('anon', 'public.pos_search_stock_products(uuid, text, integer)', 'execute')
  and has_function_privilege('authenticated', 'public.pos_search_stock_products(uuid, text, integer)', 'execute')
  and not has_function_privilege('anon', 'public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text)', 'execute')
  and (select count(*) = 1 from pg_proc where proname = 'pos_create_sale'),
  'execute : anon refuse, authenticated accorde ; une seule fonction pos_create_sale');

rollback;
