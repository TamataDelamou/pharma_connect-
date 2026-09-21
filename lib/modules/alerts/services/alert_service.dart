import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/alert.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';
import '../models/alert_status.dart';
import '../models/alert_preferences.dart';
import '../../../core/services/supabase_service.dart';

class AlertService {
  SupabaseClient get _client => SupabaseService().client;

  Future<List<Alert>> getAlerts({
    AlertStatus? status,
    AlertType? type,
    AlertSeverity? severity,
    String? userId,
    String? pharmacyId,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    var query = _client.from('alerts').select();

    if (status != null) {
      query = query.eq(
        'status',
        status == AlertStatus.new_ ? 'new' : status.name,
      );
    }
    if (type != null) {
      query = query.eq('type', type.name);
    }
    if (severity != null) {
      query = query.eq('severity', severity.name);
    }
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((row) => Alert.fromJson(row)).toList();
  }

  Future<Alert> getAlert(String id) async {
    final row = await _client.from('alerts').select().eq('id', id).single();
    return Alert.fromJson(row);
  }

  Future<int> getUnreadCount({String? userId, String? pharmacyId}) async {
    var query = _client.from('alerts').select().eq('is_read', false);
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    final rows = await query;
    return rows.length;
  }

  Future<Alert> markAsRead(String id) async {
    final row = await _client
        .from('alerts')
        .update({
          'status': 'read',
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Alert.fromJson(row);
  }

  Future<List<Alert>> markAllAsRead({
    String? userId,
    String? pharmacyId,
  }) async {
    var query = _client
        .from('alerts')
        .update({
          'status': 'read',
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('is_read', false);
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (pharmacyId != null) {
      query = query.eq('pharmacy_id', pharmacyId);
    }
    final rows = await query.select();
    return rows.map((row) => Alert.fromJson(row)).toList();
  }

  Future<Alert> dismissAlert(String id) async {
    final row = await _client
        .from('alerts')
        .update({'status': 'dismissed'})
        .eq('id', id)
        .select()
        .single();
    return Alert.fromJson(row);
  }

  Future<Alert> markAsActioned(String id) async {
    final row = await _client
        .from('alerts')
        .update({
          'status': 'actioned',
          'is_actioned': true,
          'actioned_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Alert.fromJson(row);
  }

  // ==================== CRÉATION D'ALERTE ====================

  Future<Alert> createAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
    String? actionLabel,
    String? actionRoute,
    Map<String, dynamic>? actionParams,
    String? referenceId,
    String? referenceType,
    String? userId,
    String? pharmacyId,
    String? imageUrl,
  }) async {
    final alert = Alert(
      id: const Uuid().v4(),
      type: type,
      severity: severity,
      status: AlertStatus.new_,
      title: title,
      message: message,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      actionParams: actionParams,
      referenceId: referenceId,
      referenceType: referenceType,
      createdAt: DateTime.now(),
      userId: userId,
      pharmacyId: pharmacyId,
      isRead: false,
      isActioned: false,
      imageUrl: imageUrl,
    );

    final row = await _client
        .from('alerts')
        .insert(alert.toJson())
        .select()
        .single();
    final created = Alert.fromJson(row);

    // Envoyer des notifications selon les préférences
    await _sendNotifications(created);

    return created;
  }

  Future<void> _sendNotifications(Alert alert) async {
    // Dans la réalité, on vérifierait les préférences et on enverrait
    // via push, email, ou in-app.
    final preferences = await getPreferences();
    if (preferences.pushEnabled &&
        preferences.isSeverityEnabled(alert.severity)) {
      // await NotificationService.showNotification(...);
    }
    if (preferences.emailEnabled &&
        preferences.isSeverityEnabled(alert.severity)) {
      // await EmailService.sendAlertEmail(...);
    }
  }

  // ==================== PRÉFÉRENCES ====================

  Future<AlertPreferences> getPreferences() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return const AlertPreferences();

    final row = await _client
        .from('alert_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return const AlertPreferences();
    return AlertPreferences.fromJson(row);
  }

  Future<void> updatePreferences(AlertPreferences newPreferences) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;

    await _client.from('alert_preferences').upsert({
      'user_id': userId,
      ...newPreferences.toJson(),
    });
  }

  // ==================== ALERTES SYSTÈME ====================
  //
  // Audit Module 10 (ALR, 29/08/2026) : ces deux méthodes existaient déjà
  // (implémentation complète, correctement pensée), mais n'étaient appelées
  // NULLE PART dans l'application — 8ème occurrence du schéma déjà documenté
  // au registre (D6) : du code fonctionnel jamais câblé à un déclencheur
  // métier réel. Câblées depuis cet audit à StockProvider.loadAlerts() (voir
  // ce fichier), au moment où le pharmacien consulte l'écran « Alertes de
  // stock » — c'est un déclenchement à l'ouverture d'écran, pas un vrai
  // temps réel serveur (aucun trigger PostgreSQL ni Edge Function n'existe
  // dans ce projet, même limite structurelle que RG-PAY-01, voir registre).
  // Un doublon est évité via _hasUnresolvedAlert avant chaque insertion.

  /// Vrai s'il existe déjà une alerte non résolue (status new/read) pour
  /// cette référence et ce type précis — évite de ré-insérer une alerte
  /// identique à chaque chargement de l'écran (l'ancienne implémentation,
  /// jamais appelée jusqu'ici, n'avait pas ce problème faute d'être câblée).
  /// Gardé par type (et non juste par référence) pour laisser passer une
  /// escalade légitime (ex. stockLow -> stockCritical).
  Future<bool> _hasUnresolvedAlert({
    required String referenceId,
    required String referenceType,
    required AlertType type,
  }) async {
    final rows = await _client
        .from('alerts')
        .select('id')
        .eq('reference_id', referenceId)
        .eq('reference_type', referenceType)
        .eq('type', type.name)
        .inFilter('status', ['new', 'read'])
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> generateStockAlert({
    required String productName,
    required int quantity,
    required String stockItemId,
    required String pharmacyId,
    required int thresholdLow,
    required int thresholdCritical,
  }) async {
    // thresholdLow/thresholdCritical sont désormais obligatoires et fournis
    // par l'appelant (StockItem.thresholdLow/thresholdCritical réels) —
    // audit Module 10 : les anciennes valeurs par défaut (20/5) codées en dur
    // ici ignoraient le paramétrage par produit déjà en place depuis le
    // Module 4 (StockService.computeStockStatus utilise ces mêmes seuils),
    // ce qui aurait produit une sévérité incohérente avec le reste de l'app
    // dès le premier câblage réel.
    AlertType type;
    AlertSeverity severity;
    String title;

    if (quantity <= 0) {
      type = AlertType.stockOut;
      severity = AlertSeverity.critical;
      title = 'Rupture de stock : $productName';
    } else if (quantity <= thresholdCritical) {
      type = AlertType.stockCritical;
      severity = AlertSeverity.critical;
      title = 'Stock critique : $productName';
    } else if (quantity <= thresholdLow) {
      type = AlertType.stockLow;
      severity = AlertSeverity.warning;
      title = 'Stock faible : $productName';
    } else {
      return; // Pas d'alerte
    }

    if (await _hasUnresolvedAlert(
      referenceId: stockItemId,
      referenceType: 'stock_item',
      type: type,
    )) {
      return;
    }

    await createAlert(
      type: type,
      severity: severity,
      title: title,
      message:
          'Il ne reste que $quantity unités en stock. Réapprovisionnement nécessaire.',
      actionLabel: 'Voir le stock',
      actionRoute: '/stock',
      referenceId: stockItemId,
      referenceType: 'stock_item',
      pharmacyId: pharmacyId,
    );
  }

  Future<void> generateExpiryAlert({
    required String productName,
    required String batchNumber,
    required DateTime expiryDate,
    required String batchId,
    required String pharmacyId,
    int daysThreshold = 30,
  }) async {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

    if (daysUntilExpiry < 0) {
      if (await _hasUnresolvedAlert(
        referenceId: batchId,
        referenceType: 'batch',
        type: AlertType.expired,
      )) {
        return;
      }
      await createAlert(
        type: AlertType.expired,
        severity: AlertSeverity.critical,
        title: 'Produit périmé : $productName',
        message:
            'Le lot #$batchNumber est périmé depuis ${-daysUntilExpiry} jours.',
        actionLabel: 'Voir le lot',
        actionRoute: '/stock',
        referenceId: batchId,
        referenceType: 'batch',
        pharmacyId: pharmacyId,
      );
    } else if (daysUntilExpiry <= daysThreshold) {
      if (await _hasUnresolvedAlert(
        referenceId: batchId,
        referenceType: 'batch',
        type: AlertType.expirySoon,
      )) {
        return;
      }
      await createAlert(
        type: AlertType.expirySoon,
        severity: AlertSeverity.warning,
        title: 'Péremption dans $daysUntilExpiry jours',
        message:
            'Le lot #$batchNumber ($productName) expire dans $daysUntilExpiry jours.',
        actionLabel: 'Voir le lot',
        actionRoute: '/stock',
        referenceId: batchId,
        referenceType: 'batch',
        pharmacyId: pharmacyId,
      );
    }
  }
}
