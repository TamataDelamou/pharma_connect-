import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/prescriptions/providers/prescription_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('PrescriptionProvider', () {
    test(
      'loadPrescriptions() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = PrescriptionProvider();

        await provider.loadPrescriptions();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.prescriptions, isNotEmpty);
      },
    );

    test(
      'loadPrescription() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = PrescriptionProvider();

        await provider.loadPrescription('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.selectedPrescription, isNull);
      },
    );
  });
}
