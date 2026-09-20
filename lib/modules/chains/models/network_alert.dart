import 'package:flutter/material.dart' show Color;
import 'package:equatable/equatable.dart';
import 'package:pharma_connect/core/theme/colors.dart';

class NetworkAlert extends Equatable {
  final String id;
  final String? pharmacyGroupId;
  final String severity; // critical, high, medium, low
  final String type; // stock, sales, user, system, compliance
  final String title;
  final String? description;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const NetworkAlert({
    required this.id,
    this.pharmacyGroupId,
    required this.severity,
    required this.type,
    required this.title,
    this.description,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  NetworkAlert copyWith({
    String? id,
    String? pharmacyGroupId,
    String? severity,
    String? type,
    String? title,
    String? description,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return NetworkAlert(
      id: id ?? this.id,
      pharmacyGroupId: pharmacyGroupId ?? this.pharmacyGroupId,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
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
    if (pharmacyGroupId != null) 'pharmacy_group_id': pharmacyGroupId,
    'severity': severity,
    'type': type,
    'title': title,
    if (description != null) 'description': description,
    'is_read': isRead,
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory NetworkAlert.fromJson(Map<String, dynamic> json) => NetworkAlert(
    id: json['id'] as String,
    pharmacyGroupId: json['pharmacy_group_id'] as String?,
    severity: json['severity'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    readAt: json['read_at'] != null
        ? DateTime.parse(json['read_at'] as String)
        : null,
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
    pharmacyGroupId,
    severity,
    type,
    title,
    description,
    isRead,
    readAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get severityLabel {
    switch (severity) {
      case 'critical':
        return '🔴 Critique';
      case 'high':
        return '🟠 Élevée';
      case 'medium':
        return '🟡 Moyenne';
      case 'low':
        return '🟢 Basse';
      default:
        return severity;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'stock':
        return '📦 Stock';
      case 'sales':
        return '💰 Ventes';
      case 'user':
        return '👤 Utilisateur';
      case 'system':
        return '⚙️ Système';
      case 'compliance':
        return '📋 Conformité';
      default:
        return type;
    }
  }

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return PharmaConnectColors.accentRed;
      case 'high':
        return PharmaConnectColors.accentAmber;
      case 'medium':
        return PharmaConnectColors.accentOrange;
      case 'low':
        return PharmaConnectColors.accentGreen;
      default:
        return PharmaConnectColors.textSecondary;
    }
  }
}
