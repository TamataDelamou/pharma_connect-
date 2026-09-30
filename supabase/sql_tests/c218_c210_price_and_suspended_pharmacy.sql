-- C218 (prix de vente imposé par le serveur) et C210 (officine suspendue
-- sans accès).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c218_c210_price_and_suspended_pharmacy.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- A : pharmacien de Kaloum ; T : titulaire de Kaloum.
insert into auth.users (id, email) values
  ('c2180000-0000-0000-0000-000000000001', 'c218-a@test.local'),
  ('c2180000-0000-0000-0000-000000000002', 'c218-t@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2180000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum'),
  ('c2180000-0000-0000-0000-000000000002', 'pharmacien', null, 'Titulaire T Kaloum');
update public.pharmacies set manager_id = 'c2180000-0000-0000-0000-000000000002'
  where id = '55555555-5555-5555-5555-555555550001';
-- C205 : une vente ou un remboursement en especes exige une caisse ouverte du
-- vendeur ; caisses ouvertes ici pour les identites qui vendent ou remboursent.
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', 'c2180000-0000-0000-0000-000000000001', 0, 'open');

-- Paracétamol à Kaloum : prix 1 500, un lot de test de 50 unités.
update public.stock_items set unit_price = 1500
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select 'c2180000-0000-0000-0000-0000000000b1', si.id, 'C218-LOT', current_date - 100, current_date + 30, 50, 0, now()
  from public.stock_items si
  where si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';

\set A 'c2180000-0000-0000-0000-000000000001'
\set T 'c2180000-0000-0000-0000-000000000002'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set PARA '33333333-3333-3333-3333-333333330001'
\set LOT 'c2180000-0000-0000-0000-0000000000b1'

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

-- Vente de p_qty Paracétamol au prix p_price, par produit (lots choisis par
-- le serveur) ou par lot désigné.
create function pg_temp.sell(p_case text, p_qty int, p_price int, p_by_batch boolean) returns void language plpgsql as $$
begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', p_qty * p_price, 0, 0, p_qty * p_price,
    jsonb_build_array(jsonb_build_object(
      'product_id', '33333333-3333-3333-3333-333333330001', 'product_name', 'Paracetamol',
      'quantity', p_qty, 'unit_price', p_price, 'total_price', p_qty * p_price,
      'batch_id', case when p_by_batch then 'c2180000-0000-0000-0000-0000000000b1' end)));
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.sales() returns bigint language sql as $$
  select count(*) from public.pos_sales where pharmacy_id = '55555555-5555-5555-5555-555555550001'
$$;

-- ==================== C218 : prix imposé ====================
select pg_temp.sales() as n0 \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('1', 2, 1500, false);
select pg_temp.sell('2', 2, 1000, false);
select pg_temp.sell('3', 1, 1400, true);
reset role;
select pg_temp.expect('1', 'OK', pg_temp.sales() = :'n0'::int + 1, '; vente au prix du stock (1 500) acceptee');
select pg_temp.expect('2', '22023', true, '; prix inferieur au prix du stock refuse (ligne par produit)');
select pg_temp.expect('3', '22023', pg_temp.sales() = :'n0'::int + 1, '; prix different refuse aussi sur une ligne a lot designe ; rien d''ecrit');

update public.stock_items set unit_price = 0
  where pharmacy_id = :'KALOUM' and product_id = :'PARA';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('4', 1, 0, false);
reset role;
select pg_temp.expect('4', '22023', true, '; prix de vente non renseigne : vente refusee, meme a 0');
update public.stock_items set unit_price = 1500
  where pharmacy_id = :'KALOUM' and product_id = :'PARA';

select pg_temp.as_user(:'A'); set local role authenticated;
do $$ begin
  perform public.pos_check_unit_price('X', 1, 1);
  insert into t_out values ('5', 'OK', null);
exception when others then insert into t_out values ('5', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('5', '42501', true, '; controle interne non appelable par les clients');

-- ==================== C210 : officine suspendue ====================
select pg_temp.as_user(:'A'); set local role authenticated;
select public.is_pharmacy_staff(:'KALOUM') as staff_before,
       (select count(*) from public.pos_sales where pharmacy_id = :'KALOUM') as sales_seen_before \gset
reset role;

update public.pharmacies set status = 'suspended' where id = :'KALOUM';

select pg_temp.as_user(:'A'); set local role authenticated;
select public.is_pharmacy_staff(:'KALOUM') as staff_susp,
       public.is_any_pharmacy_staff() as any_susp,
       public.has_verified_role(array['pharmacien']) as role_susp,
       (select count(*) from public.pos_sales where pharmacy_id = :'KALOUM') as sales_seen_susp \gset
select pg_temp.sell('7', 1, 1500, false);
do $$ begin
  perform * from public.pos_search_stock_products('55555555-5555-5555-5555-555555550001', null, 5);
  insert into t_out values ('7-recherche', 'OK', null);
exception when others then insert into t_out values ('7-recherche', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.stock_apply_movement('c2180000-0000-0000-0000-0000000000b1', -1, 'sale', null, 'Test C210');
  insert into t_out values ('7-stock', 'OK', null);
exception when others then insert into t_out values ('7-stock', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'T'); set local role authenticated;
do $$ begin
  perform * from public.pharmacy_list_staff('55555555-5555-5555-5555-555555550001');
  insert into t_out values ('8', 'OK', null);
exception when others then insert into t_out values ('8', sqlstate, sqlerrm);
end $$;
reset role;

select pg_temp.verdict('6',
  :'staff_before'::boolean and :'sales_seen_before'::int >= 1
  and not :'staff_susp'::boolean and not :'any_susp'::boolean and not :'role_susp'::boolean
  and :'sales_seen_susp' = '0',
  format('officine suspendue : is_pharmacy_staff %s -> %s, is_any_pharmacy_staff %s, has_verified_role(pharmacien) %s, ventes visibles %s -> %s',
    :'staff_before', :'staff_susp', :'any_susp', :'role_susp', :'sales_seen_before', :'sales_seen_susp'));
select pg_temp.expect('7', '42501', true, '; vente refusee');
select pg_temp.expect('7-recherche', '42501', true, '; recherche en stock refusee');
select pg_temp.expect('7-stock', '42501', (select quantity = 48 from public.stock_batches where id = :'LOT'), '; mouvement de stock refuse, lot intact');
select pg_temp.expect('8', '42501', true, '; le titulaire ne gere plus le personnel');
select pg_temp.verdict('6-rattachement', (select pharmacy_id = :'KALOUM' from public.profiles where id = :'A'),
  'rattachement de A conserve (non efface par la suspension)');

-- Autres statuts non actifs.
create temp table t_status (status text, staff boolean);
grant all on t_status to authenticated;
do $$
declare s text;
begin
  foreach s in array array['pending', 'underReview', 'rejected', 'verified', 'active'] loop
    update public.pharmacies set status = s where id = '55555555-5555-5555-5555-555555550001';
    perform set_config('request.jwt.claims', json_build_object('sub', 'c2180000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);
    insert into t_status values (s, public.is_pharmacy_staff('55555555-5555-5555-5555-555555550001'));
  end loop;
end $$;
select pg_temp.verdict('9',
  (select bool_and(not staff) from t_status where status in ('pending', 'underReview', 'rejected'))
  and (select bool_and(staff) from t_status where status in ('verified', 'active')),
  (select string_agg(status || '=' || staff, ', ' order by status) from t_status));

-- Réactivation : l'accès revient sans nouveau rattachement.
update public.pharmacies set status = 'active' where id = :'KALOUM';
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('10', 1, 1500, false);
reset role;
select pg_temp.expect('10', 'OK', true, '; officine reactivee : A vend de nouveau');

rollback;
