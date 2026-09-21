import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/prescription.dart';
import '../models/prescription_item.dart';
import '../models/prescription_status.dart';
import '../services/prescription_service.dart';
import '../services/ocr_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../catalog/services/catalog_service.dart';
import '../../stock/services/stock_service.dart';

enum PrescriptionUploadStatus { idle, uploading, processing, ready, error }

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionService _service = PrescriptionService();
  final OcrService _ocrService = OcrService();
  final OfflineSyncService _offlineSync = OfflineSyncService();
  final CatalogService _catalogService = CatalogService();
  final StockService _stockService = StockService();

  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  PrescriptionUploadStatus _uploadStatus = PrescriptionUploadStatus.idle;
  String? _uploadError;
  List<PrescriptionItem> _extractedItems = [];
  double _ocrConfidenceScore = 0.0;
  bool _isProcessingOcr = false;
  Map<String, bool> _availabilityMap = {};
  // Audit Module 5 (ORD, 29/08/2026) : RG-ORD-02 — une ligne d'ordonnance
  // correspondant à un produit classé stupéfiant/psychotrope (regulatory_class,
  // Module 3) doit rester traçable comme telle jusqu'à l'écran de validation,
  // pour que le pharmacien sache qu'elle ne peut être honorée que par retrait
  // physique en officine. Alimenté par _checkAvailability ci-dessous.
  Map<String, bool> _controlledSubstanceMap = {};
  String? _error; // <-- Ajouté
  bool _isLoading = false;
  // Directive standing (approuvée après Module 3) : « implementation du mode
  // offline » — même patron que SearchProvider/StockProvider : en cas
  // d'échec réseau, on conserve les dernières données connues (cache local)
  // plutôt que de basculer sur un état d'erreur bloquant.
  bool _isOffline = false;

  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;
  PrescriptionUploadStatus get uploadStatus => _uploadStatus;
  String? get uploadError => _uploadError;
  List<PrescriptionItem> get extractedItems => _extractedItems;
  double get ocrConfidenceScore => _ocrConfidenceScore;
  bool get isProcessingOcr => _isProcessingOcr;
  Map<String, bool> get availabilityMap => _availabilityMap;
  Map<String, bool> get controlledSubstanceMap => _controlledSubstanceMap;
  String? get error => _error; // <-- Ajouté
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  List<Prescription> get pendingPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.pending)
      .toList();

  List<Prescription> get validatedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.validated)
      .toList();

  List<Prescription> get dispensedPrescriptions => _prescriptions
      .where((p) => p.status == PrescriptionStatus.dispensed)
      .toList();

  // ==================== CHARGEMENT ====================

  /// Clé de partitionnement du cache local hors-ligne — l'id de l'utilisateur
  /// authentifié, patient ou pharmacien (voir cache_prescriptions dans
  /// offline_sync_service.dart). 'anon' n'est là que pour éviter un id null
  /// qui écraserait silencieusement le cache d'un autre compte ; ce cas ne
  /// devrait normalement pas se produire, les routes de ce module exigeant
  /// une session active.
  String get _cacheOwnerKey =>
      SupabaseService().currentUser?.id ?? 'anon';

  Future<void> loadPrescriptions({PrescriptionStatus? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _prescriptions = await _service.getPrescriptions(status: status);
      _isOffline = false;
      _error = null;
      // Cache uniquement la vue non filtrée : une vue filtrée par statut
      // écraserait le cache hors-ligne avec un sous-ensemble incomplet.
      if (status == null) {
        unawaited(
          _offlineSync.cachePrescriptions(
            _cacheOwnerKey,
            _prescriptions.map(_toCacheJson).toList(),
          ),
        );
      }
    } catch (e) {
      // Repli hors-ligne (directive standing, approuvée après Module 3) :
      // même patron que SearchProvider (Module 2)/StockProvider (Module 4) —
      // si un cache existe, on l'affiche avec un état informatif plutôt que
      // de bloquer l'écran sur une erreur réseau.
      final cached = await _offlineSync.getCachedPrescriptions(_cacheOwnerKey);
      if (cached.isNotEmpty) {
        var restored = cached
            .map((row) => Prescription.fromJson(row))
            .toList();
        if (status != null) {
          restored = restored.where((p) => p.status == status).toList();
        }
        _prescriptions = restored;
        _isOffline = true;
        _error =
            'Hors connexion — dernière liste synchronisée affichée (${_prescriptions.length} ordonnance(s)).';
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prescription.toJson() n'inclut jamais `items` (ce sont des lignes d'une
  /// table séparée, prescription_items — voir le commentaire du modèle) :
  /// utiliser toJson() tel quel pour le cache local ferait revenir une
  /// ordonnance sans médicaments après un repli hors-ligne. On réinjecte les
  /// items sous la même clé ('prescription_items') que celle que
  /// Prescription.fromJson attend depuis le select Supabase embarqué.
  Map<String, dynamic> _toCacheJson(Prescription p) => {
    ...p.toJson(),
    'prescription_items': p.items.map((i) => i.toJson()).toList(),
  };

  Future<void> loadPrescription(String id) async {
    try {
      _selectedPrescription = await _service.getPrescription(id);
      _isOffline = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      // Repli hors-ligne (directive standing) : cet écran n'avait aucun
      // recours au cache local avant ce module — une simple coupure réseau
      // en ouvrant le détail d'une ordonnance déjà consultée (donc déjà en
      // cache via loadPrescriptions) affichait une erreur bloquante en
      // permanence plutôt que la dernière version connue.
      final cached = await _offlineSync.getRecord('cache_prescriptions', id);
      if (cached != null) {
        try {
          final data = jsonDecode(cached['data'] as String) as Map<String, dynamic>;
          _selectedPrescription = Prescription.fromJson(data);
          _isOffline = true;
          _error =
              'Hors connexion — dernière version connue de cette ordonnance affichée.';
        } catch (_) {
          _error = e.toString();
        }
      } else {
        _error = e.toString();
      }
      notifyListeners();
    }
  }

  // ==================== UPLOAD & OCR ====================

  Future<void> uploadPrescription(
    String imagePath,
    String patientId,
    String patientName,
  ) async {
    _uploadStatus = PrescriptionUploadStatus.uploading;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _controlledSubstanceMap = {};
    _isOffline = false;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _uploadStatus = PrescriptionUploadStatus.processing;
      _isProcessingOcr = true;
      notifyListeners();

      // La reconnaissance de texte (OcrService, ML Kit on-device) ne dépend
      // d'aucun réseau — seul l'enregistrement Supabase qui suit en a
      // besoin. Directive standing « privilégier le mode hors-ligne » :
      // plutôt que de perdre la photo et l'OCR déjà faits sur une simple
      // coupure réseau, on met l'écriture en file d'attente locale (rejouée
      // par OfflineSyncService.syncAll()) exactement comme le fait déjà
      // StockProvider pour un ajustement de stock (Module 4).
      final ocrResult = await _ocrService.extractFromImage(imagePath);
      _extractedItems = ocrResult['items'] as List<PrescriptionItem>;
      _ocrConfidenceScore = ocrResult['confidenceScore'] as double;
      _isProcessingOcr = false;

      Prescription prescription;
      if (await _offlineSync.hasInternet()) {
        try {
          prescription = await _service.createPrescription(
            patientId: patientId,
            patientName: patientName,
            imageUrl: imagePath,
            items: _extractedItems,
            ocrConfidenceScore: _ocrConfidenceScore,
          );
        } catch (e) {
          // Le réseau semblait disponible (checkConnectivity) mais l'appel
          // Supabase a tout de même échoué (DNS, backend injoignable,
          // timeout) : même repli que l'absence de réseau ci-dessous plutôt
          // que de perdre la saisie.
          prescription = await _queueOfflinePrescription(
            patientId,
            patientName,
            imagePath,
          );
        }
      } else {
        prescription = await _queueOfflinePrescription(
          patientId,
          patientName,
          imagePath,
        );
      }

      _selectedPrescription = prescription;
      _prescriptions.add(prescription);
      _uploadStatus = PrescriptionUploadStatus.ready;
      if (_isOffline) {
        _uploadError =
            'Hors connexion : l\'ordonnance est enregistrée sur cet appareil '
            'et sera envoyée automatiquement au retour du réseau.';
      }

      await _checkAvailability(_extractedItems);

      notifyListeners();
    } catch (e) {
      _uploadStatus = PrescriptionUploadStatus.error;
      _uploadError = 'Erreur lors de l\'upload: $e';
      _isProcessingOcr = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Construit localement l'ordonnance et ses lignes avec des id générés
  /// côté client (même stratégie que PrescriptionService.createPrescription)
  /// afin que la synchronisation différée (syncAll) insère exactement les
  /// mêmes lignes, sans collision ni duplication possible côté serveur.
  Future<Prescription> _queueOfflinePrescription(
    String patientId,
    String patientName,
    String imagePath,
  ) async {
    _isOffline = true;
    final prescriptionId = const Uuid().v4();
    final itemsWithIds = _extractedItems
        .map(
          (item) => item.copyWith(
            id: const Uuid().v4(),
            prescriptionId: prescriptionId,
          ),
        )
        .toList();
    _extractedItems = itemsWithIds;

    final prescription = Prescription(
      id: prescriptionId,
      patientId: patientId,
      patientName: patientName,
      uploadedAt: DateTime.now(),
      status: PrescriptionStatus.pending,
      imageUrl: imagePath,
      items: itemsWithIds,
      ocrConfidenceScore: _ocrConfidenceScore,
    );

    await _offlineSync.queueOperation(
      table: 'prescriptions',
      recordId: prescriptionId,
      operation: 'insert',
      data: prescription.toJson(),
    );
    for (final item in itemsWithIds) {
      await _offlineSync.queueOperation(
        table: 'prescription_items',
        recordId: item.id,
        operation: 'insert',
        data: item.toJson(),
      );
    }
    await _offlineSync.upsertCachedPrescription(
      _cacheOwnerKey,
      _toCacheJson(prescription),
    );
    return prescription;
  }

  // ==================== VALIDATION ====================

  Future<void> validatePrescription(String id, {String? notes}) async {
    try {
      final updated = await _service.validatePrescription(id, notes: notes);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> dispensePrescription(String id) async {
    try {
      final updated = await _service.dispensePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) _prescriptions[index] = updated;
      if (_selectedPrescription?.id == id) _selectedPrescription = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> archivePrescription(String id) async {
    try {
      await _service.archivePrescription(id);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = _prescriptions[index].copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      if (_selectedPrescription?.id == id) {
        _selectedPrescription = _selectedPrescription!.copyWith(
          status: PrescriptionStatus.archived,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== CORRECTION ====================

  Future<List<String>> suggestCorrection(String wrongName) async {
    return await _ocrService.suggestCorrection(wrongName);
  }

  void updateExtractedItem(int index, PrescriptionItem newItem) {
    if (index < _extractedItems.length) {
      _extractedItems[index] = newItem;
      notifyListeners();
    }
  }

  void updateExtractedItems(List<PrescriptionItem> newItems) {
    _extractedItems = newItems;
    notifyListeners();
  }

  // ==================== AVAILABILITY ====================

  // Audit Module 5 (ORD, 29/08/2026) : cette méthode ne faisait que tirer un
  // booléen pseudo-aléatoire sur l'horloge système (`millisecondsSinceEpoch
  // % 3`) — aucune donnée réelle de stock n'était consultée, alors même que
  // StockService.searchStock (Module 4, déjà audité) existe et donne une
  // réponse réelle. Remplacé par une recherche par nom sur le catalogue
  // toutes officines confondues (aucune officine n'est encore choisie à ce
  // stade de l'écran) : `isAvailable` reflète un stock disponible dans au
  // moins une officine, et RG-ORD-02 est amorcé en marquant au passage les
  // lignes correspondant à un produit stupéfiant/psychotrope
  // (Product.isControlledSubstance, Module 3) pour que la validation
  // pharmacien affiche l'avertissement "retrait en officine uniquement".
  // Best-effort et non bloquant : un échec ici (réseau, aucun produit
  // catalogué sous ce nom) laisse simplement la ligne sans statut plutôt que
  // de faire échouer tout le dépôt d'ordonnance — RG-ORD-01 n'exige rien de
  // cette vérification, seule la validation humaine explicite compte.
  Future<void> _checkAvailability(List<PrescriptionItem> items) async {
    _availabilityMap = {};
    _controlledSubstanceMap = {};
    for (final item in items) {
      try {
        final matches = await _catalogService.getProducts(
          searchQuery: item.medicationName,
        );
        if (matches.isEmpty) continue;
        _controlledSubstanceMap[item.medicationName] = matches.any(
          (p) => p.isControlledSubstance,
        );
        final stockMatches = await _stockService.searchStock(
          query: item.medicationName,
        );
        _availabilityMap[item.medicationName] = stockMatches.any(
          (s) => s.availableQuantity > 0,
        );
      } catch (_) {
        // Pas de statut renseigné plutôt qu'un faux "disponible"/"rupture".
      }
      notifyListeners();
    }
    notifyListeners();
  }

  // ==================== RECHERCHE ====================

  Future<void> searchPrescriptions(String query) async {
    try {
      _prescriptions = await _service.searchPrescriptions(query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== NETTOYAGE ====================

  void clearSelected() {
    _selectedPrescription = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _controlledSubstanceMap = {};
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    notifyListeners();
  }

  void resetUpload() {
    _uploadStatus = PrescriptionUploadStatus.idle;
    _uploadError = null;
    _extractedItems = [];
    _ocrConfidenceScore = 0.0;
    _availabilityMap = {};
    _controlledSubstanceMap = {};
    _isProcessingOcr = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
