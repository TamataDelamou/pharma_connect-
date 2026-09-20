import 'package:equatable/equatable.dart';

// Modele absent du depot jusqu'ici (voir C150-bis) : returns_provider.dart
// et returns_service.dart importent et utilisent ce type sans qu'aucun
// fichier ne le declare. Cree ici a partir du schema reel de
// supabase/migrations/20260829010000_returns.sql (table supplier_returns),
// pattern identique a CustomerReturn.
class SupplierReturn extends Equatable {
  final String id;
  final String pharmacyId;
  final String? supplierId;
  final String? supplierOrderId;
  final String returnNumber;
  final DateTime returnDate;
  final String? reasonId;
  final String? reasonText;
  final String status; // pending, approved, shipped, completed, cancelled
  final int totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const SupplierReturn({
    required this.id,
    required this.pharmacyId,
    this.supplierId,
    this.supplierOrderId,
    required this.returnNumber,
    required this.returnDate,
    this.reasonId,
    this.reasonText,
    this.status = 'pending',
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  SupplierReturn copyWith({
    String? id,
    String? pharmacyId,
    String? supplierId,
    String? supplierOrderId,
    String? returnNumber,
    DateTime? returnDate,
    String? reasonId,
    String? reasonText,
    String? status,
    int? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return SupplierReturn(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      supplierId: supplierId ?? this.supplierId,
      supplierOrderId: supplierOrderId ?? this.supplierOrderId,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      reasonId: reasonId ?? this.reasonId,
      reasonText: reasonText ?? this.reasonText,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pharmacy_id': pharmacyId,
    if (supplierId != null) 'supplier_id': supplierId,
    if (supplierOrderId != null) 'supplier_order_id': supplierOrderId,
    'return_number': returnNumber,
    'return_date': returnDate.toIso8601String(),
    if (reasonId != null) 'reason_id': reasonId,
    if (reasonText != null) 'reason_text': reasonText,
    'status': status,
    'total_amount': totalAmount,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory SupplierReturn.fromJson(Map<String, dynamic> json) => SupplierReturn(
    id: json['id'] as String,
    pharmacyId: json['pharmacy_id'] as String,
    supplierId: json['supplier_id'] as String?,
    supplierOrderId: json['supplier_order_id'] as String?,
    returnNumber: json['return_number'] as String,
    returnDate: DateTime.parse(json['return_date'] as String),
    reasonId: json['reason_id'] as String?,
    reasonText: json['reason_text'] as String?,
    status: json['status'] as String? ?? 'pending',
    totalAmount: json['total_amount'] as int,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    pharmacyId,
    supplierId,
    supplierOrderId,
    returnNumber,
    returnDate,
    reasonId,
    reasonText,
    status,
    totalAmount,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}
