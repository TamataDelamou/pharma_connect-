import 'dart:math';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';

class PrescriptionService {
  static final List<Prescription> _prescriptions = [];
  static final Random _random = Random();

  // Simuler une base de données d'ordonnances
  static final List<Prescription> _mockPrescriptions = [
    _createMockPrescription(
      id: 'rx_001',
      patientName: 'Jean Dupont',
      doctorName: 'Dr. Martin',
      status: PrescriptionStatus.pending,
      items: [
        _createMockItem(
          'Amoxicilline 500mg',
          'Amoxicilline',
          '500 mg',
          '2x par jour',
          '7 jours',
        ),
        _createMockItem(
          'Paracétamol 1000mg',
          'Paracétamol',
          '1000 mg',
          '3x par jour',
          '3 jours',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_002',
      patientName: 'Marie Konaté',
      doctorName: 'Dr. Diallo',
      status: PrescriptionStatus.validated,
      items: [
        _createMockItem(
          'Ventoline 100µg',
          'Salbutamol',
          '100 µg',
          'A la demande',
          '1 mois',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_003',
      patientName: 'Ibrahim Camara',
      doctorName: 'Dr. Sow',
      status: PrescriptionStatus.dispensed,
      items: [
        _createMockItem(
          'Spasfon 80mg',
          'Phloroglucinol',
          '80 mg',
          '3x par jour',
          '5 jours',
        ),
        _createMockItem(
          'Doliprane 500mg',
          'Paracétamol',
          '500 mg',
          '2x par jour',
          '3 jours',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_004',
      patientName: 'Fatoumata Diallo',
      doctorName: 'Dr. Barry',
      status: PrescriptionStatus.archived,
      items: [
        _createMockItem(
          'Crestor 10mg',
          'Rosuvastatine',
          '10 mg',
          '1x par jour',
          '6 mois',
        ),
      ],
    ),
    _createMockPrescription(
      id: 'rx_005',
      patientName: 'Ousmane Sow',
      doctorName: 'Dr. Camara',
      status: PrescriptionStatus.draft,
      items: [],
    ),
  ];

  static PrescriptionItem _createMockItem(
    String name,
    String generic,
    String dosage,
    String frequency,
    String duration,
  ) {
    return PrescriptionItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      prescriptionId: '',
      medicationName: name,
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      quantity: 1 + _random.nextInt(3),
      instructions: _random.nextBool() ? 'A prendre avec de l\'eau' : null,
      isSubstitutionAllowed: _random.nextBool(),
      isExtractedByOcr: false,
      ocrConfidence: 1.0,
    );
  }

  static Prescription _createMockPrescription({
    required String id,
    required String patientName,
    required String doctorName,
    required PrescriptionStatus status,
    required List<PrescriptionItem> items,
  }) {
    final now = DateTime.now();
    return Prescription(
      id: id,
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      doctorName: doctorName,
      uploadedAt: now.subtract(Duration(hours: _random.nextInt(48))),
      validatedAt:
          status == PrescriptionStatus.validated ||
              status == PrescriptionStatus.dispensed
          ? now.subtract(Duration(hours: _random.nextInt(24)))
          : null,
      dispensedAt: status == PrescriptionStatus.dispensed
          ? now.subtract(Duration(hours: _random.nextInt(12)))
          : null,
      status: status,
      imageUrl: '',
      items: items.map((item) => item.copyWith(prescriptionId: id)).toList(),
      ocrConfidenceScore: 0.95,
    );
  }

  static void _initMockData() {
    if (_prescriptions.isEmpty) {
      _prescriptions.addAll(_mockPrescriptions);
    }
  }

  Future<List<Prescription>> getPrescriptions({
    PrescriptionStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _prescriptions.where((p) => p.status == status).toList();
    }
    return _prescriptions;
  }

  Future<Prescription> getPrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _prescriptions.firstWhere((p) => p.id == id);
  }

  Future<Prescription> createPrescription({
    required String patientId,
    required String patientName,
    required String imageUrl,
    required List<PrescriptionItem> items,
    String? doctorName,
    double? ocrConfidenceScore,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _initMockData();

    final id = 'rx_${DateTime.now().millisecondsSinceEpoch}';
    final prescription = Prescription(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      uploadedAt: DateTime.now(),
      status: PrescriptionStatus.pending,
      imageUrl: imageUrl,
      items: items.map((item) => item.copyWith(prescriptionId: id)).toList(),
      ocrConfidenceScore: ocrConfidenceScore ?? 0.9,
    );

    _prescriptions.add(prescription);
    return prescription;
  }

  Future<Prescription> validatePrescription(String id, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    final updated = _prescriptions[index].copyWith(
      status: PrescriptionStatus.validated,
      validatedAt: DateTime.now(),
      notes: notes,
    );
    _prescriptions[index] = updated;
    return updated;
  }

  Future<Prescription> dispensePrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    final updated = _prescriptions[index].copyWith(
      status: PrescriptionStatus.dispensed,
      dispensedAt: DateTime.now(),
    );
    _prescriptions[index] = updated;
    return updated;
  }

  Future<void> archivePrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final index = _prescriptions.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Prescription not found');

    _prescriptions[index] = _prescriptions[index].copyWith(
      status: PrescriptionStatus.archived,
    );
  }

  Future<List<Prescription>> searchPrescriptions(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();

    final lower = query.toLowerCase();
    return _prescriptions
        .where(
          (p) =>
              p.patientName.toLowerCase().contains(lower) ||
              (p.doctorName?.toLowerCase().contains(lower) ?? false) ||
              p.id.toLowerCase().contains(lower) ||
              p.items.any(
                (item) => item.medicationName.toLowerCase().contains(lower),
              ),
        )
        .toList();
  }
}
