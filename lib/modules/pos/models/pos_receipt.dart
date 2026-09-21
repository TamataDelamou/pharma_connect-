import 'package:equatable/equatable.dart';

class POSReceipt extends Equatable {
  final String id;
  final String saleId;
  final String receiptNumber;
  final String? receiptUrl;
  final DateTime printedAt;
  final String? printedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const POSReceipt({
    required this.id,
    required this.saleId,
    required this.receiptNumber,
    this.receiptUrl,
    required this.printedAt,
    this.printedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  POSReceipt copyWith({
    String? id,
    String? saleId,
    String? receiptNumber,
    String? receiptUrl,
    DateTime? printedAt,
    String? printedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return POSReceipt(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      printedAt: printedAt ?? this.printedAt,
      printedBy: printedBy ?? this.printedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sale_id': saleId,
    'receipt_number': receiptNumber,
    if (receiptUrl != null) 'receipt_url': receiptUrl,
    'printed_at': printedAt.toIso8601String(),
    if (printedBy != null) 'printed_by': printedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory POSReceipt.fromJson(Map<String, dynamic> json) => POSReceipt(
    id: json['id'] as String,
    saleId: json['sale_id'] as String,
    receiptNumber: json['receipt_number'] as String,
    receiptUrl: json['receipt_url'] as String?,
    printedAt: DateTime.parse(json['printed_at'] as String),
    printedBy: json['printed_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    saleId,
    receiptNumber,
    receiptUrl,
    printedAt,
    printedBy,
    gsgId,
    gsgOrgId,
  ];
}
