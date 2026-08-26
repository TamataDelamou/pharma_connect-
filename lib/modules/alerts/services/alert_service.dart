import '../models/alert.dart';
import '../models/alert_type.dart';
import '../models/alert_severity.dart';
import '../models/alert_status.dart';
import '../models/alert_preferences.dart';
import '../../../core/utils/currency_formatter.dart';

class AlertService {
  static final List<Alert> _alerts = [];
  static AlertPreferences _preferences = const AlertPreferences();

  // ==================== DONNÉES MOCKÉES ====================

  static final List<Alert> _mockAlerts = [
    Alert(
      id: 'alt_001',
      type: AlertType.stockCritical,
      severity: AlertSeverity.critical,
      status: AlertStatus.new_,
      title: 'Stock critique : Paracétamol 500mg',
      message:
          'Il ne reste que 3 unités en stock. Réapprovisionnement urgent nécessaire.',
      actionLabel: 'Voir le stock',
      actionRoute: '/stock',
      referenceId: 'stock_001',
      referenceType: 'stock_item',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      isActioned: false,
    ),
    Alert(
      id: 'alt_002',
      type: AlertType.expirySoon,
      severity: AlertSeverity.warning,
      status: AlertStatus.new_,
      title: 'Péremption dans 7 jours',
      message: 'Le lot #B2024-003 (Amoxicilline) expire dans 7 jours.',
      actionLabel: 'Voir le lot',
      actionRoute: '/stock',
      referenceId: 'batch_003',
      referenceType: 'batch',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      isActioned: false,
    ),
    Alert(
      id: 'alt_003',
      type: AlertType.reservationReady,
      severity: AlertSeverity.success,
      status: AlertStatus.new_,
      title: 'Commande prête à être retirée !',
      message: 'Votre commande #RES-001 est prête à la Pharmacie Centrale.',
      actionLabel: 'Voir la réservation',
      actionRoute: '/reservations/confirmation',
      referenceId: 'res_001',
      referenceType: 'reservation',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      isActioned: false,
    ),
    Alert(
      id: 'alt_004',
      type: AlertType.paymentSuccess,
      severity: AlertSeverity.success,
      status: AlertStatus.read,
      title: 'Paiement effectué avec succès',
      message:
          'Votre paiement de ${CurrencyFormatter.format(15000)} a été confirmé.',
      actionLabel: 'Voir la transaction',
      actionRoute: '/transactions',
      referenceId: 'tx_001',
      referenceType: 'transaction',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      isActioned: false,
    ),
    Alert(
      id: 'alt_005',
      type: AlertType.deliveryStarted,
      severity: AlertSeverity.info,
      status: AlertStatus.new_,
      title: 'Votre livraison est en route !',
      message: 'Amadou Diallo a pris en charge votre livraison.',
      actionLabel: 'Suivre la livraison',
      actionRoute: '/deliveries/tracking',
      referenceId: 'del_001',
      referenceType: 'delivery',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      isActioned: false,
    ),
    Alert(
      id: 'alt_006',
      type: AlertType.recall,
      severity: AlertSeverity.critical,
      status: AlertStatus.new_,
      title: 'Rappel de lot : Doliprane 1000mg',
      message:
          'Le lot #DOL-2024-001 fait l\'objet d\'un rappel pour défaut de fabrication.',
      actionLabel: 'Voir les détails',
      actionRoute: '/recall',
      referenceId: 'recall_001',
      referenceType: 'recall',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      isActioned: false,
    ),
  ];

  static void _initMockData() {
    if (_alerts.isEmpty) {
      _alerts.addAll(_mockAlerts);
    }
  }

  // ==================== MÉTHODES ====================

  Future<List<Alert>> getAlerts({
    AlertStatus? status,
    AlertType? type,
    AlertSeverity? severity,
    String? userId,
    String? pharmacyId,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    var list = _alerts;

    if (status != null) {
      list = list.where((a) => a.status == status).toList();
    }

    if (type != null) {
      list = list.where((a) => a.type == type).toList();
    }

    if (severity != null) {
      list = list.where((a) => a.severity == severity).toList();
    }

    if (userId != null) {
      list = list.where((a) => a.userId == userId).toList();
    }

    if (pharmacyId != null) {
      list = list.where((a) => a.pharmacyId == pharmacyId).toList();
    }

    if (unreadOnly) {
      list = list.where((a) => !a.isRead).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  Future<Alert> getAlert(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _alerts.firstWhere((a) => a.id == id);
  }

  Future<int> getUnreadCount({String? userId, String? pharmacyId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _initMockData();
    var list = _alerts.where((a) => !a.isRead);
    if (userId != null) {
      list = list.where((a) => a.userId == userId);
    }
    if (pharmacyId != null) {
      list = list.where((a) => a.pharmacyId == pharmacyId);
    }
    return list.length;
  }

  Future<Alert> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Alert not found');

    final updated = _alerts[index].copyWith(
      status: AlertStatus.read,
      isRead: true,
      readAt: DateTime.now(),
    );
    _alerts[index] = updated;
    return updated;
  }

  Future<List<Alert>> markAllAsRead({
    String? userId,
    String? pharmacyId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final updatedAlerts = <Alert>[];

    for (int i = 0; i < _alerts.length; i++) {
      final alert = _alerts[i];
      if (!alert.isRead) {
        if ((userId == null || alert.userId == userId) &&
            (pharmacyId == null || alert.pharmacyId == pharmacyId)) {
          _alerts[i] = alert.copyWith(
            status: AlertStatus.read,
            isRead: true,
            readAt: DateTime.now(),
          );
          updatedAlerts.add(_alerts[i]);
        }
      }
    }

    return updatedAlerts;
  }

  Future<Alert> dismissAlert(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Alert not found');

    final updated = _alerts[index].copyWith(status: AlertStatus.dismissed);
    _alerts[index] = updated;
    return updated;
  }

  Future<Alert> markAsActioned(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Alert not found');

    final updated = _alerts[index].copyWith(
      status: AlertStatus.actioned,
      isActioned: true,
      actionedAt: DateTime.now(),
    );
    _alerts[index] = updated;
    return updated;
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
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();

    final alert = Alert(
      id: 'alt_${DateTime.now().millisecondsSinceEpoch}',
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

    _alerts.add(alert);

    // Envoyer des notifications selon les préférences
    await _sendNotifications(alert);

    return alert;
  }

  Future<void> _sendNotifications(Alert alert) async {
    // Simuler l'envoi de notifications
    // Dans la réalité, on vérifierait les préférences et on enverrait
    // via push, email, ou in-app
    if (_preferences.pushEnabled &&
        _preferences.isSeverityEnabled(alert.severity)) {
      // Envoyer une notification push
      // await NotificationService.showNotification(...);
    }

    if (_preferences.emailEnabled &&
        _preferences.isSeverityEnabled(alert.severity)) {
      // Envoyer un email
      // await EmailService.sendAlertEmail(...);
    }
  }

  // ==================== PRÉFÉRENCES ====================

  Future<AlertPreferences> getPreferences() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _preferences;
  }

  Future<void> updatePreferences(AlertPreferences newPreferences) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _preferences = newPreferences;
  }

  // ==================== ALERTES SYSTÈME ====================

  Future<void> generateStockAlert({
    required String productName,
    required int quantity,
    required String stockItemId,
    required String pharmacyId,
    int thresholdLow = 20,
    int thresholdCritical = 5,
  }) async {
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
