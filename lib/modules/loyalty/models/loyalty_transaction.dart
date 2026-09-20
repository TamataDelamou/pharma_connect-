import 'package:equatable/equatable.dart';

class LoyaltyTransaction extends Equatable {
  final String id;
  final String accountId;
  final String transactionType; // earn, redeem, adjust, expire, referral
  final int amount;
  final int pointsBalanceAfter;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;
  final String? createdBy;
  final String? gsgId;
  final String? gsgOrgId;

  const LoyaltyTransaction({
    required this.id,
    required this.accountId,
    required this.transactionType,
    required this.amount,
    required this.pointsBalanceAfter,
    this.referenceId,
    this.description,
    required this.createdAt,
    this.createdBy,
    this.gsgId,
    this.gsgOrgId,
  });

  // Phase 4 (module loyalty) : copyWith() jamais écrit alors qu'appelé par
  // LoyaltyService.addTransaction() - même motif que CHN-10/ASR-8/
  // AvailabilitySlot/B2BOrderItem déjà rencontrés dans ce projet.
  LoyaltyTransaction copyWith({
    String? id,
    String? accountId,
    String? transactionType,
    int? amount,
    int? pointsBalanceAfter,
    String? referenceId,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    String? gsgId,
    String? gsgOrgId,
  }) => LoyaltyTransaction(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    transactionType: transactionType ?? this.transactionType,
    amount: amount ?? this.amount,
    pointsBalanceAfter: pointsBalanceAfter ?? this.pointsBalanceAfter,
    referenceId: referenceId ?? this.referenceId,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_id': accountId,
    'transaction_type': transactionType,
    'amount': amount,
    'points_balance_after': pointsBalanceAfter,
    if (referenceId != null) 'reference_id': referenceId,
    if (description != null) 'description': description,
    'created_at': createdAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        transactionType: json['transaction_type'] as String,
        amount: json['amount'] as int,
        pointsBalanceAfter: json['points_balance_after'] as int,
        referenceId: json['reference_id'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        createdBy: json['created_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    accountId,
    transactionType,
    amount,
    pointsBalanceAfter,
    referenceId,
    description,
    createdAt,
    createdBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (transactionType) {
      case 'earn':
        return 'Gagné';
      case 'redeem':
        return 'Utilisé';
      case 'adjust':
        return 'Ajustement';
      case 'expire':
        return 'Expiré';
      case 'referral':
        return 'Parrainage';
      default:
        return transactionType;
    }
  }

  String get typeIcon {
    switch (transactionType) {
      case 'earn':
        return '📈';
      case 'redeem':
        return '🛍️';
      case 'adjust':
        return '⚖️';
      case 'expire':
        return '⏰';
      case 'referral':
        return '👥';
      default:
        return '📋';
    }
  }
}
