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

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    balance: json['balance'] as int? ?? 0,
    pendingBalance: json['pending_balance'] as int? ?? 0,
    totalEarned: json['total_earned'] as int? ?? 0,
    totalSpent: json['total_spent'] as int? ?? 0,
    cashbackAvailable: json['cashback_available'] as int? ?? 0,
    currency:
        json['currency'] as String? ?? CurrencyFormatter.defaultCurrencyCode,
    lastUpdated: DateTime.parse(json['last_updated'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'balance': balance,
    'pending_balance': pendingBalance,
    'total_earned': totalEarned,
    'total_spent': totalSpent,
    'cashback_available': cashbackAvailable,
    'currency': currency,
    'last_updated': lastUpdated.toIso8601String(),
  };

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
