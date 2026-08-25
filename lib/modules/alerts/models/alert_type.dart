enum AlertType {
  stockLow,
  stockCritical,
  stockOut,
  expirySoon,
  expired,
  counterfeit,
  recall,
  orderConfirmed,
  orderDelivered,
  orderDelayed,
  paymentSuccess,
  paymentFailed,
  paymentDisputed,
  refundProcessed,
  prescriptionReceived,
  prescriptionValidated,
  prescriptionDispensed,
  reservationReady,
  reservationPickedUp,
  reservationExpired,
  deliveryStarted,
  deliveryArrived,
  deliveryCompleted,
  system,
  promotion,
  reminder,
}

extension AlertTypeExtension on AlertType {
  String get label {
    switch (this) {
      case AlertType.stockLow:
        return 'Stock faible';
      case AlertType.stockCritical:
        return 'Stock critique';
      case AlertType.stockOut:
        return 'Rupture de stock';
      case AlertType.expirySoon:
        return 'Péremption proche';
      case AlertType.expired:
        return 'Produit périmé';
      case AlertType.counterfeit:
        return 'Contrefaçon détectée';
      case AlertType.recall:
        return 'Rappel de produit';
      case AlertType.orderConfirmed:
        return 'Commande confirmée';
      case AlertType.orderDelivered:
        return 'Commande livrée';
      case AlertType.orderDelayed:
        return 'Commande en retard';
      case AlertType.paymentSuccess:
        return 'Paiement réussi';
      case AlertType.paymentFailed:
        return 'Paiement échoué';
      case AlertType.paymentDisputed:
        return 'Litige de paiement';
      case AlertType.refundProcessed:
        return 'Remboursement effectué';
      case AlertType.prescriptionReceived:
        return 'Ordonnance reçue';
      case AlertType.prescriptionValidated:
        return 'Ordonnance validée';
      case AlertType.prescriptionDispensed:
        return 'Ordonnance dispensée';
      case AlertType.reservationReady:
        return 'Réservation prête';
      case AlertType.reservationPickedUp:
        return 'Réservation retirée';
      case AlertType.reservationExpired:
        return 'Réservation expirée';
      case AlertType.deliveryStarted:
        return 'Livraison démarrée';
      case AlertType.deliveryArrived:
        return 'Livreur arrivé';
      case AlertType.deliveryCompleted:
        return 'Livraison terminée';
      case AlertType.system:
        return 'Système';
      case AlertType.promotion:
        return 'Promotion';
      case AlertType.reminder:
        return 'Rappel';
    }
  }

  String get icon {
    switch (this) {
      case AlertType.stockLow:
      case AlertType.stockCritical:
      case AlertType.stockOut:
        return '📦';
      case AlertType.expirySoon:
      case AlertType.expired:
        return '⏰';
      case AlertType.counterfeit:
        return '🚫';
      case AlertType.recall:
        return '🔔';
      case AlertType.orderConfirmed:
        return '✅';
      case AlertType.orderDelivered:
        return '📬';
      case AlertType.orderDelayed:
        return '⏳';
      case AlertType.paymentSuccess:
        return '💰';
      case AlertType.paymentFailed:
        return '💳';
      case AlertType.paymentDisputed:
        return '⚖️';
      case AlertType.refundProcessed:
        return '↩️';
      case AlertType.prescriptionReceived:
      case AlertType.prescriptionValidated:
      case AlertType.prescriptionDispensed:
        return '📋';
      case AlertType.reservationReady:
      case AlertType.reservationPickedUp:
      case AlertType.reservationExpired:
        return '🛒';
      case AlertType.deliveryStarted:
      case AlertType.deliveryArrived:
      case AlertType.deliveryCompleted:
        return '🚚';
      case AlertType.system:
        return '⚙️';
      case AlertType.promotion:
        return '🎯';
      case AlertType.reminder:
        return '🔔';
    }
  }
}
