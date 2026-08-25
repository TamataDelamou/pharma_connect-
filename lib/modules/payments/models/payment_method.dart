enum PaymentMethod {
  orangeMoney,
  mtnMomo,
  moovMoney,
  bankCard,
  gsgWallet,
  cashOnDelivery,
  installment,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN MoMo';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.bankCard:
        return 'Carte bancaire';
      case PaymentMethod.gsgWallet:
        return 'Portefeuille GSG';
      case PaymentMethod.cashOnDelivery:
        return 'Paiement à la livraison';
      case PaymentMethod.installment:
        return 'Paiement en plusieurs fois';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return '🟠';
      case PaymentMethod.mtnMomo:
        return '🟡';
      case PaymentMethod.moovMoney:
        return '🔵';
      case PaymentMethod.bankCard:
        return '💳';
      case PaymentMethod.gsgWallet:
        return '⚡';
      case PaymentMethod.cashOnDelivery:
        return '💰';
      case PaymentMethod.installment:
        return '📆';
    }
  }

  bool get isMobileMoney {
    switch (this) {
      case PaymentMethod.orangeMoney:
      case PaymentMethod.mtnMomo:
      case PaymentMethod.moovMoney:
        return true;
      default:
        return false;
    }
  }

  bool get isWallet => this == PaymentMethod.gsgWallet;
  bool get isCard => this == PaymentMethod.bankCard;
  bool get isInstallment => this == PaymentMethod.installment;
}
