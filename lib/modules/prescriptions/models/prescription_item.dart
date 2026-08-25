class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final String? instructions;
  final bool isSubstitutionAllowed;
  final String? suggestedGenericId;
  final bool isExtractedByOcr;
  final double ocrConfidence;

  PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.instructions,
    this.isSubstitutionAllowed = false,
    this.suggestedGenericId,
    this.isExtractedByOcr = false,
    this.ocrConfidence = 0.0,
  });

  PrescriptionItem copyWith({
    String? id,
    String? prescriptionId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    int? quantity,
    String? instructions,
    bool? isSubstitutionAllowed,
    String? suggestedGenericId,
    bool? isExtractedByOcr,
    double? ocrConfidence,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      quantity: quantity ?? this.quantity,
      instructions: instructions ?? this.instructions,
      isSubstitutionAllowed:
          isSubstitutionAllowed ?? this.isSubstitutionAllowed,
      suggestedGenericId: suggestedGenericId ?? this.suggestedGenericId,
      isExtractedByOcr: isExtractedByOcr ?? this.isExtractedByOcr,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
    );
  }

  String get displayName {
    if (isExtractedByOcr) {
      return '$medicationName (OCR)';
    }
    return medicationName;
  }

  bool get hasGenericAlternative => suggestedGenericId != null;
}
