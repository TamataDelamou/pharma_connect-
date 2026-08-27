import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/stock/providers/stock_provider.dart';
import 'package:pharma_connect/modules/stock/screens/stock_list_screen.dart';

void main() {
  testWidgets('StockListScreen se construit avec StockProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => StockProvider(),
          child: const StockListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(StockListScreen), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
