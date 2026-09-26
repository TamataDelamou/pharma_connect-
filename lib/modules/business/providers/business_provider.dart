import 'package:flutter/material.dart';
import '../models/business_company.dart';
import '../models/business_contract.dart';
import '../services/business_service.dart';

class BusinessProvider extends ChangeNotifier {
  final BusinessService _service = BusinessService();

  List<BusinessCompany> _companies = [];
  BusinessCompany? _selectedCompany;
  List<BusinessContract> _contracts = [];
  BusinessContract? _selectedContract;
  bool _isLoading = false;
  String? _error;

  List<BusinessCompany> get companies => _companies;
  BusinessCompany? get selectedCompany => _selectedCompany;
  List<BusinessContract> get contracts => _contracts;
  BusinessContract? get selectedContract => _selectedContract;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedCompanyForTest(BusinessCompany? value) =>
      _selectedCompany = value;

  // ---- Companies ----

  Future<void> loadCompanies({
    String? type,
    String? status,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _companies = await _service.getCompanies(
        type: type,
        status: status,
        searchQuery: searchQuery,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCompany(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCompany = await _service.getCompany(id);
      if (_selectedCompany != null) {
        await loadContracts(companyId: id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveCompany(BusinessCompany company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      BusinessCompany saved;
      if (company.id.isEmpty || company.id.startsWith('temp_')) {
        saved = await _service.createCompany(company);
        _companies.insert(0, saved);
      } else {
        saved = await _service.updateCompany(company);
        final index = _companies.indexWhere((c) => c.id == saved.id);
        if (index != -1) _companies[index] = saved;
      }
      _selectedCompany = saved;
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

  Future<bool> deleteCompany(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteCompany(id);
      _companies.removeWhere((c) => c.id == id);
      if (_selectedCompany?.id == id) _selectedCompany = null;
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

  // ---- Contracts ----

  Future<void> loadContracts({String? companyId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _contracts = await _service.getContracts(
        companyId: companyId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadContract(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedContract = await _service.getContract(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveContract(BusinessContract contract) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      BusinessContract saved;
      if (contract.id.isEmpty || contract.id.startsWith('temp_')) {
        saved = await _service.createContract(contract);
        _contracts.insert(0, saved);
      } else {
        saved = await _service.updateContract(contract);
        final index = _contracts.indexWhere((c) => c.id == saved.id);
        if (index != -1) _contracts[index] = saved;
      }
      _selectedContract = saved;
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

  Future<bool> deleteContract(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteContract(id);
      _contracts.removeWhere((c) => c.id == id);
      if (_selectedContract?.id == id) _selectedContract = null;
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
    _selectedCompany = null;
    _selectedContract = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
