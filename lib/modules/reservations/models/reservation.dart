import 'reservation_item.dart';
import 'reservation_status.dart';
import '../../../core/theme/palette.dart';

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

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as String,
    patientId: json['patient_id'] as String? ?? '',
    patientName: json['patient_name'] as String,
    patientPhone: json['patient_phone'] as String,
    patientEmail: json['patient_email'] as String?,
    pharmacyId: json['pharmacy_id'] as String,
    pharmacyName: json['pharmacy_name'] as String,
    pharmacyAddress: json['pharmacy_address'] as String,
    pharmacyPhone: json['pharmacy_phone'] as String?,
    items: (json['reservation_items'] as List<dynamic>? ?? [])
        .map((i) => ReservationItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    reservedAt: DateTime.parse(json['reserved_at'] as String),
    pickupTime: json['pickup_time'] != null
        ? DateTime.parse(json['pickup_time'] as String)
        : null,
    pickupDeadline: json['pickup_deadline'] != null
        ? DateTime.parse(json['pickup_deadline'] as String)
        : null,
    confirmedAt: json['confirmed_at'] != null
        ? DateTime.parse(json['confirmed_at'] as String)
        : null,
    readyAt: json['ready_at'] != null
        ? DateTime.parse(json['ready_at'] as String)
        : null,
    pickedUpAt: json['picked_up_at'] != null
        ? DateTime.parse(json['picked_up_at'] as String)
        : null,
    cancelledAt: json['cancelled_at'] != null
        ? DateTime.parse(json['cancelled_at'] as String)
        : null,
    status: ReservationStatus.values.byName(json['status'] as String),
    totalPrice: json['total_price'] as int? ?? 0,
    qrCodeToken: json['qr_code_token'] as String?,
    notes: json['notes'] as String?,
    deliveryAddress: json['delivery_address'] as String?,
    paymentMethod: json['payment_method'] as String?,
    queuePosition: json['queue_position'] as int?,
    estimatedWaitMinutes: json['estimated_wait_minutes'] as int?,
  );

  // items n'est jamais écrit ici : reservation_items est une table séparée.
  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId.isEmpty ? null : patientId,
    'patient_name': patientName,
    'patient_phone': patientPhone,
    'patient_email': patientEmail,
    'pharmacy_id': pharmacyId,
    'pharmacy_name': pharmacyName,
    'pharmacy_address': pharmacyAddress,
    'pharmacy_phone': pharmacyPhone,
    'reserved_at': reservedAt.toIso8601String(),
    'pickup_time': pickupTime?.toIso8601String(),
    'pickup_deadline': pickupDeadline?.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'ready_at': readyAt?.toIso8601String(),
    'picked_up_at': pickedUpAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'status': status.name,
    'total_price': totalPrice,
    'qr_code_token': qrCodeToken,
    'notes': notes,
    'delivery_address': deliveryAddress,
    'payment_method': paymentMethod,
    'queue_position': queuePosition,
    'estimated_wait_minutes': estimatedWaitMinutes,
  };

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

  ColorRole get statusColor {
    switch (status) {
      case ReservationStatus.pending:
        return ColorRole.warning;
      case ReservationStatus.confirmed:
        return ColorRole.primary;
      case ReservationStatus.ready:
        return ColorRole.success;
      case ReservationStatus.pickedUp:
        return ColorRole.textMuted;
      case ReservationStatus.cancelled:
        return ColorRole.danger;
      case ReservationStatus.expired:
        return ColorRole.textSecondary;
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
