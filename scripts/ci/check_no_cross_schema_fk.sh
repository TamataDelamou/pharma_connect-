#!/usr/bin/env bash
# Garde-fou KER-VIS-03 : aucune contrainte SQL ne doit référencer un schéma
# externe au projet (ex: un schéma appartenant au Kernel GSG, type
# gsg_id.utilisateur ou gsg_ref.pays). Le lien vers le Kernel passe toujours
# par un scalaire (uuid/string) + appel API, jamais par une contrainte SQL.
#
# Les schémas internes au projet Supabase restent autorisés (public, auth,
# storage, extensions, graphql_public).
#
# Nécessite GNU grep (grep -P). Disponible par défaut sur les runners
# ubuntu-latest de GitHub Actions.
set -euo pipefail

ALLOWED='public|auth|storage|extensions|graphql_public'
MIGRATIONS_DIR="supabase/migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "✅ KER-VIS-03 : aucun répertoire de migrations à vérifier."
  exit 0
fi

MATCHES=$(grep -rnPi "references\s+[a-z_][a-z0-9_]*\.(?!(${ALLOWED})\b)" \
  --include="*.sql" "$MIGRATIONS_DIR" 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
  echo "❌ KER-VIS-03 : référence SQL vers un schéma externe détectée (probable table du Kernel GSG) :"
  echo "$MATCHES"
  echo ""
  echo "Le lien vers le Kernel doit passer par un scalaire (uuid/string) + appel API, jamais par une contrainte SQL inter-schémas."
  exit 1
fi

echo "✅ KER-VIS-03 : aucune référence SQL vers un schéma externe."
