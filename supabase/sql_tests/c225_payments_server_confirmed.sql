-- C225 (décision D67) : l'argent ne se confirme plus côté client.
-- Chaque cas affiche « CAS n OK : … » ou « CAS n ECHEC : … ».
--
-- Exécution : docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c225_payments_server_confirmed.sql
-- Une seule transaction, terminée par rollback : aucune donnée ne reste.

\set ON_ERROR_STOP on
\pset footer off
\set QUIET on
begin;

-- c2250000-…-0000000000xx : 01 PAT patient ; 02 PAT2 patient ; 03 ADM admin GSG ;
--   10 PH pharmacien de Kaloum ; 11 PHD pharmacien de Dixinn.
insert into auth.users (id, email)
  select ('c2250000-0000-0000-0000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'c225-' || n || '@test.local'
  from unnest(array[1,2,3,10,11]) n;
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('c2250000-0000-0000-0000-000000000001', 'patient', null, 'PAT'),
  ('c2250000-0000-0000-0000-000000000002', 'patient', null, 'PAT2'),
  ('c2250000-0000-0000-0000-000000000003', 'patient', null, 'ADM'),
  ('c2250000-0000-0000-0000-000000000010', 'pharmacien', '55555555-5555-5555-5555-555555550001', 'PH Kaloum'),
  ('c2250000-0000-0000-0000-000000000011', 'pharmacien', '55555555-5555-5555-5555-555555550002', 'PHD Dixinn');
insert into public.admin_users (user_id, email, full_name, role, is_active) values
  ('c2250000-0000-0000-0000-000000000003', 'c225-3@test.local', 'Admin C225', 'admin', true);
-- Portefeuille de PAT crédité par le serveur (10 000 GNF, 300 de cashback).
insert into public.wallets (user_id, balance, cashback_available) values
  ('c2250000-0000-0000-0000-000000000001', 10000, 300);

\set PAT 'c2250000-0000-0000-0000-000000000001'
\set PAT2 'c2250000-0000-0000-0000-000000000002'
\set ADM 'c2250000-0000-0000-0000-000000000003'
\set PH 'c2250000-0000-0000-0000-000000000010'
\set PHD 'c2250000-0000-0000-0000-000000000011'
\set KALOUM '55555555-5555-5555-5555-555555550001'

create temp table t_out (c text primary key, state text, msg text);
grant all on t_out to authenticated, anon;

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

create function pg_temp.tx(p_id text) returns public.transactions language sql as $$
  select * from public.transactions where id = p_id::uuid
$$;

-- Transactions du patient (créées par lui, en attente).
--   T1 : Orange Money 5 000 à Kaloum ; T2 : portefeuille 4 000 (cashback 200) à Kaloum ;
--   T3 : espèces 3 000 à Kaloum ; T4 : paiement en 2 fois 6 000 à Kaloum ;
--   T5 : Orange Money 1 000 à Kaloum, abandonnée ensuite.
select pg_temp.as_user(:'PAT'); set local role authenticated;
select pg_temp.run('1', $q$
  insert into public.transactions (id, user_id, user_phone, pharmacy_id, amount, fee, cashback, final_amount, method, status) values
    ('c2250000-0000-0000-0000-0000000000a1', auth.uid(), '+224600000001', '55555555-5555-5555-5555-555555550001', 5000, 50, 0, 5050, 'orangeMoney', 'processing'),
    ('c2250000-0000-0000-0000-0000000000a2', auth.uid(), '+224600000001', '55555555-5555-5555-5555-555555550001', 4000, 0, 200, 3800, 'gsgWallet', 'processing'),
    ('c2250000-0000-0000-0000-0000000000a3', auth.uid(), '+224600000001', '55555555-5555-5555-5555-555555550001', 3000, 0, 0, 3000, 'cashOnDelivery', 'pending'),
    ('c2250000-0000-0000-0000-0000000000a4', auth.uid(), '+224600000001', '55555555-5555-5555-5555-555555550001', 6000, 0, 0, 6000, 'installment', 'processing'),
    ('c2250000-0000-0000-0000-0000000000a5', auth.uid(), '+224600000001', '55555555-5555-5555-5555-555555550001', 1000, 0, 0, 1000, 'orangeMoney', 'pending')
$q$);
select pg_temp.run('2a', $q$
  insert into public.transactions (user_id, user_phone, amount, final_amount, method, status, completed_at)
  values (auth.uid(), '+224600000001', 9000, 9000, 'orangeMoney', 'completed', now())
$q$);
select pg_temp.run('2b', $q$ update public.transactions set status = 'completed', completed_at = now() where id = 'c2250000-0000-0000-0000-0000000000a1' $q$);
select pg_temp.run('2c', $q$ update public.wallets set balance = 1000000 where user_id = auth.uid() $q$);
select pg_temp.run('2d', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a1') $q$);
select pg_temp.run('2e', $q$
  insert into public.invoices (transaction_id, invoice_number, pharmacy_name, pharmacy_address, pharmacy_phone, patient_name, patient_address, patient_phone, patient_email, subtotal, total, status)
  values ('c2250000-0000-0000-0000-0000000000a1', 'FAUX-1', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 5000, 5000, 'paid')
$q$);
-- Échéancier de T4 (2 x 3 000), créé par le patient.
select pg_temp.run('3', $q$
  insert into public.installments (id, transaction_id, total_amount, number_of_payments, amount_per_payment, start_date)
  values ('c2250000-0000-0000-0000-0000000000b4', 'c2250000-0000-0000-0000-0000000000a4', 6000, 2, 3000, current_date);
  insert into public.installment_payments (installment_id, payment_number, amount, due_date) values
    ('c2250000-0000-0000-0000-0000000000b4', 1, 3000, current_date),
    ('c2250000-0000-0000-0000-0000000000b4', 2, 3000, current_date + 30)
$q$);
select pg_temp.run('3b', $q$ update public.installment_payments set status = 'paid', paid_at = now() where installment_id = 'c2250000-0000-0000-0000-0000000000b4' $q$);
reset role;

select pg_temp.expect('1', 'OK', true, '; le patient cree ses transactions en attente');
select pg_temp.expect('2a', '42501', true, '; transaction creee deja payee : refusee');
select pg_temp.expect('2b', 'OK', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a1')).status = 'processing',
  '; modification directe sans effet : la transaction reste en cours');
select pg_temp.expect('2c', 'OK', (select balance = 10000 from public.wallets where user_id = :'PAT'),
  '; credit direct du portefeuille sans effet (solde inchange)');
select pg_temp.expect('2d', '42501', true, '; le patient ne confirme pas son propre paiement');
select pg_temp.expect('2e', '42501', true, '; le patient ne cree pas de facture');
select pg_temp.expect('3', 'OK', true, '; le patient cree son echeancier');
select pg_temp.expect('3b', 'OK', (select bool_and(status = 'pending') from public.installment_payments where installment_id = 'c2250000-0000-0000-0000-0000000000b4'),
  '; echeances marquees payees par le patient : sans effet');

-- ==================== Confirmation par l'officine ====================
select pg_temp.as_user(:'PHD'); set local role authenticated;
select pg_temp.run('4a', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a1') $q$);
reset role;
select (pg_temp.tx('c2250000-0000-0000-0000-0000000000a1')).status as t1_after_4a \gset
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('4b', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a1') $q$);
select pg_temp.run('4c', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a1') $q$);
select pg_temp.run('5', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a2') $q$);
reset role;
select balance as w_bal, cashback_available as w_cb, total_spent as w_spent from public.wallets where user_id = :'PAT' \gset
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('6', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a3') $q$);
select pg_temp.run('7a', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a4') $q$);
select pg_temp.run('7b', $q$ select public.payment_confirm_installment('c2250000-0000-0000-0000-0000000000a4', 1) $q$);
select pg_temp.run('7c', $q$ select public.payment_confirm_installment('c2250000-0000-0000-0000-0000000000a4', 1) $q$);
reset role;
select (pg_temp.tx('c2250000-0000-0000-0000-0000000000a4')).status as t4_after_first \gset
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('7d', $q$ select public.payment_confirm_installment('c2250000-0000-0000-0000-0000000000a4', 2) $q$);
reset role;

select pg_temp.expect('4a', '42501', :'t1_after_4a' = 'processing',
  '; une autre officine ne confirme pas le paiement');
select pg_temp.expect('4b', 'OK',
  (select status = 'completed' and completed_at is not null and confirmed_by = :'PH' from public.transactions where id = 'c2250000-0000-0000-0000-0000000000a1')
  and (select count(*) = 1 from public.invoices where transaction_id = 'c2250000-0000-0000-0000-0000000000a1' and status = 'paid' and total = 5050 and invoice_number ~ '^FAC[0-9]{6}$')
  and (select count(*) = 1 from public.audit_logs where action = 'payment_confirmed' and resource_id = 'c2250000-0000-0000-0000-0000000000a1' and user_id = :'PH'),
  '; Mobile Money confirme par l''officine : paye, auteur trace, facture numerotee, journal');
select pg_temp.expect('4c', '22023', true, '; double confirmation refusee');
select pg_temp.expect('5', 'OK',
  :'w_bal' = '6200' and :'w_cb' = '100' and :'w_spent' = '8850',
  '; paiement par portefeuille : solde debite (3 800), cashback utilise deduit (200), total depense');
select pg_temp.expect('6', 'OK', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a3')).status = 'completed',
  '; especes a la livraison confirmees par l''officine');
select pg_temp.expect('7a', '22023', true, '; paiement en plusieurs fois : pas de confirmation globale');
select pg_temp.expect('7b', 'OK', :'t4_after_first' = 'processing', '; premiere echeance payee : transaction toujours en cours');
select pg_temp.expect('7c', '22023', true, '; echeance deja payee refusee');
select pg_temp.expect('7d', 'OK',
  (pg_temp.tx('c2250000-0000-0000-0000-0000000000a4')).status = 'completed'
  and (select status = 'completed' from public.installments where id = 'c2250000-0000-0000-0000-0000000000b4')
  and (select count(*) = 1 from public.invoices where transaction_id = 'c2250000-0000-0000-0000-0000000000a4'),
  '; derniere echeance : echeancier solde, transaction payee, facture');

-- Portefeuille insuffisant.
insert into public.transactions (id, user_id, user_phone, pharmacy_id, amount, final_amount, method, status)
values ('c2250000-0000-0000-0000-0000000000a6', :'PAT', '+224600000001', :'KALOUM', 50000, 50000, 'gsgWallet', 'processing');
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('8', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a6') $q$);
reset role;
select pg_temp.expect('8', '22023', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a6')).status = 'processing',
  '; solde du portefeuille insuffisant : refus, rien n''est ecrit');

-- ==================== Patient : abandon et contestation ====================
select pg_temp.as_user(:'PAT2'); set local role authenticated;
select pg_temp.run('9a', $q$ select public.payment_cancel_transaction('c2250000-0000-0000-0000-0000000000a5') $q$);
reset role;
select pg_temp.as_user(:'PAT'); set local role authenticated;
select pg_temp.run('9b', $q$ select public.payment_cancel_transaction('c2250000-0000-0000-0000-0000000000a5') $q$);
select pg_temp.run('9c', $q$ select public.payment_cancel_transaction('c2250000-0000-0000-0000-0000000000a1') $q$);
select pg_temp.run('10', $q$ select public.payment_dispute_transaction('c2250000-0000-0000-0000-0000000000a1', 'Montant debite deux fois') $q$);
reset role;
select pg_temp.expect('9a', '42501', true, '; un autre patient n''abandonne pas la transaction');
select pg_temp.expect('9b', 'OK', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a5')).status = 'failed', '; le patient abandonne une transaction non payee');
select pg_temp.expect('9c', '22023', true, '; une transaction payee ne s''abandonne pas');
select pg_temp.expect('10', 'OK', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a1')).status = 'disputed', '; le patient conteste un paiement, avec motif');

-- ==================== Remboursement ====================
select pg_temp.as_user(:'PAT'); set local role authenticated;
select pg_temp.run('11a', $q$ select public.payment_refund_transaction('c2250000-0000-0000-0000-0000000000a2', 'Je veux mon argent') $q$);
reset role;
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('11b', $q$ select public.payment_refund_transaction('c2250000-0000-0000-0000-0000000000a2', '') $q$);
select pg_temp.run('11c', $q$ select public.payment_refund_transaction('c2250000-0000-0000-0000-0000000000a2', 'Produit indisponible') $q$);
select pg_temp.run('11d', $q$ select public.payment_refund_transaction('c2250000-0000-0000-0000-0000000000a5', 'Produit indisponible') $q$);
reset role;
select pg_temp.expect('11a', '42501', true, '; le patient ne se rembourse pas lui-meme');
select pg_temp.expect('11b', '22023', true, '; motif du remboursement obligatoire');
select pg_temp.expect('11c', 'OK',
  (select status = 'refunded' and refunded_by = :'PH' from public.transactions where id = 'c2250000-0000-0000-0000-0000000000a2')
  and (select balance = 10000 and cashback_available = 300 from public.wallets where user_id = :'PAT')
  and (select status = 'refunded' from public.invoices where transaction_id = 'c2250000-0000-0000-0000-0000000000a2'),
  '; remboursement d''un paiement par portefeuille : solde et cashback rendus, facture marquee remboursee');
select pg_temp.expect('11d', '22023', true, '; une transaction non payee ne se rembourse pas');

-- ==================== GSG et droits ====================
insert into public.transactions (id, user_id, user_phone, amount, final_amount, method, status)
values ('c2250000-0000-0000-0000-0000000000a7', :'PAT2', '+224600000002', 2000, 2000, 'mtnMomo', 'processing');
select pg_temp.as_user(:'PH'); set local role authenticated;
select pg_temp.run('12a', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a7') $q$);
reset role;
select pg_temp.as_user(:'ADM'); set local role authenticated;
select pg_temp.run('12b', $q$ select public.payment_confirm_transaction('c2250000-0000-0000-0000-0000000000a7') $q$);
reset role;
select pg_temp.expect('12a', '42501', true, '; transaction sans officine : une officine ne la confirme pas');
select pg_temp.expect('12b', 'OK', (pg_temp.tx('c2250000-0000-0000-0000-0000000000a7')).status = 'completed', '; GSG confirme une transaction sans officine (facture creee, portefeuille du patient ouvert)');

select pg_temp.as_user(:'ADM'); set local role authenticated;
select pg_temp.run('13', $q$ insert into public.wallets (user_id, balance) values (auth.uid(), 500) $q$);
select pg_temp.run('13b', $q$ insert into public.wallets (user_id) values (auth.uid()) $q$);
reset role;
select pg_temp.expect('13', '42501', true, '; portefeuille cree avec un solde : refuse');
select pg_temp.expect('13b', 'OK', true, '; portefeuille cree a zero : accepte');

select pg_temp.verdict('14',
  not has_function_privilege('anon', 'public.payment_confirm_transaction(uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.payment_settle_completed(public.transactions)', 'execute')
  and not has_function_privilege('authenticated', 'public.payment_can_collect(public.transactions)', 'execute'),
  'fonctions de paiement fermees a anon ; reglement interne non appelable par les clients');

rollback;
