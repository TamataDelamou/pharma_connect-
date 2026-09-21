# PharmaConnect — Audit Module 19 (INF — Réseau de professionnels mobiles : médecins, infirmiers, sages-femmes)

**Date :** 30/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Correspondance cahier confirmée par recherche ciblée (`project_search`) : code **INF**, priorité « Critique — Socle CARE ».

Recherche exhaustive de nom de fichier sur tout `lib/modules` (mots-clés `professional`, `verif`, `coverage`, `rating`, `evaluat`, `review`) : **aucun dossier, écran, provider ni service dédié à INF n'existe nulle part dans le projet**. Les seuls résultats pertinents appartiennent à d'autres modules (`license_verification_screen.dart` — Module 1/AUT, pharmacie uniquement ; `verification_screen.dart` — Module 12/TRC, contrefaçon).

Le seul code trouvé en rapport avec INF est la fondation de données : `supabase/migrations/20260827005500_professionals.sql`, 6 tables — `professional_profiles` (profil étendu, licence, spécialité, tarifs, `is_verified`/`verification_status`), `specialties` (référentiel), `qualifications` (référentiel), `professional_availability` (disponibilités hebdomadaires), `professional_patient_interactions` (journal d'interactions), `professional_reviews` (évaluations) — plus une seconde migration touchant `professional_reviews`, `20260828020000_professional_reviews.sql`, découverte en cours d'inspection (voir §1.2 et §3.1).

Usage réel de cette fondation dans le reste du projet : `grep` exhaustif de `professional_profiles`/`professional_availability`/`professional_reviews`/`specialties`/`qualifications`/`professional_patient_interactions` sur tout `lib/` — seule `professional_profiles` est référencée, et seulement par 5 fichiers appartenant à HOM et CNS/teleconsult (`homecare_service.dart`, `homecare_booking_screen.dart`, `teleconsult_service.dart`, `teleconsult_booking_screen.dart`, `consultation.dart`), pour leurs propres besoins de réservation (liste de professionnels vérifiés, corrigée aux Modules 15/18 — voir C62/C73). `specialties` n'apparaît que dans `pre_consultation_ai_service.dart` (sous-système Mock AI du Module 15, non routé — D26). Les 4 autres tables (`qualifications`, `professional_availability`, `professional_patient_interactions`, et `professional_reviews` au sens propre) ne sont référencées par **aucun fichier Dart du projet**.

Fichiers inspectés en intégralité : `20260827005500_professionals.sql`, `20260828020000_professional_reviews.sql`, `lib/modules/auth/screens/register_screen.dart`, `lib/modules/auth/screens/otp_verification_screen.dart`, `lib/modules/auth/screens/license_verification_screen.dart`, `lib/modules/auth/providers/auth_provider.dart`, `lib/modules/auth/services/profile_service.dart`, `lib/modules/homecare/services/homecare_service.dart`, `lib/modules/teleconsult/services/teleconsult_service.dart`, `20260827000200_profiles.sql`, `20260829003800_admin_helpers.sql`, `20260827004000_homecare.sql`, `20260827003500_teleconsult.sql`, plus une recherche exhaustive de collision de nom (`create table`) sur l'ensemble de `supabase/migrations/`.

### 1.2 Défauts constatés

1. **Découverte la plus sévère de tout l'audit à ce jour** : une collision de migration (`create table public.professional_reviews` sans `if not exists` sur une table déjà créée 3 timestamps plus tôt) qui aurait bloqué l'application de TOUTES les migrations suivantes sur une base neuve — restée indétectée pendant 18 modules faute d'avoir jamais pu exécuter `supabase db push`. Voir §3.1 (C78).
2. Motif « rôle inatteignable » (C49/C54/C63/C67/C70b), nouvelle occurrence — cette fois dans la migration d'origine du module en cours d'audit lui-même. Voir §3.2 (C79).
3. Exposition excessive de données personnelles sensibles (licence, contact d'urgence) via une policy RLS `using (true)`. Voir §3.3 (C80).
4. RG-INF-01 (Critique) totalement inappliqué au niveau RLS — enforcement uniquement côté UI. Voir §3.4 (C81).
5. **Écart de périmètre majeur** : les 4 écrans cahier d'INF et la taxonomie RG-INF-02 sont entièrement absents. Voir §2.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Périmètre cahier

Le cahier décrit INF ainsi : constituer et administrer le réseau de médecins, infirmiers, sages-femmes et autres professionnels autorisés à intervenir à domicile ou en téléconsultation sur PharmaConnect, avec vérification de leur inscription à l'ordre professionnel compétent.

Fonctionnalités clés attendues :

1. Vérification de l'inscription active à l'ordre professionnel concerné **avant toute activation de compte**.
2. Définition du périmètre d'actes autorisés par profil professionnel — un infirmier n'accédant pas aux mêmes demandes qu'un médecin.
3. Gestion des zones de couverture, des disponibilités et des tarifs par professionnel.
4. Application dédiée « PharmaConnect Health Professional » avec réception, acceptation et suivi des demandes.
5. Évaluation du professionnel par les patients, avec modération.

Écrans principaux attendus : Inscription et vérification du professionnel / Application Health Professional (file de demandes) / Gestion de zone de couverture et disponibilités / Évaluations reçues.

Règles de gestion : **RG-INF-01** (Critique) — un professionnel ne peut recevoir de demande de soin à domicile ou de téléconsultation qu'après vérification de son inscription active à l'ordre professionnel compétent. **RG-INF-02** (Critique) — un acte proposé à un patient doit relever strictement du périmètre légal de compétence du profil professionnel concerné.

### 2.2 Constat

| Fonctionnalité/écran (cahier) | Constat |
|---|---|
| Inscription et vérification du professionnel | 🔴 Absent — un compte `role='professionnel'` accède au tableau de bord immédiatement après inscription, sans jamais créer de ligne `professional_profiles`, sans jamais soumettre de licence. Le seul écran de vérification existant (`LicenseVerificationScreen`) est exclusivement réservé aux pharmacies (`role='pharmacien'`), écrit dans `public.pharmacies`, jamais dans `professional_profiles` |
| Périmètre d'actes autorisés par profil (RG-INF-02) | 🔴 Absent — aucune taxonomie « actes autorisés » n'existe dans le code ; un infirmier et un médecin sont aujourd'hui strictement interchangeables du point de vue de HOM/CNS |
| Gestion de zone de couverture, disponibilités, tarifs | 🟡 Partiel — `professional_availability` (disponibilités) existe en base mais n'est consommée par aucun code Dart ; `consultation_fee`/`home_visit_fee` existent et sont affichés en lecture par HOM/CNS, mais aucun écran ne permet à un professionnel de les définir lui-même ; aucune notion de zone de couverture géographique n'existe nulle part |
| Application « Health Professional » (file de demandes) | 🔴 Absent en tant que tel — `HomecareListScreen(asProfessional: true)`/`TeleconsultListScreen(asProfessional: true)` (Modules 15/18) affichent les demandes déjà assignées à un professionnel, mais ne constituent pas une application dédiée avec réception/acceptation/suivi propre à INF |
| Évaluations reçues, avec modération | 🔴 Absent — `professional_reviews` existe en double définition contradictoire (voir C78) et n'est consommée par aucun écran ; aucun écran « Évaluations reçues » n'existe pour qu'un professionnel consulte ses avis |
| RG-INF-01 (vérification avant réception de demande) | 🔴 Non appliqué avant correctif (voir C81) → 🟢 appliqué au niveau RLS après correctif, mais aucun parcours d'inscription/vérification réel n'existe pour qu'un professionnel devienne un jour vérifié en pratique |

### 2.3 Arbitrage

Soumis au porteur du projet (AskUserQuestion, 30/08/2026) : trois options présentées (corriger l'existant et différer la construction ; cadrer une session de construction dédiée sans rien corriger ; construire un MVP minimal maintenant). **Retenu : « Corriger l'existant, différer la construction (Recommandé) »** — les 3 défauts réels du code déjà écrit sont corrigés ce tour (C78-C81) ; les 4 écrans cahier et la taxonomie RG-INF-02 restent à construire dans une future itération dédiée, cadrée comme un chantier de conception plutôt qu'un ajout en marge — même logique que D4 (BIZ). Voir registre **D32**.

---

## 3. Sécurité & résilience

### 3.1 Collision de migration bloquant le déploiement complet (C78)

En inspectant l'ensemble des migrations touchant les 6 tables du module, `20260828020000_professional_reviews.sql` a été découverte en collision directe avec `20260827005500_professionals.sql` : les deux fichiers exécutent `create table public.professional_reviews (...)`, le second sans `if not exists`, sur un nom de table déjà pris par le premier (3 timestamps plus tôt, même journée). Sur une base neuve, l'application séquentielle des migrations (par ordre chronologique de nom de fichier, comportement standard de `supabase db push`) aurait levé une erreur Postgres bloquante (« relation "professional_reviews" already exists ») exactement à cette migration — interrompant l'application de TOUTES les migrations suivantes, c'est-à-dire la quasi-totalité du projet à partir de la fin du Module 15 (CNS). Deux collisions secondaires de même nature accompagnaient la première dans le même fichier : 2 index de nom identique (`idx_professional_reviews_professional_id`, `idx_professional_reviews_rating`) et 1 trigger de nom identique (`trigger_professional_reviews_updated_at`).

Cette collision est restée indétectée pendant 18 modules d'audit précisément parce qu'aucune exécution réelle de `supabase db push` n'a jamais eu lieu dans cette session (A1, documenté depuis le Module 0) — aucune relecture de code, aussi rigoureuse soit-elle, ne peut à elle seule garantir l'absence d'une collision de ce type entre deux fichiers qui ne sont jamais lus côte à côte dans le cours normal d'un audit module par module (le second fichier, daté du 28/08, appartient chronologiquement à la période du Module 15 ; le premier, daté du 27/08, appartient à l'ouverture du Module 19 — les deux n'ont jamais été comparés avant que l'audit d'INF n'oblige à relire toutes les migrations touchant `professional_*`).

Corrigé en réécrivant `20260828020000_professional_reviews.sql` (voir §5 pour le détail) : la table n'est plus recréée mais enrichie via `alter table ... add column if not exists`, les 2 index et le trigger dupliqués ne sont plus recréés, et les 3 anciennes policies permissives de la migration d'origine sont explicitement `drop`-ées avant d'être remplacées par le jeu avec modération — nécessaire car des policies RLS permissives se combinent en OR logique : les laisser coexister aurait rendu la modération inopérante (`using (true)` de l'ancienne policy SELECT aurait toujours autorisé la lecture d'un avis non approuvé, quelle que soit la nouvelle policy `using (status = 'approved')`).

**Recommandation impérative** : dès qu'un environnement outillé sera disponible, `supabase db push` sur une base strictement neuve doit être exécuté en priorité absolue, avant toute autre validation de ce projet — c'est le seul moyen de confirmer que cette collision était bien la seule de ce type parmi les ~90 fichiers de migration du projet.

### 3.2 Motif « rôle inatteignable », occurrence dans la migration d'origine du module audité (C79)

`20260827005500_professionals.sql`, policy « Admins can manage professional profiles » sur `professional_profiles` : `exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')` — valeur `'admin'` jamais autorisée par la contrainte CHECK de `profiles.role`. Différence notable avec les occurrences précédentes de ce motif (C49/C54/C63/C67/C70b) : celles-ci touchaient toutes des migrations d'AUTRES modules, découvertes en marge d'un audit ; celle-ci touche la migration d'origine du module en cours d'audit lui-même. Corrigé (migration `20260830046000_professionals_module_fixes.sql`) avec `is_gsg_admin()`. Le même correctif a été appliqué à « Staff moderate reviews » (`role in ('admin','staff')`, `20260828020000_professional_reviews.sql`) dans le même mouvement — via un test direct sur `public.admin_users` plutôt qu'un appel à `is_gsg_admin()`, cette fonction n'étant définie que par une migration ultérieure (`20260829003800_admin_helpers.sql`) : l'appeler depuis un fichier daté du 28/08 aurait provoqué une erreur « function does not exist », un piège de méthode propre à la correction rétroactive d'anciennes migrations plutôt qu'à l'ajout d'une nouvelle.

### 3.3 Exposition excessive de données personnelles (C80)

« Everyone can view professional profiles » (`for select using (true)`) exposait l'intégralité de la ligne `professional_profiles` — y compris `license_number`, `license_issuing_body`, `license_expiry_date`, `emergency_contact_name`, `emergency_contact_phone`, `rejection_reason` — à tout utilisateur authentifié, y compris pour un profil `is_verified = false` (jamais vérifié, potentiellement une inscription frauduleuse en cours d'examen). Même famille de limite structurelle que D27 (Module 15, exposition de `profiles.phone`), mais plus sévère : un numéro de contact d'urgence et un numéro de licence professionnelle sont des données plus sensibles qu'un numéro de téléphone de contact ordinaire.

Corrigé partiellement : policy resserrée à `is_verified = true OR auth.uid() = id OR is_gsg_admin()`, fermant l'exposition des profils jamais vérifiés (le cas le plus à risque) sans casser la découverte publique des professionnels vérifiés qu'utilisent déjà HOM/CNS (ces deux modules ne sélectionnent déjà que `is_verified = true`, corrigé aux Modules 15/18). Limite résiduelle assumée et consignée (D32, même logique que D27) : les colonnes sensibles d'un profil VÉRIFIÉ restent techniquement lisibles par API directe par tout compte authentifié — seule une vue dédiée ou un GRANT/REVOKE colonne fermerait complètement ce résidu, non entrepris faute d'environnement outillé pour vérifier l'absence de régression sur HOM/CNS.

### 3.4 RG-INF-01 non appliqué au niveau RLS (C81)

RG-INF-01 (Critique) n'était appliqué QUE côté UI (les écrans de réservation HOM/CNS filtrent déjà `is_verified = true` lors de la sélection d'un professionnel, corrigé aux Modules 15/18) — jamais au niveau des policies RLS d'écriture de `homecare_interventions`/`consultations`. Un client alternatif (appel direct à l'API REST Supabase, hors application officielle) pouvait donc créer une intervention ou une consultation avec n'importe quel `professional_id` valide, y compris celui d'un compte `role='professionnel'` jamais vérifié — voire sans aucune ligne `professional_profiles` du tout, puisque rien n'en crée une à l'inscription (voir §2.2). Le professionnel non vérifié pouvait ensuite consulter/accepter la demande via ses propres policies de lecture/mise à jour (`auth.uid() = professional_id`), déjà correctes et non modifiées par ce correctif.

Corrigé (migration `20260830046000_professionals_module_fixes.sql`) : nouvelle fonction `public.is_verified_professional(prof_id uuid)` ; les policies « Patients can insert own interventions »/« Patients can insert own consultations » sont réécrites avec un `with check` supplémentaire exigeant `is_verified_professional(professional_id)`, gatant uniquement le point d'entrée (l'admission par le patient) sans toucher aux policies de lecture/mise à jour du professionnel.

**Limite assumée** : ce correctif ferme la porte RLS, mais aucun parcours d'inscription/vérification réel n'existe pour qu'un professionnel devienne un jour `is_verified = true` en pratique — sans construction de l'écran « Inscription et vérification du professionnel » (différée, D32), la fonction `is_verified_professional()` ne trouvera jamais de ligne correspondante pour un compte `professionnel` nouvellement créé, RG-INF-01 restant correctement appliqué mais pratiquement inatteignable tant que ce chantier n'est pas mené.

---

## 4. Optimisation & améliorations

- **Rapprochement RG-INF-01 ↔ RG-HOM-01** signalé (D32, note en marge) : les deux règles reposent sur la même notion de vérification d'éligibilité avant admission d'une demande (professionnel vérifié pour INF, absence d'urgence classée TRI pour HOM) et aucune des deux n'est aujourd'hui vérifiée par un mécanisme technique commun — un futur chantier INF pourrait utilement les traiter ensemble plutôt que module par module.
- **`is_verified_professional()`** conçue comme une fonction réutilisable (pas seulement inline dans une policy), pour qu'un futur module RG-INF-02 (périmètre d'actes par profil) puisse s'appuyer sur le même principe (fonction SQL dédiée, testable indépendamment) plutôt que de dupliquer la logique.
- Aucune nouvelle fonctionnalité hors-périmètre cahier n'a été ajoutée ce module — conformément à l'arbitrage du porteur du projet, l'effort a porté exclusivement sur la correction de defects réels dans le code déjà écrit.

---

## 5. Documentation API / conformité aux règles métier

**`public.is_verified_professional(prof_id uuid)`** *(nouveau, `20260830046000_professionals_module_fixes.sql`)* — `security definer`, retourne vrai si `prof_id` correspond à un `professional_profiles.is_verified = true`. Utilisée en `with check` sur les policies INSERT de `homecare_interventions`/`consultations`.

**RLS `professional_profiles`** — « Admins can manage professional profiles » réécrite avec `is_gsg_admin()` ; « Everyone can view professional profiles » remplacée par « Verified professionals are publicly discoverable » (`is_verified = true OR auth.uid() = id OR is_gsg_admin()`).

**RLS `homecare_interventions`/`consultations`** — policies INSERT patient réécrites avec `with check (auth.uid() = patient_id and is_verified_professional(professional_id))`.

**`20260828020000_professional_reviews.sql`** *(réécrite)* — `create table` → `alter table add column if not exists` (consultation_id, is_verified, helpful_count, not_helpful_count, status, moderation_notes) ; contrainte unique élargie à `(professional_id, patient_id, consultation_id)` ; 2 index et 1 trigger dupliqués retirés ; 3 policies d'origine `drop`-ées et remplacées par un jeu avec modération, dont « Staff moderate reviews » corrigée du motif « rôle inatteignable ».

---

## 6. Scénarios de test (voir le protocole de test E2E dédié, `PharmaConnect_Module19_Protocole_Test_E2E.md`)

1. Déploiement complet des migrations sur une base neuve — priorité absolue, préalable à tout autre scénario de cet audit ou de tout audit antérieur (C78).
2. Vérification/moderation par un compte GSG admin réel (C79).
3. Visibilité d'un profil professionnel selon son statut de vérification (C80).
4. Tentative de création d'intervention/consultation par API directe avec un `professional_id` non vérifié — doit être bloquée (C81).
5. Parcours d'inscription `role='professionnel'` de bout en bout — doit être documenté comme non fonctionnel en pratique (aucun écran de vérification, limite assumée de §3.4).

---

## 7. Livrables de ce module

Modifié (correctif de collision) : `supabase/migrations/20260828020000_professional_reviews.sql`.
Nouveau : `supabase/migrations/20260830046000_professionals_module_fixes.sql`.
`PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A28 ; C78-C81 ; D32).
Ce rapport (premiers constats + corrections), le PV de recette provisoire, le protocole de test E2E.

---

**Le module Réseau de professionnels mobiles (INF) est-il totalement clos et validé pour passer au suivant, compte tenu du périmètre différé consigné en D32 ?**
