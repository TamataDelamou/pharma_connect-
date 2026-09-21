import 'package:equatable/equatable.dart';

class PreventiveAlertHistory extends Equatable {
  final String id;
  final String alertId;
  final String patientId;
  final DateTime sentAt;
  final String status; // pending, sent, dismissed, actioned
  final String? actionTaken;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const PreventiveAlertHistory({
    required this.id,
    required this.alertId,
    required this.patientId,
    required this.sentAt,
    required this.status,
    this.actionTaken,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  PreventiveAlertHistory copyWith({
    String? id,
    String? alertId,
    String? patientId,
    DateTime? sentAt,
    String? status,
    String? actionTaken,
    DateTime? createdAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return PreventiveAlertHistory(
      id: id ?? this.id,
      alertId: alertId ?? this.alertId,
      patientId: patientId ?? this.patientId,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alert_id': alertId,
    'patient_id': patientId,
    'sent_at': sentAt.toIso8601String(),
    'status': status,
    if (actionTaken != null) 'action_taken': actionTaken,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory PreventiveAlertHistory.fromJson(Map<String, dynamic> json) =>
      PreventiveAlertHistory(
        id: json['id'] as String,
        alertId: json['alert_id'] as String,
        patientId: json['patient_id'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
        status: json['status'] as String,
        actionTaken: json['action_taken'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    alertId,
    patientId,
    sentAt,
    status,
    actionTaken,
    createdAt,
    gsgId,
    gsgOrgId,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'sent':
        return 'Envoyée';
      case 'dismissed':
        return 'Ignorée';
      case 'actioned':
        return 'Actionnée';
      default:
        return status;
    }
  }
}
