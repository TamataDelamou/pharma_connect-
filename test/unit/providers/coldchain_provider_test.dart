import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/coldchain/providers/coldchain_provider.dart';

void main() {
  group('ColdChainProvider', () {
    test(
      'loadEquipments() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = ColdChainProvider();

        await provider.loadEquipments();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.equipments, isNotEmpty);
      },
    );

    test(
      'loadEquipment() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = ColdChainProvider();

        await provider.loadEquipment('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedEquipment, isNull);
      },
    );
  });
}
