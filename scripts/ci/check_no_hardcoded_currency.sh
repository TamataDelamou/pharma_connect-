#!/usr/bin/env bash
# Garde-fou KER-REF : aucune chaîne de devise codée en dur dans un widget
# Flutter. Tout montant affiché doit passer par CurrencyFormatter
# (lib/core/utils/currency_formatter.dart), seul endroit autorisé à contenir
# un code devise littéral.
set -euo pipefail

CURRENCY_CODES='GNF|FCFA|XOF|XAF|EUR|USD|GBP'
ALLOWED_FILE="lib/core/utils/currency_formatter.dart"
LIB_DIR="lib"

if [ ! -d "$LIB_DIR" ]; then
  echo "✅ KER-REF : aucun répertoire lib/ à vérifier."
  exit 0
fi

MATCHES=$(grep -rnE "'[^']*\b(${CURRENCY_CODES})\b[^']*'" --include="*.dart" "$LIB_DIR" \
  | grep -v "$ALLOWED_FILE" || true)

if [ -n "$MATCHES" ]; then
  echo "❌ KER-REF : chaîne de devise codée en dur détectée hors de CurrencyFormatter :"
  echo "$MATCHES"
  echo ""
  echo "Utilisez CurrencyFormatter.format(amount) au lieu d'une chaîne littérale."
  exit 1
fi

echo "✅ KER-REF : aucune chaîne de devise codée en dur détectée."
