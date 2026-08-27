import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'pharmacy_status.dart';

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

  Color get statusColor {
    switch (status) {
      case PharmacyStatus.pending:
        return PharmaConnectColors.accentOrange;
      case PharmacyStatus.verified:
        return PharmaConnectColors.accentCyan;
      case PharmacyStatus.active:
        return PharmaConnectColors.accentGreen;
      case PharmacyStatus.suspended:
        return PharmaConnectColors.accentRed;
      case PharmacyStatus.underReview:
        return PharmaConnectColors.accentAmber;
      case PharmacyStatus.rejected:
        return PharmaConnectColors.accentRed;
    }
  }

  bool get isPending => status == PharmacyStatus.pending;
  bool get isVerified => status == PharmacyStatus.verified;
}
