import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/dashboard_widget.dart';
import '../models/user_dashboard.dart';
import '../services/analytics_user_scope.dart';
import '../services/dashboard_customization_service.dart';

class DashboardCustomizationProvider extends ChangeNotifier {
  final DashboardCustomizationService _service =
      DashboardCustomizationService();
  // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-14 : `_createDefaultDashboard`
  // référençait `_uuid.v4()` à quatre reprises sans qu'aucun champ `_uuid` ne
  // soit jamais déclaré ni `package:uuid` importé dans ce fichier — défaut de
  // compilation bloquant, distinct de BI-6 (écran jamais routé/provider
  // jamais enregistré) et BI-7 (système non recadré officine/réseau) :
  // même une fois routé et enregistré, cet écran n'aurait jamais compilé.
  final Uuid _uuid = const Uuid();

  List<DashboardWidget> _availableWidgets = [];
  List<UserDashboard> _userDashboards = [];
  UserDashboard? _selectedDashboard;
  AnalyticsUserScope? _scope;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;

  List<DashboardWidget> get availableWidgets => _availableWidgets;
  List<UserDashboard> get userDashboards => _userDashboards;
  UserDashboard? get selectedDashboard => _selectedDashboard;
  AnalyticsUserScope? get scope => _scope;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get error => _error;

  Future<void> loadAvailableWidgets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableWidgets = await _service.getAvailableWidgets();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Audit Module 28 (BI), Étape 3, BI-7 : point d'entrée unique de l'écran
  /// DashboardEditorScreen — résout le rôle du compte courant et sert le
  /// tableau de bord officine (staff rattaché à une pharmacie), réseau
  /// (compte GSG admin) ou personnel (tout le reste), en le créant s'il
  /// n'existe pas encore. Remplace l'ancien `loadUserDashboards` jamais
  /// appelé par l'écran (BI-6/BI-7 : le tableau de bord restait donc
  /// toujours `null` même une fois l'écran atteignable).
  Future<void> loadDashboardForCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final scope = await _service.getCurrentUserScope();
      _scope = scope;
      if (scope.userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      if (scope.isPharmacyStaff) {
        _selectedDashboard =
            await _service.getOfficineDashboard(scope.pharmacyId!) ??
            await _createDefaultDashboard(
              ownerId: scope.userId!,
              scope: 'officine',
              pharmacyId: scope.pharmacyId,
              name: 'Tableau de bord officine',
            );
        _userDashboards = [_selectedDashboard!];
      } else if (scope.isGsgAdmin) {
        _selectedDashboard =
            await _service.getReseauDashboard() ??
            await _createDefaultDashboard(
              ownerId: scope.userId!,
              scope: 'reseau',
              name: 'Tableau de bord réseau GSG',
            );
        _userDashboards = [_selectedDashboard!];
      } else {
        await _loadPersonalDashboards(scope.userId!);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Conservé pour un éventuel usage direct (compte "personal" connu à
  /// l'avance) — `loadDashboardForCurrentUser()` ci-dessus est le point
  /// d'entrée normal de l'écran.
  Future<void> loadUserDashboards(String ownerId) => _loadPersonalDashboards(
    ownerId,
    manageLoadingState: true,
  );

  Future<void> _loadPersonalDashboards(
    String ownerId, {
    bool manageLoadingState = false,
  }) async {
    if (manageLoadingState) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _userDashboards = await _service.getUserDashboards(ownerId);
      if (_userDashboards.isEmpty) {
        _selectedDashboard = await _createDefaultDashboard(
          ownerId: ownerId,
          scope: 'personal',
        );
        _userDashboards = await _service.getUserDashboards(ownerId);
      } else {
        _selectedDashboard = _userDashboards.firstWhere(
          (d) => d.isDefault,
          orElse: () => _userDashboards.first,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    if (manageLoadingState) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserDashboard> _createDefaultDashboard({
    required String ownerId,
    required String scope,
    String? pharmacyId,
    String name = 'Tableau de bord principal',
  }) async {
    final defaultPanels = [
      UserDashboardPanel(
        id: _uuid.v4(),
        widgetId: 'kpi_consultations',
        position: 0,
        colSpan: 1,
        rowSpan: 1,
      ),
      UserDashboardPanel(
        id: _uuid.v4(),
        widgetId: 'kpi_prescriptions',
        position: 1,
        colSpan: 1,
        rowSpan: 1,
      ),
      UserDashboardPanel(
        id: _uuid.v4(),
        widgetId: 'kpi_revenue',
        position: 2,
        colSpan: 1,
        rowSpan: 1,
      ),
      UserDashboardPanel(
        id: _uuid.v4(),
        widgetId: 'chart_activity',
        position: 3,
        colSpan: 2,
        rowSpan: 2,
      ),
    ];

    final dashboard = UserDashboard(
      id: 'default_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: name,
      panels: defaultPanels,
      isDefault: true,
      scope: scope,
      pharmacyId: pharmacyId,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    return await _service.saveDashboard(dashboard);
  }

  Future<bool> saveDashboard(UserDashboard dashboard) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.saveDashboard(dashboard);
      final index = _userDashboards.indexWhere((d) => d.id == saved.id);
      if (index != -1) {
        _userDashboards[index] = saved;
      } else {
        _userDashboards.add(saved);
      }
      _selectedDashboard = saved;
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

  /// BI-7 : câble enfin `DashboardWidgetPicker` (widget existant, jusqu'ici
  /// jamais importé/rendu par DashboardEditorScreen) à une action réelle.
  Future<bool> addWidget(String widgetId) async {
    final dashboard = _selectedDashboard;
    if (dashboard == null) return false;
    final panel = UserDashboardPanel(
      id: _uuid.v4(),
      widgetId: widgetId,
      position: dashboard.panels.length,
    );
    return saveDashboard(dashboard.copyWith(panels: [...dashboard.panels, panel]));
  }

  /// BI-7 : implémente enfin le bouton de suppression de panneau, jusqu'ici
  /// un `onPressed` vide (`// Remove panel`) dans DashboardEditorScreen.
  Future<bool> removePanel(String panelId) async {
    final dashboard = _selectedDashboard;
    if (dashboard == null) return false;
    final updatedPanels = dashboard.panels
        .where((p) => p.id != panelId)
        .toList();
    return saveDashboard(dashboard.copyWith(panels: updatedPanels));
  }

  Future<bool> deleteDashboard(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteDashboard(id);
      _userDashboards.removeWhere((d) => d.id == id);
      if (_selectedDashboard?.id == id) {
        _selectedDashboard = _userDashboards.isNotEmpty
            ? _userDashboards.first
            : null;
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

  Future<bool> setDefaultDashboard(String id, String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.setDefaultDashboard(id, ownerId);
      await _loadPersonalDashboards(ownerId);
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

  void selectDashboard(String id) {
    _selectedDashboard = _userDashboards.firstWhere((d) => d.id == id);
    notifyListeners();
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
