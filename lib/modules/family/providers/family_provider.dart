import 'package:flutter/material.dart';
import '../models/family_link.dart';
import '../models/family_link_status.dart';
import '../models/family_alert.dart';
import '../services/family_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyService _service = FamilyService();

  List<FamilyLink> _links = [];
  List<FamilyLink> _incomingRequests = [];
  FamilyLink? _selectedLink;
  List<FamilyAlert> _alerts = [];
  int _unreadAlertCount = 0;
  bool _isLoading = false;
  String? _error;

  List<FamilyLink> get links => _links;
  List<FamilyLink> get incomingRequests => _incomingRequests;
  FamilyLink? get selectedLink => _selectedLink;
  List<FamilyAlert> get alerts => _alerts;
  int get unreadAlertCount => _unreadAlertCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedLinkForTest(FamilyLink? value) => _selectedLink = value;

  // ---- Links ----

  Future<void> loadLinks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Load as patient (my family members)
      final patientLinks = await _service.getLinksForUser(
        userId,
        asPatient: true,
      );
      // Load as family member (links where I'm the family member)
      final memberLinks = await _service.getLinksForUser(
        userId,
        asPatient: false,
      );

      // Combine: links I initiated as patient, and incoming requests where I'm the family member
      _links = patientLinks;
      _incomingRequests = memberLinks
          .where((l) => l.status == FamilyLinkStatus.pending)
          .toList();
      // Also add active links where I'm the family member to my links
      final activeMemberLinks = memberLinks
          .where((l) => l.status == FamilyLinkStatus.active)
          .toList();
      _links.addAll(activeMemberLinks);

      // Load alerts
      await _loadAlerts(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLink(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedLink = await _service.getLink(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createLink(FamilyLink link) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createLink(link);
      _links.insert(0, saved);
      _selectedLink = saved;
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

  Future<bool> updateLinkStatus(String id, FamilyLinkStatus newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateLinkStatus(id, newStatus);
      _updateLink(updated);
      // Remove from incoming requests if accepted/revoked
      if (newStatus != FamilyLinkStatus.pending) {
        _incomingRequests.removeWhere((l) => l.id == id);
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

  // Phase 5 (module family) : FamilyService.updateLink() existait déjà
  // (utilisé par family_detail_screen.dart pour la modification des
  // permissions), mais n'avait jamais été exposé par le provider - défaut
  // de compilation, jamais détecté faute de compilateur exécuté. Ajouté en
  // miroir de updateLinkStatus() ci-dessus.
  Future<bool> updateLink(FamilyLink link) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateLink(link);
      _updateLink(updated);
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

  Future<bool> deleteLink(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteLink(id);
      _links.removeWhere((l) => l.id == id);
      _incomingRequests.removeWhere((l) => l.id == id);
      if (_selectedLink?.id == id) _selectedLink = null;
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

  // ---- Alerts ----

  Future<void> _loadAlerts(String userId) async {
    try {
      _alerts = await _service.getAlertsForUser(userId);
      _unreadAlertCount = _alerts.where((a) => !a.isRead).length;
    } catch (e) {
      // Silent fail for alerts - non-critical
    }
  }

  Future<bool> createAlert(FamilyAlert alert) async {
    try {
      final saved = await _service.createAlert(alert);
      _alerts.insert(0, saved);
      if (!saved.isRead) _unreadAlertCount++;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAlertRead(String id) async {
    try {
      final updated = await _service.markAlertRead(id);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        if (!_alerts[index].isRead) _unreadAlertCount--;
        _alerts[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlert(String id) async {
    try {
      await _service.deleteAlert(id);
      final alert = _alerts.firstWhere(
        (a) => a.id == id,
        orElse: () => throw Exception('Not found'),
      );
      _alerts.removeWhere((a) => a.id == id);
      if (!alert.isRead) _unreadAlertCount--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---- Helpers ----

  void _updateLink(FamilyLink updated) {
    final index = _links.indexWhere((l) => l.id == updated.id);
    if (index != -1) _links[index] = updated;
    if (_selectedLink?.id == updated.id) _selectedLink = updated;
  }

  void clearSelected() {
    _selectedLink = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
