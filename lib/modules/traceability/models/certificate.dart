class Certificate {
  final String id;
  final String batchId;
  final String type; // coa, coo, coc, etc.
  final String title;
  final String? url;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String issuedBy;
  final String? verificationUrl;
  final bool isValid;

  const Certificate({
    required this.id,
    required this.batchId,
    required this.type,
    required this.title,
    this.url,
    required this.issuedAt,
    this.expiresAt,
    required this.issuedBy,
    this.verificationUrl,
    this.isValid = true,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'] as String,
    batchId: json['batch_id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    url: json['url'] as String?,
    issuedAt: DateTime.parse(json['issued_at'] as String),
    expiresAt: json['expires_at'] != null
        ? DateTime.parse(json['expires_at'] as String)
        : null,
    issuedBy: json['issued_by'] as String,
    verificationUrl: json['verification_url'] as String?,
    isValid: json['is_valid'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_id': batchId,
    'type': type,
    'title': title,
    'url': url,
    'issued_at': issuedAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'issued_by': issuedBy,
    'verification_url': verificationUrl,
    'is_valid': isValid,
  };
}
