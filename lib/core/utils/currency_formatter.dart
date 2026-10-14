/// Point d'entrée unique pour l'affichage des montants monétaires du produit.
///
/// La devise par défaut (GNF, ISO 4217 alpha-3 / numérique 324) est câblée en
/// dur tant que le produit ne gère qu'un seul marché. Quand le GSG Referential
/// sera branché (KER-REF), `defaultCurrencyCode` devra venir du référentiel
/// résolu pour l'organisation courante plutôt que d'une constante ici.
class CurrencyFormatter {
  const CurrencyFormatter._();

  static const String defaultCurrencyCode = 'GNF';
  static const int defaultCurrencyNumericCode = 324;

  /// Espace insécable (U+00A0) : un montant n'est jamais coupé en fin de
  /// ligne.
  static final String nbsp = String.fromCharCode(0x00A0);

  /// Signe moins typographique (U+2212).
  static final String minus = String.fromCharCode(0x2212);

  /// C267 : montant arrondi à l'unité, séparateur des milliers à la
  /// française. Une espace insécable sépare les groupes de chiffres et le
  /// code de la devise : « 1 575 GNF », « 150 000 GNF », « -1 500 GNF »
  /// (avec le signe moins typographique).
  static String format(
    num amount, {
    String currencyCode = defaultCurrencyCode,
  }) {
    final rounded = amount.round();
    final digits = rounded.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => nbsp,
    );
    final sign = rounded < 0 ? minus : '';
    return '$sign$digits$nbsp$currencyCode';
  }

  /// C267 : montant saisi par l'utilisateur, avec ou sans séparateur des
  /// milliers (« 10000 », « 10 000 », « 10 000 GNF »). Rend `null` si la
  /// saisie n'est pas un nombre entier positif ou nul. `\s` couvre aussi les
  /// espaces insécables (U+00A0, U+202F).
  static int? parse(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(RegExp(defaultCurrencyCode, caseSensitive: false), '');
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    return int.tryParse(cleaned);
  }
}
