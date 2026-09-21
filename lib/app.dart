import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/dashboard/providers/dashboard_provider.dart';
import 'modules/search/providers/search_provider.dart';
import 'modules/prescriptions/providers/prescription_provider.dart';
import 'modules/reservations/providers/reservation_provider.dart';
import 'modules/delivery/providers/delivery_provider.dart';
import 'modules/payments/providers/payment_provider.dart';
import 'modules/catalog/providers/catalog_provider.dart';
import 'modules/admin/providers/admin_provider.dart';
import 'modules/alerts/providers/alert_provider.dart';
import 'modules/coldchain/providers/coldchain_provider.dart';
import 'modules/recall/providers/recall_provider.dart';
import 'modules/stock/providers/stock_provider.dart';
import 'modules/traceability/providers/traceability_provider.dart';
import 'modules/healthrecord/providers/health_record_provider.dart';
import 'modules/teleconsult/providers/teleconsult_provider.dart';
import 'modules/homecare/providers/homecare_provider.dart';
import 'modules/triage/providers/triage_provider.dart';
import 'modules/triage/providers/triage_ai_provider.dart';
import 'modules/family/providers/family_provider.dart';
import 'modules/professionals/providers/professionals_provider.dart';
import 'modules/hospitals/providers/hospitals_provider.dart';
import 'modules/regulator/providers/regulator_provider.dart';
import 'modules/regulator/providers/inspection_provider.dart';
import 'modules/regulator/providers/marketing_authorization_provider.dart';
import 'modules/insurance/providers/insurance_provider.dart';
import 'modules/analytics/providers/analytics_provider.dart';
import 'modules/analytics/providers/dashboard_customization_provider.dart';
import 'modules/analytics/providers/forecast_provider.dart' as bi;
import 'modules/support/providers/support_provider.dart';
import 'modules/loyalty/providers/loyalty_provider.dart';
import 'modules/solidarity/providers/solidarity_provider.dart';
import 'modules/eprescription/providers/eprescription_provider.dart';
import 'modules/healthrecord/providers/preventive_alert_provider.dart';
import 'modules/homecare/providers/offline_homecare_provider.dart';
import 'modules/chains/providers/chain_provider.dart';
import 'modules/marketplace/providers/marketplace_provider.dart';
import 'modules/financing/providers/financing_provider.dart';
import 'modules/iot/providers/iot_provider.dart';
import 'modules/business/providers/business_provider.dart';
import 'modules/stock/providers/forecast_provider.dart';
import 'modules/pos/providers/pos_provider.dart';
import 'modules/chains/providers/network_admin_provider.dart';
import 'modules/sales/providers/sales_provider.dart';
import 'modules/cash/providers/cash_provider.dart';
import 'modules/returns/providers/returns_provider.dart';
import 'modules/pos/providers/offline_pos_provider.dart';

class PharmaConnectApp extends StatelessWidget {
  const PharmaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ColdChainProvider()),
        ChangeNotifierProvider(create: (_) => RecallProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => TraceabilityProvider()),
        ChangeNotifierProvider(create: (_) => TeleconsultProvider()),
        ChangeNotifierProvider(create: (_) => HomecareProvider()),
        ChangeNotifierProvider(create: (_) => TriageProvider()),
        // Audit Module 17 (TRI, 30/08/2026) : TriageAIScreen appelait déjà
        // `context.watch<TriageAIProvider>()` (voir triage_ai_screen.dart),
        // mais ce provider n'était déclaré nulle part dans l'arbre
        // `MultiProvider` — `ProviderNotFoundException` au premier rendu de
        // l'écran, un défaut distinct des bugs de compilation (le projet
        // compile, mais l'écran plante à l'exécution).
        ChangeNotifierProvider(create: (_) => TriageAIProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalsProvider()),
        ChangeNotifierProvider(create: (_) => HospitalsProvider()),
        ChangeNotifierProvider(create: (_) => RegulatorProvider()),
        ChangeNotifierProvider(create: (_) => InsuranceProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-6 : DashboardEditorScreen
        // et ForecastScreen appelaient déjà context.read/watch<...>() sur ces
        // deux providers (voir dashboard_editor_screen.dart/forecast_screen.dart)
        // sans qu'aucun des deux ne soit jamais déclaré dans cet arbre
        // MultiProvider — ProviderNotFoundException garantie au premier rendu,
        // même motif que TriageAIProvider (Module 17). Alias `bi.` sur
        // ForecastProvider : ce module importe déjà un `forecast_provider.dart`
        // distinct (module stock, `StockForecastProvider`) plus haut — préfixe
        // défensif pour exclure tout risque de collision de nom, ce fichier
        // n'étant pas dans le périmètre de cet audit.
        ChangeNotifierProvider(create: (_) => DashboardCustomizationProvider()),
        ChangeNotifierProvider(create: (_) => bi.ForecastProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => SolidarityProvider()),
        ChangeNotifierProvider(create: (_) => EPrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => PreventiveAlertProvider()),
        ChangeNotifierProvider(create: (_) => OfflineHomecareProvider()),
        ChangeNotifierProvider(create: (_) => ChainProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => FinancingProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => StockForecastProvider()),
        ChangeNotifierProvider(create: (_) => POSProvider()),
        ChangeNotifierProvider(create: (_) => NetworkAdminProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => CashProvider()),
        ChangeNotifierProvider(create: (_) => ReturnsProvider()),
        ChangeNotifierProvider(create: (_) => OfflinePOSProvider()),
        // ... tous les autres providers existants
        ChangeNotifierProvider(
          create: (_) => HealthRecordProvider(),
        ), // <-- AJOUT
        // Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : tables
        // regulatory_inspections/marketing_authorizations, jusqu'ici
        // orphelines, désormais raccordées (voir app_router.dart).
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(create: (_) => MarketingAuthorizationProvider()),
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
