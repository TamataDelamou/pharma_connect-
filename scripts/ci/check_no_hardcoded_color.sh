#!/usr/bin/env bash
# Garde-fou KER-DES-03 : aucune couleur codée en dur en dehors de
# lib/core/theme/. Deux formes détectées :
#   1. Color(0xFF...) littéral, n'importe où dans lib/ (jamais légitime
#      hors du thème).
#   2. Colors.<nom> sémantique (red, orange, green, blue, purple, yellow,
#      amber, cyan, grey...) dans un modèle métier (lib/modules/*/models/) —
#      c'est précisément la forme qui a échappé au point 1 le 25/08/2026
#      (18 occurrences dans traceability/) et de nouveau le 26/08/2026
#      (47 occurrences dans 10 modèles : alerts, admin, coldchain,
#      traceability, recall, stock). Tout modèle ou widget doit référencer
#      un rôle de PharmaConnectPalette (ou son futur équivalent GSG Design
#      Kit) à la place.
#
# Volontairement exclu du point 2 : Colors.white / Colors.black /
# Colors.transparent, structurels (glass effects, overlays, ombres) et sans
# portée de marque — leur usage est répandu et légitime dans les écrans/
# widgets. Le point 2 est aussi volontairement restreint à */models/ plutôt
# qu'à tout lib/ : un getter statusColor/typeColor/severityColor dans un
# modèle est le seul gabarit où la régression s'est répétée deux fois ;
# étendre la détection à tout lib/ (écrans, widgets) sans revue humaine
# préalable produirait des dizaines de faux positifs sur du code déjà
# accepté.
set -euo pipefail

THEME_DIR="lib/core/theme"
LIB_DIR="lib"
NAMED_COLORS='red|pink|purple|deepPurple|indigo|blue|lightBlue|cyan|teal|green|lightGreen|lime|yellow|amber|orange|deepOrange|brown|grey|gray|blueGrey'

if [ ! -d "$LIB_DIR" ]; then
  echo "✅ KER-DES-03 : aucun répertoire lib/ à vérifier."
  exit 0
fi

HEX_MATCHES=$(grep -rnE "Color\(0x[0-9A-Fa-f]{6,8}\)" --include="*.dart" "$LIB_DIR" \
  | grep -v "^${THEME_DIR}/" || true)

NAMED_MATCHES=$(grep -rnE "Colors\.(${NAMED_COLORS})([.\[]|\b)" --include="*.dart" \
  "$LIB_DIR"/modules/*/models 2>/dev/null || true)

if [ -n "$HEX_MATCHES" ] || [ -n "$NAMED_MATCHES" ]; then
  echo "❌ KER-DES-03 : couleur codée en dur détectée :"
  if [ -n "$HEX_MATCHES" ]; then
    echo "$HEX_MATCHES"
  fi
  if [ -n "$NAMED_MATCHES" ]; then
    echo "$NAMED_MATCHES"
  fi
  echo ""
  echo "Utilisez un rôle de PharmaConnectPalette (context.palette, ColorRole) au lieu d'un Color(0xFF...) ou Colors.<nom> littéral."
  exit 1
fi

echo "✅ KER-DES-03 : aucune couleur codée en dur détectée hors du thème."
