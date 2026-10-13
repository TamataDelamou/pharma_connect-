-- C262 : remise bloquée au comptoir. pos_create_sale refuse toute vente dont
-- la remise n'est pas nulle (remise sur la vente ou sur une ligne) ; une
-- vente sans remise passe comme avant.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c262_pos_no_discount.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- A : pharmacien de Kaloum, caisse ouverte (C205).
insert into auth.users (id, email) values
  ('c2620000-0000-0000-0000-000000000001', 'c262-a@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2620000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum');
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', 'c2620000-0000-0000-0000-000000000001', 0, 'open');

-- Paracétamol à Kaloum : prix 1 500, un seul lot vendable de 10 boîtes.
update public.stock_items set unit_price = 1500
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001';
update public.stock_batches b set quantity = 0, quantity_reserved = 0
  from public.stock_items si
  where si.id = b.stock_item_id
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select 'c2620000-0000-0000-0000-0000000000b1'::uuid, si.id, 'C262-B1', current_date - 100, current_date + 200, 10, 0, now()
  from public.stock_items si
  where si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';

\set A 'c2620000-0000-0000-0000-000000000001'
\set B1 'c2620000-0000-0000-0000-0000000000b1'

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

-- Vente d'une boîte de Paracétamol à 1 500, TVA 75 : remise sur la vente
-- (p_discount) et remise sur la ligne (p_line_discount, en pourcentage).
create function pg_temp.sell(p_case text, p_discount int, p_line_discount numeric default 0) returns void language plpgsql as $$
begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash',
    1500, p_discount, 75, 1500 - p_discount + 75,
    jsonb_build_array(jsonb_build_object(
      'product_id', '33333333-3333-3333-3333-333333330001', 'product_name', 'Paracetamol',
      'quantity', 1, 'unit_price', 1500, 'total_price', 1500,
      'discount_percentage', p_line_discount)));
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.qty() returns int language sql as $$
  select quantity from public.stock_batches where id = 'c2620000-0000-0000-0000-0000000000b1'
$$;
create function pg_temp.sales() returns bigint language sql as $$
  select count(*) from public.pos_sales
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and cashier_id = 'c2620000-0000-0000-0000-000000000001'
$$;
create function pg_temp.msg(p_case text) returns text language sql as $$
  select coalesce(msg, '') from t_out where c = p_case
$$;

set local role authenticated;
select pg_temp.as_user(:'A');

-- 1 : vente sans remise, comme avant.
select pg_temp.sell('1', 0);
select pg_temp.expect('1', 'OK', pg_temp.sales() = 1 and pg_temp.qty() = 9,
  '; vente sans remise acceptee, une boite sortie');

-- 2 : la remise involontaire de l'essai (2,16 % de 1 500, soit 32).
select pg_temp.sell('2', 32);
select pg_temp.expect('2', '22023', pg_temp.msg('2') like '%remise non autorisee%',
  '; remise de 32 refusee');

-- 3 : remise d'une seule unité.
select pg_temp.sell('3', 1);
select pg_temp.expect('3', '22023', pg_temp.msg('3') like '%remise non autorisee%',
  '; remise de 1 refusee');

-- 4 : remise de 100 %.
select pg_temp.sell('4', 1500);
select pg_temp.expect('4', '22023', pg_temp.msg('4') like '%remise non autorisee%',
  '; remise de 100 % refusee');

-- 5 : remise négative (contrôle existant).
select pg_temp.sell('5', -10);
select pg_temp.expect('5', '22023', pg_temp.msg('5') like '%montant negatif%',
  '; remise negative refusee');

-- 6 : remise sur la ligne (contrôle existant, C203).
select pg_temp.sell('6', 0, 5);
select pg_temp.expect('6', '22023', pg_temp.msg('6') like '%remise par ligne%',
  '; remise par ligne refusee');

-- 7 : aucune des ventes refusées n'a rien écrit.
select pg_temp.verdict('7',
  pg_temp.sales() = 1 and pg_temp.qty() = 9
  and (select count(*) from public.pos_sales
       where cashier_id = 'c2620000-0000-0000-0000-000000000001' and discount_amount <> 0) = 0,
  'une seule vente enregistree, sans remise ; stock sorti une seule fois');

-- 8 : la vente acceptée porte les montants envoyés.
select pg_temp.verdict('8',
  (select total_amount = 1500 and discount_amount = 0 and tax_amount = 75 and final_amount = 1575
   from public.pos_sales where cashier_id = 'c2620000-0000-0000-0000-000000000001'),
  'vente acceptee : total 1 500, remise 0, TVA 75, a payer 1 575');

reset role;
rollback;
