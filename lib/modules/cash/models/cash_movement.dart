import 'package:equatable/equatable.dart';

enum CashMovementType {
  sale,
  refund,
  deposit,
  withdrawal,
  adjustment,
  opening,
  closing,
}

extension CashMovementTypeExtension on CashMovementType {
  String get label {
    switch (this) {
      case CashMovementType.sale:
        return '💰 Vente';
      case CashMovementType.refund:
        return '🔄 Remboursement';
      case CashMovementType.deposit:
        return '📥 Dépôt';
      case CashMovementType.withdrawal:
        return '📤 Retrait';
      case CashMovementType.adjustment:
        return '⚖️ Ajustement';
      case CashMovementType.opening:
        return '🟢 Ouverture';
      case CashMovementType.closing:
        return '🔴 Fermeture';
    }
  }

  String get color {
    switch (this) {
      case CashMovementType.sale:
        return '#10B981';
      case CashMovementType.refund:
        return '#EF4444';
      case CashMovementType.deposit:
        return '#00D9FF';
      case CashMovementType.withdrawal:
        return '#F59E0B';
      case CashMovementType.adjustment:
        return '#8B5CF6';
      case CashMovementType.opening:
        return '#10B981';
      case CashMovementType.closing:
        return '#EF4444';
    }
  }
}

class CashMovement extends Equatable {
  final String id;
  final String cashDrawerSessionId;
  final CashMovementType type;
  final int amount;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;
  final String? gsgId;
  final String? gsgOrgId;

  const CashMovement({
    required this.id,
    required this.cashDrawerSessionId,
    required this.type,
    required this.amount,
    this.referenceId,
    this.referenceType,
    this.notes,
    required this.createdAt,
    this.createdBy,
    this.gsgId,
    this.gsgOrgId,
  });

  CashMovement copyWith({
    String? id,
    String? cashDrawerSessionId,
    CashMovementType? type,
    int? amount,
    String? referenceId,
    String? referenceType,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return CashMovement(
      id: id ?? this.id,
      cashDrawerSessionId: cashDrawerSessionId ?? this.cashDrawerSessionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cash_drawer_session_id': cashDrawerSessionId,
    'type': type.name,
    'amount': amount,
    if (referenceId != null) 'reference_id': referenceId,
    if (referenceType != null) 'reference_type': referenceType,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory CashMovement.fromJson(Map<String, dynamic> json) => CashMovement(
    id: json['id'] as String,
    cashDrawerSessionId: json['cash_drawer_session_id'] as String,
    type: CashMovementType.values.byName(json['type'] as String),
    amount: json['amount'] as int,
    referenceId: json['reference_id'] as String?,
    referenceType: json['reference_type'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    createdBy: json['created_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    cashDrawerSessionId,
    type,
    amount,
    referenceId,
    referenceType,
    notes,
    createdAt,
    createdBy,
    gsgId,
    gsgOrgId,
  ];

  bool get isIncome => type == CashMovementType.sale || type == CashMovementType.deposit || type == CashMovementType.opening;
  bool get isExpense => type == CashMovementType.refund || type == CashMovementType.withdrawal || type == CashMovementType.closing;
}
