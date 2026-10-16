import 'package:flutter/material.dart';
import 'package:pharma_connect/core/utils/user_message.dart';
import '../models/cash_drawer_session.dart';
import '../models/cash_movement.dart';
import '../services/cash_service.dart';

class CashProvider extends ChangeNotifier {
  final CashService _service;

  /// [service] : remplaçable dans les tests.
  CashProvider({CashService? service}) : _service = service ?? CashService();

  CashDrawerSession? _currentSession;
  List<CashDrawerSession> _sessions = [];
  List<CashMovement> _movements = [];
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _report;
  bool _isLoading = false;
  String? _error;

  CashDrawerSession? get currentSession => _currentSession;
  List<CashDrawerSession> get sessions => _sessions;
  List<CashMovement> get movements => _movements;
  Map<String, dynamic>? get summary => _summary;
  Map<String, dynamic>? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasOpenSession => _currentSession != null && _currentSession!.isOpen;

  /// C273 (b) : session dont les mouvements sont chargés. Sans eux, on ne
  /// sait pas si une vente a eu lieu : aucune correction n'est proposée.
  String? _movementsSessionId;

  /// C273 (b) : le compte connecté est-il le titulaire de l'officine ? `null`
  /// tant que ce n'est pas connu.
  bool? get isManager => _isManager;
  bool? _isManager;

  /// C273 (b) : mouvements de la session ouverte chargés.
  bool get _movementsKnown =>
      hasOpenSession && _movementsSessionId == currentSession?.id;

  /// C273 (b) : une vente ou un remboursement a eu lieu dans la session.
  bool get hasSaleInSession => movements.any(
    (m) => m.type == CashMovementType.sale || m.type == CashMovementType.refund,
  );

  /// C273 (b), décision d'Achille du 16/10/2026 : avant la première vente, le
  /// caissier corrige le fonds de sa caisse.
  bool get canCorrectOpening => _movementsKnown && !hasSaleInSession;

  /// C273 (b) : après une vente, dépôt ou retrait avec motif, par le
  /// titulaire seulement, sur sa propre session (pilote).
  bool get canAddCashMovement =>
      _movementsKnown && hasSaleInSession && _isManager == true;

  /// C274 : la caisse du caissier connecté est-elle ouverte ? `null` tant que
  /// ce n'est pas connu (pas encore lu, ou dernière lecture en échec, par
  /// exemple hors connexion) : le menu affiche alors « Caisse ».
  bool? get drawerOpen => _drawerOpen;
  bool? _drawerOpen;

  /// Compte et officine pour lesquels [drawerOpen] a été demandé.
  String? _drawerStateKey;

  /// C274 : lit une fois l'état de la caisse pour ce compte et cette officine
  /// (le téléphone de l'officine passe d'un compte à l'autre).
  Future<void> ensureDrawerState({
    required String userId,
    required String pharmacyId,
  }) async {
    final key = '$userId|$pharmacyId';
    if (_drawerStateKey == key) return;
    _drawerStateKey = key;
    _drawerOpen = null;
    await loadCurrentSession(pharmacyId);
  }

  /// C258 : solde d'espèces attendu de la session ouverte, calculé par le
  /// serveur à partir des mouvements (`cash_summary.current_expected_cash`,
  /// même calcul que `cash_expected_balance` à la fermeture). `null` tant que
  /// le résumé de cette session n'est pas chargé : l'écran affiche alors
  /// « — ». Ne jamais lire `expected_balance` d'une session ouverte : il
  /// reste égal au fonds de caisse jusqu'à la fermeture.
  int? get currentExpectedCash {
    final summary = this.summary;
    final session = currentSession;
    if (summary == null || session == null) return null;
    if (summary['session_id'] != session.id) return null;
    return (summary['current_expected_cash'] as num?)?.toInt();
  }

  /// C258 : relit le résumé de la session avant la fermeture. En cas
  /// d'échec, le résumé est vidé (« — » à l'écran) plutôt que de laisser une
  /// valeur ancienne ; l'écran ne bascule pas en erreur.
  Future<void> refreshSummary(String sessionId) async {
    try {
      _summary = await _service.getSessionSummary(sessionId);
    } catch (_) {
      _summary = null;
    }
    notifyListeners();
  }

  Future<void> loadCurrentSession(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSession = await _service.getCurrentOpenSession(pharmacyId);
      _drawerOpen = _currentSession?.isOpen ?? false;
      _isManager = await _readIsManager(pharmacyId);
      if (_currentSession != null) {
        await loadMovements(_currentSession!.id);
        await loadSummary(_currentSession!.id);
      }
    } catch (e) {
      _error = userMessage(e);
      _drawerOpen = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSessions({
    String? pharmacyId,
    String? cashierId,
    CashSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sessions = await _service.getSessions(
        pharmacyId: pharmacyId,
        cashierId: cashierId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMovements(String sessionId) async {
    _movementsSessionId = null;
    try {
      _movements = await _service.getMovements(sessionId);
      _movementsSessionId = sessionId;
      notifyListeners();
    } catch (e) {
      _error = userMessage(e);
    }
  }

  Future<void> loadSummary(String sessionId) async {
    try {
      _summary = await _service.getSessionSummary(sessionId);
      notifyListeners();
    } catch (e) {
      _error = userMessage(e);
    }
  }

  Future<bool> openSession({
    required String pharmacyId,
    required String cashierId,
    required int openingBalance,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSession = await _service.openSession(
        pharmacyId: pharmacyId,
        cashierId: cashierId,
        openingBalance: openingBalance,
        notes: notes,
      );
      _drawerOpen = true;
      await loadMovements(_currentSession!.id);
      await loadSummary(_currentSession!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeSession({
    required String sessionId,
    required int closingBalance,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSession = await _service.closeSession(
        sessionId: sessionId,
        closingBalance: closingBalance,
        notes: notes,
      );
      _drawerOpen = false;
      await loadMovements(_currentSession!.id);
      await loadSummary(_currentSession!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMovement({
    required String sessionId,
    required CashMovementType type,
    required int amount,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.addMovement(
        sessionId: sessionId,
        type: type,
        amount: amount,
        referenceId: referenceId,
        referenceType: referenceType,
        notes: notes,
      );
      await loadMovements(sessionId);
      await loadSummary(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// C273 (b) : titulaire ou non ; `null` si la lecture échoue (aucune action
  /// réservée au titulaire n'est alors proposée).
  Future<bool?> _readIsManager(String pharmacyId) async {
    try {
      return await _service.isPharmacyManager(pharmacyId);
    } catch (_) {
      return null;
    }
  }

  /// C273 (b) : motif des corrections du fonds avant la première vente.
  static const String openingCorrectionNote = 'Correction du fonds de caisse';

  /// C273 (b) : corrige le fonds de la session ouverte, avant la première
  /// vente, par un dépôt ou un retrait de la différence. Le fonds d'origine
  /// reste dans l'historique. Vrai si rien n'était à corriger.
  Future<bool> correctOpening(int correctFund) async {
    final session = currentSession;
    if (session == null || !canCorrectOpening) return false;
    // Avant la première vente, les espèces en caisse sont le fonds
    // d'ouverture et les corrections déjà faites (dépôts et retraits).
    final current =
        session.openingBalance +
        movements.fold<int>(
          0,
          (sum, m) => switch (m.type) {
            CashMovementType.deposit => sum + m.amount,
            CashMovementType.withdrawal => sum - m.amount,
            _ => sum,
          },
        );
    final difference = correctFund - current;
    if (difference == 0) return true;
    return addMovement(
      sessionId: session.id,
      type: difference > 0
          ? CashMovementType.deposit
          : CashMovementType.withdrawal,
      amount: difference.abs(),
      notes: openingCorrectionNote,
    );
  }

  /// C273 (b) : dépôt ou retrait d'espèces après une vente, par le titulaire,
  /// motif obligatoire.
  Future<bool> addCashMovement({
    required CashMovementType type,
    required int amount,
    required String reason,
  }) async {
    final session = currentSession;
    if (session == null || !canAddCashMovement) return false;
    if (reason.trim().isEmpty || amount <= 0) return false;
    return addMovement(
      sessionId: session.id,
      type: type,
      amount: amount,
      notes: reason.trim(),
    );
  }

  Future<bool> loadReport({
    required String pharmacyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _report = await _service.getCashReport(
        pharmacyId: pharmacyId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
