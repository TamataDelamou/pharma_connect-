import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';
import 'package:pharma_connect/modules/catalog/screens/catalog_list_screen.dart';

void main() {
  testWidgets('CatalogListScreen se construit avec CatalogProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => CatalogProvider(),
          child: const CatalogListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(CatalogListScreen), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
