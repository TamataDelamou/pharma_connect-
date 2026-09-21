import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/business/models/business_company.dart';
import 'package:pharma_connect/modules/business/providers/business_provider.dart';

void main() {
  group('BusinessProvider', () {
    late BusinessProvider provider;

    setUp(() {
      provider = BusinessProvider();
    });

    test('initial state', () {
      expect(provider.companies, isEmpty);
      expect(provider.selectedCompany, isNull);
      expect(provider.contracts, isEmpty);
      expect(provider.selectedContract, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedCompanyForTest = BusinessCompany(
        id: '1',
        name: 'Test Company',
        type: 'wholesaler',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedCompany, isNull);
    });
  });
}
