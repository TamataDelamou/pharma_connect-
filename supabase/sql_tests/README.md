# Tests SQL versionnés

Tests manuels à lancer sur la base **locale** (`supabase start`, conteneur `supabase_db_pharma_connect`), de préférence juste après `supabase db reset --local`. Ce dossier est distinct de `supabase/tests/`, réservé à `supabase test db` (pgTAP).

| Fichier | Objet |
|---|---|
| `c197_c203_pos_atomic_sale.sql` | Vente et remboursement POS atomiques (`pos_create_sale`, `pos_refund_sale`) : cas 1 à 10 de C197, cas 11 à 16 des contrôles C203. |
| `c202_document_numbering.sql` | Numérotation globale (C202) des retours client et fournisseur, tickets de support, e-ordonnances et contrats : deux identités aux portées RLS disjointes créent chacune un document. |
| `concurrency_numbering.sh` | Deux sessions `psql` simultanées (retours client, puis ventes POS de deux officines) : numéros distincts et consécutifs, la seconde session attend la première. |

Chaque cas affiche une ligne `CAS n OK : …` ou `CAS n ECHEC : …` (`RESULTAT … OK/ECHEC` pour le script de concurrence).

## Exécution

Depuis la racine du dépôt :

```bash
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c197_c203_pos_atomic_sale.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c202_document_numbering.sql
bash supabase/sql_tests/concurrency_numbering.sh
```

Les deux fichiers `.sql` s'exécutent dans une seule transaction terminée par `rollback` : ils ne laissent aucune donnée. Le script de concurrence doit committer ses données (deux sessions) ; il se termine par `supabase db reset --local`, qui efface toute la base locale.

Les identifiants du seed (lots, stock) sont générés aléatoirement à chaque `db reset` : les tests retrouvent les lots par `batch_number` et officine, jamais par identifiant.
