enum TransactionStatus { pending, processing, completed, failed, refunded, disputed }

extension TransactionStatusExtension on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.processing:
        return 'En cours';
      case TransactionStatus.completed:
        return 'Réussi';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.refunded:
        return 'Remboursé';
      case TransactionStatus.disputed:
        return 'Litige';
    }
  }
}
