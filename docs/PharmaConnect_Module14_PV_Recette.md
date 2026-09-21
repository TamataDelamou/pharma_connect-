# PharmaConnect — PV de recette, Module 14 (FIN — Financement & Crédit fournisseur)

**Date d'émission :** 29/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module14_Protocole_Test_E2E.md`), en priorité les Scénarios 1 (démarrage), 2-4 (RLS) et 8-9 (paiement d'échéance réel), sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 14 (FIN) à l'issue de son inspection, de ses correctifs et de l'arbitrage de périmètre D25, et servir de base à la décision de recette par le porteur du projet.

## 2. Périmètre couvert

Correctif RLS double cause (rôle inatteignable + confusion identité) sur 3 tables/9 policies, avec posture volontairement plus stricte que le précédent C18/C22/C25/C30 pour `financing_requests` (aucun droit d'update côté officine, sauf l'exception étroite du constat comptable de complétion), correctif des routes dupliquées `financing`/`iot` bloquant le démarrage de l'application (`iot` dédoublonné mécaniquement seulement, hors audit complet), correctif d'un embed PostgREST invalide bloquant intégralement le chargement des demandes, migration `userId`→`pharmacyId` sur 5 sites, nouveau champ `AuthProvider.isGsgAdmin` débloquant le circuit Approuver/Rejeter/Décaisser, correctif d'une colonne inexistante qui aurait fait échouer tout paiement d'échéance réel, recalcul du score de crédit sur données réelles (historique de remboursement, volume B2B, ancienneté du compte), câblage réel du paiement d'échéance au portefeuille GSG (débit réel, lien de transaction, gestion du solde insuffisant), génération de l'échéancier déplacée du moment de la demande au moment du décaissement, câblage de la détection passive des retards d'échéance, entrée de navigation « Financement » (14ème occurrence série D6). Hors périmètre, par arbitrage explicite du porteur du projet (D25) : entité partenaire financier agréé (RG-FIN-01), RG-FIN-02 (agrément/pharmacovigilance), ligne de crédit renouvelable, prélèvement automatique sur encaissements futurs. Reste assumé : aucun mode hors-ligne construit ce module, `RequestCreateScreen.b2bOrderId` reste sans appelant (liaison marketplace→financement déconnectée).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 3 modèles, 1 service, 1 provider, 3 écrans corrigés, 1 widget relu, 1 migration de correctifs, plus les points d'intégration transverses (app_router, dashboard_screen, app.dart, auth_provider, payment_provider) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-FIN-01, RG-FIN-02, 4 fonctionnalités clés, 3 écrans principaux — écart de périmètre identifié et arbitré (D25) |
| Vérification syntaxique statique (équilibrage accolades/parenthèses + scan d'octets de contrôle) | ✅ Oui | Script dédié, exécuté après chaque édition, sur l'ensemble des fichiers Dart et SQL modifiés/créés ce module |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Chemins de soumission de demande, approbation/rejet/décaissement, paiement d'échéance (débit réel), calcul de score, retracés intégralement |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas de SDK Flutter/Dart disponible |
| Tests unitaires/`flutter test` | ❌ Non | Même limite |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Pas d'accès appareil/émulateur (limite documentée depuis le Module 1) |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, pas par exécution. Le Scénario 1 du protocole E2E (démarrage) doit être exécuté en priorité absolue : avant correctif, l'application entière ne démarrait pas (routes dupliquées, même défaut que C45 au Module 13). Les Scénarios 2-4 (RLS) viennent immédiatement après, le module étant entièrement inopérant avant correctif, y compris pour le staff légitime et le back-office. Les Scénarios 8-9 (paiement d'échéance réel) vérifient la correction la plus sensible financièrement de ce module.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| RLS, rôle inatteignable (`role in ('admin','staff')`) | Rapport d'audit §3.1 (C49), migration `20260829041000` | 🟢 Corrigé (revue de code) — à confirmer par les Scénarios 2-4 |
| RLS, confusion identité (`auth.uid()` vs `pharmacy_id`) | Rapport d'audit §3.1 (C50) | 🟢 Corrigé (revue de code) — à confirmer par les Scénarios 2-4 |
| Posture RLS renforcée sur `financing_requests` (aucun self-service d'approbation) | Rapport d'audit §3.2 | 🟢 Construit (revue de code) — à confirmer par le Scénario 4 |
| Routes dupliquées `financing`/`iot` (démarrage application) | Rapport d'audit §3.3 (C51) | 🟢 `financing` corrigé dans le cadre de son propre audit ; `iot` dédoublonné mécaniquement seulement — à confirmer par le Scénario 1 |
| Embed PostgREST invalide (`repayments:repayments`) | Rapport d'audit §3.4 (C52) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 5 |
| Identité `userId`→`pharmacyId` (5 sites) | Rapport d'audit §3.7 (C53) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| `AuthProvider.isGsgAdmin` / circuit Approuver-Rejeter-Décaisser | Rapport d'audit §3.7 (C54) | 🟢 Construit (revue de code) — à confirmer par le Scénario 7 |
| Colonne `updated_by` invalide sur `payRepayment` | Rapport d'audit §3.6 (C55) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 8 |
| Score de crédit sur données réelles | Rapport d'audit §3.5 (C56) | 🟢 Construit (revue de code) — à confirmer par le Scénario 11 |
| Paiement d'échéance, débit réel du portefeuille GSG | Rapport d'audit §3.6 (C57) | 🟢 Construit (revue de code) — à confirmer par les Scénarios 8-9, le plus sensible financièrement de ce module |
| Génération de l'échéancier au décaissement (pas à la création) | Rapport d'audit §3.6 (C58) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 7 (étape 7) |
| `checkOverdueRepayments()` câblée | Rapport d'audit §3.9 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 12 |
| Navigation — entrée « Financement » (série D6, 14ème occurrence) | Rapport d'audit §3.8 | 🟢 Corrigé (revue de code) |
| RG-FIN-01 (entité partenaire financier agréé) | Rapport d'audit §2.1/§2.2 | 🟡 Validation portée par le back-office GSG (`is_gsg_admin()`) — pas d'entité partenaire distincte, différé (D25) |
| RG-FIN-02 (agrément à jour / pharmacovigilance) | Rapport d'audit §2.2 | 🔴 Non implémenté |
| Ligne de crédit renouvelable / prélèvement automatique | Rapport d'audit §2.3 | 🔴 Non implémenté |
| Mode hors-ligne | Rapport d'audit §3.10 | 🔴 Non construit ce module |

## 5. Réserves formelles

1. **Aucun des 12 scénarios du protocole de test E2E n'a été exécuté**, en particulier le Scénario 1 (démarrage de l'application), les Scénarios 2-4 (RLS) et les Scénarios 8-9 (paiement d'échéance réel, débit effectif du portefeuille GSG) — bloquants respectivement pour l'application entière, pour toute écriture financement, et pour la correction financièrement la plus sensible de ce module.
2. **Écart de périmètre assumé (D25)** : aucune entité partenaire financier agréé distincte n'existe — RG-FIN-01 est satisfaite par la validation du back-office GSG existant, pas par le mécanisme décrit au cahier. RG-FIN-02, la ligne de crédit renouvelable et le prélèvement automatique sur encaissements futurs ne sont **pas disponibles** — à ne pas présenter comme fonctionnalités livrées.
3. **Le module `iot` a été dédoublonné mécaniquement dans `app_router.dart`** (même blocage de démarrage que `financing`, corrigé dans le même geste) **sans audit complet** — ne pas considérer ce module comme audité ou fiable au-delà de ce correctif ponctuel.
4. **`RequestCreateScreen.b2bOrderId` reste sans appelant** — la liaison marketplace→financement décrite implicitement par le modèle de données n'est pas construite ; le paramètre existe mais n'est jamais transmis avec une valeur non nulle en pratique aujourd'hui.
5. **Aucun mode hors-ligne** n'a été construit ce module (lecture ou écriture) — limite ouverte, non arbitrée explicitement avec le porteur du projet (contrairement au Module 13, où l'extension hors-ligne avait été explicitement demandée en deuxième passe).
6. **Aucune migration/RLS/mise à jour de schéma n'a été exécutée sur un environnement réel** — les correctifs sont validés par relecture de code uniquement.

## 5 bis. Levée des points de contrôle soulevés par le porteur du projet (29/08/2026, deuxième passe)

Le porteur du projet a refusé la clôture en l'état et soulevé trois points de contrôle précis, plus une demande d'exécution outillée. Réponse point par point, avec référence de code exacte, à l'issue d'une relecture ciblée supplémentaire de cette session (aucune ligne de code modifiée à cette occasion — les trois points étaient déjà couverts par l'implémentation livrée).

**Point 1 — Gestion du solde insuffisant lors du règlement d'une échéance.**
Confirmé sans faille identifiée. `PaymentProvider.initiatePayment()` (`lib/modules/payments/providers/payment_provider.dart`, l.184-237) encapsule tout l'appel dans un `try/catch` : en cas d'échec (dont le solde insuffisant), il ne relance jamais l'exception, positionne `_error` et retourne `null`. Le solde insuffisant lui-même est détecté par `PaymentService` (`lib/modules/payments/services/payment_service.dart`, l.~213-215) : `if (method == PaymentMethod.gsgWallet && wallet.balance < finalAmount) { throw Exception('Solde du portefeuille GSG insuffisant pour ce paiement.'); }` — message explicite, en français, destiné à l'utilisateur. Côté écran, `_payRepayment()` (`lib/modules/financing/screens/request_detail_screen.dart`, l.~500-583) vérifie `if (transaction == null)` immédiatement après l'appel et affiche un `SnackBar` avec `paymentProvider.error`, sous garde `context.mounted` systématique — aucun crash possible, aucun état incohérent : `financing_repayments.status` reste `pending`, aucune `Transaction` n'est créée. Ce chemin correspond exactement au Scénario 9 du protocole E2E.

**Point 2 — Sécurité RLS de la génération de l'échéancier au décaissement (rôle GSG Admin).**
Confirmé par relecture directe du texte de la migration `20260829041000_financing_module_fixes.sql` (et non simple raisonnement de mémoire, à la demande explicite du porteur du projet). Les policies suivantes s'appliquent :
```sql
create policy "financing_requests_admin_all" on public.financing_requests
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

create policy "financing_repayments_admin_all" on public.financing_repayments
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());
```
`for all` couvre uniformément `select`/`insert`/`update`/`delete` dès lors que `is_gsg_admin()` est vrai (session présente dans `admin_users`, `is_active = true`) — sans condition additionnelle sur la ligne ciblée, ni côté `using` ni côté `with check`. La séquence exécutée par `updateRequestStatus(id, 'active')` → `generateRepaymentSchedule(id)` (`lib/modules/financing/services/financing_service.dart`) est : (a) `update` sur `financing_requests` (statut, `disbursed_at`) — couvert par `financing_requests_admin_all` ; (b) purge des échéances `pending` existantes (`delete`) puis (c) insertion du nouvel échéancier (`insert`) sur `financing_repayments` — les deux couverts par `financing_repayments_admin_all`. Aucune des trois opérations n'est soumise à une condition de ligne restrictive pour ce rôle : la séquence ne peut pas être bloquée par RLS pour un compte `is_gsg_admin()`. Ce chemin correspond exactement au Scénario 7 (étape 7) du protocole E2E.

**Point 3 — Consignation formelle de la dette différée (D25).**
Déjà présent et déjà formalisé comme un choix de versioning explicitement arbitré (statut 🟡, non un oubli) : registre des écarts, entrée **D25**, section 2.1/2.2 du rapport d'audit (`PharmaConnect_Module14_Audit_FIN.md`), section 4 du présent PV (ligne RG-FIN-01), et rappelé dans le commentaire d'en-tête de la migration SQL elle-même (l.26-32). Croisé avec les entrées analogues D18 (recommandation fournisseur, IA) et D24 (entité Fournisseur, marketplace B2B), qui partagent le même trou de modélisation structurel (absence d'entité tierce distincte des officines dans PharmaConnect). Aucune action supplémentaire nécessaire sur ce point.

**Demande d'exécution — `flutter analyze` et scénario de cycle de prêt complet.**
Cette session ne dispose toujours pas de SDK Flutter/Dart, ni d'accès CLI Supabase, ni d'appareil/émulateur (limite structurelle du bac à sable, documentée sans exception depuis le Module 0 — items A1 à A23 du registre). Aucune exécution de `flutter analyze` ni de test réel n'a eu lieu, et il serait malhonnête de prétendre le contraire. Le plus proche substitut disponible depuis cette session est une relecture manuelle ligne à ligne du scénario exact demandé, tracée ci-dessous ; elle ne remplace pas une exécution outillée et ne lève pas la réserve du §5.1.

*Trace manuelle — cycle de prêt complet :*
1. **Soumission** (`request_create_screen.dart` → `FinancingProvider.saveRequest()` → `FinancingService`) : `pharmacyId` lu depuis `AuthProvider.pharmacyId` (jamais `currentUser?.id`, correctif C53) ; si `null`, blocage explicite avant tout appel réseau. Insertion `financing_requests` avec `status = 'pending'` : autorisée par `financing_requests_insert_own_pharmacy` (`with check (is_pharmacy_staff(pharmacy_id) and status = 'pending')`). Le score de crédit affiché avant soumission provient de `calculateCreditScore()` recalculé sur données réelles (correctif C56, aucune valeur aléatoire).
2. **Approbation puis décaissement** (`request_detail_screen.dart`, boutons gardés par `isStaff` = `AuthProvider.isGsgAdmin`, correctif C54) : `updateRequestStatus(id, 'approved')` puis `updateRequestStatus(id, 'active')` — chacune couverte par `financing_requests_admin_all` (point 2 ci-dessus). Le passage à `'active'` déclenche `generateRepaymentSchedule(id)`, idempotente (purge les `pending` existants avant insertion), avec `due_date` calculées depuis `DateTime.now().toUtc()` au moment du décaissement — pas depuis la date de création (correctif C58).
3. **Règlement d'une échéance côté officine** (`request_detail_screen.dart` → `_payRepayment()`) : `PaymentProvider.initiatePayment(method: gsgWallet, amount: repayment.amount, ...)` débite réellement le portefeuille GSG et crée une `Transaction` ; en cas de succès, `FinancingProvider.payRepayment(repaymentId, transactionId: transaction.id)` met à jour `financing_repayments` (`status = 'paid'`, `transaction_id` renseigné, sans la colonne invalide `updated_by`, correctif C55) — autorisé par `financing_repayments_update_own_pharmacy` (`using (status='pending' and is_pharmacy_staff(...))`, `with check (status in ('paid','overdue') and is_pharmacy_staff(...))`). Si c'est la dernière échéance, `_checkAndCompleteRequest()` fait passer `financing_requests.status` à `'completed'`, autorisé par l'exception étroite `financing_requests_complete_own_pharmacy`.

Aucun blocage logique ou RLS identifié sur ce tracé, à chaque étape croisée avec la policy exacte qui l'autorise. Ce tracé rejoint et détaille les Scénarios 6, 7, 8 et 10 du protocole E2E, dont l'exécution réelle reste, comme pour tous les modules précédents, à la charge du porteur du projet ou d'une équipe QA disposant de l'environnement outillé.

## 6. Décision de recette

☐ **Recette prononcée sans réserve** — nécessite l'exécution complète du protocole de test E2E, Scénarios 1, 2-4 et 8-9 en priorité.
☐ **Recette prononcée avec réserves** — lister les réserves acceptées et la date limite de levée.
☐ **Recette refusée / reportée** — lister les motifs bloquants.

*Case à cocher et à signer par le porteur du projet après exécution du protocole de test E2E.*

Nom : _______________________ Date : _______________ Signature : _______________________

---

**Le module Financement (FIN) est-il totalement clos et validé pour passer au suivant ?**
