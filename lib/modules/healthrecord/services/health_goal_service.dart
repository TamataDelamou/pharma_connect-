import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/health_goal.dart';
import '../models/health_milestone.dart';

class HealthGoalService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Health Goals ----

  Future<List<HealthGoal>> getGoals(String patientId, {String? status}) async {
    try {
      // Phase 2bis (motif transversal "filtre après .order()") : voir
      // eprescription_service.dart pour la genèse du motif.
      var query = _client
          .from('health_goals')
          .select()
          .eq('patient_id', patientId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => HealthGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load goals: $e');
    }
  }

  Future<HealthGoal?> getGoal(String id) async {
    try {
      final response = await _client
          .from('health_goals')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return HealthGoal.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load goal: $e');
    }
  }

  Future<HealthGoal> createGoal(HealthGoal goal) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = goal
          .copyWith(
            id: id,
            currentValue: 0,
            status: 'active',
            startDate: now,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('health_goals')
          .insert(data)
          .select()
          .single();
      return HealthGoal.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<HealthGoal> updateGoal(HealthGoal goal) async {
    try {
      final data = goal
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      final response = await _client
          .from('health_goals')
          .update(data)
          .eq('id', goal.id)
          .select()
          .single();
      return HealthGoal.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  Future<void> updateGoalProgress(String id, double increment) async {
    try {
      final goal = await getGoal(id);
      if (goal == null) throw Exception('Goal not found');

      final newValue = goal.currentValue + increment;
      final isCompleted = newValue >= goal.targetValue;

      final data = {
        'current_value': newValue,
        if (isCompleted) 'status': 'completed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };
      await _client.from('health_goals').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update goal progress: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _client.from('health_goals').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // ---- Health Milestones ----

  Future<List<HealthMilestone>> getMilestones(String patientId) async {
    try {
      final response = await _client
          .from('health_milestones')
          .select()
          .eq('patient_id', patientId)
          .order('achieved_at', ascending: false);
      return (response as List)
          .map((e) => HealthMilestone.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load milestones: $e');
    }
  }

  Future<void> addMilestone({
    required String patientId,
    required String milestoneType,
    required String achievement,
  }) async {
    try {
      await _client.from('health_milestones').insert({
        'patient_id': patientId,
        'milestone_type': milestoneType,
        'achievement': achievement,
        'achieved_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Silent fail - milestone may already exist
    }
  }
}
