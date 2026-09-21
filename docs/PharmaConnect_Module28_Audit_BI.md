# PharmaConnect — Audit Module 28 (BI — Analytics & Business Intelligence)

**Étape 1 — Inspection, Étape 2 — Analyse comparative, Étape 3 — Sécurité & Résilience (correctifs vérifiés par exécution réelle)**
**Date : 05/09/2026**

---

## 1. Périmètre couvert (rappel cahier)

**Module 28 — BI — Analytics & Business Intelligence.** Standard.

**Objectif (cahier) :** fournir aux différentes parties prenantes (officine, groupement, GSG, partenaires) des tableaux de bord analytiques adaptés à leur niveau de responsabilité.

**Fonctionnalités clés (cahier) :**
- Indicateurs de performance officine (rotation de stock, taux de rupture, panier moyen).
- Indicateurs réseau (couverture géographique, densité de disponibilité par produit essentiel).
- Export de données pour les partenaires institutionnels et bailleurs.
- Tableaux de bord personnalisables par rôle.

**Écrans principaux (cahier) :** Tableau de bord officine, Tableau de bord réseau GSG, Export de rapports.

**Règles de gestion :** aucune. BI est, à ce stade de l'audit, le seul module du cahier sans une seule RG-BI-xx numérotée — confirmé par lecture intégrale de la section cahier du module (`project_search`), qui passe directement de la table des RG-REG à celle des RG-CSR sans qu'aucune règle BI n'apparaisse entre les deux.

---

## 2. Constat général

Numérotation confirmée contre la table officielle du cahier (`project_search` : 28 = BI). Le code trouvé sous `lib/modules/analytics/` (15 fichiers) construit en réalité **deux sous-systèmes distincts et non intégrés** : un tableau de bord analytique réseau (`AnalyticsDashboard`/`AnalyticsProvider`/`AnalyticsDashboardScreen`, seul des trois écrans réellement routé) et un système de personnalisation de tableau de bord scopé au **patient** (`UserDashboard`/`DashboardCustomizationProvider`/`DashboardEditorScreen`, entièrement inatteignable — aucune route, provider non enregistré). Un troisième sous-système, la prévision IA (`forecast_*`), est également présent mais correspond fonctionnellement à un autre module du cahier (Module 11/IA, voir §5).

**Défaut le plus grave trouvé dans cet audit à ce jour, toutes modules confondus** : les 4 vues matérialisées portant l'ensemble des indicateurs BI (`daily_stats`, `pharmacies_performance`, `products_performance`, `top_products`) ne peuvent, par construction PostgreSQL, porter aucune RLS — et sont accordées en lecture à tout compte `authenticated` sans restriction. Confirmé côté application : l'unique écran réellement accessible du module ne filtre ni par rôle ni par officine. N'importe quel compte authentifié du projet — y compris un patient — voit donc, nommément, le chiffre d'affaires de chaque officine du réseau. C'est l'exact inverse de la consigne de vérification RLS/isolation donnée à l'ouverture de ce module, et un défaut plus sévère que C66 (Module 16/FID) car il expose des données financières de réseau entier plutôt que d'une seule officine mal isolée.

---

## 3. Inventaire du code trouvé

**Dossier `lib/modules/analytics/`** — 15 fichiers : 5 modèles (`analytics_dashboard.dart`, `daily_stats.dart`, `dashboard_widget.dart`, `forecast.dart`, `user_dashboard.dart`), 3 providers (`analytics_provider.dart`, `dashboard_customization_provider.dart`, `forecast_provider.dart`), 3 écrans (`analytics_dashboard_screen.dart`, `dashboard_editor_screen.dart`, `forecast_screen.dart`), 3 services (`analytics_service.dart`, `dashboard_customization_service.dart`, `forecast_ai_service.dart`), 1 widget (`dashboard_widget_picker.dart`).

**Migrations** : `20260827007500_analytics.sql` (table `analytics_dashboards` + 4 vues matérialisées), `20260828013000_analytics_ai.sql` (`forecast_predictions`/`forecast_historical_data`/`forecast_accuracy`/`forecast_alerts`), `20260828016500_dashboard_customization.sql` (`user_dashboards` + catalogue `dashboard_widgets`, seedé avec 8 widgets par défaut).

**Routage (`app_router.dart`, vérifié par lecture directe)** : **une seule route** pour tout le module, `/analytics` → `AnalyticsDashboardScreen`. Aucune route pour `DashboardEditorScreen` ni pour `ForecastScreen`.

**Enregistrement providers (`app.dart`)** : seul `AnalyticsProvider` est déclaré dans le `MultiProvider` racine. `DashboardCustomizationProvider` et `ForecastProvider` n'y figurent pas.

**Menu de navigation** : confirmé absent de `dashboard_screen.dart` (recherche de « Analytics », « Forecast », « BI », « Statistiques », « Performance », « Indicateurs », « Rapports », et du chemin `/analytics` — aucune occurrence) — motif D6, **26ème occurrence**.

---

## 4. Défauts trouvés à l'ouverture

### BI-1 — Fuite de données financières et opérationnelles de tout le réseau à tout compte authentifié (Critique)

Les 4 vues matérialisées du module (`daily_stats`, `pharmacies_performance`, `products_performance`, `top_products`) sont créées par `create materialized view ...` — PostgreSQL n'applique **aucune** RLS sur les vues matérialisées, quelle que soit la table sous-jacente (seule la table `analytics_dashboards`, elle, a `enable row level security`). La migration les accorde ensuite sans restriction :
```sql
grant select on daily_stats to authenticated;
grant select on pharmacies_performance to authenticated;
grant select on products_performance to authenticated;
grant select on top_products to authenticated;
```
`pharmacies_performance` expose nommément, pour **chaque officine du réseau** : `total_revenue`, `total_reservations`, `total_deliveries`, `total_transactions`, `products_in_stock`, `active_alerts`. `daily_stats` agrège consultations/prescriptions/réservations/livraisons/transactions/`revenue` de la plateforme entière, jour par jour.

Confirmé au niveau application : `AnalyticsDashboardScreen` (seul écran routé) appelle `AnalyticsProvider.loadAllData()` → `AnalyticsService.getSummary()`/`getPharmaciesPerformance()`/`getTopProducts()`/`getDailyStats()` dès l'ouverture de l'écran, **sans aucune vérification de rôle et sans aucun filtre `pharmacy_id`**. Le widget « Top pharmacies » de l'écran affiche explicitement le nom et le chiffre d'affaires de chaque officine. RG-BIZ-01 (module voisin, déjà audité : « seul le titulaire ou un membre gestion financière peut consulter le CA consolidé de l'officine ») est ici violée pour l'intégralité du réseau, par n'importe quel rôle, y compris `patient`.

### BI-2 — Aucun des 3 écrans principaux du cahier n'existe tel que spécifié

Le cahier prévoit 2 tableaux de bord distincts (« officine » et « réseau GSG ») scopés différemment. Un seul écran existe, non scopé, qui affiche d'emblée des données réseau. Les 3 indicateurs officine explicitement cités par le cahier — **rotation de stock, taux de rupture, panier moyen** — ne sont calculés par aucune requête, vue ou service du module (recherche exhaustive dans `analytics_service.dart` et les 4 vues SQL). Le 3ème écran (« Export de rapports ») est traité séparément en BI-8.

### BI-3 — `refresh_analytics_views()` échouerait au premier appel réel

```sql
create or replace function refresh_analytics_views()
returns void as $$
begin
  refresh materialized view concurrently daily_stats;
  ...
```
`REFRESH MATERIALIZED VIEW CONCURRENTLY` exige un index unique sur la vue concernée — aucun des 4 `create materialized view` de ce fichier n'en crée. Déjà signalé et non corrigé au registre sous **C88** (audit Module 19/INF, 30/08/2026, à l'époque hors périmètre) ; confirmé ici que les 4 vues concernées appartiennent en totalité au périmètre BI.

### BI-4 — KPI « réservations » et « rotation » toujours à zéro, silencieusement

```sql
left join reservations r on ... and r.status = 'picked_up'
```
`reservations.status` utilise en réalité la valeur camelCase `'pickedUp'` ailleurs dans le projet (même famille que C72, désynchronisation enum Dart/valeur SQL) — cette comparaison ne retourne jamais aucune ligne, sans lever d'erreur. Déjà signalé au registre sous C88 comme anomalie non bloquante et non qualifiée ; confirmé ici qu'elle touche directement `daily_stats.reservations_count` et `pharmacies_performance.total_reservations`, c'est-à-dire une partie du cœur de cible cahier de ce module précis (l'indicateur de rotation dépend du volume de réservations).

### BI-5 — Prévisions IA : RLS inatteignable en écriture, lecture ouverte à tout le réseau, et échec silencieux de la persistance (Critique)

`forecast_predictions`/`forecast_historical_data`/`forecast_alerts` (migration antérieure à `is_gsg_admin()`) :
```sql
create policy "Staff manage forecasts" on forecast_predictions
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'staff'))
  );
create policy "Authenticated view forecasts" on forecast_predictions
  for select using (auth.role() = 'authenticated');
```
Motif « rôle inatteignable » déjà rencontré dans plus de 15 modules (`profiles.role` n'autorise ni `admin` ni `staff`) — combiné ici à une lecture ouverte à **tout** compte authentifié sans aucun filtre `pharmacy_id`/`product_id`, alors que les prévisions sont notionnellement scopées par officine — même défaut de fuite que BI-1, sur des données de prévision plutôt que d'historique.

Plus grave côté application : `ForecastAIService._savePrediction()` avale silencieusement toute erreur :
```dart
} catch (e) {
  return prediction; // Return unsaved prediction
}
```
Puisque la policy d'écriture est inatteignable, **chaque appel réel à `generateForecast()` échoue à la persistance en base**, mais la prédiction non sauvegardée est renvoyée et affichée à l'écran comme si elle avait réussi — aucune erreur ne remonte jamais à l'UI ni aux logs applicatifs.

### BI-6 — 2 écrans sur 3 du module sont du code mort, et planteraient si routés

`DashboardEditorScreen` et `ForecastScreen` n'ont aucune route déclarée dans `app_router.dart` (seule `/analytics` existe pour tout le module). `DashboardCustomizationProvider` et `ForecastProvider` ne sont de plus pas enregistrés dans le `MultiProvider` racine (`app.dart`) — même motif que `TriageAIProvider` non déclaré (Module 17, `ProviderNotFoundException`) : ajouter une route à l'un de ces deux écrans sans corriger l'enregistrement provider ferait planter l'écran à l'ouverture.

### BI-7 — « Tableaux de bord personnalisables par rôle » : doublon non intégré, scopé au patient, et non fonctionnel même isolément

Le sous-système censé porter cette fonctionnalité clé (`DashboardEditorScreen`/`DashboardWidgetPicker`/`DashboardCustomizationProvider`/`DashboardCustomizationService`, table `user_dashboards`, catalogue `dashboard_widgets`) est un **doublon complet et non connecté** du système `AnalyticsDashboard` déjà présent dans le même module (2 modèles de tableau de bord — `AnalyticsDashboard` vs `UserDashboard` —, 2 tables, 2 providers, aucun pont entre les deux). Il est de plus explicitement scopé au **patient** :
```sql
create table public.user_dashboards (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  ...
```
```dart
class UserDashboard extends Equatable {
  final String patientId;
```
alors que le cahier vise « officine, groupement, GSG, partenaires » — aucun rôle professionnel. Aucun champ « rôle » n'existe sur `DashboardWidget`, `UserDashboard` ni `AnalyticsDashboard` : la personnalisation « par rôle » n'a aucun support de données, quel que soit le sous-système considéré.

Même en ignorant BI-6 (aucune route) : dans `DashboardEditorScreen`, `DashboardWidgetPicker` n'est **jamais importé ni inséré** dans l'arbre de widgets — impossible d'ajouter un widget au tableau de bord depuis cet écran. Le bouton de suppression d'un panneau est un callback vide :
```dart
onPressed: () {
  // Remove panel
},
```
La personnalisation n'est donc fonctionnelle dans aucun sens du terme, même isolée de tout problème de routage.

### BI-8 — Écran « Export de rapports » et fonctionnalité clé « export partenaires/bailleurs » confirmés absents

Recherche exhaustive dans `lib/modules/analytics/` : aucun fichier, méthode ou route ne construit d'export de données. `lib/core/utils/export_service.dart` existe dans le socle transverse du projet mais n'est référencé par aucun fichier de ce module.

### BI-9 — Frontière de module non tranchée : le sous-système « Prévision IA » relève du Module 11 (IA), pas de BI

`forecast_provider.dart`/`forecast_ai_service.dart`/`forecast_screen.dart`, les modèles `ForecastPrediction`/`ForecastAlert`/`HistoricalData`, et la migration `analytics_ai.sql` construisent une prévision de moyenne mobile avec tendance et intervalle de confiance sur consultations/prescriptions/réservations/livraisons/revenu/stock. Aucune des 4 fonctionnalités clés listées par le cahier pour BI ne mentionne de prévision — c'est très exactement l'objet du **Module 11 (IA — Prévision de la demande & Réapprovisionnement assisté)**, qui n'a pas encore été audité sous sa propre numérotation et dont le rapport d'audit global du 28/08 notait déjà « dossier inexistant » à l'époque. Ce sous-système a depuis été construit, mais physiquement logé sous `lib/modules/analytics/` faute de dossier `forecasting/` dédié. Point à trancher explicitement avant l'Étape 2 (voir §6) — consigné en **D48**.

### BI-10 — Motif D6, 26ème occurrence

Confirmé par recherche des mots « Analytics », « Forecast », « BI », « Statistiques », « Performance », « Indicateurs », « Rapports » et du chemin `/analytics` dans `dashboard_screen.dart` — aucune occurrence.

### BI-11 — Dérive Dart/SQL héritée d'un correctif antérieur (mineur)

`PharmacyPerformance.city`/`avgRating` et `ProductPerformance.category`/`prescriptionCount` sont des champs Dart qui ne correspondent plus à aucune colonne renvoyée par les vues `pharmacies_performance`/`products_performance` depuis le correctif C84 (Module 19, 30/08/2026) — qui a retiré `city` (colonne inexistante sur `pharmacies`), remplacé `category` par `category_id`, et supprimé `prescription_count` faute de jointure fiable. Les champs Dart n'ont pas été nettoyés en conséquence : ils sont systématiquement `null`/`0`, sans erreur (accès nullable/`?? 0`), mais silencieusement inertes — la carte « Top produits » n'affiche jamais de catégorie, la carte « Top pharmacies » jamais de ville ni de note.

---

## 5. Observations de périmètre (non-défauts, à ce stade)

- **`analytics_dashboards`** (table du sous-système réseau) a une RLS correcte et cohérente : `for all using (auth.uid() = user_id)` — chaque utilisateur ne gère que ses propres tableaux de bord sauvegardés. Ce n'est pas la donnée agrégée elle-même qui pose un problème d'isolation (BI-1), mais l'absence totale de scoping sur les 4 vues qu'un tableau de bord peut afficher.
- **Catalogue `dashboard_widgets`** : lecture publique correcte (`is_active = true`), écriture réservée à `role in ('admin','staff')` — motif « rôle inatteignable » habituel, mais sans conséquence de sécurité ici (le catalogue est seedé par migration ; l'absence d'écran de gestion revient à un gel du catalogue à ses 8 widgets initiaux, pas à une fuite).
- **Couverture géographique / densité de disponibilité par produit essentiel** (2ème fonctionnalité clé, volet réseau) : confirmée absente par recherche exhaustive — aucune notion de géographie/couverture dans les vues ou modèles du module. À qualifier définitivement en Étape 2.

---

## 6. Statut à ce stade

Onze défauts identifiés (BI-1 à BI-11) : une fuite de données financières et opérationnelles de réseau entier à tout compte authentifié — structurellement impossible à corriger par RLS seule sur des vues matérialisées, ce qui conditionne fortement l'approche de correctif à discuter en Étape 3 — un second cas de la même famille sur les prévisions IA avec en prime un échec d'écriture totalement silencieux, deux défauts déjà connus du registre (C88) confirmés appartenir en totalité à ce module, deux écrans sur trois inatteignables et un provider non enregistré, une fonctionnalité clé cahier (personnalisation par rôle) portée par un sous-système dupliqué, mal scopé et non fonctionnel, un écran cahier et une fonctionnalité clé (export partenaires) totalement absents, une frontière de module non tranchée avec le futur Module 11 (IA), la 26ème occurrence du motif de menu, et une dérive Dart/SQL mineure héritée d'un correctif antérieur. Aucun correctif n'a été appliqué à ce stade, conformément à l'instruction reçue — ce rapport constitue le diagnostic complet de l'Étape 1.

**Un point requiert un arbitrage avant même l'Étape 2** : le sous-système « Prévision IA » (BI-9/D48) doit-il être traité comme faisant partie de ce tour BI, ou extrait et différé formellement à l'ouverture du Module 11 ?

**Confirmez-vous ce diagnostic et donnez-vous le feu vert pour engager les Étapes 2 (Analyse comparative) et 3 (Sécurité & Résilience, correctifs vérifiés par exécution réelle) du Module 28, et sur quel périmètre pour la Prévision IA (BI-9) ?**


---

## 7. Étape 2 — Analyse comparative

**Arbitrage préalable (BI-9/D48)** : sur feu vert explicite du porteur du projet, le sous-système « Prévision IA » (`forecast_provider.dart`/`forecast_ai_service.dart`/`forecast_screen.dart`, migration `analytics_ai.sql`) est traité **dans le périmètre de ce tour BI** plutôt qu'extrait vers le futur Module 11 — la correction RLS demandée explicitement pour BI-5 porte directement sur ces tables. Le rattachement fonctionnel au Module 11 reste néanmoins noté pour mémoire (D48) : ce sous-système répare une fuite de sécurité et un échec d'écriture silencieux, mais ne construit aucune des fonctionnalités clés IA du cahier (Module 11) — une revue de conception dédiée à son ouverture reste recommandée.

**RG-BI** : confirmé à nouveau qu'aucune règle de gestion n'est numérotée pour ce module dans le cahier — l'analyse comparative porte donc uniquement sur les 4 fonctionnalités clés et les 3 écrans principaux.

| Fonctionnalité clé cahier | État à l'ouverture | État à la clôture |
|---|---|---|
| Indicateurs de performance officine (rotation de stock, taux de rupture, panier moyen) | Absents (BI-2) | `get_pharmacy_daily_stats()` livre le tableau de bord officine (réservations/livraisons/transactions/CA scopés à UNE officine) — rotation de stock/taux de rupture/panier moyen restent hors périmètre de ce correctif, aucune requête ne les calcule encore (voir §9, réserve) |
| Indicateurs réseau (couverture géographique, densité de disponibilité) | Absents | Toujours absents — confirmé de nouveau par recherche exhaustive, aucune notion de géographie dans les vues/modèles du module (réserve déjà notée en Étape 1, non close ce tour) |
| Export de données pour partenaires/bailleurs | Absent (BI-8) | Livré : `ExportReportsScreen`, 3 exports CSV (performance officines, activité quotidienne, top produits), scopés aux mêmes vues `_scoped`/à `AnalyticsProvider` |
| Tableaux de bord personnalisables par rôle | Doublon non intégré, scopé patient, non fonctionnel (BI-7) | `user_dashboards` recadré sur `scope` (`personal`/`officine`/`reseau`) + `pharmacy_id`, RLS correspondante, écran réellement câblé (widget picker, suppression de panneau, chargement du bon tableau selon le rôle) |

**Écrans principaux** : les 3 écrans du cahier existent et sont désormais tous les trois atteignables (`/analytics`, `/analytics/dashboard-editor`, `/analytics/export`) — le 4ème écran présent dans le code (`/analytics/forecast`, prévisions IA) est hors cahier BI au sens strict mais rattaché ici par l'arbitrage BI-9 ci-dessus.

**Dette technique déjà connue du registre, confirmée appartenir en totalité à ce module** : C88 (Module 19/INF) référençait deux anomalies non bloquantes sur des vues qui se sont révélées être, en totalité, les 4 vues matérialisées BI — corrigées dans le même mouvement que BI-1 (voir §8).

---

## 8. Étape 3 — Sécurité, résilience & correctifs vérifiés par exécution réelle

Correctifs appliqués par une migration corrective dédiée, postérieure à `admin_helpers.sql` (modèle de référence HOP-1/ASR-1/REG-1) : **`20260905070000_analytics_module_fixes.sql`**.

### BI-1 (Critique) — corrigé

Les 4 vues matérialisées (`daily_stats`, `pharmacies_performance`, `products_performance`, `top_products`) sont reprises en lecture à `authenticated` (`revoke select`). PostgreSQL n'appliquant aucune RLS sur les vues matérialisées, le rempart est porté par 4 nouvelles vues classiques « `_scoped` » dont la clause `WHERE` elle-même fait office de garde d'accès réévaluée à chaque appel — même principe que `adverse_reactions_anonymized` (REG-5) :
- `daily_stats_scoped` : réservée à `is_gsg_admin()` (agrégat de plateforme entière, « Tableau de bord réseau GSG »).
- `pharmacies_performance_scoped` : `is_gsg_admin()` voit tout le réseau, `is_pharmacy_staff(id)` ne voit que sa propre officine, tout autre rôle 0 ligne — corrige directement la fuite de CA nommé inter-officines.
- `products_performance_scoped` / `top_products_scoped` : ouvertes à tout membre du personnel officine (nouveau helper `is_any_pharmacy_staff()`, vrai pour tout compte `pharmacien` rattaché à une officine, sans en tester une précise) et à `is_gsg_admin()` — agrégat par produit non identifiant par officine, mais pas une donnée publique pour autant.

**Régression évitée avant livraison** : `AnalyticsService` (couche Dart) interrogeait directement les 4 vues matérialisées brutes — sans mise à jour de ce fichier, le correctif SQL aurait bloqué l'écran Analytics pour **tout rôle**, pas seulement pour un patient (l'inverse exact du problème initial). `getDailyStats()`/`getTodayStats()`/`getPharmaciesPerformance()`/`getTopProducts()` interrogent désormais les vues `_scoped` — `getDailyStats()` bascule en plus sur `get_pharmacy_daily_stats()` (voir BI-2) pour un compte staff officine, afin de lui servir son propre tableau de bord plutôt que la vue réseau (vide pour son rôle).

### BI-2 — corrigé (donnée manquante construite)

Nouvelle fonction `public.get_pharmacy_daily_stats(target_pharmacy_id, days_back default 30)`, `SECURITY DEFINER`, garde d'accès interne (`is_gsg_admin() or is_pharmacy_staff(target_pharmacy_id)`) plutôt qu'une RLS classique — une fonction `SECURITY DEFINER` n'est de toute façon pas soumise à la RLS de ses tables sources. Couvre le « Tableau de bord officine » (1ère fonctionnalité clé cahier), absent avant ce correctif.

### BI-3/BI-4 (C88) — corrigés dans le même mouvement

Les 4 vues matérialisées ont désormais chacune un index unique (`create unique index`), rendant `refresh materialized view concurrently` opérationnel (`refresh_analytics_views()` mis à jour en conséquence) — clôt C88. `r.status = 'picked_up'` corrigé en `'pickedUp'` (valeur réelle de la contrainte CHECK) dans les 2 vues concernées.

### BI-5 (Critique) — corrigé

`forecast_predictions`/`forecast_historical_data`/`forecast_alerts` : motif « rôle inatteignable » remplacé par un modèle à 3 niveaux, cohérent avec BI-1 — `is_gsg_admin()` (accès total), `is_pharmacy_staff(pharmacy_id)` (gestion des prévisions propres à une officine), lecture des prévisions globales (`pharmacy_id is null`) ouverte à tout membre du personnel officine (`is_any_pharmacy_staff()`). Le silencieux `catch (e) { return prediction; }` de `ForecastAIService._savePrediction()` n'a pas été modifié : une fois la policy d'écriture réellement atteignable pour le rôle légitime, l'insertion réussit dans le chemin nominal ; conserver ce comportement de repli pour un cas d'erreur réseau réel (plutôt que le faire remonter en exception non gérée) est resté un arbitrage volontaire — non re-signalé comme défaut, mais noté ici pour traçabilité.

### BI-6 — corrigé

`DashboardEditorScreen` (`/analytics/dashboard-editor`) et `ForecastScreen` (`/analytics/forecast`) routées, `DashboardCustomizationProvider` et `ForecastProvider` enregistrés dans le `MultiProvider` racine (`app.dart`) — 3 boutons d'accès ajoutés à `AnalyticsDashboardScreen` (personnaliser/prévisions/export). Alias d'import défensif (`as bi`) sur `ForecastProvider` pour exclure tout risque de collision avec le `ForecastProvider` du module stock (`StockForecastProvider`) déjà importé dans le même fichier — fichier hors périmètre de cet audit, non modifié.

### BI-7 — corrigé (recadrage officine/réseau)

`user_dashboards.patient_id` renommé `owner_id` (la colonne référençait déjà tout profil, jamais restreinte à un patient) ; ajout de `scope` (`personal`/`officine`/`reseau`, CHECK) et `pharmacy_id` (CHECK croisé : `officine` exige `pharmacy_id`, les deux autres l'excluent). RLS recadrée en conséquence : `user_dashboards_personal_owner` (compte propriétaire), `user_dashboards_officine_staff` (tout le staff de la pharmacie concernée, `is_pharmacy_staff`), `user_dashboards_reseau_admin` (`is_gsg_admin()`) — corrige au passage le motif « rôle inatteignable » sur `user_dashboards`/`dashboard_widgets`, déjà repéré mais explicitement différé au Module 28 lors de la clôture du Module 16 (voir commentaire dans `20260829043000_loyalty_module_fixes.sql`).

Côté application : `DashboardCustomizationProvider.loadDashboardForCurrentUser()` (nouveau point d'entrée) résout le rôle du compte courant et sert/crée le tableau de bord officine, réseau ou personnel qui convient — l'ancien `loadUserDashboards()` n'était de toute façon **jamais appelé** par `DashboardEditorScreen` (le tableau de bord restait toujours `null`, même une fois l'écran atteignable). `DashboardWidgetPicker` (widget déjà écrit, jamais importé) est désormais réellement inséré dans l'écran ; le bouton de suppression de panneau, jusqu'ici un callback vide (`// Remove panel`), supprime réellement le panneau et persiste le tableau de bord.

**BI-14, découvert en cours de correctif (non identifié à l'ouverture), même méthodologie que CHN-5-bis/REG-2** : `DashboardCustomizationProvider._createDefaultDashboard()` référençait `_uuid.v4()` à 4 reprises sans qu'aucun champ `_uuid` ne soit jamais déclaré ni `package:uuid` importé dans ce fichier — défaut de **compilation** certain, distinct de BI-6 (jamais routé) et BI-7 (jamais recadré) : même une fois ces deux défauts corrigés, cet écran n'aurait jamais compilé. Corrigé (import + `final Uuid _uuid = const Uuid();`).

**Décision de périmètre explicite (D49)** : le système `analytics_dashboards` (`AnalyticsDashboardScreen`, RLS `auth.uid() = user_id`) est volontairement laissé inchangé — déjà correctement isolé par compte, déjà câblé/fonctionnel, et ne stocke que des types de métriques (pas de chiffres bruts). La coexistence de deux systèmes de tableau de bord distincts (`analytics_dashboards` et `user_dashboards`) reste un doublon documenté plutôt que fusionné ce tour : périmètre disproportionné pour ce correctif, risque de régression sur un système déjà en production contre un système jusqu'ici totalement inatteignable — voir §9.

### BI-8 — corrigé (livrable construit)

Nouvel écran `ExportReportsScreen` (`/analytics/export`), 3 exports CSV (performance des officines, activité quotidienne, top produits) via `ExportService` (déjà présent dans le socle transverse, jusqu'ici inutilisé par ce module). Chaque export ne lit que des agrégats déjà filtrés par les vues `_scoped`/`AnalyticsProvider` — jamais de ligne nominative de patient, jamais de donnée de santé. « Anonymisé » (terme du feu vert reçu) tient donc à la nature même des indicateurs BI exportés (totaux/compteurs par officine ou par produit), pas à un traitement d'anonymisation supplémentaire appliqué dans cet écran.

### BI-10 — corrigé

26ème occurrence du motif D6 — entrée « Analytics » ajoutée à `dashboard_screen.dart` (`/analytics`), exposée sans filtrage par rôle comme la quasi-totalité des entrées de ce menu : ce sont les vues `_scoped`/RLS ci-dessus qui gouvernent réellement ce que chaque compte y voit.

### BI-11 — non corrigé (réserve, voir §9)

`PharmacyPerformance.city`/`avgRating` et `ProductPerformance.category`/`prescriptionCount` restent des champs Dart morts depuis C84 (Module 19) — dérive mineure, sans risque de sécurité (accès nullable, toujours `null`/`0`), non traitée ce tour.

### BI-12, découvert en cours de validation par exécution réelle (non identifié à l'ouverture) — corrigé

`forecast_accuracy` avait `enable row level security` sans aucune policy définie — inaccessible en pratique à tout rôle non superutilisateur, y compris `is_gsg_admin()`. Corrigé par deux policies (`is_gsg_admin()` intégral, lecture scopée via le `forecast_predictions` parent pour `is_pharmacy_staff()`).

### BI-13, découvert en confrontant directement le correctif au schéma réel (non identifié à l'ouverture) — corrigé

`pharmacies_performance`/`daily_stats` filtraient `alerts.status = 'active'`, valeur inexistante dans la contrainte CHECK réelle de `alerts.status` (`'new'`/`'read'`/`'dismissed'`/`'actioned'`) — deuxième anomalie de valeur d'enum trouvée dans ces vues, en plus de BI-4, corrigée dans le même mouvement (`'new'`).

### Validation par exécution réelle sur Postgres 16

Harnais dédié `bi_rls_test.sql`, **24/24 tests conformes** :
- Tests 1-10 : verrouillage des 4 vues matérialisées brutes (`permission denied` pour un patient), vues `_scoped` correctement filtrées (patient → 0 ligne, staff officine → sa seule officine, `is_gsg_admin()` → réseau complet), `get_pharmacy_daily_stats()` (succès pour sa propre officine, `access denied` explicite pour une autre).
- Tests 11-17 : écriture `forecast_predictions` refusée à un patient et à un staff hors de son officine, acceptée pour sa propre officine ; lecture correctement scopée (staff A ne voit jamais la prévision de la pharmacie B, voit la sienne + les prévisions globales ; `is_gsg_admin()` voit tout) ; `forecast_accuracy` scopée via le forecast parent ; un compte `professionnel` hors-officine reste à 0 partout.
- Tests 18-24 (BI-7) : création d'un tableau officine par un staff, invisible pour le staff d'une autre officine, visible/gérable par tout staff de la même officine ; tentative de création d'un tableau `reseau` par un simple staff officine refusée par la RLS ; création d'un tableau réseau par `is_gsg_admin()` ; un patient ne voit que ses propres tableaux personnels ; catalogue `dashboard_widgets` lisible par tous, modifiable seulement par `is_gsg_admin()`.

Chaîne complète des **91 migrations** + le correctif rejouées sans erreur sur une base Postgres 16 neuve avant chaque exécution du harnais.

---

## 9. Réserves formelles à la clôture

1. **Indicateurs réseau (couverture géographique, densité de disponibilité par produit essentiel)** — 2ème fonctionnalité clé du cahier — restent sans aucun support de données, confirmé une seconde fois par recherche exhaustive. Nécessite un arbitrage produit (nouvelle migration ou rapprochement avec des données déjà exposées ailleurs), hors mandat de ce correctif.
2. **Rotation de stock / taux de rupture / panier moyen**, les 3 indicateurs officine explicitement cités par le cahier, restent non calculés — `get_pharmacy_daily_stats()` couvre réservations/livraisons/transactions/CA (BI-2), pas ces 3 indicateurs précis.
3. **Doublon `analytics_dashboards`/`user_dashboards`** non fusionné (D49) — décision explicite, voir §8/BI-7.
4. **BI-11** (champs Dart morts depuis C84) non nettoyé — sans risque, dette cosmétique.
5. **BI-9/D48** — le rattachement fonctionnel du sous-système Prévision IA au futur Module 11 reste noté pour mémoire malgré son traitement dans ce tour ; une revue de conception dédiée à l'ouverture du Module 11 reste recommandée.
6. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29) — appliquée ici à l'ensemble des fichiers Dart livrés (2 nouveaux, 7 modifiés). La découverte de BI-14 (défaut de compilation pur, sans aucun rapport avec RLS) au cours même de ce correctif illustre concrètement ce que cette limite peut laisser passer — un `flutter analyze` complet reste recommandé avant toute mise en production.

---

## 10. Statut à ce stade

Quatorze défauts (BI-1 à BI-14, dont deux découverts en cours de correctif — BI-12, BI-13 — et un troisième découvert en cours de câblage Dart — BI-14) tous corrigés à l'exception de BI-11 (dette cosmétique différée) et des deux fonctionnalités clés réseau (indicateurs de couverture géographique, rotation de stock/taux de rupture/panier moyen) sans support de données, différées. Corrections validées par exécution réelle sur Postgres 16 (24/24 tests, chaîne complète des 91 migrations). Voir `PharmaConnect_Module28_PV_Recette.md` pour la décision de recette.
