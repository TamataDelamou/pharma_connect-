import 'package:equatable/equatable.dart';

class POSSale extends Equatable {
  final String id;
  final String pharmacyId;
  final String saleNumber;
  final String? patientId;
  final String cashierId;
  final int totalAmount;
  final int discountAmount;
  final int taxAmount;
  final int finalAmount;
  final String paymentMethod; // cash, mobile_money, card, insurance, credit
  final String status; // completed, refunded, cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final List<POSSaleItem>? items;
  final String? patientName;
  final String? cashierName;

  const POSSale({
    required this.id,
    required this.pharmacyId,
    required this.saleNumber,
    this.patientId,
    required this.cashierId,
    required this.totalAmount,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    this.status = 'completed',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.items,
    this.patientName,
    this.cashierName,
  });

  POSSale copyWith({
    String? id,
    String? pharmacyId,
    String? saleNumber,
    String? patientId,
    String? cashierId,
    int? totalAmount,
    int? discountAmount,
    int? taxAmount,
    int? finalAmount,
    String? paymentMethod,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    List<POSSaleItem>? items,
    String? patientName,
    String? cashierName,
  }) {
    return POSSale(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      saleNumber: saleNumber ?? this.saleNumber,
      patientId: patientId ?? this.patientId,
      cashierId: cashierId ?? this.cashierId,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      items: items ?? this.items,
      patientName: patientName ?? this.patientName,
      cashierName: cashierName ?? this.cashierName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    'sale_number': saleNumber,
    if (patientId != null) 'patient_id': patientId,
    'cashier_id': cashierId,
    'total_amount': totalAmount,
    'discount_amount': discountAmount,
    'tax_amount': taxAmount,
    'final_amount': finalAmount,
    'payment_method': paymentMethod,
    'status': status,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory POSSale.fromJson(Map<String, dynamic> json) => POSSale(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    saleNumber: json['sale_number'] as String,
    patientId: json['patient_id'] as String?,
    cashierId: json['cashier_id'] as String,
    totalAmount: json['total_amount'] as int,
    discountAmount: json['discount_amount'] as int? ?? 0,
    taxAmount: json['tax_amount'] as int? ?? 0,
    finalAmount: json['final_amount'] as int,
    paymentMethod: json['payment_method'] as String,
    status: json['status'] as String? ?? 'completed',
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    items: json['items'] != null
        ? (json['items'] as List)
              .map((e) => POSSaleItem.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    cashierName: json['cashiers'] != null
        ? (json['cashiers'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    saleNumber,
    patientId,
    cashierId,
    totalAmount,
    discountAmount,
    taxAmount,
    finalAmount,
    paymentMethod,
    status,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    items,
    patientName,
    cashierName,
  ];

  String get statusLabel {
    switch (status) {
      case 'completed':
        return '✅ Terminée';
      case 'refunded':
        return '🔄 Remboursée';
      case 'cancelled':
        return '❌ Annulée';
      default:
        return status;
    }
  }

  String get paymentLabel {
    switch (paymentMethod) {
      case 'cash':
        return '💵 Espèces';
      case 'mobile_money':
        return '📱 Mobile Money';
      case 'card':
        return '💳 Carte';
      case 'insurance':
        return '🛡️ Assurance';
      case 'credit':
        return '📋 Crédit';
      default:
        return paymentMethod;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isRefunded => status == 'refunded';
  bool get isCancelled => status == 'cancelled';
}
