import 'package:flutter/material.dart';
import 'transaction_status.dart';
import 'payment_method.dart';
import '../../../core/theme/palette.dart';

class Transaction {
  final String id;
  final String? reservationId;
  final String? deliveryId;
  final String? prescriptionId;
  final String userId;
  final String userPhone;
  final String? pharmacyId;
  final String? pharmacyName;
  final int amount; // unité mineure (GNF)
  final int? fee; // unité mineure
  final int? cashback; // unité mineure
  final int finalAmount; // unité mineure
  final PaymentMethod method;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? transactionReference;
  final String? externalReference;
  final String? qrCodeToken;
  final Map<String, dynamic>? metadata;
  final String? notes;

  Transaction({
    required this.id,
    this.reservationId,
    this.deliveryId,
    this.prescriptionId,
    required this.userId,
    required this.userPhone,
    this.pharmacyId,
    this.pharmacyName,
    required this.amount,
    this.fee,
    this.cashback,
    required this.finalAmount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.refundedAt,
    this.transactionReference,
    this.externalReference,
    this.qrCodeToken,
    this.metadata,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    reservationId: json['reservation_id'] as String?,
    deliveryId: json['delivery_id'] as String?,
    prescriptionId: json['prescription_id'] as String?,
    userId: json['user_id'] as String? ?? '',
    userPhone: json['user_phone'] as String,
    pharmacyId: json['pharmacy_id'] as String?,
    pharmacyName: json['pharmacy_name'] as String?,
    amount: json['amount'] as int,
    fee: json['fee'] as int?,
    cashback: json['cashback'] as int?,
    finalAmount: json['final_amount'] as int,
    method: PaymentMethod.values.byName(json['method'] as String),
    status: TransactionStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    refundedAt: json['refunded_at'] != null
        ? DateTime.parse(json['refunded_at'] as String)
        : null,
    transactionReference: json['transaction_reference'] as String?,
    externalReference: json['external_reference'] as String?,
    qrCodeToken: json['qr_code_token'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reservation_id': reservationId,
    'delivery_id': deliveryId,
    'prescription_id': prescriptionId,
    'user_id': userId.isEmpty ? null : userId,
    'user_phone': userPhone,
    'pharmacy_id': pharmacyId,
    'pharmacy_name': pharmacyName,
    'amount': amount,
    'fee': fee,
    'cashback': cashback,
    'final_amount': finalAmount,
    'method': method.name,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'refunded_at': refundedAt?.toIso8601String(),
    'transaction_reference': transactionReference,
    'external_reference': externalReference,
    'qr_code_token': qrCodeToken,
    'metadata': metadata,
    'notes': notes,
  };

  Transaction copyWith({
    String? id,
    String? reservationId,
    String? deliveryId,
    String? prescriptionId,
    String? userId,
    String? userPhone,
    String? pharmacyId,
    String? pharmacyName,
    int? amount,
    int? fee,
    int? cashback,
    int? finalAmount,
    PaymentMethod? method,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? transactionReference,
    String? externalReference,
    String? qrCodeToken,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      deliveryId: deliveryId ?? this.deliveryId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      userId: userId ?? this.userId,
      userPhone: userPhone ?? this.userPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      cashback: cashback ?? this.cashback,
      finalAmount: finalAmount ?? this.finalAmount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      transactionReference: transactionReference ?? this.transactionReference,
      externalReference: externalReference ?? this.externalReference,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isRefunded => status == TransactionStatus.refunded;
  bool get isDisputed => status == TransactionStatus.disputed;

  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.processing:
        return 'En cours';
      case TransactionStatus.completed:
        return 'Réussi';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.refunded:
        return 'Remboursé';
      case TransactionStatus.disputed:
        return 'Litige';
    }
  }

  ColorRole get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return ColorRole.warning;
      case TransactionStatus.processing:
        return ColorRole.primary;
      case TransactionStatus.completed:
        return ColorRole.success;
      case TransactionStatus.failed:
        return ColorRole.danger;
      case TransactionStatus.refunded:
        return ColorRole.textMuted;
      case TransactionStatus.disputed:
        return ColorRole.warningStrong;
    }
  }
}
