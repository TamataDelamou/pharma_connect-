-- C220 (décision D65) : données agrégées et règles d'accès ouvertes à tous.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c220_aggregates_and_open_policies.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c2200000-…-0000000000xx :
--   01 PAT1 (livraison en cours, chauffeur D1) ; 02 PAT2 (livraison prévue, D1) ;
--   03 ADM admin GSG ; 10 PH pharmacien de Kaloum ; 11 PHD pharmacien de Dixinn ;
--   20 DRV1 (livreur D1) ; 21 DRV2 (livreur D2) ;
--   30 PROV professionnel vérifié ; 31 PRONV non vérifié ;
--   40 FAM membre de la famille de PAT1 ; 41 FAM2 membre de la famille de PAT2.
insert into auth.users (id, email)
  select ('c2200000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c220-' || n || '@test.local'
  from unnest(array[1,2,3,10,11,20,21,30,31,40,41]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2200000-0000-0000-0000-000000000001', 'patient', null, 'PAT1'),
  ('c2200000-0000-0000-0000-000000000002', 'patient', null, 'PAT2'),
  ('c2200000-0000-0000-0000-000000000003', 'patient', null, 'ADM'),
  ('c2200000-0000-0000-0000-000000000010', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH Kaloum'),
  ('c2200000-0000-0000-0000-000000000011', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'PHD Dixinn'),
  ('c2200000-0000-0000-0000-000000000020', 'livreur', null, 'DRV1'),
  ('c2200000-0000-0000-0000-000000000021', 'livreur', null, 'DRV2'),
  ('c2200000-0000-0000-0000-000000000030', 'professionnel', null, 'PROV'),
  ('c2200000-0000-0000-0000-000000000031', 'professionnel', null, 'PRONV'),
  ('c2200000-0000-0000-0000-000000000040', 'patient', null, 'FAM'),
  ('c2200000-0000-0000-0000-000000000041', 'patient', null, 'FAM2');
update public.profiles set role_verified_at = now()
  where id in ('c2200000-0000-0000-0000-000000000020', 'c2200000-0000-0000-0000-000000000021');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2200000-0000-0000-0000-000000000003', 'c220-3@test.local', 'Admin C220', 'admin', true);
insert into public.professional_profiles (id, is_verified, verification_status) values
  ('c2200000-0000-0000-0000-000000000030', true, 'verified'),
  ('c2200000-0000-0000-0000-000000000031', false, 'pending');
insert into public.system_configs (key, value, category, updated_by) values ('c220.secret', 'x', 'test', 'c220');

-- Livreurs, réservations, livraisons, tournée.
insert into public.delivery_drivers (id, user_id, name, phone, current_latitude, current_longitude) values
  ('c2200000-0000-0000-0000-0000000000d1', 'c2200000-0000-0000-0000-000000000020', 'DRV1', '+224600000020', 9.51, -13.71),
  ('c2200000-0000-0000-0000-0000000000d2', 'c2200000-0000-0000-0000-000000000021', 'DRV2', '+224600000021', 9.52, -13.72);
insert into public.reservations (id, patient_id, patient_name, patient_phone, pharmacy_id, pharmacy_name, pharmacy_address, status) values
  ('c2200000-0000-0000-0000-0000000000b1', 'c2200000-0000-0000-0000-000000000001', 'PAT1', '+224600000001',
   '55555555-5555-5555-5555-555555550001', 'Kaloum', 'Kaloum', 'ready'),
  ('c2200000-0000-0000-0000-0000000000b2', 'c2200000-0000-0000-0000-000000000002', 'PAT2', '+224600000002',
   '55555555-5555-5555-5555-555555550002', 'Dixinn', 'Dixinn', 'ready');
insert into public.deliveries (id, reservation_id, patient_id, patient_name, patient_phone, delivery_address, driver_id, scheduled_at, status) values
  ('c2200000-0000-0000-0000-0000000000e1', 'c2200000-0000-0000-0000-0000000000b1', 'c2200000-0000-0000-0000-000000000001',
   'PAT1', '+224600000001', 'Domicile PAT1, Ratoma', 'c2200000-0000-0000-0000-0000000000d1', now(), 'inProgress'),
  ('c2200000-0000-0000-0000-0000000000e2', 'c2200000-0000-0000-0000-0000000000b2', 'c2200000-0000-0000-0000-000000000002',
   'PAT2', '+224600000002', 'Domicile PAT2, Matoto', 'c2200000-0000-0000-0000-0000000000d1', now() + interval '2 hours', 'scheduled');
insert into public.delivery_routes (id, driver_id, date) values
  ('c2200000-0000-0000-0000-0000000000f1', 'c2200000-0000-0000-0000-0000000000d1', current_date);
insert into public.route_stops (route_id, delivery_id, latitude, longitude, address, stop_order) values
  ('c2200000-0000-0000-0000-0000000000f1', 'c2200000-0000-0000-0000-0000000000e1', 9.60, -13.60, 'Domicile PAT1, Ratoma', 1),
  ('c2200000-0000-0000-0000-0000000000f1', 'c2200000-0000-0000-0000-0000000000e2', 9.55, -13.65, 'Domicile PAT2, Matoto', 2);

-- Liens familiaux et alertes.
insert into public.family_links (id, patient_id, family_member_id, relationship, status) values
  ('c2200000-0000-0000-0000-0000000000a1', 'c2200000-0000-0000-0000-000000000001', 'c2200000-0000-0000-0000-000000000040', 'enfant', 'active'),
  ('c2200000-0000-0000-0000-0000000000a2', 'c2200000-0000-0000-0000-000000000002', 'c2200000-0000-0000-0000-000000000041', 'enfant', 'active');
insert into public.family_alerts (id, family_link_id, type, title, message) values
  ('c2200000-0000-0000-0000-0000000000c1', 'c2200000-0000-0000-0000-0000000000a1', 'general', 'Alerte PAT1', 'Message');

-- Avis et consultations (statistiques des professionnels).
insert into public.professional_reviews (professional_id, patient_id, rating, status) values
  ('c2200000-0000-0000-0000-000000000030', 'c2200000-0000-0000-0000-000000000001', 4, 'approved'),
  ('c2200000-0000-0000-0000-000000000031', 'c2200000-0000-0000-0000-000000000002', 5, 'approved');
insert into public.consultations (patient_id, professional_id, scheduled_at, status) values
  ('c2200000-0000-0000-0000-000000000001', 'c2200000-0000-0000-0000-000000000030', now() - interval '3 days', 'completed'),
  ('c2200000-0000-0000-0000-000000000002', 'c2200000-0000-0000-0000-000000000030', now() - interval '2 days', 'completed');
refresh materialized view public.professional_stats;

insert into public.loyalty_leaderboard (patient_id, period, points) values
  ('c2200000-0000-0000-0000-000000000001', 'monthly', 120);

\set PAT1 'c2200000-0000-0000-0000-000000000001'
\set PAT2 'c2200000-0000-0000-0000-000000000002'
\set ADM 'c2200000-0000-0000-0000-000000000003'
\set PH 'c2200000-0000-0000-0000-000000000010'
\set PHD 'c2200000-0000-0000-0000-000000000011'
\set DRV1 'c2200000-0000-0000-0000-000000000020'
\set DRV2 'c2200000-0000-0000-0000-000000000021'
\set PROV 'c2200000-0000-0000-0000-000000000030'
\set PRONV 'c2200000-0000-0000-0000-000000000031'
\set FAM 'c2200000-0000-0000-0000-000000000040'

create temp table t_out (c text primary key, state text, msg text);
create temp table t_seen (who text, what text, n bigint, primary key (who, what));
grant all on t_out, t_seen to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then raise notice 'CAS % OK : %', p_case, p_detail;
  else raise notice 'CAS % ECHEC : %', p_case, p_detail; end if;
end;
$$;

-- Lecture d'une relation par l'identité courante : nombre de lignes, ou
-- -1 si la lecture est refusée (42501).
create function pg_temp.try_count(p_who text, p_rel text, p_where text default 'true') returns void language plpgsql as $$
declare n bigint;
begin
  execute format('select count(*) from %s where %s', p_rel, p_where) into n;
  insert into t_seen values (p_who, p_rel || '|' || p_where, n);
exception when insufficient_privilege then
  insert into t_seen values (p_who, p_rel || '|' || p_where, -1);
end;
$$;

create function pg_temp.n(p_who text, p_rel text, p_where text default 'true') returns bigint language sql as $$
  select n from t_seen where who = p_who and what = p_rel || '|' || p_where
$$;

-- ==================== 1. Analyse : anon ====================
select set_config('request.jwt.claims', '', true);
set local role anon;
select pg_temp.try_count('anon', r)
  from unnest(array['public.daily_stats', 'public.pharmacies_performance', 'public.products_performance',
                    'public.top_products', 'public.network_dashboard', 'public.daily_stats_scoped',
                    'public.pharmacies_performance_scoped', 'public.products_performance_scoped',
                    'public.top_products_scoped', 'public.network_dashboard_scoped',
                    'public.adverse_reactions_anonymized', 'public.professional_stats',
                    'public.solidarity_impact', 'public.loyalty_leaderboard', 'public.professional_stats_public']) r;
reset role;

select pg_temp.verdict('1',
  (select bool_and(n = -1) from t_seen where who = 'anon'
     and what similar to 'public.(daily_stats|pharmacies_performance|products_performance|top_products|network_dashboard)\|true'),
  'anon : vues precalculees d''analyse (chiffre d''affaires, prix, stocks) refusees');
select pg_temp.verdict('1-scoped',
  (select bool_and(n = -1) from t_seen where who = 'anon' and (what like '%_scoped|%' or what like '%anonymized|%')),
  'anon : vues filtrees d''analyse et effets indesirables anonymises refusees');
select pg_temp.verdict('1-autres',
  pg_temp.n('anon', 'public.professional_stats') = -1
  and pg_temp.n('anon', 'public.solidarity_impact') = -1
  and pg_temp.n('anon', 'public.loyalty_leaderboard') = 0,
  'anon : statistiques brutes des professionnels et bilan de solidarite refuses ; classement de fidelite vide');

-- ==================== 2. Analyse : utilisateurs connectés ====================
select pg_temp.as_user(:'PAT2'); set local role authenticated;
select pg_temp.try_count('PAT2', r)
  from unnest(array['public.daily_stats', 'public.pharmacies_performance', 'public.professional_stats',
                    'public.daily_stats_scoped', 'public.solidarity_impact', 'public.loyalty_leaderboard']) r;
reset role;
select pg_temp.verdict('2',
  pg_temp.n('PAT2', 'public.daily_stats') = -1 and pg_temp.n('PAT2', 'public.pharmacies_performance') = -1
  and pg_temp.n('PAT2', 'public.professional_stats') = -1 and pg_temp.n('PAT2', 'public.daily_stats_scoped') = 0,
  'patient connecte : vues brutes refusees, vue filtree vide (reservee a GSG)');
select pg_temp.verdict('2-bilans',
  pg_temp.n('PAT2', 'public.solidarity_impact') >= 0 and pg_temp.n('PAT2', 'public.loyalty_leaderboard') = 1,
  'patient connecte : bilan de solidarite et classement de fidelite lisibles');

-- ==================== 3. Statistiques des professionnels ====================
create temp table t_stats (who text, professional_id uuid, total_reviews bigint, avg_rating numeric,
                           total_consultations bigint, total_patients bigint);
grant all on t_stats to authenticated, anon;
set local role anon;
insert into t_stats select 'anon', professional_id, total_reviews, avg_rating, total_consultations, total_patients
  from public.professional_stats_public
 where professional_id in ('c2200000-0000-0000-0000-000000000030', 'c2200000-0000-0000-0000-000000000031');
reset role;
select pg_temp.as_user(:'PROV'); set local role authenticated;
insert into t_stats select 'PROV', professional_id, total_reviews, avg_rating, total_consultations, total_patients
  from public.professional_stats_public
 where professional_id in ('c2200000-0000-0000-0000-000000000030', 'c2200000-0000-0000-0000-000000000031');
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated;
insert into t_stats select 'ADM', professional_id, total_reviews, avg_rating, total_consultations, total_patients
  from public.professional_stats_public
 where professional_id in ('c2200000-0000-0000-0000-000000000030', 'c2200000-0000-0000-0000-000000000031');
reset role;

select pg_temp.verdict('3',
  (select count(*) = 1 from t_stats where who = 'anon')
  and (select total_reviews = 1 and avg_rating = 4 and total_consultations is null and total_patients is null
         from t_stats where who = 'anon' and professional_id = :'PROV'),
  'public : note et nombre d''avis du professionnel verifie ; patients et consultations masques ; non verifie absent');
select pg_temp.verdict('3-soi',
  (select total_consultations = 2 and total_patients = 2 from t_stats where who = 'PROV' and professional_id = :'PROV')
  and (select count(*) = 1 from t_stats where who = 'PROV'),
  'le professionnel voit ses propres nombres de patients et de consultations');
select pg_temp.verdict('3-gsg',
  (select count(*) = 2 from t_stats where who = 'ADM')
  and (select total_patients = 2 from t_stats where who = 'ADM' and professional_id = :'PROV'),
  'GSG voit tout, y compris le professionnel non verifie');

-- ==================== 4. Livraisons ====================
create function pg_temp.delivery_view(p_who text) returns void language plpgsql as $$
begin
  perform pg_temp.try_count(p_who, 'public.route_stops');
  perform pg_temp.try_count(p_who, 'public.route_stops', 'delivery_id = ''c2200000-0000-0000-0000-0000000000e1''');
  perform pg_temp.try_count(p_who, 'public.delivery_routes');
  perform pg_temp.try_count(p_who, 'public.delivery_drivers');
  perform pg_temp.try_count(p_who, 'public.delivery_drivers', 'id = ''c2200000-0000-0000-0000-0000000000d1''');
end;
$$;
select pg_temp.as_user(:'PAT1'); set local role authenticated; select pg_temp.delivery_view('PAT1'); reset role;
select pg_temp.as_user(:'PAT2'); set local role authenticated; select pg_temp.delivery_view('PAT2'); reset role;
select pg_temp.as_user(:'DRV1'); set local role authenticated; select pg_temp.delivery_view('DRV1'); reset role;
select pg_temp.as_user(:'DRV2'); set local role authenticated; select pg_temp.delivery_view('DRV2'); reset role;
select pg_temp.as_user(:'PH'); set local role authenticated; select pg_temp.delivery_view('PH'); reset role;
select pg_temp.as_user(:'PHD'); set local role authenticated; select pg_temp.delivery_view('PHD'); reset role;
select pg_temp.as_user(:'PROV'); set local role authenticated; select pg_temp.delivery_view('PROV'); reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated; select pg_temp.delivery_view('ADM'); reset role;

select pg_temp.verdict('4',
  pg_temp.n('PAT1', 'public.route_stops') = 1
  and pg_temp.n('PAT1', 'public.route_stops', 'delivery_id = ''c2200000-0000-0000-0000-0000000000e1''') = 1
  and pg_temp.n('PAT2', 'public.route_stops') = 1
  and pg_temp.n('PAT2', 'public.route_stops', 'delivery_id = ''c2200000-0000-0000-0000-0000000000e1''') = 0,
  'arrets : chaque patient ne voit que l''adresse de sa propre livraison');
select pg_temp.verdict('4-officines',
  pg_temp.n('PH', 'public.route_stops') = 1 and pg_temp.n('PHD', 'public.route_stops') = 1
  and pg_temp.n('PHD', 'public.route_stops', 'delivery_id = ''c2200000-0000-0000-0000-0000000000e1''') = 0,
  'arrets : chaque officine ne voit que les livraisons de ses reservations');
select pg_temp.verdict('4-livreurs',
  pg_temp.n('DRV1', 'public.route_stops') = 2 and pg_temp.n('DRV1', 'public.delivery_routes') = 1
  and pg_temp.n('DRV2', 'public.route_stops') = 0 and pg_temp.n('DRV2', 'public.delivery_routes') = 0
  and pg_temp.n('PROV', 'public.route_stops') = 0 and pg_temp.n('ADM', 'public.route_stops') = 2,
  'arrets et tournees : le livreur de la tournee voit tout, un autre livreur et un professionnel rien, GSG tout');
select pg_temp.verdict('5',
  pg_temp.n('PAT1', 'public.delivery_drivers') = 1
  and pg_temp.n('PAT1', 'public.delivery_drivers', 'id = ''c2200000-0000-0000-0000-0000000000d1''') = 1
  and pg_temp.n('PAT2', 'public.delivery_drivers') = 1
  and pg_temp.n('PROV', 'public.delivery_drivers') = 0
  and pg_temp.n('DRV2', 'public.delivery_drivers') = 1
  and pg_temp.n('DRV2', 'public.delivery_drivers', 'id = ''c2200000-0000-0000-0000-0000000000d1''') = 0,
  'livreurs : le patient voit le livreur de sa livraison en cours, pas les autres ; un livreur ne voit que lui-meme');
select pg_temp.verdict('5-officines',
  pg_temp.n('PH', 'public.delivery_drivers') = 2 and pg_temp.n('PHD', 'public.delivery_drivers') = 2
  and pg_temp.n('ADM', 'public.delivery_drivers') = 2,
  'livreurs : le personnel des officines actives et GSG voient tous les livreurs (choix du livreur)');

-- Livraison terminée : le patient ne voit plus le livreur.
update public.deliveries set status = 'delivered', delivered_at = now() where id = 'c2200000-0000-0000-0000-0000000000e1';
select pg_temp.as_user(:'PAT1'); set local role authenticated;
select count(*) as pat1_drivers_after from public.delivery_drivers \gset
reset role;
select pg_temp.verdict('5-fin', :'pat1_drivers_after' = '0', 'livraison terminee : le patient ne voit plus le livreur');

-- Pas de boucle entre les règles : le livreur met à jour sa livraison.
select pg_temp.as_user(:'DRV1'); set local role authenticated;
do $$ begin
  update public.deliveries set status = 'arrived', arrived_at = now() where id = 'c2200000-0000-0000-0000-0000000000e2';
  insert into t_out values ('6', 'OK', null);
exception when others then insert into t_out values ('6', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.verdict('6',
  (select state = 'OK' from t_out where c = '6')
  and (select status = 'arrived' from public.deliveries where id = 'c2200000-0000-0000-0000-0000000000e2'),
  'le livreur met a jour sa livraison (pas de recursion entre les regles)' || coalesce(' ; ' || (select msg from t_out where c = '6'), ''));

-- ==================== 7. Administration GSG ====================
select pg_temp.as_user(:'PAT2'); set local role authenticated;
select pg_temp.try_count('PAT2', 'public.admin_users');
select pg_temp.try_count('PAT2', 'public.system_configs');
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated;
select pg_temp.try_count('ADM', 'public.admin_users', 'user_id = ''c2200000-0000-0000-0000-000000000003''');
select pg_temp.try_count('ADM', 'public.system_configs', 'key = ''c220.secret''');
reset role;
select pg_temp.verdict('7',
  pg_temp.n('PAT2', 'public.admin_users') = 0 and pg_temp.n('PAT2', 'public.system_configs') = 0
  and pg_temp.n('ADM', 'public.admin_users', 'user_id = ''c2200000-0000-0000-0000-000000000003''') = 1
  and pg_temp.n('ADM', 'public.system_configs', 'key = ''c220.secret''') = 1,
  'administrateurs GSG et parametres systeme : invisibles pour un utilisateur, visibles pour GSG');

-- ==================== 8. Alertes familiales ====================
select pg_temp.as_user(:'FAM'); set local role authenticated;
do $$ begin
  update public.family_alerts set is_read = true, read_at = now() where id = 'c2200000-0000-0000-0000-0000000000c1';
  insert into t_out values ('8a', 'OK', null);
exception when others then insert into t_out values ('8a', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.family_alerts set family_link_id = 'c2200000-0000-0000-0000-0000000000a2', title = 'Fausse alerte'
   where id = 'c2200000-0000-0000-0000-0000000000c1';
  insert into t_out values ('8b', 'OK', null);
exception when others then insert into t_out values ('8b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.verdict('8',
  (select state = 'OK' from t_out where c = '8a')
  and (select state = '42501' from t_out where c = '8b')
  and (select is_read and family_link_id = 'c2200000-0000-0000-0000-0000000000a1' and title = 'Alerte PAT1'
         from public.family_alerts where id = 'c2200000-0000-0000-0000-0000000000c1'),
  'membre de la famille : marque l''alerte comme lue ; ne peut pas la deplacer vers une autre famille (42501)');

-- ==================== 9. Droits ====================
select pg_temp.verdict('9',
  not has_function_privilege('anon', 'public.refresh_analytics_views()', 'execute')
  and not has_function_privilege('authenticated', 'public.refresh_professional_stats()', 'execute')
  and not has_function_privilege('anon', 'public.can_view_delivery(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.can_view_delivery_driver(uuid)', 'execute')
  and not has_table_privilege('authenticated', 'public.daily_stats_scoped', 'insert'),
  'rafraichissement des vues reserve au serveur ; fonctions de visibilite fermees a anon');

rollback;
