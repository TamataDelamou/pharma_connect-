# PharmaConnect — Audit Module 14 (FIN — Financement & Crédit fournisseur)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Le module trouvé en base est un système de **demande/suivi de ligne de crédit fournisseur** — modèles `FinancingRequest`/`FinancingRepayment`/`CreditScore` (`lib/modules/financing/models/`), `FinancingService` (307 lignes, lecture/écriture Supabase), `FinancingProvider`, écrans `financing_dashboard_screen.dart` (liste + score de crédit), `request_create_screen.dart` (soumission), `request_detail_screen.dart` (détail, échéancier, actions), widget `financing_card.dart`. La migration de base (`financing_requests`/`financing_repayments`/`credit_scores`, `20260829002000_financing.sql`) existe avec RLS déjà présente en apparence — mais doublement défaillante (voir §3.1).

Fichiers inspectés : `lib/modules/financing/models/*.dart` (3), `services/financing_service.dart`, `providers/financing_provider.dart`, `screens/financing_dashboard_screen.dart`, `screens/request_create_screen.dart`, `screens/request_detail_screen.dart`, `widgets/financing_card.dart`, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `app.dart`), plus `lib/modules/payments/` (providers/services/modèles) pour concevoir l'intégration réelle du paiement d'échéance, plus `lib/modules/admin/` (provider/service/modèle `AdminUser`) pour vérifier l'existence — ou l'absence — d'un mécanisme client permettant à un compte de connaître son propre statut de membre du back-office GSG.

### 1.2 Défauts constatés

1. **Verrou RLS total, double cause** — les policies « Pharmacy own » des 3 tables comparaient `auth.uid()` (id UTILISATEUR) directement à `pharmacy_id` (id OFFICINE), exactement le même défaut que C43 (Module 13) ; les policies « Staff manage » testaient `profiles.role in ('admin', 'staff')`, un rôle inatteignable par construction (motif déjà documenté par `20260829003800_admin_helpers.sql`, dont l'énumération des migrations concernées omettait `financing.sql`). Combinées, les 3 tables étaient totalement inaccessibles en lecture et en écriture, pour tout le monde — voir §3.1.
2. **Routes dupliquées dans `app_router.dart`** — les 6 routes `financing` et les 7 routes `iot` (imports compris) étaient chacune déclarées deux fois à l'identique, provoquant une exception `go_router` au démarrage — même anti-motif que C45 (marketplace, Module 13), laissé hors périmètre à l'époque pour ces deux modules.
3. **Embed PostgREST invalide** — `FinancingService.getRequests()`/`getRequest()` utilisaient `repayments:repayments(...)`, une table `repayments` qui n'existe pas (la table réelle est `financing_repayments`) — même bug exact que C48 (Module 13), faisant échouer ces deux méthodes dans leur intégralité.
4. **Confusion identifiant utilisateur / identifiant officine** — `request_create_screen.dart` (`_submitRequest`), `financing_dashboard_screen.dart` (3 sites : chargement initial, rechargement d'onglet, rafraîchissement du score) et `request_detail_screen.dart` (`isOwner`) utilisaient tous `SupabaseService().currentUser?.id`, jamais `AuthProvider.pharmacyId` — même motif que C43 (Module 13), cette fois cinq occurrences dans ce seul module.
5. **`isStaff` figé à `false`** (`request_detail_screen.dart`) — `final isStaff = false; // Check staff role if needed`, rendant tout le circuit Approuver/Rejeter/Décaisser (RG-FIN-01) définitivement inatteignable depuis l'UI. Aucun mécanisme n'existait par ailleurs dans le projet pour qu'un compte connaisse son propre statut de membre du back-office GSG (`AdminProvider` gère des utilisateurs/officines *depuis* le back-office, mais n'expose aucun « suis-je moi-même admin ? »).
6. **Colonne inexistante dans `payRepayment()`** — `FinancingService.payRepayment()` envoyait `'updated_by': ...` dans son payload d'update vers `financing_repayments`, colonne qui n'existe pas sur cette table (elle existe sur `financing_requests`). Contrairement aux 5 défauts précédents, ce chemin était **déjà atteignable depuis l'UI** (le bouton « Payer » n'était gardé que par `isOwner`, jamais par `isStaff`) : toute tentative réelle de paiement d'échéance aurait échoué côté serveur.
7. **Score de crédit entièrement fictif** — `calculateCreditScore()` générait `600 + DateTime.now().millisecondsSinceEpoch % 400` et des `factors` codés en dur (`'good'`/`'medium'`/`'2 years'`), sans aucun lien avec l'activité réelle de l'officine.
8. **Remboursement sans mouvement d'argent réel** — `payRepayment()` se contentait de marquer l'échéance `status = 'paid'` ; aucun débit du portefeuille GSG, aucune `Transaction` créée, `financing_repayments.transaction_id` (colonne existante) toujours nul.
9. **Échéancier généré à la mauvaise date** — `FinancingProvider.saveRequest()` générait l'échéancier complet dès la création de la demande (encore `pending`), avec des dates d'échéance calculées depuis la date de création plutôt que depuis le décaissement réel, qui peut survenir plusieurs semaines plus tard.
10. **`checkOverdueRepayments()` orpheline** — méthode fonctionnelle, jamais appelée nulle part, même motif que C11/C47 (code mort/jamais relié).
11. **`RequestCreateScreen.b2bOrderId` sans appelant** — le paramètre existe et est correctement transmis à `FinancingRequest.b2bOrderId` (le lien décrit par le cahier entre une commande B2B et une demande de financement associée), mais aucun écran du module marketplace ne navigue jamais vers cet écran avec un `b2bOrderId` non nul — la liaison marketplace→financement est entièrement déconnectée.
12. **Aucun point d'entrée de navigation** vers `/financing` dans le menu unique de l'application (`dashboard_screen.dart`) — 14ème occurrence de la série D6, voir §3.7.
13. **Aucun mode hors-ligne** — même constat qu'à l'ouverture du Module 13, avant sa première passe : aucun cache local, contrairement aux modules disposant déjà d'une lecture consultable hors-ligne.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Écart de périmètre — arbitré avec le porteur du projet

Le cahier décrit RG-FIN-01 (Critique) : *« L'octroi d'une ligne de crédit à une officine requiert un historique minimal d'activité sur la plateforme et est soumis à validation d'un **partenaire financier agréé**. »* Un partenariat explicite avec des institutions de microfinance/banques locales est également cité parmi les fonctionnalités clés. Aucune entité de ce type n'existe dans le projet — même trou de modélisation que D18 (recommandation de fournisseur, IA) et D24 (entité Fournisseur, marketplace B2B) : aucune entité tierce distincte des officines n'existe nulle part dans PharmaConnect.

**Arbitrage porteur du projet (AskUserQuestion, 29/08/2026)** : *« Corriger le scoring et le remboursement, différer le partenaire »* — le back-office GSG existant (`is_gsg_admin()`) porte la validation prévue par RG-FIN-01, à la place d'une entité partenaire distincte, au même titre que la vérification de licence officine (RG-AUT-01). Le scoring (§1.2 point 7) et le remboursement (§1.2 point 8) sont corrigés pour reposer sur des données/mouvements réels. Les six bugs bloquants (§1.2 points 1-6) sont corrigés dans tous les cas, indépendamment de ce choix de périmètre. Voir registre **D25**.

### 2.2 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-FIN-01** | Historique minimal d'activité + validation d'un partenaire financier agréé | 🟡 Validation portée par le back-office GSG (`is_gsg_admin()`), pas par une entité partenaire distincte (D25). Historique minimal : non formalisé en seuil bloquant — le score de crédit corrigé (§3.5) reflète l'historique réel mais ne bloque pas encore une demande sous un certain score |
| **RG-FIN-02** | Module accessible seulement aux officines à jour de leur agrément et sans signalement de pharmacovigilance non résolu | 🔴 Non implémenté — aucune vérification de ce type dans `request_create_screen.dart`/RLS avant ce module ni ajoutée ce module (nécessiterait de croiser `pharmacies.status`/`counterfeit_reports`, hors périmètre du choix arbitré ce tour) |

### 2.3 Fonctionnalités clés du cahier

| Fonctionnalité (cahier) | Constat |
|---|---|
| Demande de financement | 🟢 Existait déjà, fonctionnel — corrigé ce module (RLS, identité, RG-AUT-01) |
| Suivi de la ligne de crédit | 🟢 Existait déjà, fonctionnel — corrigé ce module (RLS, identité) |
| Échéancier de remboursement | 🟡 Existait déjà mais sans effet réel (§1.2 points 8-9) — corrigé ce module (paiement réel, génération au décaissement) |
| Scoring officine basé sur historique de ventes/paiements | 🟡 Existait déjà mais entièrement fictif — corrigé ce module (§3.5) |
| Ligne de crédit renouvelable pour l'achat de stock | 🔴 Non implémenté — `b2bOrderId` existe côté modèle (§1.2 point 11) mais aucun mécanisme de renouvellement automatique, aucun plafond de ligne cumulable |
| Prélèvement automatique sur les encaissements futurs | 🔴 Non implémenté — le remboursement corrigé ce module reste une action manuelle de l'officine (bouton « Payer »), jamais un prélèvement automatique sur les transactions entrantes |
| Partenariat avec institutions de microfinance/banques locales | 🔴 Hors périmètre — différé (D25) |

### 2.4 Écrans principaux (cahier)

| Écran (cahier) | Constat |
|---|---|
| Demande de financement | 🟢 Existait déjà — corrigé ce module (identité, score de crédit chargé dès l'ouverture) |
| Suivi de la ligne de crédit | 🟢 Existait déjà (tableau de bord + détail) — corrigé ce module (identité, actions back-office réellement gardées) |
| Échéancier de remboursement | 🟢 Existait déjà (dans l'écran de détail) — corrigé ce module (paiement réel) |

---

## 3. Sécurité & résilience

### 3.1 RLS — double cause de verrou total (C49/C50)

Les 6 policies de la migration de base (`financing_requests`/`financing_repayments`/`credit_scores`, 2 par table) combinaient deux défauts indépendants, chacun suffisant à lui seul pour bloquer toute la table :

- **« Staff manage »** (les 3 tables) testait `profiles.role in ('admin', 'staff')` — classé **C49** — un rôle inatteignable par construction, motif déjà documenté par `20260829003800_admin_helpers.sql` (dont l'énumération omettait `financing.sql`, un oubli de couverture plutôt qu'une réapparition du bug).
- **« Pharmacy own »** (les 3 tables) comparait `auth.uid()` à `pharmacy_id` — classé **C50** — même famille exacte que C43 (Module 13), cette fois côté RLS des 3 tables plutôt que côté écrans.

**Corrigé** : migration `20260829041000_financing_module_fixes.sql` (additive) — remplace les deux familles par `public.is_pharmacy_staff(pharmacy_id)` (lecture/écriture propre officine) et `public.is_gsg_admin()` (accès complet back-office), les deux helpers déjà établis et réutilisés dans tous les modules précédents. Voir §3.2 pour la posture RLS choisie, plus stricte que le précédent C18/C22/C25/C30.

### 3.2 Posture RLS — déviation assumée du précédent C18/C22/C25/C30

Les modules précédents (ORD/RES/LIV/PAY) suivent tous le même patron : RLS large côté rôle, l'UI cliente restreint seule les transitions de statut valides (C18/C22/C25/C30). Ce module s'en écarte délibérément pour `financing_requests` : la RLS ne donne **aucun** droit d'update à l'officine (ni approuver, ni rejeter, ni décaisser sa propre demande), sauf l'exception étroite du constat comptable `'active' → 'completed'` quand la dernière échéance est soldée. Un octroi de crédit engage des fonds réels — protéger cet enjeu par la seule discipline de l'UI cliente (contournable par un client alternatif frappant directement l'API) a été jugé insuffisant, contrairement à un statut de suivi métier ordinaire. Seul `is_gsg_admin()` peut approuver/rejeter/décaisser. Documenté explicitement en tête de la migration.

`financing_repayments` suit une posture intermédiaire : l'officine peut lire son échéancier et faire transiter une échéance `pending` vers `paid` (paiement, après débit réussi du portefeuille) ou `overdue` (constat passif de retard, sans risque — une officine ne peut que dégrader son propre statut). L'insertion (génération de l'échéancier) reste réservée au back-office, cohérent avec le déplacement de sa génération au décaissement (§3.6). `credit_scores` autorise l'officine à écrire son propre score (le calcul repose sur ses propres données, déjà protégées par leur propre RLS — aucun risque à la laisser déclencher son propre recalcul, à l'identique du flux déjà en place).

### 3.3 Démarrage de l'application — routes dupliquées (C51)

Même anti-motif que C45 (Module 13) : les 6 routes `financing` et 7 routes `iot` (imports compris) étaient chacune déclarées deux fois à l'identique, provoquant une exception `go_router` au démarrage de l'application entière. `financing` est dédoublonné dans le cadre du propre audit de ce module. `iot` est dédoublonné dans le même geste — les deux blocs de duplication cohabitaient dans le même fichier et empêchaient le démarrage ensemble, corriger l'un sans l'autre n'aurait servi à rien — mais **mécaniquement seulement** : aucun audit RLS/écrans/services du module `iot` n'a été fait ce tour, à ne pas confondre avec une clôture de module. `iot` reste donc volontairement absent du menu de navigation (§3.7), pour la même raison que `pos` (D22).

### 3.4 Embed PostgREST invalide (C52)

Même bug exact que C48 (Module 13) : `repayments:repayments(...)` référence une table `repayments` qui n'existe pas — la table réelle est `financing_repayments`. PostgREST rejette toute requête embarquant une relation inexistante (erreur 400), faisant échouer `getRequests()`/`getRequest()` dans leur intégralité. **Corrigé** : `repayments:financing_repayments(...)` dans les deux méthodes.

### 3.5 Score de crédit — calcul remplacé par des données réelles (C56)

L'ancien calcul (`600 + millisecondsSinceEpoch % 400`) est remplacé par trois facteurs réels, pondérés puis mis à l'échelle 0-1000 :

- **Historique de remboursement (50%)** — proportion d'échéances soldées à temps (`paid`, jamais passées par `overdue`) sur l'ensemble des échéances déjà échues, tous financements confondus pour l'officine. Une officine sans historique (aucune échéance échue) reçoit un score neutre de 70/100 plutôt que 0, pour ne pas la pénaliser comme mauvaise payeuse simplement faute d'avoir déjà emprunté.
- **Volume B2B (30%)** — nombre de commandes B2B en tant qu'acheteuse sur les 12 derniers mois (`b2b_orders.buyer_pharmacy_id`), plafonné à 100/100 pour 50 commandes ou plus.
- **Ancienneté du compte (20%)** — `pharmacies.created_at`, plafonnée à 100/100 pour 24 mois ou plus.

Limites assumées, non corrigées ce module : pas de pondération par montant des transactions (une commande de 10 000 GNF compte comme une commande de 10 000 000 GNF), pas de prise en compte de la saisonnalité, seuil de 70/100 par défaut pour l'historique de remboursement arbitraire (pas de données empiriques pour le calibrer). Un pharmacien peut déclencher le recalcul de son propre score (bouton « Rafraîchir », déjà présent) — sans risque, le calcul n'utilisant que ses propres données, elles-mêmes protégées par leur propre RLS.

### 3.6 Remboursement — câblage réel au portefeuille GSG (C55/C57/C58)

Trois défauts distincts, corrigés ensemble :

- **C57** — `payRepayment()` ne débitait jamais réellement le portefeuille GSG. **Corrigé** : `request_detail_screen.dart` appelle désormais `PaymentProvider.initiatePayment(method: PaymentMethod.gsgWallet, ...)` — le même mécanisme déjà utilisé pour le paiement de commande (Module 8) — avant `FinancingProvider.payRepayment(transactionId: ...)`, qui persiste désormais le lien vers la transaction réelle (`financing_repayments.transaction_id`, colonne existante mais jamais renseignée jusqu'ici). Confirmation utilisateur avant débit, message dédié en cas de solde insuffisant, et message distinct si le débit réussit mais que la mise à jour de l'échéance échoue ensuite (le portefeuille est déjà débité à ce stade — l'utilisateur ne doit pas relancer un second débit en pensant que rien ne s'est passé).
- **C55** — `payRepayment()` envoyait par ailleurs `'updated_by'` vers `financing_repayments`, colonne inexistante sur cette table : toute tentative de paiement, avant même la question du câblage au portefeuille, aurait échoué côté serveur. Ce défaut était le seul de ce module déjà atteignable par un utilisateur ordinaire (le bouton « Payer » n'était gardé que par `isOwner`). **Corrigé** : clé retirée du payload.
- **C58** — l'échéancier était généré à la création de la demande (`pending`), avec des dates calculées depuis cette date plutôt que depuis le décaissement réel. **Corrigé** : la génération est déplacée dans `FinancingService.updateRequestStatus()`, déclenchée au passage à `'active'` (décaissement, action back-office). Idempotente — purge les échéances `pending` existantes avant régénération, au cas où le décaissement serait relancé après un échec réseau partiel.

Simulation client de la confirmation de paiement (pas de webhook serveur vérifié) : posture assumée, identique au précédent D12-D13 (paiement de commande, Module 8) — pas une régression propre à ce module.

### 3.7 Contrôle d'accès applicatif — `isStaff`/`isOwner` (C53/C54)

**C53** — cinq sites utilisant `SupabaseService().currentUser?.id` au lieu de `AuthProvider.pharmacyId` (§1.2 point 4), même motif que C43 (Module 13). **Corrigé** dans les 5 écrans/sites. `request_create_screen.dart` bloque désormais explicitement la soumission si `pharmacyId` est absent (compte non encore vérifié, RG-AUT-01) plutôt que d'envoyer un identifiant faux qu'une RLS stricte aurait de toute façon rejeté silencieusement.

**C54** — `isStaff` figé à `false` (§1.2 point 5), variante distincte du motif D6 habituel : le code d'action (Approuver/Rejeter/Décaisser) est bien câblé à l'écran, contrairement à un simple manque d'appelant, mais gardé par une condition UI toujours fausse. **Corrigé** : `AuthProvider.isGsgAdmin` (nouveau) — lecture best-effort de `public.admin_users` après connexion (`_persistProfile`/`_loadAdminStatus`, même patron que `_pharmacyId`, même source que la RLS `is_gsg_admin()` elle-même) ; `isStaff` reflète désormais ce champ. Il ne s'agit que d'une commodité d'affichage côté client — la RLS (§3.1/§3.2) reste seule autorité réelle sur ce qu'un compte peut effectivement faire.

### 3.8 Navigation — 14ème occurrence de la série D6

Le module financement n'apparaissait dans aucune entrée du menu de navigation unique (`dashboard_screen.dart`, `_navItems`), reproduisant le même motif déjà rencontré 13 fois. **Corrigé** par l'ajout d'une entrée « Financement » (icône `account_balance`, route `/financing`), placée après « Marketplace B2B » et avant « Alertes ». `iot` reste volontairement absent du menu (§3.3) — même raison que `pos` (D22) : routes dédupliquées mécaniquement, jamais audité.

### 3.9 Code orphelin

`checkOverdueRepayments()` (§1.2 point 10) — **corrigé** : câblée dans `FinancingProvider.loadRequests()`, appelée best-effort/non attendue (`unawaited`) à chaque chargement du tableau de bord ; échoue silencieusement en interne (try/catch défensif) pour ne jamais faire échouer l'écran appelant.

`RequestCreateScreen.b2bOrderId` (§1.2 point 11) — **non corrigé**, signalé au registre plutôt que traité : câbler la navigation marketplace→financement (un bouton « Demander un financement pour cette commande » depuis `order_detail_screen.dart`) dépasserait le périmètre d'un audit-et-corrige de ce module, et le module marketplace lui-même reste une dette partielle (D24). Le paramètre reste fonctionnel, simplement jamais atteint avec une valeur non nulle en pratique aujourd'hui.

### 3.10 Mode hors-ligne

Aucun construit ce module — même situation qu'à l'ouverture du Module 13 avant sa première passe. Directive standing « privilégier le mode hors-ligne » non appliquée ici, par cohérence avec PAY (D13) plutôt que par oubli : les écritures de ce module (soumettre une demande, payer une échéance) sont, comme PAY, des actions financières où rejouer un appel réseau mis en file d'attente après une coupure risquerait une double soumission/un double débit. La lecture (liste des demandes, détail, score de crédit) n'a pas non plus été mise en cache ce tour — signalé comme limite ouverte plutôt que construit, faute d'arbitrage explicite demandé sur ce point précis (contrairement au Module 13, où le porteur du projet l'a explicitement demandé en deuxième passe).

---

## 4. Optimisation & améliorations livrées

1. **Migration `20260829041000_financing_module_fixes.sql`** — 9 policies RLS recréées (3 par table) avec `is_pharmacy_staff()`/`is_gsg_admin()`, posture volontairement plus stricte que le précédent C18/C22/C25/C30 pour `financing_requests` (§3.1/§3.2).
2. **`auth_provider.dart`** — `isGsgAdmin` (nouveau champ + getter), `_loadAdminStatus()` (nouvelle méthode, best-effort, lecture `admin_users`), appelée depuis `_persistProfile()` (les deux chemins de connexion, téléphone et email) ; réinitialisé à `logout()`.
3. **`financing_service.dart`** — embed `repayments:financing_repayments(...)` (2 méthodes) ; `calculateCreditScore()` réécrite (3 facteurs réels pondérés, §3.5) ; `payRepayment()` accepte et persiste `transactionId`, clé `updated_by` retirée (C55) ; `updateRequestStatus()` déclenche `generateRepaymentSchedule()` au passage à `'active'` (C58) ; `generateRepaymentSchedule()` rendue idempotente (purge avant régénération) ; `checkOverdueRepayments()` rendue défensive (try/catch interne).
4. **`financing_provider.dart`** — `payRepayment()` transmet `transactionId` ; `loadRequests()` déclenche `checkOverdueRepayments()` en tâche de fond (`unawaited`) ; `saveRequest()` ne génère plus l'échéancier à la création (déplacé au décaissement, service).
5. **`request_detail_screen.dart`** — `isOwner`/`isStaff` corrigés (`AuthProvider.pharmacyId`/`isGsgAdmin`) ; bouton « Payer » entièrement réécrit (`_payRepayment`, nouveau) : confirmation, débit réel via `PaymentProvider.initiatePayment`, gestion de l'échec de paiement et de l'échec de mise à jour post-débit, séparément.
6. **`request_create_screen.dart`** — `pharmacyId` corrigé, blocage explicite si absent ; chargement du score de crédit dès l'ouverture de l'écran (amélioration UX — jusqu'ici affiché seulement par coïncidence si le tableau de bord l'avait déjà chargé au préalable).
7. **`financing_dashboard_screen.dart`** — 3 sites `pharmacyId` corrigés ; import mort `currency_formatter.dart` retiré (jamais utilisé dans ce fichier, code mort).
8. **`app_router.dart`** — imports/déclarations `financing` et `iot` dédoublonnés (§3.3) ; commentaire de tête mis à jour pour refléter la résolution complète.
9. **`dashboard_screen.dart`** — entrée de navigation « Financement » ajoutée (§3.8), commentaire historique D6 étendu.

---

## 5. Documentation API — `FinancingService`/`FinancingProvider`/`AuthProvider` (méthodes nouvelles/modifiées)

| Méthode | Paramètres | Retour | Notes |
|---|---|---|---|
| `FinancingService.calculateCreditScore` | `pharmacyId` | `Future<CreditScore>` | Réécrite — calcul réel (§3.5) au lieu d'un score aléatoire |
| `FinancingService.payRepayment` | `repaymentId`, `transactionId?` (nouveau) | `Future<FinancingRepayment>` | Modifiée — persiste le lien vers la transaction réelle, retire la clé `updated_by` invalide |
| `FinancingService.updateRequestStatus` | `id`, `newStatus` | `Future<FinancingRequest>` | Modifiée — déclenche `generateRepaymentSchedule()` si `newStatus == 'active'` |
| `FinancingService.generateRepaymentSchedule` | `requestId` | `Future<List<FinancingRepayment>>` | Modifiée — idempotente (purge avant régénération) |
| `FinancingService.checkOverdueRepayments` | — | `Future<void>` | Modifiée — try/catch défensif interne ; désormais appelée (§3.9) |
| `FinancingProvider.payRepayment` | `repaymentId`, `transactionId?` (nouveau) | `Future<bool>` | Modifiée — transmet le paramètre au service |
| `AuthProvider.isGsgAdmin` | — | `bool` (getter) | Nouveau — reflète `admin_users`, best-effort, jamais utilisé pour trancher un accès (la RLS reste seule autorité) |

---

## 6. Livrables et écarts documentés

Livrés ce module : correctif RLS double cause sur 3 tables/9 policies (C49/C50), posture RLS renforcée pour `financing_requests` (déviation assumée du précédent C18/C22/C25/C30), correctif des routes dupliquées `financing`/`iot` bloquant le démarrage de l'application (C51, `iot` dédoublonné mécaniquement seulement), correctif de l'embed PostgREST invalide (C52), migration `userId`→`pharmacyId` sur 5 sites (C53), `AuthProvider.isGsgAdmin` (nouveau) débloquant le circuit Approuver/Rejeter/Décaisser (C54), correctif d'une colonne inexistante bloquant tout paiement d'échéance réel (C55), score de crédit recalculé sur données réelles (C56), remboursement réellement câblé au portefeuille GSG avec lien de transaction (C57), génération de l'échéancier déplacée au décaissement (C58), câblage de `checkOverdueRepayments()` (orpheline), entrée de navigation « Financement » (14ème occurrence série D6).

Écarts assumés et documentés, par arbitrage explicite du porteur du projet (D25) : l'entité **partenaire financier agréé** décrite par RG-FIN-01 n'est **pas construite** ce module ; sa validation est portée par le back-office GSG existant. RG-FIN-02 (agrément à jour + absence de signalement pharmacovigilance non résolu) n'est pas implémenté. La ligne de crédit renouvelable et le prélèvement automatique sur les encaissements futurs restent non construits. `RequestCreateScreen.b2bOrderId` reste sans appelant (liaison marketplace→financement déconnectée). Aucun mode hors-ligne n'a été construit ce module.

Voir `PharmaConnect_Module14_Protocole_Test_E2E.md` pour les scénarios de validation et `PharmaConnect_Module14_PV_Recette.md` pour l'état de recette provisoire.

---

**Le module Financement (FIN) est-il totalement clos et validé pour passer au suivant ?**
