import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/health_challenge.dart';
import '../models/loyalty_account.dart';

class LoyaltyAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();
  final _random = Random();

  // ---- Challenge Generation ----

  Future<List<HealthChallenge>> generatePersonalizedChallenges(
    String patientId,
  ) async {
    // Get patient health actions
    final actions = await _getHealthActions(patientId);

    // Get available challenges
    final challenges = await _getChallenges();

    // Analyze patient behavior
    final walkingActivity = actions
        .where((a) => a.actionType == 'walk')
        .toList();
    final waterIntake = actions
        .where((a) => a.actionType == 'water_intake')
        .toList();
    final fruits = actions.where((a) => a.actionType == 'fruits').toList();

    // Determine if patient is active
    final avgSteps = walkingActivity.isNotEmpty
        ? walkingActivity.map((a) => a.value).reduce((a, b) => a + b) /
              walkingActivity.length
        : 0;

    // Select relevant challenges based on patient profile
    var selected = <HealthChallenge>[];
    if (avgSteps < 3000) {
      selected.addAll(
        challenges.where(
          (c) => c.name.contains('Marche') && c.difficulty == 'easy',
        ),
      );
    } else if (avgSteps < 6000) {
      selected.addAll(
        challenges.where(
          (c) => c.name.contains('Marche') && c.difficulty == 'medium',
        ),
      );
    } else {
      selected.addAll(
        challenges.where(
          (c) => c.name.contains('Marche') && c.difficulty == 'hard',
        ),
      );
    }

    // Add variety
    if (waterIntake.isEmpty || waterIntake.last.value < 1.0) {
      selected.addAll(challenges.where((c) => c.name.contains('Eau')));
    }
    if (fruits.isEmpty || fruits.last.value < 3) {
      selected.addAll(
        challenges.where((c) => c.name.contains('fruits/légumes')),
      );
    }

    // Ensure we have at least 3 challenges
    if (selected.length < 3) {
      final all = challenges.where((c) => c.isActive).toList();
      all.shuffle();
      for (final c in all) {
        if (!selected.contains(c)) {
          selected.add(c);
          if (selected.length >= 3) break;
        }
      }
    }

    return selected.take(5).toList();
  }

  Future<List<HealthChallenge>> _getChallenges() async {
    try {
      final response = await _client
          .from('health_challenges')
          .select()
          .eq('is_active', true);
      return (response as List)
          .map((e) => HealthChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<HealthAction>> _getHealthActions(String patientId) async {
    try {
      final response = await _client
          .from('health_actions')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(30);
      return (response as List)
          .map((e) => HealthAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ---- Progress Tracking ----

  Future<ChallengeProgress> updateProgress({
    required String patientId,
    required String challengeId,
    required int increment,
  }) async {
    // Get existing progress
    final existing = await getProgress(patientId, challengeId);

    if (existing != null) {
      final newProgress = min(existing.progress + increment, existing.target);
      final completed = newProgress >= existing.target;
      final completedAt = completed ? DateTime.now().toUtc() : null;

      final data = {
        'progress': newProgress,
        'completed': completed,
        if (completedAt != null) 'completed_at': completedAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': SupabaseService().currentUser?.id,
      };

      final response = await _client
          .from('challenge_progress')
          .update(data)
          .eq('id', existing.id)
          .select()
          .single();

      final updated = ChallengeProgress.fromJson(
        response as Map<String, dynamic>,
      );

      // If completed, award points
      if (completed) {
        await _awardPoints(patientId, challengeId);
      }

      return updated;
    } else {
      // Create new progress
      final challenge = await _getChallenge(challengeId);
      if (challenge == null) throw Exception('Challenge not found');

      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = {
        'id': id,
        'patient_id': patientId,
        'challenge_id': challengeId,
        'progress': increment,
        'target': challenge.target,
        'completed': increment >= challenge.target,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': SupabaseService().currentUser?.id,
        'updated_by': SupabaseService().currentUser?.id,
      };

      final response = await _client
          .from('challenge_progress')
          .insert(data)
          .select()
          .single();

      final newProgress = ChallengeProgress.fromJson(
        response as Map<String, dynamic>,
      );
      if (newProgress.completed) {
        await _awardPoints(patientId, challengeId);
      }
      return newProgress;
    }
  }

  /// Audit Module 16 (FID, 29/08/2026), correctif de compilation (bug 2/3
  /// de ce module) : rendue publique — `LoyaltyAIProvider.generateChallenges()`
  /// (autre fichier) appelait `_service._getProgress(...)`, un membre privé
  /// donc de portée BIBLIOTHÈQUE (fichier), pas seulement classe, en Dart —
  /// inaccessible depuis un autre fichier, même motif exact que C59 point 4
  /// (Module 15, `pre_consultation_provider.dart`/`_currentNodeId`).
  Future<ChallengeProgress?> getProgress(
    String patientId,
    String challengeId,
  ) async {
    try {
      final response = await _client
          .from('challenge_progress')
          .select()
          .eq('patient_id', patientId)
          .eq('challenge_id', challengeId)
          .maybeSingle();
      if (response == null) return null;
      return ChallengeProgress.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<HealthChallenge?> _getChallenge(String id) async {
    try {
      final response = await _client
          .from('health_challenges')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return HealthChallenge.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> _awardPoints(String patientId, String challengeId) async {
    final challenge = await _getChallenge(challengeId);
    if (challenge == null) return;

    await _client.from('reward_earnings').insert({
      'patient_id': patientId,
      'challenge_id': challengeId,
      'points_earned': challenge.points,
      'reward_type': 'points',
      'description': 'Défi terminé : ${challenge.name}',
      'earned_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Add points to loyalty account
    final account = await _getLoyaltyAccount(patientId);
    if (account != null) {
      await _client
          .from('loyalty_accounts')
          .update({
            'points_balance': account.pointsBalance + challenge.points,
            'total_points_earned': account.totalPointsEarned + challenge.points,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', account.id);
    }
  }

  // Phase 4 (module loyalty) : retournait la Map brute alors que
  // _awardPoints() ci-dessus consomme account.pointsBalance/.totalPoints
  // Earned/.id comme un objet typé - défaut de compilation, jamais détecté
  // faute de compilateur exécuté à la clôture du Module 16/FID. Corrigé en
  // retournant LoyaltyAccount (modèle déjà utilisé ailleurs dans ce
  // module, ex. loyalty_dashboard_screen.dart), pas de nouveau type créé.
  Future<LoyaltyAccount?> _getLoyaltyAccount(String patientId) async {
    try {
      final response = await _client
          .from('loyalty_accounts')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();
      if (response == null) return null;
      return LoyaltyAccount.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ---- Recommendations ----

  Future<List<Map<String, dynamic>>> getRecommendations(
    String patientId,
  ) async {
    final actions = await _getHealthActions(patientId);

    // Analyze patterns
    //
    // Audit Module 16 (FID, 29/08/2026), correctif fonctionnel : `today`/
    // `yesterday` étaient des `DateTime.now()` (horodatage complet, avec
    // heure/minute/seconde), comparés par égalité stricte (`==`) à
    // `recordedAt`, qui n'est jamais qu'une date sans heure (colonne SQL
    // `date`, minuit UTC — voir `HealthAction.fromJson`). Cette égalité
    // n'était donc essentiellement jamais vraie : la recommandation
    // « Maintenez votre activité » ne pouvait jamais se déclencher. Corrigé
    // en normalisant `today`/`yesterday` à minuit avant comparaison.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayActions = actions.where((a) => a.recordedAt == today);
    final yesterdayActions = actions.where((a) => a.recordedAt == yesterday);

    // Phase 4 (module loyalty) : `recommendations` était utilisé sans
    // jamais être déclaré (Undefined name, x4 dans cette méthode) - défaut
    // de compilation, jamais détecté faute de compilateur exécuté à la
    // clôture du Module 16/FID. Déclaration manquante ajoutée.
    final recommendations = <Map<String, dynamic>>[];

    // Check consistency
    if (yesterdayActions.isNotEmpty && todayActions.isEmpty) {
      recommendations.add({
        'type': 'consistency',
        'title': 'Maintenez votre activité',
        'description': 'Vous étiez actif hier. Continuez aujourd\'hui !',
        'icon': '🔥',
      });
    }

    // Suggest water if not enough
    final waterToday = todayActions.where(
      (a) => a.actionType == 'water_intake',
    );
    if (waterToday.isEmpty || waterToday.first.value < 1.5) {
      recommendations.add({
        'type': 'water',
        'title': 'Buvez plus d\'eau',
        'description': 'Visez 1,5 litres d\'eau par jour pour rester hydraté.',
        'icon': '💧',
      });
    }

    // Suggest walking if inactive
    final walkToday = todayActions.where((a) => a.actionType == 'walk');
    if (walkToday.isEmpty || walkToday.first.value < 30) {
      recommendations.add({
        'type': 'walk',
        'title': 'Promenez-vous 30 minutes',
        'description': 'La marche améliore la santé cardiovasculaire.',
        'icon': '🚶',
      });
    }

    return recommendations;
  }

  // ---- Record Health Action ----

  Future<HealthAction> recordHealthAction({
    required String patientId,
    required String actionType,
    required double value,
    DateTime? date,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'patient_id': patientId,
      'action_type': actionType,
      'value': value,
      'recorded_at': (date ?? now).toIso8601String().split('T').first,
      'created_at': now.toIso8601String(),
    };
    final response = await _client
        .from('health_actions')
        .insert(data)
        .select()
        .single();
    return HealthAction.fromJson(response as Map<String, dynamic>);
  }
}

class HealthAction {
  final String id;
  final String patientId;
  final String actionType;
  final double value;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthAction({
    required this.id,
    required this.patientId,
    required this.actionType,
    required this.value,
    required this.recordedAt,
    required this.createdAt,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'action_type': actionType,
    'value': value,
    'recorded_at': recordedAt.toIso8601String().split('T').first,
    'created_at': createdAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthAction.fromJson(Map<String, dynamic> json) => HealthAction(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    actionType: json['action_type'] as String,
    value: (json['value'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recorded_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    gsgId: json['gsg_id'] as String?,
    gsgOrgId: json['gsg_org_id'] as String?,
  );
}
