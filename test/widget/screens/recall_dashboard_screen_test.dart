import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/recall/providers/recall_provider.dart';
import 'package:pharma_connect/modules/recall/screens/recall_dashboard_screen.dart';

void main() {
  testWidgets('RecallDashboardScreen se construit avec RecallProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => RecallProvider(),
          child: const RecallDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(RecallDashboardScreen), findsOneWidget);
  });
}
