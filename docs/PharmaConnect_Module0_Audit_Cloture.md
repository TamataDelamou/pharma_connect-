# Module 0 — Fondations transverses : rapport de clôture

**Date de l'audit :** 29/08/2026
**Périmètre :** conventions Kernel partagées, helpers d'autorisation RLS, cohérence de la chaîne de migrations Supabase — le socle sur lequel s'appuient tous les modules métier du cahier de conception.
**Contexte :** développement concurrent reconnu par le porteur du projet le 28/08 ("je reconnais l'existence de ces modules supplémentaires... laisse tourner") — les modules `cash`, `pos`, `sales`, `returns` ont été ajoutés en parallèle de cet audit. Ce rapport documente précisément le point de friction entre cet audit transverse et ce développement concurrent : plusieurs fichiers de migration produits le 29/08 pour ces modules contenaient des défauts qui auraient bloqué `supabase db push` pour l'ensemble du projet, migrations ultérieures comprises.

---

## 1. Inspection & rapport de situation

22 fichiers de migration ont été inspectés (27-29/08/2026), avec relecture ligne à ligne des 13 fichiers touchés par les modules `pos`, `network_admin`, `sales`, `cash`, `returns`, `business`, `stock_forecasting`, `offline_sync`, `offline_sales`.

Trois catégories de défauts systémiques ont été identifiées, chacune traversant plusieurs fichiers écrits indépendamment le même jour — signe d'une génération non coordonnée plutôt que d'erreurs isolées :

**a) Collisions de timestamp / tables dupliquées.** Deux paires de fichiers portaient le même préfixe horodaté et créaient les mêmes tables :
- `20260829006000_pos_and_network_admin.sql` vs `20260829006000_pos.sql` — les deux créaient `pos_sales`, `pos_sale_items`, `pos_receipts` ; le premier créait en plus `network_admin_roles`/`network_dashboard`, redéfinis en détail par `network_admin.sql`.
- `20260829008000_sales.sql` vs `20260829008000_sales_management.sql` — le premier créait un sous-ensemble strict des tables du second.

De plus, `sales_management.sql` dupliquait à lui seul `customer_returns`, `customer_return_items`, `cash_drawer_sessions`, `cash_movements`, déjà définies intégralement par `returns.sql` et `cash.sql`.

Un `supabase db push` aurait échoué avec `relation already exists` dès le second fichier de chaque paire appliqué (l'ordre lexicographique traite `_pos.sql` avant `_pos_and_network_admin.sql`, et `_sales.sql` avant `_sales_management.sql`), interrompant la totalité du push à ce point — y compris les migrations légitimes venant après.

**b) Table fantôme `public.pharmacy_staff`.** Sept fichiers référençaient cette table dans des policies RLS (`pos.sql` ×5, `sales_management.sql` ×8, `cash.sql` ×2, `returns.sql` ×2, `offline_sales.sql` ×2, `sales_ai.sql` ×3, plus le fichier `pos_and_network_admin.sql` neutralisé). Cette table n'a jamais été créée dans aucune migration : le modèle de rattachement personnel/officine du projet repose depuis le 27/08 sur `public.profiles.pharmacy_id` et le helper `public.is_pharmacy_staff(pharmacy_id uuid)` (`20260827002000_staff_write_policies.sql`). Toute policy y faisant référence aurait fait échouer sa création avec `relation "pharmacy_staff" does not exist`.

**c) Valeurs de rôle invalides `role in ('admin', 'staff')` sur `profiles`.** Six fichiers testaient `public.profiles.role in ('admin', 'staff')` pour des policies de type back-office (`business.sql` ×6, `stock_forecasting.sql` ×3, `returns.sql` ×2, `offline_sync.sql` ×1, plus `network_admin.sql` avec `role = 'admin'`). La contrainte CHECK de `profiles.role` (`20260827000200_profiles.sql`) n'autorise que `patient, pharmacien, grossiste, livreur, professionnel, regulateur` — ni `admin` ni `staff` ne peuvent jamais y figurer. Ces policies ne provoquaient pas d'erreur SQL (la comparaison est syntaxiquement valide) mais étaient **inatteignables par construction** : personne n'aurait jamais pu satisfaire leur condition, y compris le personnel back-office légitime. Le modèle correct existe déjà depuis le 27/08 : la table séparée `public.admin_users`.

En complément, trois défauts ponctuels : une policy tautologique `pharmacy_id = pharmacy_id` (`pos_and_network_admin.sql`, capture de nom rendant le test toujours vrai) ; une comparaison `auth.uid() = pharmacy_id` (×3, `stock_forecasting.sql`) comparant un identifiant utilisateur à un identifiant d'officine ; un opérateur ternaire `cond ? a : b` (`returns.sql`), syntaxe invalide en PL/pgSQL.

## 2. Analyse comparative avec le cahier de conception et le Kernel

Points conformes, vérifiés dans les fichiers inspectés : KER-VIS-01/KER-ORG-02 (`gsg_id`/`gsg_org_id` systématiquement en colonnes scalaires nullables, jamais en clé étrangère) ; KER-VIS-03 (aucune FK cross-schema observée) ; KER-REF-05 (tous les montants — `total_amount`, `unit_price`, `opening_balance`, etc. — en `integer`, unité mineure).

Écart à corriger dans le rapport Étape 1 déjà livré : la table du plan modulaire y faisait correspondre le dossier `business` au module cahier **BIZ — Tableau de bord Officine**. La lecture complète de `20260829004000_business.sql` montre qu'il s'agit en réalité d'un **CRM B2B/institutionnel** (`business_companies`, `business_kyc`, `business_contracts`, `business_contacts`, `business_activities`, `business_pricing` — hôpitaux, cliniques, grossistes, assurances). Cela ne correspond à aucun module numéroté du cahier v2 ; `business` reste donc, comme déjà signalé par REFERENTIEL_ARCHITECTE.md §4.3, "à clarifier avant de démarrer". Le document Étape 1 sauvegardé sur le Projet sera corrigé en conséquence.

Dette technique confirmée : les trois catégories de défauts ci-dessus touchent exclusivement des fichiers datés du 29/08, c'est-à-dire produits pendant la fenêtre de développement concurrent reconnue par le porteur du projet. Cela matérialise concrètement le risque déjà documenté dans `PharmaConnect_CLAUDE.md`/`REFERENTIEL_ARCHITECTE.md` (incident du 25/08 : modules codés sans suivre la checklist Kernel) : un rythme de génération de code supérieur au rythme de revue croisée produit des incohérences entre fichiers écrits en parallèle, même quand chacun pris isolément est raisonnable.

## 3. Sécurité & résilience — corrections appliquées

| Fichier | Défaut | Risque avant correction | Correction appliquée |
|---|---|---|---|
| `20260829006000_pos_and_network_admin.sql` | Doublon intégral de tables + policy tautologique + `role = 'admin'` invalide | Push bloqué ; policy toujours vraie | Neutralisé (stub documenté, contenu utile déjà repris ailleurs) |
| `20260829008000_sales.sql` | Sous-ensemble dupliqué de `sales_management.sql` | Push bloqué | Neutralisé (stub documenté) |
| `20260829006000_pos.sql` | `pharmacy_staff` (×5) inexistante | Policies non créées (push bloqué) | Remplacé par `is_pharmacy_staff(pharmacy_id)` |
| `20260829007000_network_admin.sql` | `profiles.role = 'admin'` inatteignable | Bootstrap du back-office réseau impossible | Remplacé par `is_gsg_admin()` ; policy "Network admins view all POS" (perdue lors de la neutralisation du fichier doublon) réintroduite ici |
| `20260829008000_sales_management.sql` | `pharmacy_staff` (×8) ; tables dupliquées avec `cash.sql`/`returns.sql` | Push bloqué | `is_pharmacy_staff()` ; tables/policies dupliquées retirées |
| `20260829009000_cash.sql` | `pharmacy_staff` (×2) | Policies non créées | Remplacé par `is_pharmacy_staff()` |
| `20260829010000_returns.sql` | `pharmacy_staff` (×2) ; `role in ('admin','staff')` (×2) ; ternaire invalide | Push bloqué (erreur de syntaxe PL/pgSQL sur le trigger) | `is_pharmacy_staff()` ; `is_gsg_admin()` ; `CASE WHEN` |
| `20260829004000_business.sql` | `role in ('admin','staff')` (×6) | Back-office jamais autorisé à gérer le CRM B2B | Remplacé par `is_gsg_admin()` |
| `20260829005000_stock_forecasting.sql` | `role in ('admin','staff')` (×3) ; `auth.uid() = pharmacy_id` (×3) | Back-office bloqué ; officines ne voyant jamais leurs propres prévisions | `is_gsg_admin()` ; `is_pharmacy_staff(pharmacy_id)` |
| `20260828017000_offline_sync.sql` | `role in ('admin','staff')` (×1) | Personnel back-office ne pouvant jamais gérer les plans hors-ligne HOM | Remplacé par `is_gsg_admin()` |
| `20260829012000_offline_sales.sql` | `pharmacy_staff` (×2) | Policies non créées | Remplacé par `is_pharmacy_staff()` |
| `20260829011000_sales_ai.sql` | `pharmacy_staff` (×3) | Policies non créées | Remplacé par `is_pharmacy_staff()` |
| `20260829003800_admin_helpers.sql` *(nouveau)* | — | — | Introduit `public.is_gsg_admin()`, SECURITY DEFINER, sur le modèle de `is_pharmacy_staff()` déjà en place |

Aucun fichier n'a été supprimé physiquement (aucun outil de suppression n'est disponible pour ce pont vers ta machine) ; les deux fichiers strictement redondants ont été neutralisés en place avec un en-tête expliquant pourquoi, pour qu'un futur lecteur — humain ou IA — ne perde pas cette traçabilité.

**Point non résolu, signalé sans correction automatique :** la vue matérialisée `network_dashboard` (`network_admin.sql`) référence `stock_items` et `alerts` sans préfixe de schéma explicite ni vérification de mon côté que ces deux tables existent sous ce nom exact ailleurs dans le projet. Si ce n'est pas le cas, la création de la vue échouera à son tour. Je recommande une vérification ciblée avant le prochain `db push` plutôt qu'une correction à l'aveugle sur une vue agrégée que je n'ai pas auditée dans son ensemble.

**Autre point signalé, non corrigé délibérément :** `offline_sync.sql` crée `sync_queue` et `homecare_offline_plans` sans préfixe `public.` explicite (contrairement au reste du projet). Fonctionnellement inoffensif tant que `search_path` inclut `public` en premier (comportement par défaut Supabase), mais c'est une incohérence de style sur une table qui, par ailleurs, soulève une question de conception plus large déjà notée dans le rapport Étape 1 : ce `sync_queue` côté serveur, à portée patient/CARE, coexiste avec le `offline_sync_service.dart` côté client qui gère sa propre file `sync_queue` locale (sqflite) — la relation entre les deux n'est pas documentée. Je n'ai pas touché à ce fichier au-delà de la correction `role in (...)`, cette question de conception dépassant le périmètre d'un correctif RLS.

## 4. Optimisation & améliorations

- **Garde CI supplémentaire.** Les scripts existants (`check_no_cross_schema_fk.sh`, `check_no_hardcoded_color.sh`) pourraient être complétés par un script grep simple détectant, avant tout push : (a) deux fichiers de migration partageant le même préfixe horodaté à 4 chiffres près, (b) toute référence à une table absente du schéma courant reconstruit localement. Cela aurait intercepté les trois défauts systémiques de ce module avant qu'ils n'atteignent la revue.
- **Généralisation du patron `is_gsg_admin()` / `is_pharmacy_staff()`.** Le gabarit de démarrage de module (`REFERENTIEL_ARCHITECTE.md` §4.2) devrait citer explicitement ces deux helpers comme seul point d'entrée autorisé pour les policies RLS "personnel officine" / "back-office GSG", pour qu'aucun futur module ne réinvente un test cassé.
- **Consolidation différée des fichiers neutralisés.** Les deux stubs (`pos_and_network_admin.sql`, `sales.sql`) pourront être supprimés proprement (au lieu de rester en `select 1;`) lors d'un futur nettoyage de l'historique de migrations, une fois qu'un outillage shell/`rm` sera disponible côté agent ou que le porteur du projet le fera lui-même.

## 5. Documentation API / conformité aux règles métier

**`public.is_gsg_admin() returns boolean`** — `STABLE`, `SECURITY DEFINER`, `search_path` fixé à `public`. Vrai si l'utilisateur courant (`auth.uid()`) correspond à une ligne active (`is_active = true`) de `public.admin_users`, quel que soit son rôle précis (`superAdmin`, `admin`, `pharmacyManager`, `regulator`, `auditor`, `support`, `viewer`). Remplace tout test `profiles.role in ('admin','staff')`.

**`public.is_pharmacy_staff(target_pharmacy_id uuid) returns boolean`** *(préexistant, réutilisé)* — vrai si l'utilisateur courant est un `profiles.role = 'pharmacien'` rattaché à `target_pharmacy_id`. Remplace tout test référençant `public.pharmacy_staff`.

Ces deux fonctions matérialisent la même séparation déjà en vigueur côté Dart entre `AuthProvider` (grand public, y compris pharmaciens d'officine) et `AdminProvider` (back-office GSG) — aucune règle métier RG-* nouvelle n'est introduite ; il s'agit strictement de faire fonctionner l'autorisation déjà prévue par le modèle de données existant.

## 6. Scénarios de test (unitaires / intégration)

1. **Migration à blanc.** `supabase db push` (ou `db reset`) sur une base de test vierge doit s'appliquer sans erreur `relation already exists`, sans `relation "pharmacy_staff" does not exist`, sans erreur de syntaxe sur `log_return_status_change()`. *(Non exécuté dans cette session — aucun accès shell/CLI Supabase côté pont machine ; à faire côté porteur du projet ou lors d'une prochaine session avec `device_bash`.)*
2. **`is_gsg_admin()`** : insérer une ligne `admin_users` active pour un `user_id` de test → attendre `true` ; désactiver (`is_active = false`) → attendre `false` ; utilisateur présent uniquement dans `profiles` (jamais dans `admin_users`) → attendre `false` même si un futur bug réintroduisait une valeur `role` non prévue par le CHECK.
3. **`is_pharmacy_staff(pharmacy_id)`** sur `pos_sales` : un `pharmacien` rattaché à l'officine A crée/lit/modifie une vente de l'officine A (autorisé) et échoue sur une vente de l'officine B (refusé) ; un `patient` échoue dans les deux cas.
4. **Trigger de traçabilité des retours** : une transition de statut sur `customer_returns` insère une ligne `return_tracking` avec `return_type = 'customer'` ; une transition sur `supplier_returns` insère `return_type = 'supplier'`.
5. **Bootstrap back-office réseau** : un membre `admin_users` actif peut créer la première ligne `network_admin_roles` (test de la policy corrigée) ; un `pharmacien` sans entrée `admin_users` ne le peut pas.
6. **Non-régression du module 0 sur les modules concurrents** : relire `cash.sql`/`returns.sql`/`pos.sql` après tout futur commit du développement concurrent, pour vérifier qu'aucune nouvelle référence à `pharmacy_staff` ou `role in ('admin','staff')` n'a été réintroduite.

## 7. Livrables de ce module

13 fichiers de migration modifiés dans `supabase/migrations/`, déjà commités dans ton dossier `PlatformGSG\pharma_connect` :
`20260829003800_admin_helpers.sql` (nouveau), `20260829006000_pos_and_network_admin.sql` et `20260829008000_sales.sql` (neutralisés), `20260829006000_pos.sql`, `20260829007000_network_admin.sql`, `20260829008000_sales_management.sql`, `20260829009000_cash.sql`, `20260829010000_returns.sql`, `20260829004000_business.sql`, `20260829005000_stock_forecasting.sql`, `20260828017000_offline_sync.sql`, `20260829012000_offline_sales.sql`, `20260829011000_sales_ai.sql`.

Correction à propager dans le rapport Étape 1 déjà sauvegardé sur le Projet : le mapping `business → BIZ` doit être retiré, `business` restant "à clarifier" comme déjà noté par REFERENTIEL_ARCHITECTE.md.

---

**Le module Fondations transverses (Module 0) est-il totalement clos et validé pour passer au suivant (Module 1 — AUT, Authentification) ?**
