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
}
