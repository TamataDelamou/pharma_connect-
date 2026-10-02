-- C225 (décision D67) : l'argent ne se confirme plus côté client.
--
-- Constat (bilan du 02/10/2026, RG-PAY-01, règle critique du cahier) :
--   - transactions : le patient pouvait créer une transaction déjà
--     « completed » et passer la sienne en « completed » (règle
--     transactions_update_own) ; l'application le faisait d'ailleurs après
--     un délai simulé de 2 secondes ;
--   - wallets : wallets_update_own laissait le patient fixer lui-même son
--     solde, son cashback et ses totaux (« recharge » sans paiement) ;
--   - installments / installment_payments : le patient marquait lui-même ses
--     échéances payées et son échéancier soldé ;
--   - invoices / invoice_items : le patient créait ses propres factures
--     « payées ».
--
-- D67 : en attendant le branchement des opérateurs (Orange, MTN, Moov), le
-- personnel de l'officine concernée confirme un paiement, tous moyens
-- confondus, après avoir constaté l'encaissement (espèces ou compte
-- marchand) ; chaque confirmation est journalisée avec son auteur. Le patient
-- ne confirme jamais. La recharge du portefeuille depuis l'application est
-- désactivée : seuls le serveur et GSG modifient les soldes.
--
-- Mise en œuvre : plus aucune écriture directe du client sur l'état
-- financier ; fonctions SECURITY DEFINER pour confirmer, rembourser, payer
-- une échéance (officine, GSG), abandonner et contester (patient).

-- ============================================================
-- 0. Colonnes de traçabilité
-- ============================================================
alter table public.transactions add column if not exists confirmed_by uuid references auth.users(id);
alter table public.transactions add column if not exists refunded_by uuid references auth.users(id);

-- ============================================================
-- 1. Écritures directes du client
-- ============================================================
-- Transactions : création par le patient à l'état « en attente » ou « en
-- cours » seulement ; aucune modification directe.
drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and status in ('pending', 'processing')
    and completed_at is null and refunded_at is null
    and confirmed_by is null and refunded_by is null
    and external_reference is null
    and amount > 0 and final_amount >= 0
  );
drop policy if exists "transactions_update_own" on public.transactions;
drop policy if exists "transactions_staff_update" on public.transactions;

-- Portefeuille : création à zéro, aucune modification directe.
drop policy if exists "wallets_insert_own" on public.wallets;
create policy "wallets_insert_own" on public.wallets
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and coalesce(balance, 0) = 0 and coalesce(pending_balance, 0) = 0
    and coalesce(total_earned, 0) = 0 and coalesce(total_spent, 0) = 0
    and coalesce(cashback_available, 0) = 0
  );
drop policy if exists "wallets_update_own" on public.wallets;

-- Échéancier : création par le patient (actif, échéances à payer) ; aucune
-- modification directe.
drop policy if exists "installments_insert_own" on public.installments;
create policy "installments_insert_own" on public.installments
  for insert to authenticated
  with check (
    status = 'active' and completed_at is null
    and exists (select 1 from public.transactions t
                 where t.id = installments.transaction_id
                   and t.user_id = auth.uid()
                   and t.method = 'installment'
                   and t.status in ('pending', 'processing'))
  );
drop policy if exists "installments_update_own" on public.installments;

drop policy if exists "installment_payments_insert_own" on public.installment_payments;
create policy "installment_payments_insert_own" on public.installment_payments
  for insert to authenticated
  with check (
    status = 'pending' and paid_at is null
    and exists (select 1 from public.installments i
                  join public.transactions t on t.id = i.transaction_id
                 where i.id = installment_payments.installment_id
                   and t.user_id = auth.uid()
                   and i.status = 'active')
  );
drop policy if exists "installment_payments_update_own" on public.installment_payments;

-- L'officine voit les échéanciers des transactions qu'elle encaisse.
drop policy if exists "installments_staff_select" on public.installments;
create policy "installments_staff_select" on public.installments
  for select to authenticated
  using (exists (select 1 from public.transactions t
                  where t.id = installments.transaction_id
                    and t.pharmacy_id is not null and public.is_pharmacy_staff(t.pharmacy_id)));
drop policy if exists "installment_payments_staff_select" on public.installment_payments;
create policy "installment_payments_staff_select" on public.installment_payments
  for select to authenticated
  using (exists (select 1 from public.installments i
                   join public.transactions t on t.id = i.transaction_id
                  where i.id = installment_payments.installment_id
                    and t.pharmacy_id is not null and public.is_pharmacy_staff(t.pharmacy_id)));

-- Factures : produites par le serveur à la confirmation.
drop policy if exists "invoices_insert_own" on public.invoices;
drop policy if exists "invoice_items_insert_own" on public.invoice_items;

-- ============================================================
-- 2. Règlement d'une transaction confirmée (interne)
-- ============================================================
create or replace function public.payment_settle_completed(p_tx public.transactions)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_wallet  public.wallets%rowtype;
  v_number  integer;
  v_invoice uuid;
  v_ph      public.pharmacies%rowtype;
  v_prof    public.profiles%rowtype;
begin
  -- Portefeuille : débit (paiement par portefeuille), cashback utilisé,
  -- total dépensé.
  if p_tx.user_id is not null then
    select * into v_wallet from public.wallets where user_id = p_tx.user_id for update;
    if not found then
      insert into public.wallets (user_id) values (p_tx.user_id) returning * into v_wallet;
    end if;
    if p_tx.method = 'gsgWallet' and v_wallet.balance < p_tx.final_amount then
      raise exception 'PAIEMENT: solde du portefeuille insuffisant' using errcode = '22023';
    end if;
    update public.wallets
       set balance = balance - case when p_tx.method = 'gsgWallet' then p_tx.final_amount else 0 end,
           cashback_available = greatest(0, cashback_available - coalesce(p_tx.cashback, 0)),
           total_spent = total_spent + p_tx.final_amount,
           last_updated = now()
     where id = v_wallet.id;
  end if;

  -- Facture « payée », numérotée sans doublon (même méthode que C202).
  if not exists (select 1 from public.invoices where transaction_id = p_tx.id) then
    perform pg_advisory_xact_lock(hashtext('invoices.invoice_number'));
    select coalesce(max(substring(invoice_number from '^FAC([0-9]+)$')::integer), 0) + 1
      into v_number from public.invoices;
    select * into v_ph from public.pharmacies where id = p_tx.pharmacy_id;
    select * into v_prof from public.profiles where id = p_tx.user_id;
    insert into public.invoices (transaction_id, invoice_number, pharmacy_name, pharmacy_address,
                                 pharmacy_phone, patient_name, patient_phone, issued_at,
                                 subtotal, tax, discount, total, status)
    values (p_tx.id, 'FAC' || lpad(v_number::text, 6, '0'),
            coalesce(v_ph.name, p_tx.pharmacy_name, 'GSG'), coalesce(v_ph.address, ''), coalesce(v_ph.phone, ''),
            coalesce(v_prof.full_name, 'Patient'), coalesce(p_tx.user_phone, ''), now(),
            p_tx.amount, coalesce(p_tx.fee, 0), coalesce(p_tx.cashback, 0), p_tx.final_amount, 'paid')
    returning id into v_invoice;
    insert into public.invoice_items (invoice_id, product_name, quantity, unit_price, total)
    values (v_invoice, 'Règlement de la commande', 1, p_tx.amount, p_tx.amount);
  end if;
end;
$$;

revoke all on function public.payment_settle_completed(public.transactions) from public, anon, authenticated;

-- Contrôle commun : l'appelant encaisse pour l'officine de la transaction.
create or replace function public.payment_can_collect(p_tx public.transactions)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_gsg_admin()
      or (p_tx.pharmacy_id is not null and public.is_pharmacy_staff(p_tx.pharmacy_id));
$$;

revoke all on function public.payment_can_collect(public.transactions) from public, anon, authenticated;

-- ============================================================
-- 3. Confirmation par l'officine
-- ============================================================
create or replace function public.payment_confirm_transaction(p_transaction_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
begin
  if auth.uid() is null then
    raise exception 'PAIEMENT: connexion requise' using errcode = '42501';
  end if;
  select * into v_tx from public.transactions where id = p_transaction_id for update;
  if not found or not public.payment_can_collect(v_tx) then
    raise exception 'PAIEMENT: seule l''officine qui encaisse (ou GSG) confirme un paiement' using errcode = '42501';
  end if;
  if v_tx.status not in ('pending', 'processing') then
    raise exception 'PAIEMENT: transaction deja %', v_tx.status using errcode = '22023';
  end if;
  if v_tx.method = 'installment' then
    raise exception 'PAIEMENT: un paiement en plusieurs fois se confirme echeance par echeance' using errcode = '22023';
  end if;

  update public.transactions
     set status = 'completed', completed_at = now(), confirmed_by = auth.uid()
   where id = v_tx.id
   returning * into v_tx;
  perform public.payment_settle_completed(v_tx);

  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (auth.uid(), coalesce((select full_name from public.profiles where id = auth.uid()), 'Officine'),
          'payment_confirmed', 'transaction', v_tx.id::text,
          jsonb_build_object('method', v_tx.method, 'amount', v_tx.final_amount, 'pharmacy_id', v_tx.pharmacy_id),
          'RPC C225');
end;
$$;

comment on function public.payment_confirm_transaction(uuid) is
  'C225 / D67 : l''officine de la transaction (ou GSG) confirme l''encaissement constaté (espèces ou compte marchand). Règlement du portefeuille, facture et journal d''audit.';
revoke all on function public.payment_confirm_transaction(uuid) from public, anon;
grant execute on function public.payment_confirm_transaction(uuid) to authenticated;

-- ============================================================
-- 4. Échéance payée (paiement en plusieurs fois)
-- ============================================================
create or replace function public.payment_confirm_installment(p_transaction_id uuid, p_payment_number integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
  v_inst public.installments%rowtype;
  v_pay public.installment_payments%rowtype;
begin
  if auth.uid() is null then
    raise exception 'PAIEMENT: connexion requise' using errcode = '42501';
  end if;
  select * into v_tx from public.transactions where id = p_transaction_id for update;
  if not found or not public.payment_can_collect(v_tx) then
    raise exception 'PAIEMENT: seule l''officine qui encaisse (ou GSG) confirme un paiement' using errcode = '42501';
  end if;
  select * into v_inst from public.installments where transaction_id = v_tx.id for update;
  if not found or v_inst.status <> 'active' then
    raise exception 'PAIEMENT: aucun echeancier actif pour cette transaction' using errcode = '22023';
  end if;
  select * into v_pay from public.installment_payments
   where installment_id = v_inst.id and payment_number = p_payment_number for update;
  if not found then
    raise exception 'PAIEMENT: echeance % introuvable', p_payment_number using errcode = '22023';
  end if;
  if v_pay.status = 'paid' then
    raise exception 'PAIEMENT: echeance % deja payee', p_payment_number using errcode = '22023';
  end if;

  update public.installment_payments set status = 'paid', paid_at = now() where id = v_pay.id;

  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (auth.uid(), coalesce((select full_name from public.profiles where id = auth.uid()), 'Officine'),
          'installment_paid', 'transaction', v_tx.id::text,
          jsonb_build_object('payment_number', p_payment_number, 'amount', v_pay.amount), 'RPC C225');

  -- Dernière échéance : échéancier soldé, transaction confirmée.
  if not exists (select 1 from public.installment_payments
                  where installment_id = v_inst.id and status <> 'paid') then
    update public.installments set status = 'completed', completed_at = now() where id = v_inst.id;
    update public.transactions
       set status = 'completed', completed_at = now(), confirmed_by = auth.uid()
     where id = v_tx.id
     returning * into v_tx;
    perform public.payment_settle_completed(v_tx);
  elsif v_tx.status = 'pending' then
    update public.transactions set status = 'processing' where id = v_tx.id;
  end if;
end;
$$;

comment on function public.payment_confirm_installment(uuid, integer) is
  'C225 / D67 : l''officine (ou GSG) confirme une échéance payée ; à la dernière, échéancier soldé et transaction confirmée (règlement, facture).';
revoke all on function public.payment_confirm_installment(uuid, integer) from public, anon;
grant execute on function public.payment_confirm_installment(uuid, integer) to authenticated;

-- ============================================================
-- 5. Remboursement par l'officine
-- ============================================================
create or replace function public.payment_refund_transaction(p_transaction_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if auth.uid() is null then
    raise exception 'PAIEMENT: connexion requise' using errcode = '42501';
  end if;
  select * into v_tx from public.transactions where id = p_transaction_id for update;
  if not found or not public.payment_can_collect(v_tx) then
    raise exception 'PAIEMENT: seule l''officine qui encaisse (ou GSG) rembourse un paiement' using errcode = '42501';
  end if;
  if v_tx.status not in ('completed', 'disputed') or v_tx.completed_at is null then
    raise exception 'PAIEMENT: seule une transaction payee peut etre remboursee' using errcode = '22023';
  end if;
  if v_reason is null or length(v_reason) < 5 then
    raise exception 'PAIEMENT: motif du remboursement obligatoire' using errcode = '22023';
  end if;

  update public.transactions
     set status = 'refunded', refunded_at = now(), refunded_by = auth.uid(),
         notes = concat_ws(' | ', notes, 'Remboursement : ' || v_reason)
   where id = v_tx.id;

  -- Portefeuille : remboursement d'un paiement par portefeuille, cashback
  -- utilisé rendu, total dépensé corrigé.
  if v_tx.user_id is not null then
    update public.wallets
       set balance = balance + case when v_tx.method = 'gsgWallet' then v_tx.final_amount else 0 end,
           cashback_available = cashback_available + coalesce(v_tx.cashback, 0),
           total_spent = greatest(0, total_spent - v_tx.final_amount),
           last_updated = now()
     where user_id = v_tx.user_id;
  end if;
  update public.invoices set status = 'refunded' where transaction_id = v_tx.id;

  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (auth.uid(), coalesce((select full_name from public.profiles where id = auth.uid()), 'Officine'),
          'payment_refunded', 'transaction', v_tx.id::text,
          jsonb_build_object('method', v_tx.method, 'amount', v_tx.final_amount, 'reason', v_reason), 'RPC C225');
end;
$$;

comment on function public.payment_refund_transaction(uuid, text) is
  'C225 / D67 : remboursement d''une transaction payée (ou contestée) par l''officine ou GSG, avec motif ; portefeuille recrédité si payé par portefeuille ; journal d''audit.';
revoke all on function public.payment_refund_transaction(uuid, text) from public, anon;
grant execute on function public.payment_refund_transaction(uuid, text) to authenticated;

-- ============================================================
-- 6. Patient : abandon et contestation
-- ============================================================
create or replace function public.payment_cancel_transaction(p_transaction_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
begin
  select * into v_tx from public.transactions where id = p_transaction_id for update;
  if auth.uid() is null or not found or v_tx.user_id <> auth.uid() then
    raise exception 'PAIEMENT: transaction introuvable' using errcode = '42501';
  end if;
  if v_tx.status not in ('pending', 'processing')
     or exists (select 1 from public.installments i
                  join public.installment_payments p on p.installment_id = i.id
                 where i.transaction_id = v_tx.id and p.status = 'paid') then
    raise exception 'PAIEMENT: cette transaction ne peut plus etre abandonnee' using errcode = '22023';
  end if;
  update public.transactions set status = 'failed' where id = v_tx.id;
  update public.installments set status = 'cancelled' where transaction_id = v_tx.id and status = 'active';
end;
$$;

comment on function public.payment_cancel_transaction(uuid) is
  'C225 : le patient abandonne une transaction non encore payée (aucune échéance réglée).';
revoke all on function public.payment_cancel_transaction(uuid) from public, anon;
grant execute on function public.payment_cancel_transaction(uuid) to authenticated;

create or replace function public.payment_dispute_transaction(p_transaction_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  select * into v_tx from public.transactions where id = p_transaction_id for update;
  if auth.uid() is null or not found or v_tx.user_id <> auth.uid() then
    raise exception 'PAIEMENT: transaction introuvable' using errcode = '42501';
  end if;
  if v_tx.status not in ('completed', 'processing') then
    raise exception 'PAIEMENT: seule une transaction payee ou en cours peut etre contestee' using errcode = '22023';
  end if;
  if v_reason is null or length(v_reason) < 5 then
    raise exception 'PAIEMENT: motif de la contestation obligatoire' using errcode = '22023';
  end if;
  update public.transactions
     set status = 'disputed', notes = concat_ws(' | ', notes, 'Contestation : ' || v_reason)
   where id = v_tx.id;
  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (auth.uid(), coalesce((select full_name from public.profiles where id = auth.uid()), 'Patient'),
          'payment_disputed', 'transaction', v_tx.id::text, jsonb_build_object('reason', v_reason), 'RPC C225');
end;
$$;

comment on function public.payment_dispute_transaction(uuid, text) is
  'C225 : le patient conteste une transaction payée ou en cours, avec motif (journalisé).';
revoke all on function public.payment_dispute_transaction(uuid, text) from public, anon;
grant execute on function public.payment_dispute_transaction(uuid, text) to authenticated;
