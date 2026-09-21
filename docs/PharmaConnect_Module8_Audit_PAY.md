# PharmaConnect — Rapport d'audit Module 8 : PAY (Paiement, Mobile Money & Portefeuille)

**Date :** 29/08/2026
**Rôle :** Superviseur & Architecte Logiciel Senior
**Méthodologie appliquée :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables (Règle d'or, module par module, validation utilisateur requise avant le suivant).

---

## 1. Inspection & rapport de situation

Périmètre inspecté : 6 modèles (`transaction.dart`, `installment.dart`, `invoice.dart`, `payment_method.dart`, `transaction_status.dart`, `wallet.dart`), 1 service (`payment_service.dart`, 398 → ~500 lignes après correctifs), 1 provider (`payment_provider.dart`), 6 écrans (`payment_screen.dart`, `wallet_screen.dart`, `transaction_history_screen.dart`, `transaction_detail_screen.dart`, `dispute_screen.dart`, `installment_plan_screen.dart`, `reconciliation_screen.dart`), 3 widgets (`payment_method_selector.dart`, `transaction_list_tile.dart`, `wallet_balance_card.dart`), et la migration `20260827001300_payments.sql` (6 tables : `transactions`, `installments`, `installment_payments`, `wallets`, `invoices`, `invoice_items`). Deux points d'intégration transverses ont également été vérifiés : l'enregistrement du module dans `app.dart`/`app_router.dart`, et le point d'entrée réel du parcours d'achat, `reservation_checkout_screen.dart` (Module 6/7).

Constat le plus significatif de cet audit, plus sévère que toute occurrence précédente de la dette « code orphelin » (voir D6 du registre) : **le module PAY était entièrement construit, correctement testé au niveau du code, enregistré dans les routes et le `MultiProvider` — mais totalement déconnecté du seul vrai parcours d'achat de l'application.** `reservation_checkout_screen.dart` ne faisait que stocker un libellé de méthode de paiement en texte libre sur la table `reservations` elle-même, sans jamais appeler `PaymentService.initiateTransaction`/`PaymentProvider.initiatePayment`. Aucune transaction, aucun portefeuille, aucune facture n'a donc jamais été créé par un vrai utilisateur de l'application, malgré un module fonctionnellement complet.

Second constat majeur : comme pour les 7 modules précédents, la migration de base ne posait que des policies RLS `select`, laissant toute écriture bloquée par le refus par défaut de RLS — 8e occurrence consécutive du même défaut de fondation.

Un bug SQL spécifique à ce module a également été trouvé : un trigger générique `set_updated_at` posé sur `wallets`, table qui n'a pas de colonne `updated_at` (seulement `last_updated`) — toute mise à jour aurait levé une erreur Postgres.

## 2. Analyse comparative (cahier de conception)

| Règle | Exigence | Constat avant correctif | Statut après correctif |
|---|---|---|---|
| RG-PAY-01 (Critique) | Aucune commande n'est marquée "payée" sans confirmation serveur vérifiée de l'agrégateur | Simulation client (`Future.delayed(2s)`) auto-confirmée, sans vérification serveur | 🟡 Non résolu — limitation structurelle de l'architecture 100% Flutter+Supabase (pas de backend séparé pour recevoir les webhooks). Documentée en D12 du registre, pas masquée |
| RG-PAY-02 (Standard) | Frais de service affichés de manière transparente avant validation | Cashback affiché, frais (1%) jamais montrés nulle part | 🟢 Résolu — ligne "Frais de service (1%)" ajoutée dans le résumé de commande, `payment_screen.dart` |
| Mobile Money / portefeuille / échéancier (cahier, fonctionnalités clés) | Paiement réel intégré au parcours d'achat | Aucun lien entre le checkout et PAY (voir B16, désormais résolu) | 🟢 Résolu — checkout câblé à `PaymentProvider.initiatePayment` |
| Cashback (cahier) | Mécanique de fidélité cohérente (gagné puis dépensable) | Dépensable sans jamais avoir été gagné, jamais crédité après un paiement | 🟢 Résolu — `_settleWallet` plafonne la dépense au solde réel et crédite le cashback gagné |
| Paiement en plusieurs fois (cahier) | Échéancier fonctionnel | `createInstallment` jamais appelée ; `getInstallment` cherchait par le mauvais identifiant | 🟢 Résolu |
| KER-REF-05 | Tout montant en unité mineure entière, jamais en flottant | Déjà respecté (tous les champs monétaires sont `int`/`integer`) | 🟢 Conforme, aucun correctif nécessaire |

## 3. Sécurité & résilience

**RLS (écriture) — 8e occurrence du défaut de fondation.** Nouvelle migration `20260829019000_payments_module_fixes.sql` : policies d'insertion/mise à jour pour `transactions` (own + staff scopé par `is_pharmacy_staff(pharmacy_id)` + `is_gsg_admin()`), `installments`/`installment_payments` (via la chaîne de propriété jusqu'à `transactions.user_id`), `wallets` (insert/update own, pour l'auto-provisionnement et les mouvements), `invoices`/`invoice_items` (insert via la chaîne de propriété, select staff).

**Trigger SQL cassé.** `set_updated_at` sur `wallets` (colonne `updated_at` inexistante) — supprimé (`drop trigger if exists`) plutôt que réécrit, le service maintenant déjà `last_updated` manuellement à chaque écriture.

**Solde du portefeuille jamais vérifié ni débité.** `PaymentMethod.gsgWallet` permettait de "payer" un montant illimité avec un solde à zéro — corrigé : vérification `wallet.balance >= finalAmount` avant d'accepter le paiement (sinon exception explicite), et débit réel dans `_settleWallet`.

**Cashback : ledger incohérent dans les deux sens.** Le cashback "à dépenser" était recalculé à 2% du montant sans jamais être comparé au solde réel (`cashbackAvailable`) — un utilisateur pouvait dépenser un cashback jamais gagné. Le cashback gagné (mobile money / portefeuille) n'était de son côté jamais crédité. Corrigé : la dépense est plafonnée au solde réel, le crédit est appliqué après complétion de la transaction.

**Identité patient codée en dur — 5 occurrences dans ce seul module** (`payment_screen.dart` : `'patient_123'`/`'+224612345678'` ; `wallet_screen.dart` : `'patient_123'` ×3 + `'Jean Dupont'` ; `transaction_history_screen.dart` : `'patient_123'`). 7e occurrence cumulée de ce défaut récurrent depuis le Module 4. Toutes remplacées par `AuthProvider.userId`/`userPhone`, avec garde-fou ("Vous devez être connecté") quand l'identité est absente.

**Réconciliation pharmacie sans contrôle d'accès ni portée correcte.** `reconciliation_screen.dart` n'avait aucun rôle requis et appelait `loadTransactions()` sans filtre — un pharmacien n'aurait vu, au mieux, que ses propres transactions patient (jamais celles de son officine), via `transactions_select_own`. Corrigé : garde `UserRole.pharmacien` (même patron que Modules 6/7) + `loadTransactions(pharmacyId: ...)`, combiné à la nouvelle policy `transactions_staff_select`.

**Perte de données silencieuse.** `dispute_screen.dart` validait `_descriptionController` comme obligatoire mais ne l'envoyait jamais à `markAsDisputed` — seul `reason` était transmis. Corrigé par concaténation des deux champs.

**Auto-provisionnement du portefeuille manquant.** Aucune ligne `wallets` n'est jamais créée à l'inscription (confirmé par recherche exhaustive dans les migrations) ; `getWallet` utilisait `.single()`, qui lève une exception sur zéro ligne — le premier appel réel pour tout utilisateur aurait donc toujours échoué. Corrigé par `getOrCreateWallet`, utilisé partout où le module lit ou écrit un portefeuille.

**Échéancier de paiement non fonctionnel de bout en bout.** `createInstallment` n'avait aucun appelant ; `getInstallment(installmentId)` cherchait par l'id propre de l'échéancier alors que l'écran ne transmet que l'id de la **transaction** — "Aucun échéancier trouvé" systématique. Corrigé : `getInstallmentByTransaction`/`payInstallmentByTransaction` résolvent par `transaction_id`, `PaymentProvider.initiatePayment` crée l'échéancier après l'initiation, et le paiement de la dernière échéance complète la transaction parente via `confirmTransaction` (génère aussi la facture, jusqu'ici jamais produite pour ce mode de paiement).

**Widget de portefeuille avec des chiffres fictifs codés en dur.** `wallet_balance_card.dart` affichait `3400` ("Cashback") et `12000` ("En attente") en constantes, sans aucun lien avec `Wallet.cashbackAvailable`/`Wallet.pendingBalance`. Corrigé : paramètres réels ajoutés au widget, transmis depuis `wallet_screen.dart`.

## 4. Optimisation & améliorations

- **Point d'entrée réel du paiement** : `reservation_checkout_screen.dart` appelle désormais `PaymentProvider.initiatePayment` après création de la réservation (libellé UI traduit vers `PaymentMethod` via un nouveau `_mapPaymentMethod`), de façon non bloquante pour la confirmation de commande en cas d'échec — même logique que la programmation de livraison (Module 7) : la réservation reste valable, le patient est informé et peut réessayer.
- **Transparence des frais (RG-PAY-02)** : ligne "Frais de service (1%)" ajoutée au résumé de commande.
- **Sélecteur du nombre d'échéances** : "Paiement en plusieurs fois" propose désormais un choix 3/6/12 fois (`_numberOfPayments`), jusqu'ici jamais exposé côté UI bien que `PaymentService.createInstallment` l'acceptait depuis le départ.
- **Mode hors-ligne (directive standing), lecture seule** : nouveau cache `cache_transactions`/`cache_wallet` dans `OfflineSyncService` (bump v6→v7), avec repli automatique sur `loadTransactions`/`loadWallet` — même patron que les modules précédents. **Délibérément non étendu aux écritures** (initiation de paiement, recharge, paiement d'échéance) : rejouer une initiation de paiement après une coupure réseau risquerait un double débit ou une double confirmation, un risque qualitativement plus grave qu'un ajustement de stock ou une réservation rejoués en double. Décision documentée en D13 du registre plutôt que traitée en silence.
- **Bannière hors-ligne** ajoutée à `wallet_screen.dart`, cohérente avec les autres écrans du projet.

## 5. Documentation API (services touchés)

`PaymentService` (`lib/modules/payments/services/payment_service.dart`) :
- `getOrCreateWallet(userId)` — **nouveau**. Retourne le portefeuille existant ou en crée un à zéro. Remplace `getWallet` dans tous les appels internes du service et du provider.
- `initiateTransaction({userId, userPhone, amount, method, ...})` — cashback à dépenser désormais plafonné par `wallet.cashbackAvailable` ; vérifie et refuse (exception) un paiement `gsgWallet` si le solde est insuffisant ; ne simule plus de confirmation immédiate pour `PaymentMethod.installment` (reste `processing` jusqu'au dernier versement) ; appelle `_settleWallet` après complétion pour les autres méthodes.
- `_settleWallet({userId, method, finalAmount, redeemedCashback, earnedCashback})` — **nouveau**, privé. Débite le portefeuille (si `gsgWallet`), ajuste `cashbackAvailable`/`totalSpent`/`totalEarned`.
- `getInstallmentByTransaction(transactionId)` — **nouveau**, remplace `getInstallment(installmentId)` comme point d'entrée public ; résout par `transaction_id`.
- `payInstallmentByTransaction(transactionId, paymentNumber)` — **nouveau**, remplace `payInstallment(installmentId, paymentNumber)` ; complète la transaction parente (facture incluse) quand la dernière échéance est payée.

`PaymentProvider` (`lib/modules/payments/providers/payment_provider.dart`) :
- `isOffline` — **nouveau** getter.
- `loadTransactions({..., pharmacyId})` — **nouveau paramètre** `pharmacyId` (passage direct à `PaymentService.getTransactions`) ; repli hors-ligne en cache par `userId`.
- `loadWallet(userId)` — repli hors-ligne en cache ; utilise `getOrCreateWallet`.
- `loadInstallment(transactionId)` / `payInstallment(transactionId, paymentNumber)` — **signatures inchangées**, résolution interne corrigée (voir service).
- `initiatePayment({..., numberOfPayments = 3})` — **nouveau paramètre** ; crée l'échéancier en interne si `method == PaymentMethod.installment`.

Migration `20260829019000_payments_module_fixes.sql` : voir le fichier pour le détail complet des 15 nouvelles policies RLS et la suppression du trigger `set_updated_at` sur `wallets`.

## 6. Scénarios de test (à exécuter — non exécutés dans cette session, pas d'accès Flutter SDK/émulateur)

1. Paiement Orange Money sans cashback → transaction `completed`, facture générée, aucun mouvement de portefeuille.
2. Paiement `gsgWallet` avec solde suffisant → débit exact du solde, transaction `completed`.
3. Paiement `gsgWallet` avec solde insuffisant → échec explicite, aucun débit, message d'erreur visible côté UI.
4. Paiement mobile money avec `useCashback=true` et `cashbackAvailable` insuffisant → dépense plafonnée au solde réel, jamais négative.
5. Paiement mobile money complété → `cashbackAvailable` augmente bien du montant gagné (2%) après la transaction.
6. "Paiement en plusieurs fois" (3 échéances) → transaction `processing`, échéancier créé et visible sur `/payments/installment/<id>`, chaque paiement d'échéance progresse le compteur, la dernière échéance complète la transaction parente et génère la facture.
7. Premier accès portefeuille d'un utilisateur jamais provisionné → `getOrCreateWallet` crée une ligne à zéro sans exception.
8. Recharge de portefeuille (`topUpWallet`) → solde augmente, transaction `TOPUP...` créée.
9. Litige (`dispute_screen.dart`) → `reason`+`description` tous deux persistés (vérifier en base que la description n'est plus perdue).
10. Réconciliation : compte patient (non pharmacien) → écran bloqué avec message "Réservé aux pharmaciens" ; compte pharmacien avec officine → ne voit que les transactions de sa propre officine.
11. Checkout complet (Module 6/7/8 bout en bout) : panier → réservation créée → paiement initié et confirmé → livraison programmée (si adresse) → écran de confirmation, avec transaction, portefeuille (le cas échéant) et facture tous cohérents en base.
12. `supabase db push`/reset sur base de test pour valider que les 15 nouvelles policies RLS + la suppression du trigger s'appliquent sans erreur (voir A1 du registre, même limite que les modules précédents — pas d'accès CLI Supabase depuis cette session).

## 7. Livrables de ce module

- Migration `supabase/migrations/20260829019000_payments_module_fixes.sql` (nouvelle).
- `lib/core/services/offline_sync_service.dart` (cache `cache_transactions`/`cache_wallet`, v6→v7).
- `lib/modules/payments/services/payment_service.dart` (correctifs cœur : wallet, cashback, échéancier).
- `lib/modules/payments/providers/payment_provider.dart` (offline, `numberOfPayments`, résolutions d'échéancier).
- `lib/modules/payments/screens/payment_screen.dart` (identité réelle, frais RG-PAY-02, `pharmacyId`, sélecteur d'échéances).
- `lib/modules/payments/screens/wallet_screen.dart` (identité réelle, chiffres réels, bannière hors-ligne).
- `lib/modules/payments/screens/transaction_history_screen.dart` (identité réelle).
- `lib/modules/payments/screens/dispute_screen.dart` (description non perdue).
- `lib/modules/payments/screens/reconciliation_screen.dart` (garde rôle + portée officine).
- `lib/modules/payments/widgets/wallet_balance_card.dart` (paramètres réels).
- `lib/modules/reservations/screens/reservation_checkout_screen.dart` (point d'entrée réel du paiement).
- Registre des écarts mis à jour : A16 (ajout), B16 (résolu), C30-C33 (ajouts), D12-D14 (ajouts), D6 (6e occurrence documentée).

### Décisions non tranchées à faire remonter au porteur du projet (registre D12-D14)

- **D12** — RG-PAY-01 est structurellement irréalisable avec l'architecture actuelle (pas de backend séparé pour recevoir les webhooks des agrégateurs). Nécessite soit une Edge Function Supabase dédiée, soit une révision assumée du cahier sur ce point.
- **D13** — Le mode hors-ligne de PAY couvre volontairement la lecture seule, jamais l'écriture, contrairement aux autres modules. Décision de sécurité assumée, à confirmer.
- **D14** — Deux points d'entrée de paiement coexistent désormais (checkout direct, et l'écran `/payments` dédié) sans être unifiés. À trancher : fusionner, ou assumer leur coexistence.

---

**Le module PAY est-il totalement clos et validé pour passer au suivant ?**
