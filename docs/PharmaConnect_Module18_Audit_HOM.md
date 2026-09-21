# PharmaConnect — Audit Module 18 (HOM — PharmaConnect HomeCare, Consultation & Soins à domicile)

**Date :** 30/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Correspondance cahier confirmée par recherche ciblée (`project_search`) : code **HOM**, priorité « Différenciant — Flagship CARE ». Le code trouvé sous `lib/modules/homecare/` couvre : 2 modèles (`intervention.dart`, `homecare_status.dart`), 1 widget (`homecare_availability_slot.dart`), 1 widget de carte (`intervention_card.dart`), 2 services (`homecare_service.dart`), 2 providers (`homecare_provider.dart`, `offline_homecare_provider.dart`), 5 écrans (`homecare_list_screen.dart`, `homecare_booking_screen.dart`, `homecare_detail_screen.dart`, `offline_homecare_screen.dart`), et la migration d'origine `20260827004000_homecare.sql`.

Fichiers inspectés en intégralité : tout le dossier `homecare/` (11 fichiers Dart), la migration d'origine, plus le précédent du Module 15 (`teleconsult_service.dart`/`teleconsult_provider.dart`/`teleconsult_booking_screen.dart`, relus pour répliquer fidèlement le motif déjà établi de remplacement d'une liste mockée par une vraie requête `professional_profiles`), le schéma exact de `professional_profiles` (`20260827005500_professionals.sql`), `app_router.dart` (balayage complet, voir §3.5), `dashboard_screen.dart`.

### 1.2 Défauts constatés

1. **4 défauts de compilation/exécution**, dont 3 occurrences du même import manquant en un seul module — voir §3.1 (C71).
2. **Nouvelle classe de bug pour cet audit** : désynchronisation entre la sérialisation Dart d'un enum et la contrainte CHECK SQL correspondante — le défaut fonctionnel le plus sévère de ce module. Voir §3.2 (C72).
3. Liste de professionnels mockée, même famille que le Module 15. Voir §3.3 (C73).
4. RG-HOM-03 non appliqué et motif de refus obligatoire (fonctionnalité clé cahier) absent. Voir §3.4 (C74).
5. **Autre nouvelle classe de bug** : dérive de schéma du cache SQLite hors-ligne, erreur avalée silencieusement. Voir §3.5 (C75).
6. Policy DELETE manquante et absence de supervision admin. Voir §3.6 (C76).
7. **Bug transverse à tout le projet** : le shadowing de route go_router (C69, Module 17) s'est révélé systémique — 16 relocalisations nécessaires dans 10+ modules. Voir §3.7 (C77), le point le plus significatif de ce module.
8. 18ème occurrence de D6 (menu de navigation).
9. Écart de périmètre cahier significatif (4 fonctionnalités clés absentes). Voir §2.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Périmètre cahier

Le cahier décrit HOM ainsi : organiser l'intervention à domicile d'un professionnel de santé, avec géolocalisation et disponibilité en temps réel. Fonctionnalités clés attendues :

1. Choix télécons/domicile **arbitré par le professionnel** (pas par le patient) au moment de la prise en charge de la demande.
2. Recherche du professionnel le plus pertinent, par spécialité, distance, disponibilité et langue, pour l'acte demandé.
3. Estimation du délai d'arrivée avec suivi en temps réel de l'approche du professionnel.
4. Acceptation ou refus de la demande par le professionnel, **avec motif obligatoire en cas de refus**.
5. Clôture par un compte-rendu structuré, versé au Dossier de Santé Numérique (DSN, Module 21).

Écrans principaux attendus : Demande de soin à domicile / Choix télécons-domicile / Suivi du professionnel en approche / Compte-rendu.

Règles de gestion :

- **RG-HOM-01** (Critique) — une demande urgente classée par TRI ne peut pas être traitée par HOM ; elle doit être bloquée ou redirigée.
- **RG-HOM-02** (Critique) — la rémunération du professionnel est indépendante du volume de prescriptions ou d'actes complémentaires réalisés (garde-fou anti-conflit d'intérêts).
- **RG-HOM-03** (Standard) — une intervention ne peut être close sans compte-rendu structuré minimal.

### 2.2 Constat

Le code réellement construit couvre une brique fonctionnelle réelle et non triviale (demande d'intervention, liste, détail, réservation, mode hors-ligne), mais aucune des 4 premières fonctionnalités clés n'y figure :

| Fonctionnalité/écran (cahier) | Constat |
|---|---|
| Choix télécons/domicile arbitré par le professionnel | 🔴 Absent — le choix est fait par le PATIENT à la réservation (`homecare_booking_screen.dart`, sélecteur statique), jamais par le professionnel |
| Recherche du professionnel le plus pertinent (spécialité/distance/disponibilité/langue/acte) | 🔴 Partiel avant correctif (liste mockée, voir C73) → 🟡 après correctif : filtre réel sur spécialité/vérification/acceptation de nouveaux patients (`getAvailableProfessionals()`), mais aucune notion de distance, de disponibilité temps réel ni de langue dans le filtre appliqué (bien que `languages_spoken` existe en base et soit remonté à l'affichage) |
| Estimation du délai d'arrivée + suivi temps réel | 🔴 Absent — aucune géolocalisation, aucun état « en approche » distinct de `confirmed`/`inProgress` dans `HomecareStatus`, aucun service de position dans `lib/core` |
| Acceptation/refus avec motif obligatoire en cas de refus | 🔴 Absent avant correctif (refus sans saisie) → 🟢 après correctif (C74) |
| Clôture par compte-rendu structuré versé au DSN | 🟡 Partiel avant correctif (compte-rendu facultatif, texte libre) → 🟡 après correctif (C74, désormais obligatoire) mais reste un champ texte libre non structuré, non relié à un DSN (le Module 21 n'existe pas encore dans le code) |

RG-HOM-01 (exclusion des urgences TRI) : aucune vérification croisée entre une demande HOM et un dossier de triage classé urgent n'a été trouvée dans `homecare_service.dart` — non applicable dans le sens où rien ne relie aujourd'hui les deux modules, mais également non protégé : rien n'empêche techniquement la création d'une demande HOM concurrente d'un dossier de triage classé urgent pour le même patient. RG-HOM-02 (rémunération indépendante des actes) : aucune notion de rémunération, de facturation ou de paiement au professionnel n'existe dans ce module — non applicable, faute de toute fonctionnalité de rémunération à laquelle l'appliquer.

### 2.3 Arbitrage

Soumis au porteur du projet (AskUserQuestion, 30/08/2026) : **« Corriger l'existant, différer le reste (Recommandé) »** — retenu. Le module de réservation/suivi/clôture existant est corrigé et sécurisé ce tour ; les 4 fonctionnalités clés manquantes (arbitrage professionnel télécons/domicile, matching multi-critères, suivi temps réel, intégration DSN) sont différées vers une future itération. Voir registre **D31**.

---

## 3. Sécurité & résilience

### 3.1 Défauts de compilation/exécution (C71)

1. `OfflineHomecareProvider._loadFromApi()` appelait `_apiService.getInterventionsForPatient(patientId)` — méthode inexistante sur `HomecareService` (la vraie méthode est `getInterventionsForUser`). Corrigé : `getInterventionsForUser(userId: patientId)`.
2. `offline_homecare_provider.dart` utilisait `SupabaseService()` sans l'importer.
3. `homecare_detail_screen.dart` — même défaut.
4. `offline_homecare_screen.dart` — même défaut. 3ème occurrence de ce motif exact en un seul module (déjà vu une fois au Module 17, `triage_detail_screen.dart`, mais jamais à cette fréquence). Corrigé : les 3 imports ajoutés.

### 3.2 Nouvelle classe de bug — désynchronisation enum Dart / contrainte CHECK SQL (C72)

`Intervention.toJson()` et `HomecareService` écrivaient `'status': status.name`. Pour la plupart des valeurs de `HomecareStatus` (`pending`/`confirmed`/`completed`/`cancelled`/`missed`), la forme camelCase de `.name` coïncide avec la forme snake_case attendue par la contrainte CHECK de `homecare_interventions.status`. Mais pour `HomecareStatus.inProgress`, `.name` retourne `'inProgress'` (camelCase strict), alors que la contrainte CHECK (migration d'origine) n'accepte que `'in_progress'`. Toute tentative de démarrer une intervention — la transition faisant passer une intervention de `confirmed` à `inProgress` — échouait donc systématiquement au niveau base, tout en compilant et s'exécutant côté client sans la moindre erreur apparente (l'appel réseau échoue, mais rien dans le code applicatif de ce module ne distinguait cet échec d'un échec réseau ordinaire). Le défaut le plus insidieux de ce module : invisible à la simple lecture du code Dart, invisible à la compilation, invisible à l'exécution sans test contre une vraie base.

Corrigé : getter `dbValue` ajouté à `HomecareStatusExtension` (`this == HomecareStatus.inProgress ? 'in_progress' : name`) et fonction top-level `homecareStatusFromDb(String value)` pour la lecture symétrique (recherche par `dbValue`, repli sur `pending` si aucune correspondance). Utilisés systématiquement partout où le statut est sérialisé/désérialisé (`Intervention.toJson/fromJson`, les 3 usages de `.name`/comparaison de statut dans `HomecareService`).

**Recommandation** : vérifier si d'autres enums du projet à valeurs composées (camelCase) sont sérialisés via `.name` brut vers une colonne CHECK snake_case ailleurs dans le projet — non balayé exhaustivement ce module, faute de périmètre.

### 3.3 Liste de professionnels mockée (C73)

`homecare_booking_screen.dart` construisait la sélection du professionnel sur une constante `_mockProfessionals` à 2 entrées, identifiants non-UUID (`pro_1`/`pro_2`) — même famille que C62 (Module 15). Toute tentative de réservation réelle contre la base aurait échoué (violation de clé étrangère `professional_id`). Corrigé en suivant fidèlement le précédent du Module 15 : `_mockProfessionals` supprimée ; `HomecareService.getAvailableProfessionals()` (nouveau) interroge `professional_profiles` avec un filtre `is_verified = true`, `is_accepting_new_patients = true`, `home_visit_fee` non nul (utilisé comme proxy de « offre des visites à domicile », faute d'un booléen dédié dans le schéma) ; `HomecareProvider.loadProfessionals()`/`professionals` ajoutés ; l'écran de réservation charge la liste réelle au premier rendu (`initState` + `addPostFrameCallback`) et affiche un état de chargement/vide/liste réelle.

### 3.4 RG-HOM-03 et motif de refus obligatoire (C74)

**RG-HOM-03** (« l'intervention ne peut être close sans compte-rendu structuré minimal ») : `updateInterventionStatus(..., completed)` acceptait un compte-rendu `null` ou vide sans aucun contrôle, ni côté service ni côté UI. Corrigé par un double garde-fou : côté UI (`homecare_detail_screen.dart`, SnackBar + blocage avant l'appel si le champ est vide) et côté service (`HomecareService.updateInterventionStatus`, `throw Exception` si `newStatus == completed` et `report` vide/absent — la barrière qui compte réellement, l'UI seule pouvant toujours être contournée par un autre client).

**Motif de refus obligatoire** (fonctionnalité clé cahier) : le bouton « Refuser » appelait directement `updateInterventionStatus(..., cancelled)` sans jamais collecter de motif — et aucune colonne dédiée n'existait même en base pour le stocker. Corrigé : colonne `refusal_reason` ajoutée (migration), boîte de dialogue à saisie obligatoire (`_showRefusalDialog`, `TextField` non vide validé avant soumission) remplaçant l'appel direct, motif désormais transmis à `updateInterventionStatus` et affiché dans le détail de l'intervention quand présent.

Un second bouton « Terminer », mort (`onPressed` vide), cohabitait avec le vrai bouton fonctionnel — supprimé au passage.

### 3.5 Nouvelle classe de bug — dérive de schéma du cache SQLite hors-ligne (C75)

`offline_sync_service.dart` définit le schéma de la table locale `interventions` à la main, indépendamment du modèle `Intervention` réel. `Intervention.toJson()` inclut désormais (et incluait déjà, en partie, avant ce module) des clés absentes de ce schéma figé — `db.insert()` levait alors `no such column`, une erreur systématiquement avalée par le `try/catch` englobant de la boucle de synchronisation dans `_loadFromApi()`/`saveIntervention()` (les deux branches). Concrètement : toute intervention réelle (dont `createdBy` — présent dans `toJson()` mais absent de la table locale — est toujours non nul) échouait silencieusement à être mise en cache, videmment le mode hors-ligne de ce module sans jamais remonter d'erreur visible à l'utilisateur ni dans les journaux applicatifs.

Corrigé par un helper `_toLocalCacheJson(Intervention)` qui filtre le JSON complet vers l'ensemble exact des colonnes réellement présentes dans la table locale, utilisé aux 3 points d'écriture du cache (`_loadFromApi()`, et les deux branches de `saveIntervention()`).

**Recommandation** : vérifier si les autres providers hors-ligne du projet (STK/ORD/RES/LIV, Modules 4/5/6/7) partagent le même risque de dérive silencieuse à mesure que leurs modèles évoluent — non balayé exhaustivement ce module.

### 3.6 Policy DELETE manquante et absence de supervision admin (C76)

`homecare_interventions` (migration d'origine) : (a) aucune policy DELETE alors qu'un bouton « Supprimer » existe réellement dans `homecare_detail_screen.dart` (réservé aux interventions terminées/annulées/non honorées) — même motif récurrent que C35/C37/C39/C41/C70a ; (b) aucune policy n'accordait de visibilité à `is_gsg_admin()`, une asymétrie avec la quasi-totalité des autres modules audités.

Corrigé par la migration `20260830045000_homecare_module_fixes.sql` : policy DELETE ajoutée (patient ou professionnel, interventions `completed`/`cancelled`/`missed` uniquement) ; policy SELECT admin ajoutée (lecture seule — un administrateur n'a pas vocation à modifier une intervention médicale à la place des parties concernées, un choix délibéré pour ne pas élargir les droits d'écriture au-delà du strict nécessaire).

### 3.7 Bug transverse à tout le projet — shadowing de route go_router systémique (C77)

En poursuivant la piste ouverte par C69 (Module 17, `/triage/:id` capturant `/triage/new`), un balayage manuel complet de `app_router.dart` a été effectué : extraction de toutes les déclarations `path: '...'` avec leur numéro de ligne, puis analyse pour chaque route à segment dynamique de l'existence d'une sœur statique de même profondeur déclarée plus loin dans le fichier (go_router évalue les routes sœurs dans l'ordre de déclaration, sans égard à leur distance dans le fichier).

Ce balayage a trouvé 14 relocalisations nécessaires (16 conflits pairwise, `/healthrecord/:id` et `/family/:id` capturant chacune plusieurs sœurs statiques) :

| Route dynamique | Route(s) statique(s) capturée(s) | Module |
|---|---|---|
| `/recall/:id` | `/recall/create` | recall |
| `/coldchain/:id` | `/coldchain/add` | coldchain |
| `/healthrecord/:id` | `/healthrecord/edit`, `/healthrecord/alerts` | healthrecord |
| `/teleconsult/:id` | `/teleconsult/book` | teleconsult (Module 15, déjà clos) |
| `/family/:id` | `/family/new`, `/family/alerts`, `/family/sos` | family |
| `/regulator/:id` | `/regulator/report` | regulator |
| `/support/:id` | `/support/new` | support |
| `/eprescription/:id` | `/eprescription/scan` | eprescription |
| `/chains/group/:id` | `/chains/group/new` | chains (hors-cahier) |
| `/iot/device/:id` | `/iot/device/new` | iot (hors-cahier) |
| `/business/company/:id` | `/business/company/new` | business (hors-cahier) |
| `/sales/customer/:id` | `/sales/customer/new` | sales (hors-cahier) |
| `/returns/customer/:id` | `/returns/customer/new` | returns (hors-cahier) |
| `/homecare/:id` | `/homecare/book` | homecare (HOM, ce module, corrigée séparément avant le balayage transverse) |

Le cas `/teleconsult/:id` vs `/teleconsult/book` est notable : ce bug existe depuis le Module 15 (CNS), déjà audité et clos, mais n'avait pas été détecté à l'époque — cette classe de défaut n'a été identifiée qu'au Module 17.

Soumis au porteur du projet (AskUserQuestion, 30/08/2026) : **« Corriger les 14 occurrences maintenant (Recommandé) »** — retenu. Les 14 relocalisations ont été appliquées (route statique déclarée avant la route dynamique correspondante), en plus de la 15ème (`/homecare/book`) déjà traitée à l'ouverture du module.

**Le balayage manuel s'est lui-même révélé incomplet.** Un script Python de vérification programmatique, écrit après coup précisément pour objectiver la couverture réelle du balayage manuel (celui-ci procédant par relecture visuelle séquentielle de l'inventaire de routes, faillible pour deux routes très éloignées l'une de l'autre dans un fichier de plus de 1300 lignes), a détecté 2 conflits supplémentaires non repérés à l'œil :

- `/stock/:id` (ligne 478) capturait `/stock/forecast` (route statique, déclarée à la ligne 1215 — loin de sa famille `/stock/forecast/orders`/`/stock/forecast/:productId`, correctement identifiée comme non conflictuelle car à 3 segments).
- `/homecare/:id` capturait `/homecare/offline` (route statique, déclarée à plus de 250 lignes de distance).

Ces 2 conflits ont été corrigés selon la même méthode (relocalisation de la route statique avant sa sœur dynamique), portant le total à **16 relocalisations, 18 conflits pairwise résolus**.

**Vérification finale** : `check_balance.py` (structure/équilibre des accolades et parenthèses du fichier complet) et le script Python de détection de shadowing (parcourt chaque route à segment dynamique, vérifie l'absence de sœur statique de même profondeur déclarée plus loin) tous deux ré-exécutés sur le fichier complet après l'ensemble des correctifs — **0 conflit restant**. Comptage de contrôle : 160 occurrences de `GoRoute(` et 160 de `path: '` (aucune déclaration orpheline issue d'une erreur d'édition), aucun nom de route dupliqué (`grep -oE "name: '...'" | sort | uniq -d` vide).

**Note de méthode** : plusieurs des relocalisations manuelles ont initialement introduit des erreurs de structure (accolade/parenthèse fermante manquante ou dupliquée) dans les modules `support`, `iot`, `business`, `sales`, `returns` — toutes détectées et corrigées par relecture immédiate de la zone éditée et par `check_balance.py`, avant la livraison finale. Cet historique renforce la recommandation ci-dessous.

**Recommandation** : ce balayage n'ayant été rendu réellement exhaustif qu'à l'aide d'un script écrit après coup, tout futur ajout de route dans `app_router.dart` devrait systématiquement être vérifié par ce même script (détection de shadowing programmatique) plutôt que par relecture manuelle seule.

### 3.8 Navigation (D6, 18ème occurrence)

Le module `homecare` n'avait aucune entrée dans le menu de navigation (`dashboard_screen.dart`). Corrigé : entrée « Soins à domicile » (icône `Icons.home_repair_service`) ajoutée, avec routage par rôle (`/homecare/professional` pour le rôle `professionnel`, `/homecare` sinon), même motif déjà établi pour Téléconsultation/Fidélité.

---

## 4. Optimisation & améliorations

- **Cohérence avec le précédent Module 15** : la nouvelle méthode `getAvailableProfessionals()` reprend délibérément la même forme de requête, de filtre et de structure de retour que `TeleconsultProvider`/`teleconsult_service.dart`, pour que les deux modules restent maintenables de façon symétrique plutôt que de diverger sur un problème identique.
- **`dbValue`/`homecareStatusFromDb`** documentés par un commentaire explicite en tête de fichier expliquant le piège (CHECK snake_case vs `.name` camelCase), pour que la prochaine personne qui ajoute une valeur à `HomecareStatus` ne réintroduise pas silencieusement le même défaut.
- **Script de détection de shadowing de route** (voir §3.7) conservé comme outil réutilisable pour tout futur audit de `app_router.dart`, plutôt qu'un usage ponctuel jetable.
- Aucune nouvelle fonctionnalité hors-périmètre cahier n'a été ajoutée ce module — l'effort a porté entièrement sur la correction et la sécurisation de l'existant, conformément à l'arbitrage du porteur du projet (§2.3).

---

## 5. Documentation API / conformité aux règles métier

**`HomecareStatusExtension.dbValue`** *(nouveau)* — mappe `HomecareStatus.inProgress` → `'in_progress'`, identité sinon. **`homecareStatusFromDb(String)`** *(nouveau, top-level)* — lecture symétrique, repli sur `HomecareStatus.pending` si aucune correspondance.

**`Intervention`** — nouveau champ `refusalReason` (`String?`), présent dans le constructeur, `copyWith`, `toJson()` (conditionnel, `if (refusalReason != null)`), `fromJson()`, et `props`.

**`HomecareService.getAvailableProfessionals()`** *(nouveau)* — `SELECT id, specialty, bio, home_visit_fee, languages_spoken, is_accepting_new_patients, profiles(full_name) FROM professional_profiles WHERE is_verified = true AND is_accepting_new_patients = true AND home_visit_fee IS NOT NULL ORDER BY specialty`.

**`HomecareService.updateInterventionStatus`** — signature étendue avec `String? refusalReason` ; garde RG-HOM-03 (`throw Exception` si clôture sans compte-rendu).

**RLS `homecare_interventions`** *(migration `20260830045000_homecare_module_fixes.sql`)* — colonne `refusal_reason` ajoutée ; policy DELETE (patient ou professionnel, statuts `completed`/`cancelled`/`missed`) ; policy SELECT admin (`is_gsg_admin()`).

**Routage** *(`app_router.dart`)* — voir §3.7 pour le détail complet des 16 relocalisations ; spécifique à HOM : `/homecare/book` et `/homecare/offline` déclarées avant `/homecare/:id`.

---

## 6. Scénarios de test (voir le protocole de test E2E dédié, `PharmaConnect_Module18_Protocole_Test_E2E.md`)

1. Compilation — priorité absolue, 4 défauts auraient empêché toute compilation.
2. Cycle de statut complet d'une intervention, en particulier la transition vers `inProgress` jusqu'en base (pas seulement côté UI) — C72, le défaut le plus insidieux de ce module.
3. Réservation avec de vrais professionnels (C73).
4. Clôture sans compte-rendu (doit être bloquée, RG-HOM-03) et refus sans motif (doit être bloqué) — C74.
5. Mode hors-ligne — mise en cache d'une intervention réelle, vérification qu'aucune erreur silencieuse ne se produit (C75).
6. RLS — DELETE (patient/professionnel sur intervention terminée) et visibilité admin (C76).
7. Routage complet — les 16 routes relocalisées, en particulier `/homecare/book`, `/homecare/offline`, `/stock/forecast`, `/teleconsult/book` (C77).

---

## 7. Livrables de ce module

Modifiés : `lib/modules/homecare/models/homecare_status.dart`, `lib/modules/homecare/models/intervention.dart`, `lib/modules/homecare/services/homecare_service.dart`, `lib/modules/homecare/providers/homecare_provider.dart`, `lib/modules/homecare/providers/offline_homecare_provider.dart`, `lib/modules/homecare/screens/homecare_booking_screen.dart`, `lib/modules/homecare/screens/homecare_detail_screen.dart`, `lib/modules/homecare/screens/offline_homecare_screen.dart`, `lib/routes/app_router.dart` (16 relocalisations transverses), `lib/modules/dashboard/dashboard_screen.dart`.
Nouveau : `supabase/migrations/20260830045000_homecare_module_fixes.sql`.
`PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A27 ; C71-C77 ; D31 ; D6 annoté d'une dix-huitième occurrence).
Ce rapport, le PV de recette provisoire, le protocole de test E2E.

---

**Le module HomeCare (HOM) est-il totalement clos et validé pour passer au suivant ?**
