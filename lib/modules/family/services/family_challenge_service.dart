import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/family_challenge.dart';
import '../models/family_challenge_contribution.dart';
import '../models/family_activity.dart';

class FamilyChallengeService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Family Challenges ----

  Future<List<FamilyChallenge>> getFamilyChallenges(String familyLinkId) async {
    try {
      final response = await _client
          .from('family_challenges')
          .select()
          .eq('family_link_id', familyLinkId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load family challenges: $e');
    }
  }

  Future<FamilyChallenge?> getFamilyChallenge(String id) async {
    try {
      final response = await _client
          .from('family_challenges')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return FamilyChallenge.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load family challenge: $e');
    }
  }

  Future<FamilyChallenge> createFamilyChallenge(
    FamilyChallenge challenge,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = challenge
          .copyWith(
            id: id,
            progress: 0,
            status: 'active',
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('family_challenges')
          .insert(data)
          .select()
          .single();
      return FamilyChallenge.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create family challenge: $e');
    }
  }

  Future<FamilyChallenge> updateChallengeProgress(
    String id,
    int increment,
  ) async {
    try {
      final challenge = await getFamilyChallenge(id);
      if (challenge == null) throw Exception('Challenge not found');

      final newProgress = challenge.progress + increment;
      final isCompleted = newProgress >= challenge.targetValue;

      final data = {
        'progress': newProgress,
        if (isCompleted) 'status': 'completed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('family_challenges')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return FamilyChallenge.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  Future<void> deleteFamilyChallenge(String id) async {
    try {
      await _client.from('family_challenges').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete family challenge: $e');
    }
  }

  // ---- Contributions ----

  Future<List<FamilyChallengeContribution>> getContributions(
    String challengeId,
  ) async {
    try {
      final response = await _client
          .from('family_challenge_contributions')
          .select('*, patients:patient_id(full_name)')
          .eq('challenge_id', challengeId)
          .order('updated_at', ascending: false);
      return (response as List)
          .map(
            (e) =>
                FamilyChallengeContribution.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load contributions: $e');
    }
  }

  Future<FamilyChallengeContribution> addContribution({
    required String challengeId,
    required String patientId,
    required int value,
  }) async {
    try {
      // Check if contribution exists
      final existing = await _client
          .from('family_challenge_contributions')
          .select()
          .eq('challenge_id', challengeId)
          .eq('patient_id', patientId)
          .maybeSingle();

      if (existing != null) {
        final newValue =
            (existing as Map<String, dynamic>)['contribution_value'] as int? ??
            0;
        final data = {
          'contribution_value': newValue + value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        final response = await _client
            .from('family_challenge_contributions')
            .update(data)
            .eq('id', existing['id'])
            .select()
            .single();
        return FamilyChallengeContribution.fromJson(
          response as Map<String, dynamic>,
        );
      } else {
        final id = _uuid.v4();
        final data = {
          'id': id,
          'challenge_id': challengeId,
          'patient_id': patientId,
          'contribution_value': value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        final response = await _client
            .from('family_challenge_contributions')
            .insert(data)
            .select()
            .single();
        return FamilyChallengeContribution.fromJson(
          response as Map<String, dynamic>,
        );
      }
    } catch (e) {
      throw Exception('Failed to add contribution: $e');
    }
  }

  // ---- Family Activities ----

  Future<List<FamilyActivity>> getFamilyActivities(String familyLinkId) async {
    try {
      final response = await _client
          .from('family_activities')
          .select('*, patients:patient_id(full_name)')
          .eq('family_link_id', familyLinkId)
          .order('recorded_at', ascending: false)
          .limit(50);
      return (response as List)
          .map((e) => FamilyActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load family activities: $e');
    }
  }

  Future<FamilyActivity> createFamilyActivity(FamilyActivity activity) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = activity
          .copyWith(
            id: id,
            recordedAt: activity.recordedAt ?? now,
            createdAt: now,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'patient_name');
      final response = await _client
          .from('family_activities')
          .insert(data)
          .select()
          .single();
      return FamilyActivity.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create family activity: $e');
    }
  }

  Future<void> deleteFamilyActivity(String id) async {
    try {
      await _client.from('family_activities').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete family activity: $e');
    }
  }
}
