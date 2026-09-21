import 'package:equatable/equatable.dart';

class BotMessage extends Equatable {
  final String id;
  final String sender; // 'user' or 'bot'
  final String text;
  final DateTime timestamp;
  final bool isTyping; // For UI animation

  const BotMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isTyping = false,
  });

  BotMessage copyWith({
    String? id,
    String? sender,
    String? text,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return BotMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'is_typing': isTyping,
  };

  factory BotMessage.fromJson(Map<String, dynamic> json) => BotMessage(
    id: json['id'] as String,
    sender: json['sender'] as String,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isTyping: json['is_typing'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, sender, text, timestamp, isTyping];
}

class BotConversation extends Equatable {
  final String id;
  final String patientId;
  final List<BotMessage> messages;
  final String status; // active, escalated, resolved, abandoned
  final String? escalationReason;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const BotConversation({
    required this.id,
    required this.patientId,
    this.messages = const [],
    this.status = 'active',
    this.escalationReason,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  BotConversation copyWith({
    String? id,
    String? patientId,
    List<BotMessage>? messages,
    String? status,
    String? escalationReason,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return BotConversation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      escalationReason: escalationReason ?? this.escalationReason,
      resolvedAt: resolvedAt ?? this.resolvedAt,
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
    'messages': messages.map((m) => m.toJson()).toList(),
    'status': status,
    if (escalationReason != null) 'escalation_reason': escalationReason,
    if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory BotConversation.fromJson(Map<String, dynamic> json) =>
      BotConversation(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        messages:
            (json['messages'] as List?)
                ?.map((e) => BotMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        status: json['status'] as String? ?? 'active',
        escalationReason: json['escalation_reason'] as String?,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
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
    messages,
    status,
    escalationReason,
    resolvedAt,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
  bool get isEscalated => status == 'escalated';
}
