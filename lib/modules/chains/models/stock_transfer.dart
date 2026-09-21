import 'package:equatable/equatable.dart';

class StockTransfer extends Equatable {
  final String id;
  final String fromPharmacyId;
  final String toPharmacyId;
  final String? groupId;
  final String status; // pending, approved, in_transit, received, cancelled
  final DateTime transferDate;
  final DateTime? receivedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? fromPharmacyName;
  final String? toPharmacyName;
  final List<TransferItem>? items;

  const StockTransfer({
    required this.id,
    required this.fromPharmacyId,
    required this.toPharmacyId,
    this.groupId,
    required this.status,
    required this.transferDate,
    this.receivedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.fromPharmacyName,
    this.toPharmacyName,
    this.items,
  });

  StockTransfer copyWith({
    String? id,
    String? fromPharmacyId,
    String? toPharmacyId,
    String? groupId,
    String? status,
    DateTime? transferDate,
    DateTime? receivedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? fromPharmacyName,
    String? toPharmacyName,
    List<TransferItem>? items,
  }) {
    return StockTransfer(
      id: id ?? this.id,
      fromPharmacyId: fromPharmacyId ?? this.fromPharmacyId,
      toPharmacyId: toPharmacyId ?? this.toPharmacyId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      transferDate: transferDate ?? this.transferDate,
      receivedDate: receivedDate ?? this.receivedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      fromPharmacyName: fromPharmacyName ?? this.fromPharmacyName,
      toPharmacyName: toPharmacyName ?? this.toPharmacyName,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_pharmacy_id': fromPharmacyId,
    'to_pharmacy_id': toPharmacyId,
    if (groupId != null) 'group_id': groupId,
    'status': status,
    'transfer_date': transferDate.toIso8601String(),
    if (receivedDate != null) 'received_date': receivedDate!.toIso8601String(),
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory StockTransfer.fromJson(Map<String, dynamic> json) => StockTransfer(
    id: json['id'] as String,
    fromPharmacyId: json['from_pharmacy_id'] as String,
    toPharmacyId: json['to_pharmacy_id'] as String,
    groupId: json['group_id'] as String?,
    status: json['status'] as String,
    transferDate: DateTime.parse(json['transfer_date'] as String),
    receivedDate: json['received_date'] != null
        ? DateTime.parse(json['received_date'] as String)
        : null,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    fromPharmacyName: json['from_pharmacies'] != null
        ? (json['from_pharmacies'] as Map<String, dynamic>)['name'] as String?
        : null,
    toPharmacyName: json['to_pharmacies'] != null
        ? (json['to_pharmacies'] as Map<String, dynamic>)['name'] as String?
        : null,
    items: json['items'] != null
        ? (json['items'] as List)
              .map((e) => TransferItem.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    fromPharmacyId,
    toPharmacyId,
    groupId,
    status,
    transferDate,
    receivedDate,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    fromPharmacyName,
    toPharmacyName,
    items,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'in_transit':
        return 'En transit';
      case 'received':
        return 'Reçu';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'approved':
        return '✅';
      case 'in_transit':
        return '🚚';
      case 'received':
        return '📦';
      case 'cancelled':
        return '❌';
      default:
        return '📋';
    }
  }
}

class TransferItem extends Equatable {
  final String id;
  final String transferId;
  final String? productId;
  final String productName;
  final int quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const TransferItem({
    required this.id,
    required this.transferId,
    this.productId,
    required this.productName,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-10 : `copyWith()`
  // totalement absent alors qu'appelé par `ChainService.addTransferItem()`
  // (`item.copyWith(id: id, createdAt: now, updatedAt: now)`) — défaut de
  // COMPILATION découvert en cours de correctif, même famille que ASR-8
  // (Module 24). Aucune des méthodes déjà mobilisées dans cet audit
  // (exécution Postgres réelle, relecture ciblée) n'aurait détecté ce
  // défaut sans passer effectivement en revue chaque appelant du modèle.
  TransferItem copyWith({
    String? id,
    String? transferId,
    String? productId,
    String? productName,
    int? quantity,
    String? batchNumber,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return TransferItem(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transfer_id': transferId,
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    if (batchNumber != null) 'batch_number': batchNumber,
    if (expiryDate != null)
      'expiry_date': expiryDate!.toIso8601String().split('T').first,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TransferItem.fromJson(Map<String, dynamic> json) => TransferItem(
    id: json['id'] as String,
    transferId: json['transfer_id'] as String,
    productId: json['product_id'] as String?,
    productName: json['product_name'] as String,
    quantity: json['quantity'] as int,
    batchNumber: json['batch_number'] as String?,
    expiryDate: json['expiry_date'] != null
        ? DateTime.parse(json['expiry_date'] as String)
        : null,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    transferId,
    productId,
    productName,
    quantity,
    batchNumber,
    expiryDate,
    notes,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}
