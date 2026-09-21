import 'package:flutter/material.dart';
import '../models/pre_consultation.dart';
import '../services/pre_consultation_ai_service.dart';

/// ⚠️ AUDIT MODULE 15 (CNS, 29/08/2026) — NE PAS ROUTER SANS ARBITRAGE.
/// Voir l'avertissement complet en tête de `pre_consultation_ai_service.dart`
/// et `pre_consultation_screen.dart` (D26). Ce provider n'est instancié que
/// par `PreConsultationScreen`, elle-même non déclarée dans
/// `app_router.dart` — recherche exhaustive confirmant qu'aucun autre écran
/// ne le référence.
class PreConsultationProvider extends ChangeNotifier {
  final PreConsultationAIService _service = PreConsultationAIService();

  PreConsultationSession? _currentSession;
  List<PreConsultationSession> _history = [];
  List<DecisionTreeNode> _decisionTree = [];
  Map<String, dynamic>? _analysisResult;
  String? _currentNodeId;
  bool _isLoading = false;
  String? _error;

  PreConsultationSession? get currentSession => _currentSession;
  List<PreConsultationSession> get history => _history;
  List<DecisionTreeNode> get decisionTree => _decisionTree;
  Map<String, dynamic>? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Audit Module 15 (CNS, 29/08/2026) : exposé en lecture seule pour que
  /// l'écran (autre fichier) puisse retrouver le nœud courant de l'arbre de
  /// décision sans accéder au champ privé `_currentNodeId` — un accès direct
  /// depuis un autre fichier est de toute façon impossible en Dart (portée
  /// de bibliothèque, pas seulement de classe) et provoquait une erreur de
  /// compilation.
  String? get currentNodeId => _currentNodeId;

  /// Nœud courant de l'arbre de décision, dérivé de [currentNodeId]. Ne
  /// retourne jamais `null` tant que [decisionTree] contient au moins un
  /// nœud (repli sur le premier), à l'identique du comportement recherché
  /// par l'écran — mais sans le défaut de typage de l'ancien `firstWhere`
  /// avec `orElse` nullable (incompatible avec la signature non-nullable
  /// attendue par `List<DecisionTreeNode>.firstWhere`).
  DecisionTreeNode? get currentNode {
    if (_decisionTree.isEmpty) return null;
    for (final node in _decisionTree) {
      if (node.id == _currentNodeId) return node;
    }
    return _decisionTree.first;
  }

  Future<void> startSession(String patientId) async {
    _isLoading = true;
    _error = null;
    _analysisResult = null;
    _currentNodeId = null;
    notifyListeners();
    try {
      _currentSession = await _service.createSession(patientId);
      await _loadDecisionTree();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDecisionTree() async {
    try {
      _decisionTree = await _service.getDecisionTree();
      if (_decisionTree.isEmpty) {
        await _service.seedDefaultTree();
        _decisionTree = await _service.getDecisionTree();
      }
      if (_decisionTree.isNotEmpty) {
        _currentNodeId = _decisionTree.firstWhere((n) => n.parentId == null).id;
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<List<DecisionTreeNode>> getChildren(String nodeId) async {
    try {
      return await _service.getChildren(nodeId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<void> selectOption(String nodeId, String optionLabel) async {
    _isLoading = true;
    notifyListeners();
    try {
      final children = await _service.getChildren(nodeId);
      if (children.isNotEmpty) {
        // Navigate to next question
        _currentNodeId = children.first.id;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Leaf node - we have a result
      final node = _decisionTree.firstWhere((n) => n.id == nodeId);
      if (node.isLeaf && node.leafResult != null) {
        await _completeSession(optionLabel, node.leafResult!);
      } else {
        // If no children and not leaf, treat as completion
        await _completeSession(optionLabel, 'Consultation recommandée');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _completeSession(String symptoms, String recommendation) async {
    if (_currentSession == null) return;

    // Analyze symptoms with AI
    _analysisResult = await _service.analyzeSymptoms(symptoms);

    final updated = _currentSession!.copyWith(
      symptoms: symptoms,
      analysis: _analysisResult!,
      specialtySuggestion: _analysisResult!['specialty_suggestion'],
      urgencyLevel: _analysisResult!['urgency_level'],
      isCritical: _analysisResult!['is_critical'] ?? false,
      summary: _analysisResult!['suggested_actions']?.join('. '),
      status: 'completed',
      updatedAt: DateTime.now().toUtc(),
    );

    _currentSession = await _service.updateSession(updated);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await _service.getSessionsForPatient(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSession() {
    _currentSession = null;
    _analysisResult = null;
    _currentNodeId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
