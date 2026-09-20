import 'package:flutter/material.dart';
import '../models/adverse_reaction.dart';
import '../models/adverse_reaction_anonymized.dart';
import '../services/regulator_service.dart';

class RegulatorProvider extends ChangeNotifier {
  final RegulatorService _service = RegulatorService();

  List<AdverseReaction> _reactions = [];
  AdverseReaction? _selectedReaction;
  bool _isLoading = false;
  String? _error;

  // Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-5 : état dédié à la
  // vue anonymisée (RG-REG-02), séparé de `_reactions` pour qu'un compte
  // 'regulateur' ne puisse jamais se retrouver, même par erreur de câblage
  // UI, à afficher une donnée issue de la table brute nominative.
  List<AdverseReactionAnonymized> _anonymizedReactions = [];
  bool _isLoadingAnonymized = false;
  String? _anonymizedError;

  List<AdverseReaction> get reactions => _reactions;
  AdverseReaction? get selectedReaction => _selectedReaction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AdverseReactionAnonymized> get anonymizedReactions =>
      _anonymizedReactions;
  bool get isLoadingAnonymized => _isLoadingAnonymized;
  String? get anonymizedError => _anonymizedError;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedReactionForTest(AdverseReaction? value) =>
      _selectedReaction = value;

  Future<void> loadReactionsAnonymized({
    String? status,
    String? severity,
  }) async {
    _isLoadingAnonymized = true;
    _anonymizedError = null;
    notifyListeners();
    try {
      _anonymizedReactions = await _service.getAdverseReactionsAnonymized(
        status: status,
        severity: severity,
      );
    } catch (e) {
      _anonymizedError = e.toString();
    }
    _isLoadingAnonymized = false;
    notifyListeners();
  }

  Future<void> loadReactions({
    String? patientId,
    String? reporterId,
    String? status,
    String? severity,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reactions = await _service.getAdverseReactions(
        patientId: patientId,
        reporterId: reporterId,
        status: status,
        severity: severity,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadReaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedReaction = await _service.getAdverseReaction(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveReaction(AdverseReaction reaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      AdverseReaction saved;
      if (reaction.id.isEmpty || reaction.id.startsWith('temp_')) {
        saved = await _service.createAdverseReaction(reaction);
        _reactions.insert(0, saved);
      } else {
        saved = await _service.updateAdverseReaction(reaction);
        final index = _reactions.indexWhere((r) => r.id == saved.id);
        if (index != -1) _reactions[index] = saved;
      }
      _selectedReaction = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAdverseReaction(id);
      _reactions.removeWhere((r) => r.id == id);
      if (_selectedReaction?.id == id) _selectedReaction = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSelected() {
    _selectedReaction = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
