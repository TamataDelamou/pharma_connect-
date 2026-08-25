class EPrescription {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final String doctorLicense;
  final String doctorSpecialty;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final List<EPrescriptionItem> items;
  final String status; // draft, signed, sent, dispensed, expired
  final String? qrCode;
  final String? notes;
  final bool isUrgent;

  const EPrescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.doctorLicense,
    required this.doctorSpecialty,
    required this.issuedAt,
    this.expiresAt,
    required this.items,
    required this.status,
    this.qrCode,
    this.notes,
    this.isUrgent = false,
  });
}

class EPrescriptionItem {
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final bool isSubstitutionAllowed;

  const EPrescriptionItem({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.isSubstitutionAllowed = false,
  });
}
