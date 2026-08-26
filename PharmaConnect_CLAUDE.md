# CLAUDE.md — PharmaConnect

Infrastructure numérique du circuit pharmaceutique et des soins à domicile en Afrique de l'Ouest (Connect Care / Connect Pharma / Connect Supply). Application Flutter, backend Supabase, conçue pour s'intégrer nativement au GSG Platform Kernel.

Référence produit : *Cahier de Conception PharmaConnect v2.1* (34 modules, 66 règles de gestion). Référence infrastructure : *GSG Platform Kernel — cahier de conception v3.0*. Référence authentification : *Modèle d'authentification Supabase — Migration Firebase vers Supabase*. Ce fichier documente l'état du **code**, pas seulement l'intention du cahier — mets-le à jour à chaque changement structurant plutôt que de laisser le cahier de conception et le dépôt diverger.

## Mise à jour (26/08/2026) — saisie téléphone séparée en composant dédié, dépôt git initialisé

Deux fichiers ajoutés dans le module `auth` : `lib/modules/auth/models/phone_country.dart` (liste `PhoneCountry`, un seul pays actif aujourd'hui — Guinée, `+224`, 9 chiffres locaux — extensible sans réécriture quand le GSG Referential sera branché) et `lib/modules/auth/widgets/phone_input_field.dart` (sélecteur pays + champ numérique local, formatters chiffres uniquement, suppression du `0` initial). `login_screen.dart` et `register_screen.dart` affichent désormais `PhoneInputField` à la place du champ identifiant générique quand la méthode SMS/WhatsApp est sélectionnée ; le champ générique reste utilisé pour l'email. La normalisation E.164 finale continue de passer par `Validators.normalizeE164()` (`lib/core/utils/validators.dart`) — un point unique qui existait déjà avant ce changement (voir correction de trace historique en §3.2 de `REFERENTIEL_ARCHITECTE.md`) ; le nouveau widget alimente ce même point plutôt que de dupliquer la normalisation.

Par ailleurs, le dépôt a été initialisé en git ce même jour (`git init` + premier commit honnête reflétant l'état vérifié du code, pas une affirmation non vérifiée) — voir `git log` pour l'historique à jour. C'est ce qui permet désormais de suivre ce type de changement comme un diff isolé plutôt que comme une modification silencieuse d'un état déjà flou.

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
| CI | Workflow `.github/workflows/kernel-compliance.yml` présent mais **jamais exécuté** — pas de dépôt git dans ce répertoire |
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

`.github/workflows/kernel-compliance.yml`, censé se déclencher sur push vers `main` et sur toute pull request :

1. `scripts/ci/check_no_cross_schema_fk.sh` (KER-VIS-03)
2. `scripts/ci/check_no_hardcoded_currency.sh` (KER-REF)
3. `scripts/ci/check_no_hardcoded_color.sh` (KER-DES-03)
4. `flutter pub get`
5. `flutter analyze`

Toute contribution doit passer ces cinq étapes avant merge — **en théorie**. En pratique, ce répertoire n'est pas un dépôt git (`git status` échoue), donc rien ne pousse jamais vers `main` et ce workflow ne s'est probablement jamais exécuté une seule fois. C'est très concrètement ce qui a permis aux deux régressions du 25/08 (§ tout en haut du fichier) de rester invisibles : les garde-fous étaient écrits, corrects, et inertes. **Avant toute chose, initialiser un dépôt git** — voir `REFERENTIEL_ARCHITECTE.md` §3.6.

## Commandes utiles

```bash
flutter pub get                 # dépendances
flutter analyze                 # lint/typecheck — doit rester à 0 signalement
flutter test                    # suite de tests — actuellement 1 seul test
flutter run                     # lancer l'app (nécessite un vrai projet Supabase configuré)

npm run supabase -- start       # démarrer Supabase en local (CLI, config supabase/config.toml)
npm run supabase -- db diff     # générer une migration à partir du schéma local
bash scripts/ci/check_no_cross_schema_fk.sh      # garde-fou KER-VIS-03 en local
bash scripts/ci/check_no_hardcoded_currency.sh   # garde-fou KER-REF en local
bash scripts/ci/check_no_hardcoded_color.sh      # garde-fou KER-DES-03 en local
```

## Chantiers ouverts (par ordre de dépendance)

0. **Initialiser un dépôt git** — condition de tout le reste : sans lui, ni la CI, ni la revue de code, ni la détection de régression (§ tout en haut du fichier) ne peuvent fonctionner. À faire avant le prochain changement de code, pas après.
1. **Corriger les deux régressions de gouvernance du 25/08** — 18 couleurs et 11 chaînes de devise codées en dur (détail § tout en haut et `REFERENTIEL_ARCHITECTE.md` §3.5). Rapide une fois le mapping littéral → token validé par un humain.
2. **Configurer un vrai projet Supabase** — remplacer les placeholders de `supabase_service.dart` (`supabaseUrl`, `supabaseAnonKey`) ; écrire les premières migrations dans `supabase/migrations/` (toujours vide) pour les tables déjà modélisées côté client (`deliveries`, `transactions`, `reservations`, `prescriptions`, et désormais `stock`, `traceability`, `recall`, `coldchain`...), en respectant KER-VIS-01/KER-ORG-02 (PK locale + colonnes `gsg_id`/`gsg_org_id` nullables). À date, seule l'authentification parle réellement à Supabase — tous les autres services sont des mocks en mémoire.
3. **Implémenter les écrans placeholder** — 13 identifiés le 24/08 (réservation, livraison, paiement/wallet) + 4 ajoutés le 25/08 pour que le routeur compile (`EquipmentAddScreen`, `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`) : 17 au total, coquilles qui compilent, pas des écrans finis.
4. **Étoffer la couverture de tests** — `test/unit/` et `test/widget/` sont toujours vides ; un seul test protège l'app entière, y compris les 86 fichiers ajoutés le 25/08.
5. **Démarrer les 20 modules non entamés** du cahier de conception (marketplace B2B, HomeCare, dossier de santé numérique, etc. — `stock`, `traceability`, `recall`, `coldchain`, `admin`, `alerts` sont sortis de cette liste le 25/08) — se référer à la section « Module N » correspondante du *Cahier de Conception PharmaConnect v2.1* pour l'objectif, les règles de gestion et les écrans attendus de chacun avant de créer le code, et à `REFERENTIEL_ARCHITECTE.md` §4.2 pour la checklist Kernel à remplir avant d'écrire le premier fichier — celle qui, manifestement, n'a pas été suivie pour les 6 modules ajoutés le 25/08.
6. **Brancher le GSG Kernel réel** une fois son URL de production connue (`gsg_kernel_auth_bridge.dart` a un `TODO(kernel-integration)` explicite) — sans casser le mode dégradé existant.
7. Mise à jour différée des paquets obsolètes (52 au 25/08, contre 27 au 24/08 — les modules ajoutés en ont introduit de nouveaux via `flutter pub outdated`), à traiter comme un chantier isolé pour ne pas mélanger montée de version et développement fonctionnel. Notamment `go_router` (13→18), `mobile_scanner` (3.5→7.4), `geolocator` (11→14) — ce dernier a déjà cassé la compilation une fois (§ Rapport d'audit 25/08).
