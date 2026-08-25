import '../../../core/utils/currency_formatter.dart';

class Wallet {
  final String id;
  final String userId;
  final int balance; // Unité mineure
  final int pendingBalance; // Transactions en attente
  final int totalEarned;
  final int totalSpent;
  final int cashbackAvailable;
  final String currency;
  final DateTime lastUpdated;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.pendingBalance = 0,
    required this.totalEarned,
    required this.totalSpent,
    this.cashbackAvailable = 0,
    this.currency = CurrencyFormatter.defaultCurrencyCode,
    required this.lastUpdated,
  });

  Wallet copyWith({
    String? id,
    String? userId,
    int? balance,
    int? pendingBalance,
    int? totalEarned,
    int? totalSpent,
    int? cashbackAvailable,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      cashbackAvailable: cashbackAvailable ?? this.cashbackAvailable,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
