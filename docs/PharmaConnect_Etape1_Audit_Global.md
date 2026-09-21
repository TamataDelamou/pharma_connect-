# PharmaConnect — Étape 1 : Audit global, règles métiers et vision
### Rapport de supervision architecturale — 28/08/2026

Sources consultées : `Cahier_de_Conception_PharmaConnect_v2.docx` (34 modules, 66 RG), `GSG_Platform_Kernel_Cahier_de_Conception_v3_0.docx` (75 KER), et dans le dépôt `PlatformGSG/pharma_connect` : `PharmaConnect_CLAUDE.md`, `REFERENTIEL_ARCHITECTE.md`, `STRUCTURE_PROJET.md`, `CLAUDE.md`, `pubspec.yaml`, ainsi qu'une inspection directe de plusieurs fichiers source (`offline_sync_service.dart`, `gsg_kernel_auth_bridge.dart`, `validators.dart`, `app.dart`, arborescence `lib/modules/`, `test/unit/providers/`).

> **Correction du 29/08/2026 (audit Module 0 — fondations transverses).** Le mapping `business → BIZ` utilisé au §4 ci-dessous était erroné. La lecture complète de la migration `business.sql` montre que ce dossier est en réalité un CRM B2B/institutionnel (hôpitaux, cliniques, grossistes, assurances), sans rapport avec le module cahier BIZ (Tableau de bord Officine). `business` est donc reclassé en hors-cahier (§4, ligne 35) ; BIZ reste un module cahier non encore identifié en code. Détail complet : rapport de clôture Module 0, `PharmaConnect_Module0_Audit_Cloture.md`.

---

## 0. Constat préalable — périmètre mouvant

Pendant cet audit, l'arborescence du dépôt a changé sous mes yeux : quatre dossiers (`cash`, `pos`, `sales`, `returns`) sont apparus avec du code réel (providers, un test) et des horodatages vieux de quelques minutes seulement — plus récents que le dernier instantané `STRUCTURE_PROJET.md` (généré le 28/08 en cours de journée). Interrogé, l'utilisateur confirme : ce sont des modules ajoutés volontairement après une recherche d'amélioration du projet, en cours de développement en parallèle de cet audit, à laisser tourner.

**Conséquence pour la méthode :** ce cluster (probablement un « Point de Vente / Caisse officine ») ne correspond à aucun des 34 modules ni aucune des 66 règles de gestion du Cahier de Conception v2.1. Il est traité au §4 comme un chantier à part, dernier de la liste, en attendant une extension formelle du cahier (nouvelles règles `RG-POS-xx`) — cohérent avec la propre discipline du projet (voir §1.5) qui interdit déjà de coder un module avant confirmation de son périmètre.

---

## 1. Audit du code existant & correctifs

### 1.1 Vue d'ensemble chiffrée (28/08/2026)

| Indicateur | Valeur |
|---|---|
| Dossiers sous `lib/modules/` | 37 : 34 modules cahier (dont BIZ non encore identifié en code — voir correction du 29/08 en tête de document) + 5 dossiers hors-cahier (`business`, `cash`, `pos`, `sales`, `returns`) |
| Fichiers `.dart` sous `lib/` | 475+ (en hausse continue) |
| Migrations SQL Supabase | 54 fichiers, 33+ tables, RLS activée partout |
| Tests provider (`test/unit/providers/`) | 34 fichiers — couvrent tous les modules cahier sauf `marketplace` ; ne couvrent pas encore `cash`, `sales`, `returns` (seul `pos_provider_test.dart` existe pour le cluster hors-cahier) |
| Écrans placeholder restants | 0 (les 18 recensés ont tous été résolus au 27/08) |
| Projet Supabase réel | Provisionné (`qemizapoldevapmygryp.supabase.co`), 15 migrations historiques appliquées et vérifiées (`migration list` local=remote) — à revérifier contre les 54 fichiers actuels, le dernier contrôle documenté datait de 15 fichiers |
| `flutter analyze` (dernier relevé documenté) | 0 erreur, ~24-27 infos de style non bloquantes |
| CI | `.github/workflows/kernel-compliance.yml` — 3 garde-fous KER-* + `flutter analyze` + `flutter test`, verte au dernier passage documenté |
| Dépôt git | Initialisé, remote GitHub privé configuré, historique par branches (fusionnées dans `main` le 27/08) |

Ce dépôt est très inhabituellement bien auto-documenté : les sessions précédentes ont tenu un journal daté, honnête (y compris sur leurs propres erreurs), avec vérification systématique (`flutter analyze`, `flutter test`, requêtes SQL directes) plutôt que des affirmations non vérifiées. C'est un actif rare à préserver — voir recommandation en §1.4.

### 1.2 Ce qui est déjà corrigé et vérifié — à ne pas rouvrir

Dix-huit corrections concrètes ont déjà été appliquées et vérifiées entre le 24 et le 27/08 (détail : `REFERENTIEL_ARCHITECTE.md` §2) :

Bugs de compilation/type bloquants (pubspec dupliqué qui empêchait tout `flutter pub get`, enum utilisant `return` — mot réservé Dart, 8 fichiers référencés par le routeur mais jamais créés, `Future<double>` qui renvoyait un `int`, `.withOpacity()` déprécié) ; anti-motifs de gouvernance Kernel (un backend OTP parallèle contournant Supabase Auth — supprimé ; un badge de statut Kernel simulé en dur — corrigé pour refléter honnêtement l'absence de connexion réelle) ; conformité KER-REF/KER-DES-03 (devise et 47 couleurs codées en dur sur 10 modèles — recentralisées via `CurrencyFormatter`/`PharmaConnectColors`, deux garde-fous CI créés) ; fiabilité (6 providers jamais enregistrés dans `MultiProvider` → crash garanti sur 20 écrans, corrigé ; `orElse` qui renvoyait un élément arbitraire au lieu de `null` sur trois services ; deux méthodes stub qui ignoraient leurs paramètres) ; persistance (`profiles` jamais réellement écrite malgré des policies RLS déjà en place — un écart classique « la policy existe, personne n'écrit dans la table » que je recommande de vérifier systématiquement module par module, voir checklist §4.2 de `REFERENTIEL_ARCHITECTE.md`).

### 1.3 Dette technique encore ouverte

1. **Dérive de gouvernance documentaire, à un rythme qui s'aggrave.** Le même travers déjà identifié et « corrigé » le 25/08 (6 modules codés hors processus, sans mise à jour de la documentation ni passage par la checklist Kernel) s'est reproduit à plus grande échelle : au moins 9 modules (`chains`, `financing`, `iot`, `marketplace`, extensions de `healthrecord`/`family`/`loyalty`/`teleconsult`/`hospitals`/`insurance`/`professionals`/`eprescription`/`homecare`/`support`/`analytics`) ont été codés entre le 27/08 soir et le 28/08 sans que `PharmaConnect_CLAUDE.md` ni `REFERENTIEL_ARCHITECTE.md` ne soient mis à jour en conséquence, et le cluster hors-cahier (`pos`/`cash`/`sales`/`returns`/`business`) s'y ajoute en ce moment même. C'est le risque n°1 de ce rapport : sans mise à jour disciplinée, cette documentation — pourtant excellente — perd sa valeur de source de vérité, exactement comme le document lui-même le prévient en tête de fichier (« ce document n'a de valeur que si l'architecte codeur le consulte avant d'ouvrir un nouveau module »). L'audit Module 0 du 29/08 (voir `PharmaConnect_Module0_Audit_Cloture.md`) a d'ailleurs mis au jour une conséquence concrète de ce rythme : plusieurs migrations SQL écrites en parallèle le 29/08 pour ce cluster contenaient des défauts systémiques qui auraient bloqué le déploiement de schéma pour l'ensemble du projet.
2. **RLS d'écriture incomplète.** Seuls `stock_items`/`stock_batches`/`stock_movements`/`stock_adjustments` (staff officine) et `deliveries`/`delivery_routes`/`route_stops`/`delivery_proofs`/`delivery_drivers` (livreur) ont des politiques d'écriture par rôle (chantier P1, 27/08). Tous les modules ajoutés depuis — `chains`, `financing`, `iot`, `marketplace`, et a fortiori le cluster `pos` — sont donc, jusqu'à preuve du contraire lors de leur audit dédié, soit inertes en écriture (RLS bloque tout), soit reposent sur des policies non documentées ici : à vérifier explicitement module par module, ne pas supposer une des deux hypothèses.
3. **Kernel GSG non branché.** `gsg_kernel_auth_bridge.dart` pointe toujours vers `https://kernel.gsg.example` (`TODO(kernel-integration)` explicite). Le patron de résilience (timeout 5s, retour `null` en silence, jamais de blocage du flux métier) est correct et exemplaire — à reproduire pour tout futur appel Kernel (Referential, bus d'événements). Mais aujourd'hui, `Org Registry`, `GSG Referential`, `Referential Engine` et le `Bus d'événements` documentés comme « Oui » dans `CLAUDE.md` racine ne sont pas réellement câblés côté produit ; seule l'authentification (Supabase Auth, avec échange best-effort vers GSG ID) est réelle.
4. **Vérification end-to-end bloquée**, pas par le code : SMS/WhatsApp indisponible sur le projet Supabase actuel, template email limité par le plan gratuit. Aucun flux d'inscription/connexion n'a encore été exercé de bout en bout par un utilisateur réel.
5. **Synchronisation hors-ligne incomplète par rapport à l'ambition du cahier.** `offline_sync_service.dart` est une file d'attente `sqflite` → Supabase fonctionnelle et bien conçue, mais elle ne couvre que trois tables du pilier CARE (`health_records`, `consultations`, `interventions`) — pas le stock d'officine (`stock_items`/`stock_batches`), pourtant explicitement identifié par le cahier (§9.3, §12 « Connectivité ») comme le cas d'usage prioritaire de l'offline-first (saisie de stock en zone à connectivité intermittente). Le cahier recommandait par ailleurs **PowerSync** ; l'implémentation actuelle est une solution maison — fonctionnellement raisonnable, mais à documenter comme un choix assumé plutôt qu'un écart silencieux (voir §3.1).
6. **`Validators.normalizeE164` suppose implicitement un seul format** (longueur minimale 12 caractères calée sur `+224` + 8 chiffres). Fonctionnellement correct tant qu'un seul pays est actif (`PhoneCountry` ne liste que la Guinée aujourd'hui), mais à généraliser avant l'extension CEDEAO (V9 de la feuille de route) plutôt qu'au moment de l'extension elle-même.
7. **Couverture de tests inégale sur les modules récents.** `marketplace` (9 fichiers) n'a aucun test provider ; le cluster `pos`/`cash`/`sales`/`returns` n'en a qu'un partiel (`pos_provider_test.dart` seul sur 4 modules). Les tests widget (14 au dernier relevé documenté) n'ont probablement pas suivi le rythme des ~20 modules ajoutés depuis — à confirmer lors de l'audit de chaque module plutôt que de supposer.
8. **Deux échecs de test volontaires (24/42 au dernier relevé)** restent attendus tant que les tests pointent délibérément sur un projet Supabase factice (`example.supabase.co`) — comportement voulu, pas une régression, mais à revérifier maintenant que le nombre total de tests a probablement augmenté avec les nouveaux modules.

### 1.4 Divergence d'architecture vs recommandation du cahier

Le Cahier de Conception (§9.1) recommande un backend modulaire **Rust** (stock, traçabilité, paiement) + **TypeScript/Node.js** (API applicative) + PostgreSQL + **PowerSync**. Le code réel est **100 % Flutter client + Supabase** (PostgREST/RLS/Auth managés) — aucun service Rust ou Node séparé n'existe dans `PlatformGSG`, aucune trace de PowerSync (remplacé par le service maison décrit en §1.3 point 5). Ce n'est pas nécessairement une erreur — Supabase peut porter une part significative de cette logique via RLS et des fonctions Postgres — mais c'est un écart architectural majeur et non documenté comme une décision assumée nulle part dans les cahiers. Je recommande de trancher explicitement ce point en fondations transverses (§4, Module 0) plutôt que de le laisser irrésolu module après module : soit le cahier est mis à jour pour refléter le choix « tout-Supabase », soit une trajectoire de migration vers des services dédiés est planifiée pour les traitements réellement critiques (moteur FEFO, calcul de traçabilité, réconciliation de paiement) qui dépassent ce qu'une RLS/fonction Postgres peut raisonnablement garantir en termes d'auditabilité et de performance à l'échelle CEDEAO.

### 1.5 Modules hors-cahier (`business`, `pos`, `cash`, `sales`, `returns`)

Confirmés par l'utilisateur comme un ajout volontaire (§0). Aucune règle de gestion `RG-POS-xx` (ni `RG-BUS-xx`) n'existe pour ce périmètre — ce qui signifie concrètement qu'il n'y a aujourd'hui aucune référence contre laquelle auditer ce code pour la conformité métier (contrairement aux 34 modules cahier, où chaque écart peut être confronté à une RG numérotée). Avant son audit formel dans la séquence module-par-module, je recommande une session dédiée pour documenter son périmètre au même niveau que les autres modules (objectif, écrans, règles de gestion numérotées `RG-POS-01...`/`RG-BUS-01...`), notamment son articulation avec `STK` (le stock est-il partagé, ou `pos` a-t-il son propre stock de caisse ?) et avec `BIZ` (le tableau de bord officine du cahier reste, à ce stade, un module sans dossier de code identifié — `business` n'en est pas l'implémentation, voir correction du 29/08 en tête de document).

---

## 2. Étude des règles métiers

### 2.1 Cadre réglementaire (résumé du cahier, §2.4)

Loi guinéenne L/2018/024/AN (création/agrément des officines sous tutelle du Ministère de la Santé, DNPM responsable de la qualité et de la surveillance de marché) ; refonte réglementaire en cours (ateliers DNPM mai 2026, appui UE/Expertise France) — le cadre légal est **mouvant**, ce qui justifie une architecture découplée (référentiel versionné, pas de règle codée en dur — cohérent avec KER-ENG-04 du Kernel). Liste nationale des médicaments essentiels (DNPM) à traiter comme source officielle du catalogue, pas reconstruite arbitrairement. Volet télémédecine/soins à domicile encadré par le cadre OMS, commercialisation à valider avec les autorités sanitaires et ordres professionnels **avant tout déploiement** — point de vigilance direct pour les modules `TRI`, `HOM`, `INF`, `CNS`.

### 2.2 Les 66 règles de gestion — statut de couverture

Le cahier définit 66 RG numérotées (`RG-AUT-01` à `RG-SEC-02`, détail complet dans le document source, section 7 « Récapitulatif »). Une vérification RG-par-RG exhaustive contre le code est le travail de l'**Étape 2 (Analyse comparative)** de chaque module, pas de cette étape globale — mais trois constats transverses ressortent déjà de l'audit documentaire :

- **RG-AUT-01** (licence officine vérifiée auprès de la DNPM avant activation) : le flux existe (`license_verification_screen.dart`), mais rien dans le code audité n'indique une vérification automatisée contre un référentiel DNPM réel — probablement un contrôle manuel/documentaire pour l'instant. À confirmer précisément lors de l'audit du module `AUT`.
- **RG-ORD-01 / RG-CNS-01 / RG-TRI-01-02 / RG-HOM-01-02** (le socle « l'IA informe, le professionnel décide », garde-fous d'urgence, non-conflit d'intérêts) : ce sont les règles les plus critiques du produit sur le plan médico-légal (cahier §12, risque « Critique »). Elles touchent aux modules `prescriptions` (OCR déjà migré vers `google_mlkit_text_recognition`), `teleconsult`, `triage`, `homecare` — tous codés récemment, donc pas encore audités en détail. Je recommande de les traiter en priorité renforcée (pas seulement dans l'ordre normal du cluster CARE) étant donné l'absence de validation réglementaire préalable mentionnée en §2.1.
- **RG-STK-01** (FEFO par défaut) : le module `stock` est codé et testé (`stock_provider_test.dart`) — la vérification du moteur FEFO réel sera le premier point de contrôle de son audit dédié.

### 2.3 Principe fondateur — statut d'implémentation observable

Le principe « IA informe, professionnel décide » (cahier §2.3, §2.6) trouve un écho architectural correct dans le code déjà audité : aucune trace, dans les corrections déjà documentées, d'une IA qui écrirait directement une décision clinique ou une commande fournisseur sans validation humaine — le patron `AuthProvider`/providers avec état exposé à l'UI plutôt qu'action automatique est cohérent avec cette exigence. Ce point sera vérifié explicitement module par module (`ORD`, `CNS`, `TRI`, `IA`/`forecasting`, `HOM`) plutôt que supposé acquis globalement.

---

## 3. Instanciation & vision plurielle

### 3.1 Architecture actuelle

- **Frontend** : Flutter/Dart unique (mobile + web + desktop via les cibles générées), Material, `provider` + `equatable`, routing `go_router` centralisé avec redirection auth-aware.
- **Backend** : Supabase (PostgreSQL managé, Auth, Storage, Realtime potentiel) — pas de Rust/Node séparé (écart documenté en §1.4).
- **Offline-first** : partiel, maison, limité au pilier CARE (§1.3 point 5) — à étendre à `STK` ou à documenter comme hors-périmètre volontaire.
- **CI/CD** : GitHub Actions, 3 garde-fous KER-* + analyse statique + tests, fonctionnels et vérifiés.
- **Sécurité** : chiffrement Supabase par défaut (repos/transit), RLS activée sur toutes les tables mais inégale en écriture (§1.3 point 2), pas encore de journal d'audit centralisé Kernel (mode dégradé).

### 3.2 Kernel GSG — état réel vs déclaré

`CLAUDE.md` racine affiche un tableau « Oui » quasi complet pour l'intégration Kernel — daté et corrigé une fois déjà (note du 25/08) pour préciser qu'il décrit l'**intention**, pas l'état du code. Au 28/08, la réalité reste : GSG ID via Supabase Auth (réel, avec échange best-effort vers un Kernel qui n'existe pas encore en production) ; Org Registry, Referential, Referential Engine, Bus d'événements — aucun câblage réel trouvé dans `lib/core/kernel/` au-delà du pont d'authentification. Ce n'est pas un problème en soi (KER-VIS-04 : un produit sans Kernel doit rester pleinement fonctionnel de façon autonome — c'est le cas), mais le tableau `CLAUDE.md` doit être corrigé pour ne plus afficher « Oui » sur des briques non câblées, au risque de tromper la prochaine personne qui s'y fie sans lire `PharmaConnect_CLAUDE.md`.

### 3.3 Fonctionnalités futures à forte valeur (rappel du cahier, à garder en tête sans les anticiper)

IA prédictive de réapprovisionnement (module `IA`/`forecasting`, actuellement le seul module cahier encore sans dossier de code), registre de traçabilité partagé (`PharmaTrace`, V8 de la feuille de route), couche Health Data agrégée, authentification portable anti-contrefaçon (partenariat matériel externe), extension CEDEAO (V9) — aucune ne doit être anticipée dans le code avant son tour dans le plan modulaire (§4), pour ne pas reproduire le travers déjà documenté en §1.3 point 1.

---

## 4. Plan de découpage modulaire strict

Ordre proposé : les 6 axes du cahier (§5 du document source) sont respectés comme structure de référence, mais l'ordre interne à chaque axe priorise ce qui a déjà du code à auditer/corriger avant ce qui reste à concevoir — cohérent avec la mission (« projet déjà bien avancé », audit avant nouvelle implémentation).

| # | Module (code cahier) | Dossier `lib/modules/` | Priorité cahier | État code |
|---|---|---|---|---|
| 0 | *Fondations transverses* | `core/`, schéma Supabase, CI | — | Existant, dette identifiée §1.3-1.4 ; corrections RLS/migrations appliquées le 29/08 (`PharmaConnect_Module0_Audit_Cloture.md`) |
| 1 | AUT | `auth` | Critique — Socle | Codé |
| 2 | REC | `search` | Critique — Cœur de valeur | Codé |
| 3 | CAT | `catalog` | Critique — Socle | Codé |
| 4 | STK | `stock` | Critique — Cœur métier | Codé |
| 5 | ORD | `prescriptions` | Haute | Codé |
| 6 | RES | `reservations` | Haute | Codé |
| 7 | LIV | `delivery` | Haute | Codé |
| 8 | PAY | `payments` | Critique | Codé |
| 9 | BIZ | *(aucun dossier identifié)* | Critique | **Clos — Non entamé** (voir `PharmaConnect_Module9_Audit_Cloture.md`, 20/09/2026) |
| 10 | ALR | `alerts` | Haute | Codé |
| 11 | TRC | `traceability` | Différenciant — Critique confiance | Codé (régression déjà documentée à revérifier) |
| 12 | RCL | `recall` | Critique — Conformité | Codé |
| 13 | CLD | `coldchain` | Différenciant | Codé |
| 14 | CHN | `chains` | Standard | Codé (récent, non audité) |
| 15 | ADM | `admin` | Critique — Socle | Codé |
| 16 | CNS | `teleconsult` (à confirmer vs HOM) | Haute | Codé (récent) |
| 17 | FID | `loyalty` | Standard | Codé (récent) |
| 18 | TRI | `triage` | Critique — Garde-fou médical | Codé — priorité renforcée (§2.2) |
| 19 | HOM | `homecare` | Différenciant — Flagship CARE | Codé (récent) — priorité renforcée |
| 20 | INF | `professionals` | Critique — Socle CARE | Codé (récent) |
| 21 | DSN | `healthrecord` | Différenciant | Codé (récent) |
| 22 | IOT | `iot` | Différenciant | Codé (très récent, non audité) |
| 23 | FAM | `family` | Différenciant | Codé (récent) |
| 24 | HOP | `hospitals` | Différenciant | Codé (récent) |
| 25 | ASR | `insurance` | Différenciant | Codé (récent) |
| 26 | PRE | `eprescription` | Différenciant | Codé (récent) |
| 27 | B2B | `marketplace` | Différenciant | Codé (récent, **sans test provider**) |
| 28 | FIN | `financing` | Différenciant | Codé (récent) |
| 29 | IA | `forecasting` | Différenciant | **Non entamé** (dossier inexistant) |
| 30 | REG | `regulator` | Critique — Conformité | Codé (récent) |
| 31 | BI | `analytics` | Standard | Codé (récent) |
| 32 | CSR | `solidarity` | Impact social | Codé (récent) |
| 33 | SAV | `support` | Standard | Codé (récent) |
| 34 | SEC | *(transverse, RLS/Kernel/audit)* | Critique — Transverse | Partiel — passe dédiée finale |
| 35 | *(hors-cahier)* | `business`, `pos`, `cash`, `sales`, `returns` | À définir | `business` (CRM B2B/institutionnel) confirmé hors-cahier lors de l'audit Module 0 (29/08) ; `pos`/`cash`/`sales`/`returns` codés en parallèle — nécessite d'abord une extension du cahier (§1.5) |

Cet ordre est une proposition ouverte à votre arbitrage — en particulier sur la place de `TRI`/`HOM`/`INF` (garde-fous médicaux, je recommande de ne pas les repousser trop loin malgré leur position dans l'axe 3 du cahier), et sur le traitement du Module 0 (fondations transverses) comme préalable obligatoire plutôt que comme un module de plus.
