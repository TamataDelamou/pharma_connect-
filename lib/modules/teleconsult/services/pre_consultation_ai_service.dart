import 'dart:math';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/pre_consultation.dart';

/// ⚠️ AUDIT MODULE 15 (CNS, 29/08/2026) — NE PAS ROUTER SANS ARBITRAGE.
///
/// `analyzeSymptoms()` ci-dessous est une IA entièrement factice
/// (`Random()` — voir « Mock AI » plus bas) : elle génère un niveau
/// d'urgence, des « possible_conditions » et une spécialité suggérée,
/// affichés au patient. Ce comportement contreviendrait à RG-CNS-01
/// (l'assistant ne formule JAMAIS de diagnostic) et RG-CNS-02 (tout contenu
/// généré doit s'appuyer exclusivement sur du contenu validé par un
/// pharmacien référent, versionné) si ce service était atteint depuis un
/// flux exposé au patient — voir le rapport d'audit Module 15 §3 et le
/// registre (D26). Décision du porteur du projet (AskUserQuestion,
/// 29/08/2026) : corriger uniquement la compilation, ne pas exposer.
///
/// Garde-fous en place (2ème refus de clôture, point de contrôle « isolation
/// du sous-système Mock AI ») : (1) `app_router.dart` ne déclare AUCUNE
/// route vers `PreConsultationScreen`, seul point d'entrée UI de ce service
/// — vérifié par recherche exhaustive, aucune occurrence ; (2) aucun fichier
/// du flux téléconsultation exposé (`teleconsult_list_screen.dart`,
/// `teleconsult_detail_screen.dart`, `teleconsult_booking_screen.dart`,
/// `async_messaging_screen.dart`, `teleconsult_service.dart`,
/// `teleconsult_provider.dart`) n'importe ni ne référence
/// `PreConsultationAIService`, `PreConsultationProvider` ou
/// `PreConsultationScreen` — vérifié par recherche exhaustive, aucune
/// occurrence croisée ; seuls les 4 fichiers du sous-système lui-même
/// (ce fichier, `pre_consultation_provider.dart`, `pre_consultation_
/// screen.dart`, `pre_consultation.dart`) se référencent entre eux. Ne pas
/// invoquer ce service depuis un autre module sans nouvel arbitrage
/// explicite du porteur du projet.
class PreConsultationAIService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  // ---- Symptom Analysis (Mock AI) ----

  Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock analysis - in real implementation, call Gemini or TFLite
    final random = Random();
    final keywords = symptoms.toLowerCase().split(' ');
    final critical = [
      'thoracique',
      'cardiaque',
      'respiratoire',
      'suffoc',
      'hemorragie',
      'saignement',
    ].any((k) => keywords.contains(k));
    final specialties = [
      'Généraliste',
      'Cardiologie',
      'Dermatologie',
      'Pédiatrie',
      'Gynécologie',
    ];
    final specialty = specialties[random.nextInt(specialties.length)];

    return {
      'symptoms_analysis': {
        'keywords': keywords,
        'severity': critical
            ? 'critical'
            : ['mild', 'moderate', 'severe'][random.nextInt(3)],
        'urgency_score': critical ? 5 : (1 + random.nextInt(4)),
        'possible_conditions': [
          'Infection',
          'Allergie',
          'Inflammation',
        ].take(1 + random.nextInt(2)).toList(),
      },
      'specialty_suggestion': specialty,
      'urgency_level': critical ? 1 : (2 + random.nextInt(4)),
      'is_critical': critical,
      'suggested_actions': critical
          ? [
              'Contacter immédiatement les urgences',
              'Ne pas conduire',
              'Prendre rendez-vous en urgence',
            ]
          : ['Prendre un rendez-vous', 'Reposer', 'Hydrater'],
    };
  }

  Future<Map<String, dynamic>> generateSummary(
    PreConsultationSession session,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'chief_complaint': session.symptoms ?? 'Non spécifié',
      'analysis': session.analysis,
      'specialty_recommendation': session.specialtySuggestion,
      'urgency': session.urgencyLevel,
      'summary':
          'Patient présente les symptômes suivants : ${session.symptoms?.substring(0, min(session.symptoms?.length ?? 0, 50))}... '
          'Niveau d\'urgence : ${session.urgencyLevel ?? 'non déterminé'}. '
          'Recommandation : consulter en ${session.specialtySuggestion ?? 'médecine générale'}',
    };
  }

  // ---- Session Management ----

  Future<PreConsultationSession> createSession(String patientId) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'patient_id': patientId,
      'status': 'in_progress',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'created_by': SupabaseService().currentUser?.id,
    };
    final response = await _client
        .from('pre_consultation_sessions')
        .insert(data)
        .select()
        .single();
    return PreConsultationSession.fromJson(response as Map<String, dynamic>);
  }

  Future<PreConsultationSession> updateSession(
    PreConsultationSession session,
  ) async {
    final data = session.copyWith(updatedAt: DateTime.now().toUtc()).toJson();
    final response = await _client
        .from('pre_consultation_sessions')
        .update(data)
        .eq('id', session.id)
        .select()
        .single();
    return PreConsultationSession.fromJson(response as Map<String, dynamic>);
  }

  Future<PreConsultationSession> getSession(String id) async {
    final response = await _client
        .from('pre_consultation_sessions')
        .select()
        .eq('id', id)
        .single();
    return PreConsultationSession.fromJson(response as Map<String, dynamic>);
  }

  Future<List<PreConsultationSession>> getSessionsForPatient(
    String patientId,
  ) async {
    final response = await _client
        .from('pre_consultation_sessions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => PreConsultationSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Decision Tree ----

  Future<List<DecisionTreeNode>> getDecisionTree() async {
    final response = await _client
        .from('decision_tree_nodes')
        .select()
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => DecisionTreeNode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DecisionTreeNode>> getChildren(String nodeId) async {
    final response = await _client
        .from('decision_tree_nodes')
        .select()
        .eq('parent_id', nodeId);
    return (response as List)
        .map((e) => DecisionTreeNode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DecisionTreeNode> createNode(DecisionTreeNode node) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final data = node.copyWith(id: id, createdAt: now, updatedAt: now).toJson();
    final response = await _client
        .from('decision_tree_nodes')
        .insert(data)
        .select()
        .single();
    return DecisionTreeNode.fromJson(response as Map<String, dynamic>);
  }

  // ---- Seed default decision tree ----

  Future<void> seedDefaultTree() async {
    // Check if tree already exists
    // Phase 4 (module teleconsult) : `count: CountOption.exact` n'existe
    // pas sur `.select()` (voir messaging_service.dart) - et n'était de
    // toute façon jamais exploité ici, seul `.isNotEmpty` est lu. Retiré
    // plutôt que migré vers `.count()`, dont le type de retour
    // (PostgrestResponse) n'a pas `.isNotEmpty`.
    final existing = await _client
        .from('decision_tree_nodes')
        .select('id')
        .limit(1);
    if (existing.isNotEmpty) return;

    // Root node
    final root = await createNode(
      DecisionTreeNode(
        id: '',
        question: 'Quel est votre symptôme principal ?',
        options: {
          'options': [
            {'label': 'Douleur', 'next': 'pain'},
            {'label': 'Fièvre', 'next': 'fever'},
            {'label': 'Toux', 'next': 'cough'},
            {'label': 'Fatigue', 'next': 'fatigue'},
            {'label': 'Problème de peau', 'next': 'skin'},
          ],
        },
        isLeaf: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    // Pain branch
    await createNode(
      DecisionTreeNode(
        id: '',
        parentId: root.id,
        question: 'Où se situe la douleur ?',
        options: {
          'options': [
            {'label': 'Thorax', 'next': 'chest'},
            {'label': 'Abdomen', 'next': 'abdomen'},
            {'label': 'Tête', 'next': 'head'},
            {'label': 'Dos', 'next': 'back'},
          ],
        },
        isLeaf: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
