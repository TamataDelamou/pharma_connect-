import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale_item.dart';
import 'package:pharma_connect/modules/pos/providers/pos_provider.dart';

void main() {
  group('POSProvider', () {
    late POSProvider provider;

    setUp(() {
      provider = POSProvider();
    });

    test('initial state', () {
      expect(provider.cart, isEmpty);
      expect(provider.sales, isEmpty);
      expect(provider.currentSale, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isCheckingOut, isFalse);
      expect(provider.total, 0);
      expect(provider.finalTotal, 0);
    });

    test('addToCart adds item', () {
      final item = POSSaleItem(
        id: '1',
        saleId: '',
        productId: 'p1',
        productName: 'Test',
        quantity: 2,
        unitPrice: 1000,
        totalPrice: 2000,
        createdAt: DateTime.now(),
      );
      provider.addToCart(item);
      expect(provider.cart.length, 1);
      expect(provider.total, 2000);
    });

    test('removeFromCart removes item', () {
      final item = POSSaleItem(
        id: '1',
        saleId: '',
        productId: 'p1',
        productName: 'Test',
        quantity: 2,
        unitPrice: 1000,
        totalPrice: 2000,
        createdAt: DateTime.now(),
      );
      provider.addToCart(item);
      provider.removeFromCart('p1');
      expect(provider.cart, isEmpty);
    });

    test('clearCart clears all', () {
      final item = POSSaleItem(
        id: '1',
        saleId: '',
        productId: 'p1',
        productName: 'Test',
        quantity: 2,
        unitPrice: 1000,
        totalPrice: 2000,
        createdAt: DateTime.now(),
      );
      provider.addToCart(item);
      provider.clearCart();
      expect(provider.cart, isEmpty);
    });

    test('setDiscount updates discount', () {
      provider.setDiscount(10);
      expect(provider.discountPercent, 10);
    });
  });
}
