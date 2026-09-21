# PharmaConnect — Module 24 (ASR — Assurance santé & Tiers-payant)
## Étape 1 — Inspection & Rapport de situation

Date d'audit : 2026-08-30
Périmètre inspecté : `lib/modules/insurance/` (9 fichiers), `supabase/migrations/20260827007000_insurance.sql`, `supabase/migrations/20260828022000_reimbursement_tracking.sql`, routage (`app_router.dart`), navigation (`dashboard_screen.dart`).

---

### 1. Rappel du périmètre cahier (Module 24 — ASR)

Extrait du `Cahier_de_Conception_PharmaConnect_v2.docx` (table canonique de numérotation, confirmé par recherche documentaire) :

**Objectif** : Préparer l'intégration de PharmaConnect avec les mutuelles de santé et futurs mécanismes de couverture santé universelle en Guinée, en permettant la prise en charge partielle ou totale des achats de médicaments.

**Fonctionnalités clés attendues** :
1. Rattachement d'un patient à une mutuelle ou un assureur santé partenaire.
2. Calcul automatique de la part prise en charge et du reste à payer au moment du paiement.
3. Télétransmission des feuilles de soins pharmaceutiques à l'assureur.
4. Tableau de bord assureur pour le suivi de la consommation de ses affiliés.

**Écrans principaux prévus** : Rattachement mutuelle / Détail de prise en charge à la caisse / Portail assureur partenaire.

**RG-ASR-01 (Critique)** : « Le montant pris en charge par un tiers-payant est calculé selon les règles contractuelles propres à chaque assureur, paramétrées en back-office et non modifiables par l'officine. »

Priorité cahier : **Différenciant**.

---

### 2. Constat général

Le module ASR existe et couvre une partie réelle du périmètre : modèle de données assez riche (compagnies, plans, adhésions, pré-autorisations, sinistres/claims, accords prestataires, suivi de remboursement), écran de liste des adhésions avec onglets, écran de détail avec simulateur de couverture, écran de suivi de remboursement. Mais l'inspection fait apparaître un défaut structurel majeur et récurrent (déjà rencontré sous une forme voisine dans plusieurs modules précédents) : **la quasi-totalité du chemin d'écriture du module est bloquée au niveau des droits Postgres/RLS**, rendant le module fonctionnellement mort en écriture malgré un code client apparemment complet. S'y ajoutent une fonctionnalité mock non branchée, un bouton menant vers un écran inexistant en pratique, une lacune de calcul métier assumée dans le code lui-même, et une absence totale d'exposition en navigation.

---

### 3. Inventaire du code trouvé

**Modèles** (`lib/modules/insurance/models/`) : `insurance_company.dart`, `insurance_enrollment.dart`, `reimbursement_tracking.dart` — RAS structurellement.

**Provider** : `insurance_provider.dart` — `ChangeNotifier` standard (companies, enrollments, selectedEnrollment, coverageCalculation), RAS.

**Service** : `insurance_service.dart` — CRUD compagnies (lecture seule) et adhésions (CRUD complet côté client), `calculateCoverage()`.

**Écrans** : `insurance_enrollments_screen.dart` (liste, onglets Tous/Actifs/Expirés, bouton staff « Nouveau contrat »), `enrollment_detail_screen.dart` (détail + simulateur de couverture + suppression), `reimbursement_status_screen.dart` (timeline de statut de remboursement).

**Widget** : `enrollment_card.dart` — RAS.

**Base de données** : `20260827007000_insurance.sql` (tables `insurance_companies`, `insurance_plans`, `insurance_enrollments`, `pre_authorizations`, `insurance_claims`, `provider_agreements` + RLS + seed), `20260828022000_reimbursement_tracking.sql` (table `reimbursement_tracking` + RLS).

**Non trouvé dans le code** : aucun mécanisme de télétransmission de feuille de soins vers un assureur externe (fonctionnalité clé n°3 du cahier), aucun portail/tableau de bord assureur (fonctionnalité clé n°4 et écran « Portail assureur partenaire » du cahier), aucun écran de création d'adhésion dédié (« Rattachement mutuelle »).

---

### 4. Défauts identifiés à l'ouverture

**ASR-1 (Critique) — Motif « rôle inatteignable » (RLS), 5 occurrences.**
Les policies `for all` suivantes utilisent `role in ('admin', 'staff')` :
- `Staff manage enrollments` (`insurance_enrollments`)
- `Staff manage pre-auths` (`pre_authorizations`)
- `Staff manage claims` (`insurance_claims`)
- `Staff manage provider agreements` (`provider_agreements`)
- `Staff manage reimbursements` (`reimbursement_tracking`)

Or la contrainte `CHECK` sur `profiles.role` n'autorise que `'patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel', 'regulateur'` — les valeurs `'admin'` et `'staff'` sont structurellement impossibles à atteindre. C'est exactement le motif déjà rencontré et corrigé aux Modules 21 (IOT), 23 (HOP) et ailleurs, dont le correctif de référence est `public.is_gsg_admin()`.

**Conséquence directe** : aucune adhésion, pré-autorisation, sinistre, accord prestataire ou suivi de remboursement ne peut être créé, modifié ou supprimé par personne — ni par un administrateur légitime (rôle inatteignable), ni par le patient (qui n'a qu'un droit de lecture sur ses propres lignes, jamais d'écriture). Le bouton « Nouveau contrat » (`insurance_enrollments_screen.dart`, staff uniquement) échouerait systématiquement en écriture même si son bug de routage (ASR-3, ci-dessous) était corrigé.

**ASR-2 (Critique) — Absence totale de policy d'écriture sur `insurance_companies` et `insurance_plans`.**
Contrairement aux autres tables du module, `insurance_companies` et `insurance_plans` ne disposent **que** d'une policy `select using (true)` (« Everyone can view... »). Aucune policy `insert`/`update`/`delete`/`all` n'existe pour ces deux tables, pour aucun rôle, y compris un futur `is_gsg_admin()`. Concrètement, la RG-ASR-01 exige des règles de prise en charge « paramétrées en back-office » — or il est aujourd'hui **impossible pour quiconque** de créer une compagnie d'assurance, un plan, ou de modifier le barème `coverage_details` (JSON pilotant les % de prise en charge par type d'acte) via l'application. Seules les 4 compagnies et le plan unique insérés par le seed de la migration existent, et le resteront tant qu'aucune policy d'écriture n'est ajoutée. Point notable : cette lacune respecte accidentellement le second volet de la RG-ASR-01 (« non modifiable par l'officine » — aucune policy pharmacien n'existe non plus), mais elle bloque également le back-office légitime, ce qui rend le paramétrage assureur totalement inopérant en l'état.

**ASR-3 — Bouton « Nouveau contrat » sans écran de destination fonctionnel.**
`insurance_enrollments_screen.dart` navigue vers `/insurance/enroll/new` (`context.push('/insurance/enroll/new')`) pour le bouton staff. Or `app_router.dart` ne déclare que `GoRoute(path: '/insurance/enroll/:id', ...)` → `EnrollmentDetailScreen(enrollmentId: id)`. Avec `go_router`, `/insurance/enroll/new` correspond à ce même pattern avec `id = 'new'` : l'écran de **détail** s'ouvre donc avec `enrollmentId: 'new'`, puis `InsuranceProvider.loadEnrollment('new')` tente `select ... where id = 'new'` sur une colonne `uuid` — requête vouée à l'échec (littéral UUID invalide). Il n'existe **aucun écran de création d'adhésion** dans le module (l'écran « Rattachement mutuelle » du cahier est absent) ; `EnrollmentDetailScreen` ne fait que consulter/simuler/supprimer une adhésion déjà existante, jamais en créer une.

**ASR-4 — `ReimbursementStatusScreen` intégralement simulé et orphelin de route.**
Deux défauts cumulés sur ce même écran :
- *Données fictives* : `_loadData()` ne consulte jamais Supabase — elle construit un `ReimbursementTracking` codé en dur (`id: '1'`, montants fixes 50 000/35 000, statut `'under_review'`) après un simple `Future.delayed`. Le paramètre `claimId` reçu par le widget est ignoré. Aucun appel à `InsuranceService` n'existe dans ce fichier.
- *Écran inatteignable* : aucune route dans `app_router.dart` ne référence `ReimbursementStatusScreen` (recherche exhaustive sur « Reimbursement/reimbursement/claim » : aucune correspondance). L'écran n'est donc, en l'état, accessible depuis nulle part dans l'application — un cumul du motif HOP-2 (import/route cassé) sous une forme encore plus radicale (absence totale de route, pas seulement un lien rompu).

**ASR-5 — Calcul du plafond restant non implémenté (`InsuranceService.calculateCoverage()`).**
```dart
'remainingLimit': enrollment.annualLimit, // Would need to track usage
```
Le champ `remainingLimit` retourné est systématiquement égal au plafond annuel complet — aucun suivi de consommation cumulée n'existe nulle part dans le code (ni colonne dédiée, ni agrégation des `insurance_claims`/`reimbursement_tracking` déjà traités). Un patient ayant déjà épuisé son plafond annuel se verrait donc afficher un plafond restant intact lors de la simulation de couverture. Défaut directement lié à l'exactitude du calcul exigée par la RG-ASR-01.

**ASR-6 (à confirmer en Étape 3) — Suspicion de syntaxe d'embed PostgREST invalide.**
`getEnrollmentsForPatient()` et `getEnrollment()` utilisent :
```dart
'*, plans:plan_id(name), companies:plans!inner(company_id(name))'
```
Le premier embed (`plans:plan_id(name)`) est correct (alias sur la colonne FK réelle `plan_id`). Le second (`companies:plans!inner(company_id(name))`) utilise comme indice de relation `plans`, qui ne correspond ni au nom de la colonne FK (`plan_id`), ni au nom de la table cible (`insurance_plans`), ni à aucune contrainte nommée `plans` — PostgREST résout les indices de relation par ces critères, pas par un alias défini plus tôt dans la même chaîne `select`. Ce motif est proche des bugs d'embed déjà confirmés dans d'autres modules (classe C48/C60/FAM-5). **Non encore vérifié par exécution réelle** — à valider en Étape 3 via un test PostgREST/schéma réel avant correction.

**ASR-7 — Motif D6 : absence totale d'exposition en navigation (23ᵉ occurrence de ce motif dans l'audit).**
Recherche exhaustive dans `dashboard_screen.dart` : aucune entrée de menu ne référence `/insurance`, `/insurance/staff`, ni aucun libellé « Assurance »/« Mutuelle »/« Tiers-payant ». Le module — pourtant partiellement fonctionnel en lecture (liste des adhésions, détail, simulateur) — est aujourd'hui totalement inaccessible depuis le menu principal de l'application.

---

### 5. Écarts de périmètre par rapport au cahier

- **Télétransmission des feuilles de soins pharmaceutiques à l'assureur** (fonctionnalité clé n°3 du cahier) : absente. Aucun mécanisme d'échange externe (webhook, export, API assureur) n'existe dans le code ; les « claims » restent strictement internes à la base PharmaConnect.
- **Tableau de bord / portail assureur partenaire** (fonctionnalité clé n°4 et écran dédié du cahier) : absent. Aucun écran, route ni service orienté « consultation côté assureur » n'a été trouvé.
- **Écran « Rattachement mutuelle »** (création d'adhésion) : absent en tant qu'écran dédié (cf. ASR-3).

---

### 6. Statut à ce stade

Sept constats ouverts (ASR-1 à ASR-7), dont deux critiques (ASR-1, ASR-2) qui bloquent intégralement le chemin d'écriture du module — y compris pour un back-office légitime — et trois écarts de périmètre cahier (télétransmission DSN-like, portail assureur, écran de rattachement dédié) relevant potentiellement d'un chantier différé, sur le modèle déjà retenu pour les modules FAM/HOP.

Conformément à la méthodologie validée (Règle d'or), ce rapport s'arrête à l'Étape 1. Souhaitez-vous que j'enchaîne directement sur les Étapes 2 et 3 (analyse comparative détaillée, correctifs RLS et navigation, et vérification par exécution réelle sur Postgres 16 — en appliquant par précaution la vigilance méthodologique découverte au Module 23 concernant l'ordre chronologique des migrations si `is_gsg_admin()` doit être invoqué) ?

---

## Étape 2 — Analyse comparative

### Nature de l'écart avec le cahier

Contrairement à FAM/TRI/IOT (écart de périmètre radical — le code trouvé ne construisait pas du tout la fonctionnalité cahier attendue) ou à INF/BIZ (fondation de données seule, aucun écran), ASR se situe dans la même famille que HOP : un **chantier réel mais inachevé**. La fonctionnalité d'adhésion à une mutuelle/un assureur, de consultation du contrat, et de simulation de couverture correspond authentiquement aux fonctionnalités clés n°1 et n°2 du cahier (« rattachement d'un patient à une mutuelle », « calcul automatique de la part prise en charge »). Ce qui manque n'est pas un malentendu de périmètre mais des pans entiers non construits : télétransmission (fonctionnalité clé n°3), portail assureur (fonctionnalité clé n°4 et écran dédié), écran de rattachement dédié.

### RG-ASR-01 (Critique), réexaminée à la lumière d'ASR-1/ASR-2

Le texte de la RG a deux volets : (a) le montant pris en charge est calculé selon des règles contractuelles **paramétrées en back-office**, et (b) ces règles ne sont **pas modifiables par l'officine**. Le volet (b) était déjà respecté avant tout correctif — aucune policy pharmacien n'a jamais existé sur `insurance_plans`/`insurance_companies`. Le volet (a), en revanche, était rendu impossible par ASR-1/ASR-2 : le back-office légitime (admin GSG) ne pouvait pas non plus écrire ces tables. Les correctifs de l'Étape 3 (ci-dessous) réconcilient les deux volets : `is_gsg_admin()` peut désormais paramétrer compagnies/plans/barèmes, et aucun rôle officine n'y a accès — la RG est maintenant techniquement applicable, pas seulement respectée par accident.

Le second axe de la RG (exactitude du calcul) était directement compromis par ASR-5 (`remainingLimit` toujours égal au plafond complet) — corrigé en Étape 3.

### Positionnement des écarts de périmètre restants

Aucun des trois écarts de périmètre cahier (télétransmission, portail assureur, écran de rattachement dédié) n'est un correctif de sécurité ou un bug isolé — ce sont des chantiers de construction neuve, de la même famille que HOP-4 (back-office HOP) ou D31 (fonctionnalités clés HOM manquantes). Ils sont proposés à l'arbitrage du porteur du projet plutôt que construits unilatéralement dans cette étape.

---

## Étape 3 — Sécurité & Résilience, correctifs, vérification par exécution réelle

### ASR-1 et ASR-2 — corrigés par migration corrective (modèle HOP-1)

`insurance.sql` (27/08) et `reimbursement_tracking.sql` (28/08) sont tous deux antérieurs à `public.is_gsg_admin()` (`20260829003800_admin_helpers.sql`, 29/08). Suivant le modèle de référence établi à la clôture du Module 23 (édition en place interdite quand elle romprait l'ordre chronologique de rejeu des migrations), le correctif a été livré par une nouvelle migration postérieure : `20260830049000_insurance_module_fixes.sql` —

- remplace les 5 policies `"Staff manage ..."` (`insurance_enrollments`, `pre_authorizations`, `insurance_claims`, `provider_agreements`, `reimbursement_tracking`) par `is_gsg_admin()` ;
- ajoute les policies d'écriture manquantes sur `insurance_companies` et `insurance_plans` (`is_gsg_admin()`), inexistantes jusqu'ici pour tout rôle.

Rejeu de la chaîne complète des 87 migrations (dont ce nouveau fichier) sur une base Postgres 16 strictement neuve : **ALL MIGRATIONS APPLIED SUCCESSFULLY**, sans casser l'ordre chronologique.

### Validation par exécution réelle (harnais `asr_rls_test.sql`, protocole établi depuis HOP/IOT/DSN)

23 scénarios exécutés contre une base Postgres 16 réelle (rôle `authenticated` distinct du propriétaire, RLS active, `GRANT` par défaut Supabase reproduit explicitement) : **23/23 conformes**.

- Patient P lit sa propre adhésion (1 ligne) ; patient Q (sans lien) n'y a pas accès (0 ligne) — isolation confirmée.
- Patient P ne peut ni créer (INSERT bloqué par RLS) ni modifier (`UPDATE 0`, valeur inchangée après tentative) sa propre adhésion.
- Admin GSG crée une adhésion pour Q et modifie celle de P — les deux réussissent (`INSERT 1`, `UPDATE 1`, valeur reflétée).
- Même patron vérifié sur les 4 autres tables « Staff manage » : `pre_authorizations`, `insurance_claims`, `provider_agreements`, `reimbursement_tracking` — écriture patient bloquée, écriture admin réussie, lectures patient sur ses propres lignes (policies non touchées) toujours opérationnelles.
- `insurance_companies`/`insurance_plans` : lecture publique intacte (5 compagnies, 2 plans visibles par le patient) ; patient bloqué en écriture (création de compagnie, modification du barème `coverage_details`) ; admin GSG réussit les deux (`INSERT 1`, `UPDATE 1`, barème effectivement modifié `{"default": 80, "consultation": 90}`).
- Isolation confirmée une seconde fois sur `reimbursement_tracking` (patient Q sans lien : 0 ligne).

### ASR-5 — corrigé (suivi réel de consommation)

`InsuranceService.calculateCoverage()` calcule désormais `remainingLimit` en sommant les `insurance_claims.covered_amount` de l'adhésion au statut `approved`/`partially_approved`/`paid` depuis le 1er janvier de l'année en cours, puis en soustrayant du plafond annuel (jamais négatif). Livré et déployé sur l'appareil de l'utilisateur.

### ASR-6 — corrigé (embed PostgREST)

`getEnrollmentsForPatient()`/`getEnrollment()` utilisent désormais un embed imbriqué valide (`plans:plan_id(name, companies:company_id(id, name))`, en s'appuyant sur la FK réelle `insurance_plans.company_id`) au lieu de l'indice de relation `plans!inner(...)` qui ne correspondait à rien de résoluble par PostgREST. `InsuranceEnrollment.fromJson()` mis à jour en conséquence (lecture de `plans.companies` plutôt qu'un ancien champ top-level `companies`). **Non vérifiable par le harnais Postgres brut** (spécifique à PostgREST/Supabase-js), même limite documentée pour C48/C60/C106. Livré et déployé sur l'appareil de l'utilisateur.

### ASR-3 — corrigé (écran de création réel + route)

Sur instruction explicite du porteur du projet, ce point n'est plus proposé à l'arbitrage mais résolu directement. Deux volets :

- **Route** : `app_router.dart` déclare désormais `GoRoute(path: '/insurance/enroll/new', ...)` **avant** `/insurance/enroll/:id` (même patron que `/triage/new` vs `/triage/:id`, `/business/company/new` vs `/business/company/:id`, etc. — motif de shadowing go_router déjà rencontré et corrigé à de multiples reprises dans ce fichier, notamment lors du balayage transverse C69 du Module 18). Le bouton « Nouveau contrat » n'atterrit donc plus sur `EnrollmentDetailScreen` avec un id littéral `'new'` (UUID invalide).
- **Écran** : nouveau fichier `enrollment_form_screen.dart` (`EnrollmentFormScreen`) — formulaire réel (`Form` + `TextFormField` validés), s'appuyant sur `InsuranceProvider.saveEnrollment()` → `InsuranceService.createEnrollment()`, déjà présents dans le code mais jusqu'ici inatteignables depuis l'UI. Champs : patient (UUID), plan (UUID), n° police (requis), n° adhérent, dates de début/fin, taux de couverture, plafond annuel, notes. À la création réussie, navigation vers `/insurance/enroll/{id}` (écran de détail), même patron que `recall_create_screen.dart`.

**Limite assumée, consignée au registre plutôt que masquée** : ni le patient ni le plan ne disposent d'un sélecteur dédié — recherche exhaustive confirmée, aucun composant de sélection de patient n'existe nulle part ailleurs dans le codebase (les sélecteurs `professionals`/`hospitals` ne portent que sur un professionnel ou un établissement), et aucun modèle/service `InsurancePlan` client n'existe pour peupler un sélecteur de plan par compagnie (seule la table `insurance_plans` existe côté base — l'app ne l'a jamais consommée en tant que ressource propre). Construire ces deux sélecteurs est un chantier UI (et pour le second, data-layer) à part entière, distinct d'un correctif de routage — saisie par identifiant UUID en attendant, chemin d'écriture désormais réel et sécurisé (`is_gsg_admin()`, validé par le harnais Postgres 16 de l'Étape 3).

### ASR-4 — corrigé (données réelles + route)

Sur la même instruction, ce point est également résolu directement plutôt que différé. Trois volets :

- **Données réelles** : `InsuranceService.getReimbursementForClaim(claimId)` (nouvelle méthode) interroge réellement `reimbursement_tracking` par `claim_id` — remplace le `ReimbursementTracking` codé en dur derrière un `Future.delayed`.
- **État provider** : `InsuranceProvider` porte désormais `reimbursementTracking`/`isLoadingReimbursement`/`reimbursementError` et `loadReimbursementForClaim()`, état dédié pour ne pas interférer avec le chargement des adhésions.
- **Écran reconnecté** : `ReimbursementStatusScreen` réécrit sur le patron déjà utilisé par `EnrollmentDetailScreen` (`context.watch<InsuranceProvider>()` + chargement en `postFrameCallback`), `widget.claimId` désormais réellement transmis à la requête.
- **Route** : `GoRoute(path: '/insurance/reimbursement/:claimId', ...)` ajoutée — l'écran, jusqu'ici inatteignable depuis nulle part dans l'application (recherche exhaustive confirmée à l'ouverture), est désormais routable.

**Limite assumée, distincte du défaut technique corrigé** : cet écran reste sans point d'entrée dans le parcours applicatif (aucune liste de sinistres/réclamations n'existe côté client pour obtenir un `claimId` et naviguer ici) — ce n'est pas un oubli de ce correctif mais le même écart de périmètre cahier déjà identifié à l'Étape 1/2 (absence d'écran de rattachement dédié / suivi des sinistres), qui reste à l'arbitrage ci-dessous. La route et les données sont désormais réelles ; le chemin pour y arriver reste à construire.

**Validation** : aucune policy RLS nouvelle n'est introduite par ASR-3/ASR-4 — les deux s'appuient exclusivement sur des chemins déjà couverts par le harnais réel de l'Étape 3 (`asr_rls_test.sql`, 23/23) : écriture admin sur `insurance_enrollments` (scénario « Admin GSG crée une adhésion pour Q », directement équivalent à ce qu'exécute désormais `EnrollmentFormScreen`) et lecture/isolation sur `reimbursement_tracking` (patient P/Q). Correctifs vérifiés par relecture de code (aucun compilateur Dart/Flutter disponible dans cet environnement — limite déjà documentée aux Modules 10/19/24 précédents, ex. A19/A24/A26/A27) plutôt que par nouvelle exécution Postgres, puisqu'aucun nouveau comportement RLS n'est en jeu.

### ASR-8 (découverte en cours de correctif ASR-3) — corrigé : `copyWith` manquant, bloquant la compilation du module

Défaut non répertorié à l'ouverture, découvert en préparant le correctif ASR-3 : `InsuranceService.createEnrollment()` et `updateEnrollment()` appellent tous deux `enrollment.copyWith(...)` — or `InsuranceEnrollment` (`insurance_enrollment.dart`) ne définissait aucune méthode `copyWith`. En Dart, statiquement typé, ceci n'est pas une simple erreur à l'exécution mais un **défaut de compilation** : le fichier `insurance_service.dart` ne pouvait pas compiler tel quel, ce qui aurait bloqué la compilation de l'application entière (pas seulement du module Assurance), indépendamment de toute correction RLS. Ni le harnais Postgres 16 (qui teste du SQL brut, pas du Dart) ni aucun compilateur Flutter (non disponible dans cet environnement) n'auraient pu détecter ce défaut par les moyens déjà mobilisés dans cet audit — il n'a été repéré qu'en lisant intégralement le fichier pour préparer ASR-3.

**Corrigé** : ajout de `InsuranceEnrollment.copyWith()`, signature calquée sur le patron déjà utilisé par `ReimbursementTracking.copyWith()` dans ce même module (tous les champs, `??` sur `this.<champ>`).

**Portée méthodologique à consigner au registre** : cette découverte suggère que des défauts de compilation Dart similaires (méthode manquante, signature incompatible, import cassé au sens du compilateur plutôt que du seul routage) pourraient exister ailleurs dans les ~36 modules déjà audités sans qu'aucun ne les ait révélés — la méthodologie de cet audit (inspection de code + tests Postgres réels + traçage logique) ne constitue pas une preuve de compilabilité. Une vérification `flutter analyze`/`dart compile` complète, hors du périmètre de cet environnement, reste recommandée avant toute mise en production.

### ASR-7 — correctif préparé, non appliqué (sur instruction explicite)

Conformément à l'instruction reçue (« préparer » sans nécessairement appliquer), le correctif de navigation est rédigé ci-dessous mais **non déployé** sur le fichier `dashboard_screen.dart` — l'exposition en menu reste, comme pour les 21 occurrences précédentes du motif D6, une décision habituellement tranchée à la clôture du module, en même temps que les écarts de périmètre cahier ci-dessous.

Entrée prête à insérer dans `_effectiveNavItems()` (`dashboard_screen.dart`), à la suite de l'entrée « Établissements de santé » :

```dart
// Audit Module 24 (ASR), Étape 2/3 (30/08/2026) : 22ème occurrence du motif
// D6 — le module `insurance` (adhésion à un tiers-payant, consultation du
// contrat, simulateur de couverture, création de contrat, suivi de
// remboursement ; routes /insurance, /insurance/staff,
// /insurance/enroll/new, /insurance/enroll/:id,
// /insurance/reimbursement/:claimId) n'a aucune entrée de menu. Aucun rôle
// "insurance_staff" dédié côté schéma — comme pour Famille/Établissements
// de santé ci-dessus, entrée exposée à tout rôle authentifié (le volet
// staff n'a de sens que pour un compte is_gsg_admin(), non identifié par
// UserRole dans ce menu).
const SidebarNavigationItem(
  label: 'Assurance & Tiers-payant',
  icon: Icons.health_and_safety,
  route: '/insurance',
),
```

### Points restant à trancher avant clôture (révisé)

- **Écarts de périmètre cahier** (télétransmission des feuilles de soins, portail/tableau de bord assureur, écran de rattachement mutuelle dédié au sens du cahier) : chantiers de conception neuve, non traités ce tour, inchangés depuis l'Étape 2.
- **Absence de point d'entrée vers `ReimbursementStatusScreen`** dans le parcours applicatif (pas de liste de sinistres côté client) — même famille que le point précédent, précisée à ASR-4 ci-dessus.
- **Sélecteurs patient/plan de `EnrollmentFormScreen`** : actuellement des champs UUID bruts, faute de composant de sélection existant à réutiliser (voir ASR-3 ci-dessus) — amélioration ergonomique, pas un défaut de sécurité ou de correction.
- **ASR-7** : correctif de navigation rédigé et prêt, non appliqué — à trancher avec les points ci-dessus.
- **Portée de la découverte ASR-8** : recommandation de vérification `flutter analyze` complète hors du périmètre de cet environnement (voir ASR-8 ci-dessus).

Module non encore scellé — Étapes 2 et 3 livrées, ASR-1 à ASR-6 et ASR-8 corrigés et déployés sur l'appareil de l'utilisateur, ASR-7 préparé. En attente d'arbitrage du porteur du projet sur les points ci-dessus pour sceller et clôturer le Module 24.

---

## Clôture — arbitrage du porteur du projet (30/08/2026)

**Scénario retenu : « Valider les correctifs techniques et différer les chantiers lourds », avec exposition immédiate en navigation** — même logique que la clôture du Module 23 (HOP), avec une différence notable : ASR-3 et ASR-4, initialement proposés à l'arbitrage à l'issue de l'Étape 3, ont été résolus directement sur instruction explicite du porteur du projet avant cette clôture (voir §Étape 2/Étape 3 révisé ci-dessus) plutôt que différés.

### Écarts de périmètre cahier (télétransmission, portail assureur, écran de rattachement/liste de sinistres dédié)

**Option retenue : différer ce chantier à une phase ultérieure.**

Motivation du porteur du projet : ces fonctionnalités lourdes (portail assureur externe, télétransmission aux normes de santé) dépassent le cadre d'un correctif d'audit et nécessitent une spécification produit dédiée — même logique que pour les écarts de périmètre des Modules 16 à 23 (D28/D29/D31/D32/D34/D36/D37/D39). Documentées et inscrites au backlog produit. **Consigné sous le ticket D41.**

### Exposition en navigation (ASR-7, motif D6, 22ème occurrence)

**Option retenue : exposer immédiatement `/insurance` au menu principal.**

Motivation : la route `/insurance` et le formulaire de création sont désormais fonctionnels et sécurisés par les 23 tests RLS réels (ASR-1/ASR-2), et ASR-3/ASR-4 rendent l'adhésion et le suivi de remboursement réellement opérationnels. **Corrigé** : une entrée « Assurance & Tiers-payant » ajoutée à `dashboard_screen.dart`, exposée à tout rôle authentifié, sur le même modèle que Famille/Établissements de santé. Livrée et committée sur l'appareil.

*Note de cohérence du registre* : le rapport d'audit Étape 1 comptait par erreur ce point comme la « 23ème occurrence » du motif D6 ; la séquence réelle, incrément par incrément depuis le Module 16 (16ème à 21ème occurrence pour Hospitals/Module 23), place ce module au 22ème rang. Corrigé dans le commentaire du code et dans ce rapport — le prochain module à exposer une entrée de menu sera donc le 23ème.

### Ergonomie des sélecteurs patient/plan (`EnrollmentFormScreen`)

**Option retenue : conserver la saisie UUID temporaire, différer l'écran de recherche UI.**

Motivation : aucun composant de sélection/recherche d'utilisateurs ou de plans n'existe dans le codebase actuel (confirmé par recherche exhaustive, voir ASR-3 ci-dessus) — la saisie UUID débloque techniquement et en sécurité le flux de création (chemin d'écriture validé par les 23/23 tests réels). L'amélioration ergonomique (menu déroulant/autocomplétion) sera traitée lors d'un ticket de refonte UX transversale. **Consigné sous le ticket D42.**

### Résumé des actions de clôture

- **Correctifs BDD & Client validés par 23/23 tests Postgres 16** : ASR-1/ASR-2 (migration corrective `is_gsg_admin()` sur 7 tables/policies), ASR-5 (calcul réel du plafond restant), ASR-6 (embed PostgREST corrigé, non vérifiable par le harnais brut).
- **Correctifs fonctionnels résolus directement (sur instruction explicite), vérifiés par relecture de code** : ASR-3 (écran de création + route), ASR-4 (données réelles + route), ASR-8 (défaut de compilation `copyWith` manquant, découvert en cours de correctif).
- **Navigation** : intégration de la route `/insurance` au menu principal (`dashboard_screen.dart`), livrée et committée.
- **Tickets enregistrés au registre** : D41 (écarts de périmètre cahier — télétransmission, portail assureur, écran de rattachement dédié — dette différée), D42 (ergonomie des sélecteurs patient/plan, dette différée).
- **PV de recette** : `PharmaConnect_Module24_PV_Recette.md`.

**Le Module 24 (ASR — Assurance santé & Tiers-payant) est officiellement clos, scellé et validé.**

---

**Passation au Module 25.** Numérotation à confirmer contre la table officielle du cahier avant ouverture de l'Étape 1.
