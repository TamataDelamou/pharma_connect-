# PharmaConnect — Export du code source (pour l'architecte)

Généré le 23/08/2026, mis à jour le 24/08/2026 (fonctionnel), puis le 24/08/2026 (conformité Kernel GSG v3.0).
Ce document rassemble l'intégralité du code Dart du projet à ce stade, organisé selon l'arborescence réelle
du dépôt, afin de documenter les corrections apportées aux modules d'authentification, de recherche, de
prescriptions, de livraison, de paiements et de réservations, ainsi que la mise en conformité avec le Kernel
GSG v3.0. Trois documents complémentaires vivent à côté de celui-ci : `CLAUDE.md` (contexte portefeuille),
`PharmaConnect_CLAUDE.md` (état vivant du code) et `REFERENTIEL_ARCHITECTE.md` (directives de conception pour
les modules restants). Trois rapports complets figurent en fin de document, dont un troisième daté du
25/08/2026.

> **Avertissement (25/08/2026) : le dump de code ci-dessous est dépassé et n'a volontairement pas été
> régénéré dans cette passe.** Six modules ont été codés entre le 24 et le 25/08 (`stock`, `traceability`,
> `coldchain`, `recall`, `admin`, `alerts` — 86 fichiers Dart, ~40 % du volume actuel du projet) sans que ce
> document ne soit mis à jour ; l'arborescence et les fichiers reproduits plus bas correspondent à l'état du
> 24/08, pas à l'état réel du dépôt. Régénérer un export mécanique de 12 800+ lignes à la main, fichier par
> fichier, dans la continuité de cette session aurait consommé l'essentiel du budget de la revue pour une
> valeur ajoutée nulle par rapport à un script d'export — ce que ce fichier semble être à l'origine
> (numérotation et format identiques à chaque section). **Recommandation à l'architecte : régénérer ce
> document via le script/outil qui l'a produit initialement plutôt que de le maintenir à la main désormais
> que le projet dépasse 170 fichiers** ; au-delà de ce volume, un export statique complet devient plus vite
> périmé qu'utile. Le « Rapport d'audit — 25 août 2026 » en fin de document, lui, est à jour et couvre les
> six modules manquants ci-dessous.

## Arborescence

```
pharma_connect/
├── .github/
│   └── workflows/
│       └── kernel-compliance.yml
├── lib/
│   ├── core/
│   │   ├── kernel/
│   │   │   ├── gsg_kernel_auth_bridge.dart
│   │   │   ├── kernel_badge.dart
│   │   │   ├── kernel_connection_indicator.dart
│   │   │   └── kernel_status.dart
│   │   ├── services/
│   │   │   └── supabase_service.dart
│   │   ├── theme/
│   │   │   ├── animations.dart
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   ├── glass.dart
│   │   │   ├── spacing.dart
│   │   │   └── typography.dart
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart
│   │   │   ├── extensions.dart
│   │   │   └── validators.dart
│   │   └── widgets/
│   │       ├── badges/
│   │       │   └── status_badge.dart
│   │       ├── buttons/
│   │       │   ├── danger_button.dart
│   │       │   ├── kernel_button.dart
│   │       │   ├── primary_button.dart
│   │       │   ├── secondary_button.dart
│   │       │   └── tertiary_button.dart
│   │       ├── cards/
│   │       │   ├── glass_card.dart
│   │       │   └── status_card.dart
│   │       ├── inputs/
│   │       │   └── glass_input.dart
│   │       ├── modals/
│   │       │   └── glass_modal.dart
│   │       ├── navigation/
│   │       │   └── sidebar_navigation.dart
│   │       └── screens/
│   │           └── placeholder_screen.dart
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   └── user_role.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── otp_verification_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart
│   │   ├── dashboard/
│   │   │   ├── models/
│   │   │   │   └── dashboard_data.dart
│   │   │   ├── providers/
│   │   │   │   └── dashboard_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── activity_timeline.dart
│   │   │   │   ├── alert_center.dart
│   │   │   │   └── quick_action_grid.dart
│   │   │   └── dashboard_screen.dart
│   │   ├── delivery/
│   │   │   ├── models/
│   │   │   │   ├── delivery.dart
│   │   │   │   ├── delivery_driver.dart
│   │   │   │   └── delivery_status.dart
│   │   │   ├── providers/
│   │   │   │   └── delivery_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── delivery_history_screen.dart
│   │   │   │   ├── delivery_schedule_screen.dart
│   │   │   │   ├── delivery_tracking_screen.dart
│   │   │   │   └── driver_dashboard_screen.dart
│   │   │   ├── services/
│   │   │   │   └── delivery_service.dart
│   │   │   └── widgets/
│   │   │       ├── delivery_card.dart
│   │   │       └── delivery_status_badge.dart
│   │   ├── payments/
│   │   │   ├── models/
│   │   │   │   ├── installment.dart
│   │   │   │   ├── payment_method.dart
│   │   │   │   ├── transaction.dart
│   │   │   │   └── transaction_status.dart
│   │   │   ├── providers/
│   │   │   │   └── payment_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── dispute_screen.dart
│   │   │   │   ├── installment_plan_screen.dart
│   │   │   │   ├── payment_screen.dart
│   │   │   │   ├── reconciliation_screen.dart
│   │   │   │   ├── transaction_history_screen.dart
│   │   │   │   └── wallet_screen.dart
│   │   │   ├── services/
│   │   │   │   └── payment_service.dart
│   │   │   └── widgets/
│   │   │       ├── payment_method_selector.dart
│   │   │       └── wallet_balance_card.dart
│   │   ├── prescriptions/
│   │   │   ├── models/
│   │   │   │   ├── prescription.dart
│   │   │   │   ├── prescription_item.dart
│   │   │   │   └── prescription_status.dart
│   │   │   ├── providers/
│   │   │   │   └── prescription_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── prescription_detail_screen.dart
│   │   │   │   ├── prescription_list_screen.dart
│   │   │   │   ├── prescription_preview_screen.dart
│   │   │   │   └── prescription_upload_screen.dart
│   │   │   ├── services/
│   │   │   │   ├── ocr_service.dart
│   │   │   │   └── prescription_service.dart
│   │   │   └── widgets/
│   │   │       ├── ocr_confidence_indicator.dart
│   │   │       ├── prescription_card.dart
│   │   │       ├── prescription_item_tile.dart
│   │   │       └── upload_guidance_overlay.dart
│   │   ├── reservations/
│   │   │   ├── models/
│   │   │   │   ├── reservation.dart
│   │   │   │   ├── reservation_item.dart
│   │   │   │   ├── reservation_status.dart
│   │   │   │   └── timeslot.dart
│   │   │   ├── providers/
│   │   │   │   └── reservation_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── cart_screen.dart
│   │   │   │   ├── pharmacy_queue_screen.dart
│   │   │   │   ├── reservation_checkout_screen.dart
│   │   │   │   ├── reservation_confirmation_screen.dart
│   │   │   │   ├── reservation_history_screen.dart
│   │   │   │   └── reservation_qr_screen.dart
│   │   │   ├── services/
│   │   │   │   └── reservation_service.dart
│   │   │   └── widgets/
│   │   │       ├── cart_item_tile.dart
│   │   │       └── timeslot_picker.dart
│   │   ├── search/
│   │   │   ├── models/
│   │   │   │   ├── availability_result.dart
│   │   │   │   ├── pharmacy.dart
│   │   │   │   └── product.dart
│   │   │   ├── providers/
│   │   │   │   └── search_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── search_screen.dart
│   │   │   ├── services/
│   │   │   │   └── search_service.dart
│   │   │   └── widgets/
│   │   │       ├── filter_chips.dart
│   │   │       ├── pharmacy_list_tile.dart
│   │   │       ├── product_card.dart
│   │   │       └── search_bar.dart
│   │   └── (27 autres modules — dossiers vides, aucun fichier)
│   ├── routes/
│   │   └── app_router.dart
│   ├── shared/            → models/providers/repositories/services, tous vides à ce jour
│   ├── app.dart
│   └── main.dart
├── scripts/
│   └── ci/
│       ├── check_no_cross_schema_fk.sh
│       ├── check_no_hardcoded_color.sh
│       └── check_no_hardcoded_currency.sh
├── supabase/
│   ├── config.toml
│   └── migrations/         → vide à ce jour
├── test/
│   └── widget_test.dart    (test/unit/ et test/widget/ existent mais sont vides)
├── assets/
│   └── config/
│       └── kernel_config.json
├── CLAUDE.md                    → contexte portefeuille GSG + règles Kernel v3.0
├── PharmaConnect_CLAUDE.md       → état vivant du code, à jour en continu
├── REFERENTIEL_ARCHITECTE.md     → directives de conception pour les modules à venir
├── code_export_architecte.md     → ce document
└── pubspec.yaml
```

## Résumé des corrections appliquées

### Mise en conformité Kernel GSG v3.0 (audit + remédiation)

Un audit de conformité au cahier Kernel GSG v3.0 a mis en évidence un backend d'authentification parallèle et non branché à l'app, ainsi qu'un indicateur d'état Kernel entièrement simulé. Remédiation appliquée en 3 priorités, détail complet dans le rapport en fin de document (section « Rapport de mise en conformité Kernel »).

- **Backend OTP orphelin supprimé** — `supabase/functions/` (send-otp, verify-otp, otpProvider, issueSession) et les migrations `otp_codes` associées n'existaient dans aucun flux appelé par l'app (le SDK Supabase Auth natif est la seule voie utilisée par `auth_service.dart`), mais reproduisaient exactement les anti-patrons KER-ID-02 : génération de code OTP maison, wrapper direct Resend/Meta Cloud API, signature JWT manuelle en contournement de l'API admin Supabase. Supprimés intégralement.
- **Indicateur Kernel sidebar corrigé** — `sidebar_navigation.dart` codait en dur `isConnected: true` et 4 services `online`, sans aucun appel réseau réel. Bascule sur un état honnête (`isConnected: false`, services `offline`, libellé « Non connecté (Dev) ») avec `TODO(kernel-integration)` explicite dans `kernel_connection_indicator.dart`.
- **`CurrencyFormatter` créé** (`lib/core/utils/currency_formatter.dart`) — centralise le code devise (ISO 4217 `GNF` / `324`), remplace 10 occurrences de `'... GNF'` codées en dur dans `payment_screen.dart`, `wallet_balance_card.dart`, `cart_screen.dart`, `cart_item_tile.dart`, `pharmacy_list_tile.dart`.
- **`assets/config/kernel_config.json` peuplé** — était vide (0 octet) ; contient désormais les valeurs de repli local (Guinée / GNF / FR) pour le mode dégradé KER-ARC-03.
- **`GsgKernelAuthBridge` créé** (`lib/core/kernel/gsg_kernel_auth_bridge.dart`) — échange la session Supabase contre une identité GSG ID via `POST /v1/auth/sso/supabase`, branché dans `auth_provider.dart` juste après un `verifyOTP()` réussi. Best-effort et non bloquant : toute erreur réseau renvoie `null` sans jamais faire échouer le login (patron de résilience KER-ARC-03 à reproduire pour toute future intégration Kernel).
- **Garde-fous CI ajoutés** — `scripts/ci/check_no_cross_schema_fk.sh` (KER-VIS-03) et `scripts/ci/check_no_hardcoded_currency.sh` (KER-REF), tous deux testés positivement et négativement, exécutés par `.github/workflows/kernel-compliance.yml` sur chaque push/PR avec `flutter analyze`.
- **Règles d'architecture sanctuarisées** — la directive « PK locale + `gsg_id`/`gsg_org_id` en colonnes nullable » et les autres invariants Kernel sont désormais figés dans `CLAUDE.md`/`PharmaConnect_CLAUDE.md`, pas seulement dans l'historique de conversation.
- **`REFERENTIEL_ARCHITECTE.md` créé** — document de conception pour l'architecte en chef : gabarit obligatoire par module, checklist Kernel, regroupement des 27 modules restants, et écarts supplémentaires détectés en creusant (montants stockés en `double` au lieu d'entier unité mineure — KER-REF-05 ; téléphones jamais normalisés E.164 ; gestion d'erreur incohérente entre providers). Voir ce fichier pour le détail.
- **Couleurs de statut codées en dur corrigées (KER-DES-03)** — en préparant `REFERENTIEL_ARCHITECTE.md`, une nouvelle règle Kernel (contrat de tokens sémantiques) a révélé que les getters `statusColor`/`stockColor` de 5 modèles (`delivery.dart`, `transaction.dart`, `prescription.dart`, `reservation.dart`, `availability_result.dart`) retournaient un `Color(0xFF...)` littéral au lieu d'une constante `PharmaConnectColors` — 27 occurrences, le même gabarit reproduit à chaque fois. Deux tokens manquants ajoutés (`neutralMuted`, `accentAmber`), les 27 littéraux remplacés, troisième garde-fou CI `scripts/ci/check_no_hardcoded_color.sh` ajouté et câblé dans `.github/workflows/kernel-compliance.yml`.

### Modules livraison, paiements, réservations (`modules/delivery`, `modules/payments`, `modules/reservations`) + routeur

Ces trois modules ainsi que le module `prescriptions` avaient été codés depuis le dernier export mais n'avaient jamais été compilés : `flutter analyze` remontait 149 signalements (87 erreurs bloquantes), et le routeur pointait vers 13 écrans qui n'existaient dans aucun fichier du projet.

- **`delivery/models/delivery.dart`**, **`reservations/models/reservation.dart`**, **`payments/models/transaction.dart`** : usage de `Color` sans `import 'package:flutter/material.dart'` → 18 erreurs de compilation à elles trois.
- **`payments/models/transaction.dart`** : référence à un enum `TransactionStatus` qui n'existait dans aucun fichier du projet → créé `payments/models/transaction_status.dart` (pending / processing / completed / failed / refunded / disputed).
- **`payments/models/installment.dart`** et **`payments/services/payment_service.dart`** : import vers `installment_status.dart`, un fichier qui n'a jamais existé — l'enum était en réalité déjà défini dans `installment.dart`. Imports morts supprimés.
- **`payments/services/payment_service.dart`** : `getWalletBalance()` retournait un `int` pour une signature `Future<double>` → corrigé.
- **`delivery/screens/delivery_tracking_screen.dart`** et **`delivery/widgets/delivery_card.dart`** : utilisaient `Delivery`/`DeliveryStatus` sans les importer directement (les imports Dart ne sont jamais transitifs) → imports ajoutés.
- **`reservations/providers/reservation_provider.dart`** : `_selectedPharmacyName` et `_selectedPharmacyAddress` étaient renseignés par `setPharmacyInfo()` mais jamais exposés → getters publics ajoutés, `_cartItems` passé en `final`.
- 8 imports morts supprimés (`reservation_item.dart`, `cart_screen.dart`, `timeslot_picker.dart`, `wallet_balance_card.dart`, `delivery_card.dart`).
- Modernisation : 28 appels à `.withOpacity()` (déprécié) remplacés par `.withValues(alpha:)` dans les modules delivery/payments/reservations/prescriptions ; `const` ajouté sur les constructeurs éligibles ; `.toList()` superflu retiré dans un spread.
- **`routes/app_router.dart`** : 13 classes d'écran référencées mais jamais créées (`ReservationCheckoutScreen`, `ReservationConfirmationScreen`, `ReservationQRScreen`, `ReservationHistoryScreen`, `PharmacyQueueScreen`, `DeliveryHistoryScreen`, `DeliveryScheduleScreen`, `DriverDashboardScreen`, `InstallmentPlanScreen`, `WalletScreen`, `TransactionHistoryScreen`, `DisputeScreen`, `ReconciliationScreen`). Plutôt que d'inventer des écrans complets, un composant partagé **`core/widgets/screens/placeholder_screen.dart`** a été créé, et chacune de ces 13 classes est une coquille minimale qui l'utilise — l'app compile et chaque route est navigable, mais l'UI et la logique métier réelles de ces écrans restent à concevoir. Voir le rapport d'audit en fin de document pour le détail complet.
- `flutter analyze` : 149 problèmes (87 erreurs) → **0 problème** (« No issues found! »). `flutter test` : 1 test passe.

### Module recherche (`modules/search`)
- **`models/availability_result.dart`** : import manquant de `package:flutter/material.dart` (utilisation de `Color`) → 5 erreurs de compilation corrigées.
- **`services/search_service.dart`** : `dart:math` importé sans préfixe alors que le code appelait `math.sin/cos/sqrt/atan2` et `Random` avec préfixe → import changé en `import 'dart:math' as math;`, `Random` → `math.Random`.
- **`widgets/filter_chips.dart`** : `_buildClearChip()` utilisait `context` sans le recevoir en paramètre → `BuildContext context` ajouté et propagé depuis `build()`.
- Imports inutilisés supprimés dans `product_detail_screen.dart`, `pharmacy_list_tile.dart`, `product_card.dart`.
- Nettoyage lint complet : `withOpacity()` (déprécié) → `withValues(alpha: …)`, ajout de `const` sur les constructeurs éligibles, suppression d'interpolations de chaîne et de `.toList()` inutiles, champ `_stocks` passé en `final`.
- `flutter analyze` : 8 erreurs + 4 avertissements + 26 infos → **0 problème** (« No issues found! »).

### Historique (corrections précédentes — module auth)
- **pubspec.yaml** : sections `fonts`/`assets` mal imbriquées sous `dev_dependencies` → déplacées sous une clé `flutter:` dédiée.
- **auth_service.dart** : réécrit pour l'API réelle de `supabase_flutter ^2.0.0` (`signInWithOtp`, `verifyOTP`) — le code initial visait l'API v1.
- **auth_provider.dart** : import manquant de `SupabaseService` corrigé ; champ `_pendingIdentifier` exposé via un getter.
- **app_router.dart** : route `/2fa` supprimée (pointait vers un écran `TwoFactorScreen` jamais créé).
- **supabase_service.dart** : `anonKey` (déprécié) → `publishableKey`.
- **login_screen.dart** : deux `Row` qui débordaient horizontalement remplacés par des `Wrap` ; usage de `context.mounted` remplacé par `mounted` (State).
- **primary_button.dart** : libellé du bouton encapsulé dans un `Flexible` + ellipse pour éviter tout débordement sur petit écran.
- **widget_test.dart** : initialisation mock de Supabase/SharedPreferences ajoutée ; assertion alignée sur l'écran réel de démarrage (`/login`).
- Nettoyage lint (`dart fix --apply`) sur `login_screen.dart`, `register_screen.dart`, `otp_verification_screen.dart`.

---

## `pubspec.yaml`

```yaml
name: pharma_connect
description: PharmaConnect — Infrastructure numérique du circuit pharmaceutique et des soins à domicile en Afrique de l'Ouest.
version: 0.1.0
publish_to: "none"

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter

  # UI & DESIGN
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.0

  # ÉTAT & ARCHITECTURE
  provider: ^6.1.0
  equatable: ^2.0.5

  # ROUTING
  go_router: ^13.0.0

  # STOCKAGE LOCAL
  shared_preferences: ^2.2.0
  sqflite: ^2.3.0
  path: ^1.8.0

  # RÉSEAU
  dio: ^5.3.0
  connectivity_plus: ^5.0.0

  # SUPABASE
  supabase_flutter: ^2.0.0

  # SCAN & CAMÉRA
  mobile_scanner: ^3.5.0
  image_picker: ^1.0.0

  # NOTIFICATIONS
  flutter_local_notifications: ^16.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true

  # ==================== POLICES DE CARACTÈRES ====================
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        # NOTE: seul le poids Light est présent sur disque pour l'instant ;
        # remplacez par JetBrainsMono-Regular.ttf si vous l'ajoutez plus tard.
        - asset: assets/fonts/JetBrainsMono/JetBrainsMono-Light.ttf
          weight: 400

  # ==================== ASSETS ====================
  assets:
    - assets/icons/
    - assets/images/
    - assets/config/
```

## `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/dashboard/providers/dashboard_provider.dart';
import 'modules/search/providers/search_provider.dart';

class PharmaConnectApp extends StatelessWidget {
  const PharmaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp.router(
        title: 'PharmaConnect',
        theme: PharmaConnectAppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
```

## `lib/core/kernel/gsg_kernel_auth_bridge.dart`

```dart
import 'package:dio/dio.dart';

/// Pont d'échange de session vers le GSG ID (Kernel) — KER-ID-02.
///
/// Appelé après un `verifyOTP()` Supabase réussi, jamais avant : Supabase Auth
/// reste l'unique mécanisme qui authentifie l'utilisateur. Cet appel ne fait
/// qu'échanger la session déjà valide contre une identité GSG.
///
/// Ne lève jamais d'exception et ne bloque jamais le flux de connexion : si le
/// Kernel est injoignable, en panne, ou pas encore déployé, l'app continue en
/// mode dégradé avec la session Supabase seule (KER-ARC-03). L'appelant ne
/// doit jamais attendre ce résultat pour considérer le login terminé.
class GsgKernelAuthBridge {
  GsgKernelAuthBridge({Dio? httpClient, String? baseUrl})
    : _dio = httpClient ?? Dio(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  // TODO(kernel-integration) : remplacer par l'URL réelle du GSG Kernel une
  // fois fournie par l'architecte (cahier de conception v3.0). Même
  // convention que SupabaseService pour les valeurs de config à renseigner.
  static const String _defaultBaseUrl = 'https://kernel.gsg.example';

  static const Duration _timeout = Duration(seconds: 5);

  final Dio _dio;
  final String _baseUrl;

  Future<GsgIdentity?> exchangeSupabaseSession({
    required String supabaseAccessToken,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/v1/auth/sso/supabase',
        data: {'supabase_access_token': supabaseAccessToken, 'supabase_user_id': userId},
        options: Options(sendTimeout: _timeout, receiveTimeout: _timeout),
      );

      final data = response.data;
      final gsgId = data is Map ? data['gsg_id'] as String? : null;
      if (gsgId == null) return null;

      return GsgIdentity(gsgId: gsgId, gsgOrgId: data['gsg_org_id'] as String?);
    } catch (_) {
      return null;
    }
  }
}

class GsgIdentity {
  final String gsgId;
  final String? gsgOrgId;

  const GsgIdentity({required this.gsgId, this.gsgOrgId});
}
```

## `lib/core/kernel/kernel_badge.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

class KernelBadge extends StatelessWidget {
  final bool showIcon;
  final double size;
  final bool showLabel;

  const KernelBadge({
    super.key,
    this.showIcon = true,
    this.size = 16,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(
          color: PharmaConnectColors.accentPurple.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text('⚡', style: TextStyle(fontSize: size)),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel) ...[
            const Text(
              'Kernel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PharmaConnectColors.accentPurple,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## `lib/core/kernel/kernel_connection_indicator.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/glass.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'kernel_badge.dart';
import 'kernel_status.dart';

class KernelConnectionIndicator extends StatefulWidget {
  final KernelStatus status;
  final bool expanded;

  const KernelConnectionIndicator({
    super.key,
    required this.status,
    this.expanded = false,
  });

  @override
  State<KernelConnectionIndicator> createState() =>
      _KernelConnectionIndicatorState();
}

class _KernelConnectionIndicatorState extends State<KernelConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: PharmaConnectGlass.glassDark.copyWith(
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================== EN-TÊTE ====================
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de connexion
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.status.isConnected
                          ? PharmaConnectColors.accentGreen
                          : PharmaConnectColors.accentRed,
                      boxShadow: widget.status.isConnected
                          ? [
                              BoxShadow(
                                color: PharmaConnectColors.accentGreen
                                    .withValues(
                                      alpha: 0.4 + 0.3 * _pulseController.value,
                                    ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'GSG KERNEL',
                  style: PharmaConnectTypography.subtitle2.copyWith(
                    color: PharmaConnectColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.status.isConnected
                      ? 'v${widget.status.version}'
                      : 'Non connecté (Dev)',
                  style: PharmaConnectTypography.micro.copyWith(
                    color: widget.status.isConnected
                        ? PharmaConnectColors.textSecondary
                        : PharmaConnectColors.accentOrange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 6),
                const KernelBadge(),
              ],
            ],
          ),

          // ==================== DÉTAILS DES SERVICES ====================
          if (widget.expanded) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Services actifs :  ${widget.status.onlineCount}/${widget.status.totalCount}',
                    style: PharmaConnectTypography.body2.copyWith(
                      color: PharmaConnectColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.status.isConnected
                  ? 'Dernière synchro : ${_formatLastSync(widget.status.lastSync)}'
                  : 'Aucune synchronisation — intégration non branchée',
              style: PharmaConnectTypography.micro.copyWith(
                color: PharmaConnectColors.textSecondary.withValues(
                  alpha: 0.7,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Liste des services
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.status.services.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(
                      PharmaConnectSpacing.radiusSm,
                    ),
                    border: Border.all(
                      color: service.statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(service.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: service.statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: service.statusColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastSync(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
```

## `lib/core/kernel/kernel_status.dart`

```dart
import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum KernelServiceStatus { online, degraded, offline }

class KernelService {
  final String name;
  final String icon;
  final KernelServiceStatus status;

  const KernelService({
    required this.name,
    required this.icon,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case KernelServiceStatus.online:
        return PharmaConnectColors.accentGreen;
      case KernelServiceStatus.degraded:
        return PharmaConnectColors.accentOrange;
      case KernelServiceStatus.offline:
        return PharmaConnectColors.accentRed;
    }
  }

  String get statusLabel {
    switch (status) {
      case KernelServiceStatus.online:
        return 'Online';
      case KernelServiceStatus.degraded:
        return 'Dégradé';
      case KernelServiceStatus.offline:
        return 'Offline';
    }
  }
}

class KernelStatus {
  final bool isConnected;
  final String version;
  final List<KernelService> services;
  final DateTime lastSync;

  const KernelStatus({
    required this.isConnected,
    required this.version,
    required this.services,
    required this.lastSync,
  });

  int get onlineCount {
    return services.where((s) => s.status == KernelServiceStatus.online).length;
  }

  int get totalCount => services.length;

  bool get isFullyOperational => onlineCount == totalCount;
}
```

## `lib/core/services/supabase_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://votre-projet.supabase.co';
  static const String supabaseAnonKey = 'votre-clé-anon';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => Supabase.instance.client.auth;

  User? get currentUser => auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> signOut() async => await auth.signOut();
}
```

## `lib/core/theme/animations.dart`

```dart
import 'package:flutter/material.dart';

class PharmaConnectAnimations {
  // ==================== DURATIONS ====================
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration hoverTransition = Duration(milliseconds: 150);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration modalOpen = Duration(milliseconds: 250);
  static const Duration notificationSlide = Duration(milliseconds: 400);
  static const Duration kernelPulse = Duration(milliseconds: 2000);
  static const Duration scanLoading = Duration(milliseconds: 1200);
  static const Duration themeTransition = Duration(milliseconds: 400);

  // ==================== CURVES ====================
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.easeOutBack;

  // ==================== ANIMATION HELPERS ====================
  static Widget slideFadeTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    double offsetY = 20,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget scalePress({
    required Widget child,
    VoidCallback? onTap,
    double scale = 0.96,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1, end: 1),
        duration: buttonPress,
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: child,
      ),
    );
  }

  static AnimationController createKernelPulseController(TickerProvider vsync) {
    return AnimationController(duration: kernelPulse, vsync: vsync)..repeat();
  }

  static Widget shimmerScanLoading({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(0.3),
        ).createShader(
          Rect.fromLTWH(
            bounds.left + animation.value * bounds.width,
            0,
            bounds.width * 0.3,
            bounds.height,
          ),
        );
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}
```

## `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class PharmaConnectAppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ==================== COULEURS ====================
      primaryColor: PharmaConnectColors.accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: PharmaConnectColors.accentCyan,
        secondary: PharmaConnectColors.accentPurple,
        surface: PharmaConnectColors.primaryDeep,
        error: PharmaConnectColors.accentRed,
        onPrimary: PharmaConnectColors.textOnAccent,
        onSecondary: PharmaConnectColors.textPrimary,
        onSurface: PharmaConnectColors.textPrimary,
        onError: PharmaConnectColors.textPrimary,
      ),

      // ==================== TYPOGRAPHIE ====================
      textTheme: PharmaConnectTypography.textTheme,

      // ==================== SCAFFOLD ====================
      scaffoldBackgroundColor: PharmaConnectColors.primaryDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: PharmaConnectTypography.heading2,
        iconTheme: IconThemeData(color: PharmaConnectColors.textPrimary),
        actionsIconTheme: IconThemeData(color: PharmaConnectColors.textPrimary),
      ),

      // ==================== CARDS ====================
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== INPUTS ====================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentCyan,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentRed,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: const BorderSide(
            color: PharmaConnectColors.accentRed,
            width: 2,
          ),
        ),
        labelStyle: PharmaConnectTypography.label,
        hintStyle: PharmaConnectTypography.body2.copyWith(
          color: PharmaConnectColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIconColor: PharmaConnectColors.textSecondary,
        suffixIconColor: PharmaConnectColors.textSecondary,
      ),

      // ==================== BOUTONS ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentCyan,
          foregroundColor: PharmaConnectColors.textOnAccent,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      // ==================== DIALOGS ====================
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== FONTES ====================
      fontFamily: 'Inter',
    );
  }

  // ==================== THÈME CLAIR (OPTIONNEL) ====================
  static ThemeData light() {
    // À développer ultérieurement
    return dark();
  }
}
```

## `lib/core/theme/colors.dart`

```dart
import 'package:flutter/material.dart';

class PharmaConnectColors {
  // ==================== FOND ====================
  static const Color primaryDeep = Color(0xFF0A0E1A);

  // ==================== ACCENTS ====================
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentAmber = Color(0xFFFF9100);
  static const Color accentRed = Color(0xFFEF4444);

  // ==================== TEXTE ====================
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textOnAccent = Color(0xFF0A0E1A);

  // ==================== NEUTRES ====================
  static const Color neutralMuted = Color(0xFF6B7280);

  // ==================== OVERLAYS ====================
  static const Color overlayDark = Color(0xB3000000);
}
```

## `lib/core/theme/glass.dart`

```dart
import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

class PharmaConnectGlass {
  // ==================== GLASS STYLES ====================
  static BoxDecoration glassPrimary = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.10),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glassDark = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.10),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration glassLight = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.06),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glassGlowCyan = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: PharmaConnectColors.accentCyan.withValues(alpha: 0.30),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.20),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration glassGlowPurple = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
    border: Border.all(
      color: PharmaConnectColors.accentPurple.withValues(alpha: 0.30),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: PharmaConnectColors.accentPurple.withValues(alpha: 0.20),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
  );

  // ==================== GLASS UTILITY ====================
  static BoxDecoration glassCustom({
    required double opacity,
    double borderRadius = 16,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != Colors.transparent
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  // ==================== GLASS MODAL OVERLAY ====================
  static BoxDecoration glassModalOverlay = const BoxDecoration(
    color: PharmaConnectColors.overlayDark,
    backgroundBlendMode: BlendMode.darken,
  );
}
```

## `lib/core/theme/spacing.dart`

```dart
class PharmaConnectSpacing {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const double gutter = 24;

  // Border radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // Sidebar
  static const double sidebarCollapsed = 72;
  static const double sidebarExpanded = 240;

  // Max content width
  static const double maxContentWidth = 1440;
}
```

## `lib/core/theme/typography.dart`

```dart
import 'package:flutter/material.dart';

import 'colors.dart';

class PharmaConnectTypography {
  static const String fontFamily = 'Inter';

  // ==================== TEXT STYLES ====================
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: 'JetBrainsMono', // Police monospace pour code
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: PharmaConnectColors.textSecondary,
  );

  static const TextStyle kpiLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle kpiMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  static const TextStyle kpiSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: PharmaConnectColors.textPrimary,
  );

  // ==================== TEXT THEME ====================
  static TextTheme get textTheme => const TextTheme(
    displayLarge: heading1,
    displayMedium: heading2,
    displaySmall: heading3,
    headlineMedium: subtitle1,
    headlineSmall: subtitle2,
    bodyLarge: body1,
    bodyMedium: body2,
    labelLarge: label,
    labelSmall: micro,
  );
}
```

## `lib/core/utils/currency_formatter.dart`

```dart
/// Point d'entrée unique pour l'affichage des montants monétaires du produit.
///
/// La devise par défaut (GNF, ISO 4217 alpha-3 / numérique 324) est câblée en
/// dur tant que le produit ne gère qu'un seul marché. Quand le GSG Referential
/// sera branché (KER-REF), `defaultCurrencyCode` devra venir du référentiel
/// résolu pour l'organisation courante plutôt que d'une constante ici.
class CurrencyFormatter {
  const CurrencyFormatter._();

  static const String defaultCurrencyCode = 'GNF';
  static const int defaultCurrencyNumericCode = 324;

  static String format(num amount, {String currencyCode = defaultCurrencyCode}) {
    return '${amount.toStringAsFixed(0)} $currencyCode';
  }
}
```

## `lib/core/utils/extensions.dart`

```dart

```

## `lib/core/utils/validators.dart`

```dart

```

## `lib/core/widgets/badges/status_badge.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

enum StatusBadgeType {
  success, // Vert
  warning, // Orange
  danger, // Rouge
  info, // Cyan
  kernel, // Violet
  neutral, // Gris
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType status;
  final bool showGlow;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final glow = _getGlow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: glow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case StatusBadgeType.success:
        return PharmaConnectColors.accentGreen;
      case StatusBadgeType.warning:
        return PharmaConnectColors.accentOrange;
      case StatusBadgeType.danger:
        return PharmaConnectColors.accentRed;
      case StatusBadgeType.info:
        return PharmaConnectColors.accentCyan;
      case StatusBadgeType.kernel:
        return PharmaConnectColors.accentPurple;
      case StatusBadgeType.neutral:
        return PharmaConnectColors.textSecondary;
    }
  }

  List<BoxShadow>? _getGlow() {
    if (!showGlow) return null;
    final color = _getColor();
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }
}
```

## `lib/core/widgets/buttons/danger_button.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentRed,
          foregroundColor: PharmaConnectColors.textPrimary,
          disabledBackgroundColor: PharmaConnectColors.accentRed.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: PharmaConnectColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PharmaConnectColors.textPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/buttons/kernel_button.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class KernelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;

  const KernelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentPurple.withValues(
            alpha: 0.10,
          ),
          foregroundColor: isDisabled
              ? PharmaConnectColors.textSecondary
              : PharmaConnectColors.accentPurple,
          side: BorderSide(
            color: isDisabled
                ? PharmaConnectColors.textSecondary.withValues(alpha: 0.2)
                : PharmaConnectColors.accentPurple.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PharmaConnectColors.accentPurple,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/buttons/primary_button.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: PharmaConnectColors.accentCyan,
          foregroundColor: PharmaConnectColors.textOnAccent,
          disabledBackgroundColor: PharmaConnectColors.accentCyan.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: PharmaConnectColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PharmaConnectColors.textOnAccent,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/buttons/secondary_button.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final double width;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isDisabled = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && onPressed != null;

    return SizedBox(
      width: width,
      height: 50,
      child: OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isDisabled
              ? PharmaConnectColors.textSecondary
              : PharmaConnectColors.textPrimary,
          side: BorderSide(
            color: isDisabled
                ? PharmaConnectColors.textSecondary.withValues(alpha: 0.2)
                : PharmaConnectColors.textPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/buttons/tertiary_button.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class TertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final IconData? icon;

  const TertiaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isDisabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && onPressed != null;

    return TextButton(
      onPressed: isInteractive ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isDisabled
            ? PharmaConnectColors.textSecondary
            : PharmaConnectColors.accentCyan,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
```

## `lib/core/widgets/cards/glass_card.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/glass.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool glow;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool hoverEffect;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
    this.glow = false,
    this.glowColor,
    this.onTap,
    this.hoverEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onTap != null;

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: hoverEffect && isInteractive
              ? (Matrix4.identity()..translateByDouble(0, -2, 0, 0))
              : Matrix4.identity(),
          decoration: glow
              ? (glowColor == PharmaConnectColors.accentPurple
                  ? PharmaConnectGlass.glassGlowPurple
                  : PharmaConnectGlass.glassGlowCyan)
              : PharmaConnectGlass.glassPrimary,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/cards/status_card.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../badges/status_badge.dart';
import 'glass_card.dart';

class StatusCard extends StatelessWidget {
  final Widget child;
  final Color statusColor;
  final String statusLabel;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.child,
    required this.statusColor,
    required this.statusLabel,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: StatusBadge(
              label: statusLabel,
              status: _mapStatusToBadge(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  StatusBadgeType _mapStatusToBadge(Color color) {
    if (color == PharmaConnectColors.accentGreen) {
      return StatusBadgeType.success;
    } else if (color == PharmaConnectColors.accentOrange) {
      return StatusBadgeType.warning;
    } else if (color == PharmaConnectColors.accentRed) {
      return StatusBadgeType.danger;
    } else if (color == PharmaConnectColors.accentPurple) {
      return StatusBadgeType.kernel;
    }
    return StatusBadgeType.info;
  }
}
```

## `lib/core/widgets/inputs/glass_input.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class GlassInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool isError;
  final String? errorText;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const GlassInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.isError = false,
    this.errorText,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PharmaConnectTypography.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          enabled: !isDisabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: PharmaConnectTypography.body1.copyWith(
            color: isDisabled ? PharmaConnectColors.textSecondary : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.textSecondary.withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isError
                        ? PharmaConnectColors.accentRed
                        : PharmaConnectColors.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: isError
                          ? PharmaConnectColors.accentRed
                          : PharmaConnectColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onSuffixPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            errorText: isError ? errorText : null,
            errorStyle: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
            filled: true,
            fillColor: isDisabled
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? PharmaConnectColors.accentRed
                    : Colors.white.withValues(alpha: 0.10),
                width: isError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? PharmaConnectColors.accentRed
                    : Colors.white.withValues(alpha: 0.10),
                width: isError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? PharmaConnectColors.accentRed
                    : PharmaConnectColors.accentCyan,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: const BorderSide(
                color: PharmaConnectColors.accentRed,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: const BorderSide(
                color: PharmaConnectColors.accentRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (errorText != null && !isError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        ],
      ],
    );
  }
}
```

## `lib/core/widgets/modals/glass_modal.dart`

```dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/glass.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class GlassModal extends StatelessWidget {
  final Widget child;
  final double width;
  final double maxWidth;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final String? title;
  final List<Widget>? actions;

  const GlassModal({
    super.key,
    required this.child,
    this.width = 720,
    this.maxWidth = 0.9,
    this.dismissible = true,
    this.onDismiss,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: width.clamp(0, MediaQuery.of(context).size.width * maxWidth),
        decoration: PharmaConnectGlass.glassPrimary.copyWith(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== EN-TÊTE ====================
            if (title != null || actions != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                child: Row(
                  children: [
                    if (title != null) ...[
                      Expanded(
                        child: Text(
                          title!,
                          style: PharmaConnectTypography.heading3,
                        ),
                      ),
                    ],
                    if (actions != null) ...[...actions!],
                    if (dismissible) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: PharmaConnectColors.textSecondary,
                          size: 24,
                        ),
                        onPressed:
                            onDismiss ?? () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
            ],
            // ==================== CONTENU ====================
            Flexible(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double width = 720,
    double maxWidth = 0.9,
    bool dismissible = true,
    VoidCallback? onDismiss,
    String? title,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: PharmaConnectColors.overlayDark,
      builder: (context) => GlassModal(
        width: width,
        maxWidth: maxWidth,
        dismissible: dismissible,
        onDismiss: onDismiss,
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }
}
```

## `lib/core/widgets/navigation/sidebar_navigation.dart`

```dart
import 'package:flutter/material.dart';

import '../../kernel/kernel_connection_indicator.dart';
import '../../kernel/kernel_status.dart';
import '../../theme/colors.dart';
import '../../theme/glass.dart';
import '../../theme/spacing.dart';

class SidebarNavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final bool isActive;

  const SidebarNavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isActive = false,
  });
}

class SidebarNavigation extends StatefulWidget {
  final List<SidebarNavigationItem> items;
  final String currentRoute;
  final ValueChanged<String> onItemSelected;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  const SidebarNavigation({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onItemSelected,
    this.expanded = true,
    this.onToggleExpand,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.expanded ? 1 : 0,
    );
    _widthAnimation =
        Tween<double>(
          begin: PharmaConnectSpacing.sidebarCollapsed,
          end: PharmaConnectSpacing.sidebarExpanded,
        ).animate(
          CurvedAnimation(parent: _expandController, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(SidebarNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: PharmaConnectGlass.glassDark.copyWith(
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ==================== BRAND ====================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '◈',
                          style: TextStyle(
                            fontSize: 28,
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ),
                    ),
                    if (widget.expanded) ...[
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (widget.onToggleExpand != null) ...[
                      IconButton(
                        icon: Icon(
                          widget.expanded
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: PharmaConnectColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: widget.onToggleExpand,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // ==================== ITEMS ====================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isActive = item.route == widget.currentRoute;

                    return _SidebarItem(
                      item: item,
                      isActive: isActive,
                      expanded: widget.expanded,
                      onTap: () => widget.onItemSelected(item.route),
                    );
                  },
                ),
              ),

              // ==================== KERNEL INDICATOR ====================
              Padding(
                padding: const EdgeInsets.all(12),
                child: KernelConnectionIndicator(
                  // TODO(kernel-integration) : ce statut est un placeholder de
                  // développement, pas une lecture réelle du GSG Kernel — aucune
                  // intégration réseau n'existe encore (cf. audit KER-ARC-03).
                  // Ne jamais remettre isConnected/online en dur ici : brancher un
                  // KernelStatusPort réel (HTTP + fallback) avant de rétablir un
                  // statut "connecté".
                  status: KernelStatus(
                    isConnected: false,
                    version: '3.0',
                    services: [
                      const KernelService(
                        name: 'GSG ID',
                        icon: '🔐',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Org Registry',
                        icon: '🏛️',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Referential',
                        icon: '📋',
                        status: KernelServiceStatus.offline,
                      ),
                      const KernelService(
                        name: 'Audit',
                        icon: '📝',
                        status: KernelServiceStatus.offline,
                      ),
                    ],
                    lastSync: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
                  expanded: widget.expanded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final SidebarNavigationItem item;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? PharmaConnectColors.accentCyan.withValues(alpha: 0.10)
                : (_isHovered
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
            border: widget.isActive
                ? const Border(
                    left: BorderSide(
                      color: PharmaConnectColors.accentCyan,
                      width: 3,
                    ),
                  )
                : null,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: PharmaConnectColors.accentCyan.withValues(
                        alpha: 0.15,
                      ),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Icon(
                    widget.item.icon,
                    color: widget.isActive
                        ? PharmaConnectColors.accentCyan
                        : (_isHovered
                              ? PharmaConnectColors.textPrimary
                              : PharmaConnectColors.textSecondary),
                    size: 22,
                  ),
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive
                          ? PharmaConnectColors.textPrimary
                          : (_isHovered
                                ? PharmaConnectColors.textPrimary
                                : PharmaConnectColors.textSecondary),
                    ),
                  ),
                ),
                if (widget.isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PharmaConnectColors.accentCyan,
                      boxShadow: [
                        BoxShadow(
                          color: PharmaConnectColors.accentCyan.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

## `lib/core/widgets/screens/placeholder_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Écran temporaire pour les fonctionnalités pas encore implémentées.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.message = 'Cet écran est en cours de développement.',
    this.icon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: PharmaConnectTypography.heading2),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: PharmaConnectTypography.body2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/main.dart`

```dart
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const PharmaConnectApp());
}
```

## `lib/modules/auth/models/user_role.dart`

```dart
enum UserRole {
  patient,
  pharmacien,
  grossiste,
  livreur,
  professionnel,
  regulateur,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.pharmacien:
        return 'Pharmacien titulaire';
      case UserRole.grossiste:
        return 'Grossiste répartiteur';
      case UserRole.livreur:
        return 'Livreur';
      case UserRole.professionnel:
        return 'Professionnel de santé';
      case UserRole.regulateur:
        return 'Régulateur / Institution';
    }
  }
}
```

## `lib/modules/auth/providers/auth_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/kernel/gsg_kernel_auth_bridge.dart';
import '../../../core/services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GsgKernelAuthBridge _kernelBridge = GsgKernelAuthBridge();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userPhone;
  UserRole? _userRole;
  String? _pendingIdentifier; // stocke l'email ou téléphone en cours
  String? _gsgId;
  String? _gsgOrgId;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  UserRole? get userRole => _userRole;
  String? get pendingIdentifier => _pendingIdentifier;
  String? get gsgId => _gsgId;
  String? get gsgOrgId => _gsgOrgId;

  // === TÉLÉPHONE ===

  Future<bool> sendPhoneOtp(String phone, String channel) async {
    _setLoading(true);
    try {
      await _authService.sendPhoneOtp(phone, channel: channel);
      _pendingIdentifier = phone;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyPhoneOtp(phone, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userPhone = user.phone;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // === EMAIL ===

  Future<bool> sendEmailOtp(String email, bool isMagicLink) async {
    _setLoading(true);
    try {
      if (isMagicLink) {
        await _authService.sendMagicLink(email);
      } else {
        await _authService.sendEmailOtp(email);
      }
      _pendingIdentifier = email;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String email, String token) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyEmailOtp(email, token);
      final user = response.user;
      if (user != null) {
        _userId = user.id;
        _userEmail = user.email;
        _isAuthenticated = true;
        _pendingIdentifier = null;
        _setLoading(false);
        _bridgeToGsgKernel(user.id, response.session?.accessToken);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // === PONT GSG KERNEL ===

  /// Échange la session Supabase fraîchement établie contre une identité GSG
  /// ID. Best-effort et non bloquant : ne fait jamais échouer le login déjà
  /// acquis, et se contente de ne pas renseigner gsgId/gsgOrgId si le Kernel
  /// est injoignable (KER-ARC-03).
  void _bridgeToGsgKernel(String userId, String? accessToken) {
    if (accessToken == null) return;
    _kernelBridge
        .exchangeSupabaseSession(supabaseAccessToken: accessToken, userId: userId)
        .then((identity) {
          if (identity == null) return;
          _gsgId = identity.gsgId;
          _gsgOrgId = identity.gsgOrgId;
          notifyListeners();
        });
  }

  // === DÉCONNEXION ===

  Future<void> logout() async {
    await SupabaseService().signOut();
    _userId = null;
    _userEmail = null;
    _userPhone = null;
    _userRole = null;
    _gsgId = null;
    _gsgOrgId = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void setRole(UserRole role) {
    _userRole = role;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

## `lib/modules/auth/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';

enum LoginMethod { emailCode, emailMagic, phoneWhatsapp, phoneSms }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  LoginMethod _selectedMethod = LoginMethod.emailCode;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  const Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connexion',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisissez votre identifiant et le mode de réception',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 32),

                  // ===== CHOIX DE LA MÉTHODE =====
                  _buildMethodChoiceChips(),
                  const SizedBox(height: 24),

                  // ===== CHAMP IDENTIFIANT =====
                  GlassInput(
                    label: _getIdentifierLabel(),
                    hint: _getIdentifierHint(),
                    controller: _identifierController,
                    prefixIcon: _getIdentifierIcon(),
                    keyboardType: _getKeyboardType(),
                  ),
                  const SizedBox(height: 8),

                  // ===== INFORMATION COMPLÉMENTAIRE =====
                  _buildMethodInfo(),
                  const SizedBox(height: 24),

                  // ===== BOUTON D'ENVOI =====
                  PrimaryButton(
                    label: _getButtonLabel(),
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_identifierController.text.isEmpty) return;
                      await _handleSendOtp(auth);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ===== LIEN INSCRIPTION =====
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ?',
                        style: PharmaConnectTypography.body2,
                      ),
                      TertiaryButton(
                        label: 'S\'inscrire',
                        onPressed: () => context.go('/register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ===== FOOTER KERNEL =====
                  const Divider(color: Colors.white12, height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Authentification sécurisée via GSG Kernel',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChoiceChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(LoginMethod.emailCode, '📧 Code OTP'),
        _buildChip(LoginMethod.emailMagic, '🔗 Magic Link'),
        _buildChip(LoginMethod.phoneWhatsapp, '💬 WhatsApp'),
        _buildChip(LoginMethod.phoneSms, '📱 SMS'),
      ],
    );
  }

  Widget _buildChip(LoginMethod method, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedMethod == method,
      onSelected: (selected) {
        if (selected) setState(() => _selectedMethod = method);
      },
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: _selectedMethod == method
            ? PharmaConnectColors.accentCyan
            : Colors.white24,
      ),
    );
  }

  String _getIdentifierLabel() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return 'Numéro de téléphone';
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return 'Adresse email';
    }
  }

  String _getIdentifierHint() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return '+224 612 345 678';
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return 'jean.dupont@example.com';
    }
  }

  IconData _getIdentifierIcon() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        return Icons.sms;
      case LoginMethod.phoneWhatsapp:
        return Icons.chat;
      case LoginMethod.emailMagic:
        return Icons.link;
      case LoginMethod.emailCode:
        return Icons.email;
    }
  }

  TextInputType _getKeyboardType() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
      case LoginMethod.phoneWhatsapp:
        return TextInputType.phone;
      case LoginMethod.emailMagic:
      case LoginMethod.emailCode:
        return TextInputType.emailAddress;
    }
  }

  Widget _buildMethodInfo() {
    String message;
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        message = 'Un code à 6 chiffres vous sera envoyé par SMS.';
        break;
      case LoginMethod.phoneWhatsapp:
        message = 'Un code à 6 chiffres vous sera envoyé sur WhatsApp.';
        break;
      case LoginMethod.emailMagic:
        message = 'Un lien de connexion vous sera envoyé par email.';
        break;
      case LoginMethod.emailCode:
        message = 'Un code à 6 chiffres vous sera envoyé par email.';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PharmaConnectColors.accentCyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PharmaConnectColors.accentCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: PharmaConnectColors.accentCyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: PharmaConnectTypography.micro.copyWith(
                color: PharmaConnectColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        return 'Envoyer le code par SMS';
      case LoginMethod.phoneWhatsapp:
        return 'Envoyer le code par WhatsApp';
      case LoginMethod.emailMagic:
        return 'Envoyer le lien de connexion';
      case LoginMethod.emailCode:
        return 'Envoyer le code par email';
    }
  }

  Future<void> _handleSendOtp(AuthProvider auth) async {
    final identifier = _identifierController.text.trim();
    bool success;

    switch (_selectedMethod) {
      case LoginMethod.phoneSms:
        success = await auth.sendPhoneOtp(identifier, 'sms');
        break;
      case LoginMethod.phoneWhatsapp:
        success = await auth.sendPhoneOtp(identifier, 'whatsapp');
        break;
      case LoginMethod.emailMagic:
        success = await auth.sendEmailOtp(identifier, true);
        break;
      case LoginMethod.emailCode:
        success = await auth.sendEmailOtp(identifier, false);
        break;
    }

    if (!mounted) return;

    if (success) {
      context.go(
        '/otp',
        extra: {'identifier': identifier, 'method': _selectedMethod.name},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi. Vérifiez votre identifiant.'),
          backgroundColor: PharmaConnectColors.accentRed,
        ),
      );
    }
  }
}
```

## `lib/modules/auth/screens/otp_verification_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isResendEnabled = true;
  int _resendCountdown = 60;

  late String _identifier;
  late String _method;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _identifier = args?['identifier'] ?? '';
    _method = args?['method'] ?? 'phoneSms';
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _isResendEnabled = false;
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown == 0) _isResendEnabled = true;
        });
      }
      return _resendCountdown > 0;
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 420,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Vérification', style: PharmaConnectTypography.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé à ${_identifier.isEmpty ? 'votre identifiant' : _identifier}.',
                    style: PharmaConnectTypography.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),
                  GlassInput(
                    label: 'Code à 6 chiffres',
                    hint: '• • • • • •',
                    controller: _otpController,
                    prefixIcon: Icons.sms,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isResendEnabled
                            ? 'Vous n\'avez pas reçu le code ?'
                            : 'Renvoyer dans $_resendCountdown s',
                        style: PharmaConnectTypography.body2,
                      ),
                      TertiaryButton(
                        label: 'Renvoyer',
                        isDisabled: !_isResendEnabled,
                        onPressed: _isResendEnabled
                            ? () {
                                // TODO: relancer l'envoi via auth
                                _startCountdown();
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Vérifier et se connecter',
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_otpController.text.length != 6) return;
                      bool success;
                      // Déterminer le type de vérification selon la méthode
                      if (_method == 'phoneSms' || _method == 'phoneWhatsapp') {
                        success = await auth.verifyPhoneOtp(
                          _identifier,
                          _otpController.text,
                        );
                      } else {
                        success = await auth.verifyEmailOtp(
                          _identifier,
                          _otpController.text,
                        );
                      }
                      if (success && context.mounted) {
                        context.go('/dashboard');
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code invalide ou expiré.'),
                            backgroundColor: PharmaConnectColors.accentRed,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TertiaryButton(
                        label: '← Retour à la connexion',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## `lib/modules/auth/screens/register_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;
  String _selectedMethod = 'emailCode'; // phoneSms, phoneWhatsapp, emailCode

  final List<Map<String, dynamic>> _roles = [
    {'label': 'Patient', 'value': UserRole.patient},
    {'label': 'Pharmacien titulaire', 'value': UserRole.pharmacien},
    {'label': 'Grossiste répartiteur', 'value': UserRole.grossiste},
    {'label': 'Livreur', 'value': UserRole.livreur},
    {'label': 'Professionnel de santé', 'value': UserRole.professionnel},
    {'label': 'Régulateur / Institution', 'value': UserRole.regulateur},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SizedBox(
            width: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        '◈',
                        style: TextStyle(
                          fontSize: 28,
                          color: PharmaConnectColors.accentCyan,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PHARMACONNECT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PharmaConnectColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      KernelBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Créer un compte',
                    style: PharmaConnectTypography.heading2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez l\'infrastructure numérique de la santé',
                    style: PharmaConnectTypography.body2,
                  ),
                  const SizedBox(height: 24),

                  // Nom complet
                  GlassInput(
                    label: 'Nom complet',
                    hint: 'Dr. Jean Dupont',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  // Rôle
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    dropdownColor: PharmaConnectColors.primaryDeep,
                    style: PharmaConnectTypography.body1,
                    decoration: InputDecoration(
                      labelText: 'Je suis un(e) :',
                      labelStyle: PharmaConnectTypography.label,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaConnectSpacing.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: PharmaConnectColors.accentCyan,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role['value'],
                        child: Text(
                          role['label'],
                          style: PharmaConnectTypography.body1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Identifiant (téléphone ou email)
                  GlassInput(
                    label:
                        _selectedMethod == 'phoneSms' ||
                            _selectedMethod == 'phoneWhatsapp'
                        ? 'Numéro de téléphone'
                        : 'Adresse email',
                    hint:
                        _selectedMethod == 'phoneSms' ||
                            _selectedMethod == 'phoneWhatsapp'
                        ? '+224 612 345 678'
                        : 'jean.dupont@example.com',
                    controller: _identifierController,
                    prefixIcon: _selectedMethod == 'phoneSms'
                        ? Icons.sms
                        : (_selectedMethod == 'phoneWhatsapp'
                              ? Icons.chat
                              : Icons.email),
                    keyboardType:
                        _selectedMethod == 'phoneSms' ||
                            _selectedMethod == 'phoneWhatsapp'
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Choix du mode de réception
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Email (code)', 'emailCode'),
                      _buildChip('WhatsApp', 'phoneWhatsapp'),
                      _buildChip('SMS', 'phoneSms'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentOrange.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusSm,
                      ),
                      border: Border.all(
                        color: PharmaConnectColors.accentOrange.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: PharmaConnectColors.accentOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Les comptes professionnels nécessitent une vérification de licence après activation.',
                            style: PharmaConnectTypography.micro.copyWith(
                              color: PharmaConnectColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'S\'inscrire',
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      if (_nameController.text.isEmpty ||
                          _identifierController.text.isEmpty) {
                        return;
                      }

                      // Envoyer l'OTP avec la méthode choisie
                      bool success;
                      final identifier = _identifierController.text.trim();
                      if (_selectedMethod == 'phoneSms') {
                        success = await auth.sendPhoneOtp(identifier, 'sms');
                      } else if (_selectedMethod == 'phoneWhatsapp') {
                        success = await auth.sendPhoneOtp(
                          identifier,
                          'whatsapp',
                        );
                      } else {
                        success = await auth.sendEmailOtp(identifier, false);
                      }

                      if (success && context.mounted) {
                        // On stocke les infos supplémentaires dans le provider
                        auth.setRole(_selectedRole);
                        // On passe à l'écran OTP avec l'identifiant
                        context.go(
                          '/otp',
                          extra: {
                            'identifier': identifier,
                            'method': _selectedMethod,
                          },
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur lors de l\'envoi.'),
                            backgroundColor: PharmaConnectColors.accentRed,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte ?',
                        style: PharmaConnectTypography.body2,
                      ),
                      TertiaryButton(
                        label: 'Se connecter',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String method) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedMethod == method,
      onSelected: (selected) {
        if (selected) setState(() => _selectedMethod = method);
      },
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: _selectedMethod == method
            ? PharmaConnectColors.accentCyan
            : Colors.white24,
      ),
    );
  }
}
```

## `lib/modules/auth/services/auth_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthService {
  final GoTrueClient _auth = SupabaseService().auth;

  // ==================== TÉLÉPHONE ====================

  /// Envoie un OTP par SMS ou WhatsApp sur le numéro donné.
  /// [channel] : 'sms' ou 'whatsapp'
  Future<void> sendPhoneOtp(String phone, {String channel = 'sms'}) async {
    await _auth.signInWithOtp(
      phone: phone,
      channel: channel == 'whatsapp' ? OtpChannel.whatsapp : OtpChannel.sms,
    );
  }

  /// Vérifie le code OTP reçu par SMS/WhatsApp.
  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return _auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ==================== EMAIL ====================

  /// Envoie un Magic Link par email (redirection automatique).
  Future<void> sendMagicLink(String email, {String? redirectUrl}) async {
    await _auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl ?? 'https://app.gsg.com/callback',
    );
  }

  /// Envoie un code OTP par email (template avec {{ .Token }}).
  Future<void> sendEmailOtp(String email) async {
    await _auth.signInWithOtp(email: email);
  }

  /// Vérifie le code OTP reçu par email.
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    return _auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }
}
```

## `lib/modules/dashboard/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/kernel/kernel_badge.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/cards/glass_card.dart';
import '../../core/widgets/navigation/sidebar_navigation.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/alert_center.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentRoute = '/dashboard';
  bool _sidebarExpanded = true;

  final List<SidebarNavigationItem> _navItems = [
    const SidebarNavigationItem(
      label: 'Tableau de bord',
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    const SidebarNavigationItem(
      label: 'Recherche',
      icon: Icons.search,
      route: '/search',
    ),
    const SidebarNavigationItem(
      label: 'Stock & Lots',
      icon: Icons.inventory,
      route: '/stock',
    ),
    const SidebarNavigationItem(
      label: 'Ordonnances',
      icon: Icons.description,
      route: '/prescriptions',
    ),
    const SidebarNavigationItem(
      label: 'Réservations',
      icon: Icons.shopping_cart,
      route: '/reservations',
    ),
    const SidebarNavigationItem(
      label: 'Livraisons',
      icon: Icons.local_shipping,
      route: '/deliveries',
    ),
    const SidebarNavigationItem(
      label: 'Paramètres',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      body: Row(
        children: [
          SidebarNavigation(
            items: _navItems,
            currentRoute: _currentRoute,
            expanded: _sidebarExpanded,
            onItemSelected: (route) {
              setState(() => _currentRoute = route);
            },
            onToggleExpand: () {
              setState(() => _sidebarExpanded = !_sidebarExpanded);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: dashboard.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tableau de bord',
                                    style: PharmaConnectTypography.heading1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bienvenue sur PharmaConnect — Infrastructure numérique du circuit pharmaceutique',
                                    style: PharmaConnectTypography.body2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const KernelBadge(),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundColor: PharmaConnectColors.accentCyan
                                  .withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                color: PharmaConnectColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ===== ACTIONS RAPIDES =====
                        QuickActionGrid(actions: dashboard.data.actions),
                        const SizedBox(height: 32),

                        // ===== INDICATEURS CLÉS (3 cartes stats) =====
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.2,
                          children: dashboard.data.stats.map((stat) {
                            return _buildStatCard(stat);
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // ===== ACTIVITÉ RÉCENTE + ALERTES (2 colonnes) =====
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: ActivityTimeline(
                                  activities: dashboard.data.activities,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: AlertCenter(
                                  alerts: dashboard.data.alerts,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(StatCardData stat) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stat.title,
                  style: PharmaConnectTypography.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  stat.value,
                  style: PharmaConnectTypography.kpiMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.change,
                  style: PharmaConnectTypography.body2.copyWith(
                    color: stat.color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## `lib/modules/dashboard/models/dashboard_data.dart`

```dart
import 'package:flutter/material.dart';

class DashboardData {
  final List<StatCardData> stats;
  final List<QuickAction> actions;
  final List<ActivityItem> activities;
  final List<AlertItem> alerts;

  const DashboardData({
    required this.stats,
    required this.actions,
    required this.activities,
    required this.alerts,
  });
}

class StatCardData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const StatCardData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });
}

class QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class AlertItem {
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;

  const AlertItem({
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

enum AlertSeverity { info, warning, danger, success }
```

## `lib/modules/dashboard/providers/dashboard_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../models/dashboard_data.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;

  DashboardData get data => _data ?? _getDefaultData();
  bool get isLoading => _isLoading;

  void fetchData() {
    _isLoading = true;
    notifyListeners();

    // Simuler un appel réseau
    Future.delayed(const Duration(milliseconds: 500), () {
      _data = _generateData();
      _isLoading = false;
      notifyListeners();
    });
  }

  DashboardData _generateData() {
    return DashboardData(
      stats: const [
        StatCardData(
          title: 'Pharmacies actives',
          value: '1,284',
          change: '+12%',
          icon: Icons.local_pharmacy,
          color: PharmaConnectColors.accentCyan,
        ),
        StatCardData(
          title: 'Disponibilité des médicaments essentiels',
          value: '94%',
          change: '+3%',
          icon: Icons.check_circle,
          color: PharmaConnectColors.accentGreen,
        ),
        StatCardData(
          title: 'Alertes de stock',
          value: '23',
          change: '⚠️ 5 critiques',
          icon: Icons.notifications_active,
          color: PharmaConnectColors.accentOrange,
        ),
      ],
      actions: const [
        QuickAction(
          label: 'Rechercher',
          icon: Icons.search,
          route: '/search',
          color: PharmaConnectColors.accentCyan,
        ),
        QuickAction(
          label: 'Ordonnance',
          icon: Icons.description,
          route: '/prescriptions',
          color: PharmaConnectColors.accentPurple,
        ),
        QuickAction(
          label: 'Réservation',
          icon: Icons.shopping_cart,
          route: '/reservations',
          color: PharmaConnectColors.accentGreen,
        ),
        QuickAction(
          label: 'Stats',
          icon: Icons.bar_chart,
          route: '/stats',
          color: PharmaConnectColors.accentOrange,
        ),
      ],
      activities: [
        ActivityItem(
          title: 'Ordonnance #1234 validée',
          subtitle: 'Par Dr. Martin',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          icon: Icons.check_circle,
          color: PharmaConnectColors.accentGreen,
        ),
        ActivityItem(
          title: 'Réservation #5678 retirée',
          subtitle: 'Patient : Jean Dupont',
          time: DateTime.now().subtract(const Duration(minutes: 20)),
          icon: Icons.shopping_cart,
          color: PharmaConnectColors.accentCyan,
        ),
        ActivityItem(
          title: 'Alerte stock faible',
          subtitle: 'Paracétamol 500mg - Rupture imminente',
          time: DateTime.now().subtract(const Duration(hours: 1)),
          icon: Icons.warning,
          color: PharmaConnectColors.accentOrange,
        ),
      ],
      alerts: [
        AlertItem(
          message: 'Rupture imminente : Paracétamol 500mg',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AlertItem(
          message: '4 lots en péremption dans 30 jours',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AlertItem(
          message: 'Aucune alerte de contrefaçon détectée',
          severity: AlertSeverity.success,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    );
  }

  DashboardData _getDefaultData() {
    return _generateData();
  }
}
```

## `lib/modules/dashboard/widgets/activity_timeline.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../models/dashboard_data.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité récente', style: PharmaConnectTypography.heading3),
        const SizedBox(height: 16),
        ...activities.map((item) => _buildTimelineItem(item)),
      ],
    );
  }

  Widget _buildTimelineItem(ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cercle icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.subtitle} • ${item.timeAgo}',
                  style: PharmaConnectTypography.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## `lib/modules/dashboard/widgets/alert_center.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/dashboard_data.dart';

class AlertCenter extends StatelessWidget {
  final List<AlertItem> alerts;

  const AlertCenter({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alertes', style: PharmaConnectTypography.heading3),
        const SizedBox(height: 16),
        ...alerts.map((alert) => _buildAlertItem(alert)),
      ],
    );
  }

  Widget _buildAlertItem(AlertItem alert) {
    final color = _getSeverityColor(alert.severity);
    final icon = _getSeverityIcon(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return PharmaConnectColors.accentCyan;
      case AlertSeverity.warning:
        return PharmaConnectColors.accentOrange;
      case AlertSeverity.danger:
        return PharmaConnectColors.accentRed;
      case AlertSeverity.success:
        return PharmaConnectColors.accentGreen;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.danger:
        return Icons.error_outline;
      case AlertSeverity.success:
        return Icons.check_circle_outline;
    }
  }
}
```

## `lib/modules/dashboard/widgets/quick_action_grid.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/dashboard_data.dart';

class QuickActionGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GlassCard(
          padding: const EdgeInsets.all(12),
          onTap: () => context.go(action.route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 32),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: PharmaConnectTypography.body2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## `lib/modules/delivery/models/delivery.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'delivery_status.dart';
import 'delivery_driver.dart';

class Delivery {
  final String id;
  final String reservationId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;
  final DeliveryDriver? driver;
  final List<String> trackingHistory;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DeliveryStatus status;
  final String? proofSignature;
  final String? proofImageUrl;
  final String? proofCode;
  final bool isColdChainRequired;
  final String? notes;
  final bool isExpress;
  final String? pickupPointId;
  final String? pickupPointName;

  Delivery({
    required this.id,
    required this.reservationId,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.driver,
    this.trackingHistory = const [],
    required this.scheduledAt,
    this.startedAt,
    this.pickedUpAt,
    this.arrivedAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.status,
    this.proofSignature,
    this.proofImageUrl,
    this.proofCode,
    this.isColdChainRequired = false,
    this.notes,
    this.isExpress = false,
    this.pickupPointId,
    this.pickupPointName,
  });

  Delivery copyWith({
    String? id,
    String? reservationId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    DeliveryDriver? driver,
    List<String>? trackingHistory,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? pickedUpAt,
    DateTime? arrivedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DeliveryStatus? status,
    String? proofSignature,
    String? proofImageUrl,
    String? proofCode,
    bool? isColdChainRequired,
    String? notes,
    bool? isExpress,
    String? pickupPointId,
    String? pickupPointName,
  }) {
    return Delivery(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driver: driver ?? this.driver,
      trackingHistory: trackingHistory ?? this.trackingHistory,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      proofSignature: proofSignature ?? this.proofSignature,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      proofCode: proofCode ?? this.proofCode,
      isColdChainRequired: isColdChainRequired ?? this.isColdChainRequired,
      notes: notes ?? this.notes,
      isExpress: isExpress ?? this.isExpress,
      pickupPointId: pickupPointId ?? this.pickupPointId,
      pickupPointName: pickupPointName ?? this.pickupPointName,
    );
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.scheduled:
        return 'Programmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.inProgress:
        return 'En cours de livraison';
      case DeliveryStatus.arrived:
        return 'Arrivé sur place';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeliveryStatus.scheduled:
        return PharmaConnectColors.accentOrange;
      case DeliveryStatus.preparing:
        return PharmaConnectColors.accentCyan;
      case DeliveryStatus.inProgress:
        return PharmaConnectColors.accentPurple;
      case DeliveryStatus.arrived:
        return PharmaConnectColors.accentGreen;
      case DeliveryStatus.delivered:
        return PharmaConnectColors.neutralMuted;
      case DeliveryStatus.cancelled:
        return PharmaConnectColors.accentRed;
    }
  }

  bool get isActive =>
      status == DeliveryStatus.inProgress || status == DeliveryStatus.preparing;
  bool get isPast =>
      status == DeliveryStatus.delivered || status == DeliveryStatus.cancelled;

  String get estimatedArrival {
    if (status == DeliveryStatus.delivered) return 'Livrée';
    if (status == DeliveryStatus.inProgress && arrivedAt != null) {
      final diff = DateTime.now().difference(arrivedAt!);
      return 'Arrivé depuis ${diff.inMinutes}m';
    }
    if (status == DeliveryStatus.arrived) {
      return 'Le livreur est sur place';
    }
    return 'En cours de préparation';
  }
}
```

## `lib/modules/delivery/models/delivery_driver.dart`

```dart
class DeliveryDriver {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final bool isAvailable;
  final double? rating;
  final int completedDeliveries;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isColdChainCertified;

  const DeliveryDriver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.isAvailable,
    this.rating,
    required this.completedDeliveries,
    this.vehicleType,
    this.vehiclePlate,
    this.currentLatitude,
    this.currentLongitude,
    this.isColdChainCertified = false,
  });

  DeliveryDriver copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAvailable,
    double? rating,
    int? completedDeliveries,
    String? vehicleType,
    String? vehiclePlate,
    double? currentLatitude,
    double? currentLongitude,
    bool? isColdChainCertified,
  }) {
    return DeliveryDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      isColdChainCertified: isColdChainCertified ?? this.isColdChainCertified,
    );
  }
}
```

## `lib/modules/delivery/models/delivery_status.dart`

```dart
enum DeliveryStatus {
  scheduled,
  preparing,
  inProgress,
  arrived,
  delivered,
  cancelled,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.scheduled:
        return 'Programmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.arrived:
        return 'Arrivé';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  String get icon {
    switch (this) {
      case DeliveryStatus.scheduled:
        return '📅';
      case DeliveryStatus.preparing:
        return '📦';
      case DeliveryStatus.inProgress:
        return '🚴';
      case DeliveryStatus.arrived:
        return '📍';
      case DeliveryStatus.delivered:
        return '✅';
      case DeliveryStatus.cancelled:
        return '❌';
    }
  }

  int get order {
    switch (this) {
      case DeliveryStatus.scheduled:
        return 0;
      case DeliveryStatus.preparing:
        return 1;
      case DeliveryStatus.inProgress:
        return 2;
      case DeliveryStatus.arrived:
        return 3;
      case DeliveryStatus.delivered:
        return 4;
      case DeliveryStatus.cancelled:
        return -1;
    }
  }
}
```

## `lib/modules/delivery/providers/delivery_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';
import '../services/delivery_service.dart';

class DeliveryProvider extends ChangeNotifier {
  final DeliveryService _service = DeliveryService();

  List<Delivery> _deliveries = [];
  Delivery? _selectedDelivery;
  List<DeliveryDriver> _availableDrivers = [];
  bool _isLoading = false;
  String? _error;

  List<Delivery> get deliveries => _deliveries;
  Delivery? get selectedDelivery => _selectedDelivery;
  List<DeliveryDriver> get availableDrivers => _availableDrivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Delivery> get activeDeliveries {
    return _deliveries.where((d) => d.isActive).toList();
  }

  List<Delivery> get pastDeliveries {
    return _deliveries.where((d) => d.isPast).toList();
  }

  // ==================== LOAD ====================

  Future<void> loadDeliveries({DeliveryStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveries = await _service.getDeliveries(status: status);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDelivery(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedDelivery = await _service.getDelivery(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableDrivers() async {
    try {
      _availableDrivers = await _service.getAvailableDrivers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // ==================== ACTIONS ====================

  Future<Delivery?> scheduleDelivery({
    required String reservationId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String deliveryAddress,
    required DateTime scheduledAt,
    bool isExpress = false,
    bool isColdChainRequired = false,
    String? pickupPointId,
    String? pickupPointName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final delivery = await _service.scheduleDelivery(
        reservationId: reservationId,
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        deliveryAddress: deliveryAddress,
        scheduledAt: scheduledAt,
        isExpress: isExpress,
        isColdChainRequired: isColdChainRequired,
        pickupPointId: pickupPointId,
        pickupPointName: pickupPointName,
      );
      _deliveries.add(delivery);
      _isLoading = false;
      notifyListeners();
      return delivery;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> assignDriver(String deliveryId, String driverId) async {
    try {
      final updated = await _service.assignDriver(deliveryId, driverId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> startDelivery(String deliveryId) async {
    try {
      final updated = await _service.startDelivery(deliveryId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> markAsArrived(String deliveryId) async {
    try {
      final updated = await _service.markAsArrived(deliveryId);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> completeDelivery({
    required String deliveryId,
    String? proofSignature,
    String? proofImageUrl,
    String? proofCode,
  }) async {
    try {
      final updated = await _service.completeDelivery(
        deliveryId: deliveryId,
        proofSignature: proofSignature,
        proofImageUrl: proofImageUrl,
        proofCode: proofCode,
      );
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> cancelDelivery(String deliveryId, {String? reason}) async {
    try {
      final updated = await _service.cancelDelivery(deliveryId, reason: reason);
      _updateDelivery(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void _updateDelivery(Delivery updated) {
    final index = _deliveries.indexWhere((d) => d.id == updated.id);
    if (index != -1) _deliveries[index] = updated;
    if (_selectedDelivery?.id == updated.id) _selectedDelivery = updated;
    notifyListeners();
  }

  void clearSelected() {
    _selectedDelivery = null;
    notifyListeners();
  }
}
```

## `lib/modules/delivery/screens/delivery_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Historique des livraisons',
      icon: Icons.history,
    );
  }
}
```

## `lib/modules/delivery/screens/delivery_schedule_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DeliveryScheduleScreen extends StatelessWidget {
  const DeliveryScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Planification des livraisons',
      icon: Icons.event_note_outlined,
    );
  }
}
```

## `lib/modules/delivery/screens/delivery_tracking_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../providers/delivery_provider.dart';
import '../widgets/delivery_status_badge.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final activeDeliveries = provider.activeDeliveries;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Suivi des livraisons',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Suivez vos livraisons en temps réel',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            // Liste des livraisons actives
            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else if (activeDeliveries.isEmpty) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune livraison en cours',
                        style: PharmaConnectTypography.heading3,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vos livraisons apparaîtront ici',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: activeDeliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = activeDeliveries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    delivery.patientName,
                                    style: PharmaConnectTypography.body1
                                        .copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DeliveryStatusBadge(status: delivery.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    delivery.deliveryAddress,
                                    style: PharmaConnectTypography.body2,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Statut de suivi
                            _buildStatusTimeline(delivery),
                            const SizedBox(height: 12),
                            if (delivery.status == DeliveryStatus.inProgress &&
                                delivery.driver != null) ...[
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: PharmaConnectColors
                                        .accentPurple
                                        .withValues(alpha: 0.2),
                                    child: const Text(
                                      '👤',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Livreur : ${delivery.driver!.name}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              PrimaryButton(
                                label: 'Voir sur la carte',
                                icon: Icons.map,
                                onPressed: () {
                                  // Simuler l'ouverture de la carte
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Carte de suivi (à intégrer avec Google Maps)',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (delivery.status == DeliveryStatus.arrived) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: PharmaConnectColors.accentGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: PharmaConnectColors.accentGreen
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: PharmaConnectColors.accentGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Le livreur est sur place !',
                                        style: TextStyle(
                                          color:
                                              PharmaConnectColors.accentGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    PrimaryButton(
                                      label: 'Confirmer réception',
                                      onPressed: () {
                                        // Simuler la confirmation
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Livraison confirmée !',
                                            ),
                                            backgroundColor:
                                                PharmaConnectColors.accentGreen,
                                          ),
                                        );
                                      },
                                      width: 150,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Delivery delivery) {
    final statuses = [
      DeliveryStatus.scheduled,
      DeliveryStatus.preparing,
      DeliveryStatus.inProgress,
      DeliveryStatus.arrived,
      DeliveryStatus.delivered,
    ];

    final currentOrder = delivery.status.order;

    return Row(
      children: statuses.map((status) {
        final isActive = status.order <= currentOrder;
        final isCurrent = status == delivery.status;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? PharmaConnectColors.accentGreen
                      : Colors.white24,
                  border: isCurrent
                      ? Border.all(
                          color: PharmaConnectColors.accentCyan,
                          width: 3,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.label.length > 8
                    ? status.label.substring(0, 6)
                    : status.label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.white70 : Colors.white24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
```

## `lib/modules/delivery/screens/driver_dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Tableau de bord livreur',
      icon: Icons.two_wheeler_outlined,
    );
  }
}
```

## `lib/modules/delivery/services/delivery_service.dart`

```dart
import 'dart:math';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/delivery_driver.dart';

class DeliveryService {
  static final List<Delivery> _deliveries = [];
  static final Random _random = Random();

  // Drivers mockés
  static final List<DeliveryDriver> _drivers = [
    const DeliveryDriver(
      id: 'drv_001',
      name: 'Amadou Diallo',
      phone: '+224 611 111 111',
      isAvailable: true,
      rating: 4.8,
      completedDeliveries: 145,
      vehicleType: 'Scooter',
      vehiclePlate: 'RC 1234',
      isColdChainCertified: true,
    ),
    const DeliveryDriver(
      id: 'drv_002',
      name: 'Mamadou Sow',
      phone: '+224 622 222 222',
      isAvailable: true,
      rating: 4.5,
      completedDeliveries: 98,
      vehicleType: 'Vélo',
      vehiclePlate: 'RC 5678',
      isColdChainCertified: false,
    ),
    const DeliveryDriver(
      id: 'drv_003',
      name: 'Fatoumata Camara',
      phone: '+224 633 333 333',
      isAvailable: false,
      rating: 4.9,
      completedDeliveries: 210,
      vehicleType: 'Moto',
      vehiclePlate: 'RC 9012',
      isColdChainCertified: true,
    ),
  ];

  // Mock des livraisons
  static final List<Delivery> _mockDeliveries = [
    _createMockDelivery(
      id: 'del_001',
      patientName: 'Jean Dupont',
      address: '123 Rue de la République, Conakry',
      status: DeliveryStatus.inProgress,
      driver: _drivers[0],
    ),
    _createMockDelivery(
      id: 'del_002',
      patientName: 'Marie Konaté',
      address: '45 Avenue de l\'Indépendance, Conakry',
      status: DeliveryStatus.scheduled,
      driver: null,
    ),
    _createMockDelivery(
      id: 'del_003',
      patientName: 'Ibrahim Camara',
      address: '78 Boulevard du 28 Septembre, Conakry',
      status: DeliveryStatus.delivered,
      driver: _drivers[1],
    ),
  ];

  static Delivery _createMockDelivery({
    required String id,
    required String patientName,
    required String address,
    required DeliveryStatus status,
    DeliveryDriver? driver,
  }) {
    final now = DateTime.now();
    return Delivery(
      id: id,
      reservationId: 'res_${_random.nextInt(1000)}',
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      patientPhone:
          '+224 6${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}',
      deliveryAddress: address,
      latitude: 9.5 + _random.nextDouble() * 0.05,
      longitude: -13.7 - _random.nextDouble() * 0.05,
      driver: driver,
      scheduledAt: now.add(Duration(hours: _random.nextInt(4) + 1)),
      status: status,
      isColdChainRequired: _random.nextBool(),
      isExpress: _random.nextBool(),
      trackingHistory: ['Livraison programmée', 'En cours de préparation'],
    );
  }

  static void _initMockData() {
    if (_deliveries.isEmpty) {
      _deliveries.addAll(_mockDeliveries);
    }
  }

  Future<List<Delivery>> getDeliveries({DeliveryStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _deliveries.where((d) => d.status == status).toList();
    }
    return _deliveries;
  }

  Future<List<Delivery>> getDeliveriesForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _deliveries.where((d) => d.patientId == patientId).toList();
  }

  Future<Delivery> getDelivery(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _deliveries.firstWhere((d) => d.id == id);
  }

  Future<List<DeliveryDriver>> getAvailableDrivers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers.where((d) => d.isAvailable).toList();
  }

  Future<DeliveryDriver?> getDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers.firstWhere((d) => d.id == id, orElse: () => _drivers[0]);
  }

  Future<Delivery> scheduleDelivery({
    required String reservationId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String deliveryAddress,
    required DateTime scheduledAt,
    bool isExpress = false,
    bool isColdChainRequired = false,
    String? pickupPointId,
    String? pickupPointName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'del_${DateTime.now().millisecondsSinceEpoch}';
    final delivery = Delivery(
      id: id,
      reservationId: reservationId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      deliveryAddress: deliveryAddress,
      scheduledAt: scheduledAt,
      status: DeliveryStatus.scheduled,
      isExpress: isExpress,
      isColdChainRequired: isColdChainRequired,
      pickupPointId: pickupPointId,
      pickupPointName: pickupPointName,
      trackingHistory: ['Livraison programmée'],
    );

    _deliveries.add(delivery);
    return delivery;
  }

  Future<Delivery> assignDriver(String deliveryId, String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final driver = _drivers.firstWhere((d) => d.id == driverId);
    final updated = _deliveries[index].copyWith(
      driver: driver,
      status: DeliveryStatus.preparing,
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> startDelivery(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.inProgress,
      startedAt: DateTime.now(),
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livraison en cours',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> markAsArrived(String deliveryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.arrived,
      arrivedAt: DateTime.now(),
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Le livreur est arrivé sur place',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> completeDelivery({
    required String deliveryId,
    String? proofSignature,
    String? proofImageUrl,
    String? proofCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.delivered,
      deliveredAt: DateTime.now(),
      proofSignature: proofSignature,
      proofImageUrl: proofImageUrl,
      proofCode: proofCode,
      trackingHistory: [
        ..._deliveries[index].trackingHistory,
        'Livraison confirmée',
      ],
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<Delivery> cancelDelivery(String deliveryId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updated = _deliveries[index].copyWith(
      status: DeliveryStatus.cancelled,
      cancelledAt: DateTime.now(),
      notes: reason,
    );
    _deliveries[index] = updated;
    return updated;
  }

  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lon,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _drivers.indexWhere((d) => d.id == driverId);
    if (index != -1) {
      _drivers[index] = _drivers[index].copyWith(
        currentLatitude: lat,
        currentLongitude: lon,
      );
    }
  }
}
```

## `lib/modules/delivery/widgets/delivery_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';
import 'delivery_status_badge.dart';

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool compact;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.patientName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DeliveryStatusBadge(status: delivery.status),
            ],
          ),
          const SizedBox(height: 8),
          // Adresse
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  delivery.deliveryAddress,
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Détails
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                delivery.isExpress ? Icons.flash_on : Icons.schedule,
                size: 14,
                color: delivery.isExpress
                    ? PharmaConnectColors.accentOrange
                    : Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                delivery.isExpress ? 'Express' : 'Standard',
                style: PharmaConnectTypography.micro,
              ),
              const SizedBox(width: 12),
              if (delivery.isColdChainRequired) ...[
                const Icon(
                  Icons.ac_unit,
                  size: 14,
                  color: PharmaConnectColors.accentCyan,
                ),
                const SizedBox(width: 4),
                Text(
                  'Chaîne du froid',
                  style: PharmaConnectTypography.micro.copyWith(
                    color: PharmaConnectColors.accentCyan,
                  ),
                ),
              ],
              const Spacer(),
              if (delivery.driver != null) ...[
                Text(
                  '👤 ${delivery.driver!.name}',
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ],
          ),
          if (!compact && delivery.status == DeliveryStatus.inProgress) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer,
                    size: 16,
                    color: PharmaConnectColors.accentPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⏱ ${delivery.estimatedArrival}',
                      style: PharmaConnectTypography.body2.copyWith(
                        color: PharmaConnectColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## `lib/modules/delivery/widgets/delivery_status_badge.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../models/delivery_status.dart';

class DeliveryStatusBadge extends StatelessWidget {
  final DeliveryStatus status;

  const DeliveryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    final label = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.scheduled:
        return PharmaConnectColors.accentOrange;
      case DeliveryStatus.preparing:
        return PharmaConnectColors.accentCyan;
      case DeliveryStatus.inProgress:
        return PharmaConnectColors.accentPurple;
      case DeliveryStatus.arrived:
        return PharmaConnectColors.accentGreen;
      case DeliveryStatus.delivered:
        return PharmaConnectColors.textSecondary;
      case DeliveryStatus.cancelled:
        return PharmaConnectColors.accentRed;
    }
  }
}
```

## `lib/modules/payments/models/installment.dart`

```dart
class Installment {
  final String id;
  final String transactionId;
  final double totalAmount;
  final int numberOfPayments;
  final double amountPerPayment;
  final DateTime startDate;
  final List<InstallmentPayment> payments;
  final InstallmentStatus status;
  final DateTime? completedAt;

  Installment({
    required this.id,
    required this.transactionId,
    required this.totalAmount,
    required this.numberOfPayments,
    required this.amountPerPayment,
    required this.startDate,
    required this.payments,
    required this.status,
    this.completedAt,
  });

  double get remainingAmount {
    final totalPaid = payments.fold(
      0.0,
      (sum, p) =>
          p.status == InstallmentPaymentStatus.paid ? sum + p.amount : sum,
    );
    return totalAmount - totalPaid;
  }

  int get paidCount =>
      payments.where((p) => p.status == InstallmentPaymentStatus.paid).length;
  int get pendingCount => payments
      .where((p) => p.status == InstallmentPaymentStatus.pending)
      .length;

  bool get isComplete => status == InstallmentStatus.completed;
  bool get isActive => status == InstallmentStatus.active;
  bool get isDelayed => status == InstallmentStatus.delayed;
}

class InstallmentPayment {
  final int number;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final InstallmentPaymentStatus status;
  final String? transactionReference;

  InstallmentPayment({
    required this.number,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    required this.status,
    this.transactionReference,
  });

  InstallmentPayment copyWith({
    int? number,
    double? amount,
    DateTime? dueDate,
    DateTime? paidAt,
    InstallmentPaymentStatus? status,
    String? transactionReference,
  }) {
    return InstallmentPayment(
      number: number ?? this.number,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
    );
  }

  String get statusLabel {
    switch (status) {
      case InstallmentPaymentStatus.pending:
        return 'En attente';
      case InstallmentPaymentStatus.paid:
        return 'Payée';
      case InstallmentPaymentStatus.late:
        return 'En retard';
      case InstallmentPaymentStatus.cancelled:
        return 'Annulée';
    }
  }
}

enum InstallmentStatus { active, completed, delayed, cancelled }

enum InstallmentPaymentStatus { pending, paid, late, cancelled }
```

## `lib/modules/payments/models/payment_method.dart`

```dart
enum PaymentMethod {
  orangeMoney,
  mtnMomo,
  moovMoney,
  bankCard,
  gsgWallet,
  cashOnDelivery,
  installment,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN MoMo';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.bankCard:
        return 'Carte bancaire';
      case PaymentMethod.gsgWallet:
        return 'Portefeuille GSG';
      case PaymentMethod.cashOnDelivery:
        return 'Paiement à la livraison';
      case PaymentMethod.installment:
        return 'Paiement en plusieurs fois';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return '🟠';
      case PaymentMethod.mtnMomo:
        return '🟡';
      case PaymentMethod.moovMoney:
        return '🔵';
      case PaymentMethod.bankCard:
        return '💳';
      case PaymentMethod.gsgWallet:
        return '⚡';
      case PaymentMethod.cashOnDelivery:
        return '💰';
      case PaymentMethod.installment:
        return '📆';
    }
  }

  bool get isMobileMoney {
    switch (this) {
      case PaymentMethod.orangeMoney:
      case PaymentMethod.mtnMomo:
      case PaymentMethod.moovMoney:
        return true;
      default:
        return false;
    }
  }

  bool get isWallet => this == PaymentMethod.gsgWallet;
  bool get isCard => this == PaymentMethod.bankCard;
  bool get isInstallment => this == PaymentMethod.installment;
}
```

## `lib/modules/payments/models/transaction.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'transaction_status.dart';
import 'payment_method.dart';

class Transaction {
  final String id;
  final String? reservationId;
  final String? deliveryId;
  final String? prescriptionId;
  final String userId;
  final String userPhone;
  final String? pharmacyId;
  final String? pharmacyName;
  final double amount;
  final double? fee;
  final double? cashback;
  final double finalAmount;
  final PaymentMethod method;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? transactionReference;
  final String? externalReference;
  final String? qrCodeToken;
  final Map<String, dynamic>? metadata;
  final String? notes;

  Transaction({
    required this.id,
    this.reservationId,
    this.deliveryId,
    this.prescriptionId,
    required this.userId,
    required this.userPhone,
    this.pharmacyId,
    this.pharmacyName,
    required this.amount,
    this.fee,
    this.cashback,
    required this.finalAmount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.refundedAt,
    this.transactionReference,
    this.externalReference,
    this.qrCodeToken,
    this.metadata,
    this.notes,
  });

  Transaction copyWith({
    String? id,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? userId,
    String? userPhone,
    String? pharmacyId,
    String? pharmacyName,
    double? amount,
    double? fee,
    double? cashback,
    double? finalAmount,
    PaymentMethod? method,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? transactionReference,
    String? externalReference,
    String? qrCodeToken,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      deliveryId: deliveryId ?? this.deliveryId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      userId: userId ?? this.userId,
      userPhone: userPhone ?? this.userPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      cashback: cashback ?? this.cashback,
      finalAmount: finalAmount ?? this.finalAmount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      transactionReference: transactionReference ?? this.transactionReference,
      externalReference: externalReference ?? this.externalReference,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isRefunded => status == TransactionStatus.refunded;
  bool get isDisputed => status == TransactionStatus.disputed;

  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.processing:
        return 'En cours';
      case TransactionStatus.completed:
        return 'Réussi';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.refunded:
        return 'Remboursé';
      case TransactionStatus.disputed:
        return 'Litige';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return PharmaConnectColors.accentOrange;
      case TransactionStatus.processing:
        return PharmaConnectColors.accentCyan;
      case TransactionStatus.completed:
        return PharmaConnectColors.accentGreen;
      case TransactionStatus.failed:
        return PharmaConnectColors.accentRed;
      case TransactionStatus.refunded:
        return PharmaConnectColors.neutralMuted;
      case TransactionStatus.disputed:
        return PharmaConnectColors.accentAmber;
    }
  }
}
```

## `lib/modules/payments/models/transaction_status.dart`

```dart
enum TransactionStatus { pending, processing, completed, failed, refunded, disputed }
```

## `lib/modules/payments/providers/payment_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  List<Transaction> _transactions = [];
  Transaction? _selectedTransaction;
  Installment? _currentInstallment;
  double _walletBalance = 0;
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  Transaction? get selectedTransaction => _selectedTransaction;
  Installment? get currentInstallment => _currentInstallment;
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== LOAD ====================

  Future<void> loadTransactions({TransactionStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = await _service.getTransactions(status: status);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransaction(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedTransaction = await _service.getTransaction(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWalletBalance(String userId) async {
    try {
      _walletBalance = await _service.getWalletBalance(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadInstallment(String installmentId) async {
    try {
      _currentInstallment = await _service.getInstallment(installmentId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // ==================== PAIEMENT ====================

  Future<Transaction?> initiatePayment({
    required String userId,
    required String userPhone,
    required double amount,
    required PaymentMethod method,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? pharmacyId,
    String? pharmacyName,
    bool useCashback = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final transaction = await _service.initiateTransaction(
        userId: userId,
        userPhone: userPhone,
        amount: amount,
        method: method,
        reservationId: reservationId,
        deliveryId: deliveryId,
        prescriptionId: prescriptionId,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        useCashback: useCashback,
      );
      _transactions.add(transaction);
      _isLoading = false;
      notifyListeners();
      return transaction;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmPayment(String transactionId) async {
    try {
      final updated = await _service.confirmTransaction(transactionId);
      _updateTransaction(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> refundPayment(String transactionId, {String? reason}) async {
    try {
      final updated = await _service.refundTransaction(
        transactionId,
        reason: reason,
      );
      _updateTransaction(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ==================== ÉCHÉANCIER ====================

  Future<Installment?> createInstallment({
    required String transactionId,
    required double totalAmount,
    required int numberOfPayments,
    required DateTime startDate,
  }) async {
    try {
      final installment = await _service.createInstallment(
        transactionId: transactionId,
        totalAmount: totalAmount,
        numberOfPayments: numberOfPayments,
        startDate: startDate,
      );
      _currentInstallment = installment;
      notifyListeners();
      return installment;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // ==================== UTILITAIRES ====================

  void _updateTransaction(Transaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) _transactions[index] = updated;
    if (_selectedTransaction?.id == updated.id) _selectedTransaction = updated;
    notifyListeners();
  }

  void clearSelected() {
    _selectedTransaction = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

## `lib/modules/payments/screens/dispute_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class DisputeScreen extends StatelessWidget {
  const DisputeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Litiges de paiement',
      icon: Icons.gavel_outlined,
    );
  }
}
```

## `lib/modules/payments/screens/installment_plan_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class InstallmentPlanScreen extends StatelessWidget {
  final String transactionId;

  const InstallmentPlanScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Plan d'échelonnement",
      icon: Icons.calendar_month_outlined,
    );
  }
}
```

## `lib/modules/payments/screens/payment_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_method_selector.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String? reservationId;
  final String? deliveryId;
  final String? pharmacyName;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.reservationId,
    this.deliveryId,
    this.pharmacyName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.orangeMoney;
  bool _useCashback = true;
  bool _isProcessing = false;

  final List<PaymentMethod> _availableMethods = [
    PaymentMethod.orangeMoney,
    PaymentMethod.mtnMomo,
    PaymentMethod.moovMoney,
    PaymentMethod.gsgWallet,
    PaymentMethod.bankCard,
    PaymentMethod.cashOnDelivery,
    PaymentMethod.installment,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final cashbackAmount = widget.amount * 0.02;
    final finalAmount = _useCashback
        ? widget.amount - cashbackAmount
        : widget.amount;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Paiement',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé de la commande',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (widget.pharmacyName != null) ...[
                            Text('Pharmacie : ${widget.pharmacyName}'),
                          ],
                          if (widget.reservationId != null) ...[
                            Text('Réservation : #${widget.reservationId}'),
                          ],
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: PharmaConnectTypography.body1,
                              ),
                              Text(
                                CurrencyFormatter.format(widget.amount),
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_useCashback && cashbackAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cashback (2%)',
                                  style: PharmaConnectTypography.body2.copyWith(
                                    color: PharmaConnectColors.accentGreen,
                                  ),
                                ),
                                Text(
                                  '- ${CurrencyFormatter.format(cashbackAmount)}',
                                  style: PharmaConnectTypography.body2.copyWith(
                                    color: PharmaConnectColors.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'À payer',
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(finalAmount),
                                style: PharmaConnectTypography.body1.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: PharmaConnectColors.accentCyan,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Choix du moyen de paiement
                    PaymentMethodSelector(
                      availableMethods: _availableMethods,
                      selectedMethod: _selectedMethod,
                      onMethodSelected: (method) {
                        setState(() => _selectedMethod = method);
                      },
                      showCashback: true,
                    ),
                    const SizedBox(height: 8),

                    // Option cashback
                    if (_selectedMethod.isMobileMoney ||
                        _selectedMethod == PaymentMethod.gsgWallet) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _useCashback,
                            onChanged: (value) {
                              setState(() => _useCashback = value ?? true);
                            },
                            activeColor: PharmaConnectColors.accentCyan,
                          ),
                          Expanded(
                            child: Text(
                              'Utiliser mon cashback (${CurrencyFormatter.format(cashbackAmount)})',
                              style: PharmaConnectTypography.body2,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton de paiement
                    PrimaryButton(
                      label: _selectedMethod == PaymentMethod.installment
                          ? 'Payer en plusieurs fois'
                          : 'Payer ${CurrencyFormatter.format(finalAmount)}',
                      isLoading: _isProcessing || provider.isLoading,
                      onPressed: () async {
                        setState(() => _isProcessing = true);

                        final transaction = await provider.initiatePayment(
                          userId: 'patient_123', // À récupérer de l'auth
                          userPhone: '+224 612 345 678',
                          amount: finalAmount,
                          method: _selectedMethod,
                          reservationId: widget.reservationId,
                          deliveryId: widget.deliveryId,
                          pharmacyName: widget.pharmacyName,
                          useCashback: _useCashback,
                        );

                        setState(() => _isProcessing = false);

                        if (transaction != null && context.mounted) {
                          if (_selectedMethod == PaymentMethod.installment) {
                            context.go(
                              '/payments/installment/${transaction.id}',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Paiement effectué avec succès !',
                                ),
                                backgroundColor:
                                    PharmaConnectColors.accentGreen,
                              ),
                            );
                            context.go('/reservations/confirmation');
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Sécurisé par GSG Kernel',
                        style: PharmaConnectTypography.micro.copyWith(
                          color: PharmaConnectColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/modules/payments/screens/reconciliation_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReconciliationScreen extends StatelessWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Réconciliation pharmacie',
      icon: Icons.fact_check_outlined,
    );
  }
}
```

## `lib/modules/payments/screens/transaction_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Historique des transactions',
      icon: Icons.receipt_long_outlined,
    );
  }
}
```

## `lib/modules/payments/screens/wallet_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Portefeuille GSG',
      icon: Icons.account_balance_wallet_outlined,
    );
  }
}
```

## `lib/modules/payments/services/payment_service.dart`

```dart
import 'dart:math';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/payment_method.dart';
import '../models/installment.dart';

class PaymentService {
  static final List<Transaction> _transactions = [];
  static final Random _random = Random();

  // Mock des transactions
  static final List<Transaction> _mockTransactions = [
    _createMockTransaction(
      id: 'tx_001',
      amount: 15000,
      method: PaymentMethod.orangeMoney,
      status: TransactionStatus.completed,
      pharmacyName: 'Pharmacie Centrale',
    ),
    _createMockTransaction(
      id: 'tx_002',
      amount: 8500,
      method: PaymentMethod.gsgWallet,
      status: TransactionStatus.completed,
      pharmacyName: 'Pharmacie du Soleil',
    ),
    _createMockTransaction(
      id: 'tx_003',
      amount: 35000,
      method: PaymentMethod.mtnMomo,
      status: TransactionStatus.pending,
      pharmacyName: 'Pharmacie Moderne',
    ),
  ];

  static Transaction _createMockTransaction({
    required String id,
    required double amount,
    required PaymentMethod method,
    required TransactionStatus status,
    required String pharmacyName,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: id,
      userId: 'patient_${_random.nextInt(100)}',
      userPhone:
          '+224 6${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}',
      pharmacyName: pharmacyName,
      amount: amount,
      fee: amount * 0.01,
      cashback: status == TransactionStatus.completed ? amount * 0.02 : 0,
      finalAmount:
          amount +
          (amount * 0.01) -
          (status == TransactionStatus.completed ? amount * 0.02 : 0),
      method: method,
      status: status,
      createdAt: now.subtract(Duration(hours: _random.nextInt(48))),
      completedAt: status == TransactionStatus.completed
          ? now.subtract(Duration(hours: _random.nextInt(12)))
          : null,
      transactionReference: 'GSG${_random.nextInt(1000000)}',
    );
  }

  static void _initMockData() {
    if (_transactions.isEmpty) {
      _transactions.addAll(_mockTransactions);
    }
  }

  Future<List<Transaction>> getTransactions({TransactionStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _transactions.where((t) => t.status == status).toList();
    }
    return _transactions;
  }

  Future<Transaction> getTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _transactions.firstWhere((t) => t.id == id);
  }

  Future<List<Transaction>> getTransactionsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _transactions.where((t) => t.userId == userId).toList();
  }

  Future<double> getWalletBalance(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simuler un solde de portefeuille
    return (15000 + _random.nextInt(50000)).toDouble();
  }

  Future<Transaction> initiateTransaction({
    required String userId,
    required String userPhone,
    required double amount,
    required PaymentMethod method,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? pharmacyId,
    String? pharmacyName,
    bool useCashback = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'tx_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final fee = method == PaymentMethod.gsgWallet ? 0.0 : amount * 0.01;
    final cashback = (method.isMobileMoney || method == PaymentMethod.gsgWallet)
        ? amount * 0.02
        : 0.0;
    final finalAmount = amount + fee - (useCashback ? cashback : 0);

    final transaction = Transaction(
      id: id,
      userId: userId,
      userPhone: userPhone,
      amount: amount,
      fee: fee,
      cashback: useCashback ? cashback : 0,
      finalAmount: finalAmount,
      method: method,
      status: TransactionStatus.processing,
      createdAt: now,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      reservationId: reservationId,
      deliveryId: deliveryId,
      prescriptionId: prescriptionId,
      transactionReference: 'GSG${_random.nextInt(1000000)}',
    );

    _transactions.add(transaction);

    // Simuler la confirmation
    await Future.delayed(const Duration(seconds: 1));
    final completed = transaction.copyWith(
      status: TransactionStatus.completed,
      completedAt: DateTime.now(),
    );
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) _transactions[index] = completed;

    return completed;
  }

  Future<Transaction> confirmTransaction(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final updated = _transactions[index].copyWith(
      status: TransactionStatus.completed,
      completedAt: DateTime.now(),
    );
    _transactions[index] = updated;
    return updated;
  }

  Future<Transaction> refundTransaction(
    String transactionId, {
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction not found');

    final updated = _transactions[index].copyWith(
      status: TransactionStatus.refunded,
      refundedAt: DateTime.now(),
      notes: reason,
    );
    _transactions[index] = updated;
    return updated;
  }

  Future<Installment> createInstallment({
    required String transactionId,
    required double totalAmount,
    required int numberOfPayments,
    required DateTime startDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final amountPerPayment = totalAmount / numberOfPayments;
    final payments = <InstallmentPayment>[];

    for (int i = 0; i < numberOfPayments; i++) {
      final dueDate = startDate.add(Duration(days: (i + 1) * 30));
      payments.add(
        InstallmentPayment(
          number: i + 1,
          amount: amountPerPayment,
          dueDate: dueDate,
          status: InstallmentPaymentStatus.pending,
        ),
      );
    }

    return Installment(
      id: 'inst_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionId,
      totalAmount: totalAmount,
      numberOfPayments: numberOfPayments,
      amountPerPayment: amountPerPayment,
      startDate: startDate,
      payments: payments,
      status: InstallmentStatus.active,
    );
  }

  Future<Installment> getInstallment(String installmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simuler la récupération d'un échéancier
    final now = DateTime.now();
    final payments = List.generate(
      3,
      (i) => InstallmentPayment(
        number: i + 1,
        amount: 15000,
        dueDate: now.add(Duration(days: (i + 1) * 30)),
        status: i == 0
            ? InstallmentPaymentStatus.paid
            : InstallmentPaymentStatus.pending,
      ),
    );
    return Installment(
      id: installmentId,
      transactionId: 'tx_${_random.nextInt(1000)}',
      totalAmount: 45000,
      numberOfPayments: 3,
      amountPerPayment: 15000,
      startDate: now.subtract(const Duration(days: 30)),
      payments: payments,
      status: InstallmentStatus.active,
    );
  }
}
```

## `lib/modules/payments/widgets/payment_method_selector.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/payment_method.dart';

class PaymentMethodSelector extends StatefulWidget {
  final List<PaymentMethod> availableMethods;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final bool showCashback;

  const PaymentMethodSelector({
    super.key,
    required this.availableMethods,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showCashback = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Moyen de paiement', style: PharmaConnectTypography.label),
        const SizedBox(height: 8),
        ...widget.availableMethods.map((method) {
          final isSelected = widget.selectedMethod == method;
          final cashback =
              method.isMobileMoney || method == PaymentMethod.gsgWallet;

          return GestureDetector(
            onTap: () => widget.onMethodSelected(method),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? PharmaConnectColors.accentCyan.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(
                  PharmaConnectSpacing.radiusMd,
                ),
                border: Border.all(
                  color: isSelected
                      ? PharmaConnectColors.accentCyan
                      : Colors.white.withValues(alpha: 0.06),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(method.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.label,
                      style: PharmaConnectTypography.body1.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.showCashback && cashback) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PharmaConnectColors.accentGreen.withValues(alpha: 
                          0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '2% cashback',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PharmaConnectColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
```

## `lib/modules/payments/widgets/wallet_balance_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/cards/glass_card.dart';

class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final String? userName;
  final VoidCallback? onTopUp;
  final VoidCallback? onHistory;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.userName,
    this.onTopUp,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: true,
      glowColor: PharmaConnectColors.accentPurple,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: PharmaConnectColors.accentPurple,
              ),
              const SizedBox(width: 8),
              const Text(
                'Portefeuille GSG',
                style: PharmaConnectTypography.heading3,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: PharmaConnectColors.accentPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '⚡ Kernel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: PharmaConnectColors.accentPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: PharmaConnectTypography.kpiLarge.copyWith(
              color: PharmaConnectColors.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          if (userName != null) ...[
            Text('Bienvenue, $userName', style: PharmaConnectTypography.body2),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTopUp,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: PharmaConnectColors.accentPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text('Approvisionner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentPurple,
                    foregroundColor: PharmaConnectColors.textPrimary,
                  ),
                  child: const Text('Historique'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## `lib/modules/prescriptions/models/prescription.dart`

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'prescription_item.dart';
import 'prescription_status.dart';

class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorName;
  final String? doctorLicense;
  final DateTime uploadedAt;
  final DateTime? validatedAt;
  final DateTime? dispensedAt;
  final PrescriptionStatus status;
  final String imageUrl;
  final Map<String, dynamic>? ocrData;
  final String? notes;
  final List<PrescriptionItem> items;
  final double? ocrConfidenceScore;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorName,
    this.doctorLicense,
    required this.uploadedAt,
    this.validatedAt,
    this.dispensedAt,
    required this.status,
    required this.imageUrl,
    this.ocrData,
    this.notes,
    required this.items,
    this.ocrConfidenceScore,
  });

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorName,
    String? doctorLicense,
    DateTime? uploadedAt,
    DateTime? validatedAt,
    DateTime? dispensedAt,
    PrescriptionStatus? status,
    String? imageUrl,
    Map<String, dynamic>? ocrData,
    String? notes,
    List<PrescriptionItem>? items,
    double? ocrConfidenceScore,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorLicense: doctorLicense ?? this.doctorLicense,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      dispensedAt: dispensedAt ?? this.dispensedAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrData: ocrData ?? this.ocrData,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      ocrConfidenceScore: ocrConfidenceScore ?? this.ocrConfidenceScore,
    );
  }

  bool get isPending => status == PrescriptionStatus.pending;
  bool get isValidated => status == PrescriptionStatus.validated;
  bool get isDispensed => status == PrescriptionStatus.dispensed;
  bool get isArchived => status == PrescriptionStatus.archived;
  bool get isDraft => status == PrescriptionStatus.draft;

  String get statusLabel {
    switch (status) {
      case PrescriptionStatus.draft:
        return 'Brouillon';
      case PrescriptionStatus.pending:
        return 'En attente';
      case PrescriptionStatus.validated:
        return 'Validée';
      case PrescriptionStatus.dispensed:
        return 'Dispensée';
      case PrescriptionStatus.archived:
        return 'Archivée';
    }
  }

  Color get statusColor {
    switch (status) {
      case PrescriptionStatus.draft:
        return PharmaConnectColors.textSecondary;
      case PrescriptionStatus.pending:
        return PharmaConnectColors.accentOrange;
      case PrescriptionStatus.validated:
        return PharmaConnectColors.accentGreen;
      case PrescriptionStatus.dispensed:
        return PharmaConnectColors.accentCyan;
      case PrescriptionStatus.archived:
        return PharmaConnectColors.neutralMuted;
    }
  }
}
```

## `lib/modules/prescriptions/models/prescription_item.dart`

```dart
class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final String? instructions;
  final bool isSubstitutionAllowed;
  final String? suggestedGenericId;
  final bool isExtractedByOcr;
  final double ocrConfidence;

  PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.instructions,
    this.isSubstitutionAllowed = false,
    this.suggestedGenericId,
    this.isExtractedByOcr = false,
    this.ocrConfidence = 0.0,
  });

  PrescriptionItem copyWith({
    String? id,
    String? prescriptionId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    int? quantity,
    String? instructions,
    bool? isSubstitutionAllowed,
    String? suggestedGenericId,
    bool? isExtractedByOcr,
    double? ocrConfidence,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      quantity: quantity ?? this.quantity,
      instructions: instructions ?? this.instructions,
      isSubstitutionAllowed:
          isSubstitutionAllowed ?? this.isSubstitutionAllowed,
      suggestedGenericId: suggestedGenericId ?? this.suggestedGenericId,
      isExtractedByOcr: isExtractedByOcr ?? this.isExtractedByOcr,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
    );
  }

  String get displayName {
    if (isExtractedByOcr) {
      return '$medicationName (OCR)';
    }
    return medicationName;
  }

  bool get hasGenericAlternative => suggestedGenericId != null;
}
```

## `lib/modules/prescriptions/models/prescription_status.dart`

```dart
enum PrescriptionStatus { draft, pending, validated, dispensed, archived }

extension PrescriptionStatusExtension on PrescriptionStatus {
  String get label {
    switch (this) {
      case PrescriptionStatus.draft:
        return 'Brouillon';
      case PrescriptionStatus.pending:
        return 'En attente';
      case PrescriptionStatus.validated:
        return 'Validée';
      case PrescriptionStatus.dispensed:
        return 'Dispensée';
      case PrescriptionStatus.archived:
        return 'Archivée';
    }
  }

  String get icon {
    switch (this) {
      case PrescriptionStatus.draft:
        return '📄';
      case PrescriptionStatus.pending:
        return '⏳';
      case PrescriptionStatus.validated:
        return '✅';
      case PrescriptionStatus.dispensed:
        return '💊';
      case PrescriptionStatus.archived:
        return '📁';
    }
  }
}
```

## `lib/modules/prescriptions/providers/prescription_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';
import '../services/prescription_service.dart';
import '../services/ocr_service.dart';

enum PrescriptionUploadStatus { idle, uploading, processing, ready, error }

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionService _service = PrescriptionService();
  final OcrService _ocrService = OcrService();

  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  PrescriptionUploadStatus _uploadStatus = PrescriptionUploadStatus.idle;
  String? _uploadError;
  List<PrescriptionItem> _extractedItems = [];
  double _ocrConfidenceScore = 0.0;
  bool _isProcessingOcr = false;
  Map<String, bool> _availabilityMap = {};

  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;
  PrescriptionUploadStatus get uploadStatus => _uploadStatus;
  String? get uploadError => _uploadError;
  List<PrescriptionItem> get extractedItems => _extractedItems;
  double get ocrConfidenceScore => _ocrConfidenceScore;
  bool get isProcessingOcr => _isProcessingOcr;
  Map<String, bool> get availabilityMap => _availabilityMap;

  List<Prescription> get pendingPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.pending)
      .toList();

  List<Prescription> get validatedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.validated)
      .toList();

  List<Prescription> get dispensedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.dispensed)
      .toList();

  // ==================== CHARGEMENT ====================

  Future<void> loadPrescriptions({PrescriptionStatus? status}) async {
    try {
      _prescriptions = await _service.getPrescriptions(status: status);
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> loadPrescription(String id) async {
    try {
      _selectedPrescription = await _service.getPrescription(id);
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  // ==================== UPLOAD & OCR ====================

  Future<void> uploadPrescription(
    String imagePath,
    String patientId,
    String patientName,
  ) async {
    _uploadStatus = PrescriptionUploadStatus.uploading;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    notifyListeners();

    try {
      // Simuler l'upload
      await Future.delayed(const Duration(seconds: 1));

      // Extraire par OCR
      _uploadStatus = PrescriptionUploadStatus.processing;
      _isProcessingOcr = true;
      notifyListeners();

      final ocrResult = await _ocrService.extractFromImage(imagePath);
      _extractedItems = ocrResult['items'] as List<PrescriptionItem>;
      _ocrConfidenceScore = ocrResult['confidenceScore'] as double;
      _isProcessingOcr = false;

      // Créer l'ordonnance
      final prescription = await _service.createPrescription(
        patientId: patientId,
        patientName: patientName,
        imageUrl: imagePath,
        items: _extractedItems,
        ocrConfidenceScore: _ocrConfidenceScore,
      );

      _selectedPrescription = prescription;
      _prescriptions.add(prescription);
      _uploadStatus = PrescriptionUploadStatus.ready;

      // Vérifier la disponibilité des produits
      await _checkAvailability(_extractedItems);

      notifyListeners();
    } catch (e) {
      _uploadStatus = PrescriptionUploadStatus.error;
      _uploadError = 'Erreur lors de l\'upload: $e';
      _isProcessingOcr = false;
      notifyListeners();
    }
  }

  // ==================== VALIDATION ====================

  Future<void> validatePrescription(String id, {String? notes}) async {
    try {
      final updated = await _service.validatePrescription(id, notes: notes);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> dispensePrescription(String id) async {
    try {
      final updated = await _service.dispensePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> archivePrescription(String id) async {
    try {
      await _service.archivePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = _prescriptions[index].copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      if (_selectedPrescription?.id == id) {
        _selectedPrescription = _selectedPrescription!.copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  // ==================== CORRECTION ====================

  Future<List<String>> suggestCorrection(String wrongName) async {
    return await _ocrService.suggestCorrection(wrongName);
  }

  void updateExtractedItem(int index, PrescriptionItem newItem) {
    if (index < _extractedItems.length) {
      _extractedItems[index] = newItem;
      notifyListeners();
    }
  }

  void updateExtractedItems(List<PrescriptionItem> newItems) {
    _extractedItems = newItems;
    notifyListeners();
  }

  // ==================== AVAILABILITY ====================

  Future<void> _checkAvailability(List<PrescriptionItem> items) async {
    _availabilityMap = {};
    for (final item in items) {
      // Simuler une vérification de disponibilité
      // En production, appeler le SearchService
      final isAvailable = DateTime.now().millisecondsSinceEpoch % 3 != 0;
      _availabilityMap[item.medicationName] = isAvailable;
    }
    notifyListeners();
  }

  // ==================== RECHERCHE ====================

  Future<void> searchPrescriptions(String query) async {
    try {
      _prescriptions = await _service.searchPrescriptions(query);
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  // ==================== NETTOYAGE ====================

  void clearSelected() {
    _selectedPrescription = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    notifyListeners();
  }

  void resetUpload() {
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _isProcessingOcr = false;
    notifyListeners();
  }
}
```

## `lib/modules/prescriptions/screens/prescription_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_item_tile.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().loadPrescription(
        widget.prescriptionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final prescription = provider.selectedPrescription;

    if (prescription == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Détail de l\'ordonnance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de l'ordonnance
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: prescription.statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ordonnance #${prescription.id}',
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: prescription.statusColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            prescription.statusLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: prescription.statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(prescription.uploadedAt),
                                          style: PharmaConnectTypography.micro,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Patient',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      prescription.patientName,
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Médecin',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      prescription.doctorName ??
                                          'Non renseigné',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (prescription.ocrConfidenceScore != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Confiance OCR : ',
                                  style: PharmaConnectTypography.label,
                                ),
                                Text(
                                  '${(prescription.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        prescription.ocrConfidenceScore! > 0.8
                                        ? PharmaConnectColors.accentGreen
                                        : PharmaConnectColors.accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (prescription.notes != null) ...[
                            const SizedBox(height: 8),
                            Text('Notes : ${prescription.notes!}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Médicaments
                    Text(
                      'Médicaments (${prescription.items.length})',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    ...prescription.items.map((item) {
                      return PrescriptionItemTile(
                        item: item,
                        isExtracted: item.isExtractedByOcr,
                      );
                    }),
                    const SizedBox(height: 24),

                    // Actions (selon statut)
                    if (prescription.isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Valider l\'ordonnance',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                await provider.validatePrescription(
                                  prescription.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ordonnance validée avec succès',
                                      ),
                                      backgroundColor:
                                          PharmaConnectColors.accentGreen,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Dispenser',
                              icon: Icons.medication,
                              onPressed: prescription.isValidated
                                  ? () async {
                                      await provider.dispensePrescription(
                                        prescription.id,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ordonnance dispensée',
                                            ),
                                            backgroundColor:
                                                PharmaConnectColors.accentCyan,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TertiaryButton(
                        label: 'Archiver',
                        onPressed: () async {
                          await provider.archivePrescription(prescription.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordonnance archivée'),
                                backgroundColor:
                                    PharmaConnectColors.textSecondary,
                              ),
                            );
                            context.pop();
                          }
                        },
                      ),
                    ],

                    if (prescription.isValidated) ...[
                      PrimaryButton(
                        label: 'Dispenser',
                        icon: Icons.medication,
                        onPressed: () async {
                          await provider.dispensePrescription(prescription.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordonnance dispensée'),
                                backgroundColor: PharmaConnectColors.accentCyan,
                              ),
                            );
                          }
                        },
                      ),
                    ],

                    if (prescription.isDispensed) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentGreen.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PharmaConnectColors.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: PharmaConnectColors.accentGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordonnance dispensée le ${_formatDateFull(prescription.dispensedAt!)}',
                                style: PharmaConnectTypography.body1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }

  String _formatDateFull(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
```

## `lib/modules/prescriptions/screens/prescription_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/prescription_status.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_card.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PrescriptionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().loadPrescriptions();
    });
  }

  void _onTabChanged() {
    final index = _tabController.index;
    setState(() {
      switch (index) {
        case 0:
          _selectedStatus = null;
          break;
        case 1:
          _selectedStatus = PrescriptionStatus.pending;
          break;
        case 2:
          _selectedStatus = PrescriptionStatus.validated;
          break;
        case 3:
          _selectedStatus = PrescriptionStatus.dispensed;
          break;
      }
    });
    context.read<PrescriptionProvider>().loadPrescriptions(
      status: _selectedStatus,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordonnances',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos ordonnances numériques',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/prescriptions/upload'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filtres par onglet
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
                Tab(text: 'Validées'),
                Tab(text: 'Dispensées'),
              ],
              labelColor: PharmaConnectColors.accentCyan,
              unselectedLabelColor: PharmaConnectColors.textSecondary,
              indicatorColor: PharmaConnectColors.accentCyan,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: 24),

            // Liste des ordonnances
            Expanded(
              child: provider.prescriptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune ordonnance',
                            style: PharmaConnectTypography.heading2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Importez votre première ordonnance numérique',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.prescriptions.length,
                      itemBuilder: (context, index) {
                        final prescription = provider.prescriptions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PrescriptionCard(
                            prescription: prescription,
                            onTap: () {
                              context.push('/prescriptions/${prescription.id}');
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/modules/prescriptions/screens/prescription_preview_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../models/prescription_item.dart';
import '../providers/prescription_provider.dart';
import '../widgets/prescription_item_tile.dart';
import '../widgets/ocr_confidence_indicator.dart';

class PrescriptionPreviewScreen extends StatefulWidget {
  const PrescriptionPreviewScreen({super.key});

  @override
  State<PrescriptionPreviewScreen> createState() =>
      _PrescriptionPreviewScreenState();
}

class _PrescriptionPreviewScreenState extends State<PrescriptionPreviewScreen> {
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final items = provider.extractedItems;
    final confidence = provider.ocrConfidenceScore;
    final availabilityMap = provider.availabilityMap;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () {
                    provider.resetUpload();
                    context.pop();
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vérification de l\'ordonnance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score de confiance OCR
                    Center(
                      child: OcrConfidenceIndicator(confidence: confidence),
                    ),
                    const SizedBox(height: 24),

                    // Liste des médicaments extraits
                    const Text(
                      'Médicaments détectés',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty) ...[
                      const Text(
                        'Aucun médicament détecté',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return PrescriptionItemTile(
                          item: item,
                          isExtracted: true,
                          showActions: true,
                          onEdit: () => _showEditDialog(context, index, item),
                          onSubstitute: item.hasGenericAlternative
                              ? () => _showSubstitutionDialog(
                                  context,
                                  index,
                                  item,
                                )
                              : null,
                        );
                      }),
                    ],
                    const SizedBox(height: 16),

                    // Disponibilité des produits
                    if (availabilityMap.isNotEmpty) ...[
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      const Text(
                        'Disponibilité en pharmacie',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...availabilityMap.entries.map((entry) {
                        final isAvailable = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: isAvailable
                                    ? PharmaConnectColors.accentGreen
                                    : PharmaConnectColors.accentRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: PharmaConnectTypography.body1,
                                ),
                              ),
                              Text(
                                isAvailable ? 'Disponible' : 'Rupture',
                                style: PharmaConnectTypography.body2.copyWith(
                                  color: isAvailable
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentRed,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TertiaryButton(
                            label: 'Retour',
                            onPressed: () {
                              provider.resetUpload();
                              context.pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: _isValidating
                                ? 'Validation en cours...'
                                : 'Valider l\'ordonnance',
                            isLoading: _isValidating,
                            onPressed: items.isEmpty
                                ? null
                                : () async {
                                    setState(() => _isValidating = true);
                                    final prescription =
                                        provider.selectedPrescription;
                                    if (prescription != null) {
                                      await provider.validatePrescription(
                                        prescription.id,
                                      );
                                      if (context.mounted) {
                                        context.go(
                                          '/prescriptions/${prescription.id}',
                                        );
                                      }
                                    }
                                    setState(() => _isValidating = false);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index, PrescriptionItem item) {
    final controller = TextEditingController(text: item.medicationName);
    final dosageController = TextEditingController(text: item.dosage);
    final freqController = TextEditingController(text: item.frequency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Modifier le médicament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom du médicament',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: freqController,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = item.copyWith(
                medicationName: controller.text,
                dosage: dosageController.text,
                frequency: freqController.text,
              );
              context.read<PrescriptionProvider>().updateExtractedItem(
                index,
                newItem,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaConnectColors.accentCyan,
              foregroundColor: PharmaConnectColors.textOnAccent,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showSubstitutionDialog(
    BuildContext context,
    int index,
    PrescriptionItem item,
  ) {
    // Simuler des suggestions de substitution
    final suggestions = ['Générique A (500mg)', 'Générique B (500mg)'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PharmaConnectColors.primaryDeep,
        title: const Text('Substitution générique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Souhaitez-vous substituer "${item.medicationName}" par un générique ?',
              style: PharmaConnectTypography.body1,
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) {
              return ListTile(
                title: Text(suggestion),
                onTap: () {
                  final newItem = item.copyWith(
                    medicationName: suggestion,
                    isSubstitutionAllowed: true,
                  );
                  context.read<PrescriptionProvider>().updateExtractedItem(
                    index,
                    newItem,
                  );
                  Navigator.pop(context);
                },
                leading: const Icon(
                  Icons.medication,
                  color: PharmaConnectColors.accentPurple,
                ),
                tileColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Garder l\'original'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/modules/prescriptions/screens/prescription_upload_screen.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/tertiary_button.dart';
import '../providers/prescription_provider.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nouvelle ordonnance',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _selectedImage == null
                  ? _buildUploadView(context)
                  : _buildPreviewView(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Téléchargez votre ordonnance',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Prenez une photo ou sélectionnez une image',
            style: PharmaConnectTypography.body2,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Appareil photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmaConnectColors.accentCyan,
                  foregroundColor: PharmaConnectColors.textOnAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TertiaryButton(label: 'Annuler', onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildPreviewView(
    BuildContext context,
    PrescriptionProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reprendre'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Analyser l\'ordonnance',
                  isLoading:
                      provider.isProcessingOcr ||
                      provider.uploadStatus ==
                          PrescriptionUploadStatus.uploading,
                  onPressed: () async {
                    // Simuler l'ID patient
                    const patientId = 'patient_123';
                    const patientName = 'Jean Dupont';
                    await provider.uploadPrescription(
                      _selectedImage!.path,
                      patientId,
                      patientName,
                    );
                    if (provider.uploadStatus ==
                            PrescriptionUploadStatus.ready &&
                        context.mounted) {
                      context.go('/prescriptions/preview');
                    }
                  },
                ),
              ),
            ],
          ),
          if (provider.uploadStatus == PrescriptionUploadStatus.processing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Analyse en cours...',
              style: PharmaConnectTypography.body2.copyWith(
                color: PharmaConnectColors.textSecondary,
              ),
            ),
          ],
          if (provider.uploadError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PharmaConnectColors.accentRed.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                provider.uploadError!,
                style: PharmaConnectTypography.body2.copyWith(
                  color: PharmaConnectColors.accentRed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // handle error
    }
  }
}
```

## `lib/modules/prescriptions/services/ocr_service.dart`

```dart
import 'dart:math';
import '../models/prescription_item.dart';

class OcrService {
  // ==================== SIMULATION D'OCR ====================
  // En production, utiliser un vrai service (Google Cloud Vision, Tesseract, etc.)

  static final Map<String, List<String>> _drugDatabase = {
    'Paracétamol': ['Doliprane', 'Efferalgan', 'Dafalgan'],
    'Amoxicilline': [
      'Amoxicilline Biogaran',
      'Clamoxyl',
      'Amoxicilline Sandoz',
    ],
    'Ibuprofène': ['Advil', 'Nurofen', 'Spedifen'],
    'Salbutamol': ['Ventoline', 'Salbumol', 'Asmasal'],
    'Phloroglucinol': ['Spasfon', 'Spasfon Lyoc', 'Spasfon 80mg'],
    'Rosuvastatine': ['Crestor', 'Rosuvastatine Mylan', 'Rosuvastatine Sandoz'],
    'Metformine': ['Glucophage', 'Metformine Mylan', 'Metformine Sandoz'],
  };

  static final List<String> _dosages = [
    '100 mg',
    '200 mg',
    '250 mg',
    '500 mg',
    '1000 mg',
    '50 mg',
    '75 mg',
    '150 mg',
    '300 mg',
    '400 mg',
    '2 mg',
    '5 mg',
    '10 mg',
    '20 mg',
    '40 mg',
    '100 µg',
    '200 µg',
    '250 µg',
    '500 µg',
  ];

  static final List<String> _frequencies = [
    '1x par jour',
    '2x par jour',
    '3x par jour',
    '4x par jour',
    '1x par semaine',
    'Toutes les 6h',
    'Toutes les 8h',
    'Toutes les 12h',
    'A la demande',
    'Avant les repas',
    'Après les repas',
  ];

  static final List<String> _durations = [
    '3 jours',
    '5 jours',
    '7 jours',
    '10 jours',
    '14 jours',
    '21 jours',
    '1 mois',
    '3 mois',
    '6 mois',
  ];

  static final Random _random = Random();

  /// Simule l'extraction OCR d'une ordonnance à partir d'une image
  /// Retourne une liste de PrescriptionItem avec un score de confiance
  Future<Map<String, dynamic>> extractFromImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));

    // Simuler la détection de 2 à 4 médicaments
    final count = 2 + _random.nextInt(3);
    final items = <PrescriptionItem>[];
    final medicationNames = _drugDatabase.keys.toList();

    for (int i = 0; i < count; i++) {
      final drugKey = medicationNames[_random.nextInt(medicationNames.length)];
      final brandNames = _drugDatabase[drugKey] ?? [];
      final useBrand = _random.nextBool() && brandNames.isNotEmpty;

      final name = useBrand
          ? brandNames[_random.nextInt(brandNames.length)]
          : drugKey;

      // Simuler une erreur OCR possible (mauvaise orthographe)
      final ocrError = _random.nextDouble() < 0.15; // 15% d'erreur
      final finalName = ocrError ? _simulateOcrError(name) : name;

      final confidence = ocrError
          ? 0.6 +
                _random.nextDouble() *
                    0.3 // 60-90%
          : 0.85 + _random.nextDouble() * 0.15; // 85-100%

      items.add(
        PrescriptionItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_$i',
          prescriptionId: '', // sera rempli par le provider
          medicationName: finalName,
          dosage: _dosages[_random.nextInt(_dosages.length)],
          frequency: _frequencies[_random.nextInt(_frequencies.length)],
          duration: _durations[_random.nextInt(_durations.length)],
          quantity: 1 + _random.nextInt(3),
          instructions: _random.nextBool() ? 'A prendre avec de l\'eau' : null,
          isSubstitutionAllowed: _random.nextBool(),
          isExtractedByOcr: true,
          ocrConfidence: confidence,
        ),
      );
    }

    // Score de confiance global
    final avgConfidence =
        items.fold(0.0, (sum, item) => sum + item.ocrConfidence) / items.length;

    return {
      'items': items,
      'confidenceScore': avgConfidence,
      'isComplete': avgConfidence > 0.7,
    };
  }

  /// Simule des erreurs d'OCR sur les noms de médicaments
  String _simulateOcrError(String original) {
    if (original.length < 4) return original;
    final errors = [
      (s: 'i', r: 'l'),
      (s: 'l', r: 'i'),
      (s: 'o', r: '0'),
      (s: '0', r: 'o'),
      (s: 'a', r: 'e'),
      (s: 'e', r: 'a'),
      (s: 'm', r: 'rn'),
      (s: 'rn', r: 'm'),
      (s: 'n', r: 'm'),
      (s: 'm', r: 'n'),
    ];
    final error = errors[_random.nextInt(errors.length)];
    return original.replaceAll(error.s, error.r);
  }

  /// Suggère des corrections pour un nom de médicament
  Future<List<String>> suggestCorrection(String wrongName) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final allDrugs = <String>[];
    for (final entry in _drugDatabase.entries) {
      allDrugs.add(entry.key);
      allDrugs.addAll(entry.value);
    }

    // Trouver les correspondances par similarité (simulé)
    final suggestions = allDrugs
        .where((drug) {
          final lowerName = wrongName.toLowerCase();
          final lowerDrug = drug.toLowerCase();
          // Simuler une correspondance de Levenshtein simplifiée
          final isClose =
              lowerDrug.contains(
                lowerName.substring(0, min(3, lowerName.length)),
              ) ||
              lowerName.contains(
                lowerDrug.substring(0, min(3, lowerDrug.length)),
              );
          return isClose && drug != wrongName;
        })
        .take(3)
        .toList();

    return suggestions;
  }

  int min(int a, int b) => a < b ? a : b;
}
```

## `lib/modules/prescriptions/services/prescription_service.dart`

```dart
import 'dart:math';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';

class PrescriptionService {
  static final List<Prescription> _prescriptions = [];
  static final Random _random = Random();

  // Simuler une base de données d'ordonnances
  static final List<Prescription> _mockPrescriptions = [
    _createMockPrescription(
      id: 'rx_001',
      patientName: 'Jean Dupont',
      doctorName: 'Dr. Martin',
      status: PrescriptionStatus.pending,
      items: [
        _createMockItem(
          'Amoxicilline 500mg',
          'Amoxicilline',
          '500 mg',
          '2x par jour',
          '7 jours',
        ),
        _createMockItem(
          'Paracétamol 1000mg',
          'Paracétamol',
          '1000 mg',
          '3x par jour',
          '3 jours',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_002',
      patientName: 'Marie Konaté',
      doctorName: 'Dr. Diallo',
      status: PrescriptionStatus.validated,
      items: [
        _createMockItem(
          'Ventoline 100µg',
          'Salbutamol',
          '100 µg',
          'A la demande',
          '1 mois',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_003',
      patientName: 'Ibrahim Camara',
      doctorName: 'Dr. Sow',
      status: PrescriptionStatus.dispensed,
      items: [
        _createMockItem(
          'Spasfon 80mg',
          'Phloroglucinol',
          '80 mg',
          '3x par jour',
          '5 jours',
        ),
        _createMockItem(
          'Doliprane 500mg',
          'Paracétamol',
          '500 mg',
          '2x par jour',
          '3 jours',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_004',
      patientName: 'Fatoumata Diallo',
      doctorName: 'Dr. Barry',
      status: PrescriptionStatus.archived,
      items: [
        _createMockItem(
          'Crestor 10mg',
          'Rosuvastatine',
          '10 mg',
          '1x par jour',
          '6 mois',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_005',
      patientName: 'Ousmane Sow',
      doctorName: 'Dr. Camara',
      status: PrescriptionStatus.draft,
      items: [],
    ),
  ];

  static PrescriptionItem _createMockItem(
    String name,
    String generic,
    String dosage,
    String frequency,
    String duration,
  ) {
    return PrescriptionItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      prescriptionId: '',
      medicationName: name,
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      quantity: 1 + _random.nextInt(3),
      instructions: _random.nextBool() ? 'A prendre avec de l\'eau' : null,
      isSubstitutionAllowed: _random.nextBool(),
      isExtractedByOcr: false,
      ocrConfidence: 1.0,
    );
  }

  static Prescription _createMockPrescription({
    required String id,
    required String patientName,
    required String doctorName,
    required PrescriptionStatus status,
    required List<PrescriptionItem> items,
  }) {
    final now = DateTime.now();
    return Prescription(
      id: id,
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      doctorName: doctorName,
      uploadedAt: now.subtract(Duration(hours: _random.nextInt(48))),
      validatedAt:
          status == PrescriptionStatus.validated ||
              status == PrescriptionStatus.dispensed
          ? now.subtract(Duration(hours: _random.nextInt(24)))
          : null,
      dispensedAt: status == PrescriptionStatus.dispensed
          ? now.subtract(Duration(hours: _random.nextInt(12)))
          : null,
      status: status,
      imageUrl: '',
      items: items.map((item) => item.copyWith(prescriptionId: id)).toList(),
      ocrConfidenceScore: 0.95,
    );
  }

  static void _initMockData() {
    if (_prescriptions.isEmpty) {
      _prescriptions.addAll(_mockPrescriptions);
    }
  }

  Future<List<Prescription>> getPrescriptions({
    PrescriptionStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _prescriptions.where((p) => p.status == status).toList();
    }
    return _prescriptions;
  }

  Future<Prescription> getPrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _prescriptions.firstWhere((p) => p.id == id);
  }

  Future<Prescription> createPrescription({
    required String patientId,
    required String patientName,
    required String imageUrl,
    required List<PrescriptionItem> items,
    String? doctorName,
    double? ocrConfidenceScore,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _initMockData();

    final id = 'rx_${DateTime.now().millisecondsSinceEpoch}';
    final prescription = Prescription(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      uploadedAt: DateTime.now(),
      status: PrescriptionStatus.pending,
      imageUrl: imageUrl,
      items: items.map((item) => item.copyWith(prescriptionId: id)).toList(),
      ocrConfidenceScore: ocrConfidenceScore ?? 0.9,
    );

    _prescriptions.add(prescription);
    return prescription;
  }

  Future<Prescription> validatePrescription(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    final updated = _prescriptions[index].copyWith(
      status: PrescriptionStatus.validated,
      validatedAt: DateTime.now(),
      notes: notes,
    );
    _prescriptions[index] = updated;
    return updated;
  }

  Future<Prescription> dispensePrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    final updated = _prescriptions[index].copyWith(
      status: PrescriptionStatus.dispensed,
      dispensedAt: DateTime.now(),
    );
    _prescriptions[index] = updated;
    return updated;
  }

  Future<void> archivePrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    _prescriptions[index] = _prescriptions[index].copyWith(
      status: PrescriptionStatus.archived,
    );
  }

  Future<List<Prescription>> searchPrescriptions(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final lower = query.toLowerCase();
    return _prescriptions
        .where(
          (p) =>
              p.patientName.toLowerCase().contains(lower) ||
              (p.doctorName?.toLowerCase().contains(lower) ?? false) ||
              p.id.toLowerCase().contains(lower) ||
              p.items.any(
                (item) => item.medicationName.toLowerCase().contains(lower),
              ),
        )
        .toList();
  }
}
```

## `lib/modules/prescriptions/widgets/ocr_confidence_indicator.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class OcrConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final double size;

  const OcrConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(confidence);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: confidence,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Column(
              children: [
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  _getLabel(confidence),
                  style: PharmaConnectTypography.micro,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Confiance OCR', style: PharmaConnectTypography.label),
      ],
    );
  }

  Color _getColor(double confidence) {
    if (confidence >= 0.8) return PharmaConnectColors.accentGreen;
    if (confidence >= 0.6) return PharmaConnectColors.accentOrange;
    return PharmaConnectColors.accentRed;
  }

  String _getLabel(double confidence) {
    if (confidence >= 0.8) return 'Élevée';
    if (confidence >= 0.6) return 'Moyenne';
    return 'Faible';
  }
}
```

## `lib/modules/prescriptions/widgets/prescription_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/prescription.dart';

class PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;
  final bool compact;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: prescription.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusSm,
              ),
            ),
            child: Center(
              child: Text(
                prescription.statusLabel[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: prescription.statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription.patientName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact) ...[
                  Text(
                    prescription.items
                        .map((item) => item.medicationName)
                        .join(', '),
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: prescription.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        prescription.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: prescription.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(prescription.uploadedAt),
                      style: PharmaConnectTypography.micro,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Indicateur de confiance OCR
          if (prescription.ocrConfidenceScore != null) ...[
            Column(
              children: [
                Text(
                  '${(prescription.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: prescription.ocrConfidenceScore! > 0.8
                        ? PharmaConnectColors.accentGreen
                        : PharmaConnectColors.accentOrange,
                  ),
                ),
                const Text('Confiance', style: PharmaConnectTypography.micro),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}
```

## `lib/modules/prescriptions/widgets/prescription_item_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/prescription_item.dart';

class PrescriptionItemTile extends StatelessWidget {
  final PrescriptionItem item;
  final bool isExtracted;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onSubstitute;

  const PrescriptionItemTile({
    super.key,
    required this.item,
    this.isExtracted = false,
    this.showActions = false,
    this.onEdit,
    this.onSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(
          color: isExtracted
              ? PharmaConnectColors.accentCyan.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur de confiance OCR
          if (isExtracted) ...[
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: item.ocrConfidence > 0.8
                    ? PharmaConnectColors.accentGreen
                    : PharmaConnectColors.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isExtracted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaConnectColors.accentCyan.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OCR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        item.medicationName,
                        style: PharmaConnectTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.dosage} • ${item.frequency} • ${item.duration}',
                  style: PharmaConnectTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.instructions != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.instructions!,
                    style: PharmaConnectTypography.micro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.hasGenericAlternative) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentPurple.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💡', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Générique disponible',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: PharmaConnectColors.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          if (showActions) ...[
            Row(
              children: [
                if (onEdit != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: PharmaConnectColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                ],
                if (onSubstitute != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: PharmaConnectColors.accentPurple,
                      size: 18,
                    ),
                    onPressed: onSubstitute,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

## `lib/modules/prescriptions/widgets/upload_guidance_overlay.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class UploadGuidanceOverlay extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const UploadGuidanceOverlay({
    super.key,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PharmaConnectColors.primaryDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusLg),
        border: Border.all(
          color: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera, color: PharmaConnectColors.accentCyan),
              SizedBox(width: 12),
              Text(
                'Conseils pour une bonne photo',
                style: PharmaConnectTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip(
            icon: Icons.lightbulb,
            text: 'Choisissez un endroit bien éclairé',
            color: PharmaConnectColors.accentOrange,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.center_focus_strong,
            text: 'Cadrez toute l\'ordonnance dans le viseur',
            color: PharmaConnectColors.accentCyan,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.camera_alt,
            text: 'Assurez-vous que le texte est net et lisible',
            color: PharmaConnectColors.accentGreen,
          ),
          const SizedBox(height: 8),
          _buildTip(
            icon: Icons.photo_size_select_actual,
            text: 'Évitez les ombres et les reflets sur le document',
            color: PharmaConnectColors.accentPurple,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        PharmaConnectSpacing.radiusMd,
                      ),
                    ),
                  ),
                  child: const Text('Compris, continuer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: PharmaConnectTypography.body2)),
      ],
    );
  }
}
```

## `lib/modules/reservations/models/reservation.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'reservation_item.dart';
import 'reservation_status.dart';

class Reservation {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final List<ReservationItem> items;
  final DateTime reservedAt;
  final DateTime? pickupTime;
  final DateTime? pickupDeadline;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? cancelledAt;
  final ReservationStatus status;
  final double totalPrice;
  final String? qrCodeToken;
  final String? notes;

  Reservation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.items,
    required this.reservedAt,
    this.pickupTime,
    this.pickupDeadline,
    this.confirmedAt,
    this.readyAt,
    this.pickedUpAt,
    this.cancelledAt,
    required this.status,
    required this.totalPrice,
    this.qrCodeToken,
    this.notes,
  });

  Reservation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    List<ReservationItem>? items,
    DateTime? reservedAt,
    DateTime? pickupTime,
    DateTime? pickupDeadline,
    DateTime? confirmedAt,
    DateTime? readyAt,
    DateTime? pickedUpAt,
    DateTime? cancelledAt,
    ReservationStatus? status,
    double? totalPrice,
    String? qrCodeToken,
    String? notes,
  }) {
    return Reservation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      items: items ?? this.items,
      reservedAt: reservedAt ?? this.reservedAt,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupDeadline: pickupDeadline ?? this.pickupDeadline,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      readyAt: readyAt ?? this.readyAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isReady => status == ReservationStatus.ready;
  bool get isPickedUp => status == ReservationStatus.pickedUp;
  bool get isCancelled => status == ReservationStatus.cancelled;
  bool get isExpired => status == ReservationStatus.expired;

  bool get isCancelable => isPending || isConfirmed;

  Duration get timeRemaining {
    if (pickupDeadline == null) return Duration.zero;
    return pickupDeadline!.difference(DateTime.now());
  }

  bool get isRunningOutOfTime {
    if (pickupDeadline == null) return false;
    return timeRemaining.inMinutes < 15;
  }

  String get statusLabel {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente de confirmation';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.ready:
        return 'Prête à être retirée';
      case ReservationStatus.pickedUp:
        return 'Retirée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.expired:
        return 'Expirée';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReservationStatus.pending:
        return PharmaConnectColors.accentOrange;
      case ReservationStatus.confirmed:
        return PharmaConnectColors.accentCyan;
      case ReservationStatus.ready:
        return PharmaConnectColors.accentGreen;
      case ReservationStatus.pickedUp:
        return PharmaConnectColors.neutralMuted;
      case ReservationStatus.cancelled:
        return PharmaConnectColors.accentRed;
      case ReservationStatus.expired:
        return PharmaConnectColors.textSecondary;
    }
  }
}
```

## `lib/modules/reservations/models/reservation_item.dart`

```dart
class ReservationItem {
  final String productId;
  final String productName;
  final String genericName;
  final String dosage;
  final double pricePerUnit;
  final int quantity;
  final int? stockAtReservation;
  final bool isSubstitution;

  ReservationItem({
    required this.productId,
    required this.productName,
    required this.genericName,
    required this.dosage,
    required this.pricePerUnit,
    required this.quantity,
    this.stockAtReservation,
    this.isSubstitution = false,
  });

  double get totalPrice => pricePerUnit * quantity;

  ReservationItem copyWith({
    String? productId,
    String? productName,
    String? genericName,
    String? dosage,
    double? pricePerUnit,
    int? quantity,
    int? stockAtReservation,
    bool? isSubstitution,
  }) {
    return ReservationItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      quantity: quantity ?? this.quantity,
      stockAtReservation: stockAtReservation ?? this.stockAtReservation,
      isSubstitution: isSubstitution ?? this.isSubstitution,
    );
  }
}
```

## `lib/modules/reservations/models/reservation_status.dart`

```dart
enum ReservationStatus {
  pending,
  confirmed,
  ready,
  pickedUp,
  cancelled,
  expired,
}

extension ReservationStatusExtension on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.ready:
        return 'Prête';
      case ReservationStatus.pickedUp:
        return 'Retirée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.expired:
        return 'Expirée';
    }
  }

  String get icon {
    switch (this) {
      case ReservationStatus.pending:
        return '⏳';
      case ReservationStatus.confirmed:
        return '✅';
      case ReservationStatus.ready:
        return '📦';
      case ReservationStatus.pickedUp:
        return '🙌';
      case ReservationStatus.cancelled:
        return '❌';
      case ReservationStatus.expired:
        return '⏰';
    }
  }
}
```

## `lib/modules/reservations/models/timeslot.dart`

```dart
class TimeSlot {
  final DateTime start;
  final DateTime end;
  final String label;
  final bool isAvailable;
  final bool isPeak;
  final int? estimatedWaitMinutes;

  const TimeSlot({
    required this.start,
    required this.end,
    required this.label,
    required this.isAvailable,
    this.isPeak = false,
    this.estimatedWaitMinutes,
  });

  bool get isNow {
    final now = DateTime.now();
    return start.isBefore(now) && end.isAfter(now);
  }

  bool get isPast {
    final now = DateTime.now();
    return end.isBefore(now);
  }

  bool get isSoon {
    final now = DateTime.now();
    final diff = start.difference(now);
    return diff.inMinutes > 0 && diff.inMinutes < 30;
  }

  String get displayTime {
    final format = (start.minute == 0 || start.minute == 30)
        ? 'HH:mm'
        : 'HH:mm';
    return '${_formatTime(start, format)} - ${_formatTime(end, format)}';
  }

  String _formatTime(DateTime time, String format) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get relativeLabel {
    if (isNow) return 'Maintenant';
    if (isSoon) return 'Dans ${start.difference(DateTime.now()).inMinutes} min';
    if (isPast) return 'Passé';
    return displayTime;
  }
}
```

## `lib/modules/reservations/providers/reservation_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../services/reservation_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationService _service = ReservationService();

  List<Reservation> _reservations = [];
  Reservation? _selectedReservation;
  final List<ReservationItem> _cartItems = [];
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  bool _isLoading = false;
  String? _selectedPharmacyId;
  String? _selectedPharmacyName;
  String? _selectedPharmacyAddress;

  List<Reservation> get reservations => _reservations;
  Reservation? get selectedReservation => _selectedReservation;
  List<ReservationItem> get cartItems => _cartItems;
  List<TimeSlot> get availableSlots => _availableSlots;
  TimeSlot? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  String? get selectedPharmacyId => _selectedPharmacyId;
  String? get selectedPharmacyName => _selectedPharmacyName;
  String? get selectedPharmacyAddress => _selectedPharmacyAddress;

  double get cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasItemsInCart => _cartItems.isNotEmpty;

  // ==================== LOAD ====================

  Future<void> loadReservations({ReservationStatus? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _reservations = await _service.getReservations(status: status);
    } catch (e) {
      // handle error
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadReservation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedReservation = await _service.getReservation(id);
    } catch (e) {
      // handle error
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableSlots({
    required String pharmacyId,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableSlots = await _service.getAvailableTimeSlots(
        pharmacyId: pharmacyId,
        date: date,
      );
      _selectedPharmacyId = pharmacyId;
    } catch (e) {
      // handle error
    }
    _isLoading = false;
    notifyListeners();
  }

  // ==================== CART ====================

  void addToCart(ReservationItem item) {
    final existingIndex = _cartItems.indexWhere(
      (i) => i.productId == item.productId,
    );
    if (existingIndex != -1) {
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + item.quantity,
      );
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ==================== CHECKOUT ====================

  Future<Reservation?> createReservation({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    DateTime? preferredPickupTime,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final reservation = await _service.createReservation(
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        pharmacyAddress: pharmacyAddress,
        items: _cartItems,
        preferredPickupTime: preferredPickupTime,
      );
      _selectedReservation = reservation;
      _reservations.add(reservation);
      _cartItems.clear();
      _isLoading = false;
      notifyListeners();
      return reservation;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTIONS SUR RÉSERVATION ====================

  Future<bool> confirmReservation(String id) async {
    try {
      final updated = await _service.confirmReservation(id);
      _updateReservation(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsReady(String id) async {
    try {
      final updated = await _service.markAsReady(id);
      _updateReservation(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsPickedUp(String id) async {
    try {
      final updated = await _service.markAsPickedUp(id);
      _updateReservation(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelReservation(String id, {String? reason}) async {
    try {
      final updated = await _service.cancelReservation(id, reason: reason);
      _updateReservation(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  void selectSlot(TimeSlot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setPharmacyInfo({
    required String id,
    required String name,
    required String address,
  }) {
    _selectedPharmacyId = id;
    _selectedPharmacyName = name;
    _selectedPharmacyAddress = address;
    notifyListeners();
  }

  void clearSelected() {
    _selectedReservation = null;
    _selectedSlot = null;
    _availableSlots = [];
    notifyListeners();
  }

  void _updateReservation(Reservation updated) {
    final index = _reservations.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reservations[index] = updated;
    }
    if (_selectedReservation?.id == updated.id) {
      _selectedReservation = updated;
    }
    notifyListeners();
  }
}
```

## `lib/modules/reservations/screens/cart_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/reservation_provider.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Panier',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (provider.hasItemsInCart) ...[
                  TextButton.icon(
                    onPressed: provider.clearCart,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Vider'),
                    style: TextButton.styleFrom(
                      foregroundColor: PharmaConnectColors.accentRed,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Contenu
            Expanded(
              child: provider.hasItemsInCart
                  ? ListView.builder(
                      itemCount: provider.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = provider.cartItems[index];
                        return CartItemTile(
                          item: item,
                          onRemove: () =>
                              provider.removeFromCart(item.productId),
                          onQuantityChanged: (qty) {
                            provider.updateCartItemQuantity(
                              item.productId,
                              qty,
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Votre panier est vide',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez des médicaments depuis la recherche',
                            style: PharmaConnectTypography.body2,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Rechercher des médicaments',
                            onPressed: () => context.go('/search'),
                            width: 300,
                          ),
                        ],
                      ),
                    ),
            ),

            // Total et checkout
            if (provider.hasItemsInCart) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total du panier',
                          style: PharmaConnectTypography.label,
                        ),
                        Text(
                          CurrencyFormatter.format(provider.cartTotal),
                          style: PharmaConnectTypography.kpiSmall.copyWith(
                            color: PharmaConnectColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  PrimaryButton(
                    label: 'Passer la commande',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      context.push('/reservations/checkout');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
```

## `lib/modules/reservations/screens/pharmacy_queue_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class PharmacyQueueScreen extends StatelessWidget {
  const PharmacyQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "File d'attente pharmacie",
      icon: Icons.people_outline,
    );
  }
}
```

## `lib/modules/reservations/screens/reservation_checkout_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationCheckoutScreen extends StatelessWidget {
  const ReservationCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Validation de la réservation',
      icon: Icons.shopping_bag_outlined,
    );
  }
}
```

## `lib/modules/reservations/screens/reservation_confirmation_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Réservation confirmée',
      icon: Icons.check_circle_outline,
    );
  }
}
```

## `lib/modules/reservations/screens/reservation_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Historique des réservations',
      icon: Icons.history,
    );
  }
}
```

## `lib/modules/reservations/screens/reservation_qr_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/screens/placeholder_screen.dart';

class ReservationQRScreen extends StatelessWidget {
  const ReservationQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'QR code de retrait',
      icon: Icons.qr_code_2,
    );
  }
}
```

## `lib/modules/reservations/services/reservation_service.dart`

```dart
import 'dart:math';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';

class ReservationService {
  static final List<Reservation> _reservations = [];
  static final Random _random = Random();

  // Mock des réservations
  static final List<Reservation> _mockReservations = [
    _createMockReservation(
      id: 'res_001',
      patientName: 'Jean Dupont',
      pharmacyName: 'Pharmacie Centrale',
      status: ReservationStatus.pending,
      items: [
        _createMockItem('Doliprane 1000mg', 2500, 2),
        _createMockItem('Amoxicilline 500mg', 4500, 1),
      ],
    ),
    _createMockReservation(
      id: 'res_002',
      patientName: 'Marie Konaté',
      pharmacyName: 'Pharmacie du Soleil',
      status: ReservationStatus.confirmed,
      items: [_createMockItem('Ventoline 100µg', 8500, 1)],
    ),
    _createMockReservation(
      id: 'res_003',
      patientName: 'Ibrahim Camara',
      pharmacyName: 'Pharmacie Moderne',
      status: ReservationStatus.ready,
      items: [_createMockItem('Spasfon 80mg', 3500, 3)],
    ),
  ];

  static ReservationItem _createMockItem(String name, double price, int qty) {
    return ReservationItem(
      productId: 'prod_${_random.nextInt(100)}',
      productName: name,
      genericName: name,
      dosage: '500 mg',
      pricePerUnit: price,
      quantity: qty,
      stockAtReservation: 10,
    );
  }

  static Reservation _createMockReservation({
    required String id,
    required String patientName,
    required String pharmacyName,
    required ReservationStatus status,
    required List<ReservationItem> items,
  }) {
    final now = DateTime.now();
    final pickupDeadline = now.add(const Duration(hours: 2));
    return Reservation(
      id: id,
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      patientPhone: '+224 612 345 678',
      pharmacyId: 'ph_${_random.nextInt(5)}',
      pharmacyName: pharmacyName,
      pharmacyAddress: '123 Rue du Commerce, Conakry',
      items: items,
      reservedAt: now.subtract(Duration(minutes: _random.nextInt(60))),
      pickupDeadline: pickupDeadline,
      status: status,
      totalPrice: items.fold(0, (sum, item) => sum + item.totalPrice),
      qrCodeToken: 'qr_${_random.nextInt(1000000)}',
    );
  }

  static void _initMockData() {
    if (_reservations.isEmpty) {
      _reservations.addAll(_mockReservations);
    }
  }

  Future<List<Reservation>> getReservations({ReservationStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _reservations.where((r) => r.status == status).toList();
    }
    return _reservations;
  }

  Future<Reservation> getReservation(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _reservations.firstWhere((r) => r.id == id);
  }

  Future<List<Reservation>> getReservationsForPharmacy(
    String pharmacyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _reservations.where((r) => r.pharmacyId == pharmacyId).toList();
  }

  Future<Reservation> createReservation({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    required List<ReservationItem> items,
    required DateTime? preferredPickupTime,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final pickupDeadline = now.add(const Duration(hours: 2));

    final reservation = Reservation(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      items: items,
      reservedAt: now,
      pickupTime: preferredPickupTime,
      pickupDeadline: pickupDeadline,
      status: ReservationStatus.pending,
      totalPrice: items.fold(0, (sum, item) => sum + item.totalPrice),
      qrCodeToken: 'qr_${_random.nextInt(1000000)}',
    );

    _reservations.add(reservation);
    return reservation;
  }

  Future<Reservation> confirmReservation(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> markAsReady(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.ready,
      readyAt: DateTime.now(),
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> markAsPickedUp(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.pickedUp,
      pickedUpAt: DateTime.now(),
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> cancelReservation(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.cancelled,
      cancelledAt: DateTime.now(),
      notes: reason,
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String pharmacyId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final slots = <TimeSlot>[];

    // Générer des créneaux de 30 minutes entre 8h et 20h
    const startHour = 8;
    const endHour = 20;

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final start = DateTime(date.year, date.month, date.day, hour, minute);
        final end = start.add(const Duration(minutes: 30));

        // Simuler la disponibilité (80% des créneaux disponibles)
        final isAvailable = _random.nextDouble() < 0.8;

        // Créneaux de pointe : midi et 17h-19h
        final isPeak = (hour >= 12 && hour <= 13) || (hour >= 17 && hour <= 18);

        // Temps d'attente estimé (0-15 min)
        final waitMinutes = isPeak
            ? 5 + _random.nextInt(10)
            : _random.nextInt(5);

        slots.add(
          TimeSlot(
            start: start,
            end: end,
            label: _formatSlotTime(start, end),
            isAvailable: isAvailable,
            isPeak: isPeak,
            estimatedWaitMinutes: isAvailable ? waitMinutes : null,
          ),
        );
      }
    }

    return slots;
  }

  String _formatSlotTime(DateTime start, DateTime end) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }
}
```

## `lib/modules/reservations/widgets/cart_item_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/reservation_item.dart';

class CartItemTile extends StatelessWidget {
  final ReservationItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(
          color: item.isSubstitution
              ? PharmaConnectColors.accentPurple.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: PharmaConnectColors.accentCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.dosage} • ${CurrencyFormatter.format(item.pricePerUnit)}',
                  style: PharmaConnectTypography.body2,
                ),
                if (item.isSubstitution) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Générique',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: PharmaConnectColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Quantité
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => onQuantityChanged(item.quantity - 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${item.quantity}',
                  style: PharmaConnectTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onQuantityChanged(item.quantity + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Prix total
          Column(
            children: [
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: PharmaConnectTypography.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PharmaConnectColors.accentCyan,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## `lib/modules/reservations/widgets/timeslot_picker.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/timeslot.dart';

class TimeslotPicker extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const TimeslotPicker({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de date
        Row(
          children: [
            const Text(
              'Choisissez un créneau',
              style: PharmaConnectTypography.heading3,
            ),
            const Spacer(),
            // Navigation date
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                onDateChanged(selectedDate.subtract(const Duration(days: 1)));
              },
            ),
            Text(
              _formatDate(selectedDate),
              style: PharmaConnectTypography.body1,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                onDateChanged(selectedDate.add(const Duration(days: 1)));
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grille de créneaux
        if (slots.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun créneau disponible pour cette date',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = selectedSlot == slot;

              if (!slot.isAvailable) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Text(
                      slot.displayTime,
                      style: PharmaConnectTypography.body2.copyWith(
                        color: PharmaConnectColors.textSecondary.withValues(alpha: 
                          0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onSlotSelected(slot),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PharmaConnectColors.accentCyan.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? PharmaConnectColors.accentCyan
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot.displayTime,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? PharmaConnectColors.accentCyan
                              : PharmaConnectColors.textPrimary,
                        ),
                      ),
                      if (slot.estimatedWaitMinutes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '⏱ ${slot.estimatedWaitMinutes} min',
                          style: const TextStyle(
                            fontSize: 10,
                            color: PharmaConnectColors.textSecondary,
                          ),
                        ),
                      ],
                      if (slot.isPeak && isSelected) ...[
                        const SizedBox(height: 2),
                        const Text(
                          '⚠️ Heure de pointe',
                          style: TextStyle(
                            fontSize: 9,
                            color: PharmaConnectColors.accentOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Demain';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

## `lib/modules/search/models/availability_result.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'product.dart';
import 'pharmacy.dart';

class AvailabilityResult {
  final Product product;
  final List<PharmacyStock> pharmacyStocks;
  final bool hasAvailableStock;
  final int availableCount;

  AvailabilityResult({required this.product, required this.pharmacyStocks})
    : hasAvailableStock = pharmacyStocks.any((p) => p.stock > 0),
      availableCount = pharmacyStocks.where((p) => p.stock > 0).length;

  List<PharmacyStock> get availableStocks =>
      pharmacyStocks.where((p) => p.stock > 0).toList();

  List<PharmacyStock> get unavailableStocks =>
      pharmacyStocks.where((p) => p.stock <= 0).toList();

  PharmacyStock? get bestPrice => pharmacyStocks
      .where((p) => p.stock > 0)
      .fold<PharmacyStock?>(
        null,
        (best, current) =>
            best == null || current.price < best.price ? current : best,
      );

  PharmacyStock? get nearest => pharmacyStocks
      .where((p) => p.stock > 0 && p.pharmacy.distance != null)
      .fold<PharmacyStock?>(
        null,
        (best, current) =>
            best == null ||
                (current.pharmacy.distance ?? double.infinity) <
                    (best.pharmacy.distance ?? double.infinity)
            ? current
            : best,
      );
}

class PharmacyStock {
  final Pharmacy pharmacy;
  final int stock;
  final double price;
  final bool isAvailable;
  final DateTime lastUpdated;

  PharmacyStock({
    required this.pharmacy,
    required this.stock,
    required this.price,
    required this.isAvailable,
    required this.lastUpdated,
  });

  bool get isOutdated => DateTime.now().difference(lastUpdated).inHours >= 24;

  String get stockLabel {
    if (stock <= 0) return 'Rupture';
    if (stock < 5) return 'Stock très faible';
    if (stock < 20) return 'Stock faible';
    return 'Disponible';
  }

  Color get stockColor {
    if (stock <= 0) return PharmaConnectColors.accentRed;
    if (stock < 5) return PharmaConnectColors.accentAmber;
    if (stock < 20) return PharmaConnectColors.accentOrange;
    return PharmaConnectColors.accentGreen;
  }
}
```

## `lib/modules/search/models/pharmacy.dart`

```dart
class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpenNow;
  final bool isOpen24h;
  final bool isOnDuty;
  final double? distance;
  final String? openingHours;
  final String? imageUrl;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.isOpenNow,
    this.isOpen24h = false,
    this.isOnDuty = false,
    this.distance,
    this.openingHours,
    this.imageUrl,
  });

  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isOpenNow,
    bool? isOpen24h,
    bool? isOnDuty,
    double? distance,
    String? openingHours,
    String? imageUrl,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      isOpen24h: isOpen24h ?? this.isOpen24h,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      distance: distance ?? this.distance,
      openingHours: openingHours ?? this.openingHours,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get distanceFormatted {
    if (distance == null) return 'Distance inconnue';
    if (distance! < 1000) return '${distance!.round()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
```

## `lib/modules/search/models/product.dart`

```dart
class Product {
  final String id;
  final String name;
  final String genericName;
  final String dosage;
  final String form;
  final String category;
  final String imageUrl;
  final bool isGeneric;
  final String manufacturer;
  final bool isPrescriptionRequired;
  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dosage,
    required this.form,
    required this.category,
    required this.imageUrl,
    required this.isGeneric,
    required this.manufacturer,
    required this.isPrescriptionRequired,
    this.description,
  });

  Product copyWith({
    String? id,
    String? name,
    String? genericName,
    String? dosage,
    String? form,
    String? category,
    String? imageUrl,
    bool? isGeneric,
    String? manufacturer,
    bool? isPrescriptionRequired,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isGeneric: isGeneric ?? this.isGeneric,
      manufacturer: manufacturer ?? this.manufacturer,
      isPrescriptionRequired:
          isPrescriptionRequired ?? this.isPrescriptionRequired,
      description: description ?? this.description,
    );
  }
}
```

## `lib/modules/search/providers/search_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/pharmacy.dart';
import '../models/availability_result.dart';
import '../services/search_service.dart';

enum SearchStatus { idle, searching, loaded, error }

class SearchProvider extends ChangeNotifier {
  final SearchService _service = SearchService();

  String _query = '';
  List<Product> _results = [];
  SearchStatus _status = SearchStatus.idle;
  String? _errorMessage;
  AvailabilityResult? _selectedProductAvailability;
  List<Pharmacy> _nearbyPharmacies = [];

  // Filtres
  bool _showOnlyAvailable = false;
  bool _showOnlyGeneric = false;
  bool _showOnlyNearby = false;

  String get query => _query;
  List<Product> get results => _results;
  SearchStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AvailabilityResult? get selectedProductAvailability =>
      _selectedProductAvailability;
  List<Pharmacy> get nearbyPharmacies => _nearbyPharmacies;
  bool get showOnlyAvailable => _showOnlyAvailable;
  bool get showOnlyGeneric => _showOnlyGeneric;
  bool get showOnlyNearby => _showOnlyNearby;

  List<Product> get filteredResults {
    var list = _results;
    if (_showOnlyGeneric) {
      list = list.where((p) => p.isGeneric).toList();
    }
    return list;
  }

  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      _results = [];
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }
    _status = SearchStatus.searching;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.searchProducts(query);
      _results = results;
      _status = SearchStatus.loaded;
    } catch (e) {
      _errorMessage = 'Erreur lors de la recherche';
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadProductAvailability(String productId) async {
    try {
      final availability = await _service.getProductAvailability(productId);
      _selectedProductAvailability = availability;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> loadNearbyPharmacies(double lat, double lon) async {
    try {
      final pharmacies = await _service.getPharmaciesByLocation(lat, lon, 5);
      _nearbyPharmacies = pharmacies;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  void toggleFilterAvailable() {
    _showOnlyAvailable = !_showOnlyAvailable;
    notifyListeners();
  }

  void toggleFilterGeneric() {
    _showOnlyGeneric = !_showOnlyGeneric;
    notifyListeners();
  }

  void toggleFilterNearby() {
    _showOnlyNearby = !_showOnlyNearby;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProductAvailability = null;
    notifyListeners();
  }

  void clearFilters() {
    _showOnlyAvailable = false;
    _showOnlyGeneric = false;
    _showOnlyNearby = false;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _results = [];
    _status = SearchStatus.idle;
    _errorMessage = null;
    _selectedProductAvailability = null;
    clearFilters();
    notifyListeners();
  }
}
```

## `lib/modules/search/screens/product_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/search_provider.dart';
import '../widgets/pharmacy_list_tile.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadProductAvailability(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final availability = search.selectedProductAvailability;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Détail du produit',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),
            // Contenu
            Expanded(
              child: availability == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fiche produit
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: PharmaConnectColors.accentCyan
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.medication,
                                        color: PharmaConnectColors.accentCyan,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            availability.product.name,
                                            style: PharmaConnectTypography
                                                .heading3,
                                          ),
                                          Text(
                                            availability.product.genericName,
                                            style:
                                                PharmaConnectTypography.body2,
                                          ),
                                          Text(
                                            '${availability.product.dosage} • ${availability.product.form}',
                                            style:
                                                PharmaConnectTypography.micro,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      availability.product.manufacturer,
                                      Icons.business,
                                      PharmaConnectColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      availability.product.isGeneric
                                          ? 'Générique'
                                          : 'Princeps',
                                      Icons.local_pharmacy,
                                      availability.product.isGeneric
                                          ? PharmaConnectColors.accentPurple
                                          : PharmaConnectColors.accentCyan,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      availability
                                              .product
                                              .isPrescriptionRequired
                                          ? 'Sur ordonnance'
                                          : 'Libre',
                                      Icons.description,
                                      availability
                                              .product
                                              .isPrescriptionRequired
                                          ? PharmaConnectColors.accentOrange
                                          : PharmaConnectColors.accentGreen,
                                    ),
                                  ],
                                ),
                                if (availability.product.description !=
                                    null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    availability.product.description!,
                                    style: PharmaConnectTypography.body2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Disponibilité par pharmacie
                          const Text(
                            'Disponibilité en pharmacie',
                            style: PharmaConnectTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (availability.hasAvailableStock) ...[
                            Text(
                              '${availability.availableCount} pharmacie(s) disponible(s)',
                              style: PharmaConnectTypography.body2,
                            ),
                          ] else ...[
                            Text(
                              'Aucune disponibilité pour le moment',
                              style: PharmaConnectTypography.body2.copyWith(
                                color: PharmaConnectColors.accentRed,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Liste des pharmacies
                          ...availability.pharmacyStocks.map((stock) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PharmacyListTile(
                                stock: stock,
                                onTap: stock.isAvailable
                                    ? () {
                                        // TODO: Naviguer vers la réservation
                                      }
                                    : null,
                              ),
                            );
                          }),
                          if (availability.hasAvailableStock) ...[
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Réserver ce produit',
                              icon: Icons.shopping_cart,
                              onPressed: () {
                                // TODO: Naviguer vers la réservation
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

## `lib/modules/search/screens/search_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_chips.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            SearchBarWidget(
              onSearch: (q) => search.search(q),
              onClear: () => search.clear(),
            ),
            const SizedBox(height: 12),
            // Filtres
            const FilterChipsWidget(),
            const SizedBox(height: 16),
            // Résultats
            Expanded(child: _buildContent(context, search)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SearchProvider search) {
    switch (search.status) {
      case SearchStatus.idle:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Recherchez un médicament, une DCI\nou une pharmacie',
                textAlign: TextAlign.center,
                style: PharmaConnectTypography.body2,
              ),
            ],
          ),
        );
      case SearchStatus.searching:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.error:
        return Center(
          child: Text(
            search.errorMessage ?? 'Une erreur est survenue',
            style: PharmaConnectTypography.body2.copyWith(
              color: PharmaConnectColors.accentRed,
            ),
          ),
        );
      case SearchStatus.loaded:
        if (search.filteredResults.isEmpty) {
          return const Center(
            child: Text(
              'Aucun résultat trouvé',
              style: PharmaConnectTypography.body2,
            ),
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: search.filteredResults.length,
          itemBuilder: (context, index) {
            final product = search.filteredResults[index];
            return ProductCard(
              product: product,
              onTap: () {
                context.push('/product/${product.id}');
              },
            );
          },
        );
    }
  }
}
```

## `lib/modules/search/services/search_service.dart`

```dart
import 'dart:math' as math;
import '../models/product.dart';
import '../models/pharmacy.dart';
import '../models/availability_result.dart';

class SearchService {
  // ==================== DONNÉES MOCKÉES ====================

  static final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Doliprane 1000mg',
      genericName: 'Paracétamol',
      dosage: '1000 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Sanofi',
      isPrescriptionRequired: false,
      description:
          'Antalgique et antipyrétique. Indiqué dans le traitement des douleurs et de la fièvre.',
    ),
    Product(
      id: 'p2',
      name: 'Amoxicilline 500mg',
      genericName: 'Amoxicilline',
      dosage: '500 mg',
      form: 'Gélule',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Biogaran',
      isPrescriptionRequired: true,
      description: 'Antibiotique de la famille des pénicillines.',
    ),
    Product(
      id: 'p3',
      name: 'Efferalgan 500mg',
      genericName: 'Paracétamol',
      dosage: '500 mg',
      form: 'Comprimé effervescent',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'UPSA',
      isPrescriptionRequired: false,
      description:
          'Antalgique et antipyrétique. Effervescent pour une meilleure absorption.',
    ),
    Product(
      id: 'p4',
      name: 'Ibuprofène 400mg',
      genericName: 'Ibuprofène',
      dosage: '400 mg',
      form: 'Comprimé',
      category: 'Anti-inflammatoire',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Pfizer',
      isPrescriptionRequired: false,
      description: 'Anti-inflammatoire non stéroïdien.',
    ),
    Product(
      id: 'p5',
      name: 'Ventoline 100µg',
      genericName: 'Salbutamol',
      dosage: '100 µg',
      form: 'Aérosol',
      category: 'Bronchodilatateur',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
      description: 'Bronchodilatateur indiqué dans l\'asthme.',
    ),
    Product(
      id: 'p6',
      name: 'Doliprane 500mg',
      genericName: 'Paracétamol',
      dosage: '500 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Sanofi',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p7',
      name: 'Augmentin 1g',
      genericName: 'Amoxicilline + Acide clavulanique',
      dosage: '1 g',
      form: 'Comprimé',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p8',
      name: 'Spasfon 80mg',
      genericName: 'Phloroglucinol',
      dosage: '80 mg',
      form: 'Comprimé',
      category: 'Antispasmodique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Teva',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p9',
      name: 'Crestor 10mg',
      genericName: 'Rosuvastatine',
      dosage: '10 mg',
      form: 'Comprimé',
      category: 'Hypolipémiant',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'AstraZeneca',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p10',
      name: 'Diabètes 850mg',
      genericName: 'Metformine',
      dosage: '850 mg',
      form: 'Comprimé',
      category: 'Antidiabétique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Merck',
      isPrescriptionRequired: true,
    ),
  ];

  static final List<Pharmacy> _pharmacies = [
    Pharmacy(
      id: 'ph1',
      name: 'Pharmacie Centrale',
      address: '123 Avenue de la République, Conakry',
      phone: '+224 612 345 678',
      latitude: 9.5095,
      longitude: -13.7122,
      isOpenNow: true,
      isOpen24h: false,
      isOnDuty: false,
      openingHours: '08:00 - 20:00',
    ),
    Pharmacy(
      id: 'ph2',
      name: 'Pharmacie du Soleil',
      address: '45 Rue du Commerce, Conakry',
      phone: '+224 622 334 455',
      latitude: 9.5195,
      longitude: -13.7222,
      isOpenNow: true,
      isOpen24h: true,
      isOnDuty: false,
      openingHours: '24h/24',
    ),
    Pharmacy(
      id: 'ph3',
      name: 'Pharmacie de l\'Hôpital',
      address: 'Avenue de l\'Hôpital, Conakry',
      phone: '+224 633 445 566',
      latitude: 9.4995,
      longitude: -13.7022,
      isOpenNow: false,
      isOpen24h: false,
      isOnDuty: true,
      openingHours: '08:00 - 18:00',
    ),
    Pharmacy(
      id: 'ph4',
      name: 'Pharmacie Moderne',
      address: 'Boulevard du 28 Septembre, Conakry',
      phone: '+224 644 556 677',
      latitude: 9.5295,
      longitude: -13.7322,
      isOpenNow: true,
      isOpen24h: false,
      isOnDuty: false,
      openingHours: '08:30 - 19:30',
    ),
    Pharmacy(
      id: 'ph5',
      name: 'Pharmacie de la Gare',
      address: 'Place de la Gare, Conakry',
      phone: '+224 655 667 788',
      latitude: 9.4895,
      longitude: -13.6922,
      isOpenNow: false,
      isOpen24h: false,
      isOnDuty: false,
      openingHours: '07:00 - 21:00',
    ),
  ];

  static final Map<String, Map<String, PharmacyStock>> _stocks = {};
  static final math.Random _random = math.Random();

  static void _initStocks() {
    if (_stocks.isNotEmpty) return;
    for (final product in _products) {
      final Map<String, PharmacyStock> stockByPharmacy = {};
      for (final pharmacy in _pharmacies) {
        final hasStock = _random.nextDouble() > 0.3;
        final stock = hasStock ? _random.nextInt(80) + 1 : 0;
        final price = 1000 + _random.nextInt(15000);
        stockByPharmacy[pharmacy.id] = PharmacyStock(
          pharmacy: pharmacy,
          stock: stock,
          price: price.toDouble(),
          isAvailable: stock > 0,
          lastUpdated: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
        );
      }
      _stocks[product.id] = stockByPharmacy;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initStocks();
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lower) ||
              p.genericName.toLowerCase().contains(lower) ||
              p.category.toLowerCase().contains(lower) ||
              p.manufacturer.toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<AvailabilityResult?> getProductAvailability(String productId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _initStocks();
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      final stockMap = _stocks[productId] ?? {};
      final pharmacyStocks = stockMap.values.toList();
      if (pharmacyStocks.isEmpty) return null;
      return AvailabilityResult(
        product: product,
        pharmacyStocks: pharmacyStocks,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<Pharmacy>> getPharmaciesByLocation(
    double lat,
    double lon,
    double radiusInKm,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initStocks();
    // Simuler un calcul de distance
    return _pharmacies
        .map((pharmacy) {
          final distance = _calculateDistance(
            lat,
            lon,
            pharmacy.latitude,
            pharmacy.longitude,
          );
          return pharmacy.copyWith(distance: distance);
        })
        .where((p) => p.distance! <= radiusInKm * 1000)
        .toList();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Rayon de la Terre en mètres
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => math.sin(x);
  double _cos(double x) => math.cos(x);
  double _sqrt(double x) => math.sqrt(x);
  double _atan2(double a, double b) => math.atan2(a, b);
}
```

## `lib/modules/search/widgets/filter_chips.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../providers/search_provider.dart';

class FilterChipsWidget extends StatelessWidget {
  const FilterChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          label: 'Disponible',
          selected: provider.showOnlyAvailable,
          onSelected: (_) => provider.toggleFilterAvailable(),
        ),
        _buildChip(
          label: 'Générique',
          selected: provider.showOnlyGeneric,
          onSelected: (_) => provider.toggleFilterGeneric(),
        ),
        _buildChip(
          label: 'Proche',
          selected: provider.showOnlyNearby,
          onSelected: (_) => provider.toggleFilterNearby(),
        ),
        if (provider.showOnlyAvailable ||
            provider.showOnlyGeneric ||
            provider.showOnlyNearby)
          _buildClearChip(context),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: PharmaConnectColors.accentCyan.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? PharmaConnectColors.accentCyan : Colors.white24,
      ),
    );
  }

  Widget _buildClearChip(BuildContext context) {
    return ActionChip(
      label: const Text('Effacer'),
      onPressed: () {
        context.read<SearchProvider>().clearFilters();
      },
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white24),
    );
  }
}
```

## `lib/modules/search/widgets/pharmacy_list_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/availability_result.dart';

class PharmacyListTile extends StatelessWidget {
  final PharmacyStock stock;
  final VoidCallback? onTap;

  const PharmacyListTile({super.key, required this.stock, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pharmacy = stock.pharmacy;
    final isAvailable = stock.isAvailable;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          border: Border.all(
            color: isAvailable
                ? PharmaConnectColors.accentGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Statut
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isAvailable
                    ? PharmaConnectColors.accentGreen
                    : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pharmacy.address,
                    style: PharmaConnectTypography.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (pharmacy.isOpenNow) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PharmaConnectColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ouvert',
                          style: PharmaConnectTypography.micro.copyWith(
                            color: PharmaConnectColors.accentGreen,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fermé',
                          style: PharmaConnectTypography.micro.copyWith(
                            color: PharmaConnectColors.accentRed,
                          ),
                        ),
                      ],
                      if (pharmacy.isOpen24h) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaConnectColors.accentCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '24h/24',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentCyan,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.isOnDuty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaConnectColors.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Garde',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: PharmaConnectColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                      if (pharmacy.distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          pharmacy.distanceFormatted,
                          style: PharmaConnectTypography.micro,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Prix & stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isAvailable) ...[
                  Text(
                    CurrencyFormatter.format(stock.price),
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stock.stockColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock.stockLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: stock.stockColor,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Rupture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## `lib/modules/search/widgets/product_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showStockIndicator;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showStockIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône ou image placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: PharmaConnectColors.accentCyan,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          // Nom
          Text(
            product.name,
            style: PharmaConnectTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // DCI
          Text(
            product.genericName,
            style: PharmaConnectTypography.body2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Dosage + forme
          Text(
            '${product.dosage} • ${product.form}',
            style: PharmaConnectTypography.micro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (product.isGeneric)
                _buildBadge('Générique', PharmaConnectColors.accentPurple),
              if (product.isPrescriptionRequired)
                _buildBadge('Ordonnance', PharmaConnectColors.accentOrange),
              if (!product.isPrescriptionRequired)
                _buildBadge('Libre', PharmaConnectColors.accentGreen),
            ],
          ),
          if (showStockIndicator) ...[
            const SizedBox(height: 8),
            // Indicateur de disponibilité (simulé)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PharmaConnectColors.accentGreen.withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: PharmaConnectColors.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Disponible en pharmacie',
                    style: PharmaConnectTypography.micro.copyWith(
                      color: PharmaConnectColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
```

## `lib/modules/search/widgets/search_bar.dart`

```dart
import 'package:flutter/material.dart';
import '../../../core/widgets/inputs/glass_input.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      label: '',
      hint: 'Nom du médicament, DCI, classe thérapeutique...',
      controller: _controller,
      prefixIcon: Icons.search,
      suffixIcon: _controller.text.isNotEmpty ? Icons.clear : null,
      onSuffixPressed: () {
        _controller.clear();
        widget.onClear();
        widget.onSearch('');
      },
      onChanged: (value) {
        setState(() {});
        widget.onSearch(value);
      },
    );
  }
}
```

## `lib/routes/app_router.dart`

```dart
import 'package:go_router/go_router.dart';

import '../core/services/supabase_service.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/otp_verification_screen.dart';
import '../modules/auth/screens/register_screen.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/delivery/screens/delivery_history_screen.dart';
import '../modules/delivery/screens/delivery_schedule_screen.dart';
import '../modules/delivery/screens/delivery_tracking_screen.dart';
import '../modules/delivery/screens/driver_dashboard_screen.dart';
import '../modules/payments/screens/dispute_screen.dart';
import '../modules/payments/screens/installment_plan_screen.dart';
import '../modules/payments/screens/payment_screen.dart';
import '../modules/payments/screens/reconciliation_screen.dart';
import '../modules/payments/screens/transaction_history_screen.dart';
import '../modules/payments/screens/wallet_screen.dart';
import '../modules/prescriptions/screens/prescription_detail_screen.dart';
import '../modules/prescriptions/screens/prescription_list_screen.dart';
import '../modules/prescriptions/screens/prescription_preview_screen.dart';
import '../modules/prescriptions/screens/prescription_upload_screen.dart';
import '../modules/reservations/screens/cart_screen.dart';
import '../modules/reservations/screens/pharmacy_queue_screen.dart';
import '../modules/reservations/screens/reservation_checkout_screen.dart';
import '../modules/reservations/screens/reservation_confirmation_screen.dart';
import '../modules/reservations/screens/reservation_history_screen.dart';
import '../modules/reservations/screens/reservation_qr_screen.dart';
import '../modules/search/screens/product_detail_screen.dart';
import '../modules/search/screens/search_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = SupabaseService().isAuthenticated;
      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/otp';

      if (!isAuth && !isGoingToAuth) return '/login';
      if (isAuth && isGoingToAuth) return '/dashboard';
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Search
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      // Prescriptions
      GoRoute(
        path: '/prescriptions',
        name: 'prescriptions',
        builder: (context, state) => const PrescriptionListScreen(),
      ),
      GoRoute(
        path: '/prescriptions/upload',
        name: 'prescriptions-upload',
        builder: (context, state) => const PrescriptionUploadScreen(),
      ),
      GoRoute(
        path: '/prescriptions/preview',
        name: 'prescriptions-preview',
        builder: (context, state) => const PrescriptionPreviewScreen(),
      ),
      GoRoute(
        path: '/prescriptions/:id',
        name: 'prescriptions-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PrescriptionDetailScreen(prescriptionId: id);
        },
      ),
      // Cart
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/reservations/checkout',
        name: 'reservations-checkout',
        builder: (context, state) => const ReservationCheckoutScreen(),
      ),
      GoRoute(
        path: '/reservations/confirmation',
        name: 'reservations-confirmation',
        builder: (context, state) => const ReservationConfirmationScreen(),
      ),
      GoRoute(
        path: '/reservations/qr',
        name: 'reservations-qr',
        builder: (context, state) => const ReservationQRScreen(),
      ),
      GoRoute(
        path: '/reservations/history',
        name: 'reservations-history',
        builder: (context, state) => const ReservationHistoryScreen(),
      ),
      GoRoute(
        path: '/pharmacy/queue',
        name: 'pharmacy-queue',
        builder: (context, state) => const PharmacyQueueScreen(),
      ),
      // Delivery
      GoRoute(
        path: '/deliveries',
        name: 'deliveries',
        builder: (context, state) => const DeliveryHistoryScreen(),
      ),
      GoRoute(
        path: '/deliveries/tracking',
        name: 'deliveries-tracking',
        builder: (context, state) => const DeliveryTrackingScreen(),
      ),
      GoRoute(
        path: '/deliveries/schedule',
        name: 'deliveries-schedule',
        builder: (context, state) => const DeliveryScheduleScreen(),
      ),
      GoRoute(
        path: '/driver/dashboard',
        name: 'driver-dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      // Payments
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => PaymentScreen(
          amount: state.extra is double ? state.extra as double : 0,
          reservationId: null,
          deliveryId: null,
        ),
      ),
      GoRoute(
        path: '/payments/installment/:id',
        name: 'payments-installment',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InstallmentPlanScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/disputes',
        name: 'disputes',
        builder: (context, state) => const DisputeScreen(),
      ),
      GoRoute(
        path: '/pharmacy/reconciliation',
        name: 'pharmacy-reconciliation',
        builder: (context, state) => const ReconciliationScreen(),
      ),
    ],
  );
}
```

## `test/widget_test.dart`

```dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('PharmaConnectApp renders the login screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PharmaConnectApp());

    // The app starts on the login screen (auth gate before the dashboard).
    expect(find.text('Connexion'), findsOneWidget);
  });
}
```

---

## Rapport d'audit — 24 août 2026

Ce qui suit est le rapport d'audit complet remis à l'issue de la revue du projet, rédigé pour une lecture continue par l'architecte.

Le projet PharmaConnect, tel qu'il se présentait avant cette intervention, ne compilait pas. La commande `flutter analyze` remontait 149 signalements, dont 87 erreurs bloquantes concentrées dans trois modules récemment développés — livraison, paiements et réservations — ainsi que dans le routeur applicatif. En creusant, la cause s'est révélée commune à la quasi-totalité des erreurs : des imports absents ou incorrects entre modèles et écrans, et des fichiers d'énumération qui n'avaient en réalité jamais été créés malgré leur utilisation dans le code.

Trois modèles de données — `delivery.dart`, `reservation.dart` et `transaction.dart` — utilisaient la classe `Color` sans importer `package:flutter/material.dart`, ce qui a provoqué à lui seul dix-huit erreurs de compilation. Le modèle `transaction.dart` allait plus loin : il référençait un enum `TransactionStatus` qui n'existait dans aucun fichier du projet, ni dans le module `payments` ni ailleurs. Le fichier a été créé de toutes pièces (`pending`, `processing`, `completed`, `failed`, `refunded`, `disputed`), en miroir du patron déjà suivi pour `DeliveryStatus` et `ReservationStatus`. À l'inverse, `installment.dart` et `payment_service.dart` importaient un fichier `installment_status.dart` qui n'a jamais existé, alors que l'enum correspondant était déjà défini en bas du fichier `installment.dart` lui-même — il s'agissait d'un import mort, simplement retiré.

Un second groupe d'erreurs venait d'un principe Dart souvent oublié : les imports ne sont jamais transitifs. L'écran `delivery_tracking_screen.dart` et le widget `delivery_card.dart` utilisaient les types `Delivery` et `DeliveryStatus` en comptant sur le fait que leur fournisseur (`delivery_provider.dart`) les importait déjà — ce qui ne suffit pas en Dart : chaque fichier doit importer directement ce qu'il utilise. Les imports manquants ont été ajoutés dans les deux fichiers concernés.

Un bug de type distinct a été corrigé dans `payment_service.dart` : la méthode `getWalletBalance()` déclarait un type de retour `Future<double>` mais renvoyait un `int`, ce qui aurait échoué silencieusement selon le contexte d'appel. Dans `reservation_provider.dart`, deux champs (`_selectedPharmacyName`, `_selectedPharmacyAddress`) étaient renseignés par `setPharmacyInfo()` mais jamais exposés à l'extérieur de la classe — des accesseurs publics ont été ajoutés, par cohérence avec le champ `selectedPharmacyId` déjà exposé. Huit imports inutilisés ont par ailleurs été retirés à travers les modules réservations et paiements, et vingt-huit appels à la méthode dépréciée `.withOpacity()` ont été remplacés par `.withValues(alpha:)` dans les modules livraison, paiements, réservations et prescriptions.

Le point le plus structurant de cet audit concerne le routeur. `lib/routes/app_router.dart` définissait treize routes pointant vers des classes d'écran — `ReservationCheckoutScreen`, `ReservationConfirmationScreen`, `ReservationQRScreen`, `ReservationHistoryScreen`, `PharmacyQueueScreen`, `DeliveryHistoryScreen`, `DeliveryScheduleScreen`, `DriverDashboardScreen`, `InstallmentPlanScreen`, `WalletScreen`, `TransactionHistoryScreen`, `DisputeScreen`, `ReconciliationScreen` — qui n'avaient jamais été écrites, dans aucun fichier du projet. Le projet ne pouvait pas compiler tant qu'elles manquaient. Plutôt que d'improviser treize écrans complets avec une logique métier inventée, un composant partagé a été créé (`core/widgets/screens/placeholder_screen.dart`), et chacune des treize classes manquantes a été ajoutée comme une coquille minimale s'appuyant sur ce composant. Le projet compile, chaque route est navigable, mais il faut être clair sur ce que cela signifie : ce ne sont que des écrans provisoires. L'interface et la logique métier réelles de ces treize écrans restent entièrement à concevoir et à développer — ce n'est pas une correction de bug, c'est du travail produit à part entière qui reste devant l'équipe.

À l'issue de l'ensemble de ces corrections, `flutter analyze` ne remonte plus aucun signalement (« No issues found! ») et la suite de tests passe (`flutter test` : 1 test, 0 échec). Restent, hors du périmètre de cette correction de code, des décisions qui relèvent de l'architecte et du produit : la conception réelle des treize écrans provisoires ; une mise à jour des vingt-sept paquets ayant des versions plus récentes disponibles (`flutter pub outdated`), volontairement non appliquée ici pour ne pas introduire de régressions hors périmètre ; et le fait que les répertoires `test/unit/` et `test/widget/` existent mais sont vides — un seul test de démarrage protège aujourd'hui l'ensemble de l'application.

---

## Rapport de mise en conformité Kernel GSG v3.0 — 24 août 2026

Ce second rapport complète celui du premier audit (section précédente) : là où le premier corrigeait des erreurs de compilation, celui-ci porte sur la conformité du produit au cahier de conception du GSG Platform Kernel v3.0 — l'infrastructure d'identité, d'organisation et de référentiel partagée par tout le portefeuille GSG.

L'audit a porté sur cinq points de contrôle du cahier Kernel : le pont d'authentification vers le GSG ID, l'isolation des identifiants entre le produit et le Kernel, l'étanchéité de la base de données, l'usage du référentiel pays/devise/langue, et la résilience du produit face à un Kernel indisponible. Le point le plus significatif concernait l'authentification : si le code réellement appelé par l'application Flutter (`auth_service.dart`) s'est révélé parfaitement conforme — il n'utilise que le SDK Supabase Auth natif, sans rien réimplémenter — le dépôt contenait par ailleurs un second système d'authentification complet et fonctionnel, mais jamais branché à l'app : des Edge Functions Supabase (`send-otp`, `verify-otp`) qui généraient elles-mêmes un code à six chiffres, l'envoyaient via des wrappers directs vers Resend (email) et l'API Meta Cloud (WhatsApp), puis signaient manuellement un token de session avec le secret JWT legacy de Supabase pour contourner l'absence d'API admin équivalente. Ce n'était pas un flux actif — aucune ligne du code Flutter ne l'appelait — mais c'était un système déployable, à l'exact opposé de ce que prescrit KER-ID-02, laissé sans nettoyage dans le dépôt. Il a été supprimé intégralement, avec sauvegarde préalable hors dépôt (le projet n'étant pas sous git, aucune récupération n'aurait été possible autrement).

Le deuxième point notable concernait moins une violation qu'un mensonge d'interface : l'indicateur « GSG Kernel » affiché dans la barre latérale de l'application affichait en permanence un état « connecté » avec quatre services marqués « en ligne », sans qu'aucun appel réseau réel n'existe nulle part dans le code — `dio`, la bibliothèque HTTP du projet, n'était même pas importée une seule fois dans `lib/`. Un utilisateur, un testeur ou l'architecte lui-même consultant cet écran aurait pu raisonnablement croire que l'intégration Kernel était en place. Elle ne l'était pas. L'indicateur affiche désormais honnêtement l'absence de connexion, avec un commentaire explicite dans le code pour empêcher qu'il soit remis en dur à « connecté » avant qu'un véritable appel ne l'alimente.

Les trois autres points de contrôle ont révélé une architecture correcte mais incomplète plutôt que des violations actives. L'isolation des identifiants était conforme par construction : aucune table métier locale n'existe encore dans ce produit au-delà de `auth.users`, géré nativement par Supabase, donc rien n'a pu être refondu de façon destructive — mais la règle (clé primaire locale conservée, `gsg_id`/`gsg_org_id` en colonnes nullables) n'avait jamais été écrite noir sur blanc avant cet audit ; elle l'est désormais dans `CLAUDE.md`. L'étanchéité de la base était également conforme — aucune contrainte `FOREIGN KEY` ou `REFERENCES` inter-schémas dans les deux migrations existantes — mais reposait sur l'absence de schéma plutôt que sur une discipline vérifiée ; un garde-fou CI empêche désormais toute régression future. Le référentiel pays/devise/langue, en revanche, était une vraie lacune : la devise « GNF » était répétée en dur dans dix endroits du code, sans code ISO 4217, et le fichier `kernel_config.json`, dont le nom suggérait qu'il devait porter cette configuration, était vide depuis sa création. Les deux ont été corrigés — un formateur de devise centralisé côté code, des valeurs de repli Guinée/GNF/Français côté configuration.

Trois garde-fous ont été mis en place pour que ces constats ne se reproduisent pas silencieusement : un script CI qui fait échouer le build si une contrainte SQL référence un schéma externe au projet, un second qui fait échouer le build si une chaîne de devise apparaît en dur hors du formateur centralisé, et un pont d'authentification vers le GSG ID (`GsgKernelAuthBridge`) conçu dès l'origine pour ne jamais bloquer le login si le Kernel est indisponible — le patron de résilience que toute future intégration Kernel devra reproduire.

En préparant le document de conception destiné à l'architecte en chef (`REFERENTIEL_ARCHITECTE.md`), deux écarts supplémentaires sont apparus, indépendants de l'audit Kernel proprement dit mais tout aussi structurants pour la suite : tous les montants du produit (transactions, échéanciers, réservations, solde du portefeuille) sont stockés en `double`, alors que la règle KER-REF-05 impose un entier en unité mineure — un flottant sur de l'argent accumule des erreurs d'arrondi dès qu'on additionne des frais ou qu'on divise un échéancier en plusieurs paiements, et ce changement de type devra être fait avant la première vraie migration Postgres plutôt qu'après. Les numéros de téléphone, par ailleurs, ne sont jamais normalisés au format E.164 strict malgré la règle explicite du portefeuille — les dix occurrences du code contiennent toutes des espaces (`+224 612 345 678`), et le fichier `validators.dart`, prévu pour ce genre de normalisation, est resté vide depuis sa création. Un troisième écart, plus proche de l'hygiène de code que de la conformité Kernel, a également été relevé : trois providers (`prescription_provider.dart`, `reservation_provider.dart`, `search_provider.dart`) avalent silencieusement leurs erreurs (`// handle error` sans code derrière), contrairement à `delivery_provider.dart` et `payment_provider.dart` qui exposent correctement l'erreur à l'UI — une incohérence qui aurait rendu une panne réseau indiscernable d'un simple écran vide pour l'utilisateur final.

À l'issue de cette seconde intervention, `flutter analyze` reste à zéro signalement, `flutter test` continue de passer, et les deux nouveaux garde-fous CI ont été vérifiés à la fois positivement (silencieux sur le code actuel) et négativement (ils échouent bien face à une violation injectée délibérément). Le détail des directives de conception pour les 27 modules restants, incluant les trois écarts ci-dessus formulés comme des règles à appliquer dès la conception plutôt que comme des corrections a posteriori, figure dans `REFERENTIEL_ARCHITECTE.md`.

---

## Rapport d'audit — 25 août 2026

Cette troisième intervention a commencé par une tentative banale de faire tourner `flutter pub get`, et s'est arrêtée net : la commande levait une exception non gérée avant même d'atteindre l'analyseur. `pubspec.yaml` déclarait trois dépendances deux fois chacune (`image_picker`, `flutter_local_notifications`, `qr_flutter`) — un YAML avec clé dupliquée n'est pas un fichier valide, et aucune commande Flutter, pas même `flutter analyze`, ne peut s'exécuter tant qu'il ne parse pas. Une fois le fichier dédoublonné, une seconde exception a suivi immédiatement : `tesseract_ocr`, la dépendance utilisée par `OcrService` pour l'OCR d'ordonnances, n'a jamais été migrée au null-safety et est structurellement incompatible avec le SDK Dart du projet. Remplacée par `google_mlkit_text_recognition` — une solution de reconnaissance de texte on-device activement maintenue — avec réécriture du service à l'identique côté interface publique, pour ne rien casser chez ses appelants.

Une fois ces deux blocages levés, `flutter analyze` a enfin pu s'exécuter, et a remonté 216 erreurs de compilation — un nombre sans commune mesure avec les 149 signalements de l'audit du 24/08, et pour cause : entre les deux dates, six modules entiers ont été codés (`stock`, `traceability`, `coldchain`, `recall`, `admin`, `alerts` — 86 fichiers Dart, environ 40 % du volume actuel du projet) sans qu'aucun des trois documents d'accompagnement de ce dépôt (`PharmaConnect_CLAUDE.md`, `REFERENTIEL_ARCHITECTE.md`, le présent export) n'en garde la moindre trace. Rien dans ce constat n'accuse qui que ce soit — il n'y a simplement aucun moyen, en l'absence de dépôt git, de savoir qui a écrit quoi, quand, ni si l'ordre des opérations (ajout de code, puis rupture de `pubspec.yaml`) est fortuit ou lié. C'est un fait vérifiable et un point sur lequel ce rapport insiste en conclusion, pas une hypothèse.

L'analyse des 216 erreurs a montré qu'aucune ne relevait d'un défaut de logique métier : la quasi-totalité provenait à nouveau du principe déjà documenté dans l'audit du 24/08 — les imports Dart ne sont jamais transitifs — appliqué cette fois à six modules neufs plutôt qu'à trois. Des modèles utilisaient `Color`/`Colors` sans importer `material.dart`, ou référençaient un enum défini dans un fichier voisin du même module sans jamais l'importer directement. Deux cas se distinguent du lot habituel : `StockMovementType` et `BatchMovementType` déclaraient chacun un membre d'enum nommé `return`, qui est un mot réservé du langage Dart et ne peut donc pas servir d'identifiant — renommés `supplierReturn` et `customerReturn` après vérification qu'aucun autre fichier du projet ne référençait le nom d'origine. Et, comme lors du premier audit, le routeur applicatif référençait des classes jamais écrites : quatre écrans (`EquipmentAddScreen`, `PharmaciesManagementScreen`, `AuditLogScreen`, `SystemConfigScreen`) et, séparément, trois widgets importés par `search_screen.dart` (`SearchSkeleton`, `SearchEmptyState`, `SearchErrorState`). Les quatre écrans ont reçu le même traitement qu'au 24/08 — une coquille minimale sur `PlaceholderScreen` — tandis que les trois widgets de recherche, eux, ont été écrits en respectant les appels déjà présents dans `search_screen.dart`, puisque leur absence bloquait un écran par ailleurs déjà fonctionnel.

Les 216 erreurs ont été corrigées en répartissant les 33 modules concernés en quatre lots traités en parallèle, chacun vérifié indépendamment par `flutter analyze` avant intégration : un premier lot (`stock`, `traceability`, `coldchain`, `recall` — 60 erreurs) a notamment révélé que deux extensions de statut (`BatchStatusExtension`, `RecallStatusExtension`) n'exposaient tout simplement pas le getter `color` que leurs propres écrans appelaient déjà. Un deuxième lot (`alerts`, `search`, `dashboard`, `delivery` — 66 erreurs) a dû recréer les trois widgets de recherche mentionnés plus haut, et corriger quatre appels à `Position(...)` du paquet `geolocator` devenus invalides parce que la version installée exige désormais les paramètres `altitudeAccuracy`/`headingAccuracy`. Un troisième lot (`payments`, `reservations`, `admin`, `auth` — 40 erreurs) a corrigé un bug de précédence d'opérateur réel dans `transaction_history_screen.dart` (`??` se lie plus faiblement que `||` en Dart, ce qui rendait une condition nullable de façon non voulue) et complété un `copyWith` manquant sur `SystemConfig`. Un dernier lot, traité directement plutôt que délégué (`routes`, `core`, `prescriptions` — 10 erreurs), a migré l'appel `zonedSchedule` de `NotificationService` vers `TZDateTime` (le paquet `timezone` n'était pas déclaré comme dépendance directe malgré un usage direct), et implémenté `OcrService.suggestCorrection()` — appelée par `PrescriptionProvider` mais jamais définie — par une recherche de distance de Levenshtein contre le catalogue de médicaments existant.

Deux régressions de conformité Kernel, distinctes des erreurs de compilation, ont été détectées en exécutant les trois garde-fous CI déjà présents dans `scripts/ci/` — et c'est là le constat le plus significatif de cette intervention. `check_no_hardcoded_color.sh` échoue : le module `traceability`, codé après que l'audit du 24/08 a corrigé et documenté l'anti-motif exact (§ rapport précédent, KER-DES-03), le reproduit à l'identique — 18 occurrences de `Color(0xFF...)` littéral dans `batch_status.dart` et `traceable_batch.dart`, le même getter `statusColor` copié depuis un des cinq modèles déjà corrigés. `check_no_hardcoded_currency.sh` échoue également : 11 chaînes `'... GNF'` littérales, dont 4 dans le module `payments` — documenté comme déjà mis en conformité le 24/08. Ni l'une ni l'autre régression n'a été corrigée dans cette intervention : la substitution d'un littéral par le token ou le formateur correct demande un arbitrage visuel ou produit ligne par ligne, pas une opération mécanique sûre à automatiser sans revue humaine — elles sont documentées comme chantier prioritaire dans `REFERENTIEL_ARCHITECTE.md` (§3.5) plutôt que corrigées à la hâte.

La cause commune à ces deux régressions n'est pas un relâchement de discipline de la part de qui a écrit les six nouveaux modules — c'est que les garde-fous censés les empêcher n'ont jamais pu s'exécuter. `.github/workflows/kernel-compliance.yml` se déclenche sur `push` vers `main` et sur toute pull request ; ce répertoire n'est pas un dépôt git, il n'y a donc jamais eu de `push`, jamais de pull request, et par construction jamais une seule exécution de ce workflow depuis sa création. Les trois scripts qu'il orchestre sont corrects — exécutés manuellement aujourd'hui, ils détectent bien les 29 occurrences ci-dessus — mais un garde-fou qui ne s'exécute jamais protège aussi peu qu'un garde-fou qui n'existe pas. C'est, plus qu'aucune des erreurs de compilation, le constat que ce rapport recommande de traiter en premier : sans dépôt git, ni cet audit ni le précédent ne peuvent garantir qu'un troisième développeur, humain ou agent, ne reproduira pas la même régression une troisième fois dans les modules restants.

À l'issue de cette intervention, `flutter pub get` résout proprement, `flutter analyze` ne remonte plus aucune erreur (83 avertissements et informations non bloquants subsistent — imports inutilisés, `const` manquants, cinq usages de `BuildContext` après un `await` sans vérification `mounted`, qui sont les seuls parmi les 83 à représenter un risque réel plutôt qu'une question de style), et `flutter test` passe (1 test, 0 échec — toujours le seul test du projet, désormais rapporté à 178 fichiers Dart plutôt qu'à ~90). Le garde-fou `check_no_cross_schema_fk.sh` passe. Les recommandations issues de cette intervention — corriger les deux régressions de gouvernance, initialiser un dépôt git avant tout nouveau module, écrire les premières migrations Supabase (le répertoire `supabase/migrations/` est resté vide sur les trois audits), et mettre à jour un lot de paquets obsolètes désormais passé de 27 à 52 — sont détaillées et priorisées dans `REFERENTIEL_ARCHITECTE.md`.
