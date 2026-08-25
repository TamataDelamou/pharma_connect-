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
}
