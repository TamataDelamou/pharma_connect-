import 'package:equatable/equatable.dart';

class EPrescription extends Equatable {
  final String id;
  final String prescriptionNumber;
  final String patientId;
  final String doctorId;
  final String? pharmacyId;
  final DateTime prescribedAt;
  final DateTime validUntil;
  final String
  status; // draft, sent, received, validated, dispensed, expired, cancelled
  final String? diagnosis;
  final String? notes;
  final bool isRenewable;
  final int renewableCount;
  final int renewableUsed;
  final String? consultationId;
  final String? qrCode;
  final String? accessCode;
  final DateTime? validatedAt;
  final DateTime? dispensedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields
  final String? patientName;
  final String? patientPhone;
  final String? doctorName;
  final String? pharmacyName;

  const EPrescription({
    required this.id,
    required this.prescriptionNumber,
    required this.patientId,
    required this.doctorId,
    this.pharmacyId,
    required this.prescribedAt,
    required this.validUntil,
    required this.status,
    this.diagnosis,
    this.notes,
    this.isRenewable = false,
    this.renewableCount = 0,
    this.renewableUsed = 0,
    this.consultationId,
    this.qrCode,
    this.accessCode,
    this.validatedAt,
    this.dispensedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.doctorName,
    this.pharmacyName,
  });

  EPrescription copyWith({
    String? id,
    String? prescriptionNumber,
    String? patientId,
    String? doctorId,
    String? pharmacyId,
    DateTime? prescribedAt,
    DateTime? validUntil,
    String? status,
    String? diagnosis,
    String? notes,
    bool? isRenewable,
    int? renewableCount,
    int? renewableUsed,
    String? consultationId,
    String? qrCode,
    String? accessCode,
    DateTime? validatedAt,
    DateTime? dispensedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? doctorName,
    String? pharmacyName,
  }) {
    return EPrescription(
      id: id ?? this.id,
      prescriptionNumber: prescriptionNumber ?? this.prescriptionNumber,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      prescribedAt: prescribedAt ?? this.prescribedAt,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      isRenewable: isRenewable ?? this.isRenewable,
      renewableCount: renewableCount ?? this.renewableCount,
      renewableUsed: renewableUsed ?? this.renewableUsed,
      consultationId: consultationId ?? this.consultationId,
      qrCode: qrCode ?? this.qrCode,
      accessCode: accessCode ?? this.accessCode,
      validatedAt: validatedAt ?? this.validatedAt,
      dispensedAt: dispensedAt ?? this.dispensedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorName: doctorName ?? this.doctorName,
      pharmacyName: pharmacyName ?? this.pharmacyName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'prescription_number': prescriptionNumber,
    'patient_id': patientId,
    'doctor_id': doctorId,
    if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    'prescribed_at': prescribedAt.toIso8601String(),
    'valid_until': validUntil.toIso8601String(),
    'status': status,
    if (diagnosis != null) 'diagnosis': diagnosis,
    if (notes != null) 'notes': notes,
    'is_renewable': isRenewable,
    'renewable_count': renewableCount,
    'renewable_used': renewableUsed,
    if (consultationId != null) 'consultation_id': consultationId,
    if (qrCode != null) 'qr_code': qrCode,
    if (accessCode != null) 'access_code': accessCode,
    if (validatedAt != null) 'validated_at': validatedAt!.toIso8601String(),
    if (dispensedAt != null) 'dispensed_at': dispensedAt!.toIso8601String(),
    if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
    if (cancellationReason != null) 'cancellation_reason': cancellationReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory EPrescription.fromJson(Map<String, dynamic> json) => EPrescription(
    id: json['id'] as String,
    prescriptionNumber: json['prescription_number'] as String,
    patientId: json['patient_id'] as String,
    doctorId: json['doctor_id'] as String,
    pharmacyId: json['pharmacy_id'] as String?,
    prescribedAt: DateTime.parse(json['prescribed_at'] as String),
    validUntil: DateTime.parse(json['valid_until'] as String),
    status: json['status'] as String,
    diagnosis: json['diagnosis'] as String?,
    notes: json['notes'] as String?,
    isRenewable: json['is_renewable'] as bool? ?? false,
    renewableCount: json['renewable_count'] as int? ?? 0,
    renewableUsed: json['renewable_used'] as int? ?? 0,
    consultationId: json['consultation_id'] as String?,
    qrCode: json['qr_code'] as String?,
    accessCode: json['access_code'] as String?,
    validatedAt: json['validated_at'] != null
        ? DateTime.parse(json['validated_at'] as String)
        : null,
    dispensedAt: json['dispensed_at'] != null
        ? DateTime.parse(json['dispensed_at'] as String)
        : null,
    cancelledAt: json['cancelled_at'] != null
        ? DateTime.parse(json['cancelled_at'] as String)
        : null,
    cancellationReason: json['cancellation_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdBy: json['created_by'] as String?,
    updatedBy: json['updated_by'] as String?,
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    patientName: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    patientPhone: json['patients'] != null
        ? (json['patients'] as Map<String, dynamic>)['phone'] as String?
        : null,
    doctorName: json['doctors'] != null
        ? (json['doctors'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    pharmacyName: json['pharmacies'] != null
        ? (json['pharmacies'] as Map<String, dynamic>)['name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    prescriptionNumber,
    patientId,
    doctorId,
    pharmacyId,
    prescribedAt,
    validUntil,
    status,
    diagnosis,
    notes,
    isRenewable,
    renewableCount,
    renewableUsed,
    consultationId,
    qrCode,
    accessCode,
    validatedAt,
    dispensedAt,
    cancelledAt,
    cancellationReason,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    doctorName,
    pharmacyName,
  ];

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'sent':
        return 'Envoyée';
      case 'received':
        return 'Reçue';
      case 'validated':
        return 'Validée';
      case 'dispensed':
        return 'Dispensée';
      case 'expired':
        return 'Expirée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status) {
      case 'draft':
        return '📄';
      case 'sent':
        return '📤';
      case 'received':
        return '📥';
      case 'validated':
        return '✅';
      case 'dispensed':
        return '💊';
      case 'expired':
        return '⏰';
      case 'cancelled':
        return '❌';
      default:
        return '📋';
    }
  }

  bool get isActive =>
      status != 'expired' && status != 'cancelled' && status != 'dispensed';
  bool get isPending => status == 'sent' || status == 'received';
  bool get isRenewableEligible => isRenewable && renewableUsed < renewableCount;
}
