import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/personalized_reward.dart';

class PersonalizedRewardService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Generate Rewards ----

  Future<List<PersonalizedReward>> generateRewards(String patientId) async {
    // Analyze patient behavior
    final actions = await _getHealthActions(patientId);
    final challenges = await _getCompletedChallenges(patientId);
    final purchases = await _getPurchaseHistory(patientId);

    // Determine preferences
    final hasRegularActivity = actions.where((a) => a.actionType == 'walk').length > 10;
    final isHealthConscious = challenges.length > 5;
    final isFrequentBuyer = purchases.length > 5;

    final rewards = <PersonalizedReward>[];
    final now = DateTime.now().toUtc();

    // Health-conscious rewards
    if (isHealthConscious) {
      rewards.add(PersonalizedReward(
        id: _uuid.v4(),
        patientId: patientId,
        rewardType: 'discount',
        title: '10% de réduction sur les vitamines',
        description: 'Pour votre engagement envers votre santé',
        discountPercentage: 10,
        expiresAt: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Regular activity rewards
    if (hasRegularActivity) {
      rewards.add(PersonalizedReward(
        id: _uuid.v4(),
        patientId: patientId,
        rewardType: 'bonus_points',
        title: '50 points bonus',
        description: 'Pour votre régularité sportive',
        pointsCost: 50,
        expiresAt: now.add(const Duration(days: 14)),
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Frequent buyer rewards
    if (isFrequentBuyer) {
      rewards.add(PersonalizedReward(
        id: _uuid.v4(),
        patientId: patientId,
        rewardType: 'free_item',
        title: '1 médicament gratuit (au choix)',
        description: 'Pour votre fidélité',
        expiresAt: now.add(const Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Save rewards
    for (final reward in rewards) {
      await _saveReward(reward);
    }

    return rewards;
  }

  Future<PersonalizedReward> _saveReward(PersonalizedReward reward) async {
    final data = reward.toJson();
    final response = await _client
        .from('personalized_rewards')
        .insert(data)
        .select()
        .single();
    return PersonalizedReward.fromJson(response as Map<String, dynamic>);
  }

  // ---- Get Rewards ----

  Future<List<PersonalizedReward>> getActiveRewards(String patientId) async {
    try {
      final response = await _client
          .from('personalized_rewards')
          .select()
          .eq('patient_id', patientId)
          .eq('is_active', true)
          // Phase 4 (module loyalty) : `.is(` - `is` est un mot réservé
          // Dart, même famille que PRE-1 (`.in()` -> `.inFilter()`) et le
          // `.in(` déjà signalé dans support_service.dart (Phase 2bis).
          // La méthode réelle du client Supabase-Dart est `.isFilter()`.
          .isFilter('used_at', null)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => PersonalizedReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PersonalizedReward>> getAllRewards(String patientId) async {
    try {
      final response = await _client
          .from('personalized_rewards')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => PersonalizedReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PersonalizedReward?> getReward(String id) async {
    try {
      final response = await _client
          .from('personalized_rewards')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return PersonalizedReward.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> useReward(String rewardId) async {
    try {
      await _client
          .from('personalized_rewards')
          .update({
            'used_at': DateTime.now().toUtc().toIso8601String(),
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', rewardId);
    } catch (e) {
      throw Exception('Failed to use reward: $e');
    }
  }

  // ---- Helper Methods ----

  Future<List<dynamic>> _getHealthActions(String patientId) async {
    try {
      final response = await _client
          .from('health_actions')
          .select()
          .eq('patient_id', patientId)
          .limit(30);
      return response as List;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getCompletedChallenges(String patientId) async {
    try {
      final response = await _client
          .from('challenge_progress')
          .select()
          .eq('patient_id', patientId)
          .eq('completed', true);
      return response as List;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getPurchaseHistory(String patientId) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'completed')
          .limit(20);
      return response as List;
    } catch (e) {
      return [];
    }
  }
}
