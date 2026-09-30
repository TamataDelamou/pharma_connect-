-- C211 / C212 : rôle déclaré ≠ rôle vérifié (décision D58). Verrouillage des
-- colonnes sensibles de profiles et professional_profiles, has_verified_role,
-- admin_set_user_role, policies fondées sur un rôle vérifié.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Les comptes sont créés en tant que postgres (comme le back-office) ; les
-- écritures testées sont faites sous le rôle authenticated (claims JWT).
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c211_verified_roles.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- ==================== Comptes ====================
-- c211-000000000xx : 01 PAT patient ; 02 ADM admin GSG ; 03 M titulaire (C208) ;
-- 04 PRO professionnel non vérifié ; 05 PROV professionnel vérifié (cas 10) ;
-- 06 PROV2 professionnel vérifié (matrice) ; 07 GRO grossiste (validé au cas 11) ;
-- 08 GRO2 grossiste non validé ; 09 PH pharmacien sans officine ;
-- 10 REG régulateur (validé au cas 13) ; 11 REG2 régulateur non validé ;
-- 12 LIV livreur validé ; 13 LIV2 livreur non validé ; 14 A pharmacien de Kaloum ;
-- 21-24 N1-N4 : utilisateurs sans profil (inscription).
insert into auth.users (id, email)
  select ('c2110000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c211-' || n || '@test.local'
  from (select generate_series(1, 14) n union all select generate_series(21, 24)) s;

insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2110000-0000-0000-0000-000000000001', 'patient', null, 'Patient PAT'),
  ('c2110000-0000-0000-0000-000000000002', 'patient', null, 'Admin GSG'),
  ('c2110000-0000-0000-0000-000000000003', 'pharmacien', null, 'Titulaire M'),
  ('c2110000-0000-0000-0000-000000000004', 'professionnel', null, 'Pro non verifie'),
  ('c2110000-0000-0000-0000-000000000005', 'professionnel', null, 'Pro verifie (licence)'),
  ('c2110000-0000-0000-0000-000000000006', 'professionnel', null, 'Pro verifie'),
  ('c2110000-0000-0000-0000-000000000007', 'grossiste', null, 'Grossiste GRO'),
  ('c2110000-0000-0000-0000-000000000008', 'grossiste', null, 'Grossiste GRO2'),
  ('c2110000-0000-0000-0000-000000000009', 'pharmacien', null, 'Pharmacien sans officine'),
  ('c2110000-0000-0000-0000-000000000010', 'regulateur', null, 'Regulateur REG'),
  ('c2110000-0000-0000-0000-000000000011', 'regulateur', null, 'Regulateur REG2'),
  ('c2110000-0000-0000-0000-000000000012', 'livreur', null, 'Livreur valide'),
  ('c2110000-0000-0000-0000-000000000013', 'livreur', null, 'Livreur non valide'),
  ('c2110000-0000-0000-0000-000000000014', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum');
update public.profiles set role_verified_at = now() where id = 'c2110000-0000-0000-0000-000000000012';
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2110000-0000-0000-0000-000000000002', 'c211-2@test.local', 'Admin GSG', 'admin', true);
insert into public.professional_profiles (id, is_verified, verification_status, license_number) values
  ('c2110000-0000-0000-0000-000000000004', false, 'pending', 'LIC-PRO'),
  ('c2110000-0000-0000-0000-000000000005', true, 'verified', 'LIC-PROV-1'),
  ('c2110000-0000-0000-0000-000000000006', true, 'verified', 'LIC-PROV2');
insert into public.pharmacies (id, name, address, phone, status, manager_id) values
  ('c2110000-0000-0000-0000-0000000000f1', 'Officine C211', 'Conakry', '+224620000211', 'pending',
   'c2110000-0000-0000-0000-000000000003');

\set PAT 'c2110000-0000-0000-0000-000000000001'
\set ADM 'c2110000-0000-0000-0000-000000000002'
\set M 'c2110000-0000-0000-0000-000000000003'
\set PRO 'c2110000-0000-0000-0000-000000000004'
\set PROV 'c2110000-0000-0000-0000-000000000005'
\set GRO 'c2110000-0000-0000-0000-000000000007'
\set PH 'c2110000-0000-0000-0000-000000000009'
\set REG 'c2110000-0000-0000-0000-000000000010'
\set N1 'c2110000-0000-0000-0000-000000000021'
\set N2 'c2110000-0000-0000-0000-000000000022'
\set N3 'c2110000-0000-0000-0000-000000000023'
\set N4 'c2110000-0000-0000-0000-000000000024'
\set KALOUM '55555555-5555-5555-5555-555555550001'
\set OFF 'c2110000-0000-0000-0000-0000000000f1'

create temp table t_out (c text primary key, state text, msg text);
grant all on t_out to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- Résultat d'un bloc : 'OK' si aucune exception, sinon le SQLSTATE.
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

-- ==================== Cas 1 : patient se donne le rôle pharmacien ====================
select pg_temp.as_user(:'PAT');
set local role authenticated;
do $$ begin
  update public.profiles set role = 'pharmacien' where id = auth.uid();
  insert into t_out values ('1', 'OK', null);
exception when others then insert into t_out values ('1', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('1', '42501', (select role = 'patient' from public.profiles where id = :'PAT'), '; role en base : patient');

-- ==================== Cas 2 : patient se rattache à Kaloum (preuve C211) ====================
select pg_temp.as_user(:'PAT');
set local role authenticated;
do $$ begin
  update public.profiles set role = 'pharmacien', pharmacy_id = '55555555-5555-5555-5555-555555550001' where id = auth.uid();
  insert into t_out values ('2', 'OK', null);
exception when others then insert into t_out values ('2', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.pos_create_sale('55555555-5555-5555-5555-555555550001', 'cash', 1000, 0, 0, 1000,
    '[{"product_name":"X","quantity":1,"unit_price":1000,"total_price":1000}]'::jsonb);
  insert into t_out values ('2-vente', 'OK', null);
exception when others then insert into t_out values ('2-vente', sqlstate, sqlerrm);
end $$;
select public.is_pharmacy_staff(:'KALOUM') as pat_staff \gset
reset role;
select pg_temp.expect('2', '42501', not :'pat_staff'::boolean, format('; is_pharmacy_staff(Kaloum) = %s', :'pat_staff'));
select pg_temp.expect('2-vente', '42501', true, '; pos_create_sale sur Kaloum refusee');

-- ==================== Cas 3 : inscription comme régulateur ====================
select pg_temp.as_user(:'N1');
set local role authenticated;
do $$ begin
  insert into public.profiles (id, role, full_name) values (auth.uid(), 'regulateur', 'N1');
  insert into t_out values ('3', 'OK', null);
exception when others then insert into t_out values ('3', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('3', '42501', (select count(*) = 0 from public.profiles where id = :'N1'), '; aucun profil cree');

-- ==================== Cas 4 : inscription avec pharmacy_id ou role_verified_at ====================
select pg_temp.as_user(:'N2');
set local role authenticated;
do $$ begin
  insert into public.profiles (id, role, full_name, pharmacy_id) values (auth.uid(), 'pharmacien', 'N2', '55555555-5555-5555-5555-555555550001');
  insert into t_out values ('4a', 'OK', null);
exception when others then insert into t_out values ('4a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'N3');
set local role authenticated;
do $$ begin
  insert into public.profiles (id, role, full_name, role_verified_at) values (auth.uid(), 'grossiste', 'N3', now());
  insert into t_out values ('4b', 'OK', null);
exception when others then insert into t_out values ('4b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('4a', '42501', true, '; insert avec pharmacy_id');
select pg_temp.expect('4b', '42501', true, '; insert avec role_verified_at');

-- ==================== Cas 5 : inscription comme pharmacien ====================
select pg_temp.as_user(:'N4');
set local role authenticated;
do $$ begin
  insert into public.profiles (id, role, full_name) values (auth.uid(), 'pharmacien', 'N4');
  insert into t_out values ('5', 'OK', null);
exception when others then insert into t_out values ('5', sqlstate, sqlerrm);
end $$;
select public.is_any_pharmacy_staff() as n4_any, public.is_pharmacy_staff(:'KALOUM') as n4_kaloum \gset
reset role;
select pg_temp.expect('5', 'OK',
  (select role = 'pharmacien' and pharmacy_id is null from public.profiles where id = :'N4')
  and not :'n4_any'::boolean and not :'n4_kaloum'::boolean,
  format('; pharmacy_id nul, is_any_pharmacy_staff = %s, is_pharmacy_staff(Kaloum) = %s', :'n4_any', :'n4_kaloum'));

-- ==================== Cas 6 : upsert, même rôle, nouveau nom ====================
select pg_temp.as_user(:'N4');
set local role authenticated;
do $$ begin
  insert into public.profiles (id, role, full_name) values (auth.uid(), 'pharmacien', 'N4 renomme')
    on conflict (id) do update set role = excluded.role, full_name = excluded.full_name;
  insert into t_out values ('6', 'OK', null);
exception when others then insert into t_out values ('6', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('6', 'OK', (select full_name = 'N4 renomme' from public.profiles where id = :'N4'), '; full_name mis a jour');

-- ==================== Cas 7 : modification du téléphone et du nom ====================
select pg_temp.as_user(:'PAT');
set local role authenticated;
do $$ begin
  update public.profiles set phone = '+224620777777', full_name = 'Patient renomme' where id = auth.uid();
  insert into t_out values ('7', 'OK', null);
exception when others then insert into t_out values ('7', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('7', 'OK', (select phone = '+224620777777' and full_name = 'Patient renomme' from public.profiles where id = :'PAT'), '; phone et full_name mis a jour');

-- ==================== Cas 8 : admin active une officine (C208 malgré le verrou) ====================
select pg_temp.as_user(:'ADM');
set local role authenticated;
do $$ begin
  update public.pharmacies set status = 'active' where id = 'c2110000-0000-0000-0000-0000000000f1';
  insert into t_out values ('8', 'OK', null);
exception when others then insert into t_out values ('8', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('8', 'OK', (select pharmacy_id = :'OFF' from public.profiles where id = :'M'),
  format('; pharmacy_id du titulaire = %s', (select coalesce(pharmacy_id::text, 'null') from public.profiles where id = :'M')));

-- ==================== Cas 9 : professionnel s'auto-vérifie (C212) ====================
select pg_temp.as_user(:'PRO');
set local role authenticated;
do $$ begin
  update public.professional_profiles set is_verified = true where id = auth.uid();
  insert into t_out values ('9a', 'OK', null);
exception when others then insert into t_out values ('9a', sqlstate, sqlerrm);
end $$;
do $$ begin
  update public.professional_profiles set verification_status = 'verified' where id = auth.uid();
  insert into t_out values ('9b', 'OK', null);
exception when others then insert into t_out values ('9b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('9a', '42501', (select not is_verified from public.professional_profiles where id = :'PRO'), '; is_verified = true refuse');
select pg_temp.expect('9b', '42501', (select verification_status = 'pending' from public.professional_profiles where id = :'PRO'), '; verification_status = verified refuse');

-- ==================== Cas 10 : professionnel vérifié modifie sa licence ====================
select pg_temp.as_user(:'PROV');
set local role authenticated;
do $$ begin
  update public.professional_profiles set license_number = 'LIC-PROV-2' where id = auth.uid();
  insert into t_out values ('10', 'OK', null);
exception when others then insert into t_out values ('10', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('10', 'OK',
  (select license_number = 'LIC-PROV-2' and not is_verified and verification_status = 'pending' from public.professional_profiles where id = :'PROV'),
  (select format('; licence %s, is_verified = %s, verification_status = %s', license_number, is_verified, verification_status)
     from public.professional_profiles where id = :'PROV'));

-- ==================== Cas 11 : grossiste non vérifié, puis validé ====================
select pg_temp.as_user(:'GRO');
set local role authenticated;
do $$ begin
  insert into public.traceable_batches (gtin, serial_number, batch_number, product_name, manufacturer, manufacturing_date, expiry_date)
    values ('03400000000011', 'C211-SN-11A', 'C211-11', 'Produit C211', 'Labo C211', current_date - 30, current_date + 365);
  insert into t_out values ('11a', 'OK', null);
exception when others then insert into t_out values ('11a', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'ADM');
set local role authenticated;
select public.admin_set_user_role(:'GRO', 'grossiste', true);
reset role;
select pg_temp.as_user(:'GRO');
set local role authenticated;
do $$ begin
  insert into public.traceable_batches (gtin, serial_number, batch_number, product_name, manufacturer, manufacturing_date, expiry_date)
    values ('03400000000011', 'C211-SN-11B', 'C211-11', 'Produit C211', 'Labo C211', current_date - 30, current_date + 365);
  insert into t_out values ('11b', 'OK', null);
exception when others then insert into t_out values ('11b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('11a', '42501', true, '; grossiste declare, non valide : ecriture refusee');
select pg_temp.expect('11b', 'OK',
  (select role_verified_at is not null and role_verified_by = :'ADM' from public.profiles where id = :'GRO'),
  '; apres admin_set_user_role(GRO, grossiste, true) : ecriture acceptee, role_verified_by = ADM');

-- ==================== Cas 12 : pharmacien sans officine ====================
select pg_temp.as_user(:'PH');
set local role authenticated;
do $$ begin
  insert into public.traceable_batches (gtin, serial_number, batch_number, product_name, manufacturer, manufacturing_date, expiry_date)
    values ('03400000000012', 'C211-SN-12', 'C211-12', 'Produit C211', 'Labo C211', current_date - 30, current_date + 365);
  insert into t_out values ('12a', 'OK', null);
exception when others then insert into t_out values ('12a', sqlstate, sqlerrm);
end $$;
do $$ begin
  insert into public.recalls (reference_number, title, description, severity, issued_by)
    values ('C211-RC-12', 'Rappel C211', 'Test', 'classII', 'Pharmacien sans officine');
  insert into t_out values ('12b', 'OK', null);
exception when others then insert into t_out values ('12b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('12a', '42501', true, '; traceable_batches refuse');
select pg_temp.expect('12b', '42501', true, '; recalls refuse');

-- ==================== Cas 13 : admin valide un régulateur ====================
select pg_temp.as_user(:'PAT');
set local role authenticated;
do $$ begin
  perform public.admin_set_user_role('c2110000-0000-0000-0000-000000000010', 'regulateur', true);
  insert into t_out values ('13-nonadmin', 'OK', null);
exception when others then insert into t_out values ('13-nonadmin', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'REG');
set local role authenticated;
do $$ begin
  insert into public.product_recalls (product_name, batch_number, manufacturer, reason, recall_type, severity, status)
    values ('Produit C211', 'C211-13', 'Labo C211', 'Test', 'mandatory', 'class_ii', 'draft');
  insert into t_out values ('13-avant', 'OK', null);
exception when others then insert into t_out values ('13-avant', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.as_user(:'ADM');
set local role authenticated;
select public.admin_set_user_role(:'REG', 'regulateur', true);
reset role;
select pg_temp.as_user(:'REG');
set local role authenticated;
do $$ begin
  insert into public.product_recalls (product_name, batch_number, manufacturer, reason, recall_type, severity, status)
    values ('Produit C211', 'C211-13', 'Labo C211', 'Test', 'mandatory', 'class_ii', 'draft');
  update public.product_recalls set status = 'published' where batch_number = 'C211-13';
  insert into t_out values ('13', 'OK', null);
exception when others then insert into t_out values ('13', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('13-nonadmin', '42501', true, '; admin_set_user_role par un non-admin');
select pg_temp.expect('13-avant', '42501', true, '; regulateur declare, non valide : product_recalls refuse');
select pg_temp.expect('13', 'OK', (select count(*) = 1 from public.product_recalls where batch_number = 'C211-13' and status = 'published'),
  '; regulateur valide par ADM : product_recalls cree et publie');

-- ==================== Cas 14 : anon ====================
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  perform public.admin_set_user_role('c2110000-0000-0000-0000-000000000001', 'regulateur', true);
  insert into t_out values ('14a', 'OK', null);
exception when others then insert into t_out values ('14a', sqlstate, sqlerrm);
end $$;
do $$ begin
  perform public.has_verified_role(array['pharmacien']);
  insert into t_out values ('14b', 'OK', null);
exception when others then insert into t_out values ('14b', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('14a', '42501', true, '; anon : admin_set_user_role');
select pg_temp.expect('14b', '42501', true, '; anon : has_verified_role');

-- ==================== Cas 15 : matrice has_verified_role ====================
create temp table t_matrix (label text, uid uuid, roles text[], expected boolean);
insert into t_matrix values
  ('patient', 'c2110000-0000-0000-0000-000000000001', array['patient'], false),
  ('pharmacien avec officine (Kaloum)', 'c2110000-0000-0000-0000-000000000014', array['pharmacien'], true),
  ('pharmacien sans officine', 'c2110000-0000-0000-0000-000000000009', array['pharmacien'], false),
  ('professionnel verifie', 'c2110000-0000-0000-0000-000000000006', array['professionnel'], true),
  ('professionnel non verifie', 'c2110000-0000-0000-0000-000000000004', array['professionnel'], false),
  ('grossiste valide', 'c2110000-0000-0000-0000-000000000007', array['grossiste'], true),
  ('grossiste non valide', 'c2110000-0000-0000-0000-000000000008', array['grossiste'], false),
  ('livreur valide', 'c2110000-0000-0000-0000-000000000012', array['livreur'], true),
  ('livreur non valide', 'c2110000-0000-0000-0000-000000000013', array['livreur'], false),
  ('regulateur valide', 'c2110000-0000-0000-0000-000000000010', array['regulateur'], true),
  ('regulateur non valide', 'c2110000-0000-0000-0000-000000000011', array['regulateur'], false),
  ('grossiste valide, role demande pharmacien', 'c2110000-0000-0000-0000-000000000007', array['pharmacien'], false);
do $$
declare r record; v boolean;
begin
  for r in select * from t_matrix loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.uid, 'role', 'authenticated')::text, true);
    v := public.has_verified_role(r.roles);
    if v = r.expected then
      raise notice 'CAS 15 OK : % : has_verified_role(%) = %', r.label, r.roles, v;
    else
      raise notice 'CAS 15 ECHEC : % : has_verified_role(%) = % (attendu %)', r.label, r.roles, v, r.expected;
    end if;
  end loop;
end $$;

-- ==================== Cas 16 : e-ordonnance par un professionnel non vérifié ====================
select pg_temp.as_user(:'PRO');
set local role authenticated;
do $$ begin
  insert into public.eprescriptions (patient_id, doctor_id, valid_until, status)
    values ('c2110000-0000-0000-0000-000000000001', auth.uid(), current_date + 30, 'draft');
  insert into t_out values ('16', 'OK', null);
exception when others then insert into t_out values ('16', sqlstate, sqlerrm);
end $$;
reset role;
select pg_temp.expect('16', '42501', (select count(*) = 0 from public.eprescriptions where doctor_id = :'PRO'),
  '; RG-PRE-01 tient (is_verified non modifiable par le professionnel)');

rollback;
