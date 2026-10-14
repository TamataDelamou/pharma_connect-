import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/reservations/widgets/pickup_qr_code.dart';

// C255 : voir c263_c264_reservations_offline_test.dart.
// C256 : le QR code est lisible dans les deux thèmes.

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  // C255 : les essais de l'ouverture du QR code depuis « Réservations » sont  // dans c263_c264_reservations_offline_test.dart (ouverture immédiate depuis  // la liste, C264).
  group('C256 : QR code lisible dans les deux thèmes', () {
    for (final (name, theme) in [
      ('clair', PharmaConnectAppTheme.light()),
      ('sombre', PharmaConnectAppTheme.dark()),
    ]) {
      testWidgets('thème $name : modules noirs, fond blanc, marge blanche', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: PickupQrCode(data: 'K7M4QX', extent: 232)),
            ),
          ),
        );

        const white = Color(0xFFFFFFFF);
        const black = Color(0xFF000000);
        final qr = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qr.backgroundColor, white);
        expect(qr.eyeStyle.color, black);
        expect(qr.dataModuleStyle.color, black);
        expect(qr.padding, EdgeInsets.zero);

        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(PickupQrCode),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((box.decoration! as BoxDecoration).color, white);

        // Marge blanche d'au moins 4 modules pour un QR code de 21 modules.
        final outer = tester.getSize(find.byType(PickupQrCode));
        final inner = tester.getSize(find.byType(QrImageView));
        expect(outer, const Size(232, 232));
        final margin = (outer.width - inner.width) / 2;
        expect(margin, greaterThanOrEqualTo(4 * inner.width / 21 - 0.01));
      });
    }

    test('aucun QR code hors de PickupQrCode', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('pickup_qr_code.dart'))
          .where((f) => f.readAsStringSync().contains('QrImageView('))
          .map((f) => f.path)
          .toList();
      expect(offenders, isEmpty);
    });
  });
}
