import 'package:equatable/equatable.dart';

class SupportTicket extends Equatable {
  final String id;
  final String ticketNumber;
  final String patientId;
  final String? categoryId;
  final String subject;
  final String description;
  final String
  status; // new, in_progress, waiting_for_patient, resolved, closed, cancelled
  final String priority; // low, medium, high, critical
  final String? assignedTo;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final int escalationLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived fields
  final String? patientName;
  final String? patientPhone;
  final String? assigneeName;
  final String? categoryName;
  final int? responseCount;
  final bool? hasFeedback;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.patientId,
    this.categoryId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.resolvedAt,
    this.closedAt,
    this.escalationLevel = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.patientPhone,
    this.assigneeName,
    this.categoryName,
    this.responseCount,
    this.hasFeedback,
  });

  SupportTicket copyWith({
    String? id,
    String? ticketNumber,
    String? patientId,
    String? categoryId,
    String? subject,
    String? description,
    String? status,
    String? priority,
    String? assignedTo,
    DateTime? resolvedAt,
    DateTime? closedAt,
    int? escalationLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? patientPhone,
    String? assigneeName,
    String? categoryName,
    int? responseCount,
    bool? hasFeedback,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      patientId: patientId ?? this.patientId,
      categoryId: categoryId ?? this.categoryId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      assigneeName: assigneeName ?? this.assigneeName,
      categoryName: categoryName ?? this.categoryName,
      responseCount: responseCount ?? this.responseCount,
      hasFeedback: hasFeedback ?? this.hasFeedback,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_number': ticketNumber,
    'patient_id': patientId,
    if (categoryId != null) 'category_id': categoryId,
    'subject': subject,
    'description': description,
    'status': status,
    'priority': priority,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
    'escalation_level': escalationLevel,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    ticketNumber: json['ticket_number'] as String,
    patientId: json['patient_id'] as String,
    categoryId: json['category_id'] as String?,
    subject: json['subject'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    priority: json['priority'] as String,
    assignedTo: json['assigned_to'] as String?,
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'] as String)
        : null,
    closedAt: json['closed_at'] != null
        ? DateTime.parse(json['closed_at'] as String)
        : null,
    escalationLevel: json['escalation_level'] as int? ?? 0,
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
    assigneeName: json['assignees'] != null
        ? (json['assignees'] as Map<String, dynamic>)['full_name'] as String?
        : null,
    categoryName: json['categories'] != null
        ? (json['categories'] as Map<String, dynamic>)['name'] as String?
        : null,
    responseCount: json['responses'] != null
        ? (json['responses'] as List).length
        : null,
    hasFeedback: json['feedbacks'] != null
        ? (json['feedbacks'] as List).isNotEmpty
        : false,
  );

  @override
  List<Object?> get props => [
    id,
    ticketNumber,
    patientId,
    categoryId,
    subject,
    description,
    status,
    priority,
    assignedTo,
    resolvedAt,
    closedAt,
    escalationLevel,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    patientPhone,
    assigneeName,
    categoryName,
    responseCount,
    hasFeedback,
  ];

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Nouveau';
      case 'in_progress':
        return 'En cours';
      case 'waiting_for_patient':
        return 'Attente patient';
      case 'resolved':
        return 'Résolu';
      case 'closed':
        return 'Fermé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Bas';
      case 'medium':
        return 'Moyen';
      case 'high':
        return 'Élevé';
      case 'critical':
        return 'Critique';
      default:
        return priority;
    }
  }

  bool get isOpen =>
      status == 'new' ||
      status == 'in_progress' ||
      status == 'waiting_for_patient';
  bool get isClosed =>
      status == 'resolved' || status == 'closed' || status == 'cancelled';
}
