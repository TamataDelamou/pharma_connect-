import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/app.dart';
import 'package:pharma_connect/core/theme/adaptive_text_scale.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/buttons/secondary_button.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/cash/models/cash_drawer_session.dart';
import 'package:pharma_connect/modules/cash/models/cash_movement.dart';
import 'package:pharma_connect/modules/cash/providers/cash_provider.dart';
import 'package:pharma_connect/modules/cash/screens/cash_dashboard_screen.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale_item.dart';
import 'package:pharma_connect/modules/pos/providers/pos_provider.dart';
import 'package:pharma_connect/modules/pos/screens/pos_receipt_screen.dart';
import 'package:pharma_connect/modules/reservations/models/reservation.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_status.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_confirmation_screen.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_history_screen.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_qr_screen.dart';
import 'package:pharma_connect/modules/reservations/widgets/queue_position_widget.dart';
import 'package:pharma_connect/modules/search/models/availability_result.dart';
import 'package:pharma_connect/modules/search/models/pharmacy.dart';
import 'package:pharma_connect/modules/search/models/search_result.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/modules/search/screens/product_detail_screen.dart';
import 'package:pharma_connect/modules/search/widgets/search_result_card.dart';
import 'package:pharma_connect/routes/app_router.dart';
import 'package:pharma_connect/shared/models/product.dart';

import '../../helpers/phone_layout.dart';

// C253 : aucun débordement à 360 px de large. Essai permanent : un écran ou
// un composant ajouté ici ne doit plus jamais afficher « OVERFLOWED BY …
// PIXELS ». Les données sont volontairement longues (noms, montants).

const _longPharmacy = 'Pharmacie Centrale de la Minière et du Rond-Point';

final _product = Product(
  id: 'p1',
  name: 'Amoxicilline acide clavulanique',
  genericName: 'Amoxicilline + acide clavulanique',
  dosage: '1g/125mg',
  form: 'Comprimé pelliculé',
  category: 'Antibiotiques',
  imageUrl: '',
  isGeneric: true,
  manufacturer: 'Laboratoire',
  isPrescriptionRequired: true,
);

Pharmacy _pharmacy({bool open24h = true}) => Pharmacy(
  id: 'ph1',
  name: _longPharmacy,
  address: 'Carrefour Minière, route Le Prince, commune de Dixinn, Conakry',
  phone: '+224620000000',
  latitude: 9.51,
  longitude: -13.71,
  isOpenNow: true,
  isOpen24h: open24h,
  isOnDuty: true,
  distance: 12.4,
);

final _availability = AvailabilityResult(
  product: _product,
  pharmacyStocks: [
    PharmacyStock(
      pharmacy: _pharmacy(),
      stock: 125,
      price: 125000,
      isAvailable: true,
      lastUpdated: DateTime.now(),
    ),
    PharmacyStock(
      pharmacy: _pharmacy(open24h: false),
      stock: 0,
      price: 125000,
      isAvailable: false,
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ],
);

Reservation _reservation(String id, ReservationStatus status) {
  final now = DateTime.now();
  return Reservation(
    id: id,
    patientId: 'patient-1',
    patientName: 'Mariama Diallo',
    patientPhone: '',
    pharmacyId: 'ph1',
    pharmacyName: _longPharmacy,
    pharmacyAddress:
        'Carrefour Minière, route Le Prince, commune de Dixinn, Conakry',
    items: [
      ReservationItem(
        id: 'i1',
        productId: 'p1',
        productName: 'Amoxicilline acide clavulanique',
        genericName: 'Amoxicilline + acide clavulanique',
        dosage: '1g/125mg',
        pricePerUnit: 125000,
        quantity: 12,
        prescriptionRequired: true,
      ),
    ],
    reservedAt: now.subtract(const Duration(hours: 2)),
    pickupDeadline: now.add(const Duration(hours: 22)),
    status: status,
    totalPrice: 1500000,
    qrCodeToken: 'K7M4QX',
    queuePosition: 12,
    estimatedWaitMinutes: 135,
  );
}

/// Caisse ouverte posée par le test.
class _OpenCashProvider extends CashProvider {
  @override
  CashDrawerSession? get currentSession => CashDrawerSession(
    id: 's1',
    pharmacyId: 'ph1',
    cashierId: 'u1',
    openingBalance: 250000,
    openedAt: DateTime(2026, 10, 10, 18),
    status: CashSessionStatus.open,
    createdAt: DateTime(2026, 10, 10, 18),
    updatedAt: DateTime(2026, 10, 10, 18),
    cashierName: 'Dr Aboubacar Sidiki Camara',
  );

  @override
  bool get hasOpenSession => true;

  @override
  Map<String, dynamic>? get summary => const {
    'session_id': 's1',
    'total_sales': 12500000,
    'total_refunds': 125000,
    'total_deposits': 0,
    'total_withdrawals': 500000,
    'current_expected_cash': 12125000,
  };

  @override
  List<CashMovement> get movements => const [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadCurrentSession(String pharmacyId) async {}
}

/// Vente terminée posée par le test.
class _ReceiptProvider extends POSProvider {
  @override
  bool get isLoading => false;

  @override
  POSSale? get currentSale => POSSale(
    id: 'sale-1',
    pharmacyId: 'ph1',
    saleNumber: 'VTE-20261010-000123',
    cashierId: 'u1',
    totalAmount: 1506000,
    discountAmount: 150600,
    taxAmount: 67770,
    finalAmount: 1423170,
    paymentMethod: 'mobile_money',
    createdAt: DateTime(2026, 10, 10, 21, 4),
    updatedAt: DateTime(2026, 10, 10, 21, 4),
    cashierName: 'Dr Aboubacar Sidiki Camara',
    patientName: 'Mariama Diallo',
    items: [
      POSSaleItem(
        id: 'i1',
        saleId: 'sale-1',
        productId: 'p1',
        productName: 'Amoxicilline acide clavulanique 1g/125mg',
        quantity: 12,
        unitPrice: 125000,
        totalPrice: 1500000,
        createdAt: DateTime(2026, 10, 10, 21, 4),
        prescriptionRequired: true,
        prescriptionChecked: true,
      ),
      POSSaleItem(
        id: 'i2',
        saleId: 'sale-1',
        productId: 'p2',
        productName: 'Paracétamol 500mg',
        quantity: 4,
        unitPrice: 1500,
        totalPrice: 6000,
        createdAt: DateTime(2026, 10, 10, 21, 4),
      ),
    ],
  );
}

class _FakeSearchProvider extends SearchProvider {
  @override
  Future<void> loadProductAvailability(String productId) async {}
}

AuthProvider _pharmacist() => AuthProvider()
  // ignore: invalid_use_of_visible_for_testing_member
  ..pharmacyIdForTesting = 'ph1';

ReservationProvider _reservations({Reservation? selected}) =>
    ReservationProvider()
      // ignore: invalid_use_of_visible_for_testing_member
      ..setStateForTesting(
        reservations: [
          _reservation('r1', ReservationStatus.pending),
          _reservation('r2', ReservationStatus.ready),
        ],
        selected: selected,
      );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
    await loadAppFonts();
  });

  group('composants', () {
    testWidgets('SecondaryButton plus étroit que son libellé', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 96,
              child: SecondaryButton(label: '📋 Historique', onPressed: () {}),
            ),
          ),
        ),
      );
      expect(overflows, isEmpty);
    });

    testWidgets('ResponsiveActions : boutons empilés, libellés entiers', (
      tester,
    ) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ResponsiveActions(
              children: [
                SecondaryButton(label: '📊 Rapport', onPressed: () {}),
                SecondaryButton(label: '📋 Historique', onPressed: () {}),
                PrimaryButton(label: '🔒 Fermer la caisse', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(overflows, isEmpty);
      // L'un sous l'autre, sur toute la largeur : rien n'est coupé.
      final report = tester.getRect(find.byType(SecondaryButton).first);
      final history = tester.getRect(find.byType(SecondaryButton).last);
      expect(history.top, greaterThan(report.bottom));
      expect(report.width, 360 - 48);
      for (final label in [
        '📊 Rapport',
        '📋 Historique',
        '🔒 Fermer la caisse',
      ]) {
        final text = tester.renderObject<RenderParagraph>(find.text(label));
        expect(text.didExceedMaxLines, isFalse, reason: label);
        expect(
          text.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(text.size.width + 0.5),
          reason: '$label est coupé',
        );
      }
    });

    testWidgets('carte de résultat de recherche', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SearchResultCard(
                result: SearchResult(
                  product: _product,
                  availability: _availability,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      expect(overflows, isEmpty);
    });

    testWidgets('position dans la file', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                QueuePositionWidget(position: 12, estimatedMinutes: 135),
                SizedBox(height: 16),
                QueuePositionWidget(
                  position: 0,
                  estimatedMinutes: 0,
                  isReady: true,
                ),
              ],
            ),
          ),
        ),
      );
      expect(overflows, isEmpty);
    });
  });

  group('écrans avec données', () {
    testWidgets('caisse ouverte', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const CashDashboardScreen(),
        wrap: (app) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: _pharmacist()),
            ChangeNotifierProvider<CashProvider>.value(
              value: _OpenCashProvider(),
            ),
          ],
          child: app,
        ),
      );
      expect(overflows, isEmpty);
      expect(find.text('📋 Historique'), findsOneWidget);
    });

    testWidgets('reçu de vente', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const POSReceiptScreen(),
        wrap: (app) => MultiProvider(
          providers: [
            ChangeNotifierProvider<POSProvider>.value(
              value: _ReceiptProvider(),
            ),
          ],
          child: app,
        ),
      );
      expect(overflows, isEmpty);
    });

    testWidgets('fiche produit', (tester) async {
      final search = _FakeSearchProvider()
        // ignore: invalid_use_of_visible_for_testing_member
        ..selectedProductAvailabilityForTesting = _availability;
      final overflows = await pumpAtPhoneWidth(
        tester,
        const ProductDetailScreen(productId: 'p1'),
        wrap: (app) => MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: search),
            ChangeNotifierProvider<ReservationProvider>.value(
              value: ReservationProvider(),
            ),
          ],
          child: app,
        ),
      );
      expect(overflows, isEmpty);
    });

    testWidgets('mes réservations', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const ReservationHistoryScreen(),
        wrap: (app) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider<ReservationProvider>.value(
              value: _reservations(),
            ),
          ],
          child: app,
        ),
      );
      expect(overflows, isEmpty);
    });

    testWidgets('réservation confirmée', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const ReservationConfirmationScreen(),
        wrap: (app) => ChangeNotifierProvider<ReservationProvider>.value(
          value: _reservations(
            selected: _reservation('r1', ReservationStatus.pending),
          ),
          child: app,
        ),
      );
      expect(overflows, isEmpty);
      final afterScroll = await collectOverflows(() async {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2000),
        );
        await pumpFrames(tester);
      });
      expect(afterScroll, isEmpty);
      expect(find.text('Voir l\'historique'), findsOneWidget);
    });

    testWidgets('QR code de retrait', (tester) async {
      final overflows = await pumpAtPhoneWidth(
        tester,
        const ReservationQRScreen(),
        wrap: (app) => ChangeNotifierProvider<ReservationProvider>.value(
          value: _reservations(
            selected: _reservation('r1', ReservationStatus.pending),
          ),
          child: app,
        ),
      );
      expect(overflows, isEmpty);
    });
  });

  // Écrans du pilote montés par leur vraie route, hors ligne : états vides,
  // en chargement ou en erreur réseau.
  group('routes du pilote, hors ligne', () {
    const routes = <(String, UserRole)>[
      ('/login', UserRole.patient),
      ('/register', UserRole.patient),
      ('/dashboard', UserRole.patient),
      ('/search', UserRole.patient),
      ('/cart', UserRole.patient),
      ('/reservations/history', UserRole.patient),
      ('/reservations/checkout', UserRole.patient),
      // « /prescriptions » n'est pas monté ici : hors ligne, son fournisseur
      // lève une erreur réseau non rattrapée, sans rapport avec la mise en
      // page.
      ('/dashboard', UserRole.pharmacien),
      ('/stock', UserRole.pharmacien),
      ('/pharmacy/queue', UserRole.pharmacien),
      ('/pos', UserRole.pharmacien),
      ('/pos/history', UserRole.pharmacien),
      ('/cash', UserRole.pharmacien),
      ('/cash/history', UserRole.pharmacien),
      ('/cash/report', UserRole.pharmacien),
    ];

    for (final (route, role) in routes) {
      testWidgets('$route (${role.name})', (tester) async {
        tester.view.physicalSize = phoneSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Hors ligne, les écrans signalent des erreurs réseau : seules les
        // erreurs de débordement comptent ici.
        final overflows = await collectOverflows(
          ignoreOtherErrors: true,
          () async {
            final router = GoRouter(
              initialLocation: route,
              routes: AppRouter.router.configuration.routes,
            );
            await tester.pumpWidget(
              MultiProvider(
                providers: appProviders(restoreSession: false),
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: PharmaConnectAppTheme.light(),
                  routerConfig: router,
                  builder: (context, child) => AdaptiveTextScale(child: child!),
                ),
              ),
            );
            final auth = tester
                .element(find.byType(AdaptiveTextScale))
                .read<AuthProvider>();
            auth.setRole(role);
            if (role == UserRole.pharmacien) {
              // ignore: invalid_use_of_visible_for_testing_member
              auth.pharmacyIdForTesting =
                  '00000000-0000-0000-0000-000000000001';
            }
            await pumpFrames(tester);
          },
        );

        expect(overflows, isEmpty);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(minutes: 5));
      });
    }
  });
}
