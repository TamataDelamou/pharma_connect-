import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'alert_type.dart';
import 'alert_severity.dart';
import 'alert_status.dart';

class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionParams;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? actionedAt;
  final String? userId;
  final String? pharmacyId;
  final bool isRead;
  final bool isActioned;
  final String? imageUrl;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    this.actionParams,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.readAt,
    this.actionedAt,
    this.userId,
    this.pharmacyId,
    this.isRead = false,
    this.isActioned = false,
    this.imageUrl,
  });

  Alert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    AlertStatus? status,
    String? title,
    String? message,
    String? actionLabel,
    String? actionRoute,
    Map<String, dynamic>? actionParams,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? actionedAt,
    String? userId,
    String? pharmacyId,
    bool? isRead,
    bool? isActioned,
    String? imageUrl,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      actionParams: actionParams ?? this.actionParams,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return PharmaConnectColors.accentRed;
      case AlertSeverity.warning:
        return PharmaConnectColors.accentOrange;
      case AlertSeverity.info:
        return PharmaConnectColors.accentCyan;
      case AlertSeverity.success:
        return PharmaConnectColors.accentGreen;
    }
  }

  String get severityIcon {
    switch (severity) {
      case AlertSeverity.critical:
        return '🔴';
      case AlertSeverity.warning:
        return '🟡';
      case AlertSeverity.info:
        return '🔵';
      case AlertSeverity.success:
        return '🟢';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AlertStatus.new_:
        return Icons.notifications_active;
      case AlertStatus.read:
        return Icons.notifications_off;
      case AlertStatus.dismissed:
        return Icons.delete_outline;
      case AlertStatus.actioned:
        return Icons.check_circle;
    }
  }

  String get statusLabel {
    switch (status) {
      case AlertStatus.new_:
        return 'Nouveau';
      case AlertStatus.read:
        return 'Lu';
      case AlertStatus.dismissed:
        return 'Ignoré';
      case AlertStatus.actioned:
        return 'Traité';
    }
  }
}
