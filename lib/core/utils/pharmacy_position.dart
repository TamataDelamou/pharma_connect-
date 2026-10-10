/// C252 : contrôle de la position d'une officine, saisie par
/// l'administrateur ou lue par le téléphone à la candidature.
class PharmacyPosition {
  const PharmacyPosition._();

  // Emprise approximative de la Guinée. Hors de cette emprise, la position
  // reste acceptée : simple avertissement (officine frontalière, erreur de
  // saisie à corriger).
  //
  // Limite connue : c'est un rectangle, pas le tracé de la frontière. Les
  // zones des pays voisins qui tombent dedans (Freetown, Bamako) ne sont pas
  // signalées. Ce contrôle détecte une erreur de saisie grossière ; ce n'est
  // pas un contrôle de frontière.
  static const double guineaMinLatitude = 7.0;
  static const double guineaMaxLatitude = 12.7;
  static const double guineaMinLongitude = -15.1;
  static const double guineaMaxLongitude = -7.6;

  /// Message de refus, ou `null` si les deux valeurs sont des coordonnées
  /// possibles (latitude entre -90 et 90, longitude entre -180 et 180).
  static String? validate(double? latitude, double? longitude) {
    if (latitude == null || latitude.isNaN || latitude < -90 || latitude > 90) {
      return 'Latitude invalide : un nombre entre -90 et 90.';
    }
    if (longitude == null ||
        longitude.isNaN ||
        longitude < -180 ||
        longitude > 180) {
      return 'Longitude invalide : un nombre entre -180 et 180.';
    }
    return null;
  }

  /// Vrai si le point, valide, tombe hors de l'emprise de la Guinée.
  static bool isOutsideGuinea(double latitude, double longitude) =>
      latitude < guineaMinLatitude ||
      latitude > guineaMaxLatitude ||
      longitude < guineaMinLongitude ||
      longitude > guineaMaxLongitude;

  static const String outsideGuineaWarning =
      'Ce point semble hors de la Guinée. Vérifiez la latitude et la '
      'longitude (et leur ordre).';
}
