import 'pharmacy_status.dart';
import '../../../core/theme/palette.dart';

class AdminPharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? licenseNumber;
  final PharmacyStatus status;
  final DateTime? licenseExpiryDate;
  final String? managerId;
  final String? managerName;
  final String? groupId;
  final String? groupName;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? licenseVerifiedAt;
  final DateTime? statusUpdatedAt;
  final String? notes;

  AdminPharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.licenseNumber,
    required this.status,
    this.licenseExpiryDate,
    this.managerId,
    this.managerName,
    this.groupId,
    this.groupName,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    required this.createdAt,
    this.licenseVerifiedAt,
    this.statusUpdatedAt,
    this.notes,
  });

  factory AdminPharmacy.fromJson(Map<String, dynamic> json) => AdminPharmacy(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String? ?? '',
    licenseNumber: json['license_number'] as String?,
    status: PharmacyStatus.values.byName(json['status'] as String),
    licenseExpiryDate: json['license_expiry_date'] != null
        ? DateTime.parse(json['license_expiry_date'] as String)
        : null,
    managerId: json['manager_id'] as String?,
    managerName: json['manager_name'] as String?,
    groupId: json['group_id'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
    licenseVerifiedAt: json['license_verified_at'] != null
        ? DateTime.parse(json['license_verified_at'] as String)
        : null,
    statusUpdatedAt: json['status_updated_at'] != null
        ? DateTime.parse(json['status_updated_at'] as String)
        : null,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'license_number': licenseNumber,
    'status': status.name,
    'license_expiry_date': licenseExpiryDate?.toIso8601String(),
    'manager_id': managerId,
    'manager_name': managerName,
    'group_id': groupId,
    'latitude': latitude,
    'longitude': longitude,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'license_verified_at': licenseVerifiedAt?.toIso8601String(),
    'status_updated_at': statusUpdatedAt?.toIso8601String(),
    'notes': notes,
  };

  AdminPharmacy copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? licenseNumber,
    PharmacyStatus? status,
    DateTime? licenseExpiryDate,
    String? managerId,
    String? managerName,
    String? groupId,
    String? groupName,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? licenseVerifiedAt,
    DateTime? statusUpdatedAt,
    String? notes,
  }) {
    return AdminPharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      licenseVerifiedAt: licenseVerifiedAt ?? this.licenseVerifiedAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case PharmacyStatus.pending:
        return 'En attente de vérification';
      case PharmacyStatus.verified:
        return 'Vérifiée';
      case PharmacyStatus.active:
        return 'Active';
      case PharmacyStatus.suspended:
        return 'Suspendue';
      case PharmacyStatus.underReview:
        return 'En révision';
      case PharmacyStatus.rejected:
        return 'Rejetée';
    }
  }

  ColorRole get statusColor {
    switch (status) {
      case PharmacyStatus.pending:
        return ColorRole.warning;
      case PharmacyStatus.verified:
        return ColorRole.primary;
      case PharmacyStatus.active:
        return ColorRole.success;
      case PharmacyStatus.suspended:
        return ColorRole.danger;
      case PharmacyStatus.underReview:
        return ColorRole.warningStrong;
      case PharmacyStatus.rejected:
        return ColorRole.danger;
    }
  }

  bool get isPending => status == PharmacyStatus.pending;
  bool get isVerified => status == PharmacyStatus.verified;
}
