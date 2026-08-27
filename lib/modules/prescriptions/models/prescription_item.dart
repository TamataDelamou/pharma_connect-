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

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        id: json['id'] as String,
        prescriptionId: json['prescription_id'] as String? ?? '',
        medicationName: json['medication_name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        duration: json['duration'] as String,
        quantity: json['quantity'] as int,
        instructions: json['instructions'] as String?,
        isSubstitutionAllowed:
            json['is_substitution_allowed'] as bool? ?? false,
        suggestedGenericId: json['suggested_generic_id'] as String?,
        isExtractedByOcr: json['is_extracted_by_ocr'] as bool? ?? false,
        ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'prescription_id': prescriptionId.isEmpty ? null : prescriptionId,
    'medication_name': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'quantity': quantity,
    'instructions': instructions,
    'is_substitution_allowed': isSubstitutionAllowed,
    'suggested_generic_id': suggestedGenericId,
    'is_extracted_by_ocr': isExtractedByOcr,
    'ocr_confidence': ocrConfidence,
  };

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
