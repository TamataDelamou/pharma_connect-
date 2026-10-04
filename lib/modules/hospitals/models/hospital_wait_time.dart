import 'package:flutter/material.dart' show Color;
import 'package:equatable/equatable.dart';
import 'package:pharma_connect/core/theme/palette.dart';

class HospitalWaitTime extends Equatable {
  final String id;
  final String hospitalId;
  final String department;
  final int waitTimeMinutes;
  final int patientsInQueue;
  final DateTime lastUpdated;
  final bool isAccurate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const HospitalWaitTime({
    required this.id,
    required this.hospitalId,
    required this.department,
    required this.waitTimeMinutes,
    this.patientsInQueue = 0,
    required this.lastUpdated,
    this.isAccurate = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  HospitalWaitTime copyWith({
    String? id,
    String? hospitalId,
    String? department,
    int? waitTimeMinutes,
    int? patientsInQueue,
    DateTime? lastUpdated,
    bool? isAccurate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return HospitalWaitTime(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      department: department ?? this.department,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
      patientsInQueue: patientsInQueue ?? this.patientsInQueue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAccurate: isAccurate ?? this.isAccurate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hospital_id': hospitalId,
    'department': department,
    'wait_time_minutes': waitTimeMinutes,
    'patients_in_queue': patientsInQueue,
    'last_updated': lastUpdated.toIso8601String(),
    'is_accurate': isAccurate,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HospitalWaitTime.fromJson(Map<String, dynamic> json) =>
      HospitalWaitTime(
        id: json['id'] as String,
        hospitalId: json['hospital_id'] as String,
        department: json['department'] as String,
        waitTimeMinutes: json['wait_time_minutes'] as int,
        patientsInQueue: json['patients_in_queue'] as int? ?? 0,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
        isAccurate: json['is_accurate'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    hospitalId,
    department,
    waitTimeMinutes,
    patientsInQueue,
    lastUpdated,
    isAccurate,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get waitTimeLabel {
    if (waitTimeMinutes < 15) return '🟢 Moins de 15 min';
    if (waitTimeMinutes < 30) return '🟡 15-30 min';
    if (waitTimeMinutes < 60) return '🟠 30-60 min';
    return '🔴 Plus de 1h';
  }

  ColorRole get waitTimeColor {
    if (waitTimeMinutes < 15) return ColorRole.success;
    if (waitTimeMinutes < 30) return ColorRole.warning;
    if (waitTimeMinutes < 60) return ColorRole.warningStrong;
    return ColorRole.danger;
  }
}
