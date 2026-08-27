class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String resource;
  final String resourceId;
  final Map<String, dynamic>? changes;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.resource,
    required this.resourceId,
    this.changes,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'] as String,
    userId: json['user_id'] as String? ?? '',
    userName: json['user_name'] as String,
    action: json['action'] as String,
    resource: json['resource'] as String,
    resourceId: json['resource_id'] as String,
    changes: json['changes'] as Map<String, dynamic>?,
    ipAddress: json['ip_address'] as String? ?? '',
    userAgent: json['user_agent'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
    isSuccess: json['is_success'] as bool? ?? true,
    errorMessage: json['error_message'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId.isEmpty ? null : userId,
    'user_name': userName,
    'action': action,
    'resource': resource,
    'resource_id': resourceId,
    'changes': changes,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'timestamp': timestamp.toIso8601String(),
    'is_success': isSuccess,
    'error_message': errorMessage,
  };
}
