import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/delivery/providers/delivery_provider.dart';
import 'package:pharma_connect/modules/delivery/screens/delivery_history_screen.dart';

void main() {
  testWidgets(
    'DeliveryHistoryScreen se construit avec DeliveryProvider sans exception',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DeliveryProvider(),
            child: const DeliveryHistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(DeliveryHistoryScreen), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    },
  );
}
