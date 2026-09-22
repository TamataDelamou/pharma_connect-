import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'alert_type.dart';
import 'alert_severity.dart';
import 'alert_status.dart';

class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionParams;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? actionedAt;
  final String? userId;
  final String? pharmacyId;
  final bool isRead;
  final bool isActioned;
  final String? imageUrl;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    this.actionParams,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.readAt,
    this.actionedAt,
    this.userId,
    this.pharmacyId,
    this.isRead = false,
    this.isActioned = false,
    this.imageUrl,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String;
    return Alert(
      id: json['id'] as String,
      type: AlertType.values.byName(json['type'] as String),
      severity: AlertSeverity.values.byName(json['severity'] as String),
      status: statusRaw == 'new'
          ? AlertStatus.new_
          : AlertStatus.values.byName(statusRaw),
      title: json['title'] as String,
      message: json['message'] as String,
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
      actionParams: json['action_params'] as Map<String, dynamic>?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      actionedAt: json['actioned_at'] != null
          ? DateTime.parse(json['actioned_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      pharmacyId: json['pharmacy_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isActioned: json['is_actioned'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'status': status == AlertStatus.new_ ? 'new' : status.name,
    'title': title,
    'message': message,
    'action_label': actionLabel,
    'action_route': actionRoute,
    'action_params': actionParams,
    'reference_id': referenceId,
    'reference_type': referenceType,
    'created_at': createdAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'actioned_at': actionedAt?.toIso8601String(),
    'user_id': userId,
    'pharmacy_id': pharmacyId,
    'is_read': isRead,
    'is_actioned': isActioned,
    'image_url': imageUrl,
  };

  Alert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    AlertStatus? status,
    String? title,
    String? message,
    String? actionLabel,
    String? actionRoute,
    Map<String, dynamic>? actionParams,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? actionedAt,
    String? userId,
    String? pharmacyId,
    bool? isRead,
    bool? isActioned,
    String? imageUrl,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      actionParams: actionParams ?? this.actionParams,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return PharmaConnectColors.accentRed;
      case AlertSeverity.warning:
        return PharmaConnectColors.accentOrange;
      case AlertSeverity.info:
        return PharmaConnectColors.accentCyan;
      case AlertSeverity.success:
        return PharmaConnectColors.accentGreen;
    }
  }

  String get severityIcon {
    switch (severity) {
      case AlertSeverity.critical:
        return '🔴';
      case AlertSeverity.warning:
        return '🟡';
      case AlertSeverity.info:
        return '🔵';
      case AlertSeverity.success:
        return '🟢';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AlertStatus.new_:
        return Icons.notifications_active;
      case AlertStatus.read:
        return Icons.notifications_off;
      case AlertStatus.dismissed:
        return Icons.delete_outline;
      case AlertStatus.actioned:
        return Icons.check_circle;
    }
  }

  String get statusLabel {
    switch (status) {
      case AlertStatus.new_:
        return 'Nouveau';
      case AlertStatus.read:
        return 'Lu';
      case AlertStatus.dismissed:
        return 'Ignoré';
      case AlertStatus.actioned:
        return 'Traité';
    }
  }

  /// Recommandation courte associée au type d'alerte, affichée sur l'écran
  /// de détail (Module 10 — ALR, audit 29/08/2026). Le cahier de conception
  /// prévoit un écran « Détail d'une alerte avec recommandation » parmi les
  /// écrans principaux d'ALR ; ce getter centralise le texte plutôt que de
  /// le dupliquer dans le widget d'écran.
  String get recommendation {
    switch (type) {
      case AlertType.stockLow:
        return 'Planifiez un réapprovisionnement auprès de votre grossiste-répartiteur avant que le stock ne devienne critique.';
      case AlertType.stockCritical:
        return 'Réapprovisionnement urgent recommandé : le stock disponible est proche du seuil critique paramétré pour ce produit.';
      case AlertType.stockOut:
        return 'Produit en rupture : passez commande immédiatement et signalez l\'indisponibilité si des réservations sont en attente.';
      case AlertType.expirySoon:
        return 'Priorisez l\'écoulement de ce lot (mise en avant, promotion) — le moteur FEFO le propose déjà en premier lors des ventes.';
      case AlertType.expired:
        return 'Retirez ce lot de la vente sans délai et enregistrez sa mise au rebut via un ajustement de stock (motif péremption).';
      case AlertType.counterfeit:
        return 'Isolez immédiatement le produit concerné et signalez-le au régulateur conformément à la procédure de traçabilité.';
      case AlertType.recall:
        return 'Consultez la fiche de rappel et retirez les lots concernés de la vente sans délai.';
      case AlertType.orderDelayed:
        return 'Contactez le livreur ou le grossiste pour connaître la cause du retard et informer le patient si nécessaire.';
      case AlertType.paymentFailed:
        return 'Vérifiez la transaction avec le patient — un nouveau moyen de paiement peut être nécessaire.';
      case AlertType.paymentDisputed:
        return 'Consultez le dossier de litige et répondez dans les délais impartis.';
      case AlertType.prescriptionReceived:
        return 'Validez ou rejetez cette ordonnance dès que possible pour ne pas retarder la prise en charge du patient.';
      case AlertType.reservationReady:
        return 'Le patient peut venir retirer sa commande — un rappel automatique lui a été envoyé si activé dans ses préférences.';
      case AlertType.reservationExpired:
        return 'La réservation n\'a pas été retirée à temps : le stock associé a été libéré, contactez le patient si besoin.';
      case AlertType.deliveryArrived:
        return 'Le livreur est arrivé à destination — aucune action requise, suivez la confirmation de remise.';
      default:
        return 'Consultez les détails ci-dessus et l\'action associée pour traiter cette alerte.';
    }
  }
}
