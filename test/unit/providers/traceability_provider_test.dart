import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/traceability/providers/traceability_provider.dart';

void main() {
  group('TraceabilityProvider', () {
    test('loadBatches() (nominal) charge la liste mockée sans erreur', () async {
      final provider = TraceabilityProvider();

      await provider.loadBatches();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.batches, isNotEmpty);
    });

    test('loadBatch() (erreur) avec un id inexistant renseigne error', () async {
      final provider = TraceabilityProvider();

      await provider.loadBatch('id-inexistant');

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.selectedBatch, isNull);
    });
  });
}
