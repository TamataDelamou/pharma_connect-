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
