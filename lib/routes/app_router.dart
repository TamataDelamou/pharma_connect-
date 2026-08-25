import 'package:go_router/go_router.dart';

import '../core/services/supabase_service.dart';
import '../core/widgets/screens/placeholder_screen.dart';
// Alerts
import '../modules/alerts/screens/alert_center_screen.dart';
import '../modules/alerts/screens/alert_preferences_screen.dart';
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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = SupabaseService().isAuthenticated;
      final isGoingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/2fa' ||
          state.matchedLocation == '/license-verification';

      if (!isAuth && !isGoingToAuth) return '/login';
      if (isAuth && isGoingToAuth) return '/dashboard';
      return null;
    },
    routes: [
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
          final amount = state.extra is num ? (state.extra as num).toInt() : 0;
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
          return PlaceholderScreen(title: 'Détail de la transaction #$id');
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
      GoRoute(
        path: '/stock/:id',
        name: 'stock-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StockDetailScreen(stockId: id);
        },
      ),
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
      GoRoute(
        path: '/traceability/:id',
        name: 'traceability-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BatchDetailScreen(batchId: id);
        },
      ),
      // Recall
      GoRoute(
        path: '/recall',
        name: 'recall',
        builder: (context, state) => const RecallDashboardScreen(),
      ),
      GoRoute(
        path: '/recall/:id',
        name: 'recall-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecallDetailScreen(recallId: id);
        },
      ),
      GoRoute(
        path: '/recall/create',
        name: 'recall-create',
        builder: (context, state) => const RecallCreateScreen(),
      ),
      // Cold Chain
      GoRoute(
        path: '/coldchain',
        name: 'coldchain',
        builder: (context, state) => const ColdChainDashboardScreen(),
      ),
      GoRoute(
        path: '/coldchain/:id',
        name: 'coldchain-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EquipmentDetailScreen(equipmentId: id);
        },
      ),
      GoRoute(
        path: '/coldchain/add',
        name: 'coldchain-add',
        builder: (context, state) => const EquipmentAddScreen(),
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
    ],
  );
}
