# CLAUDE.md — PharmaConnect

Infrastructure numérique du circuit pharmaceutique et des soins à domicile en Afrique de l'Ouest (Connect Care / Connect Pharma / Connect Supply). Application Flutter, backend Supabase, conçue pour s'intégrer nativement au GSG Platform Kernel.

Référence produit : *Cahier de Conception PharmaConnect v2.1* (34 modules, 66 règles de gestion). Référence infrastructure : *GSG Platform Kernel — cahier de conception v3.0*. Référence authentification : *Modèle d'authentification Supabase — Migration Firebase vers Supabase*. Ce fichier documente l'état du **code**, pas seulement l'intention du cahier — mets-le à jour à chaque changement structurant plutôt que de laisser le cahier de conception et le dépôt diverger.

## Mise à jour (27/08/2026, suite) — paquets obsolètes mis à jour (branche dédiée)

Chantier traité sur une branche séparée (`chore/update-outdated-packages`, créée depuis `main` propre — les 29 fichiers en attente des priorités précédentes ont d'abord été commités) pour ne pas mélanger montée de version et développement fonctionnel, comme demandé.

`flutter pub upgrade --major-versions` puis un ajustement manuel de `go_router` (bloqué à 17.5.0 par la résolution automatique alors que 18.0.0 était en fait résolvable) : les **16 dépendances directes** de `pubspec.yaml` sont désormais toutes à jour, dont les trois signalées comme à risque — `go_router` 13→**18**, `mobile_scanner` 3.5→**7.4**, `geolocator` 11→**14**. Les ~16 paquets encore listés par `flutter pub outdated` sont tous transitifs (SDK Flutter, `analyzer`/`build_runner`...), non actionnables depuis ce `pubspec.yaml`.

`flutter analyze` a révélé 13 erreurs de compilation réelles suite à la montée de version, concentrées dans 2 fichiers (aucune dans les trois paquets signalés à risque, contrairement à l'historique du 25/08 où `geolocator` avait déjà cassé la compilation une fois) :
- `notification_service.dart` — `flutter_local_notifications` 16→22 a rendu tous les paramètres positionnels de `initialize`/`show`/`zonedSchedule`/`cancel` nommés, et supprimé `uiLocalNotificationDateInterpretation`/`UILocalNotificationDateInterpretation` (l'interprétation absolue est désormais le seul comportement). Adapté en conséquence.
- `export_service.dart` — `csv` 5→8 a remplacé `ListToCsvConverter` par l'instance top-level `csv` (`csv.encode(rows)`) ; `share_plus` 7→13 a déprécié `Share.shareXFiles(...)` au profit de `SharePlus.instance.share(ShareParams(...))`. Les deux migrés.

Corrigé au passage une dépréciation (pas une erreur) introduite par `geolocator` 11→14 dans `location_service.dart` : `desiredAccuracy` → `locationSettings: LocationSettings(accuracy: ...)`.

Vérifié après coup : `flutter analyze` revient à son solde d'avant chantier (25 infos de style pré-existantes, 0 erreur, 0 nouvelle dépréciation), `flutter test` passe (l'unique test de l'app rend bien l'écran de login à travers `go_router` 18), et les trois garde-fous CI (`check_no_cross_schema_fk.sh`, `check_no_hardcoded_color.sh`, `check_no_hardcoded_currency.sh`) restent verts.

**Non fait, volontairement hors périmètre :** les ~25 infos de style relevées par `flutter analyze` (`use_build_context_synchronously`, `deprecated_member_use` sur des API du SDK Flutter lui-même comme `activeColor`/`value`) sont pré-existantes, sans lien avec cette montée de version — les corriger ici aurait justement mélangé ce chantier avec autre chose.

## Mise à jour (26/08/2026) — saisie téléphone séparée en composant dédié, dépôt git initialisé

Deux fichiers ajoutés dans le module `auth` : `lib/modules/auth/models/phone_country.dart` (liste `PhoneCountry`, un seul pays actif aujourd'hui — Guinée, `+224`, 9 chiffres locaux — extensible sans réécriture quand le GSG Referential sera branché) et `lib/modules/auth/widgets/phone_input_field.dart` (sélecteur pays + champ numérique local, formatters chiffres uniquement, suppression du `0` initial). `login_screen.dart` et `register_screen.dart` affichent désormais `PhoneInputField` à la place du champ identifiant générique quand la méthode SMS/WhatsApp est sélectionnée ; le champ générique reste utilisé pour l'email. La normalisation E.164 finale continue de passer par `Validators.normalizeE164()` (`lib/core/utils/validators.dart`) — un point unique qui existait déjà avant ce changement (voir correction de trace historique en §3.2 de `REFERENTIEL_ARCHITECTE.md`) ; le nouveau widget alimente ce même point plutôt que de dupliquer la normalisation.

Par ailleurs, le dépôt a été initialisé en git ce même jour (`git init` + premier commit honnête reflétant l'état vérifié du code, pas une affirmation non vérifiée) — voir `git log` pour l'historique à jour. C'est ce qui permet désormais de suivre ce type de changement comme un diff isolé plutôt que comme une modification silencieuse d'un état déjà flou.

Un remote GitHub a ensuite été configuré (`https://github.com/TamataDelamou/pharma_connect-`, privé) et la branche locale renommée `master` → `main` pour correspondre au déclencheur du workflow. Premier push effectué — première exécution réelle de `.github/workflows/kernel-compliance.yml` depuis sa création. Ce premier run a immédiatement révélé deux problèmes invisibles en local : `assets/icons/`/`assets/images/` déclarés dans `pubspec.yaml` mais jamais suivis par git (dossiers vides — corrigé avec des `.gitkeep`), et `flutter analyze` qui échoue par défaut sur les avertissements *et* les infos, pas seulement les erreurs (jamais vérifié jusqu'ici : seul le nombre d'erreurs était contrôlé, jamais le code de sortie réel de la commande). 25 imports/champs/variables réellement inutilisés nettoyés dans 22 fichiers, et `--no-fatal-infos` ajouté à l'étape `flutter analyze` du workflow pour aligner le seuil CI sur celui visé depuis le début du projet (0 erreur, avertissements/infos non bloquants). Second push : **CI verte** — les trois garde-fous KER-* s'exécutent réellement pour la première fois.

## Mise à jour (27/08/2026, suite) — premières migrations Supabase écrites

`supabase/migrations/` (vide depuis l'origine, sur les cinq audits précédents) contient désormais 15 fichiers, un schéma complet pour les 14 modules ayant du code réel côté Dart : `profiles` (extension de `auth.users`), `catalog` (categories/manufacturers/products), `pharmacies`/`pharmacy_groups` (table canonique unique — voir plus bas), `admin` (admin_users/audit_logs/system_configs), `stock` (stock_items/stock_batches/stock_movements/stock_adjustments), `traceability` (traceable_batches/batch_movements/cold_chain_records/certificates/verification_scans), `coldchain`, `recall`, `prescriptions`, `reservations`, `delivery` (drivers/deliveries/proofs/routes/stops), `payments` (transactions/installments/wallets/invoices), `alerts`, et `search` (search_history seulement — les résultats de recherche eux-mêmes sont calculés à la volée, pas persistés).

Trois décisions structurantes prises en écrivant ce schéma, à connaître avant d'y toucher :

1. **Une seule table `pharmacies` canonique**, pas trois. Le code Dart modélise la même entité réelle (une officine) sous trois formes différentes selon le module — `AdminPharmacy` (admin, gestion DNPM), `Pharmacy` (search, vue publique) et `PharmacyBranch` (stock, notion de succursale). Dupliquer ça en trois tables aurait rendu impossible de savoir laquelle fait foi. `pharmacies` reprend le sur-ensemble de champs d'`AdminPharmacy` ; chaque service peut continuer à n'exposer qu'un sous-ensemble de colonnes côté Dart sans que le schéma soit redondant.
2. **Deux écarts comblés que les modèles Dart ne couvraient pas** : `stock_items.pharmacy_id` (le modèle `StockItem` actuel n'a qu'un `defaultLocation` texte libre — un stock persisté doit pourtant être scopé par officine, sinon Multi-officines n'a pas de fondation) et `stock_items.unit_price` (aucun modèle Dart ne porte le prix de vente ; `PharmacyStock.price` côté `search` est aujourd'hui une valeur mockée, sans source persistée). Les deux sont documentés en commentaire SQL dans `20260827000600_stock.sql`.
3. **RLS activée sur les 33 tables**, mais volontairement inégale : les tables de référentiel/catalogue (`products`, `pharmacies`, `categories`...) sont en lecture ouverte à tout utilisateur authentifié ; les données personnelles (`profiles`, `wallets`, `alerts`, `prescriptions`, `reservations`, `transactions`, `deliveries`...) sont limitées à leur propriétaire (`auth.uid()`) en lecture, sans politique d'écriture pour l'instant. L'accès « staff » (un pharmacien voit la file d'attente de son officine, un livreur voit sa tournée — cf. `pharmacy_queue_screen.dart` ajouté le 27/08) n'est **pas** couvert : ça suppose un mécanisme de vérification de rôle/rattachement utilisateur ↔ officine qui n'existe pas encore côté produit. L'inventer dans cette migration aurait été une hypothèse de conception, pas un exercice mécanique — laissé comme chantier séparé, documenté en commentaire dans chaque fichier concerné.

En écrivant ces migrations, `scripts/ci/check_no_cross_schema_fk.sh` s'est révélé cassé depuis sa création (vérifiait le mauvais côté du point dans `references schema.table`, rejetait même `auth.users`) — invisible tant qu'aucune vraie migration n'existait pour l'exercer. Corrigé, revérifié dans les deux sens. Détail → `REFERENTIEL_ARCHITECTE.md` §5.6.

Vérifié : les 15 fichiers parsent sans erreur avec un vrai analyseur SQL PostgreSQL (`libpg-query`, hors dépendances du projet, aucun outil Docker/`supabase` CLI disponible dans cet environnement pour un `supabase db reset` réel) ; toutes les FK pointent vers une table déjà créée au moment où elle est référencée (vérifié par script) ; aucun nom de table/index/politique dupliqué ; les trois garde-fous CI passent.

**Non fait, à faire séparément :** provisionner un vrai projet Supabase et renseigner `supabase_service.dart` (actuellement `https://votre-projet.supabase.co` / `votre-clé-anon`) — ça ne se fait pas depuis un dépôt de code, ça nécessite un compte/dashboard Supabase. Câbler les services Dart mockés (`*_service.dart`) sur ce schéma reste également un chantier à part : cette migration donne un schéma cible, elle ne branche rien côté client.

## Mise à jour (27/08/2026) — gestion d'erreur des providers unifiée, montants int déjà conformes

**Montants (KER-REF-05, `REFERENTIEL_ARCHITECTE.md` §3.1) :** vérification directe du code — `Transaction.amount/fee/cashback/finalAmount`, `Installment.totalAmount/amountPerPayment`, `InstallmentPayment.amount`, `Reservation.totalPrice`, `ReservationItem.pricePerUnit`, `PaymentProvider._walletBalance` sont déjà tous en `int`, aucun `double` monétaire nulle part dans `lib/`. Rien à corriger ; §3.1 mis à jour avec une note « Résolu » pour ne plus lister ce point comme un chantier ouvert (même écart de gouvernance que §3.2 : le code avait progressé sans que la doc suive).

**Gestion d'erreur des providers (`REFERENTIEL_ARCHITECTE.md` §3.3) :** `prescription_provider.dart` et `reservation_provider.dart` n'avalent déjà plus aucune erreur silencieusement — constat également obsolète. Seul `search_provider.dart` avait un vrai reliquat, plus étendu que documenté (4 `catch` silencieux, dont un littéral `// ignore` dans `clearHistory` — pas 2) : corrigé, alignés sur `_error = e.toString(); notifyListeners();`.

Le symptôme réellement visible pour l'utilisateur n'était pas là où `REFERENTIEL_ARCHITECTE.md` le pointait, mais un cran plus loin : l'état `_error` du provider existait souvent mais n'était **jamais lu par l'écran**. Trouvé et corrigé : `prescription_detail_screen.dart` restait bloqué sur un spinner **infini** si `loadPrescription()` échouait (jamais de sortie de l'état de chargement) ; `prescription_list_screen.dart` et `patient_history_screen.dart` affichaient « Aucune ordonnance » sur un échec réseau, indiscernable d'une vraie liste vide ; `reservation_checkout_screen.dart` affichait un message d'erreur générique codé en dur au lieu de `provider.error`. Les quatre écrans suivent désormais le patron déjà en usage dans `catalog_list_screen.dart`/`stock_list_screen.dart` (état erreur dédié, bouton Réessayer, avant l'état vide).

## Mise à jour (26/08/2026) — régression KER-DES-03/KER-REF du 25/08 vérifiée déjà résolue, nouvel écart de même famille corrigé

Avant de traiter l'élément 1 de « Chantiers ouverts » (18 couleurs + 11 chaînes GNF codées en dur, régression du 25/08 documentée juste en dessous), vérification directe du code plutôt que de la liste : les deux garde-fous CI (`check_no_hardcoded_color.sh`, `check_no_hardcoded_currency.sh`) passent déjà au vert, et lecture de `batch_status.dart`/`traceable_batch.dart` confirme que les deux getters `color`/`statusColor` retournent déjà des constantes `PharmaConnectColors`. Cette régression a en réalité été corrigée en marge de la reconstruction de `traceable_batch.dart` documentée dans `code_export_architecte.md` (rapport du 26/08) — la liste « Chantiers ouverts » de ce fichier n'avait simplement pas été mise à jour en conséquence. Corrigé ci-dessous (§ Chantiers ouverts).

Ce même rapport du 26/08 signalait cependant un écart réel et distinct, non couvert par la CI actuelle : 10 fichiers modèles (`alert.dart`, `admin_pharmacy.dart`, `temperature_record.dart`, `cold_equipment.dart`, `cold_incident.dart`, `verification_result.dart`, `recall_status.dart`, `recall.dart`, `recall_affected_batch.dart`, `stock_movement.dart`) utilisaient des couleurs Material **nommées** littérales (`Colors.red`, `Colors.orange`, `Colors.blue`, `Colors.grey`, `Colors.yellow`, `Colors.purple`, `Colors.cyan`...) au lieu des tokens `PharmaConnectColors` — le même anti-motif KER-DES-03 sous une forme que `check_no_hardcoded_color.sh` ne détectait pas (il ne cherchait que `Color(0xFF...)` littéral). Corrigé : les 47 occurrences remplacées par les tokens existants selon la correspondance déjà en usage ailleurs dans le code (`Colors.red` → `accentRed`, `Colors.orange` → `accentOrange`, `Colors.green` → `accentGreen`, `Colors.blue`/`Colors.cyan` → `accentCyan`, `Colors.yellow` → `accentAmber`, `Colors.grey` → `neutralMuted`, `Colors.purple` → `accentPurple`), aucun nouveau token créé.

`check_no_hardcoded_color.sh` a ensuite été étendu le même jour pour détecter cette forme : en plus du `Color(0xFF...)` littéral (recherché dans tout `lib/`, comme avant), il recherche désormais `Colors.<nom>` sémantique (`red`, `orange`, `green`, `blue`, `purple`, `yellow`, `amber`, `cyan`, `grey`...) dans `lib/modules/*/models/` — le seul gabarit où la régression s'est répétée deux fois (18 occurrences le 25/08, 47 le 26/08). `Colors.white`/`black`/`transparent` restent volontairement exclus (structurels — glass effects, overlays — pas de portée de marque, 204 usages légitimes répartis sur 76 fichiers) et la détection reste volontairement bornée à `*/models/` plutôt qu'à tout `lib/` : étendre à tout `lib/` (écrans, widgets) sans revue humaine préalable produirait des dizaines de faux positifs sur du code déjà accepté. Vérifié positivement (silencieux sur le code actuel, les 10 modèles corrigés compris) et négativement (échoue bien face à une régression `Colors.red`/`Colors.red[700]` injectée délibérément dans un modèle, puis retirée).

## Mise à jour (25/08/2026) — régression non documentée détectée et corrigée

**Constat, avant toute nouvelle lecture de ce fichier :** entre le 24/08 (état décrit ci-dessous) et le 25/08, six nouveaux modules ont été codés (`stock`, `traceability`, `coldchain`, `recall`, `admin`, `alerts` — 86 fichiers Dart) **sans que ce fichier, ni `REFERENTIEL_ARCHITECTE.md`, ni `code_export_architecte.md` ne soient mis à jour**. Dans l'intervalle, `pubspec.yaml` a été cassé (trois dépendances dupliquées — YAML invalide, `flutter pub get` levait une exception avant même d'atteindre l'analyseur) et une dépendance non maintenue (`tesseract_ocr`, incompatible null-safety) a été ajoutée pour l'OCR des ordonnances. Résultat : le dépôt était dans un état où **aucune commande Flutter ne pouvait s'exécuter**, alors que ce fichier affirmait toujours « `flutter analyze` : aucun signalement ». Cette affirmation ne pouvait matériellement pas avoir été vérifiée sur le code réellement présent dans le dépôt au moment de la lecture — voir `code_export_architecte.md`, section « Rapport d'audit — 25 août 2026 » pour le détail complet et l'hypothèse la plus probable (absence de dépôt git, donc aucune trace de ce qui s'est passé entre les deux dates).

Deux régressions concrètes, plus graves qu'un simple retard de documentation, ont été trouvées dans ce nouveau code :

1. **KER-DES-03 (couleurs codées en dur)** — le module `traceability`, ajouté après que cette règle a été formalisée et après que l'écart équivalent a été corrigé dans 5 autres modèles (voir plus bas), reproduit exactement le même anti-motif : 18 occurrences de `Color(0xFF...)` littéral dans `batch_status.dart` et `traceable_batch.dart`. Le garde-fou CI `check_no_hardcoded_color.sh` existait déjà et aurait dû l'empêcher — il ne s'est simplement jamais exécuté, faute de dépôt git pour déclencher `.github/workflows/kernel-compliance.yml`.
2. **KER-REF (devise codée en dur)** — 11 occurrences de `'... GNF'` littéral trouvées le 25/08, dont plusieurs dans `payments/` — un module pourtant documenté ci-dessous comme déjà mis en conformité le 24/08. Soit la conformité n'a pas été aussi complète que documenté, soit une régression a eu lieu depuis ; sans git, impossible de trancher.

**Non corrigé dans l'immédiat** (nécessite un arbitrage visuel/produit, pas une substitution mécanique) : le remplacement des 18 + 11 littéraux par les tokens/`CurrencyFormatter` corrects. Voir `REFERENTIEL_ARCHITECTE.md` §3.5 pour le détail et la marche à suivre.

Ce qui a été corrigé le 25/08 pour que le projet compile à nouveau : `pubspec.yaml` réparé, `tesseract_ocr` remplacé par `google_mlkit_text_recognition`, et 216 erreurs de compilation résorbées à travers 54 fichiers (imports manquants, un membre d'enum nommé `return` — mot réservé Dart —, des signatures désynchronisées entre providers et services, 8 fichiers référencés par le routeur ou par `search_screen.dart` mais jamais créés). Détail complet → `code_export_architecte.md`, section « Rapport d'audit — 25 août 2026 ». `flutter analyze` : 0 erreur, 83 avertissements/infos non bloquants. `flutter test` : 1/1.

## État du projet (24/08/2026)

Le projet est **en chantier**, pas au stade zéro décrit par le cahier de conception initial. Section conservée telle qu'écrite le 24/08 pour l'historique ; **le décompte de modules ci-dessous est dépassé**, voir le tableau à jour juste après :

- `flutter analyze` : aucun signalement (« No issues found! »).
- `flutter test` : 1 test, 0 échec — un seul test de démarrage protège toute l'application ; `test/unit/` et `test/widget/` existent mais sont **vides**.
- 8 modules sur 34 avaient du code réel à cette date : **auth, dashboard, search, catalog, prescriptions, reservations, delivery, payments**.

### Tableau à jour (25/08/2026)

| | |
|---|---|
| Modules avec code réel | 14 / 33 dossiers existants : `search` (22 fichiers), `stock` (17), `reservations` (17), `payments` (17), `prescriptions` (16), `delivery` (15), `traceability` (14), `recall` (14), `coldchain` (14), `admin` (14), `alerts` (11), `catalog` (10), `auth` (8), `dashboard` (7) |
| Modules vides | 19 dossiers présents mais sans code (`analytics`, `business`, `chains`, `family`, `financing`, `forecasting`, `healthrecord`, `homecare`, `hospitals`, `insurance`, `iot`, `loyalty`, `marketplace`, `professionals`, `regulator`, `solidarity`, `support`, `teleconsult`, `triage`) + `eprescription`, cité dans le cahier de conception racine mais dont **le dossier n'existe même pas encore** dans `lib/modules/` |
| `flutter analyze` | 0 erreur, 83 avertissements/infos (voir §CI plus bas) |
| CI | **Verte** depuis le 26/08/2026 (remote GitHub configuré, premier push) — voir §CI plus bas pour le détail |
- `catalog` et `search` sont deux modules **distincts et complémentaires**, pas redondants : `catalog` liste les produits et leur classification (catégories, fabricants) via le modèle partagé `Product` (`lib/shared/models/product.dart`) — aucune notion de prix ni de stock. `search` réutilise les mêmes produits mais y ajoute la disponibilité en officine et le prix (`AvailabilityResult`). Les prix et les stocks réels resteront portés par `search` et par le futur module `stock` (FEFO) — ne pas faire porter cette responsabilité à `catalog`.
- Intégration de `catalog` finalisée (24/08/2026) : `CatalogProvider` était utilisé (`context.watch`/`context.read`) par `catalog_list_screen.dart` et `catalog_detail_screen.dart` sans jamais être enregistré dans le `MultiProvider` de `lib/app.dart` — corrigé (`ProviderNotFoundException` évitée). Le module a aussi été raccordé à la navigation : le `SidebarNavigation` du tableau de bord n'appelait jamais `context.go(route)` (seul le surlignage local changeait, aucun module — y compris `catalog` — n'était réellement atteignable au clic) ; corrigé dans `dashboard_screen.dart`, et une entrée « Catalogue » → `/catalog` a été ajoutée à la barre latérale.
- 13 écrans du routeur sont des **coquilles provisoires** (`core/widgets/screens/placeholder_screen.dart`), pas de vraie UI/logique métier : `ReservationCheckoutScreen`, `ReservationConfirmationScreen`, `ReservationQRScreen`, `ReservationHistoryScreen`, `PharmacyQueueScreen`, `DeliveryHistoryScreen`, `DeliveryScheduleScreen`, `DriverDashboardScreen`, `InstallmentPlanScreen`, `WalletScreen`, `TransactionHistoryScreen`, `DisputeScreen`, `ReconciliationScreen`.
- **Aucune migration Supabase** n'existe encore (`supabase/migrations/` est vide) : le schéma de données n'existe aujourd'hui que côté client, sous forme de classes Dart (`Delivery`, `Reservation`, `Transaction`, `Prescription`...). Rien n'est encore persisté côté serveur.
- `SupabaseService` (`lib/core/services/supabase_service.dart`) pointe vers des valeurs placeholder (`https://votre-projet.supabase.co`, `votre-clé-anon`) — à renseigner avant tout test contre un vrai projet Supabase (local via `supabase start`, ou distant).
- `GsgKernelAuthBridge` (`lib/core/kernel/gsg_kernel_auth_bridge.dart`) pointe vers `https://kernel.gsg.example` — le Kernel n'est pas encore déployé ; l'app tourne aujourd'hui « en mode dégradé » avec Supabase Auth seul (voir plus bas).
- 27 paquets ont des versions plus récentes disponibles (`flutter pub outdated`) — mise à jour volontairement différée pour ne pas introduire de régression hors périmètre.

Historique détaillé de la dernière intervention (imports manquants, enums fantômes, écrans du routeur jamais écrits, bug de type sur `getWalletBalance()`, `.withOpacity()` déprécié...) : voir `code_export_architecte.md`, section « Rapport d'audit — 24 août 2026 ».

## Stack réelle (pubspec.yaml / package.json)

- **Flutter** (SDK ^3.12.0), Material.
- État : **provider** (`ChangeNotifier` par module, enregistrés dans `lib/app.dart`) + **equatable**.
- Routing : **go_router**, une seule table de routes centralisée dans `lib/routes/app_router.dart`, avec redirection auth-aware (`isAuthenticated` → `/dashboard`, sinon → `/login`).
- Backend : **supabase_flutter ^2.0.0** (Auth, et à terme Postgres/Storage/Realtime).
- Réseau hors-Supabase : **dio** (utilisé notamment par `GsgKernelAuthBridge`).
- Stockage local : **shared_preferences**, **sqflite**.
- Connectivité : **connectivity_plus**.
- Scan/caméra : **mobile_scanner**, **image_picker** (ordonnances, QR retrait).
- Notifications : **flutter_local_notifications**.
- CLI Supabase : gérée via npm (`package.json` → `npm run supabase ...`), config locale dans `supabase/config.toml` (`project_id = pharma_connect`, ports par défaut du CLI Supabase).
- CI : GitHub Actions, workflow unique `.github/workflows/kernel-compliance.yml` (voir plus bas).

## Structure du dépôt

```
lib/
  core/
    kernel/      → pont vers le GSG Kernel (auth bridge, statut, badge, indicateur de connexion)
    services/    → SupabaseService (singleton client Supabase)
    theme/       → design system local (couleurs, glass, spacing, typographie, animations)
    utils/       → CurrencyFormatter, validators (vide), extensions (vide)
    widgets/     → composants partagés (boutons, cards, inputs, modals, navigation, placeholder_screen)
  modules/       → un dossier par module métier du cahier de conception (models/providers/screens/services/widgets)
  routes/        → app_router.dart, table de routes go_router unique
  app.dart       → MultiProvider + MaterialApp.router
  main.dart      → point d'entrée, initialise Supabase avant runApp
supabase/
  config.toml    → config CLI Supabase locale
  migrations/    → vide à ce jour
scripts/ci/      → garde-fous KER-* exécutés en CI (bash)
test/            → widget_test.dart (1 test) ; unit/ et widget/ vides
```

## Authentification — implémentation actuelle

Conforme au *Modèle d'authentification Supabase* : choix de l'identifiant (téléphone ou email) puis du canal de réception, sans réimplémenter ce que Supabase Auth fait nativement.

- `lib/modules/auth/services/auth_service.dart` — `sendPhoneOtp(phone, channel: 'sms'|'whatsapp')` / `verifyPhoneOtp()`, `sendMagicLink()` / `sendEmailOtp()` / `verifyEmailOtp()`. Fine couche au-dessus de `GoTrueClient` (`signInWithOtp` / `verifyOTP`), rien d'autre.
- `lib/modules/auth/providers/auth_provider.dart` — état d'authentification exposé à l'UI (`ChangeNotifier`), déclenche le pont Kernel après un `verifyOTP()` réussi.
- `lib/core/kernel/gsg_kernel_auth_bridge.dart` — échange la session Supabase contre une identité GSG ID (`POST /v1/auth/sso/supabase`). **Best-effort, non bloquant** : toute erreur réseau ou timeout (5s) renvoie `null` sans lever d'exception ; le login reste valide avec la seule session Supabase si le Kernel est injoignable.
- `lib/modules/auth/widgets/phone_input_field.dart` — saisie téléphone séparée en sélecteur pays (`lib/modules/auth/models/phone_country.dart`) + champ numérique local, normalisée en E.164 via `Validators.normalizeE164()` avant d'être transmise à `AuthProvider.sendPhoneOtp()`. Utilisé par `login_screen.dart` et `register_screen.dart` quand la méthode SMS/WhatsApp est sélectionnée.
- Écrans : `login_screen.dart`, `register_screen.dart`, `otp_verification_screen.dart`.

## Règles d'architecture — conformité GSG Kernel v3.0

Ces règles découlent de l'audit de conformité Kernel du 24/08/2026 (voir `code_export_architecte.md`). Elles s'appliquent à tout nouveau code touchant à la persistance ou à l'identité, pas seulement au code déjà audité.

### Schéma de données — clés primaires locales (KER-VIS-01, KER-ORG-02)

Toute nouvelle table métier locale (`pharmacies`, `reservations`, `deliveries`, `transactions`, etc.) **conserve sa propre clé primaire locale** (`id`, uuid généré localement) comme identifiant canonique du produit.

- `gsg_id` et `gsg_org_id` ne sont **jamais** la clé primaire. Ce sont des colonnes scalaires optionnelles (`nullable`), ajoutées en plus de `id`, qui font simplement le lien vers le Kernel quand il est connu.
- Aucune refonte destructive d'une table existante pour la faire correspondre au schéma du Kernel n'est acceptable — ni migration qui remplace `id` par `gsg_id`, ni suppression de la PK locale.

### Étanchéité de la base (KER-VIS-03)

Zéro `FOREIGN KEY` / `REFERENCES` SQL pointant vers une table hors du schéma `public`/`auth` du projet. Le lien vers le Kernel se fait uniquement par scalaire (uuid/string) + appel API, jamais par contrainte SQL inter-bases. Garde-fou CI : `scripts/ci/check_no_cross_schema_fk.sh` (grep sur `supabase/migrations/*.sql`, schémas autorisés : `public|auth|storage|extensions|graphql_public`).

### Authentification (KER-ID-02)

Le SDK Supabase Auth natif (`signInWithOtp` / `verifyOTP`) reste l'unique mécanisme qui authentifie l'utilisateur — voir `auth_service.dart`. Tout code de génération de code OTP, ou wrapper direct vers un provider SMS/WhatsApp/email dans ce dépôt, est une régression : le produit ne doit jamais réimplémenter ce que Supabase Auth fait déjà nativement.

L'échange vers le GSG ID se fait *après* un `verifyOTP()` réussi, via `gsg_kernel_auth_bridge.dart` — jamais avant, et jamais de façon bloquante pour le login.

### Devise & référentiel (KER-REF)

Tout affichage de montant passe par `CurrencyFormatter` (`lib/core/utils/currency_formatter.dart`). Aucune chaîne de devise (« GNF », « FCFA », ...) codée en dur dans un widget. Devise par défaut câblée en dur (GNF, ISO 4217 324) tant que le produit ne gère qu'un seul marché ; à faire venir du GSG Referential résolu pour l'organisation courante quand le Kernel sera branché. Garde-fou CI : `scripts/ci/check_no_hardcoded_currency.sh`.

### Résilience (KER-ARC-03)

Tout appel réseau vers un service du Kernel (statut, référentiel, SSO...) passe par un adaptateur qui échoue en silence (retourne `null`/un état dégradé) plutôt que de lever une exception qui bloquerait un cas d'usage métier. Voir `gsg_kernel_auth_bridge.dart` pour le patron à suivre. Ne jamais coder en dur un statut « connecté » ou « online » dans l'UI sans qu'un appel réel ne l'alimente.

### Design System — contrat de tokens (KER-DES-03)

Brique non urgente (KER-DES-02) : PharmaConnect n'adopte pas encore le GSG Design Kit et ce n'est pas un blocage. Mais le futur Kit n'exposera que des tokens sémantiques (couleur primaire, accent succès, surface, texte secondaire...) — jamais de couleur codée en dur dans un composant partagé — et chaque produit branchera sa propre palette sur ce contrat. `lib/core/theme/colors.dart` (`PharmaConnectColors.accentGreen`, `accentOrange`, `accentAmber`, `accentRed`, `neutralMuted`, `textPrimary`, `textSecondary`...) est écrit dans cet esprit : des rôles nommés, pas des composants qui lisent des hex en dur. Le jour où le Kit existera, ce fichier deviendra directement l'implémentation locale du contrat de tokens attendu, sans réécriture des écrans qui le consomment déjà.

Cette discipline a été contournée dans 5 modèles de statut (`delivery.dart`, `transaction.dart`, `prescription.dart`, `reservation.dart`, `availability_result.dart`), dont les getters `statusColor`/`stockColor` retournaient un `Color(0xFF...)` littéral au lieu d'une constante `PharmaConnectColors` — 27 occurrences, le même gabarit copié-collé à chaque fois. Corrigé : deux tokens manquants ajoutés (`neutralMuted`, `accentAmber`), les 27 littéraux remplacés, garde-fou CI `scripts/ci/check_no_hardcoded_color.sh` ajouté pour empêcher toute régression. Détail complet → `REFERENTIEL_ARCHITECTE.md`. Éviter en particulier d'introduire une couleur littérale nouvelle directement dans un modèle ou un widget de module (`modules/*/models`, `modules/*/screens`, `modules/*/widgets`) : passer par `PharmaConnectColors` (ou son équivalent futur) comme on le fait désormais partout.

## CI

`.github/workflows/kernel-compliance.yml`, se déclenche sur push vers `main` et sur toute pull request :

1. `scripts/ci/check_no_cross_schema_fk.sh` (KER-VIS-03)
2. `scripts/ci/check_no_hardcoded_currency.sh` (KER-REF)
3. `scripts/ci/check_no_hardcoded_color.sh` (KER-DES-03)
4. `flutter pub get`
5. `flutter analyze --no-fatal-infos`

Toute contribution doit passer ces cinq étapes avant merge — **et depuis le 26/08/2026, ce n'est plus théorique**. Un remote GitHub a été configuré (dépôt privé) et le workflow s'est réellement exécuté pour la première fois. Le premier run a échoué (assets déclarés mais non suivis par git, `flutter analyze` par défaut plus strict que le seuil visé par le projet — voir la mise à jour du 26/08/2026 en tête de fichier pour le détail) ; corrigé, second run **vert**. C'est très concrètement ce qui aurait empêché les deux régressions du 25/08 (§ plus haut) : les garde-fous étaient écrits, corrects, mais inertes faute de dépôt git pour les déclencher — ce n'est plus le cas.

## Commandes utiles

```bash
flutter pub get                 # dépendances
flutter analyze --no-fatal-infos # lint/typecheck — doit rester à 0 erreur/avertissement (commande utilisée par la CI)
flutter test                    # suite de tests — actuellement 1 seul test
flutter run                     # lancer l'app (nécessite un vrai projet Supabase configuré)

npm run supabase -- start       # démarrer Supabase en local (CLI, config supabase/config.toml)
npm run supabase -- db diff     # générer une migration à partir du schéma local
bash scripts/ci/check_no_cross_schema_fk.sh      # garde-fou KER-VIS-03 en local
bash scripts/ci/check_no_hardcoded_currency.sh   # garde-fou KER-REF en local
bash scripts/ci/check_no_hardcoded_color.sh      # garde-fou KER-DES-03 en local
```

## Chantiers ouverts (par ordre de dépendance)

0. ~~Initialiser un dépôt git~~ — **fait le 26/08/2026** : dépôt git initialisé, remote GitHub configuré, CI vérifiée verte. Ne reste plus dans cette liste que par cohérence avec la numérotation historique.
~~1. Corriger les deux régressions de gouvernance du 25/08~~ — **vérifié déjà résolu le 26/08/2026** (les deux garde-fous CI passent, code relu). Voir la mise à jour du 26/08/2026 en tête de fichier. Écart de même famille trouvé et corrigé dans la foulée : 10 fichiers modèles avec couleurs Material nommées littérales, non couvert par la CI actuelle (§ même mise à jour).
~~2a. Écrire les premières migrations dans `supabase/migrations/`~~ — **fait le 27/08/2026** : 15 fichiers, schéma complet des 14 modules (KER-VIS-01 : PK locale + `gsg_id`/`gsg_org_id` nullables sur `profiles`/`pharmacies`). Voir la mise à jour du 27/08/2026 en tête de fichier pour le détail et les décisions de conception prises.

2b. **Configurer un vrai projet Supabase** — remplacer les placeholders de `supabase_service.dart` (`supabaseUrl`, `supabaseAnonKey`) par un vrai projet (local `supabase start` ou distant), y appliquer les migrations désormais écrites, puis câbler les services Dart mockés sur ce schéma. À date, seule l'authentification parle réellement à Supabase — tous les autres services restent des mocks en mémoire ; ce n'est plus faute de schéma, seulement faute de projet Supabase réel et de câblage service→table.
3. **Implémenter les écrans placeholder** — 13 identifiés le 24/08 (réservation, livraison, paiement/wallet) + 4 ajoutés le 25/08 pour que le routeur compile (`EquipmentAddScreen`, `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`) : 17 au total, coquilles qui compilent, pas des écrans finis.
4. **Étoffer la couverture de tests** — `test/unit/` et `test/widget/` sont toujours vides ; un seul test protège l'app entière, y compris les 86 fichiers ajoutés le 25/08.
5. **Démarrer les 20 modules non entamés** du cahier de conception (marketplace B2B, HomeCare, dossier de santé numérique, etc. — `stock`, `traceability`, `recall`, `coldchain`, `admin`, `alerts` sont sortis de cette liste le 25/08) — se référer à la section « Module N » correspondante du *Cahier de Conception PharmaConnect v2.1* pour l'objectif, les règles de gestion et les écrans attendus de chacun avant de créer le code, et à `REFERENTIEL_ARCHITECTE.md` §4.2 pour la checklist Kernel à remplir avant d'écrire le premier fichier — celle qui, manifestement, n'a pas été suivie pour les 6 modules ajoutés le 25/08.
6. **Brancher le GSG Kernel réel** une fois son URL de production connue (`gsg_kernel_auth_bridge.dart` a un `TODO(kernel-integration)` explicite) — sans casser le mode dégradé existant.
~~7. Mise à jour des paquets obsolètes~~ — **fait le 27/08/2026** sur `chore/update-outdated-packages` : les 16 dépendances directes sont à jour, dont `go_router` (13→18), `mobile_scanner` (3.5→7.4), `geolocator` (11→14). Voir la mise à jour du 27/08/2026 en tête de fichier pour le détail des 2 fichiers cassés par la montée de version et leur correction. Reste à fusionner cette branche.
