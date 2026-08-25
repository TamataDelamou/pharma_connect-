class DeliveryProof {
  final String? signatureData; // Base64 de la signature
  final String? imageUrl; // Photo de la livraison
  final String? confirmationCode; // Code de confirmation
  final DateTime timestamp;
  final String? recipientName;
  final String? recipientPhone;
  final String? notes;

  const DeliveryProof({
    this.signatureData,
    this.imageUrl,
    this.confirmationCode,
    required this.timestamp,
    this.recipientName,
    this.recipientPhone,
    this.notes,
  });

  DeliveryProof copyWith({
    String? signatureData,
    String? imageUrl,
    String? confirmationCode,
    DateTime? timestamp,
    String? recipientName,
    String? recipientPhone,
    String? notes,
  }) {
    return DeliveryProof(
      signatureData: signatureData ?? this.signatureData,
      imageUrl: imageUrl ?? this.imageUrl,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      timestamp: timestamp ?? this.timestamp,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      notes: notes ?? this.notes,
    );
  }

  bool get hasSignature => signatureData != null;
  bool get hasPhoto => imageUrl != null;
  bool get hasConfirmationCode => confirmationCode != null;
}
