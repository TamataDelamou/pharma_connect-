-- C197 / C203 : vente et remboursement POS atomiques (pos_create_sale,
-- pos_refund_sale) et contrôles de vente.
--
-- Cas 1 à 10 : ceux de C197 (entrée C197 du registre). Cas 11 à 16 : C203.
-- Chaque cas affiche une ligne « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Données : seed local. Pharmaciens A (Kaloum) et B (Dixinn) créés dans la
-- transaction. Lots de A : L1 = LOT-2026-0009 (ramené à 10), L2 =
-- LOT-2026-0017 (ramené à 3) ; lot de B : LOT-2026-0028. Identités simulées
-- par request.jwt.claims + set local role authenticated ; chaque cas
-- d'erreur tourne dans un bloc DO qui capte le SQLSTATE.
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c197_c203_pos_atomic_sale.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Identités et lots ====================
insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'c197-a@test.local'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'c197-b@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn');

update public.stock_batches b set quantity = 10
  from public.stock_items si
  where si.id = b.stock_item_id and b.batch_number = 'LOT-2026-0009'
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001';
update public.stock_batches b set quantity = 3
  from public.stock_items si
  where si.id = b.stock_item_id and b.batch_number = 'LOT-2026-0017'
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001';

-- Contexte partagé avec les blocs DO (exécutés sous le rôle authenticated).
create temp table t_ctx (k text primary key, v text);
create temp table t_out (c text primary key, state text, msg text);
grant all on t_ctx, t_out to authenticated, anon;

insert into t_ctx
  select 'L1', b.id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0009' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
  union all
  select 'L2', b.id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0017' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
  union all
  select 'LB', b.id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0028' and si.pharmacy_id = '55555555-5555-5555-5555-555555550002'
  union all
  select 'P_L1', si.product_id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0009' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
  union all
  select 'P_L2', si.product_id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0017' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
  union all
  select 'P_LB', si.product_id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0028' and si.pharmacy_id = '55555555-5555-5555-5555-555555550002';

select v as l1 from t_ctx where k = 'L1' \gset
select v as l2 from t_ctx where k = 'L2' \gset
select v as lb from t_ctx where k = 'LB' \gset
select v as p_l1 from t_ctx where k = 'P_L1' \gset
select v as p_l2 from t_ctx where k = 'P_L2' \gset
select v as p_lb from t_ctx where k = 'P_LB' \gset
\set A 'aaaaaaaa-0000-0000-0000-00000000000a'
\set B 'bbbbbbbb-0000-0000-0000-00000000000b'
\set PA '55555555-5555-5555-5555-555555550001'
\set PB '55555555-5555-5555-5555-555555550002'

-- ==================== Outils ====================
create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- État observé : ventes, lignes, reçus, mouvements, quantités L1 / L2 / LB.
create function pg_temp.snap() returns text language sql as $$
  select format('ventes=%s lignes=%s recus=%s mvts=%s L1=%s L2=%s LB=%s',
    (select count(*) from public.pos_sales),
    (select count(*) from public.pos_sale_items),
    (select count(*) from public.pos_receipts),
    (select count(*) from public.stock_movements),
    (select quantity from public.stock_batches where id = (select v::uuid from t_ctx where k = 'L1')),
    (select quantity from public.stock_batches where id = (select v::uuid from t_ctx where k = 'L2')),
    (select quantity from public.stock_batches where id = (select v::uuid from t_ctx where k = 'LB')))
$$;

-- Cas d'erreur : SQLSTATE attendu, fragment de message attendu, état inchangé.
create function pg_temp.expect_err(p_case text, p_state text, p_msg text, p_before text) returns void language plpgsql as $$
declare
  o record;
  v_after text := pg_temp.snap();
begin
  select * into o from t_out where c = p_case;
  if not found then
    raise notice 'CAS % ECHEC : aucune exception (attendu %)', p_case, p_state;
  elsif o.state = p_state and o.msg ilike '%' || p_msg || '%' and v_after = p_before then
    raise notice 'CAS % OK : % « % », rien d''ecrit (%)', p_case, o.state, o.msg, v_after;
  else
    raise notice 'CAS % ECHEC : % « % » (attendu % « % ») ; avant [%] apres [%]',
      p_case, o.state, o.msg, p_state, p_msg, p_before, v_after;
  end if;
end;
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if p_ok then
    raise notice 'CAS % OK : %', p_case, p_detail;
  else
    raise notice 'CAS % ECHEC : %', p_case, p_detail;
  end if;
end;
$$;

\echo '===== Etat initial'
select pg_temp.snap();

-- ==================== Cas 1 : A vend 2 x L1 + 1 x L2 ====================
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_create_sale(:'PA', 'cash', 5000, 0, 250, 5250,
  jsonb_build_array(
    jsonb_build_object('product_id', :'p_l1', 'product_name', 'Produit L1', 'quantity', 2, 'unit_price', 1500, 'total_price', 3000, 'batch_id', :'l1'),
    jsonb_build_object('product_id', :'p_l2', 'product_name', 'Produit L2', 'quantity', 1, 'unit_price', 2000, 'total_price', 2000, 'batch_id', :'l2'))
) as sale1 \gset
reset role;
insert into t_ctx values ('S1', :'sale1');
select pg_temp.verdict('1',
  (select status = 'completed' and sale_number ~ '^S[0-9]{6}$' and cashier_id = :'A' and created_by = :'A'
     from public.pos_sales where id = :'sale1')
  and (select count(*) = 2 from public.pos_sale_items where sale_id = :'sale1')
  and (select count(*) = 1 and bool_and(receipt_number ~ '^R[0-9]{6}$') from public.pos_receipts where sale_id = :'sale1')
  and (select count(*) = 2 and bool_and(type = 'sale') from public.stock_movements where reference_id = :'sale1')
  and pg_temp.snap() like '%L1=8 L2=2%',
  (select format('vente %s %s, recu %s, caissier=A %s, created_by=A %s, ', s.sale_number, s.status, r.receipt_number,
                 s.cashier_id = :'A', s.created_by = :'A')
     from public.pos_sales s join public.pos_receipts r on r.sale_id = s.id where s.id = :'sale1')
  || (select string_agg(format('%s %s', type, quantity), ', ' order by quantity) from public.stock_movements where reference_id = :'sale1')
  || ' ; ' || pg_temp.snap());

-- ==================== Cas 2 : A vend 1 x L1 + 99 x L2 ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 199500, 0, 0, 199500,
    jsonb_build_array(
      jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1')),
      jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L2'), 'product_name', 'Produit L2', 'quantity', 99, 'unit_price', 2000, 'total_price', 198000, 'batch_id', (select v from t_ctx where k = 'L2'))));
exception when others then insert into t_out values ('2', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('2', 'P0001', 'stock insuffisant', :'before');

-- ==================== Cas 3 : B vend pour l'officine de A ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'B');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 0, 1500,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('3', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('3', '42501', 'acces refuse', :'before');

-- ==================== Cas 4 : A utilise le lot de B ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 2500, 0, 0, 2500,
    jsonb_build_array(
      jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1')),
      jsonb_build_object('product_id', (select v from t_ctx where k = 'P_LB'), 'product_name', 'Produit LB', 'quantity', 1, 'unit_price', 1000, 'total_price', 1000, 'batch_id', (select v from t_ctx where k = 'LB'))));
exception when others then insert into t_out values ('4', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('4', '42501', 'n''appartient pas', :'before');

-- ==================== Cas 5 : incohérences ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 3001, 0, 0, 3001,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 2, 'unit_price', 1500, 'total_price', 3001, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('5a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 9999, 0, 0, 9999,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 2, 'unit_price', 1500, 'total_price', 3000, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('5b', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 0, 0, 0, 0, '[]'::jsonb);
exception when others then insert into t_out values ('5c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('5a', '22023', 'ligne incoherente', :'before');
select pg_temp.expect_err('5b', '22023', 'different de la somme', :'before');
select pg_temp.expect_err('5c', '22023', 'au moins une ligne', :'before');

-- ==================== Cas 6 : vente de A puis vente de B ====================
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 0, 1500,
  jsonb_build_array(jsonb_build_object('product_id', :'p_l1', 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', :'l1'))
) as sale6a \gset
reset role;
select pg_temp.as_user(:'B');
set local role authenticated;
select public.pos_create_sale(:'PB', 'mobile_money', 1000, 0, 0, 1000,
  jsonb_build_array(jsonb_build_object('product_id', :'p_lb', 'product_name', 'Produit LB', 'quantity', 1, 'unit_price', 1000, 'total_price', 1000, 'batch_id', :'lb'))
) as sale6b \gset
reset role;
select pg_temp.verdict('6',
  (select count(distinct s.sale_number) = 2 and count(distinct r.receipt_number) = 2
     from public.pos_sales s join public.pos_receipts r on r.sale_id = s.id where s.id in (:'sale6a', :'sale6b')),
  (select string_agg(format('%s %s/%s', case when s.pharmacy_id = :'PA' then 'A' else 'B' end, s.sale_number, r.receipt_number), ', ' order by s.sale_number)
     from public.pos_sales s join public.pos_receipts r on r.sale_id = s.id where s.id in (:'sale6a', :'sale6b'))
  || ', aucune erreur d''unicite');

-- Remet L1 à 8 avant le cas 7, par la RPC elle-même (vente 6a remboursée).
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_refund_sale(:'sale6a');
reset role;

-- ==================== Cas 7 : A rembourse la vente du cas 1 ====================
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_refund_sale(:'sale1');
reset role;
select pg_temp.verdict('7',
  (select status = 'refunded' from public.pos_sales where id = :'sale1')
  and (select count(*) = 2 from public.stock_movements where reference_id = :'sale1' and type = 'adjustment')
  and pg_temp.snap() like '%L1=10 L2=3%',
  (select 'statut ' || status from public.pos_sales where id = :'sale1') || ', '
  || (select string_agg(format('%s +%s', type, quantity), ', ' order by quantity) from public.stock_movements where reference_id = :'sale1' and type = 'adjustment')
  || ' ; ' || pg_temp.snap());

-- ==================== Cas 8 : second remboursement ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S1'));
exception when others then insert into t_out values ('8', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('8', '22023', 'statut refunded', :'before');

-- ==================== Cas 9 : B rembourse une vente de A ====================
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 0, 1500,
  jsonb_build_array(jsonb_build_object('product_id', :'p_l1', 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', :'l1'))
) as sale9 \gset
reset role;
insert into t_ctx values ('S9', :'sale9');
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'B');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S9'));
exception when others then insert into t_out values ('9', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('9', '42501', 'acces refuse', :'before');
select pg_temp.verdict('9-statut', (select status = 'completed' from public.pos_sales where id = :'sale9'),
  (select 'vente de A toujours ' || status from public.pos_sales where id = :'sale9'));

-- ==================== Cas 10 : anon ====================
select pg_temp.snap() as before \gset
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 0, 1500,
    '[{"product_name":"X","quantity":1,"unit_price":1500,"total_price":1500}]'::jsonb);
exception when others then insert into t_out values ('10a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S9'));
exception when others then insert into t_out values ('10b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('10a', '42501', 'permission denied for function pos_create_sale', :'before');
select pg_temp.expect_err('10b', '42501', 'permission denied for function pos_refund_sale', :'before');
select pg_temp.verdict('10-droits',
  not has_function_privilege('anon', 'public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text)', 'execute')
  and not has_function_privilege('anon', 'public.pos_refund_sale(uuid)', 'execute')
  and has_function_privilege('authenticated', 'public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text)', 'execute')
  and has_function_privilege('authenticated', 'public.pos_refund_sale(uuid)', 'execute'),
  'execute : anon refuse, authenticated accorde (pos_create_sale, pos_refund_sale)');

-- ==================== Cas 11 (C203) : remise > total ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 2000, 0, 0,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('11', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('11', '22023', 'remise 2000 superieure au total 1500', :'before');

-- ==================== Cas 12 (C203) : montant final à 1 près ====================
-- total 1500, remise 0, TVA 75 : attendu 1575. 1577 (écart 2) refusé ; 1576 (écart 1) accepté.
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 75, 1577,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('12a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('12a', '22023', 'montant final 1577 incoherent', :'before');
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 75, 1576,
  jsonb_build_array(jsonb_build_object('product_id', :'p_l1', 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', :'l1'))
) as sale12 \gset
reset role;
select pg_temp.verdict('12b',
  (select final_amount = 1576 and status = 'completed' from public.pos_sales where id = :'sale12'),
  (select format('ecart 1 accepte : vente %s, final %s', sale_number, final_amount) from public.pos_sales where id = :'sale12'));

-- ==================== Cas 13 (C203) : remise par ligne ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 0, 1500,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1'), 'discount_percentage', 10)));
exception when others then insert into t_out values ('13', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('13', '22023', 'remise par ligne non prise en charge', :'before');

-- ==================== Cas 14 (C203) : lot L1 avec le produit de L2 ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1500, 0, 0, 1500,
    jsonb_build_array(jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L2'), 'product_name', 'Produit L2', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1'))));
exception when others then insert into t_out values ('14', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('14', '22023', 'ne correspond pas au produit', :'before');

-- ==================== Cas 15 (C203) : lot L1 sans product_id ====================
select pg_temp.as_user(:'A');
set local role authenticated;
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 0, 1500,
  jsonb_build_array(jsonb_build_object('product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', :'l1'))
) as sale15 \gset
reset role;
select pg_temp.verdict('15',
  (select count(*) = 1 and bool_and(product_id = :'p_l1') from public.pos_sale_items where sale_id = :'sale15'),
  (select format('ligne acceptee, product_id = produit de L1 : %s', bool_and(product_id = :'p_l1')) from public.pos_sale_items where sale_id = :'sale15'));

-- ==================== Cas 16 (C203) : lot inexistant après une ligne valide ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'A');
set local role authenticated;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 2500, 0, 0, 2500,
    jsonb_build_array(
      jsonb_build_object('product_id', (select v from t_ctx where k = 'P_L1'), 'product_name', 'Produit L1', 'quantity', 1, 'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1')),
      jsonb_build_object('product_name', 'Lot fantome', 'quantity', 1, 'unit_price', 1000, 'total_price', 1000, 'batch_id', gen_random_uuid())));
exception when others then insert into t_out values ('16', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('16', '22023', 'introuvable', :'before');

\echo '===== Etat final (avant rollback)'
select pg_temp.snap();

rollback;
