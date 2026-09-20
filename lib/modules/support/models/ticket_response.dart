import 'package:equatable/equatable.dart';

class TicketResponse extends Equatable {
  final String id;
  final String ticketId;
  final String authorId;
  final String message;
  final bool isInternal;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? authorName;

  const TicketResponse({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.message,
    this.isInternal = false,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
    this.authorName,
  });

  TicketResponse copyWith({
    String? id,
    String? ticketId,
    String? authorId,
    String? message,
    bool? isInternal,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
    String? authorName,
  }) => TicketResponse(
    id: id ?? this.id,
    ticketId: ticketId ?? this.ticketId,
    authorId: authorId ?? this.authorId,
    message: message ?? this.message,
    isInternal: isInternal ?? this.isInternal,
    attachments: attachments ?? this.attachments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    authorName: authorName ?? this.authorName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_id': ticketId,
    'author_id': authorId,
    'message': message,
    'is_internal': isInternal,
    'attachments': attachments,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory TicketResponse.fromJson(Map<String, dynamic> json) => TicketResponse(
    id: json['id'] as String,
    ticketId: json['ticket_id'] as String,
    authorId: json['author_id'] as String,
    message: json['message'] as String,
    isInternal: json['is_internal'] as bool? ?? false,
    attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
    authorName: json['authors'] != null
        ? (json['authors'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    ticketId,
    authorId,
    message,
    isInternal,
    attachments,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
    authorName,
  ];
}
