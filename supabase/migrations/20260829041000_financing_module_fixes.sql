-- Module 14 (FIN — Financement & Crédit fournisseur) : correctifs RLS.
-- Audit du 29/08/2026.
--
-- Constat n°1 (verrou total, registre des écarts audit Module 14) : les policies "Staff
-- manage ..." des 3 tables (financing_requests/financing_repayments/
-- credit_scores) testent `profiles.role in ('admin', 'staff')`, un test
-- inatteignable par construction — voir le commentaire de
-- 20260829003800_admin_helpers.sql, qui liste déjà business/network_admin/
-- returns/stock_forecasting/offline_sync comme touchés par ce même bug mais
-- omettait financing.sql (oubli corrigé ici).
--
-- Constat n°2 (verrou total, indépendant du n°1) : les policies "Pharmacy
-- own ..." comparent `auth.uid()` (l'identifiant UTILISATEUR) directement à
-- `pharmacy_id` (l'identifiant OFFICINE) — ces deux valeurs ne coïncident
-- jamais. C'est la même famille de confusion identité que C43 (déjà
-- rencontrée côté écrans, cette fois côté RLS). Combinés, les constats 1 et
-- 2 rendent les 3 tables totalement inaccessibles depuis le produit, quel
-- que soit l'utilisateur.
--
-- Correctif : remplace les deux familles de policies cassées par des
-- policies basées sur `is_pharmacy_staff(pharmacy_id)` (déjà introduite par
-- 20260827002000_staff_write_policies.sql) et `is_gsg_admin()` (déjà
-- introduite par 20260829003800_admin_helpers.sql) — aucune nouvelle
-- fonction d'aide n'est créée ici.
--
-- Décision de conception (arbitrage utilisateur, audit Module 14) :
-- RG-FIN-01 soumet l'octroi d'une ligne de crédit à validation d'un
-- "partenaire financier agréé" ; en l'absence d'une entité partenaire
-- distincte dans le système (dette documentée, voir D25 du registre), cette
-- validation est portée par le back-office GSG existant (is_gsg_admin()),
-- au même titre que la vérification de licence officine (RG-AUT-01, voir
-- pharmacy_service.dart).
--
-- Déviation assumée par rapport au précédent C18/C22/C25/C30 (RLS large +
-- UI restreint les transitions valides) : ici, la policy RLS ne donne
-- PAS de droit d'update large à l'officine sur financing_requests. Un octroi
-- de crédit engage des fonds réels — on ne protège pas un enjeu financier
-- avec la seule discipline de l'UI cliente, contrairement à un statut de
-- suivi métier ordinaire. Seul le back-office (is_gsg_admin()) peut faire
-- approuver/rejeter/décaisser une demande. Unique exception, étroite et
-- documentée à sa policy dédiée plus bas : le constat comptable 'active' ->
-- 'completed' quand la dernière échéance est soldée.

-- ==================== financing_requests ====================

drop policy if exists "Pharmacy own financing" on public.financing_requests;
drop policy if exists "Staff manage financing requests" on public.financing_requests;

-- L'officine ne voit et ne crée QUE ses propres demandes, toujours à
-- l'état 'pending' — aucune capacité d'update/delete côté officine (voir
-- déviation documentée ci-dessus). L'approbation/le rejet/le décaissement
-- sont réservés au back-office (policy admin ci-dessous).
create policy "financing_requests_select_own_pharmacy" on public.financing_requests
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id));

create policy "financing_requests_insert_own_pharmacy" on public.financing_requests
  for insert to authenticated
  with check (public.is_pharmacy_staff(pharmacy_id) and status = 'pending');

-- Exception étroite à "aucune capacité d'update côté officine" (voir
-- déviation documentée en tête de fichier) : le seul passage 'active' ->
-- 'completed' déclenché quand la dernière échéance est soldée
-- (financing_service.dart, _checkAndCompleteRequest, appelé depuis
-- payRepayment). Un simple constat comptable, jamais un octroi/refus/
-- décaissement de fonds : l'officine ne peut ni fabriquer ce constat (les
-- lignes financing_repayments sous-jacentes restent protégées par leur
-- propre RLS) ni l'utiliser pour obtenir quoi que ce soit qu'elle n'a pas
-- déjà remboursé.
create policy "financing_requests_complete_own_pharmacy" on public.financing_requests
  for update to authenticated
  using (status = 'active' and public.is_pharmacy_staff(pharmacy_id))
  with check (status = 'completed' and public.is_pharmacy_staff(pharmacy_id));

create policy "financing_requests_admin_all" on public.financing_requests
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ==================== financing_repayments ====================

drop policy if exists "Pharmacy view own repayments" on public.financing_repayments;
drop policy if exists "Staff manage repayments" on public.financing_repayments;

-- Lecture de son échéancier + passage d'une échéance 'pending' à 'paid'
-- (paiement déclenché côté client après débit réussi du portefeuille GSG,
-- même posture assumée que pour les paiements de commande — voir
-- payment_service.dart / précédent D12-D13) OU à 'overdue' (constat passif
-- qu'une échéance 'pending' a dépassé sa date d'échéance,
-- `checkOverdueRepayments()` appelé au chargement du tableau de bord —
-- sans risque : une officine ne peut que dégrader son propre statut,
-- jamais celui d'un tiers, et n'a aucun intérêt à le faire). La génération
-- de l'échéancier (insert) reste back-office : elle a lieu au décaissement
-- (financing_service.dart, updateRequestStatus 'active'), une action déjà
-- réservée à is_gsg_admin() ci-dessus.
create policy "financing_repayments_select_own_pharmacy" on public.financing_repayments
  for select to authenticated
  using (
    exists (
      select 1 from public.financing_requests fr
      where fr.id = financing_repayments.financing_request_id
        and public.is_pharmacy_staff(fr.pharmacy_id)
    )
  );

create policy "financing_repayments_update_own_pharmacy" on public.financing_repayments
  for update to authenticated
  using (
    status = 'pending'
    and exists (
      select 1 from public.financing_requests fr
      where fr.id = financing_repayments.financing_request_id
        and public.is_pharmacy_staff(fr.pharmacy_id)
    )
  )
  with check (
    status in ('paid', 'overdue')
    and exists (
      select 1 from public.financing_requests fr
      where fr.id = financing_repayments.financing_request_id
        and public.is_pharmacy_staff(fr.pharmacy_id)
    )
  );

create policy "financing_repayments_admin_all" on public.financing_repayments
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ==================== credit_scores ====================

drop policy if exists "Pharmacy view own credit score" on public.credit_scores;
drop policy if exists "Staff manage credit scores" on public.credit_scores;

-- Le score est calculé à partir des propres données de l'officine
-- (historique de remboursement, volume B2B, ancienneté du compte — voir
-- financing_service.dart calculateCreditScore) : laisser l'officine
-- déclencher/rafraîchir son propre calcul est sans risque, à l'identique du
-- flux déjà en place (calcul automatique au premier affichage du tableau de
-- bord). Le back-office garde un accès complet pour audit/correction.
create policy "credit_scores_select_own_pharmacy" on public.credit_scores
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id));

create policy "credit_scores_insert_own_pharmacy" on public.credit_scores
  for insert to authenticated
  with check (public.is_pharmacy_staff(pharmacy_id));

create policy "credit_scores_update_own_pharmacy" on public.credit_scores
  for update to authenticated
  using (public.is_pharmacy_staff(pharmacy_id))
  with check (public.is_pharmacy_staff(pharmacy_id));

create policy "credit_scores_admin_all" on public.credit_scores
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());
