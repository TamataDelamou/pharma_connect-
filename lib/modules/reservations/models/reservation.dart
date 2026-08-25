import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'reservation_item.dart';
import 'reservation_status.dart';

class Reservation {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String? patientEmail;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final String? pharmacyPhone;
  final List<ReservationItem> items;
  final DateTime reservedAt;
  final DateTime? pickupTime;
  final DateTime? pickupDeadline;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? cancelledAt;
  final ReservationStatus status;
  final int totalPrice;
  final String? qrCodeToken;
  final String? notes;
  final String? deliveryAddress;
  final String? paymentMethod;
  final int? queuePosition;
  final int? estimatedWaitMinutes;

  Reservation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.patientEmail,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    this.pharmacyPhone,
    required this.items,
    required this.reservedAt,
    this.pickupTime,
    this.pickupDeadline,
    this.confirmedAt,
    this.readyAt,
    this.pickedUpAt,
    this.cancelledAt,
    required this.status,
    required this.totalPrice,
    this.qrCodeToken,
    this.notes,
    this.deliveryAddress,
    this.paymentMethod,
    this.queuePosition,
    this.estimatedWaitMinutes,
  });

  Reservation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyPhone,
    List<ReservationItem>? items,
    DateTime? reservedAt,
    DateTime? pickupTime,
    DateTime? pickupDeadline,
    DateTime? confirmedAt,
    DateTime? readyAt,
    DateTime? pickedUpAt,
    DateTime? cancelledAt,
    ReservationStatus? status,
    int? totalPrice,
    String? qrCodeToken,
    String? notes,
    String? deliveryAddress,
    String? paymentMethod,
    int? queuePosition,
    int? estimatedWaitMinutes,
  }) {
    return Reservation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      patientEmail: patientEmail ?? this.patientEmail,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      items: items ?? this.items,
      reservedAt: reservedAt ?? this.reservedAt,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupDeadline: pickupDeadline ?? this.pickupDeadline,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      readyAt: readyAt ?? this.readyAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
    );
  }

  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isReady => status == ReservationStatus.ready;
  bool get isPickedUp => status == ReservationStatus.pickedUp;
  bool get isCancelled => status == ReservationStatus.cancelled;
  bool get isExpired => status == ReservationStatus.expired;
  bool get isCancelable => isPending || isConfirmed;
  bool get canBePickedUp => isReady || isConfirmed;

  Duration get timeRemaining {
    if (pickupDeadline == null) return Duration.zero;
    return pickupDeadline!.difference(DateTime.now());
  }

  bool get isRunningOutOfTime {
    if (pickupDeadline == null) return false;
    return timeRemaining.inMinutes < 15;
  }

  bool get isOverdue {
    if (pickupDeadline == null) return false;
    return pickupDeadline!.isBefore(DateTime.now());
  }

  String get statusLabel {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente de confirmation';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.ready:
        return 'Prête à être retirée';
      case ReservationStatus.pickedUp:
        return 'Retirée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.expired:
        return 'Expirée';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReservationStatus.pending:
        return PharmaConnectColors.accentOrange;
      case ReservationStatus.confirmed:
        return PharmaConnectColors.accentCyan;
      case ReservationStatus.ready:
        return PharmaConnectColors.accentGreen;
      case ReservationStatus.pickedUp:
        return PharmaConnectColors.neutralMuted;
      case ReservationStatus.cancelled:
        return PharmaConnectColors.accentRed;
      case ReservationStatus.expired:
        return PharmaConnectColors.textSecondary;
    }
  }

  String get statusIcon {
    switch (status) {
      case ReservationStatus.pending:
        return '⏳';
      case ReservationStatus.confirmed:
        return '✅';
      case ReservationStatus.ready:
        return '📦';
      case ReservationStatus.pickedUp:
        return '🙌';
      case ReservationStatus.cancelled:
        return '❌';
      case ReservationStatus.expired:
        return '⏰';
    }
  }

  String get queueDisplay {
    if (queuePosition == null || queuePosition == 0) return 'En cours';
    return 'Position #$queuePosition';
  }

  String get estimatedWaitDisplay {
    if (estimatedWaitMinutes == null) return '';
    if (estimatedWaitMinutes! < 1) return 'Moins d\'1 minute';
    if (estimatedWaitMinutes! < 60) return '${estimatedWaitMinutes!} minutes';
    final hours = estimatedWaitMinutes! ~/ 60;
    final minutes = estimatedWaitMinutes! % 60;
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }
}
