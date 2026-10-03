import 'package:go_router/go_router.dart';

import '../core/services/supabase_service.dart';
import '../core/widgets/screens/not_found_screen.dart';
import 'app_shell.dart'; // C226
// Alerts
import '../modules/alerts/screens/alert_center_screen.dart';
import '../modules/alerts/screens/alert_detail_screen.dart';
import '../modules/alerts/screens/alert_preferences_screen.dart';
import '../modules/alerts/screens/alert_threshold_settings_screen.dart';
import '../modules/auth/screens/license_verification_screen.dart';
// Auth
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/otp_verification_screen.dart';
import '../modules/auth/screens/register_screen.dart';
import '../modules/auth/screens/two_factor_screen.dart';
import '../modules/catalog/screens/catalog_detail_screen.dart';
// Catalog
import '../modules/catalog/screens/catalog_list_screen.dart';
// Dashboard
import '../modules/dashboard/dashboard_screen.dart';
// Delivery
import '../modules/delivery/screens/delivery_history_screen.dart';
import '../modules/delivery/screens/delivery_schedule_screen.dart';
import '../modules/delivery/screens/delivery_tracking_screen.dart';
import '../modules/delivery/screens/driver_dashboard_screen.dart';
import '../modules/payments/screens/dispute_screen.dart';
import '../modules/payments/screens/installment_plan_screen.dart';
// Payments
import '../modules/payments/screens/payment_screen.dart';
import '../modules/payments/screens/reconciliation_screen.dart';
import '../modules/payments/screens/transaction_detail_screen.dart';
import '../modules/payments/screens/transaction_history_screen.dart';
import '../modules/payments/screens/wallet_screen.dart';
import '../modules/prescriptions/screens/patient_history_screen.dart';
import '../modules/prescriptions/screens/prescription_detail_screen.dart';
// Prescriptions
import '../modules/prescriptions/screens/prescription_list_screen.dart';
import '../modules/prescriptions/screens/prescription_preview_screen.dart';
import '../modules/prescriptions/screens/prescription_upload_screen.dart';
// Reservations
import '../modules/reservations/screens/cart_screen.dart';
import '../modules/reservations/screens/pharmacy_queue_screen.dart';
import '../modules/reservations/screens/reservation_checkout_screen.dart';
import '../modules/reservations/screens/reservation_confirmation_screen.dart';
import '../modules/reservations/screens/reservation_history_screen.dart';
import '../modules/reservations/screens/reservation_qr_screen.dart';
import '../modules/search/screens/barcode_scanner_screen.dart';
import '../modules/search/screens/product_detail_screen.dart';
// Search
import '../modules/search/screens/search_screen.dart';
import '../modules/stock/screens/stock_adjustment_screen.dart';
import '../modules/stock/screens/stock_alerts_screen.dart';
import '../modules/stock/screens/stock_detail_screen.dart';
// Stock
import '../modules/stock/screens/stock_list_screen.dart';
import '../modules/stock/screens/stock_movements_screen.dart';

// Traceability
import '../modules/traceability/screens/traceability_dashboard_screen.dart';
import '../modules/traceability/screens/verification_screen.dart';
import '../modules/traceability/screens/batch_detail_screen.dart';
import '../modules/traceability/screens/reception_screen.dart';
import '../modules/traceability/screens/report_screen.dart';

// Recall
import '../modules/recall/screens/recall_dashboard_screen.dart';
import '../modules/recall/screens/recall_detail_screen.dart';
import '../modules/recall/screens/recall_create_screen.dart';

// Cold Chain
import '../modules/coldchain/screens/coldchain_dashboard_screen.dart';
import '../modules/coldchain/screens/equipment_detail_screen.dart';
import '../modules/coldchain/screens/equipment_add_screen.dart';

// Admin
import '../modules/admin/screens/admin_dashboard_screen.dart';
import '../modules/admin/screens/users_management_screen.dart';
import '../modules/admin/screens/pharmacies_management_screen.dart';
import '../modules/admin/screens/audit_log_screen.dart';
import '../modules/admin/screens/system_config_screen.dart';
import '../modules/admin/screens/role_verification_screen.dart';
import '../modules/pharmacy_staff/screens/pharmacy_staff_screen.dart';

// Importer les écrans
import '../modules/healthrecord/screens/health_record_list_screen.dart';
import '../modules/healthrecord/screens/health_record_detail_screen.dart';
import '../modules/healthrecord/screens/health_record_edit_screen.dart';
import '../modules/healthrecord/screens/emergency_access_screen.dart';
import '../modules/healthrecord/screens/health_goal_create_screen.dart'; // C232
import '../modules/healthrecord/screens/health_goals_screen.dart'; // C226

//teleconsult
import '../modules/teleconsult/screens/teleconsult_list_screen.dart';
import '../modules/teleconsult/screens/teleconsult_detail_screen.dart';
import '../modules/teleconsult/screens/teleconsult_booking_screen.dart';

// homecare
import '../modules/homecare/screens/homecare_list_screen.dart';
import '../modules/homecare/screens/homecare_detail_screen.dart';
import '../modules/homecare/screens/homecare_booking_screen.dart';

// triage
import '../modules/triage/screens/triage_list_screen.dart';
import '../modules/triage/screens/triage_detail_screen.dart';
import '../modules/triage/screens/triage_new_screen.dart';
import '../modules/triage/screens/triage_ai_screen.dart';

//family
import '../modules/family/screens/family_list_screen.dart';
import '../modules/family/screens/family_detail_screen.dart';
import '../modules/family/screens/family_new_screen.dart';
import '../modules/family/screens/family_challenge_detail_screen.dart'; // C232
import '../modules/family/screens/family_challenges_screen.dart'; // C226

// professionnals
import '../modules/professionals/screens/professionals_list_screen.dart';
import '../modules/professionals/screens/professional_detail_screen.dart';
import '../modules/professionals/screens/my_professional_profile_screen.dart';

//hospitals
import '../modules/hospitals/screens/hospitals_list_screen.dart';
import '../modules/hospitals/screens/hospital_detail_screen.dart';
import '../modules/hospitals/screens/hospital_wait_times_screen.dart';

// regulator
import '../modules/regulator/screens/adverse_reactions_list_screen.dart';
import '../modules/regulator/screens/adverse_reaction_detail_screen.dart';
import '../modules/regulator/screens/adverse_reaction_report_screen.dart';
// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : écrans inspections/AMM.
import '../modules/regulator/screens/inspections_list_screen.dart';
import '../modules/regulator/screens/inspection_detail_screen.dart';
import '../modules/regulator/screens/inspection_create_screen.dart';
import '../modules/regulator/screens/marketing_authorizations_list_screen.dart';
import '../modules/regulator/screens/marketing_authorization_detail_screen.dart';
import '../modules/regulator/screens/marketing_authorization_create_screen.dart';

//Insurance
import '../modules/insurance/screens/insurance_enrollments_screen.dart';
import '../modules/insurance/screens/enrollment_detail_screen.dart';
// Audit Module 24 (ASR), Étape 2/3 (30/08/2026), ASR-3/ASR-4 : deux écrans
// nouvellement routés — voir les deux GoRoute correspondantes plus bas.
import '../modules/insurance/screens/enrollment_form_screen.dart';
import '../modules/insurance/screens/reimbursement_status_screen.dart';

// analitycs
import '../modules/analytics/screens/analytics_dashboard_screen.dart';
import '../modules/analytics/screens/dashboard_editor_screen.dart';
// TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
// import '../modules/analytics/screens/forecast_screen.dart';
import '../modules/analytics/screens/export_reports_screen.dart';

//support
import '../modules/support/screens/support_list_screen.dart';
import '../modules/support/screens/ticket_detail_screen.dart';
import '../modules/support/screens/new_ticket_screen.dart';
import '../modules/support/screens/chat_bot_screen.dart';
import '../modules/support/screens/bot_history_screen.dart';
import '../modules/support/screens/knowledge_base_screen.dart';
import '../modules/support/screens/escalated_conversations_screen.dart';
import '../modules/support/screens/staff_conversation_screen.dart';

// loyalty
import '../modules/loyalty/screens/loyalty_dashboard_screen.dart';
import '../modules/loyalty/screens/loyalty_pharmacy_select_screen.dart';

//solidarty
import '../modules/solidarity/screens/solidarity_dashboard_screen.dart';
import '../modules/solidarity/screens/solidarity_program_form_screen.dart'; // C232
import '../modules/solidarity/screens/solidarity_program_detail_screen.dart'; // C232

//eprescription
import '../modules/eprescription/screens/eprescription_list_screen.dart';
import '../modules/eprescription/screens/eprescription_detail_screen.dart';
import '../modules/eprescription/screens/eprescription_form_screen.dart';

// Audit Module 20 (DSN), clôture (30/08/2026), arbitrage du porteur du
// projet (D33) : sous-module « Alertes préventives » dé-routé — C95, les 3
// tables qu'il consomme (`preventive_alerts`, `preventive_alert_history`,
// `health_record_vaccinations`/`health_actions`) n'existent nulle part dans
// le projet, chaque appel échouerait à l'exécution. Code Dart (écrans,
// provider, service, modèles) volontairement conservé intact — seul le
// routage est désactivé, pour permettre une reprise directe le jour où le
// schéma manquant sera construit, sans reconstruire l'UI.
// import '../modules/healthrecord/screens/preventive_alerts_screen.dart';
// import '../modules/healthrecord/screens/preventive_alert_create_screen.dart';

// service amelioration
import '../modules/homecare/screens/offline_homecare_screen.dart';
import '../modules/eprescription/screens/scanner_screen.dart';
import '../modules/family/screens/sos_screen.dart';
import '../modules/teleconsult/screens/async_messaging_screen.dart';

// chain (reseau)
import '../modules/chains/screens/groups_list_screen.dart';
import '../modules/chains/screens/group_detail_screen.dart';

//marketplace
import '../modules/marketplace/screens/marketplace_home_screen.dart';
import '../modules/marketplace/screens/offer_detail_screen.dart';
import '../modules/marketplace/screens/order_detail_screen.dart';
import '../modules/marketplace/screens/offer_create_screen.dart';
import '../modules/marketplace/models/b2b_offer.dart';

//financing
import '../modules/financing/screens/financing_dashboard_screen.dart';
import '../modules/financing/screens/request_detail_screen.dart';
import '../modules/financing/screens/request_create_screen.dart';

// iot
import '../modules/iot/screens/iot_dashboard_screen.dart';
import '../modules/iot/screens/device_detail_screen.dart';
import '../modules/iot/screens/device_create_screen.dart';

// business
import '../modules/business/screens/business_dashboard_screen.dart';
import '../modules/business/screens/company_detail_screen.dart';
import '../modules/business/screens/company_create_screen.dart';

//forecast
// TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
// import '../modules/stock/screens/demand_forecast_screen.dart';
// TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
// import '../modules/stock/screens/reorder_recommendation_screen.dart';

// pos
import '../modules/pos/screens/pos_checkout_screen.dart';
import '../modules/pos/screens/pos_receipt_screen.dart';
import '../modules/pos/screens/pos_sales_history_screen.dart';
import '../modules/pos/screens/offline_pos_indicator.dart';

//network
import '../modules/chains/screens/network_dashboard_screen.dart';
import '../modules/chains/screens/network_alerts_screen.dart';
import '../modules/chains/screens/network_roles_screen.dart';
// Diagnostic app_router (19/09/2026) : ces 4 écrans existent bien sous
// lib/modules/chains/screens/ avec la classe attendue et une signature de
// constructeur déjà conforme à leur usage plus bas dans ce fichier — seul
// l'import avait été omis (pas un renommage). Ajoutés pour restaurer la
// compilation, aucun autre changement.
import '../modules/chains/screens/group_create_screen.dart';
import '../modules/chains/screens/group_edit_screen.dart';
import '../modules/chains/screens/transfer_create_screen.dart';
import '../modules/chains/screens/transfer_detail_screen.dart';

//sales
import '../modules/sales/screens/customers_list_screen.dart';
// TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
// import '../modules/sales/screens/customer_detail_screen.dart';
// TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
// import '../modules/sales/screens/customer_create_screen.dart';
// TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
// import '../modules/sales/screens/suppliers_list_screen.dart';
import '../modules/sales/screens/orders_list_screen.dart';
import '../modules/sales/screens/quotations_list_screen.dart';
import '../modules/sales/screens/invoices_list_screen.dart';

//cash
import '../modules/cash/screens/cash_dashboard_screen.dart';
import '../modules/cash/screens/cash_history_screen.dart';
import '../modules/cash/screens/cash_report_screen.dart';

//returns
import '../modules/returns/screens/customer_returns_list_screen.dart';
import '../modules/returns/screens/customer_return_detail_screen.dart';
import '../modules/returns/screens/customer_return_create_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = SupabaseService().isAuthenticated;
      // Audit Module 1 (29/08/2026) : `/2fa` et `/license-verification` sont
      // des étapes POST-authentification (Supabase a déjà validé l'OTP à ce
      // stade, isAuth == true) — les traiter comme des écrans "pré-connexion"
      // au même titre que /login/register/otp les rendait inaccessibles : la
      // seconde règle ci-dessous ("déjà authentifié => /dashboard") renvoyait
      // systématiquement vers /dashboard tout utilisateur qui venait tout
      // juste de s'authentifier, avant même d'avoir pu les afficher. Résultat
      // concret : aucun pharmacien ne pouvait jamais atteindre la
      // vérification de licence (RG-AUT-01), et l'écran 2FA était
      // inatteignable pour quiconque. Seuls /login, /register et /otp sont
      // de vrais écrans "pré-connexion" à bounce une fois authentifié.
      final isEntryAuthScreen =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/otp';

      if (!isAuth && !isEntryAuthScreen) return '/login';
      if (isAuth && isEntryAuthScreen) return '/dashboard';
      return null;
    },
    // C231 : page « Page introuvable » en français, avec un retour qui
    // fonctionne (celle de go_router renvoyait vers `/`, route absente).
    errorBuilder: (context, state) =>
        NotFoundScreen(isAuthenticated: SupabaseService().isAuthenticated),
    routes: [
      // C231 : `/` n'avait pas de route. Non connecté, la redirection
      // ci-dessus envoie déjà vers /login.
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      // ==================== AUTH ====================
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
      GoRoute(
        path: '/2fa',
        name: '2fa',
        builder: (context, state) {
          final userId = state.extra as String? ?? '';
          return TwoFactorScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/license-verification',
        name: 'license-verification',
        builder: (context, state) => const LicenseVerificationScreen(),
      ),

      // C226 : cadre de navigation commun (barre latérale ou barre du haut et
      // tiroir, retour, déconnexion) pour toutes les routes connectées.
      // Restent hors du cadre, ci-dessus : `/`, /login, /register, /otp,
      // /2fa, /license-verification (parcours de connexion) et la page
      // « Page introuvable » (errorBuilder). Aucune route publique : toute
      // adresse hors de ces écrans exige une session (redirect ci-dessus).
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ==================== DASHBOARD ====================
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ==================== CATALOG ====================
          GoRoute(
            path: '/catalog',
            name: 'catalog',
            builder: (context, state) => const CatalogListScreen(),
          ),
          GoRoute(
            path: '/catalog/:id',
            name: 'catalog-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CatalogDetailScreen(productId: id);
            },
          ),

          // ==================== SEARCH ====================
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
          GoRoute(
            path: '/scan',
            name: 'scan',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),

          // ==================== PRESCRIPTIONS ====================
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
          GoRoute(
            path: '/prescriptions/patient/:patientId',
            name: 'prescriptions-patient',
            builder: (context, state) {
              final patientId = state.pathParameters['patientId']!;
              return PatientHistoryScreen(patientId: patientId);
            },
          ),

          // ==================== RESERVATIONS ====================
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

          // ==================== DELIVERY ====================
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
            path: '/deliveries/tracking/:id',
            name: 'deliveries-tracking-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DeliveryTrackingScreen(deliveryId: id);
            },
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

          // ==================== PAYMENTS ====================
          GoRoute(
            path: '/payments',
            name: 'payments',
            builder: (context, state) {
              final amount = state.extra is num
                  ? (state.extra as num).toInt()
                  : 0;
              return PaymentScreen(
                amount: amount,
                reservationId: null,
                deliveryId: null,
              );
            },
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
            path: '/transactions/:id',
            name: 'transaction-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TransactionDetailScreen(transactionId: id);
            },
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

          // ==================== STOCK ====================
          GoRoute(
            path: '/stock',
            name: 'stock',
            builder: (context, state) => const StockListScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026) : balayage complet de ce fichier
          // suite à C69 (Module 17) — `/stock/:id` capturait `/stock/movements`
          // et `/stock/alerts` (déclarées après), même bug de shadowing
          // go_router. Réordonnancement : routes statiques avant route
          // dynamique. Voir le registre pour l'inventaire complet des 14
          // occurrences corrigées dans ce balayage.
          GoRoute(
            path: '/stock/movements',
            name: 'stock-movements',
            builder: (context, state) => const StockMovementsScreen(),
          ),
          GoRoute(
            path: '/stock/alerts',
            name: 'stock-alerts',
            builder: (context, state) => const StockAlertsScreen(),
          ),
          // Audit Module 18 (30/08/2026) : `/stock/forecast` (statique) était
          // déclarée bien plus loin dans ce fichier (section "forecast", après
          // `/stock/adjust/:productId`) — donc jamais atteignable, capturée par
          // `/stock/:id` (id='forecast'). Même bug de shadowing go_router que
          // C69/le balayage transverse Module 18. Relocalisée ici, avant la
          // route dynamique.
          // TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
          // GoRoute(
          //   path: '/stock/forecast',
          //   name: 'stock-forecast',
          //   builder: (context, state) => const DemandForecastScreen(),
          // ),
          GoRoute(
            path: '/stock/:id',
            name: 'stock-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StockDetailScreen(stockId: id);
            },
          ),
          GoRoute(
            path: '/stock/adjust/:productId',
            name: 'stock-adjust',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              final productName = state.extra as String? ?? '';
              return StockAdjustmentScreen(
                productId: productId,
                productName: productName,
              );
            },
          ),
          // Alerts
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertCenterScreen(),
          ),
          GoRoute(
            path: '/alerts/preferences',
            name: 'alert-preferences',
            builder: (context, state) => const AlertPreferencesScreen(),
          ),
          // Audit Module 10 (ALR), arbitrage D15 (29/08/2026) : écran manquant
          // au cahier, construit ce module — voir AlertThresholdSettingsScreen.
          GoRoute(
            path: '/alerts/thresholds',
            name: 'alert-thresholds',
            builder: (context, state) => const AlertThresholdSettingsScreen(),
          ),
          // Audit Module 10 (ALR, 29/08/2026) : écran de détail manquant (voir
          // rapport d'audit) — chemin distinct de /alerts/:id pour ne jamais
          // entrer en conflit avec /alerts/preferences ci-dessus.
          GoRoute(
            path: '/alerts/detail/:id',
            name: 'alert-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AlertDetailScreen(alertId: id);
            },
          ),

          // Traceability
          GoRoute(
            path: '/traceability',
            name: 'traceability',
            builder: (context, state) => const TraceabilityDashboardScreen(),
          ),
          GoRoute(
            path: '/traceability/verify',
            name: 'traceability-verify',
            builder: (context, state) => const VerificationScreen(),
          ),
          // Audit Module 12 (TRC, 29/08/2026), arbitrages D19/D20 : deux écrans
          // manquants au cahier (voir rapport d'audit) — placés avant
          // '/traceability/:id' pour éviter toute ambiguïté de correspondance de
          // route (même précaution que '/stock/forecast/orders' au Module 11).
          GoRoute(
            path: '/traceability/receive',
            name: 'traceability-receive',
            builder: (context, state) => const ReceptionScreen(),
          ),
          GoRoute(
            path: '/traceability/report',
            name: 'traceability-report',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/traceability/:id',
            name: 'traceability-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return BatchDetailScreen(batchId: id);
            },
          ),
          // Recall
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/recall/:id`
          // capturait `/recall/create` (déclarée après) — réordonnancement.
          GoRoute(
            path: '/recall',
            name: 'recall',
            builder: (context, state) => const RecallDashboardScreen(),
          ),
          GoRoute(
            path: '/recall/create',
            name: 'recall-create',
            builder: (context, state) => const RecallCreateScreen(),
          ),
          GoRoute(
            path: '/recall/:id',
            name: 'recall-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecallDetailScreen(recallId: id);
            },
          ),
          // Cold Chain
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/coldchain/:id`
          // capturait `/coldchain/add` (déclarée après) — réordonnancement.
          GoRoute(
            path: '/coldchain',
            name: 'coldchain',
            builder: (context, state) => const ColdChainDashboardScreen(),
          ),
          GoRoute(
            path: '/coldchain/add',
            name: 'coldchain-add',
            builder: (context, state) => const EquipmentAddScreen(),
          ),
          GoRoute(
            path: '/coldchain/:id',
            name: 'coldchain-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EquipmentDetailScreen(equipmentId: id);
            },
          ),
          // Admin
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const UsersManagementScreen(),
          ),
          GoRoute(
            path: '/admin/pharmacies',
            name: 'admin-pharmacies',
            builder: (context, state) => const PharmaciesManagementScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            name: 'admin-audit',
            builder: (context, state) => const AuditLogScreen(),
          ),
          GoRoute(
            path: '/admin/config',
            name: 'admin-config',
            builder: (context, state) => const SystemConfigScreen(),
          ),
          // C214 : validation des rôles déclarés et vérification des professionnels
          // (décision D58). Accès réservé côté serveur à is_gsg_admin().
          GoRoute(
            path: '/admin/verifications',
            name: 'admin-verifications',
            builder: (context, state) => const RoleVerificationScreen(),
          ),
          // Importer les écrans
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/healthrecord/:id`
          // capturait `/healthrecord/edit` (déclarée juste après) ET
          // `/healthrecord/alerts` (déclarée bien plus loin dans ce fichier) —
          // déplacée après ses deux sœurs statiques à 2 segments (voir plus bas,
          // juste après `/healthrecord/alerts`).
          GoRoute(
            path: '/healthrecord',
            name: 'healthrecord',
            builder: (context, state) => const HealthRecordListScreen(),
          ),
          GoRoute(
            path: '/healthrecord/edit',
            name: 'healthrecord-edit',
            builder: (context, state) => const HealthRecordEditScreen(),
          ),
          GoRoute(
            path: '/healthrecord/edit/:id',
            name: 'healthrecord-edit-existing',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HealthRecordEditScreen(recordId: id);
            },
          ),
          // C219 / D63 : accès d'urgence au dossier de santé. Déclarées avant
          // `/healthrecord/:id` (qui capturerait `/healthrecord/emergency-access`).
          // Droits vérifiés côté serveur (lien de soin ou accès d'urgence en cours).
          GoRoute(
            path: '/healthrecord/emergency-access',
            name: 'healthrecord-emergency-access',
            builder: (context, state) => const EmergencyAccessScreen(),
          ),
          // C232 : création d'un objectif santé, écran déjà construit (table
          // health_goals). 3 segments : pas de conflit avec `/healthrecord/:id`.
          // C226 : liste des objectifs santé (écran trouvé par C232), sans
          // contrôle de rôle comme ses routes sœurs ; entrée « Objectifs santé »
          // du menu. 2 segments, déclarée avant `/healthrecord/:id`.
          GoRoute(
            path: '/healthrecord/goals',
            name: 'healthrecord-goals',
            builder: (context, state) => const HealthGoalsScreen(),
          ),
          GoRoute(
            path: '/healthrecord/goals/new',
            name: 'healthrecord-goals-new',
            builder: (context, state) => const HealthGoalCreateScreen(),
          ),
          GoRoute(
            path: '/healthrecord/patient/:patientId',
            name: 'healthrecord-patient',
            builder: (context, state) {
              final patientId = state.pathParameters['patientId']!;
              return HealthRecordListScreen(patientId: patientId);
            },
          ),
          // Route teleconsult
          GoRoute(
            path: '/teleconsult',
            name: 'teleconsult',
            builder: (context, state) => const TeleconsultListScreen(),
          ),
          GoRoute(
            path: '/teleconsult/professional',
            name: 'teleconsult-professional',
            builder: (context, state) =>
                const TeleconsultListScreen(asProfessional: true),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/teleconsult/:id`
          // capturait `/teleconsult/book` (déclarée après) — même bug que celui
          // corrigé pour l'homecare ce module, présent depuis le Module 15
          // (CNS), non détecté à l'époque car cette classe de défaut n'a été
          // identifiée qu'au Module 17 (C69). Réordonnancement.
          GoRoute(
            path: '/teleconsult/book',
            name: 'teleconsult-book',
            builder: (context, state) => const TeleconsultBookingScreen(),
          ),
          GoRoute(
            path: '/teleconsult/:id',
            name: 'teleconsult-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TeleconsultDetailScreen(consultationId: id);
            },
          ),
          // homecare
          GoRoute(
            path: '/homecare',
            name: 'homecare',
            builder: (context, state) => const HomecareListScreen(),
          ),
          GoRoute(
            path: '/homecare/professional',
            name: 'homecare-professional',
            builder: (context, state) =>
                const HomecareListScreen(asProfessional: true),
          ),
          // Audit Module 18 (HOM, 30/08/2026) : `/homecare/:id` était déclarée
          // AVANT `/homecare/book` — même bug de shadowing go_router que C69
          // (Module 17, `/triage/new` capturée par `/triage/:id`), une
          // récurrence exacte du même motif que la recommandation de C69
          // invitait à rechercher ailleurs dans ce fichier. `/homecare/book`
          // était donc systématiquement interceptée par `/homecare/:id`
          // (id='book'), cassant le bouton « Demander une intervention ».
          // Réordonnancement : route statique avant route dynamique.
          GoRoute(
            path: '/homecare/book',
            name: 'homecare-book',
            builder: (context, state) => const HomecareBookingScreen(),
          ),
          GoRoute(
            path: '/homecare/offline',
            name: 'homecare-offline',
            builder: (context, state) => const OfflineHomecareScreen(),
          ),
          GoRoute(
            path: '/homecare/:id',
            name: 'homecare-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HomecareDetailScreen(interventionId: id);
            },
          ),
          // triage
          GoRoute(
            path: '/triage',
            name: 'triage',
            builder: (context, state) => const TriageListScreen(),
          ),
          GoRoute(
            path: '/triage/nurse',
            name: 'triage-nurse',
            builder: (context, state) => const TriageListScreen(isNurse: true),
          ),
          // Audit Module 17 (TRI, 30/08/2026), correctif de compilation/routage
          // (bug 7) : `/triage/new` était déclarée APRÈS `/triage/:id` — go_router
          // évalue les routes sœurs dans l'ordre de déclaration, donc
          // `/triage/new` était systématiquement capturée par `/triage/:id`
          // (id = 'new') avant même d'atteindre sa propre déclaration : le
          // bouton « Nouveau patient » (triage_list_screen.dart) ouvrait en
          // réalité un dossier patient inexistant (« Patient introuvable »),
          // jamais l'écran de création. Route statique remontée avant la route
          // dynamique — seul ordre correct pour des routes sœurs go_router.
          GoRoute(
            path: '/triage/new',
            name: 'triage-new',
            builder: (context, state) => const TriageNewScreen(),
          ),
          GoRoute(
            path: '/triage/:id',
            name: 'triage-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TriageDetailScreen(patientId: id);
            },
          ),
          // Audit Module 17 (TRI, 30/08/2026) : TriageAIScreen existait déjà
          // (règles réelles, non factices — voir le rapport d'audit), mais
          // n'était référencée nulle part : ni route, ni bouton d'accès depuis
          // aucun autre écran du module. Route ajoutée, déclarée après
          // `/triage/:id` (segment statique supplémentaire `/ai`, pas
          // d'ambiguïté avec la route dynamique qui la précède).
          GoRoute(
            path: '/triage/:id/ai',
            name: 'triage-ai',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TriageAIScreen(triagePatientId: id);
            },
          ),
          // family
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/family/:id`
          // capturait `/family/new`, `/family/alerts` (déclarées juste après)
          // ET `/family/sos` (déclarée bien plus loin) — déplacée après ses 3
          // sœurs statiques à 2 segments (voir plus bas, juste après
          // `/family/sos`).
          GoRoute(
            path: '/family',
            name: 'family',
            builder: (context, state) => const FamilyListScreen(),
          ),
          GoRoute(
            path: '/family/new',
            name: 'family-new',
            builder: (context, state) => const FamilyNewScreen(),
          ),
          GoRoute(
            path: '/family/alerts',
            name: 'family-alerts',
            builder: (context, state) => const FamilyListScreen(),
          ),
          // C232 : détail d'un défi familial, écran déjà construit (table
          // family_challenges). 3 segments : pas de conflit avec `/family/:id`.
          // C226 : défis d'une famille (écran trouvé par C232). L'écran exige
          // l'identifiant du lien familial : route sous `/family/:id`, sans entrée
          // de menu globale. Pas de conflit avec `/family/challenges/:id`.
          GoRoute(
            path: '/family/:id/challenges',
            name: 'family-challenges',
            builder: (context, state) => FamilyChallengesScreen(
              familyLinkId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/family/challenges/:id',
            name: 'family-challenge-detail',
            builder: (context, state) => FamilyChallengeDetailScreen(
              challengeId: state.pathParameters['id']!,
            ),
          ),
          // professionnals
          // C222 / D66 : fiche du professionnel connecté (création, correction).
          GoRoute(
            path: '/professional/my-profile',
            name: 'professional-my-profile',
            builder: (context, state) => const MyProfessionalProfileScreen(),
          ),
          GoRoute(
            path: '/professionals',
            name: 'professionals',
            builder: (context, state) => const ProfessionalsListScreen(),
          ),
          GoRoute(
            path: '/professionals/select',
            name: 'professionals-select',
            builder: (context, state) =>
                const ProfessionalsListScreen(isSelectMode: true),
          ),
          GoRoute(
            path: '/professionals/:id',
            name: 'professionals-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProfessionalDetailScreen(professionalId: id);
            },
          ),
          // hospitals
          GoRoute(
            path: '/hospitals',
            name: 'hospitals',
            builder: (context, state) => const HospitalsListScreen(),
          ),
          GoRoute(
            path: '/hospitals/select',
            name: 'hospitals-select',
            builder: (context, state) =>
                const HospitalsListScreen(isSelectMode: true),
          ),
          GoRoute(
            path: '/hospitals/:id',
            name: 'hospitals-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HospitalDetailScreen(hospitalId: id);
            },
          ),
          // Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-2 : cet écran
          // existait (`hospital_wait_times_screen.dart`) mais n'avait jamais été
          // déclaré ici — code mort et totalement inatteignable, indépendamment
          // de son import cassé corrigé dans le même mouvement (voir le rapport
          // d'audit §7.2). Chemin à 3 segments, distinct de `/hospitals/:id`
          // (2 segments) : aucun risque de shadowing avec les 2 routes
          // ci-dessus.
          GoRoute(
            path: '/hospitals/:id/wait-times',
            name: 'hospitals-wait-times',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HospitalWaitTimesScreen(hospitalId: id);
            },
          ),
          // regulator
          GoRoute(
            path: '/regulator',
            name: 'regulator',
            builder: (context, state) => const AdverseReactionsListScreen(),
          ),
          // Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-3 (2e occurrence) :
          // `/regulator/staff` (route dédiée pilotée par le seul paramètre de
          // construction `isRegulator`, jamais lié à un rôle réel) est
          // supprimée. `AdverseReactionsListScreen` s'auto-adapte désormais au
          // rôle réel de l'utilisateur (cf. le fichier de l'écran) via la
          // route `/regulator` unique ci-dessus.
          //
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/regulator/:id`
          // capturait `/regulator/report` (déclarée après) — réordonnancement.
          // Règle conservée et étendue ici : toute route statique sous
          // `/regulator/*` (report, inspections, authorizations, et leurs
          // sous-routes `new` avant `:id`) doit précéder `/regulator/:id`,
          // qui reste la dernière déclaration de ce groupe.
          GoRoute(
            path: '/regulator/report',
            name: 'regulator-report',
            builder: (context, state) => const AdverseReactionReportScreen(),
          ),
          // Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : tables
          // `regulatory_inspections`/`marketing_authorizations`, jusqu'ici
          // orphelines, désormais raccordées à une UI complète.
          GoRoute(
            path: '/regulator/inspections',
            name: 'regulator-inspections',
            builder: (context, state) => const InspectionsListScreen(),
          ),
          GoRoute(
            path: '/regulator/inspections/new',
            name: 'regulator-inspections-new',
            builder: (context, state) => const InspectionCreateScreen(),
          ),
          GoRoute(
            path: '/regulator/inspections/:id',
            name: 'regulator-inspections-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InspectionDetailScreen(inspectionId: id);
            },
          ),
          GoRoute(
            path: '/regulator/authorizations',
            name: 'regulator-authorizations',
            builder: (context, state) =>
                const MarketingAuthorizationsListScreen(),
          ),
          GoRoute(
            path: '/regulator/authorizations/new',
            name: 'regulator-authorizations-new',
            builder: (context, state) =>
                const MarketingAuthorizationCreateScreen(),
          ),
          GoRoute(
            path: '/regulator/authorizations/:id',
            name: 'regulator-authorizations-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MarketingAuthorizationDetailScreen(authorizationId: id);
            },
          ),
          GoRoute(
            path: '/regulator/:id',
            name: 'regulator-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdverseReactionDetailScreen(reactionId: id);
            },
          ),
          // insurance
          GoRoute(
            path: '/insurance',
            name: 'insurance',
            builder: (context, state) => const InsuranceEnrollmentsScreen(),
          ),
          GoRoute(
            path: '/insurance/staff',
            name: 'insurance-staff',
            builder: (context, state) =>
                const InsuranceEnrollmentsScreen(isStaff: true),
          ),
          // Audit Module 24 (ASR), Étape 2/3 (30/08/2026), ASR-3 : route statique
          // ajoutée AVANT '/insurance/enroll/:id' ci-dessous — même patron de
          // correction que '/triage/new' vs '/triage/:id', '/business/company/new'
          // vs '/business/company/:id', etc. (motif de shadowing go_router déjà
          // rencontré et corrigé à de multiples reprises dans ce fichier, voir
          // le balayage transverse C69 du Module 18). Le bouton « Nouveau
          // contrat » (insurance_enrollments_screen.dart) navigue vers
          // '/insurance/enroll/new', jusqu'ici capturé par la route dynamique
          // ci-dessous (id='new', littéral UUID invalide en base — voir le
          // rapport d'audit, constat ASR-3). Nouvel écran dédié :
          // EnrollmentFormScreen.
          GoRoute(
            path: '/insurance/enroll/new',
            name: 'insurance-enroll-new',
            builder: (context, state) => const EnrollmentFormScreen(),
          ),
          GoRoute(
            path: '/insurance/enroll/:id',
            name: 'insurance-enroll-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EnrollmentDetailScreen(enrollmentId: id);
            },
          ),
          // Audit Module 24 (ASR), Étape 2/3 (30/08/2026), ASR-4 : route
          // manquante ajoutée pour ReimbursementStatusScreen — jusqu'ici
          // totalement inatteignable, aucune route ne la référençait nulle part
          // (voir le rapport d'audit, constat ASR-3/ASR-4). Segment
          // '/insurance/reimbursement/...', distinct de
          // '/insurance/enroll/...' ci-dessus : aucun risque de shadowing entre
          // les deux familles de routes du module.
          GoRoute(
            path: '/insurance/reimbursement/:claimId',
            name: 'insurance-reimbursement-detail',
            builder: (context, state) {
              final claimId = state.pathParameters['claimId']!;
              return ReimbursementStatusScreen(claimId: claimId);
            },
          ),
          // analitycs
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsDashboardScreen(),
          ),
          // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-6 : DashboardEditorScreen
          // (personnalisation du tableau de bord, cf. BI-7) et ForecastScreen
          // (prévisions IA) étaient toutes deux entièrement construites et
          // fonctionnelles côté widget, mais aucune route ne les référençait nulle
          // part dans ce fichier — inatteignables depuis l'application, même en
          // tapant l'URL. Chemins statiques sous /analytics/... : aucun risque de
          // shadowing avec la route racine ci-dessus (motif C69, déjà rencontré à
          // de multiples reprises dans ce fichier).
          GoRoute(
            path: '/analytics/dashboard-editor',
            name: 'analytics-dashboard-editor',
            builder: (context, state) => const DashboardEditorScreen(),
          ),
          // TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
          // GoRoute(
          //   path: '/analytics/forecast',
          //   name: 'analytics-forecast',
          //   builder: (context, state) => const ForecastScreen(),
          // ),
          // BI-8 : livrable de ce correctif — écran d'export de rapports
          // agrégés (CSV), sans données de santé nominatives, scopé aux mêmes
          // vues/fonctions "_scoped" que AnalyticsDashboardScreen (BI-1/BI-2).
          GoRoute(
            path: '/analytics/export',
            name: 'analytics-export',
            builder: (context, state) => const ExportReportsScreen(),
          ),
          // support
          GoRoute(
            path: '/support',
            name: 'support',
            builder: (context, state) => const SupportListScreen(),
          ),
          // C161 : `isStaff` n'est plus impose par la route -- SupportListScreen
          // le determine lui-meme depuis AuthProvider.isGsgAdmin (voir le
          // widget). La route est conservee comme alias pour ne pas casser un
          // lien profond existant.
          GoRoute(
            path: '/support/staff',
            name: 'support-staff',
            builder: (context, state) => const SupportListScreen(),
          ),
          // C158 : reconstruit en ecran reel (historique des conversations bot
          // du patient courant) plutot que retire -- voir BotHistoryScreen.
          GoRoute(
            path: '/support/bot/history',
            name: 'support-bot-history',
            builder: (context, state) => const BotHistoryScreen(),
          ),
          // C158 : route manquante vers ChatBotScreen, ecran jusqu'ici orphelin.
          GoRoute(
            path: '/support/chat',
            name: 'support-chat',
            builder: (context, state) => const ChatBotScreen(),
          ),
          // Base de connaissances (fonctionnalite cahier absente jusqu'ici).
          GoRoute(
            path: '/support/knowledge-base',
            name: 'support-knowledge-base',
            builder: (context, state) => const KnowledgeBaseScreen(),
          ),
          // C159 : ecran staff listant les conversations bot escaladees.
          GoRoute(
            path: '/support/staff/conversations',
            name: 'support-staff-conversations',
            builder: (context, state) => const EscalatedConversationsScreen(),
          ),
          GoRoute(
            path: '/support/staff/conversations/:id',
            name: 'support-staff-conversation-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StaffConversationScreen(conversationId: id);
            },
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/support/:id`
          // capturait `/support/new` (déclarée après) — réordonnancement. Les
          // routes statiques ci-dessus restent, pour la même raison, toutes
          // déclarées avant `/support/:id`.
          GoRoute(
            path: '/support/new',
            name: 'support-new',
            builder: (context, state) => const NewTicketScreen(),
          ),
          GoRoute(
            path: '/support/:id',
            name: 'support-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TicketDetailScreen(ticketId: id);
            },
          ),
          // loyalty
          // Audit Module 16 (FID, 29/08/2026) : '/loyalty' pointait directement
          // vers LoyaltyDashboardScreen sans jamais fournir de pharmacyId — le
          // paramètre optionnel retombait alors sur la chaîne littérale
          // 'default_pharmacy', ni un UUID ni une officine réelle (toute
          // requête réelle échouait, « invalid input syntax for type uuid »).
          // '/loyalty' route désormais vers le sélecteur d'officine ;
          // '/loyalty/:pharmacyId' (nouveau) vers le tableau de bord lui-même.
          GoRoute(
            path: '/loyalty',
            name: 'loyalty',
            builder: (context, state) => const LoyaltyPharmacySelectScreen(),
          ),
          GoRoute(
            path: '/loyalty/:pharmacyId',
            name: 'loyalty-dashboard',
            builder: (context, state) {
              final pharmacyId = state.pathParameters['pharmacyId']!;
              return LoyaltyDashboardScreen(pharmacyId: pharmacyId);
            },
          ),
          // solidarity
          GoRoute(
            path: '/solidarity',
            name: 'solidarity',
            builder: (context, state) => const SolidarityDashboardScreen(),
          ),
          GoRoute(
            path: '/solidarity/staff',
            name: 'solidarity-staff',
            builder: (context, state) =>
                const SolidarityDashboardScreen(isStaff: true),
          ),
          // C232 : formulaire et détail d'un programme, déjà construits. `new`
          // avant `:id`. Création et suppression réservées à l'administration
          // GSG (RLS is_gsg_admin()) ; les écrans n'affichent ces actions qu'à
          // elle.
          GoRoute(
            path: '/solidarity/program/new',
            name: 'solidarity-program-new',
            builder: (context, state) => const SolidarityProgramFormScreen(),
          ),
          GoRoute(
            path: '/solidarity/program/:id',
            name: 'solidarity-program-detail',
            builder: (context, state) => SolidarityProgramDetailScreen(
              programId: state.pathParameters['id']!,
              isStaff: state.extra as bool? ?? false,
            ),
          ),
          // eprescription
          GoRoute(
            path: '/eprescription',
            name: 'eprescription',
            builder: (context, state) => const EPrescriptionListScreen(),
          ),
          GoRoute(
            path: '/eprescription/doctor',
            name: 'eprescription-doctor',
            builder: (context, state) =>
                const EPrescriptionListScreen(isDoctor: true),
          ),
          GoRoute(
            path: '/eprescription/pharmacy',
            name: 'eprescription-pharmacy',
            builder: (context, state) =>
                const EPrescriptionListScreen(isPharmacy: true),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/eprescription/:id`
          // capturait `/eprescription/scan` (déclarée bien plus loin dans ce
          // fichier) — déplacée après cette sœur statique (voir plus bas, juste
          // après `/eprescription/scan`).
          // Audit Module 20 (DSN), clôture (30/08/2026), D33 : route dé-routée,
          // voir le commentaire complet à l'import ci-dessus.
          // GoRoute(
          //   path: '/healthrecord/alerts',
          //   name: 'healthrecord-alerts',
          //   builder: (context, state) => const PreventiveAlertsScreen(),
          // ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/healthrecord/:id`
          // relocalisée ici (voir le commentaire à sa déclaration d'origine,
          // section healthrecord) — désormais après ses deux sœurs statiques à
          // 2 segments (`/healthrecord/edit`, `/healthrecord/alerts`).
          GoRoute(
            path: '/healthrecord/:id',
            name: 'healthrecord-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HealthRecordDetailScreen(recordId: id);
            },
          ),
          // Audit Module 20 (DSN), clôture (30/08/2026), D33 : routes dé-routées
          // avec `/healthrecord/alerts` ci-dessus, même motif (C95).
          // GoRoute(
          //   path: '/healthrecord/alerts/new',
          //   name: 'healthrecord-alerts-new',
          //   builder: (context, state) => const PreventiveAlertCreateScreen(),
          // ),
          // GoRoute(
          //   path: '/healthrecord/alerts/edit/:id',
          //   name: 'healthrecord-alerts-edit',
          //   builder: (context, state) {
          //     final id = state.pathParameters['id']!;
          //     return PreventiveAlertCreateScreen(alertId: id);
          //   },
          // ),
          // service amelioration
          // Audit Module 18 (30/08/2026) : '/homecare/offline' (statique) a été
          // relocalisée plus haut dans ce fichier, avant '/homecare/:id' — elle
          // était déclarée ici, bien après lui, donc jamais atteignable
          // (capturée par id='offline'). Voir le registre pour l'inventaire
          // complet du balayage transverse.
          GoRoute(
            path: '/eprescription/scan',
            name: 'eprescription-scan',
            builder: (context, state) => const ScannerScreen(),
          ),
          // PRE-5 (audit Module 25, Étape 2/3, 30/08/2026) : le bouton
          // « Nouvelle prescription » (`eprescription_list_screen.dart`)
          // naviguait vers `/eprescription/new`, route jamais déclarée — captée
          // par la route dynamique `/eprescription/:id` (id='new', UUID
          // invalide), même classe de défaut que ASR-3 (Module 24). Nouvelle
          // route statique ajoutée AVANT `/eprescription/:id`, sur le modèle des
          // sœurs statiques déjà réordonnancées ici (balayage C69, Module 18).
          GoRoute(
            path: '/eprescription/new',
            name: 'eprescription-new',
            builder: (context, state) => const EPrescriptionFormScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 :
          // `/eprescription/:id` relocalisée ici (voir le commentaire à sa
          // déclaration d'origine, section eprescription) — désormais après ses
          // sœurs statiques `/eprescription/scan` et `/eprescription/new`.
          GoRoute(
            path: '/eprescription/:id',
            name: 'eprescription-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EPrescriptionDetailScreen(prescriptionId: id);
            },
          ),
          GoRoute(
            path: '/family/sos',
            name: 'family-sos',
            builder: (context, state) => const SOSScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/family/:id`
          // relocalisée ici (voir le commentaire à sa déclaration d'origine,
          // section family) — désormais après ses 3 sœurs statiques à 2
          // segments (`/family/new`, `/family/alerts`, `/family/sos`).
          GoRoute(
            path: '/family/:id',
            name: 'family-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return FamilyDetailScreen(linkId: id);
            },
          ),
          GoRoute(
            path: '/teleconsult/messages/:patientId/:professionalId',
            name: 'teleconsult-messages',
            builder: (context, state) {
              final params = state.pathParameters;
              return AsyncMessagingScreen(
                patientId: params['patientId']!,
                professionalId: params['professionalId']!,
              );
            },
          ),
          // chain (reseaux)
          GoRoute(
            path: '/chains',
            name: 'chains',
            builder: (context, state) => const GroupsListScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 :
          // `/chains/group/:id` capturait `/chains/group/new` (déclarée après,
          // même profondeur à 3 segments) — réordonnancement.
          GoRoute(
            path: '/chains/group/new',
            name: 'chains-group-new',
            builder: (context, state) =>
                const GroupCreateScreen(), // à implémenter
          ),
          GoRoute(
            path: '/chains/group/:id',
            name: 'chains-group-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return GroupDetailScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/chains/group/edit/:id',
            name: 'chains-group-edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return GroupEditScreen(groupId: id); // à implémenter
            },
          ),
          GoRoute(
            path: '/chains/transfer/new',
            name: 'chains-transfer-new',
            builder: (context, state) =>
                const TransferCreateScreen(), // à implémenter
          ),
          GoRoute(
            path: '/chains/transfer/:id',
            name: 'chains-transfer-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TransferDetailScreen(transferId: id); // à implémenter
            },
          ),
          // Audit Module 13 (B2B, 29/08/2026) : ces six routes marketplace
          // (import compris ci-dessus) étaient chacune déclarées deux fois à
          // l'identique — même `name` GoRoute répété, ce que go_router rejette
          // en levant une exception à l'initialisation du routeur (noms de
          // route non uniques), empêchant purement et simplement l'application
          // de démarrer. Dédupliqué. Même motif de duplication, laissé hors
          // périmètre à l'époque pour les imports et routes `financing`/`iot`
          // plus bas, corrigé lors de l'audit Module 14 (FIN, 29/08/2026) —
          // les six routes financing/iot (imports compris) étaient elles aussi
          // déclarées deux fois à l'identique, même défaut de démarrage.
          //
          // Nouvelle route `/marketplace/offer/edit/:id` : le bouton
          // « Modifier » de offer_detail_screen.dart était un no-op (voir
          // rapport d'audit) — corrigé en réutilisant OfferCreateScreen en mode
          // édition (offre passée via `state.extra`, jamais rechargée par id
          // pour rester cohérent avec le patron déjà utilisé par
          // '/stock/adjust/:productId' plus haut).
          GoRoute(
            path: '/marketplace',
            name: 'marketplace',
            builder: (context, state) => const MarketplaceHomeScreen(),
          ),
          GoRoute(
            path: '/marketplace/offer/new',
            name: 'marketplace-offer-new',
            builder: (context, state) => const OfferCreateScreen(),
          ),
          GoRoute(
            path: '/marketplace/offer/edit/:id',
            name: 'marketplace-offer-edit',
            builder: (context, state) {
              final offer = state.extra as B2BOffer?;
              return OfferCreateScreen(existingOffer: offer);
            },
          ),
          GoRoute(
            path: '/marketplace/offer/:id',
            name: 'marketplace-offer-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OfferDetailScreen(offerId: id);
            },
          ),
          GoRoute(
            path: '/marketplace/order/:id',
            name: 'marketplace-order-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: id);
            },
          ),
          //financing
          GoRoute(
            path: '/financing',
            name: 'financing',
            builder: (context, state) => const FinancingDashboardScreen(),
          ),
          GoRoute(
            path: '/financing/:id',
            name: 'financing-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RequestDetailScreen(requestId: id);
            },
          ),
          GoRoute(
            path: '/financing/request/new',
            name: 'financing-request-new',
            builder: (context, state) => const RequestCreateScreen(),
          ),
          // iot
          GoRoute(
            path: '/iot',
            name: 'iot',
            builder: (context, state) => const IotDashboardScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 : `/iot/device/:id`
          // capturait `/iot/device/new` (déclarée après, même profondeur à 3
          // segments) — réordonnancement.
          GoRoute(
            path: '/iot/device/new',
            name: 'iot-device-new',
            builder: (context, state) => const DeviceCreateScreen(),
          ),
          GoRoute(
            path: '/iot/device/:id',
            name: 'iot-device-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DeviceDetailScreen(deviceId: id);
            },
          ),
          GoRoute(
            path: '/iot/device/edit/:id',
            name: 'iot-device-edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DeviceCreateScreen(deviceId: id);
            },
          ),
          // business
          GoRoute(
            path: '/business',
            name: 'business',
            builder: (context, state) => const BusinessDashboardScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 :
          // `/business/company/:id` capturait `/business/company/new` (déclarée
          // après, même profondeur à 3 segments) — réordonnancement.
          GoRoute(
            path: '/business/company/new',
            name: 'business-company-new',
            builder: (context, state) => const CompanyCreateScreen(),
          ),
          GoRoute(
            path: '/business/company/:id',
            name: 'business-company-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CompanyDetailScreen(companyId: id);
            },
          ),
          GoRoute(
            path: '/business/company/edit/:id',
            name: 'business-company-edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CompanyCreateScreen(companyId: id);
            },
          ),
          // Audit Module 11 (29/08/2026), arbitrage D17 : nouvel écran « Commande
          // recommandée » — placé avant '/stock/forecast/:productId' pour éviter
          // toute ambiguïté de correspondance de route ('orders' ne doit jamais
          // être interprété comme un productId).
          // Audit Module 18 (30/08/2026) : '/stock/forecast' (route statique,
          // ancien alias inutilisé du "//forecast") déplacée avant '/stock/:id'
          // — voir plus haut dans ce fichier — car elle était déclarée bien
          // après lui et donc jamais atteignable.
          // TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
          // GoRoute(
          //   path: '/stock/forecast/orders',
          //   name: 'stock-forecast-orders',
          //   builder: (context, state) => const ReorderRecommendationScreen(),
          // ),
          // TODO PharmaConnect: écran non construit, cluster forecast différé (C188 / D54)
          // GoRoute(
          //   path: '/stock/forecast/:productId',
          //   name: 'stock-forecast-product',
          //   builder: (context, state) {
          //     final id = state.pathParameters['productId']!;
          //     return DemandForecastScreen(productId: id);
          //   },
          // ),
          // pos
          GoRoute(
            path: '/pos',
            name: 'pos',
            builder: (context, state) => const POSCheckoutScreen(),
          ),
          // C209 : personnel de l'officine (invitations, retrait, départ).
          // Réservé au titulaire côté serveur (pharmacy_list_staff).
          GoRoute(
            path: '/pharmacy/staff',
            name: 'pharmacy-staff',
            builder: (context, state) => const PharmacyStaffScreen(),
          ),
          GoRoute(
            path: '/pos/receipt/:id',
            name: 'pos-receipt',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return POSReceiptScreen(saleId: id);
            },
          ),
          GoRoute(
            path: '/pos/history',
            name: 'pos-history',
            builder: (context, state) => const POSSalesHistoryScreen(),
          ),
          //network
          GoRoute(
            path: '/network',
            name: 'network',
            builder: (context, state) => const NetworkDashboardScreen(),
          ),
          GoRoute(
            path: '/network/group/:id',
            name: 'network-group',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return NetworkDashboardScreen(groupId: id);
            },
          ),
          GoRoute(
            path: '/network/alerts',
            name: 'network-alerts',
            builder: (context, state) => const NetworkAlertsScreen(),
          ),
          GoRoute(
            path: '/network/roles',
            name: 'network-roles',
            builder: (context, state) => const NetworkRolesScreen(),
          ),
          // sales
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) => const CustomersListScreen(),
          ),
          GoRoute(
            path: '/sales/customers',
            name: 'sales-customers',
            builder: (context, state) => const CustomersListScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 :
          // `/sales/customer/:id` capturait `/sales/customer/new` (déclarée
          // après, même profondeur à 3 segments) — réordonnancement.
          // TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
          // GoRoute(
          //   path: '/sales/customer/new',
          //   name: 'sales-customer-new',
          //   builder: (context, state) => const CustomerCreateScreen(),
          // ),
          // TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
          // GoRoute(
          //   path: '/sales/customer/:id',
          //   name: 'sales-customer-detail',
          //   builder: (context, state) {
          //     final id = state.pathParameters['id']!;
          //     return CustomerDetailScreen(customerId: id);
          //   },
          // ),
          // TODO PharmaConnect: écran non cadré, cluster hors-cahier, cf. Etape1 §1.5 — audit dédié requis avant réintégration.
          // GoRoute(
          //   path: '/sales/suppliers',
          //   name: 'sales-suppliers',
          //   builder: (context, state) => const SuppliersListScreen(),
          // ),
          GoRoute(
            path: '/sales/orders',
            name: 'sales-orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: '/sales/quotations',
            name: 'sales-quotations',
            builder: (context, state) => const QuotationsListScreen(),
          ),
          GoRoute(
            path: '/sales/invoices',
            name: 'sales-invoices',
            builder: (context, state) => const InvoicesListScreen(),
          ),
          //cash
          GoRoute(
            path: '/cash',
            name: 'cash',
            builder: (context, state) => const CashDashboardScreen(),
          ),
          GoRoute(
            path: '/cash/history',
            name: 'cash-history',
            builder: (context, state) => const CashHistoryScreen(),
          ),
          GoRoute(
            path: '/cash/report',
            name: 'cash-report',
            builder: (context, state) => const CashReportScreen(),
          ),
          //returns
          GoRoute(
            path: '/returns',
            name: 'returns',
            builder: (context, state) => const CustomerReturnsListScreen(),
          ),
          GoRoute(
            path: '/returns/customer',
            name: 'returns-customer',
            builder: (context, state) => const CustomerReturnsListScreen(),
          ),
          // Audit Module 18 (HOM, 30/08/2026), balayage C69 :
          // `/returns/customer/:id` capturait `/returns/customer/new` (déclarée
          // après, même profondeur à 3 segments) — réordonnancement. Dernière
          // des 14 occurrences trouvées lors de ce balayage complet.
          GoRoute(
            path: '/returns/customer/new',
            name: 'returns-customer-new',
            builder: (context, state) => const CustomerReturnCreateScreen(),
          ),
          GoRoute(
            path: '/returns/customer/:id',
            name: 'returns-customer-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerReturnDetailScreen(returnId: id);
            },
          ),
        ],
      ),
    ],
  );
}
