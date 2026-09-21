# C151 — Correctif `business_service.dart` (chaînage Postgrest) + tests `business_provider_test.dart` / `pos_provider_test.dart`

**Rédigé par :** session d'audit (Cowork). Contrairement à C150/C154/C155, ce correctif a été entièrement pré-diagnostiqué par lecture directe des fichiers (pas de `flutter`/`dart` disponible dans mon pont machine, mais le diagnostic ne nécessitait pas de l'exécuter). Les 4 emplacements ci-dessous sont donnés avec leur contenu exact avant/après — aucune investigation supplémentaire n'est requise avant de corriger.
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 20/09/2026
**Contexte :** cadrage du cluster hors-cahier clos (D51/D52 au registre). C151 était le dernier correctif mécanique en attente, identique dans son principe à C155 déjà validé (`returns_service.dart`) — périmètre acté, aucune règle métier en jeu.

**Correction apportée à la description initiale de C151** (celle du document de cadrage `PharmaConnect_Cadrage_Cluster_HorsCahier.md`, §6) : elle indiquait « 6 erreurs `flutter analyze` sur `business_provider_test.dart`/`pos_provider_test.dart` : accès à des champs privés sans setter `@visibleForTesting` » pour les **deux** fichiers. En relisant les deux fichiers directement, seul `business_provider_test.dart` accède à des champs privés (`provider._error`, `provider._selectedCompany`). `pos_provider_test.dart` n'accède à aucun champ privé : son seul défaut est un import manquant (`POSSaleItem` utilisé sans être importé). Les instructions ci-dessous reflètent le constat réel, pas la description initiale.

---

## 0. Périmètre

4 fichiers, aucun autre :
- `lib/modules/business/services/business_service.dart`
- `lib/modules/business/providers/business_provider.dart`
- `test/unit/providers/business_provider_test.dart`
- `test/unit/providers/pos_provider_test.dart`

Ne rien toucher d'autre, en particulier pas `pos_provider.dart` (aucun défaut trouvé dedans) ni `pos_service.dart` (hors périmètre C151, concerné par C156 séparément).

## 1. `lib/modules/business/services/business_service.dart` — chaînage Postgrest (même motif que C155)

Même défaut que celui déjà corrigé sur `returns_service.dart` : `.order()` est appelé sur le query builder **avant** les filtres `.eq()`, alors que `.order()` retourne un `PostgrestTransformBuilder` qui n'expose plus `.eq()`/`.or()` ensuite.

**`getCompanies()` (lignes 18-21 et 37) :**

Avant :
```dart
      var query = _client
          .from('business_companies')
          .select()
          .order('name', ascending: true);

      if (type != null) {
        query = query.eq('type', type);
      }
      ...
      final response = await query;
```

Après :
```dart
      var query = _client
          .from('business_companies')
          .select();

      if (type != null) {
        query = query.eq('type', type);
      }
      ...
      final response = await query.order('name', ascending: true);
```

**`getContracts()` (lignes 120-123 et 132) :** même correction, avec `.order('start_date', ascending: false)`.

Avant :
```dart
      var query = _client
          .from('business_contracts')
          .select()
          .order('start_date', ascending: false);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      ...
      final response = await query;
```

Après :
```dart
      var query = _client
          .from('business_contracts')
          .select();

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      ...
      final response = await query.order('start_date', ascending: false);
```

Ne rien changer d'autre dans ce fichier (en particulier, ne pas toucher `company.status ?? 'pending'` / `contract.status ?? 'draft'` — c'est C149, hors périmètre de ce correctif).

## 2. `lib/modules/business/providers/business_provider.dart` — setters `@visibleForTesting`

Motif déjà en usage dans ce dépôt, exemple exact à reproduire : `lib/modules/analytics/providers/analytics_provider.dart` (setters `errorForTest`/`selectedDashboardForTest`, appelés depuis `test/unit/providers/analytics_provider_test.dart`).

Ajouter, juste après les getters existants (après la ligne `String? get error => _error;`) :

```dart
  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedCompanyForTest(BusinessCompany? value) =>
      _selectedCompany = value;
```

Pas de nouvel import requis : `package:flutter/material.dart` (déjà importé en tête de fichier) réexporte `@visibleForTesting`.

## 3. `test/unit/providers/business_provider_test.dart`

1. Ajouter l'import manquant, avec les autres imports en tête de fichier :
   ```dart
   import 'package:pharma_connect/modules/business/models/business_company.dart';
   ```
2. Ligne 22, remplacer :
   ```dart
   provider._error = 'error';
   ```
   par :
   ```dart
   provider.errorForTest = 'error';
   ```
3. Ligne 28, remplacer :
   ```dart
   provider._selectedCompany = BusinessCompany(
   ```
   par :
   ```dart
   provider.selectedCompanyForTest = BusinessCompany(
   ```
   (le reste de l'appel — `id`, `name`, `type`, `createdAt`, `updatedAt` — ne change pas, déjà cohérent avec le constructeur réel de `BusinessCompany`.)

## 4. `test/unit/providers/pos_provider_test.dart`

Un seul défaut réel : `POSSaleItem` est utilisé (lignes 23 et suivantes) sans être importé — `pos_provider.dart` importe le modèle en privé (`import '../models/pos_sale_item.dart';`, pas de `export`), donc ce n'est pas visible depuis un fichier qui importe seulement `pos_provider.dart`.

Ajouter, avec les autres imports en tête de fichier :
```dart
import 'package:pharma_connect/modules/pos/models/pos_sale_item.dart';
```

Ne rien ajouter d'autre : aucun champ privé n'est accédé dans ce fichier, donc aucun setter `@visibleForTesting` n'est nécessaire sur `POSProvider`. Si `flutter analyze` signale malgré tout une erreur dans ce fichier après cet ajout, ne pas improviser de correctif — la consigner en section 6 ci-dessous plutôt que de deviner une règle métier.

## 5. Vérification et commit

1. `flutter analyze lib/modules/business/services/business_service.dart lib/modules/business/providers/business_provider.dart test/unit/providers/business_provider_test.dart test/unit/providers/pos_provider_test.dart`
2. `flutter test test/unit/providers/business_provider_test.dart test/unit/providers/pos_provider_test.dart`
3. Puis `flutter analyze lib/` et `flutter test` complets, pour confirmer qu'aucune régression n'a été introduite ailleurs et obtenir le nouveau total (dernier connu : 169 erreurs analyze restantes après C155, hors C156).
4. Un seul commit, fichiers listés explicitement (pas de `git add -A`) :
   `fix(business): correct Postgrest filter chaining and test visibility (C151)`

## 6. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

*(Section à compléter uniquement si un point de règle métier apparaît en cours de correctif — ne pas trancher, décrire et attendre l'arbitrage du porteur du projet.)*

---

**Rapport attendu en retour :** confirmation du diff appliqué (ou explication précise si un point ne correspond pas à ce qui est décrit ci-dessus — a été observé plusieurs fois sur ce dépôt que le périmètre réel dépasse parfois le constat initial), + nombre d'erreurs `flutter analyze lib/` avant/après, + résultat `flutter test`. Je mets à jour le registre (C151 → résolu) une fois ce retour vérifié.
