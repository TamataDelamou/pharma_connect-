import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/payments/providers/payment_provider.dart';
import 'package:pharma_connect/modules/payments/screens/wallet_screen.dart';

void main() {
  testWidgets('WalletScreen se construit avec PaymentProvider sans exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => PaymentProvider(),
          child: const WalletScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(WalletScreen), findsOneWidget);
  });
}
