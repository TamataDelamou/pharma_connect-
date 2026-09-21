import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/modules/healthrecord/providers/health_record_provider.dart';
import 'package:pharma_connect/modules/healthrecord/screens/health_record_list_screen.dart';

void main() {
  testWidgets('HealthRecordListScreen shows empty state when no records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => HealthRecordProvider(),
          child: const HealthRecordListScreen(),
        ),
      ),
    );

    // Wait for async load
    await tester.pumpAndSettle();

    expect(find.text('Aucun dossier de santé'), findsOneWidget);
  });
}
