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

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
    id: json['id'] as String,
    reservationId: json['reservation_id'] as String? ?? '',
    patientId: json['patient_id'] as String? ?? '',
    patientName: json['patient_name'] as String,
    patientPhone: json['patient_phone'] as String,
    deliveryAddress: json['delivery_address'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    driver: json['driver'] != null
        ? DeliveryDriver.fromJson(json['driver'] as Map<String, dynamic>)
        : null,
    trackingHistory: (json['tracking_history'] as List<dynamic>? ?? [])
        .map((t) => t as String)
        .toList(),
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    startedAt: json['started_at'] != null
        ? DateTime.parse(json['started_at'] as String)
        : null,
    pickedUpAt: json['picked_up_at'] != null
        ? DateTime.parse(json['picked_up_at'] as String)
        : null,
    arrivedAt: json['arrived_at'] != null
        ? DateTime.parse(json['arrived_at'] as String)
        : null,
    deliveredAt: json['delivered_at'] != null
        ? DateTime.parse(json['delivered_at'] as String)
        : null,
    cancelledAt: json['cancelled_at'] != null
        ? DateTime.parse(json['cancelled_at'] as String)
        : null,
    status: DeliveryStatus.values.byName(json['status'] as String),
    proof: json['proof'] != null
        ? DeliveryProof.fromJson(json['proof'] as Map<String, dynamic>)
        : null,
    isColdChainRequired: json['is_cold_chain_required'] as bool? ?? false,
    notes: json['notes'] as String?,
    isExpress: json['is_express'] as bool? ?? false,
    pickupPointId: json['pickup_point_id'] as String?,
    pickupPointName: json['pickup_point_name'] as String?,
    distanceToDestination: (json['distance_to_destination'] as num?)
        ?.toDouble(),
    estimatedTimeRemaining: json['estimated_time_remaining'] as int?,
  );

  // proof n'est jamais écrit ici : delivery_proofs est une table séparée
  // (1:1, PK = delivery_id), gérée indépendamment par DeliveryService.
  Map<String, dynamic> toJson() => {
    'id': id,
    'reservation_id': reservationId.isEmpty ? null : reservationId,
    'patient_id': patientId.isEmpty ? null : patientId,
    'patient_name': patientName,
    'patient_phone': patientPhone,
    'delivery_address': deliveryAddress,
    'latitude': latitude,
    'longitude': longitude,
    'driver_id': driver?.id,
    'tracking_history': trackingHistory,
    'scheduled_at': scheduledAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'picked_up_at': pickedUpAt?.toIso8601String(),
    'arrived_at': arrivedAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'status': status.name,
    'is_cold_chain_required': isColdChainRequired,
    'notes': notes,
    'is_express': isExpress,
    'pickup_point_id': pickupPointId,
    'pickup_point_name': pickupPointName,
    'distance_to_destination': distanceToDestination,
    'estimated_time_remaining': estimatedTimeRemaining,
  };

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
