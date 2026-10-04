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

  /// Un seul mode de réception : la puce de choix est inutile et le
  /// sous-titre devient [authEmailOnlySubtitle].
  static const bool authEmailOnly = !authSms && !authWhatsapp && !authMagicLink;
  static const String authEmailOnlySubtitle =
      'Recevez un code de connexion par e-mail';

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

  // ===== Réservation (Click & Collect) =====
  // Étape « Livraison » (adresse, chaîne du froid) : le pilote se fait en
  // retrait à l'officine.
  static const bool reservationDelivery = false;
  // Étape « Créneau » : les disponibilités sont tirées au hasard
  // (`ReservationService.getAvailableTimeSlots`), aucune table de créneaux.
  static const bool reservationTimeslots = false;

  // ===== Fonctions « IA » simulées (registre, A36) =====
  // Prévision de la demande : bouton de l'écran des alertes de stock (les
  // routes /stock/forecast et /analytics/forecast sont déjà retirées, C188).
  static const bool aiDemandForecast = false;
  // Assistant du support (réponses par mots-clés, repli tiré au hasard) :
  // /support/chat et /support/bot/history.
  static const bool aiSupportBot = false;
  // Lecture automatique des ordonnances : extraction, « confiance OCR » et
  // substitution générique fictive (/prescriptions/preview). Masquée,
  // l'ordonnance est envoyée en photo à l'officine, sans analyse.
  static const bool aiPrescriptionOcr = false;
  // Objets connectés : /iot et ses écrans (« Simuler une lecture »).
  static const bool iot = false;
  // Sans route ni appelant aujourd'hui, donc rien à masquer : pré-consultation
  // (`PreConsultationScreen`), traduction (`TranslationService`), défis et
  // récompenses « IA » de fidélité, synthèse « IA » du dossier de santé.

  // ===== Accueil =====
  // Indicateurs du tableau de bord (« Pharmacies actives », « 94 % »…) :
  // valeurs fictives de `DashboardProvider`, pas de vraies données.
  static const bool dashboardDemoStats = false;
  // Activité récente et alertes du tableau de bord : fictives elles aussi.
  static const bool dashboardDemoActivity = false;
}
