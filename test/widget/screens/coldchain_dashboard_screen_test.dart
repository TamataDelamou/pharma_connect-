import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/coldchain/providers/coldchain_provider.dart';
import 'package:pharma_connect/modules/coldchain/screens/coldchain_dashboard_screen.dart';

void main() {
  testWidgets(
    'ColdChainDashboardScreen se construit avec ColdChainProvider sans exception',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ColdChainProvider(),
            child: const ColdChainDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(ColdChainDashboardScreen), findsOneWidget);
    },
  );
}
