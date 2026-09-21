# PharmaConnect — Audit Module 27 (REG — Module Régulateur & Reporting Pharmacovigilance)

**Étape 1 — Inspection & rapport de situation**
**Date : 05/09/2026**

---

## 1. Périmètre couvert (rappel cahier)

**Module 27 — REG — Module Régulateur & Reporting Pharmacovigilance.** Critique — Conformité.

**Objectif (cahier) :** offrir au Ministère de la Santé et de l'Hygiène Publique, à la DNPM et à l'Ordre National des Pharmaciens une interface de supervision proportionnée, cohérente avec la digitalisation et la meilleure traçabilité des officines.

**Fonctionnalités clés (cahier) :**
- Cartographie en temps réel des officines actives et de leur statut d'agrément.
- Remontée agrégée et anonymisée des signalements de pharmacovigilance et de produits suspects.
- Statistiques de disponibilité des médicaments essentiels par région.
- Canal de diffusion officiel des alertes de rappel de lots vers l'ensemble des officines partenaires.

**Écrans principaux (cahier) :** Tableau de bord régulateur, Carte des officines et de leur statut, Diffusion d'une alerte de rappel.

**Règles de gestion :**
> **RG-REG-01 (Critique)** — Une alerte de rappel de lot diffusée par le régulateur est propagée automatiquement à toutes les officines détenant ce lot, avec blocage immédiat de sa vente.
> **RG-REG-02 (Critique)** — Les données transmises au régulateur respectent le secret médical et ne comportent aucune donnée nominative de patient sans base légale explicite.

---

## 2. Constat général

Numérotation confirmée contre la table officielle du cahier (`project_search` : 27 = REG). Le code trouvé sous `lib/modules/regulator/` (7 fichiers) ne couvre qu'**une seule** des quatre fonctionnalités clés du cahier — le signalement individuel de pharmacovigilance — et le fait sous une forme qui **contredit directement RG-REG-02** : les rapports individuels restent nominatifs (patient et déclarant identifiés), sans agrégation ni anonymisation, alors que le cahier exige explicitement une « remontée **agrégée et anonymisée** ». La migration du module (`20260827006500_regulator.sql`) définit 4 tables, mais **3 sur 4 sont totalement orphelines** — aucun fichier Dart du projet ne les référence. La RLS du module reproduit intégralement le motif « rôle inatteignable » déjà rencontré dans plus de dix modules précédents, ici sous une forme particulièrement sévère : les 4 policies de gestion réservées au régulateur/admin ne peuvent **jamais** être satisfaites, sur les 4 tables à la fois. Un défaut de compilation certain (import manquant) a également été trouvé.

---

## 3. Inventaire du code trouvé

**Dossier `lib/modules/regulator/`** — 7 fichiers : 1 modèle (`adverse_reaction.dart`), 1 provider (`regulator_provider.dart`), 1 service (`regulator_service.dart`), 3 écrans (`adverse_reactions_list_screen.dart`, `adverse_reaction_detail_screen.dart`, `adverse_reaction_report_screen.dart`), 1 widget (`adverse_reaction_card.dart`). Aucun tableau de bord régulateur, aucune carte des officines, aucun écran de diffusion de rappel, aucun écran de statistiques.

**Migration** : `20260827006500_regulator.sql` — 4 tables : `adverse_reactions` (seule consommée par du code Dart), `product_recalls`, `regulatory_inspections`, `marketing_authorizations` (les trois dernières : recherche exhaustive dans tout `lib/`, **aucune** référence Dart nulle part dans le projet — orphelines).

**Routage (`app_router.dart`, vérifié par lecture directe)** : `/regulator` (liste), `/regulator/staff` (liste, `isRegulator: true`), `/regulator/report`, `/regulator/:id` — 4 routes, déjà réordonnancées pour éviter le shadowing go_router (commentaire d'audit référençant explicitement le balayage C69 du Module 18/HOM, déjà appliqué ici — pas une régression).

**Menu de navigation** : confirmé absent de `dashboard_screen.dart` (recherche du mot « regulator » et de variantes — aucune occurrence) — motif D6, **25ème occurrence**.

**Point de recoupement notable** : un dossier `lib/modules/recall/` distinct et beaucoup plus riche (15 fichiers, sévérité Classe I/II/III, statut par lot affecté, diffusion publique) existe déjà dans le projet et porte la fonctionnalité réelle de diffusion de rappel — mais il correspond au **Module 30 (RCL — Gestion des rappels de lots)**, pas à REG, et a déjà été partiellement examiné lors de la clôture du Module 12 (TRC, 29/08/2026) sans audit complet dédié (registre, **D23**). La table `product_recalls` de la migration `regulator.sql` (orpheline, ci-dessus) est un **second mécanisme de rappel entièrement distinct et mort**, sans aucun rapport avec la table `recalls` réellement utilisée par `recall/` — à ne pas confondre, et à noter pour la coordination future avec l'ouverture du Module 30.

---

## 4. Défauts trouvés à l'ouverture

### REG-1 — Motif « rôle inatteignable », sur les 4 tables du module à la fois (Critique)

Les 4 policies de gestion réservée de `20260827006500_regulator.sql` testent :
```sql
exists (
  select 1 from public.profiles
  where id = auth.uid() and role in ('admin', 'regulator')
)
```
Or la contrainte CHECK de `public.profiles.role` (`20260827000200_profiles.sql`) n'autorise que `'patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel', 'regulateur'` — ni `'admin'` (le personnel back-office GSG est modélisé séparément, table `public.admin_users`, testé par le helper déjà existant `public.is_gsg_admin()`) ni `'regulator'` (orthographe anglaise ; la valeur réelle est `'regulateur'`, en français) ne peuvent jamais correspondre. **Conséquence : aucun compte, quel que soit son rôle réel, ne peut jamais lire ni gérer `adverse_reactions`/`product_recalls`/`regulatory_inspections`/`marketing_authorizations` par la voie destinée au régulateur/à l'administration** — seules les policies étroites (« patient/professionnel voit ses propres signalements ») restent atteignables. C'est la 4ème table du projet touchée par ce motif au sein d'une seule et même migration (même convention de comptage qu'établie aux Modules 10-12), et la première fois que la totalité des tables d'un module est simultanément et intégralement bloquée en écriture/lecture-étendue pour le rôle auquel le module est censé servir en premier lieu.

### REG-2 — Défaut de compilation certain : `SupabaseService` utilisé sans import

`adverse_reaction_detail_screen.dart`, ligne 54 :
```dart
final isRegulator =
    reaction.reporterId != SupabaseService().currentUser?.id;
```
Aucun `import 'package:pharma_connect/core/services/supabase_service.dart';` dans ce fichier (imports vérifiés en tête de fichier : flutter/material, go_router, provider, kernel_badge, colors, typography, primary_button, glass_card, regulator_provider — pas de supabase_service). Identifiant non résolu, défaut de compilation certain — même famille que C71/C75 (Module 18/HOM, où ce motif précis était déjà apparu 3 fois dans un seul module).

### REG-3 — Miroir du motif CHN-6/PRE-6 : un calcul de rôle qui n'en est pas un

Deux occurrences distinctes dans ce module :

1. `adverse_reaction_detail_screen.dart` ligne 53-54 (citée ci-dessus) : `isRegulator` est déterminé par « je ne suis pas l'auteur de ce signalement », pas par une vérification de rôle réelle. Cette confusion contrôle l'affichage des actions de gestion (Prendre en charge/Investigation/Clore/Rejeter).
2. `AdverseReactionsListScreen(isRegulator: true)`, câblé en dur dans la déclaration de route `/regulator/staff` (`app_router.dart`) — un paramètre de **route**, jamais calculé depuis le rôle réel de l'utilisateur connecté (`AuthProvider`). N'importe quel compte authentifié qui navigue vers `/regulator/staff` reçoit l'affichage « vue staff » (masque le bouton Signaler), indépendamment de son rôle réel — aujourd'hui sans conséquence sur les données réellement chargées (RLS cassée par REG-1 les limite de toute façon aux signalements propres), mais un affichage trompeur qui deviendrait un vrai problème de contrôle d'accès applicatif dès que REG-1 est corrigé, si rien d'autre n'est fait.

### REG-4 — Trois tables sur quatre entièrement orphelines

`product_recalls`, `regulatory_inspections`, `marketing_authorizations` : recherche exhaustive (`grep` sur les 3 noms de table dans tout `lib/`) confirmant zéro référence Dart. Ces trois tables correspondent directement à 3 des 4 fonctionnalités clés du cahier (cartographie/agrément via une notion d'établissement, diffusion de rappel, autorisations de mise sur le marché) — le schéma anticipait une construction qui n'a jamais eu lieu côté application.

### REG-5 — RG-REG-02 non respectée par construction : aucune anonymisation ni agrégation

Le cahier demande une « remontée **agrégée et anonymisée** » des signalements, et RG-REG-02 interdit toute donnée nominative de patient transmise au régulateur sans base légale explicite. Or `RegulatorService.getAdverseReactions()` retourne systématiquement, via jointure PostgREST (`patients:patient_id(full_name)`, `reporters:reporter_id(full_name)`), le nom complet du patient et du déclarant pour **chaque signalement individuel** — aucune étape d'agrégation, aucun mode anonymisé, aucune vérification de base légale avant affichage. Dès lors que REG-1 serait corrigé (accès régulateur effectivement rendu possible), un compte régulateur verrait l'identité complète de chaque patient concerné, en contradiction directe avec la lettre du cahier et de la RG.

### REG-6 — Motif D6, 25ème occurrence

Confirmé par recherche du mot « regulator » (et variantes) dans `dashboard_screen.dart` : aucune entrée de menu pour `/regulator`.

---

## 5. Observations de périmètre (non-défauts, à ce stade)

- **Écran « Signalement individuel » (fonctionnalité clé n°2, volet non-anonymisé)** : construit, routé, fonctionnellement correct côté formulaire (validation complète, tous les champs de la migration couverts) — seul son mode de consultation régulateur pose problème (REG-1, REG-5), pas la collecte elle-même.
- **Écarts de périmètre cahier confirmés absents** : cartographie des officines/statut d'agrément, statistiques de disponibilité régionale, canal de diffusion officiel des rappels, et les 2 écrans principaux correspondants (Tableau de bord régulateur, Carte des officines) — à confirmer définitivement (recherche déjà large mais pas exhaustive module par module) et à qualifier en Étape 2.
- **Chevauchement avec le futur Module 30 (RCL)** : la fonctionnalité de diffusion de rappel attendue par REG (fonctionnalité clé n°4, RG-REG-01) et le module `recall/` (déjà découvert et partiellement sécurisé lors de la clôture du Module 12/TRC, D23) se recoupent largement dans le cahier lui-même (RG-REG-01 et RG-RCL-01 décrivent la même mécanique de blocage automatique). Point à trancher explicitement à l'ouverture du Module 30, pas ce tour — non traité ici.
- **`admin_users`/`is_gsg_admin()` comme référence de correction** : contrairement à plusieurs modules précédents où ce helper devait être créé, il existe déjà et est directement réutilisable pour corriger REG-1, de même qu'un test direct sur `profiles.role = 'regulateur'` (orthographe correcte) pour la casquette régulateur proprement dite — pas de nouvelle fonction à inventer.

---

## 6. Statut à ce stade

Six défauts identifiés (REG-1 à REG-6) : un motif RLS critique bloquant intégralement les 4 tables du module pour le rôle même qu'il est censé servir, un défaut de compilation certain, un motif de contrôle d'accès client déjà rencontré deux fois (CHN-6/PRE-6) sous deux formes distinctes dans ce seul module, trois tables orphelines correspondant à l'essentiel du périmètre cahier non construit, une non-conformité de fond à RG-REG-02 (absence totale d'anonymisation), et la 25ème occurrence du motif de navigation D6. Aucun correctif n'a été appliqué à ce stade, conformément à l'instruction reçue — ce rapport constitue le diagnostic complet de l'Étape 1.

**Confirmez-vous ce diagnostic et donnez-vous le feu vert pour engager les Étapes 2 (Analyse comparative) et 3 (Sécurité & Résilience, correctifs vérifiés par exécution réelle) du Module 27, ou souhaitez-vous d'abord trancher certains points (notamment le périmètre à corriger — signalement nominatif uniquement, ou également une étape d'anonymisation pour RG-REG-02 — et la question du chevauchement avec le futur Module 30/RCL) ?**

---

## 7. Étape 2 — Analyse comparative

**Feu vert reçu du porteur du projet** (confirmation explicite du diagnostic Étape 1, roadmap Étapes 2/3 validée point par point).

### 7.1 Écart avec le cahier — synthèse avant/après

| Exigence cahier | État à l'ouverture | État après correctif |
|---|---|---|
| RG-REG-01 (propagation + blocage vente) | Hors périmètre réel du module (mécanique portée par `recall/`, cf. §3 et §9 ci-dessous) | Inchangé — décision de périmètre explicite, voir §9 |
| RG-REG-02 (aucune donnée nominative sans base légale) | Violée par construction (REG-5) : jointures nominatives systématiques, aucun mode agrégé | Respectée : vue `adverse_reactions_anonymized` (aucune colonne nominative), seule source de données autorisée pour un compte `'regulateur'` |
| Fonctionnalité clé n°2 (remontée agrégée et anonymisée) | Absente | Couverte par la vue anonymisée + écran auto-adapté (mode régulateur) |
| Cartographie officines/statut d'agrément | Absente | Toujours absente — hors périmètre du correctif REG (aucune table dédiée dans ce module ; recoupe la gestion d'officines déjà couverte ailleurs dans le projet, non repris ici) |
| Statistiques de disponibilité régionale | Absente | Toujours absente — hors périmètre (aucune donnée de stock régional n'est portée par ce module ; dépendrait d'un rapprochement avec le module stock, non demandé dans la roadmap validée) |
| Canal de diffusion des rappels | Portée par `product_recalls` (orpheline) | RLS corrigée par cohérence, aucune UI reconstruite — décision explicite, voir §9 |
| Inspections réglementaires (implicite, table dédiée) | Table orpheline (REG-4) | Fonctionnalité complète (RLS + modèle + service + provider + 3 écrans) |
| Autorisations de mise sur le marché (implicite, table dédiée) | Table orpheline (REG-4) | Fonctionnalité complète (RLS + modèle + service + provider + 3 écrans), lecture publique des AMM approuvées préservée |

### 7.2 Dette technique résiduelle assumée

- **Cartographie des officines/statut d'agrément et statistiques de disponibilité régionale** : ces deux volets du cahier ne correspondent à aucune table de la migration `regulator.sql` et n'ont donc pas de support de données dans ce module. Les construire supposerait soit une nouvelle migration (hors du plan validé, qui portait sur les correctifs RLS/UI des tables existantes), soit un rapprochement avec des données déjà exposées ailleurs (pharmacies, stock). Signalé comme écart de périmètre cahier non traité — nouveau ticket D (voir §11) plutôt que construction hors mandat.
- **`product_recalls`** : RLS corrigée pour cohérence (REG-1), mais aucune UI n'est reconstruite dessus — décision motivée en §9.

### 7.3 Pour/contre des choix d'implémentation retenus

- **Vue `adverse_reactions_anonymized` avec garde `WHERE` interne** (plutôt qu'un simple `GRANT` sur une vue non filtrée) : *pour* — seul moyen de garantir RG-REG-02 au niveau base de données plutôt que par un filtrage applicatif contournable via l'API PostgREST ; *contre* — introduit une dépendance supplémentaire entre la vue et les helpers `is_gsg_admin()`/`is_regulator()`, à maintenir en cohérence si ces fonctions évoluent.
- **Suppression complète de `/regulator/staff` et du paramètre `isRegulator`** (plutôt que de le corriger en place) : *pour* — élimine définitivement le motif « miroir client » pour ce module, l'écran s'auto-adapte au rôle réel et reste correct quelle que soit la route d'entrée ; *contre* — supprime une route nommée qui aurait pu être utilisée par un lien externe déjà distribué (jugé peu probable : aucune référence trouvée ailleurs dans le projet, cf. REG-3).

---

## 8. Étape 3 — Sécurité & résilience (correctifs, validés par exécution réelle)

### 8.1 Correctifs SQL/RLS (migration `20260905060000_regulator_module_fixes.sql`)

- **`public.is_regulator()`** — nouveau helper SECURITY DEFINER, teste `profiles.role = 'regulateur'` (orthographe réelle de la contrainte CHECK).
- **REG-1** — 4 policies de gestion réécrites :
  - `adverse_reactions` : réservée à `is_gsg_admin()` (gestion de cas) — un compte `'regulateur'` n'a plus vocation à lire la table brute (RG-REG-02, voir REG-5).
  - `product_recalls`, `regulatory_inspections`, `marketing_authorizations` : `is_gsg_admin() or is_regulator()`.
- **REG-5 / RG-REG-02** — vue `public.adverse_reactions_anonymized` (aucune colonne nominative : ni `patient_id`, ni `reporter_id`, ni notes libres), avec une clause `WHERE is_gsg_admin() or is_regulator()` **au niveau de la vue elle-même** — le `GRANT select ... to authenticated` seul aurait ouvert la vue à n'importe quel compte authentifié via PostgREST ; c'est la clause `WHERE` qui fait office de rempart réel, la vue étant propriété du rôle des migrations (motif « vue security-definer »).

### 8.2 Validation par exécution réelle (Postgres 16)

Chaîne complète de 91 migrations rejouée avec succès après ajout du correctif (`run_chain.sh`, base `pharma_test` réinitialisée). Harnais dédié `reg_rls_test.sql`, 10 scénarios :

| # | Scénario | Résultat |
|---|---|---|
| 1 | Patient : ne peut PAS modifier `adverse_reactions` | OK |
| 2 | Staff GSG (`is_gsg_admin()`) : PEUT gérer `adverse_reactions` (REG-1) | OK |
| 3 | Régulateur : ne peut PAS lire `adverse_reactions` brute (RG-REG-02) | OK |
| 4 | Régulateur : PEUT lire la vue anonymisée (REG-5), volume attendu | OK |
| 5 | Vue anonymisée : aucune colonne nominative (`patient_id`/`reporter_id`/`notes` absentes du schéma de la vue) | OK |
| 6 | Patient : ne voit rien via la vue anonymisée (garde `WHERE` de la vue) | OK |
| 7 | Régulateur : PEUT gérer `regulatory_inspections` (REG-1/REG-4) | OK |
| 8 | Pharmacien (ni staff GSG, ni régulateur) : ne peut PAS gérer `marketing_authorizations` | OK |
| 9 | Régulateur : PEUT gérer `marketing_authorizations` (REG-1/REG-4) | OK |
| 10 | Lecture publique des AMM approuvées non régressée | OK |

**10/10 tests conformes.**

### 8.3 Correctifs Dart/UI

- **REG-2** — import manquant de `SupabaseService` : supprimé avec la cause elle-même (voir REG-3 ci-dessous, le calcul concerné a été remplacé, l'import n'est donc plus nécessaire).
- **REG-3 (les deux occurrences)** :
  - `adverse_reaction_detail_screen.dart` : `isRegulator` (proxy « je ne suis pas l'auteur ») remplacé par `canManage = context.watch<AuthProvider>().isGsgAdmin` — gate désormais les actions de statut **et** le bouton Supprimer (RLS ne les autorise de toute façon qu'au staff GSG).
  - Route `/regulator/staff` et paramètre de construction `isRegulator` : supprimés. `AdverseReactionsListScreen` s'auto-adapte au rôle réel (`AuthProvider`) en 3 modes : régulateur (vue anonymisée, sans navigation vers un détail nominatif), staff GSG (gestion de cas + accès rapide inspections/AMM), tout autre compte (ses propres signalements + bouton Signaler, comportement historique).
- **REG-4** — `regulatory_inspections` et `marketing_authorizations` raccordées : nouveaux modèles, extension du service (`RegulatorService`), 2 nouveaux providers (`InspectionProvider`, `MarketingAuthorizationProvider`), 6 nouveaux écrans (liste/détail/création pour chacune des deux tables), 6 nouvelles routes go_router déclarées dans l'ordre sans risque de shadowing (statique avant `:id`, `new` avant `:id` par sous-arborescence, `/regulator/:id` en dernier du groupe). Limitation connue assumée : `entity_id` (polymorphe, sans FK) saisi manuellement (validé par un motif UUID côté client), faute de sélecteur d'entité réutilisable dans ce module.
- **REG-5** — nouveau modèle `AdverseReactionAnonymized`, `RegulatorService.getAdverseReactionsAnonymized()`, état dédié dans `RegulatorProvider` (séparé de `_reactions` pour qu'un compte régulateur ne puisse jamais, même par erreur de câblage UI, se voir présenter une donnée de la table brute), carte d'affichage dédiée sans navigation vers un détail nominatif.
- **REG-6** — entrée de menu « Pharmacovigilance » → `/regulator` ajoutée à `dashboard_screen.dart` (25ème occurrence du motif D6), exposée sans filtrage par rôle comme la quasi-totalité des entrées existantes — la RLS et l'auto-adaptation de l'écran restent le rempart réel.
- **`app.dart`** — 2 nouvelles inscriptions `ChangeNotifierProvider` (`InspectionProvider`, `MarketingAuthorizationProvider`).

### 8.4 Fichiers livrés (20 fichiers, déposés sur le poste de l'utilisateur)

1 migration SQL + 3 nouveaux modèles + 1 service étendu + 1 provider étendu + 2 nouveaux providers + 1 nouveau widget + 2 écrans corrigés + 6 nouveaux écrans + routeur + menu + `app.dart`.

---

## 9. Décision de périmètre assumée : `product_recalls` non reconstruite en UI

Conformément à l'observation de périmètre notée en Étape 1 (§5) : `product_recalls` (table de la migration `regulator.sql`) est un second mécanisme de rappel, entièrement mort, distinct et sans aucun rapport avec la table `recalls` réellement utilisée par le module `recall/` (15 fichiers, sévérité Classe I/II/III, diffusion publique déjà fonctionnelle) — lequel correspond au futur **Module 30 (RCL — Gestion des rappels de lots)**. Construire une UI complète sur `product_recalls` créerait une deuxième mécanique de rappel concurrente de celle déjà en service, un risque de confusion et de double-saisie plus grave que l'absence d'écran. **Décision : seule la RLS de `product_recalls` est corrigée en Étape 2 (cohérence du module), aucune UI n'est construite dessus.** Ce choix s'écarte de la lettre littérale de l'instruction reçue (« raccordement des tables orphelines », REG-4) pour cette seule table, sur la base du chevauchement déjà documenté (D23) — signalé explicitement ici pour validation, avec un nouveau ticket D dédié (§11) recommandant la réconciliation des deux tables à l'ouverture du Module 30.

---

## 10. Clôture — Bilan du Module 27 (REG)

| Défaut | Statut |
|---|---|
| REG-1 (RLS inatteignable, 4 tables) | Corrigé, validé (tests 1-2-7-8-9) |
| REG-2 (import manquant) | Corrigé (cause supprimée) |
| REG-3 (miroir client, 2 occurrences) | Corrigé (les deux) |
| REG-4 (3 tables orphelines) | 2/3 raccordées (inspections, AMM) ; `product_recalls` : RLS seule, décision §9 |
| REG-5 (RG-REG-02 non respectée) | Corrigé, validé (tests 3-4-5-6) |
| REG-6 (menu, D6 25ème) | Corrigé |

Module 27 (REG) — Étapes 1 à 3 closes. 91 migrations validées en chaîne complète, 10/10 tests RLS réels conformes, 20 fichiers livrés.

---

## 11. Registre — nouveaux tickets

- **C133-C138** : REG-1 à REG-6 (voir tableau §10 pour le détail des statuts).
- **D46** : `product_recalls` (REG, RLS seule corrigée, aucune UI) à réconcilier avec `recalls`/module `recall/` à l'ouverture du Module 30 (RCL) — deux mécaniques de rappel distinctes portant la même exigence cahier (RG-REG-01 / RG-RCL-01).
- **D47** : cartographie des officines/statut d'agrément et statistiques de disponibilité régionale (fonctionnalités clés n°1 et n°3 du cahier pour REG) n'ont aucun support de données dans la migration `regulator.sql` — à trancher (nouvelle migration dédiée, ou rapprochement avec les modules pharmacies/stock existants) lors d'un futur arbitrage produit, hors mandat du présent correctif.
