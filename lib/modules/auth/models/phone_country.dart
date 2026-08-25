/// Pays disponibles pour la saisie du numéro de téléphone.
///
/// Un seul pays aujourd'hui (Guinée), miroir de `assets/config/kernel_config.json`
/// qui tourne en `fallback_mode` tant que le GSG Referential (Kernel) n'est pas
/// branché. La liste est volontairement une constante Dart extensible plutôt
/// qu'un chargement JSON : quand le Referential sera branché (KER-REF),
/// `PhoneCountry.supported` devra venir du référentiel résolu au lieu de cette
/// constante, sans changer la forme du widget qui la consomme.
class PhoneCountry {
  final String isoCode;
  final String flag;
  final String dialCode;
  final String nameFr;
  final int localDigits;

  const PhoneCountry({
    required this.isoCode,
    required this.flag,
    required this.dialCode,
    required this.nameFr,
    required this.localDigits,
  });

  static const List<PhoneCountry> supported = [
    PhoneCountry(
      isoCode: 'GN',
      flag: '🇬🇳',
      dialCode: '+224',
      nameFr: 'Guinée',
      localDigits: 9,
    ),
  ];
}
