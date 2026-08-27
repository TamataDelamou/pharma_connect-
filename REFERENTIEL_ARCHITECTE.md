# Référentiel de Conception — PharmaConnect
### À l'attention de l'Architecte en Chef

Ce document synthétise trois sources déjà maintenues dans ce dépôt — il ne les remplace pas, il les met en musique pour orienter la conception des modules restants :

- **`CLAUDE.md`** — contexte du portefeuille GSG et règles du Kernel v3.0 (KER-*), communes à tous les produits.
- **`PharmaConnect_CLAUDE.md`** — état vivant du code : ce qui existe réellement, à mettre à jour à chaque changement structurant. C'est la source de vérité sur « qu'est-ce qui est codé aujourd'hui ».
- **`code_export_architecte.md`** — export complet du code source + rapport d'audit du 24/08/2026 (149 signalements → 0, 87 erreurs bloquantes corrigées).

Ce document répond à une question différente des trois autres : **comment concevoir les 27 modules qui restent à écrire, sans reproduire les écarts déjà corrigés une fois.**

*Mise à jour du 24/08/2026 : `CLAUDE.md` et `PharmaConnect_CLAUDE.md` ont formalisé une nouvelle règle — **KER-DES-03** (contrat de tokens sémantiques du futur GSG Design Kit, à respecter dès aujourd'hui même avant son adoption). Elle a révélé un écart concret déjà présent dans le code : 27 couleurs littérales dans 5 modèles de statut. Corrigé (§2, point 9) et intégré au gabarit obligatoire (§4.1) et à la checklist de démarrage (§6) pour ne pas être réintroduit.*

> **Mise à jour du 25/08/2026 — la mise en garde ci-dessus n'a pas suffi.** Six modules ont été codés entre le 24 et le 25/08 (`stock`, `traceability`, `coldchain`, `recall`, `admin`, `alerts` — 86 fichiers) sans que ce document ne soit consulté ni mis à jour, et sans passer par la checklist §4.2. Conséquence directe et vérifiable : le module `traceability` reproduit *exactement* l'anti-motif que le paragraphe précédent décrit comme corrigé — 18 nouvelles couleurs littérales, le même gabarit `statusColor` copié-collé. Le projet a par ailleurs cessé de compiler dans l'intervalle (`pubspec.yaml` invalide). Détail complet en §2 (points 10-13) et §3.5-3.6. La leçon à tirer n'est pas seulement technique : **ce document n'a de valeur que si l'architecte codeur le consulte avant d'ouvrir un nouveau module — pas seulement en fin de session.**



---

## 1. Où en est le produit — résumé

*Tableau du 24/08/2026, laissé pour mémoire — voir la version datée du 25/08 juste en dessous, sensiblement différente.*

| | |
|---|---|
| Modules avec code réel | 7 / 34 : `auth`, `dashboard`, `search`, `prescriptions`, `reservations`, `delivery`, `payments` |
| Modules vides | 27 (voir §4.3) |
| Écrans placeholder | 13 (coquilles qui compilent, sans UI/logique métier — `core/widgets/screens/placeholder_screen.dart`) |
| Migrations Supabase | 0 — le schéma n'existe qu'en Dart côté client |
| Kernel GSG | Non branché — URL placeholder dans `gsg_kernel_auth_bridge.dart`, mode dégradé assumé partout |
| Tests | 1 seul test (démarrage) ; `test/unit/` et `test/widget/` vides |
| `flutter analyze` | 0 signalement |
| CI | `.github/workflows/kernel-compliance.yml` — 3 garde-fous KER-* + `flutter analyze` |

### 1 bis. Où en est le produit — 25/08/2026

| | |
|---|---|
| Modules avec code réel | 14 / 33 dossiers (+ `catalog`, ajouté le 24/08 et déjà compté ci-dessus au fil de l'eau ; `eprescription` n'a même pas de dossier) : `auth`, `dashboard`, `search`, `catalog`, `prescriptions`, `reservations`, `delivery`, `payments`, et depuis le 25/08 `stock`, `traceability`, `coldchain`, `recall`, `admin`, `alerts` |
| Modules vides | 20 (voir §4.3, revu) |
| Écrans placeholder | 17 (13 du 24/08 + 4 ajoutés le 25/08 pour que le routeur compile : `EquipmentAddScreen`, `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`) |
| Migrations Supabase | 0 — toujours — le schéma n'existe qu'en Dart côté client, y compris pour les 6 nouveaux modules |
| Kernel GSG | Non branché — inchangé depuis le 24/08 |
| Tests | 1 seul test (démarrage), inchangé — protège désormais 178 fichiers Dart au lieu de ~90 |
| `flutter analyze` | 0 erreur (216 le 25/08 au matin, cause : `pubspec.yaml` invalide + 6 modules non intégrés — voir §2 points 10-13), 83 avertissements/infos |
| CI | Le fichier workflow existe mais **ne s'est jamais exécuté** — pas de dépôt git dans ce répertoire (voir §3.6) |

Détail vivant et à jour → **`PharmaConnect_CLAUDE.md`**.

### 1 ter. Où en est le produit — 27/08/2026

| | |
|---|---|
| Modules avec code réel | 14 / 33 — inchangé depuis le 25/08, aucun nouveau module démarré cette session |
| Écrans placeholder | **1 restant** (`PlaceholderScreen(title: 'Détail de la transaction #$id')` sur `/transactions/:id`) — sur les 17 recensés le 25/08, 8 se sont révélés déjà réels à l'audit, 9 ont été réécrits ; ce dernier n'était pas dans la liste des 17 (écran de détail, pas l'écran principal du chantier « historique »), découvert au passage |
| Migrations Supabase | 15 fichiers dans `supabase/migrations/`, 33 tables couvrant les 14 modules avec code réel — le schéma existe désormais aussi côté SQL, pas seulement côté Dart. Aucun projet Supabase réel provisionné derrière (`supabase_service.dart` a toujours ses placeholders) — voir `PharmaConnect_CLAUDE.md`, chantier 2b |
| Kernel GSG | Non branché — inchangé |
| Tests | **42 tests** (1 test de démarrage + 27 unitaires dans `test/unit/providers/`, un par provider + 14 widget dans `test/widget/screens/`, un par écran principal de module) — contre 1 seul le 25/08. Voir §5.5 |
| `flutter analyze` | 0 erreur, ~66 infos de style pré-existantes non bloquantes |
| CI | `flutter test` fait désormais partie de `.github/workflows/kernel-compliance.yml` — les 42 tests s'exécutent réellement à chaque push/PR, pas seulement les 3 garde-fous KER-* + `flutter analyze` |

Deux trouvailles significatives cette session, corrigées avant que les tests ne les masquent en échouant silencieusement ailleurs — détail complet → §2 points 14-15 et `PharmaConnect_CLAUDE.md` :
- 6 providers sur 14 n'étaient jamais enregistrés dans le `MultiProvider` racine (`app.dart`) — un crash garanti (`ProviderNotFoundException`) sur 20 écrans de production, invisible faute de test qui construise ces écrans.
- `recall_dashboard_screen.dart` avait un dépassement de mise en page (`RenderFlex overflowed`) et une erreur de type sur un graphique (`int` passé où `BarChartRodData.toY` exige un `double`) — les deux trouvés par le premier test widget jamais écrit pour cet écran.

Détail vivant et à jour → **`PharmaConnect_CLAUDE.md`**, sections « Mise à jour (27/08/2026) ».

---

## 2. Corrections déjà appliquées — ne pas les réintroduire

Résumé condensé de l'audit du 24/08/2026 (détail complet et diffs → `code_export_architecte.md`, section « Rapport d'audit »). Chaque point ci-dessous est désormais une règle vivante, pas juste un historique :

1. **Imports non transitifs** — en Dart, importer un provider n'importe pas les types qu'il utilise. Chaque écran/widget doit importer directement les modèles et enums qu'il référence.
2. **Enums fantômes** — `TransactionStatus`, `InstallmentStatus` étaient importés depuis des fichiers qui n'existaient pas, ou dupliqués. Un enum de statut vit dans **un seul** fichier (`xxx_status.dart`), jamais réimporté depuis un chemin inventé.
3. **Écrans référencés mais jamais écrits** — le routeur (`app_router.dart`) ne doit jamais référencer une classe qui n'existe pas. Si un écran n'est pas prêt, c'est un `PlaceholderScreen` explicite, jamais une classe fantôme.
4. **Bug de type** — `getWalletBalance()` déclarait `Future<double>` et renvoyait un `int`. Toujours faire correspondre le type de retour déclaré au type réellement renvoyé.
5. **`.withOpacity()` déprécié** → `.withValues(alpha:)` partout.
6. **Backend OTP orphelin** — un backend Edge Functions parallèle (génération de code, wrapper Resend/Meta Cloud API, signature JWT manuelle) existait sans être appelé par l'app, en contournement direct de Supabase Auth natif. **Supprimé.** Ne jamais réintroduire de génération d'OTP ou de signature de token côté produit — voir §5.3.
7. **Statut Kernel simulé** — le badge sidebar affichait `isConnected: true` et « 4/4 services en ligne » en dur, sans aucun appel réseau réel. **Corrigé** pour refléter honnêtement l'absence d'intégration (`Non connecté (Dev)`). Ne jamais coder en dur un état "connecté" dans l'UI.
8. **Devise codée en dur** — 10 occurrences de `'... GNF'` littéral. Centralisées dans `CurrencyFormatter`.
9. **Couleurs de statut codées en dur (KER-DES-03)** — 27 occurrences de `Color(0xFF...)` littéral dans les getters `statusColor`/`stockColor` de 5 modèles (`delivery.dart`, `transaction.dart`, `prescription.dart`, `reservation.dart`, `availability_result.dart`), le même gabarit reproduit à l'identique à chaque fois. Deux tokens manquants ajoutés à `PharmaConnectColors` (`neutralMuted`, `accentAmber`), les 27 littéraux remplacés par la constante correspondante, garde-fou CI `scripts/ci/check_no_hardcoded_color.sh` ajouté. Ne jamais réintroduire un `Color(0xFF...)` littéral hors de `lib/core/theme/` — voir §4.1 pour la règle intégrée au gabarit.

**Corrections du 25/08/2026** — suite à l'ajout non documenté de 6 modules (§ note en tête de document) :

10. **`pubspec.yaml` invalide** — trois dépendances déclarées deux fois chacune (`image_picker`, `flutter_local_notifications`, `qr_flutter`), un YAML avec clé dupliquée n'étant pas valide. `flutter pub get` levait une exception avant même d'atteindre l'analyseur : **le projet entier était à l'arrêt**, pas seulement en défaut de qualité. Dédoublonné, dépendances regroupées par thème.
11. **Dépendance abandonnée (`tesseract_ocr`)** — utilisée par `OcrService` pour l'OCR d'ordonnances, jamais migrée au null-safety, incompatible avec le SDK Dart actuel. Remplacée par `google_mlkit_text_recognition` (reconnaissance de texte on-device maintenue) ; interface publique de `OcrService` inchangée pour ses appelants.
12. **`return` comme membre d'enum** — `StockMovementType.return` et `BatchMovementType.return` : `return` est un mot réservé Dart, invalide comme identifiant, empêchait la compilation des deux fichiers. Renommés `supplierReturn` / `customerReturn`.
13. **8 fichiers référencés, jamais créés** — 4 écrans routés depuis `app_router.dart` (`EquipmentAddScreen`, `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`) et 3 widgets importés par `search_screen.dart` (`SearchSkeleton`, `SearchEmptyState`, `SearchErrorState`) n'existaient sur le disque sous aucune forme. Mêmes causes, même remède qu'au point 3 : les 4 écrans utilisent `PlaceholderScreen`, les 3 widgets de recherche ont été écrits en respectant les appels déjà présents dans `search_screen.dart` (ce ne sont pas des coquilles vides, contrairement aux écrans).

Le détail complet des 216 erreurs corrigées le 25/08 (216 → 0, sur 54 fichiers) → `code_export_architecte.md`, section « Rapport d'audit — 25 août 2026 ».

**Corrections du 27/08/2026** — trouvées en écrivant la couverture de tests (§5.5), pas en développant un nouveau module, ce qui montre exactement pourquoi §5.5 existe :

14. **Provider créé mais jamais enregistré dans `app.dart`** — un nouveau `ChangeNotifierProvider` doit être ajouté au `MultiProvider` racine de `app.dart` **au moment où le provider est créé**, pas seulement quand un écran commence à l'utiliser. `AdminProvider`, `AlertProvider`, `ColdChainProvider`, `RecallProvider`, `StockProvider` et `TraceabilityProvider` ont existé pendant toute la session du 25/08 sans jamais être enregistrés, alors que 20 écrans dans ces 6 modules appellent déjà `context.read<X>()`/`context.watch<X>()` dessus — un crash `ProviderNotFoundException` garanti à la navigation, resté invisible faute d'un seul test qui construise ces écrans. Les 6 providers manquants ont été ajoutés à `app.dart`. Voir §6, nouvel item de checklist.
15. **Valeur de repli entière passée à une API qui exige un `double`** — `(provider.statistics['averageCompletionRate'] ?? 0) * 100` dans `recall_dashboard_screen.dart` : le littéral `0` du repli est un `int`, donc `int * int = int`, rejeté par `BarChartRodData.toY` qui exige un `double`. Se déclenchait dès que la statistique n'était pas encore chargée — un cas normal en tout début de vie de l'écran, pas un cas limite rare. Règle générale : tout repli `?? 0`/`?? 0.0` doit avoir le même type que le reste de l'expression ; si l'expression finale doit être un `double`, écrire `?? 0.0` ou caster explicitement (`.toDouble()`), jamais `?? 0` suivi d'une opération arithmétique.

---

## 3. Écarts encore ouverts — à corriger

Distinction volontaire : ce qui suit sont des **déviations par rapport aux règles déjà écrites** (CLAUDE.md, KER-*), pas simplement du travail non commencé. Le travail non commencé (les 27 modules, les 13 écrans) est traité au §4, pas ici.

### 3.1 — Montants stockés en `double`, pas en unité mineure entière (KER-REF-05)

**Règle du Kernel :** *« Tout montant est stocké en unité mineure entière (ex. centimes). »*

**Constat :** tous les champs monétaires du code actuel sont des `double` :
- `Transaction.amount`, `.fee`, `.cashback` ([transaction.dart](lib/modules/payments/models/transaction.dart))
- `Installment.totalAmount`, `.amountPerPayment`, `InstallmentPayment.amount` ([installment.dart](lib/modules/payments/models/installment.dart))
- `Reservation.totalPrice`, `ReservationItem.pricePerUnit` ([reservation.dart](lib/modules/reservations/models/reservation.dart), [reservation_item.dart](lib/modules/reservations/models/reservation_item.dart))
- `PaymentProvider._walletBalance`

Un `double` sur de l'argent accumule des erreurs d'arrondi dès qu'on additionne/multiplie (frais, cashback, échéancier divisé en plusieurs paiements). Le fait que le GNF n'ait pas de sous-unité (0 décimale) ne dispense pas de la règle : l'unité mineure d'une devise à 0 décimale, c'est l'unité elle-même — mais elle doit rester un **entier**, jamais un flottant.

**Plan d'action :** migrer ces champs vers `int` (GNF entier) avant la première vraie persistance Postgres — c'est un changement de type qui casse toute donnée déjà écrite, donc à faire **avant** d'écrire les premières migrations (§4.3, chantier 1), pas après. `CurrencyFormatter.format()` continue de recevoir un `num`, aucun impact côté affichage.

**Résolu (27/08/2026) — constat obsolète, même écart de gouvernance qu'en §3.2 :** vérification directe du code (pas de cette liste) montre que les cinq champs ci-dessus sont déjà tous en `int` — `Transaction.amount/fee/cashback/finalAmount`, `Installment.totalAmount/amountPerPayment`, `InstallmentPayment.amount`, `Reservation.totalPrice`, `ReservationItem.pricePerUnit`, `PaymentProvider._walletBalance` — et qu'aucun champ `double` lié à un montant/prix/solde/frais ne subsiste nulle part dans `lib/`. `CurrencyFormatter.format()` accepte déjà `num`, donc `int` sans modification. Aucune trace de quand ni par qui cette migration a eu lieu (déjà relevé en §3.2 pour `validators.dart` — le même point continue de valoir : le code peut progresser sans que la documentation suive). Section conservée pour l'historique ; ne plus considérer ce point comme un chantier ouvert.

### 3.2 — Téléphones non normalisés E.164

**Règle du portefeuille :** *« Téléphones stockés au format E.164. »* (`CLAUDE.md`)

**Constat :** tous les numéros du code (mocks, hints d'UI) sont écrits avec des espaces : `'+224 612 345 678'` (10 occurrences dans `login_screen.dart`, `register_screen.dart`, `delivery_service.dart`, `payment_service.dart`, `reservation_service.dart`, `search_service.dart`, `payment_screen.dart`). Le format E.164 strict n'a **aucun espace ni séparateur** : `+224612345678`.

`lib/core/utils/validators.dart` existe mais est **vide (0 octet)** — rien ne normalise ni ne valide un numéro saisi aujourd'hui.

**Plan d'action :** implémenter dans `validators.dart` une fonction `normalizeE164(String input)` (retire espaces/tirets, vérifie le préfixe `+`) et l'appeler systématiquement avant tout appel à `AuthService.sendPhoneOtp()` ou toute écriture en base. Les espaces restent acceptables **à l'affichage** (formatage lisible), jamais dans la donnée stockée ou transmise.

**Résolu (26/08/2026) — et correction de trace historique :** un audit du code réel mené ce jour a constaté que `validators.dart` **n'était déjà plus vide** et que `normalizeE164()` était **déjà implémentée et déjà appelée** par `AuthProvider.sendPhoneOtp()` — sans qu'aucune mise à jour de ce fichier ni de `PharmaConnect_CLAUDE.md` ne le documente entre-temps. Même écart de gouvernance que celui décrit en §3.5/§3.6 (correctif non tracé faute de dépôt git), cette fois dans le sens inverse : le code avait progressé sans que la doc suive, plutôt que régressé. Le seul écart qui restait réellement ouvert — les 10 occurrences de numéros écrits avec espaces dans les mocks/hints d'UI — est refermé le même jour par l'ajout de `PhoneInputField` (`lib/modules/auth/widgets/phone_input_field.dart`), qui sépare l'indicatif pays du numéro local et ne laisse remonter au reste de l'app qu'une chaîne déjà passée par `normalizeE164()`. Voir `PharmaConnect_CLAUDE.md`, mise à jour du 26/08/2026, pour le détail.

### 3.3 — Gestion d'erreur incohérente entre modules

**Constat :** `delivery_provider.dart` et `payment_provider.dart` capturent correctement les erreurs (`_error = e.toString(); notifyListeners();`, exposées à l'UI). À l'inverse, `prescription_provider.dart` (6 occurrences), `reservation_provider.dart` (3 occurrences) et `search_provider.dart` (2 occurrences) avalent l'erreur silencieusement :

```dart
} catch (e) {
  // handle error
}
```

Aucun état d'erreur n'est renseigné, aucun log — l'utilisateur voit un écran qui ne se met simplement pas à jour, sans indication de ce qui s'est passé. C'est un vrai risque en usage réel (coupure réseau, erreur serveur) : rien ne distingue « en cours de chargement » de « a échoué en silence ».

**Plan d'action :** aligner ces trois providers sur le patron déjà correct de `delivery_provider.dart`/`payment_provider.dart` — voir §5.1 pour la règle transverse à appliquer à tout nouveau module.

**Résolu partiellement, constat partiellement obsolète (27/08/2026) :** vérification directe du code montre que `prescription_provider.dart` et `reservation_provider.dart` n'avalent déjà plus aucune erreur silencieusement — chaque `catch (e)` y positionne déjà `_error = e.toString()` suivi de `notifyListeners()`, sans trace de quand cette migration a eu lieu (même écart de gouvernance qu'en §3.2). Seul `search_provider.dart` avait un vrai reliquat, plus étendu que documenté ici : 4 `catch` silencieux (`loadSuggestions`, `loadHistory`, `clearHistory` — avec un littéral `// ignore` — et `loadProductAvailability`), pas 2. Les quatre ont été alignés sur le patron `_error = e.toString()`.

Le second symptôme, plus grave que le premier — l'état `_error` était souvent renseigné dans le provider mais jamais lu par l'écran, donc invisible pour l'utilisateur malgré tout — a aussi été trouvé et corrigé : `prescription_detail_screen.dart` affichait un spinner de chargement **infini** en cas d'échec de `loadPrescription()` (jamais de sortie de l'état de chargement, `provider.error` jamais consulté) ; `prescription_list_screen.dart` et `patient_history_screen.dart` traitaient un échec réseau comme une liste vide (« Aucune ordonnance ») plutôt que comme une erreur ; `reservation_checkout_screen.dart` affichait un message d'erreur générique codé en dur au lieu du `provider.error` réel remonté par `createReservation()`. Les quatre corrigés en suivant le patron déjà en usage dans `catalog_list_screen.dart`/`stock_list_screen.dart` (état erreur dédié avec bouton Réessayer, avant l'état vide).

### 3.4 — Chantiers déjà identifiés dans `PharmaConnect_CLAUDE.md`

Rappel de ce qui y est déjà suivi (ne pas dupliquer le détail ici, s'y référer) — état au 27/08/2026, la plupart des points ci-dessous étaient encore ouverts le 25/08 : écrans placeholder (16/17 traités, voir §1 ter), premières migrations Supabase écrites (15 fichiers, §1 ter — configurer un vrai projet Supabase reste ouvert), couverture de tests étoffée (42 tests, §5.5), paquets obsolètes mis à jour (16 dépendances directes, sur une branche dédiée non encore fusionnée). Reste ouvert sans progrès cette session : brancher le Kernel réel.

### 3.5 — Régression KER-DES-03 / KER-REF dans les modules ajoutés le 25/08

Le point §2.9 documentait une correction de 27 couleurs littérales et le point équivalent en §2.8 une correction de 10 chaînes de devise littérales — les deux garde-fous CI existent depuis le 24/08. Le module `traceability`, codé après ces deux corrections, contient pourtant 18 nouvelles occurrences de `Color(0xFF...)` littéral dans `batch_status.dart` et `traceable_batch.dart` — le même getter `statusColor` copié depuis un des 5 modèles déjà corrigés, sans passer par `PharmaConnectColors`. Séparément, 11 chaînes `'... GNF'` littérales ont été trouvées le 25/08 hors de `CurrencyFormatter`, dont 4 dans `payments/` — un module documenté comme déjà conforme au 24/08 (`wallet_screen.dart`, `dispute_screen.dart`, `reconciliation_screen.dart`, `wallet_balance_card.dart`).

**Non corrigé** dans la session du 25/08, volontairement : la substitution littéral → token demande de vérifier, couleur par couleur, quelle constante `PharmaConnectColors` correspond visuellement à chaque hex existant (ou d'en créer une nouvelle si aucune ne correspond) — un arbitrage produit, pas une opération mécanique sûre à automatiser sans revue.

**Plan d'action :** avant le prochain module, traiter ces 29 occurrences avec la même méthode qu'au point §2.9 (recenser les hex uniques, les faire correspondre à un token existant ou en créer un nouveau, remplacer, laisser `check_no_hardcoded_color.sh`/`check_no_hardcoded_currency.sh` confirmer). Utiliser ce chantier comme test de la recommandation §3.6 : le faire *après* avoir initialisé git, pour que la CI existante prouve enfin qu'elle attrape quelque chose.

**Résolu (26-27/08/2026) :** les 18 couleurs littérales de `traceability` (`batch_status.dart`, `traceable_batch.dart`) et celles trouvées dans 8 autres fichiers modèles (`admin_pharmacy.dart`, `alert.dart`, `cold_equipment.dart`, `cold_incident.dart`, `temperature_record.dart`, `recall.dart`, `recall_affected_batch.dart`, `recall_status.dart`, `stock_movement.dart` — 10 fichiers au total, pas seulement les 2 de `traceability`) remplacées par les tokens `PharmaConnectColors` correspondants. `check_no_hardcoded_color.sh` renforcé pour détecter aussi la forme `Colors.<nom>` (il ne couvrait auparavant que `Color(0xFF...)`), scopé sur `lib/modules/*/models/`, avec exclusion de `Colors.white/black/transparent` (204 usages structurels légitimes). Les 11 chaînes `'... GNF'` littérales n'ont pas été retrouvées lors de la vérification directe du code du 27/08 — `CurrencyFormatter` semble déjà systématiquement utilisé ; aucune trace de quand cette partie a été corrigée (même écart de gouvernance qu'en §3.2/§3.3). Les deux garde-fous CI sont verts.

### 3.6 — Absence de dépôt git : le risque le plus élevé de ce rapport

Ce répertoire n'est pas un dépôt git. Conséquence directe, déjà matérialisée une fois : les trois garde-fous CI de `.github/workflows/kernel-compliance.yml` (KER-VIS-03, KER-REF, KER-DES-03) n'ont jamais pu s'exécuter, puisqu'ils sont déclenchés par `push`/`pull_request` — un événement qui ne peut pas se produire sans dépôt distant. La régression du §3.5 est passée inaperçue précisément pour cette raison : le garde-fou qui l'aurait bloquée existait, était correct, et n'a jamais tourné une seule fois.

Second effet, plus large : sans historique, il est impossible de savoir *quand* et *dans quel ordre* les 86 fichiers des 6 nouveaux modules ont été écrits, ni de faire un `git bisect` pour isoler la modification exacte qui a cassé `pubspec.yaml`. Ce rapport a dû reconstituer les faits par déduction (comparaison des dates de documentation vs état du code) — un exercice qui devient impraticable à l'échelle de 34 modules si la pratique se répète.

**Plan d'action, avant tout nouveau module :** `git init`, premier commit sur l'état actuel (216 erreurs corrigées, régressions §3.5 encore ouvertes — un commit honnête, pas un commit qui prétend que tout est propre), puis un dépôt distant pour que `.github/workflows/kernel-compliance.yml` puisse enfin s'exécuter. Sans cela, tout le §5.6 de ce document (« les trois garde-fous ne sont pas optionnels ») reste une déclaration d'intention non vérifiable.

**Résolu (26/08/2026) :** dépôt git initialisé, remote GitHub configuré (dépôt privé), premier push effectué. Le premier run réel du workflow a échoué — pas sur les trois garde-fous KER-*, mais sur `flutter analyze` (assets déclarés non suivis par git, seuil de sortie de la commande plus strict que ce que le projet vise) — corrigé, second run vert. Le §5.6 n'est donc plus une déclaration d'intention non vérifiable : les garde-fous se sont réellement exécutés et ont réellement bloqué un problème (même si ce problème n'était, cette fois, ni une couleur ni une devise codée en dur). Voir `PharmaConnect_CLAUDE.md`, mise à jour du 26/08/2026, pour le détail complet.

---

## 4. Directives de conception — modules à venir

### 4.1 — Gabarit obligatoire par module

Chaque module déjà codé suit la même structure (`models/`, `providers/`, `screens/`, `services/`, `widgets/`) — c'est la convention à reproduire, pas à réinventer par module :

```
lib/modules/<nom_module>/
  models/      → classes de données + enum de statut dans son propre fichier (xxx_status.dart)
               → un éventuel getter statusColor retourne TOUJOURS une constante PharmaConnectColors,
                 jamais un Color(0xFF...) littéral (§2 point 9, KER-DES-03) — c'est le point où le
                 gabarit précédent a dérivé 27 fois de suite, ne pas reproduire l'erreur une 28e fois
  providers/   → ChangeNotifier, état exposé à l'UI, _error TOUJOURS renseigné sur catch (§5.1)
               → enregistré dans le MultiProvider de lib/app.dart AU MOMENT où il est créé, pas
                 quand un écran commence à l'utiliser (§2 point 14) — sinon ProviderNotFoundException
  screens/     → un écran = un fichier ; enregistré dans app_router.dart SEULEMENT s'il existe déjà
  services/    → couche d'accès aux données ; mock aujourd'hui, Supabase demain — même interface publique dans les deux cas (§5.2)
  widgets/     → composants réutilisables internes au module
```

Avant d'écrire le premier fichier d'un nouveau module, remplir la checklist suivante (reprise et adaptée du gabarit portefeuille défini dans `CLAUDE.md`, section « Gabarit à reproduire dans chaque cahier produit ») :

### 4.2 — Checklist Kernel par module (à documenter dans un commentaire d'en-tête du module ou dans `PharmaConnect_CLAUDE.md`)

1. **Briques du noyau consommées** — GSG ID (déjà géré transversalement par `auth`, rien à refaire par module) / Org Registry (`gsg_org_id` si le module a une notion d'organisation — officine, fournisseur...) / GSG Referential (pays/devise/langue via `CurrencyFormatter` et futur équivalent pour pays/langue) / Referential Engine avec `code_domaine = pharmaceutique` si le module modélise une variation réglementaire inter-pays (ex. `regulator`, `insurance`) / Bus d'événements (lister ce qui est publié/consommé) / Audit (obligatoire si le module touche à des données de santé ou financières sensibles).
2. **Champs hérités du référentiel vs stockés en local** — tout champ pays/devise/langue/unité administrative/ville référence l'identifiant du Referential, jamais une valeur libre.
3. **Clé primaire locale** — `id` local, `gsg_org_id`/`gsg_id` en colonnes scalaires nullable (règle KER-VIS-01/KER-ORG-02, déjà appliquée dans `PharmaConnect_CLAUDE.md`).
4. **Montants** — entier en unité mineure dès la conception (§3.1 — ne pas refaire l'erreur `double`).
5. **Événements publiés/consommés** — format de charge utile documenté avant la première implémentation, pas après coup.

### 4.3 — Les 20 modules restants, regroupés (revu le 25/08/2026)

`stock`, `traceability`, `recall`, `coldchain`, `admin` et `alerts` sont sortis de cette liste le 25/08 — ils ont désormais du code (voir §1 bis). **Leur sortie de cette liste ne signifie pas qu'ils sont conformes** : c'est justement l'un de ces six (`traceability`) qui porte la régression documentée en §3.5. Avant de les considérer « terminés », vérifier qu'ils suivent bien la checklist §4.2 a posteriori — rien n'indique qu'elle ait été suivie à leur création.

Regroupement fonctionnel indicatif pour prioriser — **le périmètre exact de chaque module doit être confirmé contre le *Cahier de Conception PharmaConnect v2.1***, absent de ce dépôt : ce document ne s'y substitue pas.

| Cluster | Modules (dossier) | Remarque Kernel |
|---|---|---|
| Commerce & finance B2B | `marketplace`, `financing`, `chains` | `chains` (nom ambigu — probablement « multi-officines » d'après `CLAUDE.md` racine, à confirmer) a une forte dimension Org Registry (`gsg_org_id` par officine). |
| Soins & suivi patient | `homecare`, `healthrecord`, `teleconsult`, `triage`, `family` | Données de santé sensibles → Audit Kernel obligatoire (KER cardinal), jamais de publication sur le bus d'événements sans finalité explicite documentée. |
| Professionnels & institutions | `professionals`, `hospitals`, `regulator`, `insurance` | Candidats naturels au Referential Engine (`code_domaine = pharmaceutique`) pour les variations réglementaires inter-pays CEDEAO. |
| Support & pilotage | `analytics`, `support`, `loyalty`, `solidarity`, `eprescription` | `analytics` ne doit lire que des agrégats, jamais republier de la donnée nominative sur le bus. `eprescription` n'a même pas de dossier vide dans `lib/modules/` à ce jour — à créer au démarrage du module, pas avant. |
| IoT | `iot` | Candidat naturel pour porter le transport technique des capteurs de `coldchain` (déjà codé) — clarifier si ce sont deux modules distincts ou si `iot` est une couche sous `coldchain` avant de démarrer, pour ne pas dupliquer ce qui existe déjà. |
| **À clarifier avant de démarrer** | `business` | Nom de dossier sans correspondance évidente dans la liste de modules du `CLAUDE.md` racine — ne pas coder avant d'avoir confirmé son périmètre exact dans le cahier de conception v2.1. |

### 4.4 — Conventions de données transverses (déjà en vigueur, à appliquer sans exception)

- Monnaie → `CurrencyFormatter` + entier unité mineure (§3.1).
- Téléphone → E.164 strict en stockage, formaté à l'affichage seulement (§3.2).
- Statut → toujours un `enum` dans son propre fichier `xxx_status.dart`, jamais une `String` libre.
- Couleur → toujours une constante `PharmaConnectColors` (ou son futur équivalent GSG Design Kit), jamais un `Color(0xFF...)` littéral dans un modèle ou un widget de module (§2 point 9, KER-DES-03). Garde-fou CI : `scripts/ci/check_no_hardcoded_color.sh`.
- Nommage : français pour tout champ qui reflète un concept du référentiel métier partagé (`pays`, `devise`, `langue`...), anglais pour l'infrastructure technique (services, identifiants, API) — règle KER-NOM-01/02/03 du `CLAUDE.md` racine.

---

## 5. Instructions pour la solidité du code

### 5.1 — Gestion d'erreur : un seul patron, sans exception

Tout `try/catch` dans un provider suit le patron déjà correct de `delivery_provider.dart` :

```dart
try {
  // ...
} catch (e) {
  _error = e.toString();
  notifyListeners();
}
```

Un commentaire `// handle error` sans code derrière n'est pas une gestion d'erreur, c'est une erreur avalée. Chaque écran qui consomme un provider doit afficher `provider.error` quand il est non nul. Corriger les trois providers listés en §3.3 avant d'utiliser leur patron comme modèle pour un nouveau module.

### 5.2 — Mock aujourd'hui, Supabase demain : ne jamais changer l'interface publique

Tous les services actuels (`payment_service.dart`, `delivery_service.dart`, `reservation_service.dart`, `search_service.dart`, `prescription_service.dart`) sont des mocks en mémoire. C'est un choix délibéré et sain pour développer l'UI sans attendre le backend — mais cela n'a de valeur que si la bascule vers une vraie table Supabase ne casse pas les providers/écrans qui consomment le service. Règle : la signature publique d'un service (`Future<List<X>> getX()`, `Future<X> createX(...)`) ne change pas entre la version mock et la version réelle ; seul le corps de la méthode change.

### 5.3 — Authentification : ne jamais dupliquer ce que Supabase Auth fait déjà

Rappel explicite après l'incident du §2.6 : aucun code de génération de code OTP, aucun wrapper direct vers un provider SMS/WhatsApp/email, aucune signature de token manuelle ne doit apparaître dans ce dépôt, backend compris. `auth_service.dart` reste la seule porte d'entrée vers l'authentification, au-dessus du SDK Supabase natif.

### 5.4 — Résilience Kernel : le patron `GsgKernelAuthBridge` est la référence

Tout futur appel réseau vers une brique du Kernel (Referential, Org Registry, Bus d'événements) doit suivre le même patron que [gsg_kernel_auth_bridge.dart](lib/core/kernel/gsg_kernel_auth_bridge.dart) : timeout court, `try/catch` qui renvoie `null`/un état dégradé plutôt que de lever, jamais de blocage d'un cas d'usage métier sur la disponibilité du Kernel (KER-ARC-03). Ne jamais coder en dur un état « connecté » dans l'UI sans qu'un appel réel ne l'alimente (§2.7).

### 5.5 — Tests : ce qui doit accompagner chaque nouveau module

Pour tout nouveau module, a minima :
- un test unitaire par provider (au moins le chemin nominal + un chemin d'erreur, ce qui aurait immédiatement révélé le problème du §3.3) — voir `test/unit/providers/*.dart` pour le patron à reproduire ;
- un test widget pour l'écran principal du module qui construit l'écran dans son provider réel — voir `test/widget/screens/*.dart`. C'est précisément ce type de test qui aurait immédiatement révélé le crash du §2 point 14 (provider jamais enregistré dans `app.dart`).

Ne pas attendre un chantier « tests » séparé en fin de projet — l'écart ne fera que grandir avec 20 modules de plus.

**Résolu partiellement (27/08/2026) :** `test/unit/` et `test/widget/` n'étaient effectivement vides que jusqu'à cette date — 27 tests unitaires (un fichier par provider, 14/14) et 14 tests widget (un par écran principal des 14 modules avec code réel) ajoutés. Deux cas particuliers documentés plutôt que forcés à rentrer dans le patron nominal/erreur : `DashboardProvider` n'a aucun chemin d'erreur possible (données générées en pur mémoire, ne peut jamais lever d'exception) ; `AuthProvider` parle à un vrai `GoTrueClient` Supabase, donc seules ses branches synchrones/hors-réseau sont testables en unitaire sans un vrai projet Supabase. Reste ouvert : les écrans secondaires de chaque module (détail, formulaires) ne sont pas couverts, seul l'écran principal ; les 20 modules non entamés (§4.3) n'ont par construction encore rien à tester.

### 5.6 — CI : les trois garde-fous ne sont pas optionnels

`scripts/ci/check_no_cross_schema_fk.sh` (KER-VIS-03), `scripts/ci/check_no_hardcoded_currency.sh` (KER-REF) et `scripts/ci/check_no_hardcoded_color.sh` (KER-DES-03) tournent sur chaque push/PR via `.github/workflows/kernel-compliance.yml`, avec `flutter analyze`. Tout nouveau module qui introduit une chaîne de devise ou une couleur en dur, ou une contrainte SQL inter-schémas, fait échouer la CI par construction — c'est voulu, ne pas contourner avec un `# skip`.

**Correctif (27/08/2026) — `check_no_cross_schema_fk.sh` était cassé depuis sa création :** la première écriture de SQL réel dans `supabase/migrations/` (voir PharmaConnect_CLAUDE.md, mise à jour du 27/08/2026) a révélé que le script rejetait `references auth.users(id)` et `references public.categories(id)` — des références 100% légitimes. La regex vérifiait le mauvais côté du point (`references schema.TABLE` au lieu de `references SCHEMA.table`), un bug invisible tant que `supabase/migrations/` était vide (rien à analyser) et que le seul test négatif jamais fait portait sur une violation injectée, jamais sur une référence légitime au même schéma. Corrigé, revérifié positivement (silencieux sur les 15 migrations réelles) et négativement (échoue bien sur une FK injectée vers un schéma `gsg_id.*` fictif, retirée ensuite). Même leçon que celle déjà tirée en §3.6 : un garde-fou jamais exercé contre du contenu réel ne prouve rien.

**Ajout (27/08/2026) — `flutter test` manquait du workflow CI :** `.github/workflows/kernel-compliance.yml` exécutait `flutter analyze` mais jamais `flutter test`, y compris après l'ajout des 42 tests (§5.5). Un test qui ne tourne qu'en local, jamais en CI, ne protège personne d'autre que la personne qui pense à le lancer — la même leçon que §3.6 et l'ajout ci-dessus à `check_no_cross_schema_fk.sh`, appliquée cette fois à l'absence totale d'une étape plutôt qu'à un bug dans une étape existante. Étape `flutter test` ajoutée après `flutter analyze`.

---

## 6. Annexe — checklist de démarrage d'un nouveau module

0. **Vérifier qu'un `git commit` récent existe et que `flutter analyze` tourne à 0 erreur avant d'ouvrir le moindre nouveau fichier.** Ajouté le 25/08 suite à l'incident §3.5/§3.6 : les 6 derniers modules ont été codés sur un état déjà cassé (`pubspec.yaml` invalide), ce qu'un simple `flutter analyze` préalable aurait révélé en quelques secondes.
1. Confirmer le périmètre exact dans le *Cahier de Conception PharmaConnect v2.1* (surtout pour les clusters « À clarifier », §4.3).
2. Remplir la checklist Kernel (§4.2) avant d'écrire le premier fichier.
3. Créer la structure `models/providers/screens/services/widgets` (§4.1).
4. Montants en entier unité mineure dès le modèle (§3.1) — pas de `double`.
5. Tout champ téléphone passe par la normalisation E.164 (§3.2) dès qu'elle existera dans `validators.dart`.
6. Provider : patron d'erreur §5.1 dès la première ligne, pas en correction a posteriori — et enregistré dans le `MultiProvider` de `lib/app.dart` dès sa création (§2 point 14), pas seulement quand un écran commence à l'utiliser.
7. Service : interface publique stable mock → réel (§5.2).
8. Tout `statusColor` (ou équivalent) retourne une constante `PharmaConnectColors`, jamais un `Color(0xFF...)` littéral (§2 point 9, KER-DES-03).
9. Écran ajouté à `app_router.dart` **seulement** s'il existe déjà — sinon `PlaceholderScreen` explicite.
10. Au moins un test unitaire (provider) + un test widget (écran principal) avant de considérer le module « fait ».
11. `flutter analyze` + les trois garde-fous CI passent avant toute PR.
