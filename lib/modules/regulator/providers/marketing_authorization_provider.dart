import 'package:flutter/material.dart';
import '../models/marketing_authorization.dart';
import '../services/regulator_service.dart';

// Audit Module 27 (REG), Étape 3 (05/09/2026) — REG-4 : provider pour la
// table `marketing_authorizations` (AMM), jusqu'ici entièrement orpheline.
// La lecture publique des AMM approuvées ("Public view approved
// authorizations", inchangée en Étape 2) reste accessible via
// loadAuthorizations(status: 'approved') sans connexion staff/regulateur.
class MarketingAuthorizationProvider extends ChangeNotifier {
  final RegulatorService _service = RegulatorService();

  List<MarketingAuthorization> _authorizations = [];
  MarketingAuthorization? _selectedAuthorization;
  bool _isLoading = false;
  String? _error;

  List<MarketingAuthorization> get authorizations => _authorizations;
  MarketingAuthorization? get selectedAuthorization => _selectedAuthorization;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAuthorizations({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _authorizations = await _service.getAuthorizations(status: status);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAuthorization(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedAuthorization = await _service.getAuthorization(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAuthorization(MarketingAuthorization authorization) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      MarketingAuthorization saved;
      if (authorization.id.isEmpty || authorization.id.startsWith('temp_')) {
        saved = await _service.createAuthorization(authorization);
        _authorizations.insert(0, saved);
      } else {
        saved = await _service.updateAuthorization(authorization);
        final index = _authorizations.indexWhere((a) => a.id == saved.id);
        if (index != -1) _authorizations[index] = saved;
      }
      _selectedAuthorization = saved;
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

  Future<bool> deleteAuthorization(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAuthorization(id);
      _authorizations.removeWhere((a) => a.id == id);
      if (_selectedAuthorization?.id == id) _selectedAuthorization = null;
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
    _selectedAuthorization = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
