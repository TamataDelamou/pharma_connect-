# Phase 8 — Correction des erreurs de compilation dans `test/` : rapport de clôture

**Statut : clôturée (20/09/2026).** Tâche mécanique de fond, sans décision de règle métier tranchée par Claude Code — les points nécessitant un arbitrage sont consignés en section 5 et au registre (`PharmaConnect_Registre_Ecarts_A_Verifier.md`, tickets C150-C152, D50), pas décidés ici.

## 0. Périmètre effectivement respecté

- Aucun fichier `lib/` ni `supabase/migrations/` modifié.
- Cluster hors-cahier (`business`, `pos`, `cash`, `sales`, `returns`) non traité en priorité, conformément à la règle du jeu — un seul contact avec ce cluster, en lecture seule, documenté en section 4 (C150/C151).
- 2 fichiers `test/` modifiés, 1 commit (`bf2be9c`), fichiers listés explicitement (pas de `git add -A`).

## 1. Étape préalable — inspection & chiffre réel

```
flutter pub get
flutter analyze test/ 2>&1 | tee phase8_analyze.log
flutter test 2>&1 | tee phase8_test.log
```

**Le chiffre de 97 annoncé en tête de ce document est corrigé** : il correspondait à l'état constaté par le commit `c469ce3` (« align unit test harness for 17 cahier provider test files »), déjà appliqué **avant** l'ouverture de cette Phase 8 — 97 erreurs de compilation sur 19 fichiers de `test/unit/providers/`, 17 fichiers « cahier » corrigés dans ce commit, 2 fichiers hors-cahier (`business`, `pos`) volontairement laissés de côté sous le même mur que le code qu'ils testent.

**Chiffre réel constaté à l'ouverture de Phase 8** (après ce commit, donc l'état de départ réel de cette tâche) :

| Vérification | Résultat |
|---|---|
| `flutter analyze test/` | **6 erreurs**, 0 avertissement nouveau — 100 % dans `business_provider_test.dart` (3) et `pos_provider_test.dart` (3), cluster hors-cahier |
| `flutter test` | **70 passants / 28 échecs** |

Des 28 échecs de `flutter test`, seuls **3** sont de vraies erreurs de compilation/chargement (`loading ... [E]`) : `business_provider_test.dart`, `pos_provider_test.dart` (correspondant aux 6 erreurs analyze), et **`test/widget_test.dart`** — celui-ci pour une raison sans rapport avec `test/` (voir §4, C150). Les **25** échecs restants sont des échecs d'exécution (assertions/exceptions runtime), pas des défauts de compilation — voir §4, C152.

## 2. Corrections mécaniques appliquées

**1 lot, 1 catégorie : provider manquant dans l'arbre de test d'un widget (`ProviderNotFoundException`).**

| Fichier | Défaut | Correction |
|---|---|---|
| `test/widget/screens/dashboard_screen_test.dart` | `DashboardScreen` lit `AuthProvider` (rôle affiché) en plus de `DashboardProvider` ; absent du wrapper de test → `ProviderNotFoundException` à la construction. Une fois `AuthProvider` ajouté, second défaut révélé : `AuthProvider` → `AuthService` touche `SupabaseService().auth` dès son constructeur → nécessite `Supabase.initialize()`, absent de ce fichier (présent partout ailleurs dans le dépôt). | `MultiProvider` avec `AuthProvider` + `DashboardProvider` ; ajout du bloc `setUpAll`/`Supabase.initialize()` standard déjà utilisé dans les ~20 autres fichiers de test du dépôt. |
| `test/widget/screens/wallet_screen_test.dart` | `WalletScreen.initState()` lit `context.read<AuthProvider>().userId` avant d'appeler `PaymentProvider` ; `AuthProvider` absent du wrapper de test → `ProviderNotFoundException`. | `MultiProvider` avec `AuthProvider` + `PaymentProvider` (le `Supabase.initialize()` existait déjà dans ce fichier). |

Ni l'un ni l'autre ne change ce que le test vérifie (`tester.takeException()` doit toujours être `null`, l'écran doit toujours se construire) ni le comportement de `lib/` — uniquement la complétude du décor de test.

**Vérifié avant commit** : `flutter test test/widget/screens/dashboard_screen_test.dart test/widget/screens/wallet_screen_test.dart` → 2/2 passants. `flutter analyze` sur les 2 fichiers → 0 issue. Suite complète rejouée après coup : **72 passants / 26 échecs** (+2/-2 par rapport au chiffre de départ).

**Commit** : `bf2be9c fix(test): wrap DashboardScreen/WalletScreen tests with missing AuthProvider` (2 fichiers listés explicitement, pas de `git add -A`).

## 3. Tickets `C15x` non résolus, consignés au registre

| Ticket | Nature | Pourquoi non corrigé ce tour |
|---|---|---|
| **C150** — **priorité la plus haute de ce rapport** | `lib/modules/returns/models/customer_return_item.dart` (cluster hors-cahier `returns`) : constructeur, `copyWith()`, `toJson()`, `fromJson()` sont des placeholders littéraux `{...}` jamais implémentés. `lib/app.dart` importe transitivement ce fichier (via `returns_provider.dart`) — ce défaut de compilation bloque **`flutter build`/`flutter run` du produit entier**, pas seulement `test/widget_test.dart` (seul test qui pompe l'app complète et donc seul à le révéler). Fichier non committé (jamais dans l'historique git). | `lib/`, interdit par le périmètre Phase 8 ; module du cluster hors-cahier. Signalé néanmoins en priorité absolue car neutralisable sans trancher aucune question de conception (contrairement au reste du cluster) — recommande de ne pas attendre la session de cadrage de 30 min pour ce point précis. |
| **C151** | `business_provider_test.dart`/`pos_provider_test.dart` (6 erreurs analyze) : accès direct à des champs privés (`provider._error = ...`) sans setter `@visibleForTesting`, motif désormais standard (voir `c469ce3`) non appliqué ici ; de plus `business_service.dart` a ses propres erreurs de compilation (`.eq()`/`.or()` non définis sur `PostgrestTransformBuilder` — usage incompatible avec la version installée de `postgrest`). | Correction test-only impossible : même en réécrivant le test, `business_service.dart` (`lib/`, hors-cahier) resterait non compilable. Ne bloque pas la compilation globale de `test/` (package:test isole chaque fichier), donc pas d'exception mécanique à appliquer. |
| **C152** | 24 échecs `flutter test` restants (25 à l'ouverture, 1 déjà résolu en marge — voir note), aucun n'étant un défaut de compilation ni une régression de règle métier identifiable : **(a)** 19 tests (12 unitaires + 7 widgets en cascade) où un provider appelle une vraie méthode réseau (`loadX()`) sans aucun mock HTTP/Supabase — `Supabase.initialize()` pointe vers `https://example.supabase.co`, une URL fictive qui **répond réellement** (`PostgrestException code 400`, le sous-domaine résout via le DNS générique `*.supabase.co`) plutôt que d'échouer silencieusement ; **(b)** 5 tests (4 unitaires + 1 widget en cascade) où `OfflineSyncService` (cache hors-ligne, plugin `sqflite` réel) échoue avec `Bad state: databaseFactory not initialized`, `sqflite_common_ffi` n'étant pas configuré (ni même présent dans `pubspec.yaml`) pour l'environnement de test pur Dart. | Corriger proprement demande soit une vraie couche de mock réseau par test (refonte méthodologique, pas mécanique), soit une nouvelle dépendance de test (`sqflite_common_ffi`) — deux décisions de méthodologie, remontées en section 5 / **D50** plutôt que tranchées ici. |

*Note sur le compte : `stock_provider_test.dart: StockProvider loadStockItem() ... (incohérence connue)` fait partie des 24 de C152 (cause (a)) — son propre nom indique qu'un auteur précédent l'avait déjà repéré et documenté comme connu ; regroupé sous C152 plutôt que renuméroté séparément.*

## 4. Sortie finale

`flutter analyze test/` :
```
6 issues found. (business_provider_test.dart ×3, pos_provider_test.dart ×3 — cluster hors-cahier, voir C151)
```

`flutter test` :
```
72 passants / 26 échecs
  - 3 échecs de chargement/compilation : business_provider_test.dart, pos_provider_test.dart (C151),
    test/widget_test.dart (C150, defaut lib/ hors-cahier, hors perimetre test/)
  - 23 echecs runtime (C152, causes systemiques (a)/(b) ci-dessus)
```

**0 erreur de compilation n'est pas atteint globalement**, mais **0 erreur de compilation est atteint sur tout le périmètre cahier** (tout ce qui n'est pas `business`/`pos`/`returns`) — les 3 restantes sont toutes rattachées au mur hors-cahier déjà en vigueur, avec un cas (C150) dont l'impact dépasse ce mur et mérite une attention immédiate indépendante du calendrier de cadrage.

## 5. Décisions de règle métier / méthodologie remontées

Aucune décision de **règle métier (RG-\*)** rencontrée ce tour — cohérent avec la nature mécanique de la tâche.

Deux décisions de **méthodologie/priorisation** à trancher par le porteur du projet, ni l'une ni l'autre tranchée par Claude Code :

1. **C150 (returns, compilation de l'app entière)** : traiter maintenant (neutralisation simple : implémenter réellement les 4 méthodes placeholder, ou retirer temporairement l'import dans `returns_provider.dart` le temps de la session de cadrage) ou attendre la session de cadrage de 30 min déjà prévue pour le cluster `business/pos/cash/sales/returns` ? Le dilemme : c'est le seul point de ce cluster qui bloque autre chose que ses propres tests.
2. **D50 (mocking réseau/sqflite pour 24 tests)** : investir dans un vrai harnais de mock HTTP/Supabase + `sqflite_common_ffi` pour ces tests « nominaux », les faire migrer vers le style `@visibleForTesting`-only déjà utilisé par les 17 fichiers de `c469ce3` (qui n'exercent jamais le réseau réel), ou acter cet état comme connu et documenté sans investissement supplémentaire ?

---

**Question à trancher par le porteur du projet :** la Phase 8 est-elle close (périmètre cahier à 0 erreur de compilation, tickets C150-C152/D50 actés au registre) pour enchaîner sur le Module 29 (CSR) ? Note : Module 29/CSR est déjà en cours d'audit dans ce dépôt (Étapes 1 et 3 déjà traitées séparément) — à confirmer si cette question visait sa poursuite ou sa clôture finale.
