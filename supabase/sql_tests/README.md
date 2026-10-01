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
| `c201_pos_sale_from_stock.sql` | Vente sur le vrai stock (C201, décision D60) : recherche en stock, lots choisis par le serveur (péremption la plus proche, périmés et réservés exclus, répartition sur plusieurs lots), lot périmé refusé, ligne sans produit refusée, ordonnance tracée sans blocage, remboursement d'une vente répartie. |
| `c216_c217_care_scoped_access.sql` | Accès aux données de santé (C216, décision D61) : dossiers par lien de soin (consultation ou soin à domicile non annulés), lien non falsifiable, ordonnances visibles de l'officine destinataire seulement, triage limité à l'hôpital d'affiliation, stupéfiants retirés aux livreurs ; journal d'audit réservé à GSG et `admin_log_action` (C217). |
| `c218_c210_price_and_suspended_pharmacy.sql` | Prix de vente imposé par le serveur (C218 : prix du stock, prix non renseigné refusé, ligne par produit ou par lot) et officine non active sans accès (C210 : suspendue, en attente, en révision ou rejetée ; rattachement conservé, accès rétabli à la réactivation). |
| `c205_cash_linked_to_sales.sql` | Caisse reliée aux ventes et aux remboursements (C205, décision D62) : ouverture contrôlée (une caisse par caissier), vente et remboursement en espèces avec caisse ouverte, autres moyens tracés à part, dépôts et retraits, écritures directes interdites, solde attendu, fermeture, cloisonnement. |
| `c219_emergency_access.sql` | Accès d'urgence au dossier de santé (C219, décision D63) : déclaration depuis un triage en cours par un professionnel affilié à l'hôpital, motif obligatoire, 24 heures, journal d'audit, visibilité patient / professionnel / GSG, échéance et renouvellement, fin anticipée, écritures directes interdites ; interactions professionnelles limitées au lien de soin. |
| `c213_account_status.sql` | État du compte (C213, décision D64) : `my_account_status` pour un patient, un rôle refusé par GSG (motif rendu 30 jours), grossiste et livreur en attente puis validés, professionnels (fiche absente, en attente, refusée, vérifiée), pharmaciens (sans officine, candidature en attente ou refusée, officine active puis suspendue), invitations ; concordance avec `has_verified_role` ; `anon` refusé. |
| `c220_aggregates_and_open_policies.sql` | Données agrégées et règles ouvertes à tous (C220, décision D65) : vues d'analyse fermées à `anon`, statistiques des professionnels (note publique, patients et consultations réservés), arrêts, tournées et livreurs visibles des seules parties de la livraison, administrateurs et paramètres GSG, alertes familiales non déplaçables, bilans de solidarité et classement réservés aux utilisateurs connectés. |
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
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c201_pos_sale_from_stock.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c216_c217_care_scoped_access.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c218_c210_price_and_suspended_pharmacy.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c205_cash_linked_to_sales.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c219_emergency_access.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c213_account_status.sql
docker exec -i supabase_db_pharma_connect psql -U postgres -d postgres < supabase/sql_tests/c220_aggregates_and_open_policies.sql
bash supabase/sql_tests/concurrency_numbering.sh
```

Les fichiers `.sql` s'exécutent dans une seule transaction terminée par `rollback` : ils ne laissent aucune donnée. Le script de concurrence doit committer ses données (deux sessions) ; il se termine par `supabase db reset --local`, qui efface toute la base locale.

Les identifiants du seed (lots, stock) sont générés aléatoirement à chaque `db reset` : les tests retrouvent les lots par `batch_number` et officine, jamais par identifiant.
