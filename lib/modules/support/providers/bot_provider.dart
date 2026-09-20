import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bot_conversation.dart';
import '../services/bot_ai_service.dart';

class BotProvider extends ChangeNotifier {
  final BotAIService _service = BotAIService();
  final _uuid = const Uuid();

  BotConversation? _currentConversation;
  List<BotConversation> _history = [];
  bool _isLoading = false;
  bool _isThinking = false;
  String? _error;

  BotConversation? get currentConversation => _currentConversation;
  List<BotConversation> get history => _history;
  bool get isLoading => _isLoading;
  bool get isThinking => _isThinking;
  String? get error => _error;

  Future<void> startConversation(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentConversation = await _service.createConversation(patientId);
      // Add welcome message
      final welcomeMsg = BotMessage(
        id: _uuid.v4(),
        sender: 'bot',
        text:
            'Bonjour ! 👋 Je suis l\'assistant PharmaConnect. Comment puis-je vous aider aujourd\'hui ?\n\n'
            'Je peux vous aider avec :\n'
            '📦 Vos commandes\n'
            '💊 Médicaments\n'
            '📋 Ordonnances\n'
            '💰 Facturation\n'
            '🔐 Votre compte',
        timestamp: DateTime.now().toUtc(),
      );
      final updated = _currentConversation!.copyWith(
        messages: [..._currentConversation!.messages, welcomeMsg],
      );
      _currentConversation = await _service.updateConversation(updated);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    if (_currentConversation == null) return;

    _isThinking = true;
    notifyListeners();

    try {
      final response = await _service.getResponse(
        _currentConversation!,
        message,
      );
      _currentConversation = await _service.getConversation(
        _currentConversation!.id,
      );
      _isThinking = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await _service.getConversationsForPatient(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadConversation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentConversation = await _service.getConversation(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> escalate({String? reason}) async {
    if (_currentConversation == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _currentConversation = await _service.escalateConversation(
        _currentConversation!.id,
        reason ?? 'Demande d\'escalade',
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolve() async {
    if (_currentConversation == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _currentConversation = await _service.resolveConversation(
        _currentConversation!.id,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitFeedback({
    required int rating,
    String? comment,
    bool? issueResolved,
  }) async {
    if (_currentConversation == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _service.submitFeedback(
        conversationId: _currentConversation!.id,
        rating: rating,
        comment: comment,
        issueResolved: issueResolved,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearConversation() {
    _currentConversation = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
