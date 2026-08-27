import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';

// DashboardProvider agrège des données générées en pur mémoire (aucun
// service, aucun appel réseau, _generateData() ne peut pas lever
// d'exception) : il n'existe pas de chemin d'erreur à tester ici. Un seul
// test nominal couvre donc ce provider — voir PharmaConnect_CLAUDE.md.
void main() {
  group('DashboardProvider', () {
    test('fetchData() (nominal) charge les données générées', () async {
      final provider = DashboardProvider();

      provider.fetchData();
      expect(provider.isLoading, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(provider.isLoading, isFalse);
      expect(provider.data.stats, isNotEmpty);
    });
  });
}
