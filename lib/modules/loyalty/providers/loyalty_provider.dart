import 'package:flutter/material.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_transaction.dart';
import '../models/loyalty_reward.dart';
import '../services/loyalty_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _service = LoyaltyService();

  LoyaltyAccount? _account;
  List<LoyaltyTransaction> _transactions = [];
  List<LoyaltyReward> _rewards = [];
  List<LoyaltyAccount> _myAccounts = [];
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = false;
  String? _error;

  LoyaltyAccount? get account => _account;
  List<LoyaltyTransaction> get transactions => _transactions;
  List<LoyaltyReward> get rewards => _rewards;
  List<LoyaltyAccount> get myAccounts => _myAccounts;
  List<Map<String, dynamic>> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAccount(String patientId, String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _service.getAccount(patientId, pharmacyId);
      if (_account == null) {
        // Audit Module 16 (FID, 29/08/2026), correctif de compilation
        // (bug 1/3 de ce module) : accédait directement à un champ `_client`
        // jamais défini dans cette classe (`Undefined name '_client'`, la
        // seule occurrence dans tout le module d'un provider contournant sa
        // propre couche service pour parler directement à Supabase).
        // Extrait dans `LoyaltyService.getActiveProgramId()`.
        final programId = await _service.getActiveProgramId(pharmacyId);
        if (programId != null) {
          _account = await _service.createAccount(
            LoyaltyAccount(
              id: '',
              patientId: patientId,
              pharmacyId: pharmacyId,
              programId: programId,
              joinedAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        }
      }
      if (_account != null) {
        await _loadTransactions(_account!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Audit Module 16 (FID, 29/08/2026) : pour `LoyaltyPharmacySelectScreen`
  /// — liste les officines où le patient a déjà un compte fidélité.
  Future<void> loadMyAccounts(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _myAccounts = await _service.getMyAccounts(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Audit Module 16 (FID, 29/08/2026) : pour `LoyaltyPharmacySelectScreen`
  /// — officines actives où le patient peut rejoindre un programme.
  Future<void> loadActivePharmacies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pharmacies = await _service.getActivePharmacies();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTransactions(String accountId) async {
    try {
      _transactions = await _service.getTransactions(accountId);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadRewards(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _rewards = await _service.getRewards(pharmacyId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> earnPoints(
    int amount, {
    String? referenceId,
    String? description,
  }) async {
    if (_account == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newBalance = await _service.earnPoints(
        accountId: _account!.id,
        amount: amount,
        referenceId: referenceId,
        description: description,
      );
      _account = _account!.copyWith(pointsBalance: newBalance);
      await _loadTransactions(_account!.id);
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

  Future<bool> redeemPoints(
    int amount, {
    String? referenceId,
    String? description,
  }) async {
    if (_account == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newBalance = await _service.redeemPoints(
        accountId: _account!.id,
        amount: amount,
        referenceId: referenceId,
        description: description,
      );
      _account = _account!.copyWith(pointsBalance: newBalance);
      await _loadTransactions(_account!.id);
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

  Future<bool> createReward(LoyaltyReward reward) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createReward(reward);
      _rewards.add(saved);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
