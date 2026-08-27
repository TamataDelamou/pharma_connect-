import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/prescriptions/providers/prescription_provider.dart';
import 'package:pharma_connect/modules/prescriptions/screens/prescription_list_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets(
    'PrescriptionListScreen se construit avec PrescriptionProvider sans exception',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => PrescriptionProvider(),
            child: const PrescriptionListScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(PrescriptionListScreen), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    },
  );
}
