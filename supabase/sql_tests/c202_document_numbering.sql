-- C202 : numérotation globale des documents (retours client et fournisseur,
-- tickets de support, e-ordonnances, contrats B2B).
--
-- Pour chaque table : deux identités dont les portées RLS ne se recouvrent
-- pas créent chacune une ligne. Avant C202, la fonction de numérotation
-- (max + 1, sans SECURITY DEFINER) ne voit que les lignes de l'identité
-- courante : la seconde insertion reprend le numéro de la première et échoue
-- sur l'unicité (23505). Après C202 : deux numéros consécutifs, au-dessus du
-- maximum initial.
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c202_document_numbering.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
begin;

-- ==================== Identités ====================
-- A (Kaloum) et B (Dixinn) : pharmaciens, comme dans le test C197.
-- P1, P2 : patients. M1, M2 : professionnels vérifiés (policy
-- « Doctors manage own prescriptions » : auth.uid() = doctor_id et
-- is_verified_professional_account(doctor_id)). ADM : admin GSG actif
-- (seule policy de business_contracts : is_gsg_admin()).
insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'c202-a@test.local'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'c202-b@test.local'),
  ('c0000000-0000-0000-0000-0000000000c1', 'c202-p1@test.local'),
  ('c0000000-0000-0000-0000-0000000000c2', 'c202-p2@test.local'),
  ('d0000000-0000-0000-0000-0000000000d1', 'c202-m1@test.local'),
  ('d0000000-0000-0000-0000-0000000000d2', 'c202-m2@test.local'),
  ('e0000000-0000-0000-0000-0000000000e1', 'c202-adm@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'Pharmacien A Kaloum'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'Pharmacien B Dixinn'),
  ('c0000000-0000-0000-0000-0000000000c1', 'patient', null, 'Patient P1'),
  ('c0000000-0000-0000-0000-0000000000c2', 'patient', null, 'Patient P2'),
  ('d0000000-0000-0000-0000-0000000000d1', 'professionnel', null, 'Medecin M1'),
  ('d0000000-0000-0000-0000-0000000000d2', 'professionnel', null, 'Medecin M2'),
  ('e0000000-0000-0000-0000-0000000000e1', 'patient', null, 'Admin GSG');
insert into public.professional_profiles (id, is_verified, verification_status) values
  ('d0000000-0000-0000-0000-0000000000d1', true, 'verified'),
  ('d0000000-0000-0000-0000-0000000000d2', true, 'verified');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('e0000000-0000-0000-0000-0000000000e1', 'c202-adm@test.local', 'Admin GSG', 'admin', true);
insert into public.business_companies (id, name, type) values
  ('f0000000-0000-0000-0000-0000000000f1', 'Societe test C202', 'other');

-- Résultats : un numéro (ou un SQLSTATE) par insertion.
create temp table t_res (tbl text, ident text, num text, err text);
grant all on t_res to authenticated;

create function pg_temp.as_user(u text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true)
$$;

-- Maximum initial (en tant que postgres : toutes les lignes).
create temp table t_max as
  select 'customer_returns'::text as tbl, coalesce(max(substring(return_number from '^CR([0-9]+)$')::integer), 0) as m from public.customer_returns
  union all select 'supplier_returns', coalesce(max(substring(return_number from '^SR([0-9]+)$')::integer), 0) from public.supplier_returns
  union all select 'support_tickets', coalesce(max(substring(ticket_number from '^T([0-9]+)$')::integer), 0) from public.support_tickets
  union all select 'eprescriptions', coalesce(max(substring(prescription_number from '^RX([0-9]+)$')::integer), 0) from public.eprescriptions
  union all select 'business_contracts', coalesce(max(substring(contract_number from '^CON-([0-9]+)$')::integer), 0) from public.business_contracts;
\echo '===== Maximum initial par table'
select * from t_max order by tbl;

-- Contrôle : deux numéros obtenus, consécutifs, au-dessus du max initial.
create function pg_temp.check(p_case text, p_tbl text, p_regex text) returns void language plpgsql as $$
declare
  v_max integer;
  v_nums integer[];
  v_errs text;
  v_raw text;
begin
  select m into v_max from t_max where tbl = p_tbl;
  select array_agg(substring(num from p_regex)::integer order by ident), string_agg(ident || '=' || coalesce(num, 'erreur ' || err), ', ' order by ident),
         string_agg(err, ',') filter (where err is not null)
    into v_nums, v_raw, v_errs
    from t_res where tbl = p_tbl;
  if v_errs is null and array_length(v_nums, 1) = 2
     and v_nums[1] = v_max + 1 and v_nums[2] = v_max + 2 then
    raise notice 'CAS % OK : % (max initial %) : %', p_case, p_tbl, v_max, v_raw;
  else
    raise notice 'CAS % ECHEC : % (max initial %) : %', p_case, p_tbl, v_max, v_raw;
  end if;
end;
$$;

-- ==================== C202-1 : customer_returns (A puis B) ====================
select pg_temp.as_user('aaaaaaaa-0000-0000-0000-00000000000a');
set local role authenticated;
do $$ declare n text; begin
  insert into public.customer_returns (pharmacy_id, status, total_amount)
    values ('55555555-5555-5555-5555-555555550001', 'pending', 0) returning return_number into n;
  insert into t_res values ('customer_returns', '1-A', n, null);
exception when others then insert into t_res values ('customer_returns', '1-A', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;
select pg_temp.as_user('bbbbbbbb-0000-0000-0000-00000000000b');
set local role authenticated;
do $$ declare n text; begin
  insert into public.customer_returns (pharmacy_id, status, total_amount)
    values ('55555555-5555-5555-5555-555555550002', 'pending', 0) returning return_number into n;
  insert into t_res values ('customer_returns', '2-B', n, null);
exception when others then insert into t_res values ('customer_returns', '2-B', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;

-- ==================== C202-2 : supplier_returns (A puis B) ====================
select pg_temp.as_user('aaaaaaaa-0000-0000-0000-00000000000a');
set local role authenticated;
do $$ declare n text; begin
  insert into public.supplier_returns (pharmacy_id, status, total_amount)
    values ('55555555-5555-5555-5555-555555550001', 'pending', 0) returning return_number into n;
  insert into t_res values ('supplier_returns', '1-A', n, null);
exception when others then insert into t_res values ('supplier_returns', '1-A', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;
select pg_temp.as_user('bbbbbbbb-0000-0000-0000-00000000000b');
set local role authenticated;
do $$ declare n text; begin
  insert into public.supplier_returns (pharmacy_id, status, total_amount)
    values ('55555555-5555-5555-5555-555555550002', 'pending', 0) returning return_number into n;
  insert into t_res values ('supplier_returns', '2-B', n, null);
exception when others then insert into t_res values ('supplier_returns', '2-B', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;

-- ==================== C202-3 : support_tickets (P1 puis P2) ====================
select pg_temp.as_user('c0000000-0000-0000-0000-0000000000c1');
set local role authenticated;
do $$ declare n text; begin
  insert into public.support_tickets (patient_id, subject, description, status, priority)
    values ('c0000000-0000-0000-0000-0000000000c1', 'Test C202', 'Ticket P1', 'new', 'low') returning ticket_number into n;
  insert into t_res values ('support_tickets', '1-P1', n, null);
exception when others then insert into t_res values ('support_tickets', '1-P1', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;
select pg_temp.as_user('c0000000-0000-0000-0000-0000000000c2');
set local role authenticated;
do $$ declare n text; begin
  insert into public.support_tickets (patient_id, subject, description, status, priority)
    values ('c0000000-0000-0000-0000-0000000000c2', 'Test C202', 'Ticket P2', 'new', 'low') returning ticket_number into n;
  insert into t_res values ('support_tickets', '2-P2', n, null);
exception when others then insert into t_res values ('support_tickets', '2-P2', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;

-- ==================== C202-4 : eprescriptions (M1 puis M2) ====================
select pg_temp.as_user('d0000000-0000-0000-0000-0000000000d1');
set local role authenticated;
do $$ declare n text; begin
  insert into public.eprescriptions (patient_id, doctor_id, valid_until, status)
    values ('c0000000-0000-0000-0000-0000000000c1', 'd0000000-0000-0000-0000-0000000000d1', current_date + 30, 'draft')
    returning prescription_number into n;
  insert into t_res values ('eprescriptions', '1-M1', n, null);
exception when others then insert into t_res values ('eprescriptions', '1-M1', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;
select pg_temp.as_user('d0000000-0000-0000-0000-0000000000d2');
set local role authenticated;
do $$ declare n text; begin
  insert into public.eprescriptions (patient_id, doctor_id, valid_until, status)
    values ('c0000000-0000-0000-0000-0000000000c2', 'd0000000-0000-0000-0000-0000000000d2', current_date + 30, 'draft')
    returning prescription_number into n;
  insert into t_res values ('eprescriptions', '2-M2', n, null);
exception when others then insert into t_res values ('eprescriptions', '2-M2', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;

-- ==================== C202-5 : business_contracts (ADM, deux fois) ====================
-- Seule policy : is_gsg_admin(), qui voit toutes les lignes. Aucune paire
-- d'identités autorisées aux portées disjointes : un seul cas, deux
-- insertions successives par le même admin.
select pg_temp.as_user('e0000000-0000-0000-0000-0000000000e1');
set local role authenticated;
do $$ declare n text; begin
  insert into public.business_contracts (company_id, title, type, start_date)
    values ('f0000000-0000-0000-0000-0000000000f1', 'Contrat 1', 'service', current_date) returning contract_number into n;
  insert into t_res values ('business_contracts', '1-ADM', n, null);
exception when others then insert into t_res values ('business_contracts', '1-ADM', null, sqlstate || ' ' || sqlerrm);
end $$;
do $$ declare n text; begin
  insert into public.business_contracts (company_id, title, type, start_date)
    values ('f0000000-0000-0000-0000-0000000000f1', 'Contrat 2', 'service', current_date) returning contract_number into n;
  insert into t_res values ('business_contracts', '2-ADM', n, null);
exception when others then insert into t_res values ('business_contracts', '2-ADM', null, sqlstate || ' ' || sqlerrm);
end $$;
reset role;

-- ==================== Bilan ====================
\echo '===== Resultats'
select pg_temp.check('C202-1', 'customer_returns', '^CR([0-9]+)$');
select pg_temp.check('C202-2', 'supplier_returns', '^SR([0-9]+)$');
select pg_temp.check('C202-3', 'support_tickets', '^T([0-9]+)$');
select pg_temp.check('C202-4', 'eprescriptions', '^RX([0-9]+)$');
select pg_temp.check('C202-5', 'business_contracts', '^CON-([0-9]+)$');
select tbl, ident, num, err from t_res order by tbl, ident;

rollback;
