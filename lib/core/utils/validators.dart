/// Validateurs et normalisateurs pour les données métier.
class Validators {
  /// Normalise un numéro de téléphone vers le format E.164 strict
  /// (supprime espaces, tirets, parenthèses ; s'assure du préfixe '+').
  /// Retourne null si le numéro est invalide.
  static String? normalizeE164(String input) {
    if (input.isEmpty) return null;

    // Supprimer tous les caractères non numériques sauf le '+'
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Exiger le préfixe '+'
    if (!cleaned.startsWith('+')) {
      return null;
    }

    // Longueur minimale : +224 + 8 chiffres = 12 caractères
    if (cleaned.length < 12) return null;

    return cleaned;
  }
}
