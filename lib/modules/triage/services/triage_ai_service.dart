import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/triage_ai_analysis.dart';
import '../models/triage_rules.dart';

class TriageAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Analysis ----

  Future<TriageAIAnalysis> analyzeSymptoms({
    required String triagePatientId,
    required String symptoms,
  }) async {
    // Get triage rules
    final rules = await _getRules();

    // Analyze symptoms against rules
    final lowerSymptoms = symptoms.toLowerCase();
    var matchedRules = <TriageRule>[];

    for (final rule in rules) {
      if (lowerSymptoms.contains(rule.keyword)) {
        matchedRules.add(rule);
      }
    }

    // Determine priority (take highest priority - lowest score)
    var priorityScore = 5;
    var suggestedDepartment = 'Généraliste';
    var isCritical = false;

    if (matchedRules.isNotEmpty) {
      // Sort by priority score ascending
      matchedRules.sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
      final bestMatch = matchedRules.first;
      priorityScore = bestMatch.priorityScore;
      suggestedDepartment = bestMatch.department ?? 'Généraliste';
      isCritical = bestMatch.isCritical;

      // If multiple critical matches, flag as critical
      if (matchedRules.any((r) => r.isCritical)) {
        isCritical = true;
      }
    }

    // Build analysis details
    final analysisDetails = {
      'matched_keywords': matchedRules.map((r) => r.keyword).toList(),
      'matched_rule_count': matchedRules.length,
      'symptoms_keywords': lowerSymptoms.split(' '),
    };

    // Create and save analysis
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'triage_patient_id': triagePatientId,
      'symptoms': symptoms,
      'priority_score': priorityScore,
      'suggested_department': suggestedDepartment,
      'is_critical': isCritical,
      'analysis_details': analysisDetails,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'created_by': SupabaseService().currentUser?.id,
      'updated_by': SupabaseService().currentUser?.id,
    };

    final response = await _client
        .from('triage_ai_analyses')
        .insert(data)
        .select()
        .single();

    return TriageAIAnalysis.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TriageRule>> _getRules() async {
    final response = await _client
        .from('triage_rules')
        .select()
        .eq('is_active', true);
    return (response as List)
        .map((e) => TriageRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TriageRule>> getRules() async => _getRules();

  Future<TriageRule> createRule(TriageRule rule) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = rule
        .copyWith(
          id: id,
          createdAt: now,
          updatedAt: now,
          createdBy: SupabaseService().currentUser?.id,
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('triage_rules')
        .insert(data)
        .select()
        .single();
    return TriageRule.fromJson(response as Map<String, dynamic>);
  }

  Future<TriageRule> updateRule(TriageRule rule) async {
    final data = rule
        .copyWith(
          updatedAt: DateTime.now().toUtc(),
          updatedBy: SupabaseService().currentUser?.id,
        )
        .toJson();
    final response = await _client
        .from('triage_rules')
        .update(data)
        .eq('id', rule.id)
        .select()
        .single();
    return TriageRule.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRule(String id) async {
    await _client.from('triage_rules').delete().eq('id', id);
  }

  // ---- Feedback ----

  Future<TriageAIAnalysis> submitFeedback({
    required String analysisId,
    required int actualPriority,
    required String actualDepartment,
    String? feedback,
  }) async {
    final data = {
      'actual_priority': actualPriority,
      'actual_department': actualDepartment,
      'doctor_feedback': feedback,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': SupabaseService().currentUser?.id,
    };
    final response = await _client
        .from('triage_ai_analyses')
        .update(data)
        .eq('id', analysisId)
        .select()
        .single();
    return TriageAIAnalysis.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TriageAIAnalysis>> getAnalysesForPatient(
    String triagePatientId,
  ) async {
    final response = await _client
        .from('triage_ai_analyses')
        .select()
        .eq('triage_patient_id', triagePatientId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => TriageAIAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TriageAIAnalysis?> getLatestAnalysisForPatient(
    String triagePatientId,
  ) async {
    try {
      final response = await _client
          .from('triage_ai_analyses')
          .select()
          .eq('triage_patient_id', triagePatientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return TriageAIAnalysis.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
