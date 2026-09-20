import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/eprescription.dart';
import '../models/eprescription_item.dart';
import '../models/eprescription_history.dart';

class EPrescriptionService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Prescriptions ----

  Future<List<EPrescription>> getPrescriptions({
    String? patientId,
    String? doctorId,
    String? pharmacyId,
    String? status,
    bool? isActive,
  }) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : .order()
      // faisait passer le type de PostgrestFilterBuilder (qui a .eq/.inFilter)
      // à PostgrestTransformBuilder (qui ne les a plus) avant même que les
      // filtres conditionnels ne soient appliqués — déplacé après.
      var query = _client
          .from('eprescriptions')
          .select('*, patients:patient_id(full_name, phone), doctors:doctor_id(full_name), pharmacies:pharmacy_id(name)');

      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }
      if (doctorId != null) {
        query = query.eq('doctor_id', doctorId);
      }
      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (isActive != null && isActive) {
        // PRE-1 (audit Module 25, Étape 2/3, 30/08/2026) : `.in(...)` était
        // utilisé comme nom de méthode — `in` est un mot-clé réservé du
        // langage Dart, erreur de syntaxe certaine (pas seulement une
        // méthode inexistante). Corrigé par `.inFilter()`, la méthode
        // réelle du client Supabase-Dart, déjà utilisée correctement
        // ailleurs dans ce projet (`InsuranceService.calculateCoverage()`).
        query = query.inFilter('status', ['sent', 'received', 'validated']);
      }

      final response = await query.order('prescribed_at', ascending: false);
      return (response as List)
          .map((e) => EPrescription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load e-prescriptions: $e');
    }
  }

  Future<EPrescription?> getPrescription(String id) async {
    try {
      final response = await _client
          .from('eprescriptions')
          .select('*, patients:patient_id(full_name, phone), doctors:doctor_id(full_name), pharmacies:pharmacy_id(name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return EPrescription.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load e-prescription: $e');
    }
  }

  Future<EPrescription> createPrescription(EPrescription prescription) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = prescription.copyWith(
        id: newId,
        status: 'draft',
        prescribedAt: now,
        createdAt: now,
        updatedAt: now,
        createdBy: SupabaseService().currentUser?.id,
        updatedBy: SupabaseService().currentUser?.id,
      ).toJson();
      data.removeWhere((key, value) =>
          key == 'patient_name' ||
          key == 'patient_phone' ||
          key == 'doctor_name' ||
          key == 'pharmacy_name' ||
          key == 'patients' ||
          key == 'doctors' ||
          key == 'pharmacies');

      final response = await _client
          .from('eprescriptions')
          .insert(data)
          .select()
          .single();
      return EPrescription.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create e-prescription: $e');
    }
  }

  Future<EPrescription> updatePrescription(EPrescription prescription) async {
    try {
      final data = prescription.copyWith(
        updatedAt: DateTime.now().toUtc(),
        updatedBy: SupabaseService().currentUser?.id,
      ).toJson();
      data.removeWhere((key, value) =>
          key == 'patient_name' ||
          key == 'patient_phone' ||
          key == 'doctor_name' ||
          key == 'pharmacy_name' ||
          key == 'patients' ||
          key == 'doctors' ||
          key == 'pharmacies');

      final response = await _client
          .from('eprescriptions')
          .update(data)
          .eq('id', prescription.id)
          .select()
          .single();
      return EPrescription.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update e-prescription: $e');
    }
  }

  Future<EPrescription> updatePrescriptionStatus(String id, String newStatus, {String? notes}) async {
    try {
      final data = {
        'status': newStatus,
        if (newStatus == 'validated') 'validated_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'dispensed') 'dispensed_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == 'cancelled') 'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        if (notes != null) 'cancellation_reason': notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('eprescriptions')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return EPrescription.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update e-prescription status: $e');
    }
  }

  Future<void> deletePrescription(String id) async {
    try {
      await _client.from('eprescriptions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete e-prescription: $e');
    }
  }

  // ---- Items ----

  Future<List<EPrescriptionItem>> getItems(String prescriptionId) async {
    try {
      final response = await _client
          .from('eprescription_items')
          .select()
          .eq('eprescription_id', prescriptionId);
      return (response as List)
          .map((e) => EPrescriptionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load items: $e');
    }
  }

  Future<EPrescriptionItem> addItem(EPrescriptionItem item) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = item.copyWith(
        id: newId,
        createdAt: now,
        updatedAt: now,
      ).toJson();
      final response = await _client
          .from('eprescription_items')
          .insert(data)
          .select()
          .single();
      return EPrescriptionItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<EPrescriptionItem> updateItem(EPrescriptionItem item) async {
    try {
      final data = item.copyWith(
        updatedAt: DateTime.now().toUtc(),
      ).toJson();
      final response = await _client
          .from('eprescription_items')
          .update(data)
          .eq('id', item.id)
          .select()
          .single();
      return EPrescriptionItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _client.from('eprescription_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // ---- History ----

  Future<List<EPrescriptionHistory>> getHistory(String prescriptionId) async {
    try {
      final response = await _client
          .from('eprescription_history')
          .select()
          .eq('eprescription_id', prescriptionId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((e) => EPrescriptionHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }
}
