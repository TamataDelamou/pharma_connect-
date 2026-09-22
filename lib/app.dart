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
import 'modules/teleconsult/providers/teleconsult_provider.dart';
import 'modules/marketplace/providers/marketplace_provider.dart';
import 'modules/financing/providers/financing_provider.dart';
import 'modules/triage/providers/triage_provider.dart';
import 'modules/triage/providers/triage_ai_provider.dart';
import 'modules/homecare/providers/homecare_provider.dart';
import 'modules/homecare/providers/offline_homecare_provider.dart';
import 'modules/professionals/providers/professionals_provider.dart';
import 'modules/healthrecord/providers/health_record_provider.dart';
import 'modules/healthrecord/providers/preventive_alert_provider.dart';
import 'modules/healthrecord/providers/health_goal_provider.dart';
import 'modules/iot/providers/iot_provider.dart';
import 'modules/loyalty/providers/loyalty_provider.dart';
import 'modules/loyalty/providers/badge_provider.dart';
import 'modules/loyalty/providers/personalized_reward_provider.dart';

class PharmaConnectApp extends StatelessWidget {
  const PharmaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => FinancingProvider()),
        ChangeNotifierProvider(create: (_) => TriageProvider()),
        // Audit Module 17 (TRI, 30/08/2026) : TriageAIScreen appelle deja
        // context.watch<TriageAIProvider>() sans que ce provider ne soit
        // jamais declare ici -> ProviderNotFoundException garantie a
        // l'ouverture de l'ecran (confirme par grep avant ajout).
        ChangeNotifierProvider(create: (_) => TriageAIProvider()),
        ChangeNotifierProvider(create: (_) => HomecareProvider()),
        ChangeNotifierProvider(create: (_) => OfflineHomecareProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalsProvider()),
        ChangeNotifierProvider(create: (_) => HealthRecordProvider()),
        ChangeNotifierProvider(create: (_) => PreventiveAlertProvider()),
        // Oubli du lot Module 20/DSN : health_goals_screen.dart,
        // health_goal_create_screen.dart et health_milestones_screen.dart
        // appellent deja context.watch/read<HealthGoalProvider>() sans que
        // ce provider ne soit jamais declare ici -> ProviderNotFoundException
        // garantie a l'ouverture de ces 3 ecrans (trouve en verifiant la
        // migration gamification_health, corrige au meme geste).
        ChangeNotifierProvider(create: (_) => HealthGoalProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
        // Module 16/FID (loyalty), deja sur main avant le reset (commit
        // 35c0756) mais jamais cable ici : badges_gallery_screen.dart,
        // leaderboard_screen.dart, loyalty_dashboard_screen.dart,
        // loyalty_pharmacy_select_screen.dart et
        // personalized_rewards_screen.dart appellent deja
        // context.watch/read<LoyaltyProvider|BadgeProvider|
        // PersonalizedRewardProvider>() -> ProviderNotFoundException
        // garantie sur tout le module, trouve en verifiant les 3 migrations
        // gamification/recompenses manquantes, corrige au meme geste.
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => PersonalizedRewardProvider()),
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
