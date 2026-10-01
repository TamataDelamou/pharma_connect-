-- C224 : une seule candidature d'officine en attente par titulaire ;
-- candidature réservée à un compte déclaré pharmacien.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c224_single_pending_pharmacy_application.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- c2240000-…-0000000000xx : 01 PAT patient ; 03 ADM admin GSG ;
--   30 PH pharmacien sans officine ; 31 PH2 pharmacien sans officine.
insert into auth.users (id, email)
  select ('c2240000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c224-' || n || '@test.local'
  from unnest(array[1,3,30,31]) n;
insert into public.profiles (id, role, full_name) values
  ('c2240000-0000-0000-0000-000000000001', 'patient', 'PAT'),
  ('c2240000-0000-0000-0000-000000000003', 'patient', 'ADM'),
  ('c2240000-0000-0000-0000-000000000030', 'pharmacien', 'PH'),
  ('c2240000-0000-0000-0000-000000000031', 'pharmacien', 'PH2');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2240000-0000-0000-0000-000000000003', 'c224-3@test.local', 'Admin C224', 'admin', true);

\set PAT 'c2240000-0000-0000-0000-000000000001'
\set ADM 'c2240000-0000-0000-0000-000000000003'
\set PH 'c2240000-0000-0000-0000-000000000030'
\set PH2 'c2240000-0000-0000-0000-000000000031'

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

-- Candidature de l'utilisateur courant.
create function pg_temp.apply(p_case text, p_name text) returns void language plpgsql as $$
begin
  insert into public.pharmacies (name, address, phone, manager_id, manager_name, status)
  values (p_name, 'Conakry', '+224600000000', auth.uid(), 'Titulaire', 'pending');
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

create function pg_temp.n(p_manager uuid) returns bigint language sql as $$
  select count(*) from public.pharmacies where manager_id = p_manager
$$;

select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.apply('1', 'Officine A');
select pg_temp.apply('2', 'Officine A bis');
reset role;
select pg_temp.expect('1', 'OK', true, '; premiere candidature acceptee');
select pg_temp.expect('2', '22023', pg_temp.n(:'PH') = 1, '; seconde candidature pendant l''attente refusee');

update public.pharmacies set status = 'underReview' where manager_id = :'PH';
select pg_temp.as_user(:'PH'); set local role authenticated; select pg_temp.apply('3', 'Officine A ter'); reset role;
select pg_temp.expect('3', '22023', pg_temp.n(:'PH') = 1, '; candidature en revue : nouvelle candidature refusee');

update public.pharmacies set status = 'rejected' where manager_id = :'PH';
select pg_temp.as_user(:'PH'); set local role authenticated; select pg_temp.apply('4', 'Officine A corrigee'); reset role;
select pg_temp.expect('4', 'OK', pg_temp.n(:'PH') = 2, '; apres un refus, nouvelle candidature acceptee');

select pg_temp.as_user(:'PH2'); set local role authenticated; select pg_temp.apply('5', 'Officine B'); reset role;
select pg_temp.expect('5', 'OK', true, '; un autre pharmacien n''est pas bloque');

select pg_temp.as_user(:'PAT'); set local role authenticated; select pg_temp.apply('6', 'Officine du patient'); reset role;
select pg_temp.expect('6', '42501', pg_temp.n(:'PAT') = 0, '; un patient ne depose pas de candidature d''officine');

-- Écriture serveur (postgres, service_role) : non concernée par la limite.
do $$ begin
  insert into public.pharmacies (name, address, phone, manager_id, manager_name, status)
  values ('Officine B2 (serveur)', 'Conakry', '+224600000000', 'c2240000-0000-0000-0000-000000000031', 'Titulaire', 'pending');
  insert into t_out values ('7', 'OK', null);
exception when others then insert into t_out values ('7', sqlstate, sqlerrm);
end $$;
select pg_temp.expect('7', 'OK', pg_temp.n(:'PH2') = 2, '; ecriture serveur non concernee par la limite');

rollback;
