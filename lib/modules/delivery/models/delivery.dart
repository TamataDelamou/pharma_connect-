import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'delivery_status.dart';
import 'delivery_driver.dart';
import 'delivery_proof.dart';

class Delivery {
  final String id;
  final String reservationId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;
  final DeliveryDriver? driver;
  final List<String> trackingHistory;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DeliveryStatus status;
  final DeliveryProof? proof;
  final bool isColdChainRequired;
  final String? notes;
  final bool isExpress;
  final String? pickupPointId;
  final String? pickupPointName;
  final double? distanceToDestination;
  final int? estimatedTimeRemaining; // en minutes

  Delivery({
    required this.id,
    required this.reservationId,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.driver,
    this.trackingHistory = const [],
    required this.scheduledAt,
    this.startedAt,
    this.pickedUpAt,
    this.arrivedAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.status,
    this.proof,
    this.isColdChainRequired = false,
    this.notes,
    this.isExpress = false,
    this.pickupPointId,
    this.pickupPointName,
    this.distanceToDestination,
    this.estimatedTimeRemaining,
  });

  Delivery copyWith({
    String? id,
    String? reservationId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    DeliveryDriver? driver,
    List<String>? trackingHistory,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? pickedUpAt,
    DateTime? arrivedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DeliveryStatus? status,
    DeliveryProof? proof,
    bool? isColdChainRequired,
    String? notes,
    bool? isExpress,
    String? pickupPointId,
    String? pickupPointName,
    double? distanceToDestination,
    int? estimatedTimeRemaining,
  }) {
    return Delivery(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driver: driver ?? this.driver,
      trackingHistory: trackingHistory ?? this.trackingHistory,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      proof: proof ?? this.proof,
      isColdChainRequired: isColdChainRequired ?? this.isColdChainRequired,
      notes: notes ?? this.notes,
      isExpress: isExpress ?? this.isExpress,
      pickupPointId: pickupPointId ?? this.pickupPointId,
      pickupPointName: pickupPointName ?? this.pickupPointName,
      distanceToDestination:
          distanceToDestination ?? this.distanceToDestination,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
    );
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.scheduled:
        return 'Programmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.inProgress:
        return 'En cours de livraison';
      case DeliveryStatus.arrived:
        return 'Arrivé sur place';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeliveryStatus.scheduled:
        return PharmaConnectColors.accentOrange;
      case DeliveryStatus.preparing:
        return PharmaConnectColors.accentCyan;
      case DeliveryStatus.inProgress:
        return PharmaConnectColors.accentPurple;
      case DeliveryStatus.arrived:
        return PharmaConnectColors.accentGreen;
      case DeliveryStatus.delivered:
        return PharmaConnectColors.neutralMuted;
      case DeliveryStatus.cancelled:
        return PharmaConnectColors.accentRed;
    }
  }

  String get statusIcon {
    switch (status) {
      case DeliveryStatus.scheduled:
        return '📅';
      case DeliveryStatus.preparing:
        return '📦';
      case DeliveryStatus.inProgress:
        return '🚴';
      case DeliveryStatus.arrived:
        return '📍';
      case DeliveryStatus.delivered:
        return '✅';
      case DeliveryStatus.cancelled:
        return '❌';
    }
  }

  bool get isActive =>
      status == DeliveryStatus.inProgress || status == DeliveryStatus.preparing;
  bool get isPast =>
      status == DeliveryStatus.delivered || status == DeliveryStatus.cancelled;
  bool get isReadyToStart =>
      status == DeliveryStatus.scheduled && driver != null;
  bool get canBeCancelled =>
      status == DeliveryStatus.scheduled || status == DeliveryStatus.preparing;

  String get estimatedArrival {
    if (status == DeliveryStatus.delivered) return 'Livrée';
    if (status == DeliveryStatus.inProgress && estimatedTimeRemaining != null) {
      if (estimatedTimeRemaining! < 1) return 'Arrivée imminente';
      if (estimatedTimeRemaining! < 60) return '${estimatedTimeRemaining!} min';
      final hours = estimatedTimeRemaining! ~/ 60;
      final minutes = estimatedTimeRemaining! % 60;
      if (minutes == 0) return '$hours h';
      return '$hours h $minutes min';
    }
    if (status == DeliveryStatus.arrived) {
      return 'Le livreur est sur place';
    }
    return 'En cours de préparation';
  }

  double get progress {
    switch (status) {
      case DeliveryStatus.scheduled:
        return 0.0;
      case DeliveryStatus.preparing:
        return 0.2;
      case DeliveryStatus.inProgress:
        return 0.5;
      case DeliveryStatus.arrived:
        return 0.8;
      case DeliveryStatus.delivered:
        return 1.0;
      case DeliveryStatus.cancelled:
        return 0.0;
    }
  }
}
