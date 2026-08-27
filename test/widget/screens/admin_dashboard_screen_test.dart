import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/admin/providers/admin_provider.dart';
import 'package:pharma_connect/modules/admin/screens/admin_dashboard_screen.dart';

void main() {
  testWidgets('AdminDashboardScreen se construit avec AdminProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });
}
