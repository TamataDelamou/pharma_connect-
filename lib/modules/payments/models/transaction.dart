import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'transaction_status.dart';
import 'payment_method.dart';

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

  Color get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return PharmaConnectColors.accentOrange;
      case TransactionStatus.processing:
        return PharmaConnectColors.accentCyan;
      case TransactionStatus.completed:
        return PharmaConnectColors.accentGreen;
      case TransactionStatus.failed:
        return PharmaConnectColors.accentRed;
      case TransactionStatus.refunded:
        return PharmaConnectColors.neutralMuted;
      case TransactionStatus.disputed:
        return PharmaConnectColors.accentAmber;
    }
  }
}
