# C211 — Inventaire des droits fondés sur `profiles.role`

État réel lu le 29/09/2026 sur base locale neuve (`supabase db reset --local`, toutes migrations jusqu'à `20260930000000_pos_refund_policy.sql`), par les requêtes des consignes C211 :

- policies dont `qual` ou `with_check` mentionne `profiles` et `role` : 21 ;
- fonctions `public` dont le corps lit `profiles` et `role` : 6 ;
- complément : policies qui appellent `is_pharmacist()`, `is_regulator()` ou `is_any_pharmacy_staff()` (leur texte ne contient pas `profiles`, la première requête ne les voit pas) : 10.

Aucune policy ne lit le rôle depuis le JWT (`auth.jwt()`, `user_metadata`, `app_metadata`). Les 7 policies du schéma `storage` ne lisent pas `profiles.role`.

Catégories :

- **(a)** droit ouvert sur un rôle déclaré, non vérifié : corrigé par `20260930020000_role_policies_require_verification.sql` (condition de rôle remplacée par `public.has_verified_role(...)`, reste de la condition inchangé) ;
- **(b)** condition sur une valeur absente de la contrainte `check` de `profiles.role` : toujours fausse, sans risque, non modifiée ;
- **(c)** sans risque, ou sécurisé par le verrouillage des colonnes de `20260930010000_verified_roles_and_locked_columns.sql` : non modifié.

## Policies

| Objet | Table | Commande | Condition de rôle actuelle | Cat. | Action |
|---|---|---|---|---|---|
| `batch_movements_select_staff` | `batch_movements` | SELECT | `is_gsg_admin() OR role IN (pharmacien, grossiste, regulateur)` | a | `has_verified_role(['pharmacien','grossiste','regulateur'])` |
| `batch_movements_write_staff` | `batch_movements` | ALL | idem (using et with check) | a | idem |
| `certificates_select_staff` | `certificates` | SELECT | idem | a | idem |
| `cold_chain_records_select_staff` | `cold_chain_records` | SELECT | idem | a | idem |
| `traceable_batches_write_staff` | `traceable_batches` | ALL | idem | a | idem |
| `recalls_write_staff` | `recalls` | ALL | idem | a | idem |
| `recall_affected_batches_write_staff` | `recall_affected_batches` | ALL | idem | a | idem |
| `verification_scans_select_own_or_staff` | `verification_scans` | SELECT | `auth.uid() = verified_by OR is_gsg_admin() OR role IN (pharmacien, grossiste, regulateur)` | a | idem |
| `Staff view health goals` | `health_goals` | SELECT | `is_gsg_admin() OR role = professionnel` | a | `has_verified_role(['professionnel'])` |
| `Staff view milestones` | `health_milestones` | SELECT | idem | a | idem |
| `Staff generate summaries` | `health_record_summaries` | INSERT | `role = professionnel OR admin_users actif` | a | idem |
| `Staff view summaries` | `health_record_summaries` | SELECT | idem | a | idem |
| `Professionals can view all records` | `health_records` | SELECT | `role IN (pharmacien, professionnel)` | a | `has_verified_role(['pharmacien','professionnel'])` |
| `Staff manage triage AI analyses` | `triage_ai_analyses` | ALL | `is_gsg_admin() OR role = professionnel` | a | `has_verified_role(['professionnel'])` |
| `Nurses can manage assessments` | `triage_assessments` | ALL | `role = professionnel` | a | idem |
| `Nurses can view all triage patients` | `triage_patients` | SELECT | idem | a | idem |
| `Nurses can insert triage patients` | `triage_patients` | INSERT | idem | a | idem |
| `Nurses can update triage patients` | `triage_patients` | UPDATE | idem | a | idem |
| `Nurses can delete triage patients` | `triage_patients` | DELETE | idem | a | idem |
| `products_select_scoped` | `products` | SELECT | stupéfiants et psychotropes visibles si `is_gsg_admin() OR role <> patient` | a | `has_verified_role(['pharmacien','grossiste','livreur','professionnel','regulateur'])` (mêmes rôles que `<> patient`, vérifiés) |
| `Staff view notifications` | `notifications_history` | SELECT | `role IN (admin, staff)` | b | aucune (valeurs hors contrainte, condition toujours fausse) |
| `prescriptions_staff_select`, `prescriptions_staff_update` | `prescriptions` | SELECT, UPDATE | `is_pharmacist()` | a | via la fonction `is_pharmacist()` (ci-dessous) |
| `prescription_items_staff_select`, `prescription_items_staff_update` | `prescription_items` | SELECT, UPDATE | `is_pharmacist()` | a | idem |
| `GSG admin or regulator manage recalls` | `product_recalls` | ALL | `is_gsg_admin() OR is_regulator()` | a | via la fonction `is_regulator()` |
| `GSG admin or regulator manage inspections` | `regulatory_inspections` | ALL | idem | a | idem |
| `GSG admin or regulator manage authorizations` | `marketing_authorizations` | ALL | idem | a | idem |
| `forecast_*_pharmacy_view_global` (3) | `forecast_alerts`, `forecast_historical_data`, `forecast_predictions` | SELECT | `pharmacy_id IS NULL AND is_any_pharmacy_staff()` | c | aucune (fonction sécurisée par le verrou de `pharmacy_id`) |

## Fonctions

| Fonction | Condition actuelle | Cat. | Action |
|---|---|---|---|
| `is_pharmacist()` | `role = 'pharmacien'` | a | recréée : `has_verified_role(['pharmacien'])` (pharmacien rattaché à une officine) |
| `is_regulator()` | `role = 'regulateur'` | a | recréée : `has_verified_role(['regulateur'])` (régulateur validé par GSG) |
| `is_pharmacy_staff(uuid)` | `role = 'pharmacien' AND pharmacy_id = cible` | c | aucune : `pharmacy_id` n'est plus modifiable par l'utilisateur (posé par C208 ou GSG) |
| `is_any_pharmacy_staff()` | `role = 'pharmacien' AND pharmacy_id IS NOT NULL` | c | aucune : même raison |
| `is_verified_professional_account(uuid)` | `role = 'professionnel' AND professional_profiles.is_verified` | c | aucune : `is_verified` n'est plus modifiable par le professionnel (C212) ; `role` n'est plus modifiable par l'utilisateur |
| `log_network_activity()` | lit `role` pour journaliser | c | aucune (journal, n'ouvre aucun droit) |

`is_verified_professional(uuid)` (lit `professional_profiles.is_verified`, pas `role`) relève du même verrou C212.

## Décompte

- (a) : 20 policies directes + 2 fonctions (`is_pharmacist`, `is_regulator`, qui ouvrent 7 policies) ;
- (b) : 1 policy ;
- (c) : 3 policies (`forecast_*`) + 4 fonctions.

## Observations, non corrigées (hors vérification du rôle)

- `health_records` « Professionals can view all records » et `prescriptions_staff_select` / `prescription_items_staff_*` (`is_pharmacist()`) ouvrent **tous** les dossiers de santé et **toutes** les ordonnances à tout pharmacien ou professionnel, sans lien avec le patient ni l'officine. Portée trop large, à revoir séparément.
- `triage_*` : tout professionnel vérifié voit, modifie et supprime tous les patients de triage.
- `products_select_scoped` ouvre les stupéfiants et psychotropes aux livreurs vérifiés (même ensemble de rôles qu'avant, `<> patient`).
