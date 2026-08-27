import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/delivery/providers/delivery_provider.dart';
import 'package:pharma_connect/modules/delivery/screens/delivery_history_screen.dart';

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
