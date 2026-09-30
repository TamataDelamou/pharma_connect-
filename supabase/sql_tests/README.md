# Tests SQL versionnés

Tests manuels à lancer sur la base **locale** (`supabase start`, conteneur `supabase_db_pharma_connect`), de préférence juste après `supabase db reset --local`. Ce dossier est distinct de `supabase/tests/`, réservé à `supabase test db` (pgTAP).

| Fichier | Objet |
|---|---|
| `c197_c203_pos_atomic_sale.sql` | Vente et remboursement POS atomiques (`pos_create_sale`, `pos_refund_sale`) : cas 1 à 10 de C197 (remboursements avec la signature C204), cas 11 à 16 des contrôles C203. |
| `c202_document_numbering.sql` | Numérotation globale (C202) des retours client et fournisseur, tickets de support, e-ordonnances et contrats : deux identités aux portées RLS disjointes créent chacune un document. |
| `c204_pos_refund_policy.sql` | Règle de remboursement POS (C204, décision D57) : jour même et plafond hors titulaire, motif obligatoire, remise en stock ou quarantaine, une seule signature `pos_refund_sale(uuid, text, text)`, lecture et écriture de `pos_refund_quarantine`. |
| `c208_manager_attachment.sql` | Rattachement du titulaire (`pharmacies.manager_id`) à son officine (`profiles.pharmacy_id`, C208) : insertion directe active, changement de titulaire, officine pending, rattrapage. |
| `c211_verified_roles.sql` | Rôle déclaré ≠ rôle vérifié (C211, C212, décision D58) : verrouillage de `profiles.role` / `pharmacy_id` / `role_verified_*` et de la vérification des professionnels, `has_verified_role`, `admin_set_user_role`, policies fondées sur un rôle vérifié. |
| `c214_admin_role_validation.sql` | Validation des rôles et vérification des professionnels par l'administration GSG (C214) : `admin_list_verification_requests`, `admin_review_role`, `admin_verify_professional`, `admin_set_user_role` journalisée, droits réservés à `is_gsg_admin()`, journal `audit_logs`. |
| `c209_pharmacy_staff_invitations.sql` | Rattachement du personnel non titulaire (C209, décision D59) : invitation par le titulaire d'une officine validée (numéro de téléphone), acceptation ou refus par l'employé, annulation, retrait, départ, liste du personnel, cloisonnement entre officines. |
| `concurrency_numbering.sh` | Deux sessions `psql` simultanées (retours client, puis ventes POS de deux officines) : numéros distincts et consécutifs, la seconde session attend la première. |

Chaque cas affiche une ligne `CAS n OK : …` ou `CAS n ECHEC : …` (`RESULTAT … OK/ECHEC` pour le script de concurrence).

## Exécution

Depuis la racine du dépôt :

```bash
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c197_c203_pos_atomic_sale.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c202_document_numbering.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c204_pos_refund_policy.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c208_manager_attachment.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c211_verified_roles.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c214_admin_role_validation.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c209_pharmacy_staff_invitations.sql
bash supabase/sql_tests/concurrency_numbering.sh
```

Les fichiers `.sql` s'exécutent dans une seule transaction terminée par `rollback` : ils ne laissent aucune donnée. Le script de concurrence doit committer ses données (deux sessions) ; il se termine par `supabase db reset --local`, qui efface toute la base locale.

Les identifiants du seed (lots, stock) sont générés aléatoirement à chaque `db reset` : les tests retrouvent les lots par `batch_number` et officine, jamais par identifiant.
