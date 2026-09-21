-- Audit Module 8 (PAY, 29/08/2026) : correctifs sur 20260827001300_payments.sql.
--
-- 1) Comme pour AUT/REC/CAT/STK/ORD/RES/LIV (7e occurrence du même écart),
--    la migration d'origine n'ouvrait que des policies SELECT sur
--    transactions / installments / installment_payments / wallets /
--    invoices / invoice_items. Faute de policy insert/update, RLS bloque
--    par défaut TOUTE écriture (deny-by-default) : initiation de paiement,
--    recharge de portefeuille, paiement d'échéance, facturation — rien de
--    tout cela n'aurait jamais pu être écrit en base.
--
-- 2) Bug SQL : le trigger générique "set_updated_at" (qui fait
--    NEW.updated_at = now()) était posé sur public.wallets, qui n'a PAS de
--    colonne updated_at — seulement last_updated (voir wallet.dart,
--    fromJson/toJson : uniquement last_updated). Toute UPDATE sur wallets
--    aurait levé une erreur Postgres ("record "new" has no field
--    "updated_at""). Le service met déjà last_updated à jour manuellement
--    sur chaque écriture (payment_service.dart) : on supprime simplement
--    ce trigger plutôt que d'en réécrire un qui ferait doublon.

drop trigger if exists set_updated_at on public.wallets;

-- ---------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------

create policy "transactions_insert_own" on public.transactions
  for insert to authenticated
  with check (auth.uid() = user_id);

-- Le patient peut mettre à jour sa propre transaction (ex. passage en
-- litige via dispute_screen.dart / markAsDisputed). Les colonnes
-- monétaires (amount, final_amount, fee, cashback, method) restent sous
-- la responsabilité de payment_service.dart côté écriture applicative ;
-- RLS ne fait pas de contrôle colonne par colonne ici, comme pour les
-- autres policies "update_own" déjà en place dans les modules précédents
-- (ex. reservations_update_own).
create policy "transactions_update_own" on public.transactions
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Le personnel de la pharmacie voit les transactions de sa pharmacie
-- (back-office de réconciliation, reconciliation_screen.dart).
create policy "transactions_staff_select" on public.transactions
  for select to authenticated
  using (
    pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id)
  );

-- Le personnel de la pharmacie peut faire évoluer le statut (ex.
-- rapprochement manuel d'une transaction cash à la livraison).
create policy "transactions_staff_update" on public.transactions
  for update to authenticated
  using (
    pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id)
  )
  with check (
    pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id)
  );

create policy "transactions_gsg_admin_all" on public.transactions
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ---------------------------------------------------------------------
-- installments / installment_payments
-- ---------------------------------------------------------------------

create policy "installments_insert_own" on public.installments
  for insert to authenticated
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = installments.transaction_id and t.user_id = auth.uid()
    )
  );

create policy "installments_update_own" on public.installments
  for update to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = installments.transaction_id and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = installments.transaction_id and t.user_id = auth.uid()
    )
  );

create policy "installment_payments_insert_own" on public.installment_payments
  for insert to authenticated
  with check (
    exists (
      select 1 from public.installments i
      join public.transactions t on t.id = i.transaction_id
      where i.id = installment_payments.installment_id and t.user_id = auth.uid()
    )
  );

create policy "installment_payments_update_own" on public.installment_payments
  for update to authenticated
  using (
    exists (
      select 1 from public.installments i
      join public.transactions t on t.id = i.transaction_id
      where i.id = installment_payments.installment_id and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.installments i
      join public.transactions t on t.id = i.transaction_id
      where i.id = installment_payments.installment_id and t.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- wallets
-- ---------------------------------------------------------------------

-- Auto-provisionnement (getOrCreateWallet) : l'utilisateur peut créer son
-- propre portefeuille au premier accès.
create policy "wallets_insert_own" on public.wallets
  for insert to authenticated
  with check (auth.uid() = user_id);

-- Recharge, débit (paiement par portefeuille), crédit de cashback.
create policy "wallets_update_own" on public.wallets
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- invoices / invoice_items
-- ---------------------------------------------------------------------

create policy "invoices_insert_own" on public.invoices
  for insert to authenticated
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = invoices.transaction_id and t.user_id = auth.uid()
    )
  );

create policy "invoices_staff_select" on public.invoices
  for select to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = invoices.transaction_id
        and t.pharmacy_id is not null
        and public.is_pharmacy_staff(t.pharmacy_id)
    )
  );

create policy "invoice_items_insert_own" on public.invoice_items
  for insert to authenticated
  with check (
    exists (
      select 1 from public.invoices inv
      join public.transactions t on t.id = inv.transaction_id
      where inv.id = invoice_items.invoice_id and t.user_id = auth.uid()
    )
  );
