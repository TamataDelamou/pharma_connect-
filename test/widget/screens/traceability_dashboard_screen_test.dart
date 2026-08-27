import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/traceability/providers/traceability_provider.dart';
import 'package:pharma_connect/modules/traceability/screens/traceability_dashboard_screen.dart';

void main() {
  testWidgets(
    'TraceabilityDashboardScreen se construit avec TraceabilityProvider sans exception',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => TraceabilityProvider(),
            child: const TraceabilityDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(TraceabilityDashboardScreen), findsOneWidget);
    },
  );
}
