# PharmaConnect — Audit Module 16 (FID — Fidélité & Suivi des traitements chroniques, réservé ici au sous-système réellement codé sous `lib/modules/loyalty/`)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Recherche exhaustive de nom de fichier sur les 36 dossiers de `lib/modules` (mots-clés chronic/chronique/renouvel/subscription/abonnement/treatment/traitement/refill/medication) : aucun dossier dédié au suivi de traitement chronique n'existe. Le seul code trouvé en rapport avec FID est `lib/modules/loyalty/` — 7 modèles (`loyalty_account.dart`, `loyalty_reward.dart`, `loyalty_transaction.dart`, `loyalty_badge.dart`, `patient_badge.dart`, `health_challenge.dart`, `personalized_reward.dart`), 5 providers (`loyalty_provider.dart`, `badge_provider.dart`, `loyalty_ai_provider.dart`, `personalized_reward_provider.dart`), 5 services (`loyalty_service.dart`, `badge_service.dart`, `loyalty_ai_service.dart`, `personalized_reward_service.dart`), 5 écrans (`loyalty_dashboard_screen.dart`, `badges_gallery_screen.dart`, `challenges_dashboard_screen.dart`, `leaderboard_screen.dart`, `personalized_rewards_screen.dart`), et 8 migrations réparties entre le 27/08 et le 28/08 (`20260827008500_loyalty.sql`, `20260828015000_loyalty_ai.sql`, `20260828016000_gamification_badges.sql`, `20260828016100_gamification_leaderboard.sql`, `20260828016200_gamification_family.sql`, `20260828016300_gamification_health.sql`, `20260828016400_personalized_rewards.sql`, `20260828016500_dashboard_customization.sql`).

Fichiers inspectés : l'intégralité du dossier `loyalty/` (20 fichiers Dart), les 8 migrations ci-dessus, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `20260827000200_profiles.sql` pour la contrainte CHECK sur `role`, `pharmacy_staff.sql` pour la structure exploitée par la faille C66).

### 1.2 Défauts constatés

1. **3 défauts de compilation distincts sur 3 fichiers.** `_client` non défini dans `LoyaltyProvider.loadAccount()` ; méthode privée `_getProgress()` appelée depuis un autre fichier (`LoyaltyAIProvider`) — même motif que C59 point 4 (Module 15) ; paramètre `TextStyle.opacity` inexistant dans `badges_gallery_screen.dart`. Détail complet en §3.1.
2. **Faille RLS critique, cross-officine — la plus sévère de tout l'audit à ce jour.** Une sous-requête corrélée mal scopée rendait 5 policies « Staff » tautologiques, ouvrant en lecture ET écriture le module fidélité de toute officine du réseau à tout membre du personnel d'une seule officine. Voir §3.2 (C66).
3. **11 occurrences du motif « rôle inatteignable »** (C49/C54/C63) rien que dans ce module (9 corrigées, 2 hors périmètre) — de loin la plus grosse récurrence de tout l'audit. Voir §3.3 (C67).
4. **2 défauts fonctionnels** : comparaison de dates non normalisée rendant une branche de recommandation IA morte (`getRecommendations()`) ; calcul de série de jours consécutifs entièrement fictif décidant de l'attribution de vrais badges — même famille que le score de crédit fictif C56 (Module 14). Voir §3.4.
5. **Écart de périmètre majeur avec le cahier** : 2 des 3 écrans principaux cahier (suivi de traitement chronique, abonnement renouvellement automatique) sont entièrement absents ; le troisième (programme de fidélité) est construit très au-delà du périmètre décrit. Voir §2.
6. **16ème occurrence de D6** (route absente du menu de navigation), avec une variante inédite : 4 des 5 écrans du module n'avaient même aucune déclaration de route dans `app_router.dart`, pas seulement une entrée de menu manquante. Voir §3.5.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Écart de périmètre — arbitré avec le porteur du projet

Le cahier décrit le Module 16 (FID) ainsi : *« Accompagner les patients sous traitement chronique (diabète, hypertension, VIH, asthme) dans le renouvellement régulier de leurs ordonnances et fidéliser la relation avec une officine de référence. »* Fonctionnalités clés attendues : rappel de renouvellement d'ordonnance chronique avant rupture de traitement, programme de fidélité avec avantages sur les produits de parapharmacie, historique de traitement consultable par le patient et, avec consentement, par un professionnel, option d'abonnement mensuel avec livraison automatique pour les traitements chroniques (RG-FID-01, Critique : « Le renouvellement automatique d'un traitement chronique ne peut être activé sans ordonnance valide couvrant la durée de l'abonnement »). Écrans principaux attendus : Suivi de traitement chronique / Programme de fidélité / Abonnement renouvellement automatique.

Recherche exhaustive de nom de fichier confirmant l'absence totale de code pour les 2 premiers écrans (aucun résultat pertinent — seul un incident, `healthrecord/widgets/medication_tile.dart`, sans rapport). Le troisième écran existe (`loyalty/`), mais construit **très au-delà** du périmètre cahier : badges, classement, défis santé, récompenses personnalisées générées par IA, objectifs/jalons santé — une plateforme de gamification complète, dont rien n'apparaît dans la section FID du cahier. RG-FID-01 est en conséquence **inapplicable** : aucune fonctionnalité d'abonnement n'existe dans le projet à laquelle cette règle pourrait s'appliquer.

**Arbitrage porteur du projet (AskUserQuestion, 29/08/2026), deux questions distinctes** :

- *« Corriger l'existant, différer le reste »* — le programme de fidélité existant est corrigé et sécurisé ce tour ; les 2 écrans cahier manquants (suivi de traitement chronique, abonnement automatique) sont consignés comme dette différée plutôt que construits dans ce tour, même logique que D24 (Module 13, B2B).
- *« Exposer le programme de fidélité de base seulement »* — seul le sélecteur d'officine → tableau de bord fidélité (`/loyalty`) est routé et exposé au patient ; la couche de gamification (badges/classement/défis/récompenses personnalisées/objectifs santé), corrigée-pour-compiler et sécurisée, reste volontairement non routée en attendant une décision produit ultérieure — même logique que D26 (Module 15, sous-système de pré-consultation IA).

Voir registre **D28**.

### 2.2 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-FID-01** | Le renouvellement automatique d'un traitement chronique ne peut être activé sans ordonnance valide couvrant la durée de l'abonnement | 🔴 Non applicable — aucune fonctionnalité d'abonnement/renouvellement automatique n'existe dans le projet (§2.1) |

### 2.3 Fonctionnalités clés et écrans principaux du cahier

| Fonctionnalité/écran (cahier) | Constat |
|---|---|
| Rappel de renouvellement d'ordonnance chronique avant rupture | 🔴 Absent — aucune trace dans le code |
| Historique de traitement consultable (patient, avec consentement pour un professionnel) | 🔴 Absent — aucune trace dans le code |
| Option d'abonnement mensuel avec livraison automatique (RG-FID-01) | 🔴 Absent — aucune trace dans le code |
| Programme de fidélité avec avantages parapharmacie | 🟡 Construit mais très étendu au-delà du cahier (gamification complète), corrigé et sécurisé ce module, exposition limitée à la base par arbitrage (§2.1) |
| *(hors cahier FID, construit à la place)* Badges, classement, défis santé, récompenses personnalisées IA, objectifs/jalons santé | 🟢 Corrigé pour compiler et sécurisé ce module — laissé volontairement non routé (arbitrage §2.1) |

---

## 3. Sécurité & résilience

### 3.1 Défauts de compilation

1. `LoyaltyProvider.loadAccount()` appelait `_client.from('loyalty_programs')...` directement — `_client` n'était défini nulle part dans `LoyaltyProvider` (`Undefined name '_client'`). Corrigé en extrayant la logique dans `LoyaltyService.getActiveProgramId(pharmacyId)`, appelée depuis le provider.
2. `LoyaltyAIProvider.generateChallenges()` appelait `_service._getProgress(...)` — méthode privée (portée de bibliothèque) d'un AUTRE fichier, inaccessible en Dart. Même motif exact que C59 point 4 (Module 15). Corrigé en renommant la méthode du service en `getProgress` (publique) et en mettant à jour le seul site d'appel interne (`updateProgress()`).
3. `badges_gallery_screen.dart` : `Text(isEarned ? badge.icon : '🔒', style: TextStyle(fontSize: 40, opacity: isEarned ? 1.0 : 0.3))` — `TextStyle` n'a aucun paramètre `opacity` en Flutter (`The named parameter 'opacity' isn't defined`). Corrigé en enveloppant le `Text` dans un widget `Opacity(opacity: ..., child: Text(..., style: const TextStyle(fontSize: 40)))`.

### 3.2 Faille RLS critique, cross-officine (C66)

`20260827008500_loyalty.sql` posait 5 policies « Staff » (`loyalty_programs`, `loyalty_accounts` ×2, `loyalty_rewards`, `loyalty_referrals`) utilisant une sous-requête corrélée :

```sql
exists (
  select 1 from public.pharmacy_staff
  where user_id = auth.uid() and pharmacy_id = pharmacy_id
)
```

En SQL, un nom de colonne non qualifié dans une sous-requête se résout d'abord contre le FROM de CETTE sous-requête. `pharmacy_staff` possédant elle-même une colonne `pharmacy_id`, les DEUX occurrences de `pharmacy_id = pharmacy_id` se résolvaient contre `pharmacy_staff.pharmacy_id` — jamais contre la table externe (`loyalty_programs.pharmacy_id`, etc.). Résultat : une tautologie toujours vraie pour quiconque a ne serait-ce qu'une ligne dans `pharmacy_staff`, quelle que soit l'officine. Concrètement, avant correctif, le personnel de N'IMPORTE QUELLE officine pouvait consulter ET MODIFIER (via `for all`) le programme de fidélité, les comptes clients (y compris ajuster leur solde de points), le catalogue de récompenses et les parrainages de TOUTES LES AUTRES officines du réseau.

Distinct de tous les défauts RLS précédents de cet audit : C1/C40 (sur-exposition en lecture), C43/C50 (policy inatteignable, donc trop restrictive) sont tous des défauts qui BLOQUENT un accès légitime. C66 est l'inverse — un défaut qui OUVRE un accès illégitime — ce qui en fait le bug de sécurité le plus sévère de tout l'audit à ce jour.

Corrigé (migration `20260829043000_loyalty_module_fixes.sql`, partie 1) en remplaçant les 5 sous-requêtes par le helper existant et déjà correct `public.is_pharmacy_staff(target_pharmacy_id uuid)` (SECURITY DEFINER), dont l'argument est évalué directement dans le contexte de la ligne de la table sur laquelle porte la policy — pas de sous-requête, pas de FROM-list à ambiguïté possible :

```sql
drop policy if exists "Staff manage loyalty programs" on public.loyalty_programs;
create policy "Staff manage loyalty programs" on public.loyalty_programs
  for all using (public.is_pharmacy_staff(pharmacy_id));
-- (et 4 policies symétriques sur loyalty_accounts ×2, loyalty_rewards, loyalty_referrals)
```

### 3.3 Récurrence massive du motif « rôle inatteignable » (C67)

`role in ('admin', 'staff')`/`role = 'admin'` — valeurs impossibles par construction (`public.profiles.role` n'autorise que `patient`/`pharmacien`/`grossiste`/`livreur`/`professionnel`/`regulateur`, contrainte CHECK de `20260827000200_profiles.sql`). Déjà identifié 4 fois avant ce module (Module 13 ×1, Module 14 ×2, Module 15 ×2). **9 nouvelles occurrences trouvées et corrigées dans ce module** : `gamification_badges.sql` (1), `gamification_leaderboard.sql` (1), `gamification_health.sql` (2, branche `role = 'professionnel'` déjà atteignable en parallèle sur ces deux-là), `loyalty_ai.sql` (4), `personalized_rewards.sql` (1) — 9 tables distinctes (soit 11 occurrences au total trouvées dans les migrations de ce module, en comptant les 2 supplémentaires hors périmètre ci-dessous).

Corrigé (migration `20260829043000_loyalty_module_fixes.sql`, partie 2) : `is_gsg_admin()` pour les 8 tables sans notion d'officine (`loyalty_badges`, `health_goals`, `health_milestones`, `health_challenges`, `challenge_progress`, `reward_earnings`, `health_actions`, `personalized_rewards` — aucune ne porte de colonne `pharmacy_id`, il ne peut donc s'agir que d'une supervision GSG plutôt que d'un accès scopé à une officine), et `is_pharmacy_staff(pharmacy_id) or is_gsg_admin()` pour `loyalty_leaderboard` (seule table du lot à porter réellement une colonne `pharmacy_id`).

**2 instances supplémentaires trouvées mais non corrigées**, hors périmètre : `dashboard_customization.sql` (« Staff view/manage user dashboards »/« dashboard widgets ») — migration orpheline, aucun fichier Dart du projet ne référence `user_dashboards`/`dashboard_widgets`, territoire probable du futur Module 28 (BI). Signalée dans le registre plutôt que corrigée pour rester dans le périmètre strict de ce module.

Recommandation réitérée (4ème fois) : un balayage complet et unique du projet sur ce motif serait désormais plus efficace que de continuer à le découvrir module par module.

### 3.4 Défauts fonctionnels

1. **`LoyaltyAIService.getRecommendations()`** : `today`/`yesterday` étaient des instants complets (`DateTime.now()`) comparés via `==` à `recordedAt` (valeur date-seule, minuit) — l'égalité n'était quasiment jamais vraie, rendant la recommandation « Maintenez votre activité » du code mort. Corrigé en normalisant `today`/`yesterday` à minuit avant comparaison.
2. **`BadgeService._getStreak()`** : retournait `5 + (DateTime.now().millisecondsSinceEpoch % 10)` — une valeur entièrement fictive, sans rapport avec l'activité réelle du patient, utilisée pourtant pour décider de l'attribution de vrais badges « streak ». Même famille de défaut que le score de crédit fictif C56 (Module 14). Corrigé par un calcul réel : requête sur `health_actions` du patient (limite 400, tri décroissant), déduplication par jour, comptage de jours consécutifs en remontant depuis le jour le plus récent.

### 3.5 Navigation (D6, 16ème occurrence)

`/loyalty` existait bien dans `app_router.dart` mais était absent du menu de navigation (`dashboard_screen.dart`) — motif D6 habituel. Particularité inédite par rapport aux 15 occurrences précédentes : 4 des 5 écrans du module (`badges_gallery_screen.dart`, `challenges_dashboard_screen.dart`, `leaderboard_screen.dart`, `personalized_rewards_screen.dart`) n'avaient AUCUNE déclaration de route dans `app_router.dart` — pas seulement une entrée de menu manquante, mais une absence totale de point d'entrée, orpheline par construction.

Corrigé conformément à l'arbitrage §2.1 : une entrée « Fidélité » (icône `Icons.card_giftcard`, route `/loyalty`) a été ajoutée à `_effectiveNavItems()`, visible uniquement pour le rôle `patient`. Les 4 écrans de gamification restent volontairement sans route (aucune régression : ils n'en avaient aucune avant non plus), en attente de la décision produit sur leur sort.

---

## 4. Optimisation & améliorations

- **Sélecteur d'officine (`LoyaltyPharmacySelectScreen`, nouveau)** : avant ce module, `LoyaltyDashboardScreen` acceptait un `pharmacyId` optionnel avec un repli `'default_pharmacy'` — pas un UUID valide, la route ne fournissant de toute façon jamais ce paramètre, ce repli s'exécutait 100 % du temps et toute réservation réelle aurait échoué (`invalid input syntax for type uuid`). `pharmacyId` est désormais obligatoire (`required`), et un nouvel écran de sélection présente « Mes programmes » (officines déjà rejointes, avec palier/points) et « Rejoindre une officine » (liste filtrée par recherche des officines actives) avant d'atteindre le tableau de bord fidélité.
- **`LoyaltyService`** : 3 nouvelles méthodes (`getActiveProgramId`, `getMyAccounts`, `getActivePharmacies`) nécessaires au sélecteur d'officine et au correctif du bug de compilation §3.1 point 1.
- **`PersonalizedRewardProvider.useReward()`** : dérivait le `patientId` pour ses rechargements post-action via `_activeRewards.isNotEmpty ? _activeRewards.first.patientId : ''` — repli silencieux vers une chaîne vide dès que la récompense utilisée était la seule active. Corrigé en mémorisant `_patientId` explicitement comme champ, plutôt que déduit d'une liste qui vient justement d'être modifiée par l'action en cours.
- **Aucun mode hors-ligne** n'a été construit ce module (ni lecture ni écriture) — même famille que C13/C21/C28/C33/C46, extension différée plutôt que choix assumé documenté ; candidat naturel pour une prochaine passe (lecture seule du solde de points/palier, à l'identique du Module 8/PAY).

---

## 5. Documentation API / conformité aux règles métier

**`LoyaltyService.getActiveProgramId(pharmacyId)`** *(nouveau)* — extrait de la logique auparavant buguée du provider ; retourne l'identifiant du premier programme actif d'une officine.

**`LoyaltyService.getMyAccounts(patientId)`** *(nouveau)* — liste tous les comptes fidélité d'un patient, toutes officines confondues, avec le nom de l'officine embarqué (`pharmacies:pharmacy_id(name)`), triés par date d'adhésion décroissante.

**`LoyaltyService.getActivePharmacies()`** *(nouveau)* — liste les officines `status = 'active'` (id/nom/adresse, limite 100), pour l'écran de sélection.

**`LoyaltyAIService.getProgress(...)`** *(renommé, était privé)* — voir §3.1 point 2.

**RLS `loyalty_*`/`health_*`/`personalized_rewards`/`reward_earnings`/`challenge_progress`** *(migration `20260829043000_loyalty_module_fixes.sql`)* — voir §3.2 et §3.3 pour le détail complet des 17 policies corrigées.

---

## 6. Scénarios de test (voir le protocole de test E2E dédié, `PharmaConnect_Module16_Protocole_Test_E2E.md`)

1. Démarrage/compilation — préalable bloquant, ce module comptait 3 défauts de compilation distincts sur 3 fichiers.
2. RLS cross-officine (C66) — le scénario le plus critique de tout l'audit : un compte staff d'une officine A ne doit pouvoir ni lire ni écrire les données de fidélité d'une officine B.
3. RLS « rôle inatteignable » (C67) — écriture back-office réelle sur les 9 tables concernées.
4. Sélecteur d'officine — rejoindre une nouvelle officine, basculer entre plusieurs officines déjà rejointes.
5. Attribution de badge « streak » sur données réelles (`_getStreak()` recalculé).
6. Confirmation que les 4 écrans de gamification restent inaccessibles (aucune route, aucun lien de menu).

---

## 7. Livrables de ce module

Nouveau : `supabase/migrations/20260829043000_loyalty_module_fixes.sql`, `lib/modules/loyalty/screens/loyalty_pharmacy_select_screen.dart`.
Modifiés : `lib/modules/dashboard/dashboard_screen.dart`, `lib/modules/loyalty/services/loyalty_service.dart`, `lib/modules/loyalty/providers/loyalty_provider.dart`, `lib/modules/loyalty/screens/loyalty_dashboard_screen.dart`, `lib/routes/app_router.dart`, `lib/modules/loyalty/services/loyalty_ai_service.dart`, `lib/modules/loyalty/providers/loyalty_ai_provider.dart`, `lib/modules/loyalty/screens/badges_gallery_screen.dart`, `lib/modules/loyalty/services/badge_service.dart`, `lib/modules/loyalty/providers/personalized_reward_provider.dart`.
`PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A25 ; C66-C67 ; D28 ; D6 annoté d'une seizième occurrence).
Ce rapport, le PV de recette provisoire, le protocole de test E2E.

---

**Le module Fidélité (FID) est-il totalement clos et validé pour passer au suivant ?**
