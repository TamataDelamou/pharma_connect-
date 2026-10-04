-- C243 : réservation faite par le serveur (reservation_create,
-- reservation_mark_ready, reservation_cancel, reservation_pickup,
-- reservation_expire_overdue) et vente au comptoir qui respecte les boîtes
-- retenues.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c243_server_side_reservation.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- P1, P2 : patients. A : pharmacien de Kaloum, caisse ouverte. B : pharmacien
-- de Kaloum sans caisse. D : pharmacien de Dixinn.
insert into auth.users (id, email) values
  ('c2430000-0000-0000-0000-000000000001', 'c243-p1@test.local'),
  ('c2430000-0000-0000-0000-000000000002', 'c243-p2@test.local'),
  ('c2430000-0000-0000-0000-00000000000a', 'c243-a@test.local'),
  ('c2430000-0000-0000-0000-00000000000b', 'c243-b@test.local'),
  ('c2430000-0000-0000-0000-00000000000d', 'c243-d@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name, phone) values
  ('c2430000-0000-0000-0000-000000000001', 'patient', null, 'Patient Un', '+224620000001'),
  ('c2430000-0000-0000-0000-000000000002', 'patient', null, null, null),
  ('c2430000-0000-0000-0000-00000000000a', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum', null),
  ('c2430000-0000-0000-0000-00000000000b', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien B Kaloum', null),
  ('c2430000-0000-0000-0000-00000000000d', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien D Dixinn', null);
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('55555555-5555-5555-5555-555555550001', 'c2430000-0000-0000-0000-00000000000a', 0, 'open');

-- Stock de test à Kaloum (lots du seed vidés pour ces produits) :
--   Paracétamol, 1 500 : L1 (3 boîtes, péremption la plus proche), L2 (4) ;
--   Ibuprofène, 2 000, sur ordonnance : I1 (30) ;
--   Aspirine, 1 000 : S1 (10) — classée stupéfiant puis psychotrope dans les cas 6 ;
--   Doliprane, 1 200 : D1 (2), D2 (2).
insert into public.stock_items (pharmacy_id, product_id, unit_price, status)
  select '55555555-5555-5555-5555-555555550001', p.id::uuid, p.price, 'inStock'
  from (values ('33333333-3333-3333-3333-333333330001', 1500),
               ('33333333-3333-3333-3333-333333330002', 1200),
               ('33333333-3333-3333-3333-333333330003', 2000),
               ('33333333-3333-3333-3333-333333330004', 1000)) as p(id, price)
  on conflict (pharmacy_id, product_id) do update set unit_price = excluded.unit_price, status = 'inStock';
update public.stock_batches b set quantity = 0, quantity_reserved = 0
  from public.stock_items si
  where si.id = b.stock_item_id and si.pharmacy_id = '55555555-5555-5555-5555-555555550001'
    and si.product_id in ('33333333-3333-3333-3333-333333330001', '33333333-3333-3333-3333-333333330002',
                          '33333333-3333-3333-3333-333333330003', '33333333-3333-3333-3333-333333330004');
update public.stock_items set reserved_quantity = 0
  where pharmacy_id = '55555555-5555-5555-5555-555555550001'
    and product_id in ('33333333-3333-3333-3333-333333330001', '33333333-3333-3333-3333-333333330002',
                       '33333333-3333-3333-3333-333333330003', '33333333-3333-3333-3333-333333330004');
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select v.id::uuid, si.id, v.num, current_date - 100, current_date + v.days, v.qty, 0, now()
  from (values ('c2430000-0000-0000-0000-0000000000f1', '33333333-3333-3333-3333-333333330001', 'C243-L1', 20, 3),
               ('c2430000-0000-0000-0000-0000000000f2', '33333333-3333-3333-3333-333333330001', 'C243-L2', 60, 4),
               ('c2430000-0000-0000-0000-0000000000f3', '33333333-3333-3333-3333-333333330003', 'C243-I1', 60, 30),
               ('c2430000-0000-0000-0000-0000000000f4', '33333333-3333-3333-3333-333333330004', 'C243-S1', 60, 10),
               ('c2430000-0000-0000-0000-0000000000f5', '33333333-3333-3333-3333-333333330002', 'C243-D1', 20, 2),
               ('c2430000-0000-0000-0000-0000000000f6', '33333333-3333-3333-3333-333333330002', 'C243-D2', 60, 2)) as v(id, product, num, days, qty)
  join public.stock_items si on si.pharmacy_id = '55555555-5555-5555-5555-555555550001' and si.product_id = v.product::uuid;
update public.products set regulatory_class = 'sur_ordonnance', is_prescription_required = true
  where id = '33333333-3333-3333-3333-333333330003';
update public.products set regulatory_class = 'libre', is_prescription_required = false
  where id in ('33333333-3333-3333-3333-333333330001', '33333333-3333-3333-3333-333333330002', '33333333-3333-3333-3333-333333330004');

\set P1 'c2430000-0000-0000-0000-000000000001'
\set P2 'c2430000-0000-0000-0000-000000000002'
\set A 'c2430000-0000-0000-0000-00000000000a'
\set B 'c2430000-0000-0000-0000-00000000000b'
\set D 'c2430000-0000-0000-0000-00000000000d'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set PARA '33333333-3333-3333-3333-333333330001'
\set DOLI '33333333-3333-3333-3333-333333330002'
\set IBU '33333333-3333-3333-3333-333333330003'
\set ASPI '33333333-3333-3333-3333-333333330004'
\set L1 'c2430000-0000-0000-0000-0000000000f1'
\set L2 'c2430000-0000-0000-0000-0000000000f2'
\set I1 'c2430000-0000-0000-0000-0000000000f3'
\set D1 'c2430000-0000-0000-0000-0000000000f5'
\set D2 'c2430000-0000-0000-0000-0000000000f6'

create temp table t_out (c text primary key, state text, msg text, id uuid);
grant all on t_out to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- Exécute une requête qui rend un uuid ou rien (fonction void) et note le
-- résultat.
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

create function pg_temp.rid(p_case text) returns uuid language sql as $$ select id from t_out where c = p_case $$;
create function pg_temp.msg(p_case text) returns text language sql as $$ select coalesce(msg, '') from t_out where c = p_case $$;
create function pg_temp.qty(p_batch text) returns int language sql as $$ select quantity from public.stock_batches where id = p_batch::uuid $$;
create function pg_temp.held(p_batch text) returns int language sql as $$ select quantity_reserved from public.stock_batches where id = p_batch::uuid $$;
create function pg_temp.status(p_case text) returns text language sql as $$ select status from public.reservations where id = pg_temp.rid(p_case) $$;
create function pg_temp.nres() returns bigint language sql as $$
  select count(*) from public.reservations where pharmacy_id = '55555555-5555-5555-5555-555555550001'
$$;
-- Réservation d'un seul produit à Kaloum.
create function pg_temp.reserve(p_product text, p_qty int) returns text language sql as $$
  select format('select public.reservation_create(%L, %L::jsonb)', '55555555-5555-5555-5555-555555550001',
    jsonb_build_array(jsonb_build_object('product_id', p_product, 'quantity', p_qty, 'unit_price', 1))::text)
$$;
-- Vente au comptoir de Paracétamol au prix du stock, par produit ou sur un lot désigné.
create function pg_temp.sale(p_qty int, p_price int, p_batch text) returns text language sql as $$
  select format('select public.pos_create_sale(%L, ''cash'', %s, 0, 0, %s, %L::jsonb)', '55555555-5555-5555-5555-555555550001',
    p_qty * p_price, p_qty * p_price,
    jsonb_build_array(jsonb_build_object('product_id', '33333333-3333-3333-3333-333333330001', 'product_name', 'Paracetamol',
      'quantity', p_qty, 'unit_price', p_price, 'total_price', p_qty * p_price, 'batch_id', p_batch))::text)
$$;

-- ==================== 1. Réserver ====================
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('1', pg_temp.reserve(:'PARA', 4));
select available_quantity as dispo1 from public.patient_stock_availability(array[:'PARA']::uuid[], :'KALOUM') \gset
reset role;
select pg_temp.expect('1', 'OK',
  pg_temp.held(:'L1') = 3 and pg_temp.held(:'L2') = 1 and pg_temp.qty(:'L1') = 3 and pg_temp.qty(:'L2') = 4
  and :dispo1 = 3
  and (select status = 'pending' and patient_id = :'P1'::uuid and total_price = 6000 and patient_name = 'Patient Un'
              and pickup_deadline between now() + interval '23 hours 59 minutes' and now() + interval '24 hours 1 minute'
              and qr_code_token like 'qr_%'
         from public.reservations where id = pg_temp.rid('1'))
  and (select price_per_unit = 1500 and quantity = 4 from public.reservation_items where reservation_id = pg_temp.rid('1'))
  and (select reserved_quantity from public.stock_items where pharmacy_id = :'KALOUM' and product_id = :'PARA') = 4
  and (select count(*) from public.stock_movements where reference_id = pg_temp.rid('1')::text and type = 'reservation') = 2,
  '; 4 boites retenues (L1 3, L2 1, peremption la plus proche d''abord) ; disponible patient 3 ; echeance a 24 h ; prix du stock (1 500), prix envoye par l''application ignore');

select pg_temp.nres() as n0 \gset
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('2', pg_temp.reserve(:'PARA', 5));
reset role;
select pg_temp.expect('2', 'P0001',
  pg_temp.msg('2') like '%stock insuffisant pour Paracétamol (demande 5, disponible 3)%'
  and pg_temp.nres() = :n0 and pg_temp.held(:'L2') = 1,
  '; vendable insuffisant : refus, rien d''ecrit');

-- ==================== 2. Limites et produits non réservables ====================
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('3a', pg_temp.reserve(:'IBU', 6));
select pg_temp.try('3b', format('select public.reservation_create(%L, %L::jsonb)', :'KALOUM', '[]'));
select pg_temp.try('3c', format('select public.reservation_create(%L, %L::jsonb)', :'KALOUM',
  jsonb_build_array(jsonb_build_object('product_id', :'IBU', 'quantity', 1), jsonb_build_object('product_id', :'IBU', 'quantity', 1))::text));
select pg_temp.try('3d', pg_temp.reserve(:'IBU', 0));
reset role;
select pg_temp.expect('3a', '22023', pg_temp.msg('3a') like '%5 boites au plus%', '; 6 boites sur une ligne : refus (limite de l''officine : 5)');
select pg_temp.expect('3b', '22023', true, '; reservation vide : refus');
select pg_temp.expect('3c', '22023', true, '; meme produit sur deux lignes : refus');
select pg_temp.expect('3d', '22023', true, '; quantite nulle : refus');

select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('4', pg_temp.reserve(:'IBU', 2));
reset role;
select pg_temp.expect('4', 'OK',
  (select prescription_required from public.reservation_items where reservation_id = pg_temp.rid('4'))
  and pg_temp.held(:'I1') = 2
  and (select patient_name = 'c243-p2@test.local' from public.reservations where id = pg_temp.rid('4')),
  '; produit sur ordonnance : reservable, ligne marquee « ordonnance a presenter » ; patient sans nom : e-mail repris');

update public.products set regulatory_class = 'stupefiant' where id = :'ASPI';
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('5a', pg_temp.reserve(:'ASPI', 1));
reset role;
update public.products set regulatory_class = 'psychotrope' where id = :'ASPI';
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('5b', pg_temp.reserve(:'ASPI', 1));
reset role;
update public.products set regulatory_class = 'libre' where id = :'ASPI';
select pg_temp.expect('5a', '22023', pg_temp.msg('5a') like '%ne peut pas etre reserve%', '; stupefiant : reservation refusee');
select pg_temp.expect('5b', '22023', true, '; psychotrope : reservation refusee');

-- Au plus 3 réservations actives par patient dans l'officine.
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('6a', pg_temp.reserve(:'IBU', 1));
select pg_temp.try('6b', pg_temp.reserve(:'IBU', 1));
select pg_temp.try('6c', pg_temp.reserve(:'IBU', 1));
reset role;
select pg_temp.expect('6b', 'OK', true, '; 3e reservation active de P2 : acceptee');
select pg_temp.expect('6c', '22023', pg_temp.msg('6c') like '%deja 3 reservations en cours%(maximum 3)%' and pg_temp.held(:'I1') = 4,
  '; 4e reservation active : refus');
update public.pharmacies set reservation_max_active_per_patient = 4 where id = :'KALOUM';
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('6d', pg_temp.reserve(:'IBU', 1));
reset role;
select pg_temp.expect('6d', 'OK', pg_temp.held(:'I1') = 5, '; limite de l''officine portee a 4 : 4e reservation acceptee');
update public.pharmacies set reservation_max_active_per_patient = 3 where id = :'KALOUM';

update public.pharmacies set status = 'suspended' where id = :'KALOUM';
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('7a', pg_temp.reserve(:'IBU', 1));
reset role;
update public.pharmacies set status = 'active' where id = :'KALOUM';
set local role anon;
select pg_temp.try('7b', pg_temp.reserve(:'IBU', 1));
reset role;
select pg_temp.expect('7a', '22023', true, '; officine suspendue : reservation refusee');
select pg_temp.expect('7b', '42501', true, '; anonyme : refuse');

-- ==================== 3. Écritures directes fermées, lectures conservées ====================
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('8a', format('insert into public.reservations (patient_id, patient_name, patient_phone, pharmacy_id, pharmacy_name, pharmacy_address) values (%L, ''x'', ''x'', %L, ''x'', ''x'') returning id', :'P1', :'KALOUM'));
select pg_temp.try('8b', format('insert into public.reservation_items (reservation_id, product_id, product_name) values (%L, %L, ''x'') returning id', pg_temp.rid('1'), :'PARA'));
with u as (update public.reservations set status = 'pickedUp', total_price = 1 where id = pg_temp.rid('1') returning 1)
select count(*) as maj_patient from u \gset
select (select count(*) from public.reservations) as vues_p1,
       (select count(*) from public.reservation_items) as lignes_p1,
       (select count(*) from public.reservation_item_batches) as lots_p1 \gset
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
with u as (update public.reservations set status = 'cancelled' where id = pg_temp.rid('1') returning 1)
select count(*) as maj_staff from u \gset
select (select count(*) from public.reservations where id = pg_temp.rid('1')) as vues_a,
       (select count(*) from public.reservation_item_batches h join public.reservation_items ri on ri.id = h.reservation_item_id where ri.reservation_id = pg_temp.rid('1')) as lots_a \gset
reset role;
select pg_temp.as_user(:'D'); set local role authenticated;
select count(*) as vues_d from public.reservations where id = pg_temp.rid('1') \gset
reset role;
select pg_temp.expect('8a', '42501', true, '; insertion directe d''une reservation par un patient : refusee');
select pg_temp.expect('8b', '42501', true, '; insertion directe d''une ligne : refusee');
select pg_temp.verdict('8c', :maj_patient = 0 and :maj_staff = 0 and pg_temp.status('1') = 'pending'
  and (select total_price from public.reservations where id = pg_temp.rid('1')) = 6000,
  'modification directe (statut, montant) : ' || :maj_patient || ' ligne pour le patient, ' || :maj_staff || ' pour l''officine ; reservation inchangee');
select pg_temp.verdict('8d', :vues_p1 = 1 and :lignes_p1 = 1 and :lots_p1 = 0 and :vues_a = 1 and :lots_a = 2 and :vues_d = 0,
  'lecture : le patient voit sa reservation et sa ligne, aucun lot ; l''officine voit la reservation et ses 2 lots retenus ; une autre officine ne voit rien');

-- ==================== 4. Vente au comptoir et boîtes retenues ====================
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('9a', pg_temp.sale(4, 1500, null));
select pg_temp.try('9b', pg_temp.sale(1, 1500, :'L1'));
select pg_temp.try('9c', pg_temp.sale(5, 1500, :'L1'));
select pg_temp.try('9d', pg_temp.sale(3, 1500, null));
reset role;
select pg_temp.expect('9a', 'P0001', pg_temp.msg('9a') like '%stock insuffisant pour Paracetamol (demande 4, disponible 3)%',
  '; vente par produit de 4 boites : seules 3 sont libres, refus');
select pg_temp.expect('9b', 'P0001', pg_temp.msg('9b') like '%sur le lot C243-L1 (demande 1, disponible 0 hors boites reservees)%' and pg_temp.qty(:'L1') = 3,
  '; vente a lot designe d''une boite retenue : refus');
select pg_temp.expect('9c', 'P0001', pg_temp.msg('9c') like '%STK: stock insuffisant sur le lot%',
  '; lot designe sans assez de stock du tout : refus habituel, inchange');
select pg_temp.expect('9d', 'OK', pg_temp.qty(:'L1') = 3 and pg_temp.qty(:'L2') = 1 and pg_temp.held(:'L1') = 3 and pg_temp.held(:'L2') = 1,
  '; vente de 3 boites libres : prises sur L2, boites retenues intactes (L1 3/3, L2 1/1)');

-- ==================== 5. Prête ====================
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('10a', format('select public.reservation_mark_ready(%L)', pg_temp.rid('1')));
reset role;
select pg_temp.as_user(:'D'); set local role authenticated;
select pg_temp.try('10b', format('select public.reservation_mark_ready(%L)', pg_temp.rid('1')));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('10c', format('select public.reservation_mark_ready(%L)', pg_temp.rid('1')));
reset role;
select pg_temp.expect('10a', '42501', true, '; « prete » par le patient : refuse');
select pg_temp.expect('10b', '42501', true, '; « prete » par une autre officine : refuse');
select pg_temp.expect('10c', 'OK', pg_temp.status('1') = 'ready'
  and (select pickup_deadline < reserved_at + interval '24 hours 1 minute' from public.reservations where id = pg_temp.rid('1')),
  '; « prete » par l''officine ; echeance non prolongee');

-- ==================== 6. Retrait : la réservation devient une vente ====================
select pg_temp.as_user(:'B'); set local role authenticated;
select pg_temp.try('11a', format('select public.reservation_pickup(%L)', pg_temp.rid('1')));
reset role;
select pg_temp.expect('11a', '22023', pg_temp.msg('11a') like '%ouvrez votre caisse%' and pg_temp.status('1') = 'ready'
  and pg_temp.held(:'L1') = 3 and pg_temp.held(:'L2') = 1 and pg_temp.qty(:'L1') = 3,
  '; retrait sans caisse ouverte : refus, reservation et boites retenues intactes');
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('11b', format('select public.reservation_pickup(%L)', pg_temp.rid('1')));
select pg_temp.try('11c', format('select reservation_item_id from public.reservation_pickup_preview(%L) limit 1', pg_temp.rid('1')));
reset role;
select pg_temp.expect('11b', '42501', true, '; retrait par le patient : refuse');
select pg_temp.expect('11c', '42501', true, '; apercu du retrait par le patient : refuse');

-- Le prix a changé depuis la réservation : prix du jour au retrait.
update public.stock_items set unit_price = 1600 where pharmacy_id = :'KALOUM' and product_id = :'PARA';
select (select count(*) from public.pos_sales where pharmacy_id = :'KALOUM') as ventes0,
       (select count(*) from public.cash_movements where type = 'sale' and created_by = :'A') as caisse0 \gset
select pg_temp.as_user(:'A'); set local role authenticated;
select reserved_unit_price as prix_reserve, current_unit_price as prix_jour, unavailable_quantity as indispo
  from public.reservation_pickup_preview(pg_temp.rid('1')) \gset
select pg_temp.try('12', format('select public.reservation_pickup(%L)', pg_temp.rid('1')));
reset role;
select pg_temp.verdict('12-apercu', :prix_reserve = 1500 and :prix_jour = 1600 and :indispo = 0,
  'apercu du retrait : prix indicatif ' || :prix_reserve || ', prix du jour ' || :prix_jour || ', rien d''indisponible');
select pg_temp.expect('12', 'OK',
  pg_temp.status('1') = 'pickedUp'
  and pg_temp.qty(:'L1') = 0 and pg_temp.qty(:'L2') = 0 and pg_temp.held(:'L1') = 0 and pg_temp.held(:'L2') = 0
  and (select count(*) from public.pos_sales where pharmacy_id = :'KALOUM') = :ventes0 + 1
  and (select s.final_amount = 6400 and s.payment_method = 'cash' and s.patient_id = :'P1'::uuid and s.status = 'completed' and s.cashier_id = :'A'::uuid
         from public.pos_sales s where s.id = pg_temp.rid('12'))
  and (select pos_sale_id = pg_temp.rid('12') and total_price = 6400 and picked_up_at is not null from public.reservations where id = pg_temp.rid('1'))
  and (select count(*) = 2 and sum(quantity) = 4 from public.pos_sale_items where sale_id = pg_temp.rid('12'))
  and (select count(*) from public.pos_receipts where sale_id = pg_temp.rid('12')) = 1
  and (select count(*) from public.cash_movements where type = 'sale' and created_by = :'A') = :caisse0 + 1
  and (select amount from public.cash_movements where reference_id = pg_temp.rid('12')::text) = 6400
  and (select reserved_quantity from public.stock_items where pharmacy_id = :'KALOUM' and product_id = :'PARA') = 0
  and (select price_per_unit from public.reservation_items where reservation_id = pg_temp.rid('1')) = 1500,
  '; retrait : une vente en especes de 6 400 (prix du jour 1 600 x 4), un ticket, un encaissement en caisse ; stock sorti une seule fois (L1 0, L2 0), retenue a zero ; prix indicatif de la ligne conserve (1 500)');

select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('13', format('select public.reservation_pickup(%L)', pg_temp.rid('1')));
select pg_temp.try('13b', format('select public.reservation_cancel(%L, ''Test'')', pg_temp.rid('1')));
reset role;
select pg_temp.expect('13', '22023', true, '; second retrait de la meme reservation : refus');
select pg_temp.expect('13b', '22023', true, '; annulation d''une reservation retiree : refus');

-- ==================== 7. Annulation ====================
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('14a', format('select public.reservation_cancel(%L)', pg_temp.rid('4')));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('14b', format('select public.reservation_cancel(%L)', pg_temp.rid('4')));
reset role;
select pg_temp.as_user(:'D'); set local role authenticated;
select pg_temp.try('14c', format('select public.reservation_cancel(%L, ''Test'')', pg_temp.rid('4')));
reset role;
select pg_temp.expect('14a', '42501', true, '; annulation par un autre patient : refus');
select pg_temp.expect('14b', '22023', pg_temp.msg('14b') like '%motif%', '; annulation par l''officine sans motif : refus');
select pg_temp.expect('14c', '42501', pg_temp.held(:'I1') = 5, '; annulation par une autre officine : refus');

select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('15a', format('select public.reservation_cancel(%L)', pg_temp.rid('4')));
select pg_temp.try('15b', format('select public.reservation_cancel(%L)', pg_temp.rid('4')));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('15c', format('select public.reservation_cancel(%L, ''Produit abime'')', pg_temp.rid('6a')));
reset role;
select pg_temp.expect('15a', 'OK', pg_temp.status('4') = 'cancelled'
  and (select cancelled_by = :'P2'::uuid and cancelled_at is not null from public.reservations where id = pg_temp.rid('4'))
  and (select count(*) = 1 and sum(quantity) = 2 from public.stock_movements where reference_id = pg_temp.rid('4')::text and type = 'unreservation')
  and (select bool_and(h.released_at is not null) from public.reservation_item_batches h join public.reservation_items ri on ri.id = h.reservation_item_id where ri.reservation_id = pg_temp.rid('4')),
  '; annulation par le patient : ses 2 boites liberees (mouvement de liberation, retenue levee), auteur enregistre');
select pg_temp.expect('15b', '22023', true, '; seconde annulation : refus');
select pg_temp.expect('15c', 'OK', pg_temp.status('6a') = 'cancelled' and pg_temp.held(:'I1') = 2
  and (select cancelled_by = :'A'::uuid and cancel_reason = 'Produit abime' from public.reservations where id = pg_temp.rid('6a')),
  '; annulation par l''officine avec motif : boite liberee, auteur et motif enregistres ; retenue I1 passee de 5 a 2 apres les deux annulations');

-- ==================== 8. Expiration (24 h) ====================
-- 6b dépasse son échéance ; 6d reste dans les délais.
update public.reservations set pickup_deadline = now() - interval '1 minute' where id = pg_temp.rid('6b');
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('16a', format('select public.reservation_pickup(%L)', pg_temp.rid('6b')));
select pg_temp.try('16b', format('select public.reservation_mark_ready(%L)', pg_temp.rid('6b')));
select pg_temp.try('16c', 'select null::uuid from (select public.reservation_expire_overdue()) x');
reset role;
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('16d', format('select null::uuid from (select public.reservation_expire_for_pharmacy(%L)) x', :'KALOUM'));
reset role;
select pg_temp.expect('16a', '22023', pg_temp.msg('16a') like '%expiree%', '; retrait apres l''echeance : refus');
select pg_temp.expect('16b', '22023', true, '; « prete » apres l''echeance : refus');
select pg_temp.expect('16c', '42501', true, '; expiration interne non appelable par les clients');
select pg_temp.expect('16d', '42501', true, '; expiration a l''usage reservee au personnel de l''officine');

select pg_temp.as_user(:'A'); set local role authenticated;
select public.reservation_expire_for_pharmacy(:'KALOUM') as expirees \gset
reset role;
select pg_temp.verdict('17', :expirees = 1 and pg_temp.status('6b') = 'expired' and pg_temp.status('6d') = 'pending'
  and pg_temp.held(:'I1') = 1
  and (select expired_at is not null from public.reservations where id = pg_temp.rid('6b')),
  'expiration a l''usage par l''officine : ' || :expirees || ' reservation expiree, sa boite liberee (retenue I1 2 -> 1) ; la reservation dans les delais est intacte');

-- La tâche planifiée appelle la même fonction, sans utilisateur connecté.
update public.reservations set pickup_deadline = now() - interval '1 minute' where id = pg_temp.rid('6d');
select set_config('request.jwt.claims', '', true);
select public.reservation_expire_overdue() as expirees_cron \gset
select pg_temp.verdict('18', :expirees_cron = 1 and pg_temp.status('6d') = 'expired' and pg_temp.held(:'I1') = 0,
  'expiration par la tache planifiee (sans utilisateur) : ' || :expirees_cron || ' reservation expiree, retenue I1 a 0');

-- Contrôle à l'usage : une réservation dépassée libère ses boîtes quand un
-- autre patient réserve.
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('19a', pg_temp.reserve(:'DOLI', 4));
reset role;
update public.reservations set pickup_deadline = now() - interval '1 minute' where id = pg_temp.rid('19a');
select pg_temp.as_user(:'P2'); set local role authenticated;
select pg_temp.try('19b', pg_temp.reserve(:'DOLI', 4));
reset role;
select pg_temp.expect('19b', 'OK', pg_temp.status('19a') = 'expired' and pg_temp.held(:'D1') = 2 and pg_temp.held(:'D2') = 2,
  '; les 4 boites etaient retenues par une reservation depassee : elle expire a la nouvelle demande, qui est servie');

-- ==================== 9. Lot rappelé entre la réservation et le retrait ====================
-- 19b tient D1 (2) et D2 (2). D1 est rappelé ; aucun autre lot libre.
insert into public.recalls (id, reference_number, title, description, severity, status, issued_by)
  values ('c2430000-0000-0000-0000-0000000000c1', 'R-C243-001', 'Rappel de test C243', 'Lot C243-D1', 'classI', 'inProgress', 'Test C243');
insert into public.recall_affected_batches (recall_id, batch_number, product_id, product_name, status)
  values ('c2430000-0000-0000-0000-0000000000c1', 'C243-D1', :'DOLI', 'Doliprane', 'pending');

select pg_temp.as_user(:'P2'); set local role authenticated;
select count(*) as alertes_patient from public.reservation_unavailable_items() where reservation_id = pg_temp.rid('19b') \gset
select pg_temp.try('20x', format('select reservation_id from public.reservation_unavailable_items(%L) limit 1', :'KALOUM'));
reset role;
select pg_temp.as_user(:'A'); set local role authenticated;
select count(*) as alertes_officine from public.reservation_unavailable_items(:'KALOUM') where reservation_id = pg_temp.rid('19b') \gset
select unavailable_quantity as indispo2 from public.reservation_pickup_preview(pg_temp.rid('19b')) \gset
select pg_temp.try('20a', format('select public.reservation_pickup(%L)', pg_temp.rid('19b')));
select pg_temp.try('20b', format('select public.reservation_pickup(%L, false, true, null)', pg_temp.rid('19b')));
select pg_temp.try('20c', format('select public.reservation_pickup(%L, false, true, ''Lot rappele'')', pg_temp.rid('19b')));
reset role;
select pg_temp.verdict('20', :alertes_patient = 1 and :alertes_officine = 1 and :indispo2 = 2,
  'lot rappele apres la reservation : signale au patient (' || :alertes_patient || ' ligne) et a l''officine (' || :alertes_officine || ' ligne) ; apercu : ' || :indispo2 || ' boites sans remplacant');
select pg_temp.expect('20x', '42501', true, '; alertes d''une officine demandees par un patient : refus');
select pg_temp.expect('20a', 'P0001', pg_temp.msg('20a') like '%Doliprane ne peut plus etre remis%'
  and pg_temp.status('19b') = 'pending' and pg_temp.held(:'D1') = 2 and pg_temp.held(:'D2') = 2,
  '; retrait : aucun autre lot, refus ; reservation et retenues inchangees');
select pg_temp.expect('20b', '22023', pg_temp.msg('20b') like '%motif du retrait partiel%', '; retrait partiel sans motif : refus');
select pg_temp.expect('20c', '22023', pg_temp.msg('20c') like '%aucun produit ne peut etre remis%' and pg_temp.status('19b') = 'pending',
  '; retrait partiel alors que la seule ligne est indisponible : refus, a annuler');

-- Un autre lot devient disponible : le retrait se fait dessus.
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select 'c2430000-0000-0000-0000-0000000000f7', si.id, 'C243-D3', current_date - 10, current_date + 90, 5, 0, now()
  from public.stock_items si where si.pharmacy_id = :'KALOUM' and si.product_id = :'DOLI';
select pg_temp.as_user(:'A'); set local role authenticated;
select unavailable_quantity as indispo3 from public.reservation_pickup_preview(pg_temp.rid('19b')) \gset
select pg_temp.try('21', format('select public.reservation_pickup(%L)', pg_temp.rid('19b')));
reset role;
select pg_temp.expect('21', 'OK',
  :indispo3 = 0 and pg_temp.status('19b') = 'pickedUp'
  and pg_temp.qty(:'D1') = 2 and pg_temp.held(:'D1') = 0
  and pg_temp.qty(:'D2') = 0 and pg_temp.qty('c2430000-0000-0000-0000-0000000000f7') = 3
  and (select sum(quantity) = 4 and bool_and(batch_id <> :'D1'::uuid) from public.pos_sale_items where sale_id = pg_temp.rid('21'))
  and (select final_amount from public.pos_sales where id = pg_temp.rid('21')) = 4800,
  '; un autre lot existe : les 2 boites du lot rappele sont remplacees (D3), le lot rappele n''est pas vendu (D1 reste a 2, retenue 0)');

-- Retrait partiel : deux lignes, l'une sur un lot rappelé sans remplaçant.
update public.stock_batches set quantity = 0 where id = 'c2430000-0000-0000-0000-0000000000f7';
delete from public.recalls where id = 'c2430000-0000-0000-0000-0000000000c1';
select pg_temp.as_user(:'P1'); set local role authenticated;
select pg_temp.try('22', format('select public.reservation_create(%L, %L::jsonb)', :'KALOUM',
  jsonb_build_array(jsonb_build_object('product_id', :'DOLI', 'quantity', 2), jsonb_build_object('product_id', :'IBU', 'quantity', 1))::text));
reset role;
insert into public.recalls (id, reference_number, title, description, severity, status, issued_by)
  values ('c2430000-0000-0000-0000-0000000000c2', 'R-C243-002', 'Rappel de test C243', 'Lot C243-D1', 'classI', 'inProgress', 'Test C243');
insert into public.recall_affected_batches (recall_id, batch_number, product_id, product_name, status)
  values ('c2430000-0000-0000-0000-0000000000c2', 'C243-D1', :'DOLI', 'Doliprane', 'pending');
select pg_temp.as_user(:'A'); set local role authenticated;
select pg_temp.try('23', format('select public.reservation_pickup(%L, true, true, ''Lot rappele, patient informe'')', pg_temp.rid('22')));
reset role;
select pg_temp.expect('23', 'OK',
  pg_temp.status('22') = 'pickedUp' and pg_temp.held(:'D1') = 0 and pg_temp.qty(:'D1') = 2
  and (select removed_at is not null and removed_reason = 'Lot rappele, patient informe'
         from public.reservation_items where reservation_id = pg_temp.rid('22') and product_id = :'DOLI')
  and (select count(*) = 1 and bool_and(product_id = :'IBU'::uuid and prescription_required and prescription_checked)
         from public.pos_sale_items where sale_id = pg_temp.rid('23'))
  and (select final_amount from public.pos_sales where id = pg_temp.rid('23')) = 2000
  and (select total_price from public.reservations where id = pg_temp.rid('22')) = 2000,
  '; retrait partiel motive : la ligne du lot rappele est retiree (motif garde), l''autre est vendue (2 000), ordonnance verifiee tracee');

-- ==================== 10. Droits et réglages ====================
select pg_temp.verdict('24',
  not has_function_privilege('anon', 'public.reservation_create(uuid, jsonb, text)', 'execute')
  and has_function_privilege('authenticated', 'public.reservation_create(uuid, jsonb, text)', 'execute')
  and not has_function_privilege('anon', 'public.reservation_pickup(uuid, boolean, boolean, text)', 'execute')
  and not has_function_privilege('anon', 'public.reservation_cancel(uuid, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.reservation_hold_stock(uuid, uuid, uuid, integer)', 'execute')
  and not has_function_privilege('authenticated', 'public.reservation_release_holds(uuid, uuid, uuid, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.reservation_expire_overdue(uuid)', 'execute'),
  'fonctions de reservation fermees a anon ; retenue, liberation et expiration internes fermees aux clients');

select pg_temp.verdict('25',
  (select count(*) from pg_policies where schemaname = 'public' and tablename in ('reservations', 'reservation_items', 'reservation_item_batches') and cmd <> 'SELECT') = 0
  and (select count(*) from pg_policies where schemaname = 'public' and tablename in ('reservations', 'reservation_items') and cmd = 'SELECT') = 4
  and (select reservation_max_active_per_patient = 3 and reservation_max_quantity_per_line = 5 from public.pharmacies where id = :'KALOUM'),
  'aucune regle d''ecriture sur les reservations, leurs lignes et leurs lots ; les 4 regles de lecture sont conservees ; limites par defaut 3 et 5');

rollback;
