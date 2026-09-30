import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';
import '../../../core/services/supabase_service.dart';

class PrescriptionService {
  SupabaseClient get _client => SupabaseService().client;

  static const _prescriptionSelect = '*, prescription_items(*)';

  Future<List<Prescription>> getPrescriptions({
    PrescriptionStatus? status,
  }) async {
    var query = _client.from('prescriptions').select(_prescriptionSelect);
    if (status != null) {
      query = query.eq('status', status.name);
    }
    final rows = await query.order('uploaded_at', ascending: false);
    return rows.map((row) => Prescription.fromJson(row)).toList();
  }

  Future<Prescription> getPrescription(String id) async {
    final row = await _client
        .from('prescriptions')
        .select(_prescriptionSelect)
        .eq('id', id)
        .single();
    return Prescription.fromJson(row);
  }

  Future<Prescription> createPrescription({
    required String patientId,
    required String patientName,
    required String imageUrl,
    required List<PrescriptionItem> items,
    String? doctorName,
    double? ocrConfidenceScore,
    String? pharmacyId,
  }) async {
    final prescription = Prescription(
      id: const Uuid().v4(),
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      uploadedAt: DateTime.now(),
      status: PrescriptionStatus.pending,
      imageUrl: imageUrl,
      items: const [],
      ocrConfidenceScore: ocrConfidenceScore ?? 0.9,
      pharmacyId: pharmacyId,
    );

    await _client.from('prescriptions').insert(prescription.toJson());

    if (items.isNotEmpty) {
      final itemRows = items
          .map(
            (item) => item
                .copyWith(
                  id: const Uuid().v4(),
                  prescriptionId: prescription.id,
                )
                .toJson(),
          )
          .toList();
      await _client.from('prescription_items').insert(itemRows);
    }

    return getPrescription(prescription.id);
  }

  Future<Prescription> validatePrescription(String id, {String? notes}) async {
    final row = await _client
        .from('prescriptions')
        .update({
          'status': PrescriptionStatus.validated.name,
          'validated_at': DateTime.now().toIso8601String(),
          'notes': notes,
        })
        .eq('id', id)
        .select(_prescriptionSelect)
        .single();
    return Prescription.fromJson(row);
  }

  Future<Prescription> dispensePrescription(String id) async {
    final row = await _client
        .from('prescriptions')
        .update({
          'status': PrescriptionStatus.dispensed.name,
          'dispensed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select(_prescriptionSelect)
        .single();
    return Prescription.fromJson(row);
  }

  Future<void> archivePrescription(String id) async {
    await _client
        .from('prescriptions')
        .update({'status': PrescriptionStatus.archived.name})
        .eq('id', id);
  }

  Future<List<Prescription>> searchPrescriptions(String query) async {
    final rows = await _client
        .from('prescriptions')
        .select(_prescriptionSelect);
    final prescriptions = rows
        .map((row) => Prescription.fromJson(row))
        .toList();

    final lower = query.toLowerCase();
    return prescriptions
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
