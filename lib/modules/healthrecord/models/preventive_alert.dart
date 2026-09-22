import 'package:equatable/equatable.dart';

class PreventiveAlert extends Equatable {
  final String id;
  final String patientId;
  final String
  alertType; // vaccination, screening, medication_refill, checkup, lifestyle
  final Map<String, dynamic> triggerCondition;
  final String messageTemplate;
  final bool isActive;
  final DateTime? lastTriggered;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const PreventiveAlert({
    required this.id,
    required this.patientId,
    required this.alertType,
    required this.triggerCondition,
    required this.messageTemplate,
    this.isActive = true,
    this.lastTriggered,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  PreventiveAlert copyWith({
    String? id,
    String? patientId,
    String? alertType,
    Map<String, dynamic>? triggerCondition,
    String? messageTemplate,
    bool? isActive,
    DateTime? lastTriggered,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return PreventiveAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      alertType: alertType ?? this.alertType,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      isActive: isActive ?? this.isActive,
      lastTriggered: lastTriggered ?? this.lastTriggered,
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
    'patient_id': patientId,
    'alert_type': alertType,
    'trigger_condition': triggerCondition,
    'message_template': messageTemplate,
    'is_active': isActive,
    if (lastTriggered != null)
      'last_triggered': lastTriggered!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory PreventiveAlert.fromJson(Map<String, dynamic> json) =>
      PreventiveAlert(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        alertType: json['alert_type'] as String,
        triggerCondition:
            json['trigger_condition'] as Map<String, dynamic>? ?? {},
        messageTemplate: json['message_template'] as String,
        isActive: json['is_active'] as bool? ?? true,
        lastTriggered: json['last_triggered'] != null
            ? DateTime.parse(json['last_triggered'] as String)
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
    patientId,
    alertType,
    triggerCondition,
    messageTemplate,
    isActive,
    lastTriggered,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (alertType) {
      case 'vaccination':
        return '💉 Vaccination';
      case 'screening':
        return '🔬 Dépistage';
      case 'medication_refill':
        return '💊 Renouvellement';
      case 'checkup':
        return '🩺 Bilan de santé';
      case 'lifestyle':
        return '🧘 Mode de vie';
      default:
        return alertType;
    }
  }

  String get previewMessage {
    return messageTemplate.replaceAll('{patient_name}', 'Patient');
  }
}
