import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('ReservationProvider', () {
    test(
      'loadReservations() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = ReservationProvider();

        await provider.loadReservations();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.reservations, isNotEmpty);
      },
    );

    test(
      'loadReservation() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = ReservationProvider();

        await provider.loadReservation('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedReservation, isNull);
      },
    );
  });
}
