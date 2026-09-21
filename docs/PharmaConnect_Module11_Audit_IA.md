# PharmaConnect — Audit Module 11 (IA — Prévision de la demande & Réapprovisionnement assisté)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 Une conclusion de registre erronée, corrigée par ré-investigation active

Le registre indiquait en **D5** : « Module IA/forecasting (cahier) : dossier inexistant — non entamé ». Cette conclusion, héritée de l'Étape 1 (audit global initial), était **fausse** — elle avait d'ailleurs déjà été mise en doute par les items **C16/C17** du Module 4 (STK), qui signalaient la présence de fichiers `forecast_*` sous `lib/modules/stock/` sans les avoir lus en détail. Conformément à la méthodologie désormais établie (ne jamais rouvrir un module sur la foi d'une conclusion non revérifiée — précédent Module 9/BIZ), ces fichiers ont été intégralement chargés et lus à l'ouverture de ce module plutôt que de faire confiance à D5.

**Constat réel :** un embryon d'implémentation du Module 11 existe bel et bien, sous `lib/modules/stock/` (mauvais emplacement — aurait dû être `lib/modules/forecasting/` ou `lib/modules/ia/`) :

- `models/demand_forecast.dart` — `DemandForecast`, `ReorderAlert`
- `services/forecast_service.dart` — `ForecastService` (génération de prévision, alertes de réapprovisionnement, simulation de scénario)
- `providers/forecast_provider.dart` — `StockForecastProvider`
- `screens/demand_forecast_screen.dart` — écran « Prévision de la demande »
- `widgets/forecast_chart.dart` — graphique (`fl_chart`)

**Contrairement au motif D6 habituel** (code fonctionnel jamais câblé), ce code **était déjà routé** (`/stock/forecast`, `/stock/forecast/:productId`, `app_router.dart`) et son provider **déjà déclaré** dans `app.dart` (`MultiProvider`). Mais il n'était accessible par aucun bouton/lien nulle part dans l'application (aucune occurrence de `/stock/forecast` en dehors des définitions de route elles-mêmes) — orphelin à la couche navigation, pas à la couche routage.

### 1.2 Le code lui-même était gravement défaillant — pas seulement « non câblé »

C'est la découverte la plus sévère de tout l'audit à ce jour : contrairement aux 9 occurrences précédentes du motif D6 (du code fonctionnel simplement pas relié), **ce code n'aurait pas compilé**, et même une fois compilable, n'aurait jamais produit de résultat réel. Cinq défauts distincts, cumulatifs :

1. **Syntaxe invalide, bloquante à la compilation.** `demand_forecast.dart` : la classe `ReorderAlert` ne comportait qu'un constructeur placeholder littéral, `const ReorderAlert({...});` — syntaxe Dart invalide — et **aucune** méthode `copyWith`/`toJson`/`fromJson`, pourtant déjà appelées par `ForecastService`. Le module entier était donc syntaxiquement non compilable, indépendamment de tout câblage.
2. **Identifiant non défini, bloquant à la compilation.** `forecast_provider.dart:loadForecasts()` appelait `_client.from(...)` sans qu'aucun champ `_client` n'existe dans `StockForecastProvider` (ni import Supabase). Erreur de compilation qui aurait bloqué `flutter analyze`/le build de **tout le projet** dès l'inclusion de ce fichier — pas seulement de cette fonctionnalité — que `loadForecasts` soit appelée ou non.
3. **Mauvais identifiant transmis comme `pharmacyId`.** `demand_forecast_screen.dart` passait `SupabaseService().currentUser?.id` (l'ID utilisateur authentifié) là où l'app utilise partout ailleurs `AuthProvider.pharmacyId` (l'ID de l'officine — deux identifiants distincts depuis le Module 1). Toute requête scopée par `pharmacy_id` aurait donc silencieusement retourné zéro ligne en permanence.
4. **Requête historique de ventes portant sur des colonnes inexistantes.** `ForecastService._getHistoricalSales()` filtrait `stock_movements` sur `product_id`, `pharmacy_id`, `movement_type`, `created_at` — aucune de ces colonnes n'existe sur cette table (colonnes réelles : `stock_item_id`, `type`, `timestamp`, sans `product_id` ni `pharmacy_id` du tout — voir `20260827000600_stock.sql`). Cette requête échouait donc systématiquement (exception absorbée silencieusement), forçant `generateDemandForecast` à toujours retomber sur une moyenne par défaut codée en dur (10/jour) — la « prévision » n'a **jamais**, à aucun moment, exploité de données de vente réelles, même avant tout autre bug.
5. **Sélecteur de produit entièrement fictif.** `_buildProductSelector()` proposait 5 produits codés en dur (`p1`..`p5`, « Doliprane 1000mg », etc.), sans lien avec le catalogue réel — même une fois (1)-(4) corrigés, toute sélection aurait échoué sur `.from('products')...single()` (aucune ligne).

À cela s'ajoutaient deux défauts fonctionnels (pas bloquants, mais réels) :

6. **Aucune protection anti-doublon** sur `checkReorderAlerts` — même défaut déjà corrigé pour `alerts` au Module 10 (C35).
7. **Formule de seuil de réapprovisionnement déconnectée** (`totalQuantity * 0.2 + 5`) de `StockItem.thresholdLow`, pourtant déjà le seuil réel, paramétrable par le pharmacien depuis le Module 10 (D15).
8. **Requête `.select()` sans jointure** sur `stock_items` dans `checkReorderAlerts` — `StockItem.fromJson` exige une relation `product` imbriquée absente d'un `select()` nu ; aurait levé une exception dès le premier item.

**Conclusion de l'Inspection :** ce module n'était pas simplement « non câblé » (motif D6 habituel) — le code lui-même était non compilable et, même corrigé de ses erreurs de syntaxe, n'aurait jamais reflété de données réelles. C'est la 10ème occurrence de « code déjà écrit mais jamais réellement vérifié », mais la première à ce niveau de gravité.

### 1.3 Correction du registre C36

Le registre indiquait (C36, Module 10) que `demand_forecasts`/`reorder_alerts`/`scenario_simulations` (`stock_forecasting.sql`) n'avaient **aucun** producteur Dart, au même titre que les tables de `sales_ai.sql`. C'est **inexact** pour ces trois tables précises : `ForecastService.generateDemandForecast`/`_saveForecast`, `checkReorderAlerts`/`_saveReorderAlert` et `simulateScenario` les alimentent bel et bien (une fois leurs bugs corrigés ce module). Seule `forecast_accuracy` reste, elle, un schéma authentiquement vide et sans aucun code Dart producteur ou consommateur — voir §2.3 et D18. Le registre est corrigé en conséquence (voir la mise à jour C36 dans le registre des écarts).

---

## 2. Analyse comparative au cahier de conception

### 2.1 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-IA-01** (Critique) | Aucune commande recommandée ne peut être transmise automatiquement à un fournisseur sans validation explicite du pharmacien | 🟢 Respectée par construction — **aucune intégration fournisseur n'existe dans tout le projet** (grep exhaustif : zéro table, zéro modèle, zéro service « fournisseur/supplier »). Il n'y a donc rien qui pourrait transmettre automatiquement. Le nouvel écran « Commande recommandée » (D17, voir §4.3) formalise et documente cette garantie plutôt que de la laisser implicite |
| **RG-IA-02** (Critique) | Les données d'apprentissage agrégé inter-officines sont anonymisées, sans réidentification possible d'une officine tierce | 🟡 Non applicable en l'état — **aucun apprentissage agrégé inter-officines n'existe** : le modèle actuel est une heuristique mono-officine (moyenne + bruit), voir §2.2. Rien à anonymiser tant que cette fonctionnalité n'est pas construite. Reporté (arbitrage D18) |

### 2.2 Fonctionnalités clés du cahier

| Fonctionnalité (cahier) | Constat |
|---|---|
| Modèle de prévision par produit (saisonnalité, tendance, événements) | 🟡 Un modèle heuristique existe (moyenne des 30 derniers mouvements de vente + facteur jour de semaine + bruit aléatoire), **corrigé ce module pour être fonctionnel** (voir §1.2, points 4-5), mais ce n'est pas un modèle de saisonnalité/tendance/événements au sens du cahier — décision explicite : documenté comme MVP indicatif dans l'écran lui-même, pas présenté comme un moteur prédictif avancé |
| Génération automatique de proposition de commande fournisseur, éditable par le pharmacien | 🟢 Construit ce module (D17) — voir §4.3. Éditable, avec validation explicite, sans transmission fournisseur (aucune intégration n'existe) |
| Apprentissage progressif propre à l'officine + agrégé anonymisé inter-officines | 🔴 Absent. Propre à l'officine : le modèle utilise déjà l'historique de l'officine (une fois corrigé), mais sans amélioration progressive réelle (pas de rétro-apprentissage sur `actual_demand`/`forecast_accuracy`, restée vide). Agrégé inter-officines : entièrement absent. Reporté (D18) |
| Simulation d'impact d'une rupture de stock sur le CA estimé | 🟡 `simulateScenario` existe mais reste entièrement simulé (dictionnaire de scénarios codé en dur, pas de calcul réel à partir des données de l'officine) — non modifié ce module, hors du périmètre des correctifs prioritaires (bug de compilation, RLS, identifiants) |
| Recommandation de fournisseur (prix/délai/fiabilité) | 🔴 Absent — aucun modèle de données Fournisseur dans tout le projet. Reporté (D18) |

### 2.3 Écrans principaux (cahier)

| Écran (cahier) | Constat |
|---|---|
| Écran de commande recommandée | 🟢 **Construit ce module** (D17) — `ReorderRecommendationScreen`, route `/stock/forecast/orders` |
| Détail des prévisions par produit | 🟡 Existait déjà (`DemandForecastScreen`) mais non fonctionnel (§1.2) — **corrigé ce module** ; reste un modèle indicatif, pas un moteur prédictif avancé (voir §2.2) |
| Historique de fiabilité des prévisions | 🔴 Absent — table `forecast_accuracy` vide, aucun code Dart producteur (calcul d'erreur/MAE/RMSE) ni consommateur (écran). Reporté (D18) |

---

## 3. Sécurité & résilience

### 3.1 RLS — 10ème occurrence confirmée du motif « migration de base incomplète en écriture »

`demand_forecasts`/`reorder_alerts`/`scenario_simulations` (migration `20260829005000_stock_forecasting.sql`) n'avaient qu'une policy SELECT pour le staff d'officine (`is_pharmacy_staff`) ; la seule autre policy était `for all using (is_gsg_admin())`, réservée à l'admin GSG. Un pharmacien — pourtant le seul rôle censé déclencher `generateDemandForecast`/`checkReorderAlerts`/`simulateScenario` — ne pouvait donc jamais insérer ni mettre à jour ces lignes. Même motif que C35 (alerts, Module 10) et les 8 occurrences précédentes de cet audit.

**Corrigé** : migration `20260829022000_forecasting_module_fixes.sql`, additive (n'enlève aucune policy existante) — policies INSERT/UPDATE scopées `is_pharmacy_staff(pharmacy_id)` sur les trois tables.

### 3.2 Contrôle d'accès applicatif

Les deux écrans (`DemandForecastScreen`, `ReorderRecommendationScreen`) sont réservés au rôle `pharmacien` avec `pharmacyId` non nul — même patron que `alert_threshold_settings_screen.dart` (Module 10) et `reconciliation_screen.dart` (Module 8).

### 3.3 Mode hors-ligne

Directive standing « privilégier le mode hors-ligne » appliquée en lecture seule (prévisions déjà générées, propositions de réapprovisionnement déjà calculées) — même patron que `cache_alerts`/`AlertProvider` (Module 10) : `cache_forecasts`/`cache_reorder_alerts` (migration sqflite v8→v9), bandeau « Hors ligne » sur les deux écrans. Volontairement pas en écriture (générer une prévision ou valider une commande reste en ligne uniquement) — cohérent avec PAY (D13) et ALR.

### 3.4 Non-temps-réel

Comme pour ALR (A17) et PAY (D12), la génération de prévisions/alertes de réapprovisionnement se déclenche à l'ouverture de l'écran, pas en tâche de fond serveur — limitation structurelle assumée, cohérente avec le reste du projet (100% Flutter + Supabase, sans backend séparé — voir D1).

---

## 4. Optimisation & améliorations livrées

1. **`demand_forecast.dart`** — `ReorderAlert` complété (constructeur réel, `copyWith`, `toJson`, `fromJson`) ; le fichier ne compilait pas auparavant.
2. **`forecast_provider.dart`** — bug de compilation (`_client` non défini) corrigé en passant par une nouvelle méthode `ForecastService.getForecasts()`.
3. **`forecast_service.dart`** — `_getHistoricalSales` réécrite pour interroger les colonnes réelles de `stock_movements` (résolution du `stock_item_id` puis filtrage `type = 'sale'`, valeur absolue de la quantité) ; `checkReorderAlerts` corrigée pour utiliser une requête jointe (`_stockItemSelect`) et un anti-doublon ; `_calculateReorderPoint` alignée sur `StockItem.thresholdLow` ; nouvelles méthodes `getPendingReorderAlerts`/`validateReorder`/`dismissReorder`.
4. **`demand_forecast_screen.dart`** — `pharmacyId` corrigé (`AuthProvider.pharmacyId` au lieu de l'ID utilisateur) ; contrôle d'accès pharmacien/officine ajouté ; sélecteur de produit connecté au stock réel de l'officine (`StockProvider`) au lieu d'une liste fictive ; bandeau hors-ligne ; lien vers le nouvel écran « Commande recommandée » corrigé (menait auparavant vers `/stock/alerts`, sans rapport).
5. **`reorder_recommendation_screen.dart`** (nouveau, D17) — écran « Commande recommandée » : liste des propositions en attente, quantité éditable, validation explicite (RG-IA-01), option « Écarter ».
6. **`app_router.dart`** — route `/stock/forecast/orders`.
7. **`stock_alerts_screen.dart`** — point d'entrée de navigation ajouté (icône, réservée au rôle pharmacien) vers `/stock/forecast`, jusque-là inaccessible depuis nulle part dans l'app malgré son routage.
8. **`offline_sync_service.dart`** — `cache_forecasts`/`cache_reorder_alerts` (v8→v9), méthodes `cache*`/`getCached*`, ajoutées à `clearAll()`.
9. **Migration `20260829022000_forecasting_module_fixes.sql`** — policies RLS INSERT/UPDATE pour le staff d'officine sur les trois tables de prévision.

---

## 5. Documentation API — `ForecastService`

| Méthode | Paramètres | Retour | Notes |
|---|---|---|---|
| `generateDemandForecast` | `productId`, `pharmacyId`, `days` (défaut 14) | `List<DemandForecast>` | Corrigée ce module — utilise désormais un historique de ventes réel (`stock_movements`) |
| `getForecasts` | `pharmacyId` | `List<DemandForecast>` | Nouvelle — lecture pure, utilisée par `StockForecastProvider.loadForecasts` |
| `checkReorderAlerts` | `pharmacyId` | `List<ReorderAlert>` | Corrigée ce module — requête jointe + anti-doublon |
| `getPendingReorderAlerts` | `pharmacyId` | `List<ReorderAlert>` | Nouvelle — lecture pure sans effet de bord, utilisée par l'écran D17 |
| `validateReorder` | `alertId`, `quantityToOrder` | `bool` | Nouvelle — RG-IA-01 : passe l'alerte à `'ordered'`, aucune transmission externe |
| `dismissReorder` | `alertId` | `bool` | Nouvelle — passe l'alerte à `'cancelled'` |
| `simulateScenario` | `pharmacyId`, `name`, `parameters` | `Map<String, dynamic>` | Inchangée — reste un mock (voir §2.2) |

---

## 6. Livrables et écarts documentés

Livrés ce module : correctifs de compilation, correctif RLS (10ème occurrence), correctif d'identifiant (`pharmacyId`), correctif de requête historique, sélecteur de produit réel, anti-doublon, alignement des seuils, écran « Commande recommandée » (D17), mode hors-ligne en lecture, navigation.

Écarts assumés et documentés (arbitrage D18, reporté vers un futur chantier IA/BI dédié) : modèle de prévision avancé (saisonnalité/tendance/événements), apprentissage agrégé anonymisé inter-officines (RG-IA-02), écran « Historique de fiabilité des prévisions » (`forecast_accuracy`, toujours vide), recommandation de fournisseur.

Voir `PharmaConnect_Module11_Protocole_Test_E2E.md` pour les scénarios de validation et `PharmaConnect_Module11_PV_Recette.md` pour l'état de recette provisoire.

---

**Le module Prévision de la demande / IA est-il totalement clos et validé pour passer au suivant ?**
