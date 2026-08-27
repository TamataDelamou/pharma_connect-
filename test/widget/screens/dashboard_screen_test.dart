import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';
import 'package:pharma_connect/modules/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen se construit avec DashboardProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
