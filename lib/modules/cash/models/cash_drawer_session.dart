import 'cash_rectification.dart';
import 'package:equatable/equatable.dart';
import '../../../core/theme/palette.dart';

enum CashSessionStatus { open, closed, suspended }

extension CashSessionStatusExtension on CashSessionStatus {
  String get label {
    switch (this) {
      case CashSessionStatus.open:
        return '🟢 Ouverte';
      case CashSessionStatus.closed:
        return '🔴 Fermée';
      case CashSessionStatus.suspended:
        return '🟡 Suspendue';
    }
  }

  String get color {
    switch (this) {
      case CashSessionStatus.open:
        return '#10B981';
      case CashSessionStatus.closed:
        return '#EF4444';
      case CashSessionStatus.suspended:
        return '#F59E0B';
    }
  }
}

class CashDrawerSession extends Equatable {
  final String id;
  final String pharmacyId;
  final String cashierId;
  final int openingBalance;
  final int? closingBalance;
  final int? expectedBalance;
  final int? difference;
  final DateTime openedAt;
  final DateTime? closedAt;
  final CashSessionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? cashierName;

  /// C273 (c) : rectifications rattachées à la caisse fermée, dans l'ordre
  /// d'enregistrement (embed `rectifications:cash_drawer_rectifications(*)`).
  final List<CashRectification> rectifications;

  const CashDrawerSession({
    required this.id,
    required this.pharmacyId,
    required this.cashierId,
    required this.openingBalance,
    this.closingBalance,
    this.expectedBalance,
    this.difference,
    required this.openedAt,
    this.closedAt,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.cashierName,
    this.rectifications = const [],
  });

  CashDrawerSession copyWith({
    String? id,
    String? pharmacyId,
    String? cashierId,
    int? openingBalance,
    int? closingBalance,
    int? expectedBalance,
    int? difference,
    DateTime? openedAt,
    DateTime? closedAt,
    CashSessionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? cashierName,
    List<CashRectification>? rectifications,
  }) {
    return CashDrawerSession(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      cashierId: cashierId ?? this.cashierId,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      expectedBalance: expectedBalance ?? this.expectedBalance,
      difference: difference ?? this.difference,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      cashierName: cashierName ?? this.cashierName,
      rectifications: rectifications ?? this.rectifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    'cashier_id': cashierId,
    'opening_balance': openingBalance,
    if (closingBalance != null) 'closing_balance': closingBalance,
    if (expectedBalance != null) 'expected_balance': expectedBalance,
    if (difference != null) 'difference': difference,
    'opened_at': openedAt.toIso8601String(),
    if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
    'status': status.name,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory CashDrawerSession.fromJson(Map<String, dynamic> json) {
    // 'cashiers' : embed Supabase (cashiers:cashier_id(full_name)), voir
    // CashService.getSession()/getSessions()/getCurrentOpenSession().
    String? derivedCashierName;
    final cashiersEmbed = json['cashiers'];
    if (cashiersEmbed is Map) {
      derivedCashierName = cashiersEmbed['full_name'] as String?;
    }
    final rectifications = [
      for (final r in (json['rectifications'] as List? ?? const []))
        CashRectification.fromJson(r as Map<String, dynamic>),
    ]..sort((a, b) => a.seq.compareTo(b.seq));

    return CashDrawerSession(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      cashierId: json['cashier_id'] as String,
      openingBalance: json['opening_balance'] as int,
      closingBalance: json['closing_balance'] as int?,
      expectedBalance: json['expected_balance'] as int?,
      difference: json['difference'] as int?,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      status: CashSessionStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      gsgId: json['gsg_id'] as String?,
      gsgOrgId: json['gsg_org_id'] as String?,
      cashierName: derivedCashierName,
      rectifications: rectifications,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    cashierId,
    openingBalance,
    closingBalance,
    expectedBalance,
    difference,
    openedAt,
    closedAt,
    status,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    cashierName,
    rectifications,
  ];

  bool get isOpen => status == CashSessionStatus.open;
  bool get isClosed => status == CashSessionStatus.closed;

  /// C273 (c) : dernière rectification, qui fait foi ; `null` sans
  /// rectification.
  CashRectification? get latestRectification =>
      rectifications.isEmpty ? null : rectifications.last;

  String get differenceLabel {
    if (difference == null) return 'Non vérifié';
    if (difference! > 0) return '+${difference}';
    if (difference! < 0) return '${difference}';
    return 'Équilibre';
  }

  ColorRole get differenceColor {
    if (difference == null) return ColorRole.textMuted;
    if (difference! > 0) return ColorRole.success;
    if (difference! < 0) return ColorRole.danger;
    return ColorRole.textPrimary;
  }
}
