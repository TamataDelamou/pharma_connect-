# PharmaConnect — PV de recette, Module 19 (INF — Réseau de professionnels mobiles)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module19_Protocole_Test_E2E.md`), en priorité absolue le Scénario 1 (déploiement complet des migrations sur une base neuve — ce scénario conditionne la validité de tous les modules précédents, pas seulement celui-ci), sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 19 à l'issue de son inspection et de ses correctifs, et de l'arbitrage de périmètre (D32), et servir de base à la décision de recette par le porteur du projet.

## 2. Périmètre couvert

Correction d'une collision de migration bloquant potentiellement le déploiement de tout le projet sur une base neuve (`professional_reviews` créée deux fois), correction d'une nouvelle occurrence du motif « rôle inatteignable » dans la migration d'origine du module audité lui-même, resserrement d'une policy RLS exposant des données personnelles sensibles à tout compte authentifié, et application au niveau RLS de RG-INF-01 (Critique) — jusque-là appliqué uniquement côté UI. Hors périmètre, par arbitrage explicite du porteur du projet (D32) : les 4 écrans cahier d'INF (Inscription et vérification, Application Health Professional, Gestion de zone de couverture et disponibilités, Évaluations reçues) et la taxonomie RG-INF-02 (périmètre d'actes par profil professionnel) ne sont pas construits ce module — reportés vers une future itération dédiée.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 6 tables (1 migration d'origine), 1 seconde migration découverte en cours d'inspection, recherche exhaustive de nom de fichier confirmant l'absence de tout écran/provider/service dédié |
| Analyse comparative au cahier de conception | ✅ Oui | RG-INF-01/02, 4 fonctionnalités clés/écrans principaux — écart de périmètre majeur identifié et arbitré (D32) |
| Recherche exhaustive de collision de migration (`create table`) | ✅ Oui | `grep` de toutes les déclarations `create table public.<nom>` sur l'ensemble de `supabase/migrations/` pour les 6 tables du module et les tables liées (`consultations`) — 1 collision trouvée (C78), aucune autre |
| Vérification syntaxique statique (équilibrage accolades/parenthèses, SQL) | ✅ Oui | Script dédié `.sql` (`/tmp/balance_check.py`) exécuté sur les 2 fichiers modifiés/créés |
| Vérification d'ordre chronologique des migrations | ✅ Oui | Confirmé que `is_gsg_admin()` (définie par une migration du 29/08) n'est PAS appelée depuis un fichier daté du 28/08 (`20260828020000_professional_reviews.sql`) — test direct sur `admin_users` utilisé à la place, pour respecter l'ordre d'application réel des migrations |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Parcours d'inscription `role='professionnel'`, flux de réservation HOM/CNS, policies RLS des 6+2 tables concernées, retracés intégralement |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ⚪ Non applicable | Aucun fichier Dart modifié ce module |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) — **c'est précisément cette limite qui a permis à C78 de rester indétectée pendant 18 modules** |
| Test end-to-end sur appareil/émulateur réel | ⚪ Non applicable | Aucun écran Dart créé/modifié ce module |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, avec une portée inhabituelle pour ce module précis : la découverte de C78 démontre que cette méthode, bien qu'ayant permis de trouver et corriger la collision elle-même, ne peut PAS garantir avec certitude qu'aucune collision analogue ne subsiste ailleurs dans les ~90 fichiers de migration du projet. Le Scénario 1 du protocole E2E (déploiement complet sur base neuve) doit donc être traité comme un préalable bloquant, pas seulement pour ce module mais pour la validité de toutes les recettes précédentes de ce projet.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Collision de migration `professional_reviews` (création dupliquée) | Rapport d'audit §3.1 (C78) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1, priorité absolue et préalable |
| Collision secondaire (2 index + 1 trigger dupliqués) | Rapport d'audit §3.1 (C78) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1 |
| RLS « rôle inatteignable » (`professional_profiles` + `professional_reviews`) | Rapport d'audit §3.2 (C79) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 2 |
| Exposition PII (`license_number`, contact d'urgence, etc.) | Rapport d'audit §3.3 (C80) | 🟢 Partiellement corrigé (profils non vérifiés) — résidu assumé sur profils vérifiés (D32) — à confirmer par le Scénario 3 |
| RG-INF-01 non appliqué au niveau RLS | Rapport d'audit §3.4 (C81) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 4 |
| Écran Inscription et vérification du professionnel | Rapport d'audit §2.2 | 🔴 Non implémenté — hors périmètre arbitré (D32) |
| Taxonomie d'actes autorisés par profil (RG-INF-02) | Rapport d'audit §2.2 | 🔴 Non implémenté — hors périmètre arbitré (D32) |
| Gestion de zone de couverture, disponibilités, tarifs | Rapport d'audit §2.2 | 🔴 Non implémenté (zone de couverture) / 🟡 Partiel (disponibilités en base, non consommées ; tarifs en lecture seule) — hors périmètre arbitré (D32) |
| Application Health Professional (file de demandes) | Rapport d'audit §2.2 | 🔴 Non implémenté en tant que tel — hors périmètre arbitré (D32) |
| Évaluations reçues, avec modération | Rapport d'audit §2.2 | 🔴 Écran non implémenté ; fondation de données désormais cohérente (C78) mais non consommée — hors périmètre arbitré (D32) |

## 5. Réserves formelles

1. ~~Aucun des scénarios du protocole de test E2E n'a été exécuté~~ **Partiellement levée au 1er refus de clôture (30/08/2026, voir addendum §5 bis)** : le cœur du Scénario 1 (C78 ne laisse aucun objet orphelin) est désormais confirmé par exécution réelle contre Postgres 16, sur un schéma ciblé réel. Le Scénario 1 dans son intégralité (chaîne complète des ~85 fichiers de bout en bout) reste NON complété — la tentative s'est arrêtée après correctif du 6e blocage rencontré (C87), tous hors périmètre du Module 19 (voir C82-C87). Cette réserve dépasse donc toujours le seul Module 19 : tant que la chaîne complète n'aura pas été rejouée jusqu'à son terme, aucune des « clôtures » de modules précédentes (1 à 18) ne peut être considérée comme totalement vérifiée à l'exécution — deux d'entre elles (Modules 16 et 11) sont même désormais confirmées comme comportant une régression bloquante réelle (C86, C87).
2. **Écart de périmètre majeur non résolu (D32)** — les 4 écrans cahier et la taxonomie RG-INF-02 restent entièrement absents. Reste en 🟡 au registre — report assumé, pas une clôture du périmètre cahier complet.
3. **RG-INF-01 appliqué au niveau RLS mais pratiquement inatteignable** — aucun parcours d'inscription/vérification réel n'existe pour qu'un professionnel devienne un jour `is_verified = true` en pratique ; le correctif ferme une porte technique sans ouvrir le chemin normal.
4. **Exposition PII résiduelle sur les profils vérifiés** (C80) — `license_number` et les autres colonnes sensibles restent lisibles par API directe par tout compte authentifié pour un professionnel déjà vérifié ; seule une vue dédiée ou un GRANT/REVOKE colonne fermerait complètement ce résidu.
5. ~~Aucune migration n'a été exécutée sur un environnement réel~~ **Levée au 1er refus de clôture (30/08/2026, voir addendum §5 bis)** : le correctif C78 a été exécuté réellement contre un Postgres 16 local et vérifié par introspection système (`pg_constraint`/`pg_indexes`/`pg_trigger`/`pg_policies`) et par test fonctionnel (insertions/suppressions réelles). C'est la première fois dans les 19 modules de cet audit qu'une migration corrective est validée par exécution réelle plutôt que par seule relecture de code.

## 5 bis. Addendum — réponse au 1er refus de clôture (30/08/2026)

### Point 1 — Résolution de la collision de migration : préservation des clés étrangères et contraintes, absence d'objets orphelins

Le porteur du projet a demandé une confirmation concrète, pas seulement un raisonnement statique, que la conversion de `20260828020000_professional_reviews.sql` en `alter table`/`if not exists` préserve l'intégralité des clés étrangères et contraintes d'origine sans laisser d'objets orphelins. Cette session a construit, pour la première fois de tout l'audit (19 modules), un environnement Postgres 16 local réel (le sandbox dispose de `postgresql-16`/`postgresql-client-16` préinstallés, non identifié lors des audits précédents) et y a rejoué, avec les fichiers RÉELS et non modifiés du projet (`20260827000200_profiles.sql`, `20260827000500_admin.sql`, `20260827003500_teleconsult.sql`, `20260827005500_professionals.sql`), la chaîne minimale nécessaire pour faire exister `public.professional_reviews` dans son état d'origine, puis a appliqué le fichier correctif corrigé.

**État avant correctif (introspection réelle, `pg_constraint`) :**

| Objet | Détail |
|---|---|
| Contrainte unique | `professional_reviews_professional_id_patient_id_key` — UNIQUE (professional_id, patient_id) |
| FK | `professional_reviews_patient_id_fkey` → profiles(id) ON DELETE CASCADE |
| FK | `professional_reviews_professional_id_fkey` → profiles(id) ON DELETE CASCADE |
| CHECK | `professional_reviews_rating_check` — (rating >= 1 AND rating <= 5) |
| Index | `idx_professional_reviews_professional_id`, `idx_professional_reviews_rating` |
| Trigger | `trigger_professional_reviews_updated_at` |
| Policies | « Everyone can view reviews », « Patients can create reviews », « Patients can update own reviews » |

**État après correctif (introspection réelle, même méthode) :**

| Objet | Détail |
|---|---|
| Contrainte unique | `professional_reviews_professional_patient_consultation_key` — UNIQUE (professional_id, patient_id, consultation_id) — **l'ancienne contrainte à 2 colonnes est bien ABSENTE, confirmé, aucun doublon** |
| FK (x2, inchangées) | `professional_reviews_patient_id_fkey`, `professional_reviews_professional_id_fkey` — toujours présentes, définitions identiques |
| FK (nouvelle) | `professional_reviews_consultation_id_fkey` → consultations(id) ON DELETE SET NULL — présente |
| CHECK (inchangé) | `professional_reviews_rating_check` — toujours présent, définition identique |
| CHECK (nouveau) | `professional_reviews_status_check` — présent |
| Index | `idx_professional_reviews_professional_id`, `idx_professional_reviews_rating` (inchangés, **aucun doublon**), + `idx_professional_reviews_status` (nouveau) |
| Trigger | `trigger_professional_reviews_updated_at` — **un seul exemplaire, aucun doublon** |
| Policies | « Everyone view approved reviews », « Patients create reviews », « Patients update own reviews », « Patients delete own reviews », « Staff moderate reviews » — les 3 anciennes policies sont bien ABSENTES, confirmé |

**Test fonctionnel complémentaire** (pas seulement structurel — le comportement réel des contraintes a été exercé) :

1. Insertion d'un avis (professionnel P, patient U, consultation A) → **acceptée**.
2. Insertion d'un second avis (même P, même U, consultation B différente) → **acceptée** — c'est précisément l'objectif de l'élargissement de la contrainte, confirmé fonctionnel et pas seulement déclaré.
3. Insertion d'un vrai doublon (même P, même U, même consultation A) → **rejetée** par `professional_reviews_professional_patient_consultation_key` (`duplicate key value violates unique constraint`).
4. Suppression de la consultation A → l'avis correspondant **survit**, `consultation_id` passe à `null` (`ON DELETE SET NULL` fonctionne, aucun enregistrement orphelin de FK).
5. Suppression du profil patient U → **les deux avis sont supprimés en cascade** (`ON DELETE CASCADE` fonctionne, aucune ligne orpheline laissée en base).

**Conclusion du Point 1 :** confirmé par exécution réelle et non plus seulement par relecture — l'ensemble des clés étrangères et contraintes d'origine sont préservées, aucun objet orphelin (ni contrainte, ni index, ni trigger, ni ligne) n'est laissé par le correctif.

**Défaut supplémentaire trouvé et corrigé par cette même exécution :** le bloc `do $$ ... $$` de recherche dynamique de contrainte (introduit pour répondre au 1er refus de clôture initial) échouait lui-même à l'exécution réelle — `array_agg(attname order by attname)` produit un tableau de type `name[]` (type système Postgres des noms de colonnes), qui ne dispose d'aucun opérateur d'égalité avec `text[]`, provoquant `ERROR: operator does not exist: name[] = text[]`. Corrigé par un cast explicite (`a.attname::text`) avant agrégation ; la ré-exécution complète ci-dessus a été effectuée APRÈS ce second correctif et confirme son bon fonctionnement. C'est un exemple concret de la valeur de l'exécution réelle par rapport à la seule relecture de code : ce défaut n'aurait jamais été trouvé sans elle, y compris par un relecteur humain attentif.

### Point 2 — Consignation officielle du périmètre UI différé (D32)

Actée formellement au registre (voir la ligne D32, section « Scellé au 1er refus de clôture ») : l'usage actuel d'INF se limite strictement à sa couche BDD (6 tables), consommée en lecture par HOM et CNS pour leurs seuls besoins de sélection d'un professionnel vérifié. Aucun écran, provider ou service applicatif propre à INF n'existe — confirmé par recherche exhaustive (aucun dossier `lib/modules/professionals` ou équivalent). Aucun professionnel ne peut aujourd'hui gérer son propre profil, ses disponibilités, sa zone de couverture ou consulter ses avis reçus.

### Constat additionnel — six défauts hors périmètre découverts par ricochet lors de l'exécution réelle

En construisant l'environnement Postgres pour répondre au Point 1, cette session a rejoué la chaîne complète des ~85 fichiers de migration (pas seulement le sous-ensemble minimal du Module 19) pour tenter d'objectiver le Scénario 1 du protocole E2E dans son intégralité. Cette tentative a été bloquée successivement par **six défauts supplémentaires**, tous confirmés bloquants par exécution réelle (pas par simple lecture), tous **hors du périmètre du Module 19** — consignés au registre sous C82 à C87 :

- **C82** (le plus grave) : `public.update_updated_at()` référencée dans 18 fichiers de migration mais jamais définie — bloque, entre autres, `20260827005500_professionals.sql`, **la migration d'origine du Module 19 lui-même**.
- **C83** : `public.invoices` créée deux fois (Module 8/PAY + module hors-cahier `sales`) — même classe de bug que C78, non encore confirmée par exécution réelle (scan statique).
- **C84** : `20260827007500_analytics.sql` (module Analytics/BI, jamais audité) — 6 références à des colonnes inexistantes sur 2 vues matérialisées.
- **C85** : `20260827008000_support.sql` — erreur de syntaxe SQL bloquante (échappement `\'` non standard) dans un seed de données.
- **C86** : **régression dans le Module 16 (FID), déjà clôturé** — `20260827008500_loyalty.sql` référence 8 fois une table `pharmacy_staff` inexistante, échappée au correctif global qui avait traité ce même motif partout ailleurs dès le Module 0.
- **C87** : **régression dans le Module 11 (IA), déjà clôturé** — `20260828012000_triage_ai.sql` utilise `on conflict (keyword)` sans contrainte unique correspondante sur `keyword`.

Ces six défauts avaient d'abord été neutralisés UNIQUEMENT dans une copie de travail locale (« TEST HARNESS ONLY ») pour permettre à la chaîne de test d'avancer jusqu'à `professional_reviews.sql`, sans être corrigés dans le projet réel.

### Constat final — décision du porteur du projet et succès complet de `supabase db push`

Sur décision explicite du porteur du projet (« ces bugs DDL bloquent l'exécution séquentielle de `supabase db push`... il est préférable de corriger immédiatement ce socle d'infrastructure BDD »), les tickets C82 à C87 ont été corrigés dans le projet réel (fichiers réels livrés à l'appareil, plus les mêmes correctifs appliqués à la copie de test locale). La reprise de l'exécution réelle de la chaîne complète a alors révélé **7 défauts bloquants supplémentaires**, du même ordre, dans 5 fichiers jamais audités jusqu'ici (`support_ai.sql`, `offline_sync.sql`, `chains.sql`, `iot.sql`, `stock_forecasting.sql` — consignés au registre sous C89 à C93), tous corrigés dans le même mouvement dès leur découverte.

**Résultat** : après correction de 12 défauts bloquants distincts dans 15 fichiers réels, la chaîne complète des ~85 migrations du projet s'applique désormais **sans aucune erreur, de bout en bout, sur une base Postgres 16 strictement neuve** — vérifié deux fois (avant et après le second lot de correctifs). C'est la première fois de toute la durée de cet audit (19 modules) que ce résultat est atteint, et il résout substantiellement l'item A1 du registre (« `supabase db push` jamais exécuté »), documenté depuis le Module 0.

3 anomalies non bloquantes supplémentaires ont été repérées au passage et volontairement laissées non corrigées, hors périmètre de ce correctif ciblé sur les blocages de `supabase db push` (consignées au registre sous C88) : une comparaison de chaîne toujours fausse dans `analytics.sql` (`'picked_up'` vs `'pickedUp'`), l'absence d'index unique nécessaire au rafraîchissement concurrent des vues du même fichier, une policy RLS rendue inopérante par une policy plus ancienne dans `chains.sql`, et une comparaison `auth.uid() = pharmacy_id` sémantiquement incorrecte dans `iot.sql`.

**Limite de la vérification** : ce sandbox local n'ayant pas d'accès réseau pour installer l'extension `pgvector` (403 sur le dépôt Ubuntu), la colonne `embeddings vector(384)` de `support_ai.sql` a été vérifiée avec un stub de test (`double precision[]`) plutôt qu'avec le vrai type — le fichier livré au projet réel contient bien `create extension if not exists vector` et le vrai type `vector(384)`, mais cette portion précise n'a pas pu être vérifiée par exécution réelle dans cette session.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : périmètre UI différé (D32, chantier de conception distinct à cadrer) ; exposition PII résiduelle sur les profils vérifiés (C80, réserve assumée) ; les 3 anomalies non bloquantes de C88 (dette technique classique, sans échéance imposée) ; la vérification non exhaustive du type `vector` réel (limite d'environnement de test, pas du correctif livré).
☐ **Recette prononcée sans réserve**
☐ **Recette refusée / reportée**

*Recette prononcée par le porteur du projet (30/08/2026), à l'issue du traitement du 1er refus de clôture et de la correction des tickets C82-C93.*

---

**Le module Réseau de professionnels mobiles (INF) est validé et clos.** Conformément à la méthodologie du projet, l'audit passe désormais au module suivant.
