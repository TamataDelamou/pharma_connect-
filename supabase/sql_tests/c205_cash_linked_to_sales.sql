-- C205 (décision D62) : caisse reliée aux ventes et aux remboursements, et
-- sécurisation du module de caisse (ouverture, dépôts / retraits,
-- fermeture, solde attendu, droits, résumé de session).
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c205_cash_linked_to_sales.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- A, E : pharmaciens de Kaloum ; T : titulaire de Kaloum ; B : pharmacien de Dixinn ; PAT : patient.
insert into auth.users (id, email) values
  ('c2050000-0000-0000-0000-000000000001', 'c205-a@test.local'),
  ('c2050000-0000-0000-0000-000000000002', 'c205-e@test.local'),
  ('c2050000-0000-0000-0000-000000000003', 'c205-t@test.local'),
  ('c2050000-0000-0000-0000-000000000004', 'c205-b@test.local'),
  ('c2050000-0000-0000-0000-000000000005', 'c205-p@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2050000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A'),
  ('c2050000-0000-0000-0000-000000000002', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien E'),
  ('c2050000-0000-0000-0000-000000000003', 'pharmacien', null, 'Titulaire T'),
  ('c2050000-0000-0000-0000-000000000004', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn'),
  ('c2050000-0000-0000-0000-000000000005', 'patient', null, 'Patient');
update public.pharmacies set manager_id = 'c2050000-0000-0000-0000-000000000003'
  where id = '55555555-5555-5555-5555-555555550001';

-- Paracétamol à Kaloum : prix 1 500, un lot de 100 unités.
update public.stock_items set unit_price = 1500
  where pharmacy_id = '55555555-5555-5555-5555-555555550001' and product_id = '33333333-3333-3333-3333-333333330001';
insert into public.stock_batches (stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select si.id, 'C205-LOT', current_date - 100, current_date + 30, 100, 0, now()
  from public.stock_items si
  where si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = '33333333-3333-3333-3333-333333330001';

\set A 'c2050000-0000-0000-0000-000000000001'
\set E 'c2050000-0000-0000-0000-000000000002'
\set T 'c2050000-0000-0000-0000-000000000003'
\set B 'c2050000-0000-0000-0000-000000000004'
\set PAT 'c2050000-0000-0000-0000-000000000005'
\set KALOUM '55555555-5555-5555-5555-555555550001'

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

-- Vente de p_qty Paracétamol (1 500) avec le moyen p_method ; identifiant dans t_ctx(p_case).
create function pg_temp.sell(p_case text, p_qty int, p_method text) returns void language plpgsql as $$
begin
  insert into t_ctx values (p_case, public.pos_create_sale('55555555-5555-5555-5555-555555550001', p_method,
    p_qty * 1500, 0, 0, p_qty * 1500,
    jsonb_build_array(jsonb_build_object(
      'product_id', '33333333-3333-3333-3333-333333330001', 'product_name', 'Paracetamol',
      'quantity', p_qty, 'unit_price', 1500, 'total_price', p_qty * 1500)))::text);
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.try(p_case text, p_sql text) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.session_of(u uuid) returns uuid language sql as $$
  select id from public.cash_drawer_sessions
   where cashier_id = u and pharmacy_id = '55555555-5555-5555-5555-555555550001'
   order by opened_at desc limit 1
$$;

-- ==================== Ouverture ====================
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select pg_temp.try('1', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', null, 0, null)$q$);
reset role;
select pg_temp.as_user(:'PAT'); set local role authenticated;
select pg_temp.try('2a', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', null, 0, null)$q$);
reset role;
select pg_temp.as_user(:'B'); set local role authenticated;
select pg_temp.try('2b', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', null, 0, null)$q$);
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('3a', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', 'c2050000-0000-0000-0000-000000000002', 0, null)$q$);
select pg_temp.try('3b', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', 'c2050000-0000-0000-0000-000000000001', 10000, 'Matin')$q$);
select pg_temp.try('3c', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', null, 5000, null)$q$);
reset role;
select pg_temp.expect('1', '42501', true, '; anon ne peut plus ouvrir de caisse');
select pg_temp.expect('2a', '42501', true, '; un patient non plus');
select pg_temp.expect('2b', '42501', true, '; ni le personnel d''une autre officine');
select pg_temp.expect('3a', '42501', pg_temp.session_of(:'E') is null, '; A ne peut pas ouvrir une caisse au nom de E');
select pg_temp.expect('3b', 'OK',
  (select opening_balance = 10000 and status = 'open' and cashier_id = :'A' from public.cash_drawer_sessions where id = pg_temp.session_of(:'A')),
  '; A ouvre sa caisse avec 10 000');
select pg_temp.expect('3c', '22023', (select count(*) = 1 from public.cash_drawer_sessions where cashier_id = :'A'),
  '; une seule caisse ouverte par caissier');

-- ==================== Ventes ====================
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.sell('4', 2, 'cash');
select pg_temp.sell('6', 3, 'mobile_money');
reset role;
select pg_temp.as_user(:'E'); set local role authenticated;
select pg_temp.sell('5a', 1, 'cash');
select pg_temp.sell('5b', 1, 'card');
reset role;
select pg_temp.expect('4', 'OK',
  (select cash_drawer_session_id = pg_temp.session_of(:'A') from public.pos_sales where id = (select v::uuid from t_ctx where k = '4'))
  and exists (select 1 from public.cash_movements where reference_id = (select v from t_ctx where k = '4')
              and type = 'sale' and amount = 3000 and payment_method = 'cash' and cash_drawer_session_id = pg_temp.session_of(:'A')),
  '; vente en especes de 3 000 enregistree dans la caisse de A');
select pg_temp.expect('5a', '22023', true, '; E sans caisse ouverte ne vend pas en especes');
select pg_temp.expect('5b', 'OK',
  not exists (select 1 from public.cash_movements where reference_id = (select v from t_ctx where k = '5b')),
  '; E vend par carte sans caisse (aucun mouvement)');
select pg_temp.expect('6', 'OK',
  exists (select 1 from public.cash_movements where reference_id = (select v from t_ctx where k = '6')
          and type = 'sale' and amount = 4500 and payment_method = 'mobile_money'),
  '; vente mobile money de 4 500 tracee dans la caisse de A');

-- ==================== Dépôts et retraits ====================
-- C273 (c) : après la première vente, dépôt et retrait réservés au titulaire,
-- motif obligatoire. Les écritures de 7a à 7c passent donc par le titulaire ;
-- 7g et 7h montrent le refus pour le caissier et sans motif.
select v as s_a from (select pg_temp.session_of(:'A')::text as v) x \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('7d', format('select public.cash_add_movement(%L, %L, 1000, %L)', :'s_a', 'sale', 'Vente'));
select pg_temp.try('7g', format('select public.cash_add_movement(%L, %L, 2000, %L)', :'s_a', 'deposit', 'Monnaie'));
reset role;
select pg_temp.as_user(:'E'); set local role authenticated;
select pg_temp.try('7e', format('select public.cash_add_movement(%L, %L, 100, %L)', :'s_a', 'deposit', 'Essai'));
reset role;
select pg_temp.as_user(:'T'); set local role authenticated;
select pg_temp.try('7a', format('select public.cash_add_movement(%L, %L, 2000, %L)', :'s_a', 'deposit', 'Monnaie'));
select pg_temp.try('7b', format('select public.cash_add_movement(%L, %L, 500, %L)', :'s_a', 'withdrawal', 'Achat fournitures'));
select pg_temp.try('7c', format('select public.cash_add_movement(%L, %L, 999999, %L)', :'s_a', 'withdrawal', 'Essai'));
select pg_temp.try('7h', format('select public.cash_add_movement(%L, %L, 100, null)', :'s_a', 'deposit'));
select pg_temp.try('7f', format('select public.cash_add_movement(%L, %L, 1000, %L)', :'s_a', 'deposit', 'Apport titulaire'));
reset role;
select pg_temp.expect('7a', 'OK', true, '; depot de 2 000 (titulaire)');
select pg_temp.expect('7b', 'OK', true, '; retrait de 500 (titulaire)');
select pg_temp.expect('7c', '22023', true, '; retrait superieur aux especes attendues refuse');
select pg_temp.expect('7d', '22023', true, '; une vente ne se saisit pas a la main');
select pg_temp.expect('7e', '42501', true, '; E ne touche pas a la caisse de A');
select pg_temp.expect('7f', 'OK', true, '; le titulaire peut deposer dans la caisse de A');
select pg_temp.expect('7g', '42501', true, '; C273 : apres une vente, le caissier ne depose plus');
select pg_temp.expect('7h', '22023', true, '; C273 : depot sans motif refuse');

-- ==================== Écritures directes interdites ====================
select count(*) as mv_before from public.cash_movements where cash_drawer_session_id = :'s_a' \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('8a', format('insert into public.cash_movements (cash_drawer_session_id, type, amount) values (%L, %L, 50000)', :'s_a', 'deposit'));
delete from public.cash_movements where cash_drawer_session_id = :'s_a' and type = 'withdrawal';
update public.cash_movements set amount = 1 where cash_drawer_session_id = :'s_a';
update public.cash_drawer_sessions set expected_balance = 999999, opening_balance = 999999 where id = :'s_a';
reset role;
select pg_temp.expect('8a', '42501', true, '; insertion directe d''un mouvement refusee');
select pg_temp.verdict('8b',
  (select count(*) from public.cash_movements where cash_drawer_session_id = :'s_a') = :'mv_before'::int
  and not exists (select 1 from public.cash_movements where cash_drawer_session_id = :'s_a' and amount = 1)
  and (select opening_balance = 10000 from public.cash_drawer_sessions where id = :'s_a'),
  'suppression et modification directes sans effet : mouvements et session intacts');

-- ==================== Remboursements ====================
select pg_temp.as_user(:'E'); set local role authenticated;
select pg_temp.try('9a', format('select public.pos_refund_sale(%L, %L, %L)', (select v from t_ctx where k = '4'), 'Erreur de produit', 'restock'));
select pg_temp.try('9b', $q$select public.open_cash_drawer('55555555-5555-5555-5555-555555550001', null, 5000, null)$q$);
select pg_temp.try('9c', format('select public.pos_refund_sale(%L, %L, %L)', (select v from t_ctx where k = '4'), 'Erreur de produit', 'restock'));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('10', format('select public.pos_refund_sale(%L, %L, %L)', (select v from t_ctx where k = '6'), 'Doublon', 'restock'));
reset role;
select pg_temp.expect('9a', '22023', true, '; E sans caisse ne rembourse pas une vente en especes');
select pg_temp.expect('9c', 'OK',
  exists (select 1 from public.cash_movements where reference_id = (select v from t_ctx where k = '4')
          and type = 'refund' and amount = 3000 and payment_method = 'cash' and cash_drawer_session_id = pg_temp.session_of(:'E')),
  '; apres ouverture, remboursement en especes sorti de la caisse de E');
select pg_temp.expect('10', 'OK',
  exists (select 1 from public.cash_movements where reference_id = (select v from t_ctx where k = '6')
          and type = 'refund' and amount = 4500 and payment_method = 'mobile_money' and cash_drawer_session_id = pg_temp.session_of(:'A')),
  '; remboursement mobile money trace dans la caisse de A (moyen d''origine)');

-- ==================== Résumé et solde attendu ====================
-- A : fonds 10 000 + vente especes 3 000 + depots 3 000 - retrait 500 = 15 500
-- (vente et remboursement mobile money 4 500 traces a part).
select pg_temp.as_user(:'A'); set local role authenticated;
select total_sales, total_refunds, total_deposits, total_withdrawals, total_non_cash_sales,
       total_non_cash_refunds, current_expected_cash
  from public.cash_summary where session_id = :'s_a' \gset sa_
reset role;
select pg_temp.verdict('11',
  :'sa_total_sales' = '3000' and :'sa_total_refunds' = '0' and :'sa_total_deposits' = '3000'
  and :'sa_total_withdrawals' = '500' and :'sa_total_non_cash_sales' = '4500'
  and :'sa_total_non_cash_refunds' = '4500' and :'sa_current_expected_cash' = '15500',
  format('caisse de A : ventes especes %s, depots %s, retraits %s, autres moyens %s / %s, especes attendues %s',
    :'sa_total_sales', :'sa_total_deposits', :'sa_total_withdrawals', :'sa_total_non_cash_sales',
    :'sa_total_non_cash_refunds', :'sa_current_expected_cash'));

-- ==================== Fermeture ====================
select pg_temp.as_user(:'E'); set local role authenticated;
select pg_temp.try('12a', format('select public.close_cash_drawer(%L, 15500, null)', :'s_a'));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('12b', format('select public.close_cash_drawer(%L, 15400, %L)', :'s_a', 'Manque 100'));
select pg_temp.try('12c', format('select public.close_cash_drawer(%L, 15400, null)', :'s_a'));
select pg_temp.sell('12d', 1, 'cash');
reset role;
select pg_temp.expect('12a', '42501', true, '; E ne ferme pas la caisse de A');
select pg_temp.expect('12b', 'OK',
  (select status = 'closed' and expected_balance = 15500 and closing_balance = 15400 and difference = -100
     from public.cash_drawer_sessions where id = :'s_a'),
  '; A ferme : attendu 15 500, compte 15 400, ecart -100');
select pg_temp.expect('12c', '22023', true, '; une session fermee ne se referme pas');
select pg_temp.expect('12d', '22023', true, '; caisse fermee : plus de vente en especes');

select pg_temp.as_user(:'T'); set local role authenticated;
select pg_temp.try('13', format('select public.close_cash_drawer(%L, 2000, null)', pg_temp.session_of(:'E')));
reset role;
-- E : fonds 5 000 - remboursement especes 3 000 = 2 000.
select pg_temp.expect('13', 'OK',
  (select status = 'closed' and expected_balance = 2000 and difference = 0 from public.cash_drawer_sessions where id = pg_temp.session_of(:'E')),
  '; le titulaire ferme la caisse de E (attendu 2 000, ecart 0)');

-- ==================== Cloisonnement et droits ====================
select pg_temp.as_user(:'B'); set local role authenticated;
select (select count(*) from public.cash_drawer_sessions where pharmacy_id = :'KALOUM') as b_sessions,
       (select count(*) from public.cash_summary where pharmacy_id = :'KALOUM') as b_summary,
       (select count(*) from public.cash_movements m join public.cash_drawer_sessions s on s.id = m.cash_drawer_session_id where s.pharmacy_id = :'KALOUM') as b_moves \gset
reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select pg_temp.try('14-anon', 'select count(*) from public.cash_summary');
reset role;
select pg_temp.verdict('14', :'b_sessions' = '0' and :'b_summary' = '0' and :'b_moves' = '0',
  format('B (Dixinn) ne voit ni les caisses (%s), ni le resume (%s), ni les mouvements (%s) de Kaloum', :'b_sessions', :'b_summary', :'b_moves'));
select pg_temp.expect('14-anon', '42501', true, '; resume de caisse refuse a anon');
select pg_temp.verdict('15',
  not has_function_privilege('anon', 'public.open_cash_drawer(uuid, uuid, integer, text)', 'execute')
  and not has_function_privilege('anon', 'public.close_cash_drawer(uuid, integer, text)', 'execute')
  and not has_function_privilege('anon', 'public.cash_add_movement(uuid, text, integer, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.cash_expected_balance(uuid)', 'execute')
  and has_function_privilege('authenticated', 'public.open_cash_drawer(uuid, uuid, integer, text)', 'execute')
  and (select relkind = 'v' from pg_class where oid = 'public.cash_summary'::regclass),
  'execute : anon refuse (ouverture, fermeture, mouvement), calcul interne ferme ; cash_summary est une vue ordinaire');

rollback;
