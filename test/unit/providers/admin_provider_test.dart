import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/admin/providers/admin_provider.dart';

void main() {
  group('AdminProvider', () {
    test('loadUsers() (nominal) charge la liste mockée sans erreur', () async {
      final provider = AdminProvider();

      await provider.loadUsers();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.users, isNotEmpty);
    });

    test('loadUser() (erreur) avec un id inexistant renseigne error', () async {
      final provider = AdminProvider();

      await provider.loadUser('id-inexistant');

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.selectedUser, isNull);
    });
  });
}
