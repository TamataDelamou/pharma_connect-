# PharmaConnect — Audit Module 17 (TRI — Triage & Orientation d'urgence, réservé ici au système de triage interne hospitalier réellement codé sous `lib/modules/triage/`)

**Date :** 30/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Recherche exhaustive de nom de fichier sur tout `lib/modules` (mots-clés urgence/urgent/emergency/pretriage/pre_triage/questionnaire/sos/preassess/pre_assess), via une liste récursive complète du répertoire suivie d'un filtrage `grep`, faute de pouvoir tenir l'intégralité de l'arborescence en contexte en une seule passe. **Aucun résultat pertinent** : le seul fichier matché, `lib/modules/family/screens/sos_screen.dart`, appartient à un module sans rapport (famille/aidants).

Le seul code trouvé en rapport avec le mot « triage » est `lib/modules/triage/` — 4 modèles (`triage_patient.dart`, `triage_assessment.dart`, `triage_ai_analysis.dart`, `triage_status.dart`, plus le fichier `triage_rules.dart` manquant à l'ouverture, voir §1.2), 2 providers (`triage_provider.dart`, `triage_ai_provider.dart`), 2 services (`triage_service.dart`, `triage_ai_service.dart`), 4 écrans (`triage_list_screen.dart`, `triage_new_screen.dart`, `triage_detail_screen.dart`, `triage_ai_screen.dart`), 1 widget (`triage_patient_card.dart`), et 2 migrations (`20260827004500_triage.sql`, `20260828012000_triage_ai.sql`).

Fichiers inspectés : l'intégralité du dossier `triage/` (13 fichiers Dart), les 2 migrations ci-dessus, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `app.dart`, `20260827000200_profiles.sql` pour la contrainte CHECK sur `role` et les colonnes `gsg_org_id`/`gsg_id`).

### 1.2 Défauts constatés

1. **6 défauts de compilation/exécution regroupés**, dont un fichier modèle entièrement absent malgré un usage extensif ailleurs dans le projet — le défaut le plus sévère de ce module, empêchant toute compilation. Voir §3.1 (C68).
2. **Nouvelle classe de bug pour cet audit : shadowing de route go_router.** `/triage/:id` déclarée avant sa sœur statique `/triage/new`, rendant le bouton « Nouveau patient » totalement non fonctionnel. Voir §3.2 (C69).
3. **Policy DELETE manquante** sur `triage_patients` alors qu'un bouton de suppression existe réellement dans l'UI, et **2 nouvelles occurrences du motif « rôle inatteignable »** (C49/C54/C63/C67) dans `triage_ai.sql`. Voir §3.3 (C70).
4. **Écart de périmètre majeur avec le cahier** : le questionnaire d'auto-évaluation patient décrit par TRI est entièrement absent ; le code trouvé est un système de triage interne hospitalier, hors correspondance stricte avec le cahier. Voir §2.
5. **17ème occurrence de D6** (aucune entrée de menu pour tout le module `triage` ; `TriageAIScreen` sans route ni bouton d'accès nulle part avant correctif). Voir §3.4.
6. **Dette d'architecture RLS identifiée et arbitrée** (accès non scopé par hôpital, faute d'un équivalent de `is_pharmacy_staff` côté hospitalier — les colonnes `profiles.gsg_org_id`/`gsg_id` sont structurellement NULL tant que le Kernel/Org Registry, D2, n'est pas branché). Voir §3.5.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Écart de périmètre — arbitré avec le porteur du projet

Le cahier décrit TRI (code TRI, priorité « Critique — Garde-fou médical ») ainsi : *« Distinguer, dès le premier contact du patient avec le pilier CARE, les situations relevant d'un soin à domicile, d'une consultation rapide ou d'une urgence vitale, avant toute autre action, conformément au principe de séparation stricte du circuit d'urgence retenu pour PharmaConnect. »* Fonctionnalités clés attendues : questionnaire de pré-évaluation structuré (motif, durée, douleur, fièvre, détresse respiratoire, perte de connaissance, saignement, grossesse, antécédents chroniques) ; classification automatique en trois niveaux (consultation à domicile possible / consultation rapide nécessaire / situation potentiellement urgente) ; redirection immédiate et prioritaire vers les services d'urgence en cas de signal d'alerte, sans attendre l'affectation d'un professionnel (RG-TRI-01, Critique : « Toute réponse indiquant un signe de gravité […] déclenche systématiquement l'orientation « situation potentiellement urgente », sans possibilité de contournement par l'utilisateur » ; RG-TRI-02, Critique : « Le module de triage n'affecte jamais automatiquement un professionnel dans un cas classé urgent ; il oriente exclusivement vers les services d'urgence ou une structure de soins adaptée ») ; protocoles de triage élaborés/validés avec des professionnels de santé, versionnés et auditables, revus au moins annuellement (RG-TRI-03, Standard). Écrans principaux attendus : Questionnaire de pré-évaluation / Résultat de triage avec orientation / Écran d'urgence (contacts et structures).

Recherche exhaustive de nom de fichier confirmant l'absence totale de code pour ce questionnaire patient (§1.1). Le code réellement trouvé sous `lib/modules/triage/` est un système de triage **interne à un service d'urgence hospitalier**, destiné au personnel soignant et non au patient : prise en charge d'un patient déjà arrivé physiquement aux urgences par une infirmière (`TriagePatient` — patient, infirmier, heure d'arrivée, statut, priorité 1-5, motif, symptômes, constantes vitales, service/médecin assigné), évaluation clinique structurée (`TriageAssessment` — douleur, fréquence respiratoire, fréquence cardiaque, tension artérielle, température, saturation, niveau de conscience, catégorie sur une échelle proche de l'ESI : résuscitation/urgence/urgent/semi-urgent/non-urgent), et un moteur de suggestion IA à base de règles-mots-clés réellement seedées (`TriageAIAnalysis`/`TriageRule`, 19 correspondances mot-clé→priorité/service, ex. « thoracique »→priorité 1/Cardiologie/critique, avec boucle de retour médecin pour la précision — logique réelle, pas de données factices, à la différence du Mock AI explicitement commenté du Module 15).

Vérifié et écarté explicitement comme correspondance cahier alternative : Module 23 (HOP — Intégration Hôpitaux, Laboratoires & Imagerie), dont le périmètre réel (structures partenaires, prescription d'examens de laboratoire/imagerie, RG-HOP-01/02) ne recouvre pas non plus ce code. Ce système de triage hospitalier ne correspond donc à aucun module du cahier identifié à ce jour — la même dérive de fusion déjà repérée en D26 (Module 15 : CNS/téléconsultation/pré-consultation IA mélangés) se confirme du côté opposé : un système de triage existe réellement dans le projet, mais ce n'est pas celui attendu par le cahier pour TRI.

**Arbitrage porteur du projet (AskUserQuestion, 30/08/2026), deux questions distinctes** :

- *« Corriger l'existant, différer le reste »* — le système de triage hospitalier interne trouvé est corrigé et sécurisé ce tour ; la construction du questionnaire d'auto-évaluation patient réellement décrit par le cahier (RG-TRI-01/02/03) est différée vers un futur module dédié, même logique que D24 (Module 13)/D28 (Module 16).
- *« Laisser tel quel, consigner comme dette d'architecture (Recommandé) »* — l'accès RLS non scopé par hôpital (tout compte `role='professionnel'` peut voir/modifier les dossiers de triage de n'importe quel hôpital du réseau) est laissé en l'état plutôt que corrigé sans les fondations nécessaires (l'Org Registry, D2, jamais câblé), et consigné comme dette d'architecture explicite.

Voir registre **D29** (écart de périmètre) et **D30** (dette RLS multi-hôpital).

### 2.2 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-TRI-01** (Critique) | Toute réponse indiquant un signe de gravité déclenche systématiquement l'orientation « situation potentiellement urgente », sans contournement possible | 🔴 Non applicable — aucun questionnaire patient auquel cette règle pourrait s'appliquer n'existe dans le projet (§2.1) |
| **RG-TRI-02** (Critique) | Le module de triage n'affecte jamais automatiquement un professionnel dans un cas classé urgent ; il oriente exclusivement vers les services d'urgence | 🔴 Non applicable, même motif. Noter que le système hospitalier trouvé fait précisément l'inverse par construction (affectation d'un médecin/service par une infirmière ou par suggestion IA) — cohérent avec son usage réel (gestion de flux interne aux urgences, patient déjà pris en charge), mais confirme que ce n'est pas le même concept que RG-TRI-02, qui vise le tout premier contact patient AVANT toute affectation |
| **RG-TRI-03** (Standard) | Les protocoles de triage sont revus et validés par un comité médical au moins une fois par an ou après tout incident significatif | 🔴 Non applicable — `triage_rules` (moteur IA du système hospitalier trouvé) est versionné en base (`created_at`/`updated_at`/`created_by`/`updated_by`) mais aucun mécanisme de revue/validation par un comité médical, ni aucune notion de version applicative des règles, n'existe dans le code |

### 2.3 Fonctionnalités clés et écrans principaux du cahier

| Fonctionnalité/écran (cahier) | Constat |
|---|---|
| Questionnaire de pré-évaluation structuré (motif, durée, douleur, fièvre, détresse respiratoire, perte de connaissance, saignement, grossesse, antécédents chroniques) | 🔴 Absent — aucune trace dans le code |
| Classification automatique en 3 niveaux (domicile / consultation rapide / urgence) | 🔴 Absent au sens cahier — le système trouvé classe sur une échelle clinique à 5 niveaux (ESI-like), destinée au personnel soignant, pas au patient en amont |
| Redirection immédiate vers les urgences sans affectation automatique (RG-TRI-01/02) | 🔴 Absent — voir §2.2 |
| Écran d'urgence (contacts et structures) | 🔴 Absent — aucune trace dans le code |
| *(hors cahier TRI, construit à la place)* Système de triage interne hospitalier (intake infirmier, évaluation clinique, moteur de suggestion IA à règles réelles) | 🟢 Corrigé (compilation/exécution) et sécurisé (policy DELETE, RLS « rôle inatteignable ») ce module — dette d'architecture RLS multi-hôpital consignée (D30) |

---

## 3. Sécurité & résilience

### 3.1 Défauts de compilation/exécution (C68)

1. **Fichier modèle `lib/modules/triage/models/triage_rules.dart` entièrement absent du projet** (`class TriageRule`) malgré un usage extensif dans `triage_ai_service.dart` et `triage_ai_provider.dart` — confirmé par `grep -rl "class TriageRule"` sur `lib/` ne retournant aucun résultat, et par la liste du dossier `models/` ne comptant que 4 fichiers. Le défaut le plus sévère de ce module, même famille que C38 (Module 11, code référencé mais syntaxiquement invalide/absent). Corrigé en créant le modèle complet (Equatable — id, keyword, priorityScore, department, isCritical, isActive, createdAt, updatedAt, createdBy, updatedBy, gsgId, gsgOrgId — avec copyWith/toJson/fromJson), conforme au schéma de la table `triage_rules` et à tous les sites d'usage observés.
2. `triage_detail_screen.dart` utilisait `SupabaseService()`, `TriagePatient` (comme type explicite) et `TriageAssessment` (comme constructeur) sans importer aucun des 3 fichiers source correspondants — 3 identifiants non définis dans un seul fichier. Corrigé en ajoutant les 3 imports manquants.
3. `patient.status.isPast` — accesseur inexistant sur l'extension `TriageStatus` (qui ne définit que `isActive`/`isCompleted`, confirmé par lecture complète de `triage_status.dart`). Corrigé en remplaçant par `.isCompleted`.
4. Variable `provider` non définie dans le gestionnaire de succès de `_showAssignDialog` (`triage_detail_screen.dart`). Corrigée en remplaçant par `context.read<TriageProvider>()`.
5. **Nouvelle classe de défaut pour cet audit** : `TriageAIProvider` jamais déclaré dans le `MultiProvider` racine (`lib/app.dart`) malgré `context.watch<TriageAIProvider>()` dans `TriageAIScreen` — le projet compile sans erreur, mais l'écran plante à l'exécution (`ProviderNotFoundException`) dès son premier rendu. Distinct de tous les défauts de compilation précédents (C38/C44/C59), qui empêchaient la compilation elle-même. Corrigé en ajoutant l'import et la déclaration `ChangeNotifierProvider(create: (_) => TriageAIProvider())`.
6. `triage_ai_screen.dart`, section `_buildFeedbackSection` : les sélections de dropdown (`selectedPriority`/`selectedDepartment`) étaient des variables locales à la méthode de construction, jamais liées au `State` et sans aucun appel à `setState()` dans leurs callbacks `onChanged` — le bouton de soumission du retour, dont la condition d'activation dépendait de ces variables, restait donc structurellement désactivé en permanence. Corrigé en élevant les deux variables au rang de champs `_feedbackPriority`/`_feedbackDepartment` de la classe `State`, en enveloppant les callbacks dans `setState()`, et en ajoutant une garde `context.mounted` autour du `SnackBar` post-soumission.

### 3.2 Nouvelle classe de bug — shadowing de route go_router (C69)

`app_router.dart` déclarait la route dynamique `/triage/:id` **avant** sa sœur statique `/triage/new`, au même niveau d'imbrication. go_router évalue les routes sœurs dans l'ordre de déclaration ; un segment dynamique (`:id`) capture toute chaîne de segment unique, y compris le littéral `new`. `/triage/new` était donc systématiquement intercepté par `/triage/:id` avant même d'être évalué — l'application tentait de charger un dossier de triage d'identifiant littéral `"new"`, échouant silencieusement (« Patient introuvable » ou équivalent), rendant le bouton « Nouveau patient » totalement non fonctionnel malgré un écran de création par ailleurs correct (`triage_new_screen.dart`, lu en entier, formulaire de saisie manuelle avec priorité définie via un curseur 1-5, sans connexion aux suggestions IA, aucun défaut trouvé).

Jamais rencontré dans cet audit avant ce module — une classe de bug distincte du motif « route dupliquée » déjà vu (C45/C51). Corrigé par réordonnancement : la route statique `/triage/new` déclarée avant la route dynamique `/triage/:id`. Un balayage exhaustif du reste de `app_router.dart` pour d'autres paires statique/dynamique du même préfixe n'a pas été effectué ce module, faute de périmètre — recommandé pour une prochaine passe transverse.

### 3.3 Policy DELETE manquante et récurrence « rôle inatteignable » (C70)

**Policy DELETE manquante.** `20260827004500_triage.sql` ne posait que des policies select/insert/update pour `role = 'professionnel'` sur `triage_patients` — aucune policy DELETE. `TriageService.deletePatient()` et un bouton « Supprimer » (réservé aux dossiers sortis/transférés) existent pourtant réellement dans l'UI — toute tentative de suppression aurait donc échoué silencieusement (RLS refuse par défaut toute opération sans policy permissive correspondante). Même motif exact que C35/C37/C39/C41 (migration de base incomplète en écriture), ici sur DELETE plutôt que sur INSERT/UPDATE. Corrigé (migration `20260830044000_triage_module_fixes.sql`, partie 1) par une nouvelle policy `"Nurses can delete triage patients"`, même portée que les policies existantes.

**Motif « rôle inatteignable » (C49/C54/C63/C67), 2 nouvelles occurrences.** `20260828012000_triage_ai.sql` : `"Staff manage triage AI analyses"` (`role in ('admin', 'staff', 'professionnel')`) sur `triage_ai_analyses`, et `"Staff manage triage rules"` (`role in ('admin', 'staff')`) sur `triage_rules` — mêmes valeurs impossibles que dans tous les modules précédents (`public.profiles.role` n'autorise jamais `admin`/`staff`). 6ème+ module affecté par ce motif (après Module 13 ×1, Module 14 ×2, Module 15 ×2, Module 16 ×11). La seconde policy bloquait TOUTE écriture sur `triage_rules`, y compris pour un administrateur GSG légitime. Corrigé (migration `20260830044000_triage_module_fixes.sql`, partie 2) : `is_gsg_admin() or (role='professionnel' exists-check)` pour `triage_ai_analyses` (branche professionnel préservée, un soignant doit pouvoir enrichir/corriger une analyse IA en conditions réelles), `is_gsg_admin()` seul pour `triage_rules` (un référentiel de règles de triage est une donnée de configuration back-office, pas une donnée d'usage quotidien par le personnel soignant).

**Recommandation réitérée (5ème+ fois)** : un balayage complet et unique du projet sur le motif « rôle inatteignable » serait désormais nettement plus efficace que de continuer à le découvrir module par module.

### 3.4 Navigation (D6, 17ème occurrence)

Le module `triage` entier — 4 routes fonctionnelles (`/triage`, `/triage/nurse`, `/triage/new`, `/triage/:id`) — n'avait aucune entrée dans le menu de navigation (`dashboard_screen.dart`), motif D6 habituel. Particularité aggravante par rapport aux occurrences précédentes : `TriageAIScreen` n'avait ni route déclarée dans `app_router.dart`, ni aucun bouton ou lien depuis quelque écran que ce soit du projet — un écran fonctionnel (une fois les défauts de compilation de §3.1 corrigés) mais totalement inatteignable par l'utilisateur, pire que les occurrences précédentes de D6 où la route existait au moins.

Corrigé : une entrée « Triage » (icône `Icons.emergency`) ajoutée à `_effectiveNavItems()`, suivant le même motif de routage par rôle déjà établi pour Téléconsultation/Fidélité (`/triage/nurse` pour le rôle `professionnel`, `/triage` sinon) ; une nouvelle route `/triage/:id/ai` ajoutée pour `TriageAIScreen` ; un nouveau bouton « Analyse IA » ajouté sur `triage_detail_screen.dart` (même condition de visibilité que le bouton « Évaluer » existant : `patient.status.isActive && isNurse`).

### 3.5 Dette d'architecture — RLS non scopée par hôpital (D30)

Toutes les policies du module (`triage_patients`/`triage_assessments`/`triage_ai_analyses`/`triage_rules`) autorisent tout compte `role='professionnel'` sans aucune restriction d'établissement — un professionnel de l'Hôpital A peut consulter ET modifier les dossiers de triage de l'Hôpital B. Aucun helper d'autorisation « personnel de cet hôpital » n'existe, contrairement à `is_pharmacy_staff(pharmacy_id)` (Module 1) qui scope correctement l'équivalent pour les officines depuis C66. Vérifié directement dans `20260827000200_profiles.sql` : les colonnes `profiles.gsg_org_id`/`gsg_id` (uuid, destinées à porter ce rattachement organisationnel) sont explicitement documentées dans leurs commentaires de colonne comme « Nullable TANT QUE LE KERNEL N'EST PAS BRANCHÉ » — c'est-à-dire structurellement NULL en pratique aujourd'hui, le Kernel/Org Registry (D2) n'ayant jamais été câblé.

Construire un scoping hospitalier réel aurait donc nécessité d'anticiper une brique d'infrastructure hors périmètre de ce module (l'Org Registry lui-même), à la différence de C66 qui disposait déjà du helper nécessaire. Présenté au porteur du projet plutôt qu'un correctif RLS unilatéral construit sur des fondations absentes — voir §2.1, arbitrage 2, et registre D30.

---

## 4. Optimisation & améliorations

- **`TriageAIScreen` intégrée au parcours réel** plutôt que laissée orpheline : bouton « Analyse IA » depuis l'écran de détail, cohérent avec la décision « corriger l'existant » (§2.1) — distinct du précédent Module 15/16 de « masquer, ne pas router » (D26/D28), puisque ce sous-système utilise un moteur de règles réel et non des données factices, et que le porteur du projet a explicitement choisi de corriger plutôt que différer le système hospitalier trouvé.
- **`_showTransferDialog` (`triage_detail_screen.dart`)** : confirmé être un stub vide (`// Similaire à assign`) — le bouton « Transférer » ne fait rien. Non corrigé ce module : une fonctionnalité de transfert réelle nécessiterait un modèle de données « hôpital cible » qui n'existe nulle part dans le projet (même trou de modélisation que D18/D24/D25, ici côté structures de santé plutôt qu'entités commerciales) — signalé plutôt que construit à la hâte sans les fondations nécessaires.
- **Aucun mode hors-ligne** n'a été construit ce module — cohérent avec la nature du système (prise en charge d'urgence en temps réel, un mode hors-ligne dégradé serait contre-productif pour un outil de gestion de flux d'urgence), non arbitré explicitement comme un choix documenté mais raisonnablement hors de propos pour ce type de module.

---

## 5. Documentation API / conformité aux règles métier

**`TriageRule`** *(nouveau modèle)* — id, keyword, priorityScore, department, isCritical, isActive, createdAt, updatedAt, createdBy, updatedBy, gsgId, gsgOrgId ; copyWith/toJson/fromJson conformes au schéma de `triage_rules`.

**RLS `triage_patients`** *(migration `20260830044000_triage_module_fixes.sql`, partie 1)* — nouvelle policy DELETE, même portée que select/update/insert (`role = 'professionnel'`).

**RLS `triage_ai_analyses`/`triage_rules`** *(migration `20260830044000_triage_module_fixes.sql`, partie 2)* — voir §3.3 pour le détail complet des 2 policies réécrites.

**Routage** *(`app_router.dart`)* — réordonnancement `/triage/new` avant `/triage/:id` ; nouvelle route `/triage/:id/ai` → `TriageAIScreen(triagePatientId: id)`.

**Provider** *(`app.dart`)* — `ChangeNotifierProvider(create: (_) => TriageAIProvider())` ajouté au `MultiProvider` racine.

---

## 6. Scénarios de test (voir le protocole de test E2E dédié, `PharmaConnect_Module17_Protocole_Test_E2E.md`)

1. Compilation ET premier rendu de chaque écran — priorité absolue, ce module comptait à la fois des défauts de compilation et un défaut d'exécution (`ProviderNotFoundException`) invisible à la seule compilation.
2. Routage — `/triage/new` doit atteindre l'écran de création, pas être capturé par `/triage/:id` (C69).
3. RLS DELETE — suppression d'un dossier de triage sorti/transféré par une infirmière (C70).
4. RLS « rôle inatteignable » — écriture back-office réelle sur `triage_ai_analyses`/`triage_rules` (C70).
5. Accès non scopé par hôpital — documenté comme limitation connue et acceptée (D30), à vérifier comme tel plutôt qu'à faire « échouer/réussir ».
6. Écran `TriageAIScreen` nouvellement câblé (route + bouton), formulaire de retour IA (dropdowns fonctionnels après correctif du bug d'état).

---

## 7. Livrables de ce module

Nouveau : `lib/modules/triage/models/triage_rules.dart`, `supabase/migrations/20260830044000_triage_module_fixes.sql`.
Modifiés : `lib/modules/triage/screens/triage_detail_screen.dart`, `lib/modules/triage/screens/triage_ai_screen.dart`, `lib/routes/app_router.dart`, `lib/modules/dashboard/dashboard_screen.dart`, `lib/app.dart`.
`PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A26 ; C68-C70 ; D29-D30 ; D6 annoté d'une dix-septième occurrence).
Ce rapport, le PV de recette provisoire, le protocole de test E2E.

---

**Le module Triage (TRI) est-il totalement clos et validé pour passer au suivant ?**
