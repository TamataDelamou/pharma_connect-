import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';

// AuthProvider parle à un vrai GoTrueClient Supabase (voir auth_service.dart) :
// les branches OTP nominales (envoi/vérification réussis) nécessitent un
// projet Supabase réel et ne sont pas testables ici en unitaire — voir
// PharmaConnect_CLAUDE.md pour ce choix documenté. Les deux tests ci-dessous
// couvrent ce qui EST déterministe sans réseau : la validation synchrone
// avant tout appel réseau (erreur), et les transitions d'état pures (nominal).
// Même le constructeur d'AuthProvider (via AuthService -> GoTrueClient) exige
// que Supabase.initialize() ait été appelé au moins une fois dans l'isolat.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('AuthProvider', () {
    test(
      'sendPhoneOtp() (erreur) avec un numéro invalide échoue avant tout appel réseau',
      () async {
        final provider = AuthProvider();

        final result = await provider.sendPhoneOtp('123', 'sms');

        expect(result, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
      },
    );

    test(
      'setRole()/clearError() (nominal) mettent à jour l\'état sans appel réseau',
      () {
        final provider = AuthProvider();

        provider.setError('une erreur');
        expect(provider.error, 'une erreur');

        provider.clearError();
        expect(provider.error, isNull);

        provider.setRole(UserRole.patient);
        expect(provider.userRole, UserRole.patient);
      },
    );
  });
}
