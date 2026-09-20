import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/consultation.dart';
import '../models/consultation_status.dart';
import '../models/availability_slot.dart';

// Audit Module 15 (CNS, 29/08/2026) : `getConsultationsForUser`/
// `getConsultation` embarquaient `professionals:professional_id(full_name,
// specialty)` — `specialty` n'existe PAS sur `public.profiles` (elle vit
// sur `public.professional_profiles`, table distincte à même clé primaire,
// voir 20260827005500_professionals.sql) — PostgREST rejetait la requête
// dans son intégralité (colonne inexistante), cassant les deux méthodes de
// lecture principales du module, même sévérité que C48/C52 (Modules 13/14).
// Corrigé en emboîtant un second embed (`professional_profiles(specialty)`)
// à l'intérieur du premier — valide car `professional_profiles.id`
// référence `profiles.id` (relation un-à-un exploitable par PostgREST).
// Ce correctif ne suffit pas seul : sans la policy RLS
// `profiles_select_professionals_public` (migration
// 20260829042000_teleconsult_module_fixes.sql), l'embed `profiles`
// reviendrait silencieusement `null` pour tout patient — voir ce fichier de
// migration pour le détail du gap RLS découvert ce module (registre C61).
class TeleconsultService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Consultations ----

  Future<List<Consultation>> getConsultationsForUser({
    required String userId,
    bool asProfessional = false,
    ConsultationStatus? status,
  }) async {
    try {
      final field = asProfessional ? 'professional_id' : 'patient_id';
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('consultations')
          .select(
            '*, patients:patient_id(full_name, phone), '
            'professionals:professional_id(full_name, professional_profiles(specialty))',
          )
          .eq(field, userId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('scheduled_at', ascending: true);
      return (response as List)
          .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load consultations: $e');
    }
  }

  Future<Consultation?> getConsultation(String id) async {
    try {
      final response = await _client
          .from('consultations')
          .select(
            '*, patients:patient_id(full_name, phone), '
            'professionals:professional_id(full_name, professional_profiles(specialty))',
          )
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Consultation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load consultation: $e');
    }
  }

  Future<Consultation> createConsultation(Consultation consultation) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = consultation
          .copyWith(
            id: newId,
            status: ConsultationStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      // Remove derived fields that are not in the table
      data.removeWhere(
        (key, value) =>
            key == 'patient_name' ||
            key == 'patient_phone' ||
            key == 'professional_name' ||
            key == 'professional_specialty',
      );

      final response = await _client
          .from('consultations')
          .insert(data)
          .select()
          .single();
      return Consultation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create consultation: $e');
    }
  }

  Future<Consultation> updateConsultation(Consultation consultation) async {
    try {
      final data = consultation
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
          .from('consultations')
          .update(data)
          .eq('id', consultation.id)
          .select()
          .single();
      return Consultation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update consultation: $e');
    }
  }

  Future<Consultation> updateConsultationStatus(
    String id,
    ConsultationStatus newStatus, {
    String? professionalNotes,
  }) async {
    try {
      final data = {
        'status': newStatus.name,
        if (professionalNotes != null) 'professional_notes': professionalNotes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('consultations')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Consultation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update consultation status: $e');
    }
  }

  Future<void> deleteConsultation(String id) async {
    try {
      await _client.from('consultations').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete consultation: $e');
    }
  }

  // ---- Availability ----

  Future<List<AvailabilitySlot>> getAvailabilitySlots(
    String professionalId,
  ) async {
    try {
      final response = await _client
          .from('availability_slots')
          .select()
          .eq('professional_id', professionalId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true);
      return (response as List)
          .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load availability slots: $e');
    }
  }

  Future<AvailabilitySlot> createAvailabilitySlot(AvailabilitySlot slot) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now().toUtc();
      final data = slot
          .copyWith(id: newId, createdAt: now, updatedAt: now)
          .toJson();
      final response = await _client
          .from('availability_slots')
          .insert(data)
          .select()
          .single();
      return AvailabilitySlot.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create availability slot: $e');
    }
  }

  Future<AvailabilitySlot> updateAvailabilitySlot(AvailabilitySlot slot) async {
    try {
      final data = slot.copyWith(updatedAt: DateTime.now().toUtc()).toJson();
      final response = await _client
          .from('availability_slots')
          .update(data)
          .eq('id', slot.id)
          .select()
          .single();
      return AvailabilitySlot.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update availability slot: $e');
    }
  }

  Future<void> deleteAvailabilitySlot(String id) async {
    try {
      await _client.from('availability_slots').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete availability slot: $e');
    }
  }

  // ---- Professionals ----

  /// Audit Module 15 (CNS, 29/08/2026) : remplace `_mockProfessionals`
  /// (liste codée en dur, IDs `pro_1`/`pro_2`/`pro_3` — pas des UUID
  /// valides, toute réservation réelle échouait côté base avec
  /// `invalid input syntax for type uuid`, et même corrigé en UUID aucun
  /// professionnel réel n'aurait jamais reçu la demande) dans
  /// `teleconsult_booking_screen.dart`. Interroge les comptes
  /// `professional_profiles` réellement vérifiés (`is_verified = true`) et
  /// ouverts à de nouveaux patients, avec le nom embarqué depuis `profiles`
  /// — nécessite la policy `profiles_select_professionals_public` (migration
  /// 20260829042000_teleconsult_module_fixes.sql) pour ne pas revenir `null`
  /// (voir le commentaire en tête de fichier).
  ///
  /// Audit Module 15 (CNS, 29/08/2026), 2ème refus de clôture, point de
  /// contrôle « annuaire des professionnels réels […] sans fuite de données
  /// personnelles non médicales » : cette requête embarquait initialement
  /// `profiles(full_name, phone)` alors qu'aucun écran ne lit/affiche ce
  /// numéro (vérifié — `teleconsult_booking_screen.dart` n'utilise que
  /// `full_name` via `_professionalName()`). Minimisation appliquée :
  /// `phone` retiré de la sélection. Limite documentée et non résolue par ce
  /// correctif (voir le registre, item D27) : la RLS Postgres est de
  /// granularité LIGNE et non colonne — la policy `profiles_select_
  /// professionals_public` autorise toujours, au niveau base, la lecture du
  /// `phone` d'un compte `professionnel` par tout utilisateur authentifié
  /// via un appel direct à l'API REST Supabase (hors de cette requête
  /// applicative). Une restriction hermétique nécessiterait soit une vue
  /// dédiée exposant uniquement les colonnes non sensibles, soit un GRANT/
  /// REVOKE au niveau colonne sur `public.profiles` — non entrepris dans ce
  /// correctif car cela toucherait aussi la relecture de son PROPRE profil
  /// (`ProfileService.upsertProfile()`, `.select()` sans restriction de
  /// colonnes) sans environnement disponible ici pour vérifier l'absence de
  /// régression (`flutter analyze`/tests réels, indisponibles — voir A1).
  Future<List<Map<String, dynamic>>> getAvailableProfessionals() async {
    try {
      final response = await _client
          .from('professional_profiles')
          .select(
            'id, specialty, bio, consultation_fee, is_accepting_new_patients, '
            'profiles(full_name)',
          )
          .eq('is_verified', true)
          .eq('is_accepting_new_patients', true)
          .order('specialty', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load available professionals: $e');
    }
  }

  // ---- Helpers ----

  /// Generate available time slots for a given date based on professional's recurring slots
  Future<List<DateTime>> getAvailableSlotsForDate({
    required String professionalId,
    required DateTime date,
  }) async {
    final dayOfWeek = date.weekday % 7; // 0=Sunday
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
        // Check if slot is in the future and not booked
        if (currentStart.isAfter(now)) {
          // Check if already booked
          final existing = await _client
              .from('consultations')
              .select('id')
              .eq('professional_id', professionalId)
              .eq('scheduled_at', currentStart.toIso8601String())
              .eq('status', ConsultationStatus.confirmed.name)
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
