import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/intervention.dart';
import '../models/homecare_status.dart';
import '../models/homecare_availability_slot.dart';

class HomecareService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Interventions ----

  Future<List<Intervention>> getInterventionsForUser({
    required String userId,
    bool asProfessional = false,
    HomecareStatus? status,
  }) async {
    try {
      final field = asProfessional ? 'professional_id' : 'patient_id';
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('homecare_interventions')
          .select(
            '*, patients:patient_id(full_name, phone), professionals:professional_id(full_name, specialty)',
          )
          .eq(field, userId);

      if (status != null) {
        query = query.eq('status', status.dbValue);
      }

      final response = await query.order('scheduled_at', ascending: true);
      return (response as List)
          .map((e) => Intervention.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load interventions: $e');
    }
  }

  Future<Intervention?> getIntervention(String id) async {
    try {
      final response = await _client
          .from('homecare_interventions')
          .select(
            '*, patients:patient_id(full_name, phone), professionals:professional_id(full_name, specialty)',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Intervention.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load intervention: $e');
    }
  }

  Future<Intervention> createIntervention(Intervention intervention) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = intervention
          .copyWith(
            id: newId,
            status: HomecareStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      // Remove derived fields
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'professional_name' ||
            key == 'professional_specialty',
      );

      final response = await _client
          .from('homecare_interventions')
          .insert(data)
          .select()
          .single();
      return Intervention.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create intervention: $e');
    }
  }

  Future<Intervention> updateIntervention(Intervention intervention) async {
    try {
      final data = intervention
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'professional_name' ||
            key == 'professional_specialty',
      );

      final response = await _client
          .from('homecare_interventions')
          .update(data)
          .eq('id', intervention.id)
          .select()
          .single();
      return Intervention.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update intervention: $e');
    }
  }

  Future<Intervention> updateInterventionStatus(
    String id,
    HomecareStatus newStatus, {
    String? report,
    String? refusalReason,
    int? patientRating,
    String? patientFeedback,
  }) async {
    try {
      // Audit Module 18 (HOM, 30/08/2026), RG-HOM-03 (Standard) : « Une
      // intervention à domicile ne peut être close sans compte-rendu
      // structuré minimal. » Avant correctif, `report` était accepté tel
      // quel (y compris vide/null) par ce service comme par l'écran de
      // détail — une intervention pouvait donc être clôturée sans aucun
      // compte-rendu. Garde-fou ajouté ici en plus de la validation côté UI
      // (`homecare_detail_screen.dart`), pour ne pas dépendre uniquement de
      // l'écran.
      if (newStatus == HomecareStatus.completed &&
          (report == null || report.trim().isEmpty)) {
        throw Exception(
          'RG-HOM-03 : un compte-rendu est obligatoire pour clôturer une intervention',
        );
      }
      final data = {
        'status': newStatus.dbValue,
        if (report != null) 'report': report,
        if (refusalReason != null) 'refusal_reason': refusalReason,
        if (patientRating != null) 'patient_rating': patientRating,
        if (patientFeedback != null) 'patient_feedback': patientFeedback,
        if (newStatus == HomecareStatus.inProgress)
          'started_at': DateTime.now().toUtc().toIso8601String(),
        if (newStatus == HomecareStatus.completed)
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('homecare_interventions')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Intervention.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update intervention status: $e');
    }
  }

  Future<void> deleteIntervention(String id) async {
    try {
      await _client.from('homecare_interventions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete intervention: $e');
    }
  }

  // ---- Professionals ----

  // Audit Module 18 (HOM, 30/08/2026) : `HomecareBookingScreen` proposait
  // jusqu'ici une liste de professionnels codée en dur (`_mockProfessionals`,
  // IDs `pro_1`/`pro_2`, pas des UUID valides) — même défaut que C62
  // (Module 15, `TeleconsultBookingScreen`) : toute tentative de réservation
  // réelle aurait échoué côté base (`invalid input syntax for type uuid`).
  // Corrigé selon le même principe que C62 : interroger `professional_profiles`
  // réellement vérifiés, ici filtrés en plus sur `home_visit_fee is not null`
  // (seule colonne actuellement disponible signalant qu'un professionnel
  // propose des visites à domicile — aucun booléen dédié n'existe). Le
  // matching avancé du cahier (distance/langue/type d'acte) reste hors
  // périmètre de ce correctif minimal — voir le rapport d'audit, écart de
  // périmètre D31.
  Future<List<Map<String, dynamic>>> getAvailableProfessionals() async {
    try {
      final response = await _client
          .from('professional_profiles')
          .select(
            'id, specialty, bio, home_visit_fee, languages_spoken, '
            'is_accepting_new_patients, profiles(full_name)',
          )
          .eq('is_verified', true)
          .eq('is_accepting_new_patients', true)
          .not('home_visit_fee', 'is', null)
          .order('specialty', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load available professionals: $e');
    }
  }

  // ---- Availability ----

  Future<List<HomecareAvailabilitySlot>> getAvailabilitySlots(
    String professionalId,
  ) async {
    try {
      final response = await _client
          .from('homecare_availability_slots')
          .select()
          .eq('professional_id', professionalId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true);
      return (response as List)
          .map(
            (e) => HomecareAvailabilitySlot.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load availability slots: $e');
    }
  }

  Future<HomecareAvailabilitySlot> createAvailabilitySlot(
    HomecareAvailabilitySlot slot,
  ) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = slot
          .copyWith(id: newId, createdAt: now, updatedAt: now)
          .toJson();
      final response = await _client
          .from('homecare_availability_slots')
          .insert(data)
          .select()
          .single();
      return HomecareAvailabilitySlot.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to create availability slot: $e');
    }
  }

  Future<HomecareAvailabilitySlot> updateAvailabilitySlot(
    HomecareAvailabilitySlot slot,
  ) async {
    try {
      final data = slot.copyWith(updatedAt: DateTime.now().toUtc()).toJson();
      final response = await _client
          .from('homecare_availability_slots')
          .update(data)
          .eq('id', slot.id)
          .select()
          .single();
      return HomecareAvailabilitySlot.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to update availability slot: $e');
    }
  }

  Future<void> deleteAvailabilitySlot(String id) async {
    try {
      await _client.from('homecare_availability_slots').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete availability slot: $e');
    }
  }

  // ---- Helpers ----

  Future<List<DateTime>> getAvailableSlotsForDate({
    required String professionalId,
    required DateTime date,
  }) async {
    final dayOfWeek = date.weekday % 7;
    final slots = await getAvailabilitySlots(professionalId);
    final daySlots = slots.where((s) => s.dayOfWeek == dayOfWeek).toList();

    final availableSlots = <DateTime>[];
    final now = DateTime.now();

    for (final slot in daySlots) {
      final startParts = slot.startTime.split(':').map(int.parse).toList();
      final endParts = slot.endTime.split(':').map(int.parse).toList();

      DateTime currentStart = DateTime(
        date.year,
        date.month,
        date.day,
        startParts[0],
        startParts[1],
      );
      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        endParts[0],
        endParts[1],
      );

      while (currentStart.isBefore(endTime)) {
        if (currentStart.isAfter(now)) {
          // Check if already booked
          final existing = await _client
              .from('homecare_interventions')
              .select('id')
              .eq('professional_id', professionalId)
              .eq('scheduled_at', currentStart.toIso8601String())
              .eq('status', HomecareStatus.confirmed.dbValue)
              .maybeSingle();
          if (existing == null) {
            availableSlots.add(currentStart);
          }
        }
        currentStart = currentStart.add(
          Duration(minutes: slot.durationMinutes),
        );
      }
    }

    return availableSlots;
  }
}
