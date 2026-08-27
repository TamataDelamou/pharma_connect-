import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/alerts/providers/alert_provider.dart';
import 'package:pharma_connect/modules/alerts/screens/alert_center_screen.dart';

void main() {
  testWidgets('AlertCenterScreen se construit avec AlertProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AlertProvider(),
          child: const AlertCenterScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertCenterScreen), findsOneWidget);
  });
}
