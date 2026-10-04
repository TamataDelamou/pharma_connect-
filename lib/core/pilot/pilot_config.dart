/// Interrupteur central du périmètre du pilote (registre, C239), sur le
/// modèle de `KernelUi`.
///
/// Une valeur par fonction. Tant qu'une valeur est fausse, la fonction est
/// masquée partout dans l'application ; rien n'est supprimé, la passer à
/// vrai la rétablit sans autre changement.
class PilotConfig {
  // ===== Connexion et inscription =====
  // « Code par e-mail » reste toujours proposé (prouvé en ligne, A31).
  static const bool authSms = false;
  static const bool authWhatsapp = false;
  static const bool authMagicLink = false;

  // ===== Paiement =====
  // Aucun moyen activé : la réservation se termine par « À payer à
  // l'officine au retrait », sans paiement en ligne.
  static const bool payOrangeMoney = false;
  static const bool payMtnMomo = false;
  static const bool payMoovMoney = false;
  static const bool payGsgWallet = false;
  static const bool payBankCard = false;
  static const bool payInstallment = false;
  static const bool payOnDelivery = false;
  // Pastilles « 2 % cashback », case « Utiliser mon cashback » et ligne de
  // cashback du résumé.
  static const bool cashback = false;

  /// Libellé de fin de réservation quand aucun moyen de paiement n'est activé.
  static const String payAtPickupLabel = 'À payer à l\'officine au retrait';

  // ===== Accueil =====
  // Indicateurs du tableau de bord (« Pharmacies actives », « 94 % »…) :
  // valeurs fictives de `DashboardProvider`, pas de vraies données.
  static const bool dashboardDemoStats = false;
  // Activité récente et alertes du tableau de bord : fictives elles aussi.
  static const bool dashboardDemoActivity = false;
}
