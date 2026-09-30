-- C204 : règle de remboursement POS (décision D57) et destination du stock
-- rendu. Chaque cas affiche une ligne « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Identités (créées dans la transaction) :
--   T : titulaire de Kaloum. Profil 'pharmacien' créé sans pharmacy_id, puis
--       pharmacies.manager_id = T : le déclencheur C208 le rattache à Kaloum
--       (vérifié au cas 5). L'accès exige is_pharmacy_staff() ; le statut de
--       titulaire ne lève que la règle jour/plafond ;
--   E : pharmacien de Kaloum, non titulaire ;
--   B : pharmacien de Dixinn.
-- Lots de Kaloum : L1 = LOT-2026-0009, L2 = LOT-2026-0017, portés à 200.
-- Vieillissement d'une vente (en tant que postgres) :
--   update pos_sales set created_at = now() - interval '1 day'.
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c204_pos_refund_policy.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Identités et données ====================
insert into auth.users (id, email) values
  ('71000000-0000-0000-0000-000000000001', 'c204-t@test.local'),
  ('e1000000-0000-0000-0000-000000000001', 'c204-e@test.local'),
  ('b1000000-0000-0000-0000-000000000001', 'c204-b@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('71000000-0000-0000-0000-000000000001', 'pharmacien', null, 'Titulaire T Kaloum'),
  ('e1000000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien E Kaloum'),
  ('b1000000-0000-0000-0000-000000000001', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn');
update public.pharmacies set manager_id = '71000000-0000-0000-0000-000000000001'
  where id = '55555555-5555-5555-5555-555555550001';
-- C205 : une vente ou un remboursement en especes exige une caisse ouverte du
-- vendeur ; caisses ouvertes ici pour les identites qui vendent ou remboursent.
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', '71000000-0000-0000-0000-000000000001', 0, 'open'),
  ('55555555-5555-5555-5555-555555550001', 'e1000000-0000-0000-0000-000000000001', 0, 'open'),
  ('55555555-5555-5555-5555-555555550002', 'b1000000-0000-0000-0000-000000000001', 0, 'open');

update public.stock_batches b set quantity = 200
  from public.stock_items si
  where si.id = b.stock_item_id and b.batch_number in ('LOT-2026-0009', 'LOT-2026-0017')
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001';
-- C218 : le serveur impose le prix du stock ; prix de vente des lots de test
-- alignés sur ceux des lignes de ce fichier (L1 1 500, L2 2 000).
update public.stock_items si set unit_price = case b.batch_number when 'LOT-2026-0009' then 1500 else 2000 end
  from public.stock_batches b
  where b.stock_item_id = si.id and b.batch_number in ('LOT-2026-0009', 'LOT-2026-0017')
    and si.pharmacy_id = '55555555-5555-5555-5555-555555550001';

create temp table t_ctx (k text primary key, v text);
create temp table t_out (c text primary key, state text, msg text);
grant all on t_ctx, t_out to authenticated, anon;

insert into t_ctx
  select 'L1', b.id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0009' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
  union all
  select 'L2', b.id::text from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
    where b.batch_number = 'LOT-2026-0017' and si.pharmacy_id = '55555555-5555-5555-5555-555555550001';

select v as l1 from t_ctx where k = 'L1' \gset
select v as l2 from t_ctx where k = 'L2' \gset
\set T '71000000-0000-0000-0000-000000000001'
\set E 'e1000000-0000-0000-0000-000000000001'
\set B 'b1000000-0000-0000-0000-000000000001'
\set PA '55555555-5555-5555-5555-555555550001'

-- ==================== Outils ====================
create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- Petite vente du jour par E : 1 x L1 à 1 500 (sous le plafond).
create function pg_temp.items_small() returns jsonb language sql as $$
  select jsonb_build_array(jsonb_build_object('product_name', 'Produit L1', 'quantity', 1,
    'unit_price', 1500, 'total_price', 1500, 'batch_id', (select v from t_ctx where k = 'L1')))
$$;

create function pg_temp.snap() returns text language sql as $$
  select format('rembourses=%s quarantaine=%s mvts=%s L1=%s L2=%s',
    (select count(*) from public.pos_sales where status = 'refunded'),
    (select count(*) from public.pos_refund_quarantine),
    (select count(*) from public.stock_movements),
    (select quantity from public.stock_batches where id = (select v::uuid from t_ctx where k = 'L1')),
    (select quantity from public.stock_batches where id = (select v::uuid from t_ctx where k = 'L2')))
$$;

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
  if coalesce(p_ok, false) then
    raise notice 'CAS % OK : %', p_case, p_detail;
  else
    raise notice 'CAS % ECHEC : %', p_case, p_detail;
  end if;
end;
$$;

\echo '===== Etat initial'
select pg_temp.snap();

-- ==================== Ventes de E (toutes du jour) ====================
select pg_temp.as_user(:'E');
set local role authenticated;
-- s1, s2 : 2 lignes (L1 + L2), sous le plafond.
select public.pos_create_sale(:'PA', 'cash', 5000, 0, 0, 5000,
  jsonb_build_array(
    jsonb_build_object('product_name', 'Produit L1', 'quantity', 2, 'unit_price', 1500, 'total_price', 3000, 'batch_id', :'l1'),
    jsonb_build_object('product_name', 'Produit L2', 'quantity', 1, 'unit_price', 2000, 'total_price', 2000, 'batch_id', :'l2'))) as s1 \gset
select public.pos_create_sale(:'PA', 'cash', 6500, 0, 0, 6500,
  jsonb_build_array(
    jsonb_build_object('product_name', 'Produit L1', 'quantity', 3, 'unit_price', 1500, 'total_price', 4500, 'batch_id', :'l1'),
    jsonb_build_object('product_name', 'Produit L2', 'quantity', 1, 'unit_price', 2000, 'total_price', 2000, 'batch_id', :'l2'))) as s2 \gset
-- s3 : au-dessus du plafond (150 000 > 100 000) : 100 x L1 à 1 500 (C218 : prix du stock).
select public.pos_create_sale(:'PA', 'cash', 150000, 0, 0, 150000,
  jsonb_build_array(jsonb_build_object('product_name', 'Produit L1', 'quantity', 100, 'unit_price', 1500, 'total_price', 150000, 'batch_id', :'l1'))) as s3 \gset
-- s4 : petite vente, vieillie d'un jour ; s6 : petite vente du jour.
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 0, 1500, pg_temp.items_small()) as s4 \gset
select public.pos_create_sale(:'PA', 'cash', 1500, 0, 0, 1500, pg_temp.items_small()) as s6 \gset
reset role;
insert into t_ctx values ('S1', :'s1'), ('S2', :'s2'), ('S3', :'s3'), ('S4', :'s4'), ('S6', :'s6');
update public.pos_sales set created_at = now() - interval '1 day' where id in (:'s3', :'s4');
\echo '===== Apres les ventes de E'
select pg_temp.snap();

-- ==================== Cas 1 : E, jour même, sous plafond, restock ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
select public.pos_refund_sale(:'s1', 'Boite intacte, erreur de produit', 'restock');
reset role;
select pg_temp.verdict('1',
  (select status = 'refunded' and refunded_at is not null and refunded_by = :'E'
          and refund_reason = 'Boite intacte, erreur de produit' and refund_stock_disposition = 'restock'
     from public.pos_sales where id = :'s1')
  and (select count(*) = 2 from public.stock_movements where reference_id = :'s1' and type = 'adjustment')
  and (select count(*) = 0 from public.pos_refund_quarantine where sale_id = :'s1'),
  (select format('refunded_by=E %s, motif « %s », destination %s, ', refunded_by = :'E', refund_reason, refund_stock_disposition)
     from public.pos_sales where id = :'s1')
  || (select string_agg(format('%s +%s', type, quantity), ', ' order by quantity) from public.stock_movements where reference_id = :'s1' and type = 'adjustment')
  || format(' ; avant [%s] apres [%s]', :'before', pg_temp.snap()));

-- ==================== Cas 2 : E, jour même, sous plafond, quarantine ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
select public.pos_refund_sale(:'s2', 'Boite ouverte par le patient', 'quarantine');
reset role;
select pg_temp.verdict('2',
  (select status = 'refunded' and refund_stock_disposition = 'quarantine' and refunded_by = :'E' from public.pos_sales where id = :'s2')
  and (select count(*) = 0 from public.stock_movements where reference_id = :'s2' and type = 'adjustment')
  and (select count(*) = 2 and bool_and(q.status = 'quarantined' and q.pharmacy_id = :'PA'
                                         and q.reason = 'Boite ouverte par le patient' and q.created_by = :'E'
                                         and q.quantity = si.quantity and q.batch_id = si.batch_id
                                         and q.sale_item_id = si.id)
         from public.pos_refund_quarantine q join public.pos_sale_items si on si.id = q.sale_item_id
         where q.sale_id = :'s2')
  and regexp_replace(pg_temp.snap(), '^.* mvts=', '') = regexp_replace(:'before', '^.* mvts=', ''),
  (select string_agg(format('%s x%s %s', product_name, quantity, status), ', ' order by quantity)
     from public.pos_refund_quarantine where sale_id = :'s2')
  || format(' ; stock inchange : avant [%s] apres [%s]', :'before', pg_temp.snap()));

-- ==================== Cas 3 : E, vente au-dessus du plafond ====================
-- s3 est aussi vieillie : on la rajeunit pour isoler le plafond, puis on la
-- revieillit pour le cas 5.
update public.pos_sales set created_at = now() where id = :'s3';
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S3'), 'Erreur de caisse', 'restock');
exception when others then insert into t_out values ('3', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('3', '42501', 'reserve au titulaire (montant 150000 superieur au plafond 100000)', :'before');
update public.pos_sales set created_at = now() - interval '1 day' where id = :'s3';

-- ==================== Cas 4 : E, vente de la veille, sous plafond ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S4'), 'Erreur de caisse', 'restock');
exception when others then insert into t_out values ('4', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('4', '42501', 'reserve au titulaire (vente d''un jour precedent)', :'before');

-- ==================== Cas 5 : T, vente de la veille au-dessus du plafond ====================
select pg_temp.as_user(:'T');
select public.is_pharmacy_staff(:'PA') as t_staff \gset
set local role authenticated;
select public.pos_refund_sale(:'s3', 'Remboursement valide par le titulaire', 'restock');
reset role;
select pg_temp.verdict('5',
  (select status = 'refunded' and refunded_by = :'T' and final_amount = 150000
          and created_at < now() - interval '23 hours' from public.pos_sales where id = :'s3')
  and :'t_staff'::boolean
  and (select pharmacy_id = :'PA' from public.profiles where id = :'T'),
  (select format('vente %s de la veille, %s GNF, remboursee par T (%s) ; T rattache a Kaloum par C208, is_pharmacy_staff(T) = %s',
                 sale_number, final_amount, refunded_by = :'T', :'t_staff') from public.pos_sales where id = :'s3'));

-- ==================== Cas 6 : motif absent, vide, 2 caractères ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), null, 'restock');
exception when others then insert into t_out values ('6a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), '   ', 'restock');
exception when others then insert into t_out values ('6b', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'ab', 'restock');
exception when others then insert into t_out values ('6c', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('6a', '22023', 'motif du remboursement obligatoire', :'before');
select pg_temp.expect_err('6b', '22023', 'motif du remboursement obligatoire', :'before');
select pg_temp.expect_err('6c', '22023', 'motif du remboursement obligatoire', :'before');

-- ==================== Cas 7 : destination null ou inconnue ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'Motif valide', null);
exception when others then insert into t_out values ('7a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'Motif valide', 'autre');
exception when others then insert into t_out values ('7b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('7a', '22023', 'destination du stock a preciser', :'before');
select pg_temp.expect_err('7b', '22023', 'destination du stock a preciser', :'before');

-- ==================== Cas 8 : second remboursement ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S1'), 'Deuxieme essai', 'restock');
exception when others then insert into t_out values ('8a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S2'), 'Deuxieme essai', 'quarantine');
exception when others then insert into t_out values ('8b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('8a', '22023', 'statut refunded', :'before');
select pg_temp.expect_err('8b', '22023', 'statut refunded', :'before');

-- ==================== Cas 9 : B rembourse une vente de Kaloum ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'B');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'Motif valide', 'restock');
exception when others then insert into t_out values ('9', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('9', '42501', 'acces refuse a cette officine', :'before');

-- ==================== Cas 10 : plafond de Kaloum à 0 ====================
update public.pharmacies set pos_refund_staff_limit = 0 where id = :'PA';
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'Motif valide', 'restock');
exception when others then insert into t_out values ('10', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('10', '42501', 'montant 1500 superieur au plafond 0', :'before');
update public.pharmacies set pos_refund_staff_limit = 100000 where id = :'PA';

-- ==================== Cas 11 : anon ====================
select pg_temp.snap() as before \gset
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform public.pos_refund_sale((select v::uuid from t_ctx where k = 'S6'), 'Motif valide', 'restock');
exception when others then insert into t_out values ('11', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('11', '42501', 'permission denied for function pos_refund_sale', :'before');
select pg_temp.verdict('11-droits',
  not has_function_privilege('anon', 'public.pos_refund_sale(uuid, text, text)', 'execute')
  and has_function_privilege('authenticated', 'public.pos_refund_sale(uuid, text, text)', 'execute'),
  'execute sur pos_refund_sale(uuid, text, text) : anon refuse, authenticated accorde');

-- ==================== Cas 12 : une seule fonction pos_refund_sale ====================
select pg_temp.verdict('12',
  (select count(*) = 1 and bool_and(pg_get_function_identity_arguments(p.oid) = 'p_sale_id uuid, p_reason text, p_disposition text')
     from pg_proc p where p.proname = 'pos_refund_sale'),
  (select format('%s fonction(s) : %s', count(*), string_agg(n.nspname || '.pos_refund_sale(' || pg_get_function_identity_arguments(p.oid) || ')', ' ; '))
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace where p.proname = 'pos_refund_sale'));

-- ==================== Cas 13 : lecture de la quarantaine ====================
select pg_temp.as_user(:'E');
set local role authenticated;
select count(*) as q_e from public.pos_refund_quarantine \gset
reset role;
select pg_temp.as_user(:'B');
set local role authenticated;
select count(*) as q_b from public.pos_refund_quarantine \gset
reset role;
select pg_temp.as_user(:'T');
set local role authenticated;
select count(*) as q_t from public.pos_refund_quarantine \gset
reset role;
select pg_temp.verdict('13', :q_e = 2 and :q_b = 0 and :q_t = 2,
  format('E voit %s ligne(s) (cas 2), B voit %s, T (titulaire) voit %s', :q_e, :q_b, :q_t));

-- ==================== Cas 14 : insert direct par E ====================
select pg_temp.snap() as before \gset
select pg_temp.as_user(:'E');
set local role authenticated;
do $$ begin
  insert into public.pos_refund_quarantine (pharmacy_id, sale_id, product_name, quantity, reason)
    values ('55555555-5555-5555-5555-555555550001', (select v::uuid from t_ctx where k = 'S6'), 'Insert direct', 1, 'Contournement');
exception when others then insert into t_out values ('14', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect_err('14', '42501', 'row-level security', :'before');

\echo '===== Etat final (avant rollback)'
select pg_temp.snap();

rollback;
