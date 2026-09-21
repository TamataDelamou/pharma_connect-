# PharmaConnect — Audit Module 10 (ALR — Alertes intelligentes)

**Date :** 29/08/2026
**Méthodologie :** Inspection → Analyse comparative → Sécurité & résilience → Optimisation → Documentation API → Scénarios de test → Livrables, conformément à la Règle d'or du projet.
**Rappel de séquencement :** le Module 9 (BIZ) a été réinvestigué à l'ouverture de ce cycle et confirmé non entamé (voir registre, item D4) ; décision prise avec le porteur du projet de passer directement à ce module (ALR).

---

## 1. Inspection & rapport de situation

### 1.1 Périmètre inspecté

`lib/modules/alerts/` en entier : 5 modèles (`alert.dart`, `alert_type.dart` — 26 valeurs, `alert_severity.dart`, `alert_status.dart`, `alert_preferences.dart`), 1 service (`alert_service.dart`), 1 provider (`alert_provider.dart`), 2 écrans (`alert_center_screen.dart`, `alert_preferences_screen.dart`), 2 widgets (`alert_card.dart`, `alert_filter_chips.dart`), plus la migration dédiée `20260827001400_alerts.sql` et les points d'intégration transverses (`app.dart`, `app_router.dart`, `lib/modules/stock/`, `lib/modules/dashboard/`).

### 1.2 Constat général

Contrairement à plusieurs modules précédents, la qualité intrinsèque du code de ce module est bonne : modèles complets et cohérents (sérialisation JSON propre, gestion du mot réservé Dart `new` via `new_`/`'new'`), service correctement structuré (CRUD alertes, préférences, deux générateurs métier `generateStockAlert`/`generateExpiryAlert`), provider standard (chargement, actions, gestion d'erreur), écrans soignés (regroupement par type et priorité, filtres, badges "URGENT"). Ce n'est donc pas un problème de qualité de code qui a été trouvé ici, mais un problème d'intégration :

- **8ème occurrence du motif D6** (code fonctionnel jamais câblé) : `generateStockAlert`/`generateExpiryAlert` n'étaient appelés nulle part dans l'application avant cet audit — ni depuis le module stock, ni depuis aucun autre module. La table `alerts` serait donc restée vide indéfiniment en production, quel que soit l'état réel du stock.
- **RLS bloquante** : même si quelque chose avait appelé ces méthodes, l'écriture aurait échoué — la migration d'origine n'avait aucune policy `INSERT` sur `alerts` (voir §3).
- **Écran manquant** : le cahier prévoit 3 écrans principaux pour ALR (Centre d'alertes, Détail d'une alerte avec recommandation, Paramétrage des seuils). Seuls 2 existaient ; le premier des deux manquants a été construit ce module (voir §4), le second reste un écart documenté (voir §2 et registre D15).
- **Deux systèmes d'alertes stock parallèles, non unifiés** : `StockAlertsScreen`/`StockProvider` (module STK) calcule déjà en direct ses propres listes `outOfStockItems`/`criticalStockItems`/`lowStockItems` depuis le stock réel — un système entièrement fonctionnel et indépendant du module ALR. Le module ALR (`Alert`/`AlertService`), lui, est le système "persistant + notifications + centre unifié multi-source" prévu par le cahier, mais qui n'avait jamais été alimenté. Les deux ne sont pas en conflit (l'un est une vue directe, l'autre un flux d'événements) mais n'étaient pas connectés — corrigé ce module (voir §4).

### 1.3 Modules externes vérifiés (pour ne pas conclure prématurément un "non entamé")

Avant de conclure que RG-ALR-01/02 étaient inappliquées, trois pistes ont été vérifiées pour écarter l'hypothèse d'un code mal cartographié (motif désormais établi, voir D6) :

- `lib/modules/stock/` : contient bien la logique de seuils (`StockItem.thresholdLow`/`thresholdCritical`, `StockService.computeStockStatus`) et le moteur FEFO (tri chronologique pur par `expiryDate`, aucun champ `priority`).
- `supabase/migrations/20260829005000_stock_forecasting.sql` : tables `demand_forecasts`/`reorder_alerts`/`scenario_simulations` — **vides, sans aucun code Dart producteur ou consommateur**. Ce n'est pas une implémentation alternative d'ALR, c'est un schéma en attente d'un pipeline de prévision qui n'a jamais été construit (voir registre C36).
- `supabase/migrations/20260829011000_sales_ai.sql` : table `fraud_alerts` — même constat, vide et sans producteur. Correspond à la fonctionnalité clé « détection d'anomalies de vente/fraude » du cahier, mais reste un schéma inerte (voir registre C36, D16).

Conclusion : aucune implémentation alternative cachée — les écarts identifiés en §2 sont réels, pas un problème de cartographie.

---

## 2. Analyse comparative (cahier vs réalité)

### 2.1 Règles de gestion

| Réf. | Énoncé | Statut avant cet audit | Statut après cet audit |
|---|---|---|---|
| RG-ALR-01 | Alerte de rupture imminente dès que le stock estimé passe sous 3 jours de consommation moyenne, sauf paramétrage produit | ❌ Non appliquée (générateur jamais appelé, RLS bloquante) | 🟡 Partiellement conforme — mécanisme câblé et fonctionnel, mais sur seuil **statique par produit** (`thresholdLow`/`thresholdCritical`), pas sur un calcul réel de consommation moyenne journalière (aucune vélocité de ventes calculée nulle part dans l'app — voir registre B18). La clause « sauf paramétrage spécifique du produit » est, elle, bien respectée puisque le seuil est déjà par produit |
| RG-ALR-02 | Alerte de péremption à 60 jours reclasse automatiquement le lot en priorité de sortie « élevée » dans le moteur FEFO | ❌ Non appliquée (même cause) | 🟢 Conforme en pratique — alerte câblée sur un horizon 60 jours. Nuance : le moteur FEFO de ce projet est un **tri chronologique pur** par date de péremption (voir `StockService.getExpiringBatches`/`confirmReservation`) : un lot à J-60 est déjà systématiquement proposé avant un lot à J-200, sans qu'aucun champ « priorité » séparé n'existe ou ne soit nécessaire. La reclassification explicite décrite par la règle est donc déjà satisfaite par construction plutôt que par un mécanisme dédié — documenté au registre (B9) plutôt que traité comme un écart |

### 2.2 Fonctionnalités clés du cahier

| Fonctionnalité | Statut |
|---|---|
| Alerte stock faible (sur consommation moyenne journalière) | 🟡 Implémentée sur seuil statique, pas sur consommation réelle (voir RG-ALR-01 ci-dessus) |
| Alerte rupture imminente avec estimation des jours restants | 🟡 L'alerte existe (`stockOut`) mais sans estimation du nombre de jours restants (nécessiterait la même vélocité de ventes) |
| Alerte péremption à horizon paramétrable (30/60/90 jours) | 🟡 Câblée sur un horizon fixe de 60 jours (le seul paramétrable dans le code est `daysThreshold` de `generateExpiryAlert`, jamais exposé à l'utilisateur) — pas de sélecteur 30/60/90 en UI |
| Alerte surstock par rapport à la consommation habituelle | ❌ Absente — aucun `AlertType.overstock`, aucune notion de surstock dans le code (registre D16) |
| Détection d'anomalies de vente/fraude avec score de risque | ❌ Absente côté ALR — schéma `fraud_alerts` existe ailleurs mais vide, sans producteur (registre C36, D16) |

### 2.3 Écrans principaux

| Écran (cahier) | Statut |
|---|---|
| Centre d'alertes | ✅ Existait et fonctionne (`AlertCenterScreen`, route `/alerts`) — comportement de navigation amélioré ce module (voir §4) |
| Détail d'une alerte avec recommandation | ❌ Absent avant cet audit (`AlertProvider.loadAlert`/`selectedAlert` codés mais jamais consommés) → ✅ Construit ce module (`AlertDetailScreen`, route `/alerts/detail/:id`) |
| Paramétrage des seuils par produit ou catégorie | ❌ Absent — `AlertPreferencesScreen` existant couvre les préférences de *notification* (canaux, sévérité, type), pas la configuration des *valeurs de seuil* elles-mêmes. Les valeurs existent en base et sont déjà éditables côté RLS (staff d'officine), seule l'UI manque — voir registre D15 |

---

## 3. Sécurité & résilience

### 3.1 Faille RLS bloquante — corrigée

`public.alerts` (migration d'origine `20260827001400_alerts.sql`) n'avait **aucune policy INSERT**, et les policies SELECT/UPDATE existantes ne couvraient que `auth.uid() = user_id` — une alerte d'officine (cas de `generateStockAlert`/`generateExpiryAlert`, où `user_id` est NULL et seul `pharmacy_id` est renseigné) aurait donc :
1. échoué à l'insertion (permission denied, aucune policy INSERT ne matche) ;
2. même en supposant l'insertion possible par un autre biais, n'aurait jamais été visible ni actionnable par personne (`auth.uid() = NULL` n'est jamais vrai).

**Corrigé** par la migration `20260829020000_alerts_module_fixes.sql` : policy INSERT couvrant les deux cas (alerte personnelle OU alerte d'officine créée par un membre du staff rattaché, via `is_pharmacy_staff()` déjà en place depuis le Module 4), et policies SELECT/UPDATE staff symétriques aux policies personnelles existantes.

### 3.2 Portée des accès

- Alerte personnelle (`user_id` renseigné) : visible/actionnable uniquement par son propriétaire — cohérent.
- Alerte d'officine (`pharmacy_id` renseigné) : visible/actionnable par tout membre du staff rattaché à cette officine (`is_pharmacy_staff`), pas par le staff d'une autre officine ni par un patient — cohérent avec le modèle multi-officines déjà établi (STK, RES, PAY).
- Aucune policy `is_gsg_admin()` n'a été ajoutée pour une vue toutes-officines (choix délibéré, hors périmètre de ce qui a été demandé — un futur écran back-office ADM pourrait en avoir besoin, à l'image de B6).

### 3.3 Résilience — déclenchement non temps-réel (limitation structurelle assumée)

Le câblage réalisé ce module (`StockProvider.loadAlerts()` → `AlertService.generateStockAlert`/`generateExpiryAlert`) se déclenche **à l'ouverture de l'écran « Alertes de stock »**, pas en temps réel à chaque mouvement de stock. C'est la même famille de limitation que RG-PAY-01 (D12) : ce projet est 100 % Flutter + Supabase côté client, sans trigger PostgreSQL ni Edge Function — un vrai temps réel (« dès que » de RG-ALR-01) demanderait l'un des deux. Documenté au registre (A17) plutôt que présenté comme pleinement conforme.

### 3.4 Anti-doublon

Avant cet audit, appeler `generateStockAlert`/`generateExpiryAlert` à chaque ouverture d'écran aurait créé une nouvelle ligne d'alerte à chaque fois (spam). Une vérification (`_hasUnresolvedAlert`, nouvelle) interroge désormais `alerts` avant toute insertion et n'insère que s'il n'existe pas déjà une alerte non résolue (`new`/`read`) pour la même référence **et le même type** — le "et le même type" est volontaire : il laisse passer une escalade légitime (ex. `stockLow` → `stockCritical`) sans jamais dupliquer la même alerte.

---

## 4. Optimisation & améliorations livrées ce module

1. **Câblage réel de `generateStockAlert`/`generateExpiryAlert`** (`StockProvider.loadAlerts()`) — avec seuils réels par produit (`thresholdLow`/`thresholdCritical`, plus l'ancien défaut codé en dur 20/5 qui aurait produit une sévérité incohérente avec le reste de l'app) et horizon péremption 60 jours (aligné sur RG-ALR-02).
2. **Écran de détail manquant construit** (`AlertDetailScreen`) — affiche l'alerte, une recommandation contextuelle par type (nouveau getter `Alert.recommendation`, 26 cas couverts), et les actions (traiter/ignorer/action métier). Le clic sur une alerte dans le Centre d'alertes ouvre maintenant ce détail au lieu de sauter directement vers `actionRoute` — améliore l'UX en laissant le pharmacien comprendre l'alerte avant d'agir, conformément à l'écran prévu par le cahier.
3. **Mode hors-ligne (lecture)** — directive standing appliquée : `cache_alerts` (nouvelle table sqflite, version 8 du schéma local), repli automatique si le réseau échoue, bandeau "Hors ligne" dans le Centre d'alertes, même patron que PAY (Module 8).
4. **Anti-doublon** (voir §3.4) — évite qu'une alerte déjà connue et non résolue soit réinsérée à chaque chargement d'écran.

---

## 5. Documentation API

### `AlertService` (`lib/modules/alerts/services/alert_service.dart`)

| Méthode | Description |
|---|---|
| `getAlerts({status, type, severity, userId, pharmacyId, unreadOnly, limit})` | Liste les alertes visibles par l'utilisateur courant (RLS), avec filtres optionnels |
| `getAlert(id)` | Une alerte par id |
| `getUnreadCount({userId, pharmacyId})` | Nombre d'alertes non lues |
| `markAsRead(id)` / `markAllAsRead({userId, pharmacyId})` | Marque lu |
| `dismissAlert(id)` | Ignore une alerte |
| `markAsActioned(id)` | Marque traitée |
| `createAlert({...})` | Création générique + notification best-effort selon préférences |
| `getPreferences()` / `updatePreferences(prefs)` | Préférences de notification de l'utilisateur courant |
| `generateStockAlert({productName, quantity, stockItemId, pharmacyId, thresholdLow, thresholdCritical})` | **Signature modifiée ce module** — `thresholdLow`/`thresholdCritical` désormais obligatoires (plus de défaut 20/5 codé en dur). Anti-doublon intégré |
| `generateExpiryAlert({productName, batchNumber, expiryDate, batchId, pharmacyId, daysThreshold = 30})` | Anti-doublon intégré |

### `AlertProvider` (`lib/modules/alerts/providers/alert_provider.dart`)

`loadAlerts({..., userId})` (paramètre `userId` désormais utilisé pour le cache hors-ligne), `loadAlert(id)`, `loadPreferences()`, `markAsRead/markAllAsRead/dismissAlert/markAsActioned`, `updatePreferences`, `clearSelected`, `clearError`. Nouveaux getters : `isOffline`.

### Routes ajoutées

`/alerts/detail/:id` → `AlertDetailScreen`.

---

## 6. Scénarios de test (non exécutés dans cette session — voir limite ci-dessous)

Cette session ne dispose ni de SDK Flutter/Dart, ni d'accès CLI Supabase, ni d'appareil/émulateur (même limite déjà documentée pour les Modules 4 à 8). Les scénarios suivants sont écrits pour exécution sur un environnement outillé, et la relecture manuelle du code modifié (dry-run ligne à ligne de `AlertService`/`StockProvider._generateStockAndExpiryAlerts`) n'a révélé aucune anomalie supplémentaire.

1. **Génération d'alerte stock faible réelle** : ajuster le stock d'un produit sous son `thresholdLow`, ouvrir « Alertes de stock », vérifier qu'une ligne `alerts` (type `stockLow`, `pharmacy_id` renseigné) apparaît, et que le Centre d'alertes patient/pharmacien la montre.
2. **Anti-doublon** : rouvrir l'écran une seconde fois sans changement de stock — vérifier qu'aucune deuxième ligne `alerts` n'est créée.
3. **Escalade** : faire passer le même produit sous `thresholdCritical` — vérifier qu'une nouvelle alerte `stockCritical` est bien créée (pas bloquée par l'anti-doublon, car type différent).
4. **Alerte péremption** : créer un lot à J+45 (dans l'horizon 60 jours), ouvrir « Alertes de stock », vérifier la création d'une alerte `expirySoon`.
5. **RLS — non-régression** : tenter, avec un compte `patient`, de lire/écrire une alerte `pharmacy_id` d'une officine à laquelle il n'est pas rattaché — doit échouer.
6. **RLS — staff croisé** : avec un compte pharmacien d'une officine A, tenter de lire/agir sur une alerte de l'officine B — doit échouer.
7. **Écran de détail** : cliquer une alerte dans le Centre d'alertes → vérifie l'ouverture du détail, le marquage automatique en lu, l'affichage de la recommandation, et que les boutons Traiter/Ignorer fonctionnent.
8. **Mode hors-ligne** : charger le Centre d'alertes en ligne (peuple le cache), couper le réseau, rouvrir l'écran — vérifier l'affichage du bandeau "Hors ligne" et des alertes en cache.

---

## 7. Livrables de ce module

- `supabase/migrations/20260829020000_alerts_module_fixes.sql` (nouveau) — correctifs RLS.
- `lib/modules/alerts/services/alert_service.dart` — anti-doublon, seuils réels.
- `lib/modules/alerts/models/alert.dart` — getter `recommendation`.
- `lib/modules/alerts/providers/alert_provider.dart` — cache hors-ligne, `isOffline`.
- `lib/modules/alerts/screens/alert_center_screen.dart` — navigation vers le détail, bandeau hors-ligne, `userId` réel.
- `lib/modules/alerts/screens/alert_detail_screen.dart` (nouveau) — écran manquant du cahier.
- `lib/modules/stock/providers/stock_provider.dart` — câblage des générateurs d'alerte.
- `lib/core/services/offline_sync_service.dart` — `cache_alerts` (schéma v8).
- `lib/routes/app_router.dart` — route `/alerts/detail/:id`.
- `PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A17, C35, C36, B18, D6 8ème occurrence, D15, D16 ; B9/B2/B7 etc. inchangés).

### Écarts documentés, non corrigés dans ce module (décisions à trancher — voir registre)

- **D15** — écran « Paramétrage des seuils » manquant (RLS déjà prête, UI à construire).
- **D16** — alerte surstock et détection de fraude/anomalies : fonctionnalités clés du cahier, aucune RG ne les impose, non construites (nécessitent un calcul de vélocité de ventes, territoire IA/BI).
- **B18** — RG-ALR-01 : seuil statique retenu en l'absence de calcul de consommation moyenne réel.
- **A17** — mode hors-ligne (lecture) et déclenchement d'alerte non exercés sur appareil réel.

---

**Le module Alertes intelligentes (ALR) est-il totalement clos et validé pour passer au suivant ?**
