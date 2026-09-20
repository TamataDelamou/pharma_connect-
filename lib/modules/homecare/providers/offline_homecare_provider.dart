import 'package:flutter/material.dart';
import 'package:pharma_connect/core/services/offline_sync_service.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import '../models/intervention.dart';
import '../services/homecare_service.dart';

class OfflineHomecareProvider extends ChangeNotifier {
  final OfflineSyncService _syncService = OfflineSyncService();
  final HomecareService _apiService = HomecareService();

  List<Intervention> _interventions = [];
  bool _isOffline = false;
  bool _isSyncing = false;
  bool _isLoading = false;
  String? _error;

  List<Intervention> get interventions => _interventions;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  // Phase 3 (module homecare) : offline_homecare_screen.dart référence
  // provider.isLoading (spinner du chargement initial, distinct de
  // isSyncing qui couvre la synchronisation hors-ligne en arrière-plan) sans
  // qu'aucun champ de ce nom n'ait jamais existé sur ce provider - défaut de
  // compilation, jamais détecté faute de compilateur exécuté lors de
  // l'audit Module 18/HOM. Ajouté en suivant le même patron que isSyncing.
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInterventions(String patientId) async {
    _isLoading = true;
    notifyListeners();

    _isOffline = !(await _syncService.hasInternet());

    if (_isOffline) {
      await _loadFromLocal(patientId);
    } else {
      await _loadFromApi(patientId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocal(String patientId) async {
    final db = await _syncService.database;
    final results = await db.query(
      'interventions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    _interventions = results.map((e) => Intervention.fromJson(e)).toList();
  }

  Future<void> _loadFromApi(String patientId) async {
    try {
      // Audit Module 18 (HOM, 30/08/2026) : `getInterventionsForPatient`
      // n'existe pas sur `HomecareService` (seule `getInterventionsForUser`
      // existe) — identifiant non défini, défaut de compilation. Corrigé en
      // appelant la méthode réelle, sans le paramètre `asProfessional`
      // (toujours `false` par défaut, cohérent avec l'usage patient de ce
      // provider hors-ligne).
      _interventions = await _apiService.getInterventionsForUser(
        userId: patientId,
      );
      // Cache locally
      for (final intervention in _interventions) {
        await _syncService.saveRecord(
          table: 'interventions',
          // Audit Module 18 (HOM, 30/08/2026) : `intervention.toJson()`
          // inclut des clés absentes de la table locale `interventions`
          // (voir `offline_sync_service.dart`, schéma limité à
          // id/patient_id/professional_id/scheduled_at/duration_minutes/
          // status/reason/address/notes/report/created_at/updated_at) —
          // `patient_rating`/`patient_feedback`/`started_at`/`completed_at`/
          // `created_by`/`updated_by`/`gsg_id`/`gsg_org_id`/`refusal_reason`
          // provoquaient une erreur SQLite (« no such column ») dès la
          // première intervention réelle (créée avec `created_by` non nul),
          // avortant silencieusement toute la boucle de mise en cache — le
          // mode hors-ligne ne mettait donc jamais réellement en cache la
          // moindre intervention réelle. Corrigé en ne transmettant que les
          // colonnes réellement présentes dans le schéma local.
          record: _toLocalCacheJson(intervention),
          sync: false,
        );
      }
    } catch (e) {
      _error = e.toString();
      await _loadFromLocal(patientId);
    }
  }

  Map<String, dynamic> _toLocalCacheJson(Intervention intervention) {
    final full = intervention.toJson();
    const localColumns = {
      'id',
      'patient_id',
      'professional_id',
      'scheduled_at',
      'duration_minutes',
      'status',
      'reason',
      'address',
      'notes',
      'report',
      'created_at',
      'updated_at',
    };
    return Map<String, dynamic>.fromEntries(
      full.entries.where((e) => localColumns.contains(e.key)),
    );
  }

  Future<void> saveIntervention(Intervention intervention) async {
    final isOnline = await _syncService.hasInternet();

    if (isOnline) {
      try {
        await _apiService.createIntervention(intervention);
        await _syncService.saveRecord(
          table: 'interventions',
          record: _toLocalCacheJson(intervention),
          sync: false,
        );
      } catch (e) {
        await _syncService.saveRecord(
          table: 'interventions',
          record: _toLocalCacheJson(intervention),
          sync: true,
        );
      }
    } else {
      await _syncService.saveRecord(
        table: 'interventions',
        record: _toLocalCacheJson(intervention),
        sync: true,
      );
    }

    _interventions.insert(0, intervention);
    notifyListeners();
  }

  Future<void> syncOfflineData() async {
    _isSyncing = true;
    notifyListeners();
    await _syncService.syncAll();
    _isSyncing = false;
    final patientId = SupabaseService().currentUser?.id;
    if (patientId != null) {
      await loadInterventions(patientId);
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
