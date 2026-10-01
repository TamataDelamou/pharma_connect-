-- C222 (décision D66) : fiche professionnelle créée par le professionnel,
-- vérifiée par GSG ; fiche refusée corrigée puis remise en attente.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c222_professional_self_profile.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- c2220000-…-0000000000xx : 01 PAT patient ; 03 ADM admin GSG ;
--   30 PRO professionnel sans fiche ; 31 PRO2 professionnel sans fiche.
insert into auth.users (id, email)
  select ('c2220000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c222-' || n || '@test.local'
  from unnest(array[1,3,30,31]) n;
insert into public.profiles (id, role, full_name) values
  ('c2220000-0000-0000-0000-000000000001', 'patient', 'PAT'),
  ('c2220000-0000-0000-0000-000000000003', 'patient', 'ADM'),
  ('c2220000-0000-0000-0000-000000000030', 'professionnel', 'PRO'),
  ('c2220000-0000-0000-0000-000000000031', 'professionnel', 'PRO2');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2220000-0000-0000-0000-000000000003', 'c222-3@test.local', 'Admin C222', 'admin', true);

\set PAT 'c2220000-0000-0000-0000-000000000001'
\set ADM 'c2220000-0000-0000-0000-000000000003'
\set PRO 'c2220000-0000-0000-0000-000000000030'
\set PRO2 'c2220000-0000-0000-0000-000000000031'

create temp table t_out (c text primary key, state text, msg text);
create temp table t_ctx (k text primary key, v text);
grant all on t_out, t_ctx to authenticated, anon;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

create function pg_temp.verdict(p_case text, p_ok boolean, p_detail text) returns void language plpgsql as $$
begin
  if coalesce(p_ok, false) then raise notice 'CAS % OK : %', p_case, p_detail;
  else raise notice 'CAS % ECHEC : %', p_case, p_detail; end if;
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

create function pg_temp.run(p_case text, p_sql text) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into t_out values (p_case, 'OK', null);
exception when others then insert into t_out values (p_case, sqlstate, sqlerrm);
end;
$$;

-- ==================== Création ====================
select pg_temp.as_user(:'PRO'); set local role authenticated;
select public.my_account_status()->>'state' as state_before \gset
select pg_temp.run('1', $q$
  insert into public.professional_profiles (id, specialty, license_number, license_issuing_body, license_expiry_date, is_verified, verification_status)
  values (auth.uid(), 'Pediatrie', 'ONMG-1234', 'Ordre national des medecins de Guinee', current_date + 365, true, 'verified')
$q$);
select public.my_account_status()->>'state' as state_after,
       public.has_verified_role(array['professionnel']) as active_after \gset
reset role;
select pg_temp.expect('1', 'OK',
  :'state_before' = 'professional_profile_missing'
  and (select not is_verified and verification_status = 'pending' from public.professional_profiles where id = :'PRO')
  and :'state_after' = 'pending_review' and not :'active_after'::boolean,
  '; fiche creee par le professionnel : en attente (verification envoyee ignoree), compte en attente de verification');

select pg_temp.as_user(:'PRO2'); set local role authenticated;
select pg_temp.run('2', $q$
  insert into public.professional_profiles (id, specialty) values (auth.uid(), 'Cardiologie')
$q$);
select pg_temp.run('3', $q$
  insert into public.professional_profiles (id, license_number, license_issuing_body)
  values ('c2220000-0000-0000-0000-000000000001', 'X-1', 'Ordre')
$q$);
reset role;
select pg_temp.as_user(:'PAT'); set local role authenticated;
select pg_temp.run('4', $q$
  insert into public.professional_profiles (id, license_number, license_issuing_body) values (auth.uid(), 'X-2', 'Ordre')
$q$);
reset role;
select pg_temp.expect('2', '22023', true, '; numero d''ordre et organisme obligatoires');
select pg_temp.expect('3', '42501', true, '; fiche au nom d''un autre compte refusee');
select pg_temp.expect('4', '42501', true, '; un patient ne cree pas de fiche professionnelle');

-- ==================== Vérification GSG ====================
select pg_temp.as_user(:'ADM'); set local role authenticated;
select count(*) as listed from public.admin_list_verification_requests('pending', null)
 where user_id = :'PRO' and professional_status = 'pending' and license_number = 'ONMG-1234' \gset
select public.admin_verify_professional(:'PRO', false, 'Numero d''ordre illisible');
reset role;
select pg_temp.verdict('5', :'listed' = '1', 'la fiche apparait dans la liste de verification de GSG (en attente, avec la licence)');

select pg_temp.as_user(:'PRO'); set local role authenticated;
select public.my_account_status()->>'state' as state_rejected,
       public.my_account_status()->>'professional_rejection_reason' as reason_rejected \gset
select pg_temp.run('6a', $q$ update public.professional_profiles set bio = 'Pediatre a Conakry' where id = auth.uid() $q$);
select verification_status as status_after_bio from public.professional_profiles where id = :'PRO' \gset
select pg_temp.run('6b', $q$ update public.professional_profiles set verification_status = 'pending' where id = auth.uid() $q$);
select pg_temp.run('6c', $q$ update public.professional_profiles set license_number = 'ONMG-1234-B' where id = auth.uid() $q$);
select public.my_account_status()->>'state' as state_corrected \gset
reset role;
select pg_temp.verdict('6',
  :'state_rejected' = 'professional_rejected' and :'reason_rejected' = 'Numero d''ordre illisible'
  and (select state = 'OK' from t_out where c = '6a') and :'status_after_bio' = 'rejected',
  'fiche refusee : motif rendu ; modifier la presentation ne change pas le statut');
select pg_temp.expect('6b', '42501', true, '; le professionnel ne remet pas lui-meme sa fiche en attente');
select pg_temp.expect('6c', 'OK',
  (select verification_status = 'pending' and rejection_reason is null and not is_verified
     from public.professional_profiles where id = :'PRO')
  and :'state_corrected' = 'pending_review',
  '; licence corrigee : fiche de nouveau en attente, motif efface');

select pg_temp.as_user(:'ADM'); set local role authenticated;
select public.admin_verify_professional(:'PRO', true, null);
reset role;
select pg_temp.as_user(:'PRO'); set local role authenticated;
select public.my_account_status()->>'state' as state_final,
       public.has_verified_role(array['professionnel']) as active_final \gset
reset role;
select pg_temp.verdict('7', :'state_final' = 'verified' and :'active_final'::boolean,
  'GSG valide la fiche : professionnel verifie, role actif');

rollback;
