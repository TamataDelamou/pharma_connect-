import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_history_screen.dart';

void main() {
  testWidgets(
    'ReservationHistoryScreen se construit avec ReservationProvider sans exception',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ReservationProvider(),
            child: const ReservationHistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(ReservationHistoryScreen), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    },
  );
}
