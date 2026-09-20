import 'dart:async';

import 'package:flutter/material.dart';
import '../models/financing_request.dart';
import '../models/financing_repayment.dart';
import '../models/credit_score.dart';
import '../services/financing_service.dart';

class FinancingProvider extends ChangeNotifier {
  final FinancingService _service = FinancingService();

  List<FinancingRequest> _requests = [];
  FinancingRequest? _selectedRequest;
  List<FinancingRepayment> _repayments = [];
  CreditScore? _creditScore;
  bool _isLoading = false;
  String? _error;

  List<FinancingRequest> get requests => _requests;
  FinancingRequest? get selectedRequest => _selectedRequest;
  List<FinancingRepayment> get repayments => _repayments;
  CreditScore? get creditScore => _creditScore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedRequestForTest(FinancingRequest? value) =>
      _selectedRequest = value;

  // ---- Credit Score ----

  Future<void> loadCreditScore(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _creditScore = await _service.getCreditScore(pharmacyId);
      if (_creditScore == null) {
        _creditScore = await _service.calculateCreditScore(pharmacyId);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCreditScore(String pharmacyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _creditScore = await _service.calculateCreditScore(pharmacyId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Financing Requests ----

  Future<void> loadRequests({String? pharmacyId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _requests = await _service.getRequests(
        pharmacyId: pharmacyId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    // Câblage de l'orpheline checkOverdueRepayments (audit Module 14,
    // 29/08/2026) : best-effort, non attendu — ne doit pas retarder
    // l'affichage de la liste, et échoue silencieusement en interne (voir
    // financing_service.dart) si l'utilisateur courant n'a aucune échéance
    // à évaluer.
    unawaited(_service.checkOverdueRepayments());
  }

  Future<void> loadRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedRequest = await _service.getRequest(id);
      if (_selectedRequest != null) {
        _repayments = await _service.getRepayments(id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRequest(FinancingRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      FinancingRequest saved;
      if (request.id.isEmpty || request.id.startsWith('temp_')) {
        saved = await _service.createRequest(request);
        _requests.insert(0, saved);
        // L'échéancier n'est plus généré ici (audit Module 14, 29/08/2026)
        // mais au décaissement (financing_service.dart, updateRequestStatus
        // 'active') — voir la docstring de cette méthode pour le pourquoi.
      } else {
        saved = await _service.updateRequest(request);
        final index = _requests.indexWhere((r) => r.id == saved.id);
        if (index != -1) _requests[index] = saved;
      }
      _selectedRequest = saved;
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

  Future<bool> updateRequestStatus(String id, String newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateRequestStatus(id, newStatus);
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) _requests[index] = updated;
      if (_selectedRequest?.id == id) _selectedRequest = updated;
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

  Future<bool> deleteRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRequest(id);
      _requests.removeWhere((r) => r.id == id);
      if (_selectedRequest?.id == id) _selectedRequest = null;
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

  // ---- Repayments ----

  Future<bool> payRepayment(String repaymentId, {String? transactionId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.payRepayment(
        repaymentId,
        transactionId: transactionId,
      );
      final index = _repayments.indexWhere((r) => r.id == updated.id);
      if (index != -1) _repayments[index] = updated;
      // Refresh request if all repayments paid
      if (_selectedRequest != null) {
        _selectedRequest = await _service.getRequest(_selectedRequest!.id);
      }
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
    _selectedRequest = null;
    _repayments = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
