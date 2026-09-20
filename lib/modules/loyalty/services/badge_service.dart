import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/loyalty_badge.dart';
import '../models/patient_badge.dart';

class BadgeService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Badges ----

  Future<List<LoyaltyBadge>> getAllBadges() async {
    try {
      final response = await _client
          .from('loyalty_badges')
          .select()
          .eq('is_active', true)
          .order('category', ascending: true);
      return (response as List)
          .map((e) => LoyaltyBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load badges: $e');
    }
  }

  Future<LoyaltyBadge?> getBadge(String id) async {
    try {
      final response = await _client
          .from('loyalty_badges')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return LoyaltyBadge.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load badge: $e');
    }
  }

  // ---- Patient Badges ----

  Future<List<PatientBadge>> getPatientBadges(String patientId) async {
    try {
      final response = await _client
          .from('patient_badges')
          .select('*, badges:badge_id(name, icon, category, description)')
          .eq('patient_id', patientId)
          .order('earned_at', ascending: false);
      return (response as List)
          .map((e) => PatientBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load patient badges: $e');
    }
  }

  Future<void> awardBadge(String patientId, String badgeId) async {
    try {
      await _client.from('patient_badges').insert({
        'patient_id': patientId,
        'badge_id': badgeId,
        'earned_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Badge already earned or error - log but don't throw
      print('Badge award failed: $e');
    }
  }

  Future<bool> hasBadge(String patientId, String badgeId) async {
    try {
      final response = await _client
          .from('patient_badges')
          .select('id')
          .eq('patient_id', patientId)
          .eq('badge_id', badgeId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAndAwardBadges(String patientId) async {
    try {
      final allBadges = await getAllBadges();
      final earned = await getPatientBadges(patientId);
      final earnedIds = earned.map((e) => e.badgeId).toSet();

      for (final badge in allBadges) {
        if (earnedIds.contains(badge.id)) continue;
        if (await _checkRequirement(patientId, badge)) {
          await awardBadge(patientId, badge.id);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<bool> _checkRequirement(String patientId, LoyaltyBadge badge) async {
    switch (badge.requirementType) {
      case 'steps':
        final steps = await _getSteps(patientId);
        return steps >= (badge.requirementValue ?? 0);
      case 'streak':
        final streak = await _getStreak(patientId);
        return streak >= (badge.requirementValue ?? 0);
      case 'challenges':
        final completed = await _getCompletedChallenges(patientId);
        return completed >= (badge.requirementValue ?? 0);
      case 'referrals':
        final referrals = await _getReferralsCount(patientId);
        return referrals >= (badge.requirementValue ?? 0);
      case 'consultations':
        final consultations = await _getConsultationsCount(patientId);
        return consultations >= (badge.requirementValue ?? 0);
      case 'prescriptions':
        final prescriptions = await _getPrescriptionsCount(patientId);
        return prescriptions >= (badge.requirementValue ?? 0);
      default:
        return false;
    }
  }

  // ---- Helper methods for requirements ----

  Future<int> _getSteps(String patientId) async {
    try {
      final response = await _client
          .from('health_actions')
          .select('value')
          .eq('patient_id', patientId)
          .eq('action_type', 'walk')
          .eq('recorded_at', DateTime.now().toIso8601String().split('T').first)
          .maybeSingle();
      if (response == null) return 0;
      return (response as Map<String, dynamic>)['value'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Audit Module 16 (FID, 29/08/2026) : remplace un calcul factice
  /// (`5 + millisecondsSinceEpoch % 10`, sans aucun rapport avec l'activité
  /// réelle du patient) qui décidait pourtant de l'attribution de vrais
  /// badges de type « streak » — même famille de défaut que l'ancien score
  /// de crédit fictif du Module 14 (C56), mais découvert et corrigé dès la
  /// première passe ici plutôt qu'après une réserve du porteur du projet.
  /// Calcul réel : nombre de jours consécutifs, en remontant depuis le jour
  /// le plus récent enregistré, avec au moins une entrée `health_actions`.
  Future<int> _getStreak(String patientId) async {
    try {
      final response = await _client
          .from('health_actions')
          .select('recorded_at')
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(400);
      final dates =
          (response as List)
              .map(
                (e) => DateTime.parse(
                  (e as Map<String, dynamic>)['recorded_at'] as String,
                ),
              )
              .toSet() // une seule entrée par jour, même si plusieurs actions ce jour-là
              .toList()
            ..sort((a, b) => b.compareTo(a));
      if (dates.isEmpty) return 0;
      var streak = 1;
      for (var i = 1; i < dates.length; i++) {
        final gap = dates[i - 1].difference(dates[i]).inDays;
        if (gap == 1) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Phase 4 (module loyalty) : `select(..., count: CountOption.exact)`
  // n'est pas l'API réelle de postgrest-dart 2.9.1 pinné dans ce projet -
  // voir messaging_service.dart (module teleconsult) pour la genèse du
  // motif. Les 4 méthodes ci-dessous migrées vers `.count()` chaîné après
  // les filtres, `response.count` au lieu de `response.length`.
  Future<int> _getCompletedChallenges(String patientId) async {
    try {
      final response = await _client
          .from('challenge_progress')
          .select('id')
          .eq('patient_id', patientId)
          .eq('completed', true)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getReferralsCount(String patientId) async {
    try {
      final response = await _client
          .from('loyalty_referrals')
          .select('id')
          .eq('referrer_patient_id', patientId)
          .eq('status', 'rewarded')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getConsultationsCount(String patientId) async {
    try {
      final response = await _client
          .from('consultations')
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'completed')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getPrescriptionsCount(String patientId) async {
    try {
      final response = await _client
          .from('eprescriptions')
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'dispensed')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  // ---- Leaderboard ----

  Future<List<Map<String, dynamic>>> getLeaderboard({
    required String pharmacyId,
    String period = 'all_time',
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('loyalty_leaderboard')
          .select('*, patients:patient_id(full_name)')
          .eq('pharmacy_id', pharmacyId)
          .eq('period', period)
          .order('points', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }
}
