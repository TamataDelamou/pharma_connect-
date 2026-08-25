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

  static String format(num amount, {String currencyCode = defaultCurrencyCode}) {
    return '${amount.toStringAsFixed(0)} $currencyCode';
  }
}
