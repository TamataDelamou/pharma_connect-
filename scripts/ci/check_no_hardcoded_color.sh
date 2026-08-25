#!/usr/bin/env bash
# Garde-fou KER-DES-03 : aucune couleur codée en dur (Color(0xFF...)) en
# dehors de lib/core/theme/. Tout modèle ou widget doit référencer une
# constante PharmaConnectColors (ou son futur équivalent GSG Design Kit).
set -euo pipefail

THEME_DIR="lib/core/theme"
LIB_DIR="lib"

if [ ! -d "$LIB_DIR" ]; then
  echo "✅ KER-DES-03 : aucun répertoire lib/ à vérifier."
  exit 0
fi

MATCHES=$(grep -rnE "Color\(0x[0-9A-Fa-f]{6,8}\)" --include="*.dart" "$LIB_DIR" \
  | grep -v "^${THEME_DIR}/" || true)

if [ -n "$MATCHES" ]; then
  echo "❌ KER-DES-03 : couleur codée en dur détectée hors de lib/core/theme/ :"
  echo "$MATCHES"
  echo ""
  echo "Utilisez une constante PharmaConnectColors au lieu d'un Color(0xFF...) littéral."
  exit 1
fi

echo "✅ KER-DES-03 : aucune couleur codée en dur détectée hors du thème."
