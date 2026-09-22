import 'package:equatable/equatable.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';

class AsyncMessage extends Equatable {
  final String id;
  final String? consultationId;
  final String patientId;
  final String professionalId;
  final String senderId;
  final String message;
  final List<String> attachments;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? senderName;

  const AsyncMessage({
    required this.id,
    this.consultationId,
    required this.patientId,
    required this.professionalId,
    required this.senderId,
    required this.message,
    this.attachments = const [],
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.senderName,
  });

  AsyncMessage copyWith({
    String? id,
    String? consultationId,
    String? patientId,
    String? professionalId,
    String? senderId,
    String? message,
    List<String>? attachments,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? senderName,
  }) {
    return AsyncMessage(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      patientId: patientId ?? this.patientId,
      professionalId: professionalId ?? this.professionalId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      attachments: attachments ?? this.attachments,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      senderName: senderName ?? this.senderName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (consultationId != null) 'consultation_id': consultationId,
    'patient_id': patientId,
    'professional_id': professionalId,
    'sender_id': senderId,
    'message': message,
    'attachments': attachments,
    'is_read': isRead,
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory AsyncMessage.fromJson(Map<String, dynamic> json) => AsyncMessage(
    id: json['id'] as String,
    consultationId: json['consultation_id'] as String?,
    patientId: json['patient_id'] as String,
    professionalId: json['professional_id'] as String,
    senderId: json['sender_id'] as String,
    message: json['message'] as String,
    attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
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
    senderName: json['senders'] != null
        ? (json['senders'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    consultationId,
    patientId,
    professionalId,
    senderId,
    message,
    attachments,
    isRead,
    readAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    senderName,
  ];

  bool get isMine => senderId == SupabaseService().currentUser?.id;
}
