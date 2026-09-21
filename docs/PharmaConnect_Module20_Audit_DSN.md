# PharmaConnect — Module 20 (DSN — Dossier de Santé Numérique Longitudinal)
### Rapport d'audit — Étape 1 : Inspection & rapport de situation — 30/08/2026

**Ouverture officielle du module.** Comme convenu avec le porteur du projet, la numérotation retenue est celle du cahier de conception lui-même (table de correspondance retrouvée dans `Cahier_de_Conception_PharmaConnect_v2.docx`, section 4/récapitulatif), qui fait coïncider exactement 15=CNS, 16=FID, 17=TRI, 18=HOM, 19=INF avec la séquence réellement auditée jusqu'ici — confirmation qu'elle est la bonne référence, à la différence de la table proposée (et depuis longtemps dépassée dans les faits) au §4 de `PharmaConnect_Etape1_Audit_Global.md`. **Module 20 = DSN.**

---

## 1. Périmètre cahier (rappel)

**Code module :** DSN — **Priorité :** Différenciant — Valeur long terme

**Objectif.** Constituer, avec le consentement du patient, un historique structuré et continu de ses interventions de santé sur la plateforme (consultations, soins à domicile, ordonnances, résultats d'examens), consultable par le patient et, selon autorisation, par les professionnels de son parcours.

**Fonctionnalités clés attendues :** enregistrement structuré de chaque événement de santé (date, professionnel, motif, constantes, décision, ordonnance, suivi prévu) ; consultation par le patient de son historique complet ; partage sélectif et révocable avec un professionnel ou un proche aidant désigné ; interopérabilité prévue avec les dossiers des établissements partenaires (module HOP) ; export du dossier à la demande du patient.

**Écrans principaux attendus :** Historique de santé du patient · Détail d'un événement de santé · Gestion des partages et autorisations.

**Règles de gestion :**

| Réf. | Énoncé | Criticité |
|---|---|---|
| RG-DSN-01 | L'accès d'un professionnel au dossier de santé numérique d'un patient requiert un consentement explicite et révocable, hors situation d'urgence documentée. | Critique |
| RG-DSN-02 | Chaque intervention de soin, à domicile, en téléconsultation ou via un établissement partenaire, génère automatiquement un événement dans le dossier du patient concerné. | Standard |

---

## 2. Inventaire du code trouvé

**Dossier `lib/modules/healthrecord/`** — 24 fichiers, structure complète (models/providers/services/screens/widgets), organisés en **trois sous-ensembles distincts** :

- **Dossier de santé proprement dit** (le plus proche du périmètre cahier) : `health_record.dart` (modèle), `health_record_provider.dart`, `health_record_service.dart`, écrans liste/détail/édition, widgets d'affichage (allergie, antécédent, traitement, vaccination).
- **Résumé IA** : `health_record_ai_service.dart`/`_provider.dart`, `health_record_summary.dart` — génère un résumé texte structuré à partir du dossier (explicitement commenté `// Simulate AI processing`, cohérent avec la discipline déjà observée ailleurs dans le projet de ne jamais présenter un gabarit de texte comme une vraie IA).
- **Deux fonctionnalités hors périmètre RG-DSN, greffées sur ce même dossier** : objectifs de bien-être personnels (`health_goal.dart` — pas, hydratation, méditation, sommeil...) et alertes préventives (`preventive_alert.dart`/`preventive_alert_history.dart`) — plus proches, par nature, de FID (Module 16, suivi des traitements chroniques) que de DSN. Signalé comme observation de périmètre, pas comme un défaut en soi.

**Migrations Supabase concernées :** `20260827003000_health_records.sql` (table `health_records`), `20260828011000_healthrecord_ai.sql` (table `health_record_summaries`), `20260828016300_gamification_health.sql` (tables `health_goals`/`health_milestones`) — **aucune migration pour `preventive_alerts`/`preventive_alert_history`, voir C95 ci-dessous.**

**Routage (`app_router.dart`).** Toutes les routes `/healthrecord`, `/healthrecord/:id`, `/healthrecord/edit[/:id]`, `/healthrecord/alerts[...]` sont déclarées et fonctionnelles ; un chevauchement de route (`/healthrecord/:id` capturant `/healthrecord/edit` et `/healthrecord/alerts`) a déjà été identifié et corrigé lors du balayage transverse C69 de l'audit du Module 18 (HOM) — rien à rouvrir ici.

**Menu de navigation.** Confirmé absent de `dashboard_screen.dart` (`_navItems`/`_effectiveNavItems`) — 19ème occurrence du motif D6 déjà rencontré à presque tous les modules précédents. **Corrigé dans ce même mouvement** (voir C93bis/nav ci-dessous) : entrée « Dossier de santé » ajoutée, réservée au rôle patient (le code actuel n'implémente que la consultation par le patient de son propre dossier, pas d'écran de consultation dédié à un professionnel).

---

## 3. Constats et défauts trouvés à l'ouverture

### C94 — Motif « rôle inatteignable » (🟢 corrigé ce même mouvement)

Même motif que C49/C54/C63/C67/C70b/C79 : `role in ('admin', 'staff', 'professionnel')` sur `profiles.role`, qui n'admet jamais `'admin'` ni `'staff'` (contrainte CHECK). Quatre occurrences trouvées dans les migrations propres à ce module : 2 dans `healthrecord_ai.sql` (« Staff view summaries », « Staff generate summaries »), 2 dans `gamification_health.sql` (« Staff view health goals », « Staff view milestones »). Non bloquant pour `supabase db push` (juste une branche OR morte, la branche `'professionnel'` restait fonctionnelle), mais un accès administrateur réel restait inatteignable. **Corrigé** en remplaçant la branche morte par une vérification inlined sur `admin_users` — ces deux fichiers (28/08, 11h00 et 16h30) sont antérieurs à `is_gsg_admin()` (`20260829003800_admin_helpers.sql`), même piège de non-antériorité que C90. Rejoué avec succès sur la chaîne complète des 85 migrations (`ALL MIGRATIONS APPLIED SUCCESSFULLY`).

### C95 — Trois tables inexistantes consommées par le module « Alertes préventives » (🔴 non corrigé — nécessite un arbitrage)

`preventive_alert_service.dart` interroge `preventive_alerts`, `preventive_alert_history`, et (dans `_evaluateCondition`) `health_record_vaccinations` ou `health_actions` selon le type d'alerte. **Aucune de ces quatre tables n'existe dans les 85 migrations du projet** — recherche exhaustive confirmée (`grep` sur l'ensemble du dossier `supabase/migrations/`). Contrairement au motif D6 habituel (code construit mais jamais atteignable depuis le menu), ici c'est l'inverse : le code EST routé (`/healthrecord/alerts`, `/healthrecord/alerts/new`, `/healthrecord/alerts/edit/:id`) et sera désormais visible depuis le menu une fois la fiche « Dossier de santé » ouverte — mais chaque appel (`getPatientAlerts`, `createAlert`, `checkAndTriggerAlerts`...) échouera à l'exécution avec une erreur Postgrest « relation does not exist ». Ne bloque pas `supabase db push` (absence de DDL, pas un défaut de DDL), mais bloque la fonctionnalité entière dès qu'un patient l'utilise. Non corrigé à ce stade : construire le schéma manquant (au minimum 2 tables avec RLS, éventuellement une troisième selon ce que doit réellement être `health_actions`) est un chantier de conception, pas un correctif ponctuel — proposé à l'arbitrage du porteur du projet en clôture de module, dans la même logique que D4/D32.

### RG-DSN-02 — Écart d'architecture majeur, non consigné comme un simple bug (à confirmer en Étape 2)

Le cahier décrit un historique d'ÉVÉNEMENTS (un événement par intervention : consultation, soin à domicile, ordonnance, résultat d'examen — chacun horodaté, rattaché à un professionnel, avec motif/décision/suivi). Le code réel (`health_records`) est une fiche médicale UNIQUE par patient (groupe sanguin, taille, poids, allergies, antécédents, traitements, vaccinations), éditée directement par le patient lui-même (`health_record_edit_screen.dart` + `HealthRecordProvider.saveRecord`) — pas un journal d'événements généré automatiquement par HOM/CNS/HOP à la clôture d'une intervention. Aucun appel à `HealthRecordService` n'a été trouvé dans les modules `homecare`/`teleconsult` lors de cet audit (à confirmer de façon exhaustive en Étape 2). RG-DSN-02 (Standard) apparaît donc non implémenté à la racine : l'auto-déclaration par le patient n'est pas équivalente à la génération automatique d'un événement par un professionnel lors d'une intervention réelle.

### RG-DSN-01 — Règle Critique non appliquée en RLS (à confirmer en Étape 3, Sécurité)

`health_records.sql` accorde un accès en lecture à **tout** compte `role in ('pharmacien', 'professionnel')` sur **tous** les dossiers patients, sans aucune vérification de consentement (le commentaire du fichier lui-même l'admet : `-- (Future) Professionals can update with patient consent via separate policy` — jamais construit). `healthrecord_ai.sql` a le même défaut pour les résumés IA. Aucune table de consentement/autorisation, aucun écran « Gestion des partages et autorisations » n'existe nulle part dans le projet — la règle la plus critique du module est donc totalement absente, pas seulement mal appliquée. Point de vigilance direct avec le principe déjà noté à l'Étape 1 globale (§2.1) pour les modules à enjeu médico-légal.

### Écran « Export du dossier » — absent

Aucune trace d'export (PDF, JSON, ou autre) du dossier patient nulle part dans `lib/modules/healthrecord/` ni dans `core/utils/export_service.dart` (ce fichier existe mais n'a pas été vérifié comme couvrant ce cas — à confirmer en Étape 2).

### À vérifier par exécution réelle (Étape 3) — suppression silencieuse possible

`health_records.sql` ne définit **aucune policy `delete`** pour `health_records` (seules select/update/insert existent côté patient). Avec RLS activée et aucune policy de suppression, un `delete` ne doit normalement affecter aucune ligne — or `health_record_detail_screen.dart` propose un bouton « Supprimer ce dossier » (`HealthRecordProvider.deleteRecord` → `_confirmDelete`) qui, à en juger par le code, considère l'opération réussie dès que l'appel ne lève pas d'exception (Supabase ne remonte pas nécessairement une erreur pour un delete RLS qui n'affecte aucune ligne). Signalé comme un défaut plausible mais **non encore confirmé par exécution réelle** — à vérifier avec le même protocole Postgres local que celui qui a servi pour C78/C82-C93, avant de trancher un correctif.

---

## 4. Statut à ce stade

Trois constats consignés :
- **C94** — corrigé ce même mouvement, rejoué avec succès sur la chaîne des 85 migrations.
- **D6 (19ème occurrence)** — corrigé ce même mouvement (entrée de menu ajoutée).
- **C95, RG-DSN-01, RG-DSN-02, absence d'export, suppression RLS non prouvée** — consignés, non corrigés, en attente de l'Étape 2 (analyse comparative détaillée RG par RG) et de l'Étape 3 (sécurité), et pour C95/RG-DSN-01/RG-DSN-02, probablement d'un arbitrage de périmètre du porteur du projet (construire maintenant vs différer, comme pour D4/BIZ et D32/INF).

---

## 5. Étape 2 — Analyse comparative détaillée

| Exigence cahier | État observé dans le code | Écart / dette | Pour / Contre du choix actuel |
|---|---|---|---|
| **RG-DSN-01** (Critique) — accès professionnel soumis à consentement explicite et révocable, hors urgence documentée | RLS `health_records`/`health_record_summaries` : tout compte `role in ('pharmacien','professionnel')` lit l'intégralité de n'importe quel dossier patient, sans aucune vérification. Aucune table de consentement/autorisation nulle part dans le projet (recherche transversale : `grep consent` sur les 85 migrations ne trouve que le commentaire `(Future)` du fichier lui-même) | **Total** — la règle la plus critique du module n'est pas seulement mal appliquée, elle est absente. **Confirmé par exécution réelle, §6 ci-dessous** | Pour : simplicité de démonstration, tout professionnel voit immédiatement les données utiles à une prise en charge. Contre : exposition non consentie de données de santé sensibles (allergies, antécédents, traitements) à l'ensemble du réseau de pharmaciens/professionnels, sans lien avec le patient — risque réglementaire (secret médical, cadre OMS cité en Étape 1 globale §2.1) et risque de confiance produit de premier ordre |
| **RG-DSN-02** (Standard) — chaque intervention génère automatiquement un événement dans le dossier | `health_records` est une fiche **unique par patient**, éditée directement par le patient (`health_record_edit_screen.dart`) — pas un journal d'événements. Aucun appel à `HealthRecordService` trouvé dans `homecare`/`teleconsult` (recherche par lecture directe des services de ces deux modules, non exhaustive à 100 % sur l'ensemble du projet mais convergente avec l'absence de toute écriture croisée observée ailleurs dans l'audit) | **Architecture différente de l'objectif cahier** — le patient s'auto-déclare, aucune intervention réelle (HOM/CNS/HOP) n'alimente jamais le dossier | Pour : plus simple à construire, s'apparente à un carnet de santé auto-renseigné plutôt qu'à un audit trail. Contre : ne répond pas à l'objectif « historique continu des interventions » du cahier — la valeur différenciante du module (interopérabilité, confiance, traçabilité longitudinale) repose entièrement sur cette génération automatique, qui n'existe pas |
| Écran « Historique de santé du patient » | Présent (`health_record_list_screen.dart`) mais liste des « dossiers » (fiches), pas des événements | Partiellement couvert, dans l'esprit d'une fiche plutôt que d'un historique | — |
| Écran « Détail d'un événement de santé » | Présent (`health_record_detail_screen.dart`) mais affiche une fiche complète, pas un événement daté et contextualisé (professionnel, motif, décision, suivi) | Partiellement couvert | — |
| Écran « Gestion des partages et autorisations » | **Absent** — aucun fichier, aucune route | Total, corollaire direct de l'absence de modèle de consentement (RG-DSN-01) | — |
| Export du dossier à la demande du patient | **Absent** — `core/utils/export_service.dart` existe mais n'est utilisé que pour l'export CSV des rapports de stock (`exportStockReport`), jamais importé par `lib/modules/healthrecord/` (confirmé par lecture directe du fichier) | Total | — |
| Interopérabilité avec le module HOP | Non applicable à ce stade — HOP (Module 23) n'est pas encore audité et son propre état de code n'a pas été vérifié dans cette session | Prématuré à évaluer avant l'audit de HOP | — |
| Deux fonctionnalités hors périmètre RG-DSN (objectifs de bien-être, alertes préventives) | Construites et greffées sur ce même dossier de code, sans RG cahier correspondante | Écart de périmètre (extension non documentée), pas un défaut de conformité au sens strict | Pour : valeur produit additionnelle plausible (engagement patient). Contre : consomme du budget de développement sur une extension non spécifiée pendant que les écrans cahier eux-mêmes (partage, export) restent non construits — à signaler comme un choix de priorisation à assumer explicitement, même logique que le cluster hors-cahier `pos`/`cash`/`sales`/`returns` (Étape 1 globale, §1.5) |

## 6. Étape 3 — Sécurité, résilience & vérification par exécution réelle

Deux questions posées ont été vérifiées par exécution réelle sur Postgres 16 local (schéma complet des 85 migrations, rôle `authenticated` distinct du propriétaire des tables, RLS effectivement active — pas un test en tant que superutilisateur), plutôt que par lecture statique seule.

### 6.1 Suppression de `health_records` : silencieuse ou rejet strict ?

**Résultat : silencieuse, confirmée.** Protocole : patient A crée son propre dossier (`insert`, policy respectée) ; le même patient A, authentifié, exécute `delete from health_records where id = ...` sur sa propre ligne. PostgreSQL répond `DELETE 0` — **aucune erreur, aucun refus d'autorisation** — puis une relecture en tant que `postgres` (hors RLS) confirme que la ligne existe toujours. C'est le comportement standard de PostgreSQL RLS : en l'absence de policy pour une commande donnée, la clause `USING` implicite vaut `false`, ce qui filtre silencieusement 0 ligne plutôt que de lever une exception — à condition que le rôle dispose du privilège SQL `DELETE` au niveau table (accordé par défaut à `authenticated` sur un vrai projet Supabase ; reproduit ici explicitement dans le harnais de test, absent du stub minimal utilisé jusqu'ici dans cette session — voir la note de méthode ci-dessous). **Confirme le défaut A30/C96 : un patient qui clique « Supprimer ce dossier » voit l'écran se comporter comme un succès (aucune exception remontée à `HealthRecordProvider.deleteRecord`) alors que ses données de santé restent en base, intégralement lisibles par tout pharmacien/professionnel (voir 6.2).**

### 6.2 État réel du modèle de consentement (RG-DSN-01)

**Résultat : confirmé absent, mesuré concrètement.** Même protocole : patient A crée son dossier (groupe sanguin, note). Un compte `professionnel` sans aucun lien avec patient A (jamais de réservation, jamais d'intervention commune) exécute un `select` sur ce dossier : **succès, lecture intégrale** (`blood_type`, `notes`, toutes les colonnes). Un compte `pharmacien` sans aucun lien obtient le même résultat. Le même compte `professionnel` peut également **créer un résumé IA** du dossier (`health_record_summaries`, policy C94 fraîchement corrigée) sans lien ni consentement. À l'inverse, l'isolement patient-à-patient **fonctionne correctement** : un second patient (patient B) sans lien obtient 0 ligne — la seule barrière réellement en place est le rôle (`patient` vs `pharmacien`/`professionnel`), pas la relation de soin.

**Mesure du travail d'isolation RLS nécessaire pour appliquer RG-DSN-01** (base d'estimation pour l'arbitrage du porteur du projet) :
1. Une table `health_record_consents` (ou équivalent) : `patient_id`, `professional_id` (ou `granted_to`, pouvant aussi être un proche aidant — cahier §fonctionnalités clés), `granted_at`, `revoked_at nullable`, `scope` éventuel (lecture seule vs résumé IA).
2. Remplacement des deux policies actuelles (« Professionals can view all records », « Staff view/generate summaries ») par une vérification `exists (... where patient_id = health_records.patient_id and professional_id = auth.uid() and revoked_at is null)`, combinée le cas échéant à une exception « urgence documentée » (RG-DSN-01 le prévoit explicitement — nécessite de définir ce que « documentée » signifie concrètement, non spécifié par le cahier).
3. Un écran « Gestion des partages et autorisations » (accorder/révoquer), aujourd'hui totalement absent, plus la logique métier associée (provider/service).
4. Alignement avec les policies déjà en place pour d'autres modules utilisant une notion voisine de « professionnel en charge du patient » (HOM/CNS via `professional_patient_interactions`, Module 19/INF) — à étudier pour réutiliser une source de vérité commune plutôt que dupliquer un nouveau mécanisme de consentement isolé.

C'est un chantier de conception (nouvelle table, RLS, écran, provider, service, décision produit sur le cas « urgence »), pas un correctif RLS ponctuel — cohérent avec la classification en D33.

**Note de méthode.** Le harnais de test local (schéma stub auth/rôles) ne reproduisait pas les `GRANT` par défaut qu'un vrai projet Supabase applique automatiquement au rôle `authenticated` sur le schéma `public` — sans ce `GRANT`, le test aurait échoué sur un refus d'autorisation SQL avant même que RLS n'entre en jeu, un résultat non représentatif. Reproduit explicitement pour ce test (documenté dans le script), conformément à la discipline déjà appliquée pour le stub pgvector (A29). Un défaut de trigger sans rapport avec DSN a été rencontré au passage lors du seeding des comptes de test (`log_network_activity()` sur `profiles`, `admin_user_id not null` alimenté par `auth.uid()`) — contourné localement (trigger désactivé le temps du seed), signalé pour information à l'audit futur du Module 33 (ADM), hors périmètre de ce module.

---

## 7. Options d'arbitrage pour sceller le Module 20

**C95 — Alertes préventives (3 tables manquantes) :**
- **Option A — Construire maintenant.** Ajouter les tables `preventive_alerts`/`preventive_alert_history` (RLS incluse) dans une migration corrective de ce module ; clarifier/renommer la troisième référence (`health_record_vaccinations`/`health_actions`, aucune des deux n'existe et leur intention exacte n'est pas documentée) avant de la construire, ou la retirer si son utilité reste incertaine.
- **Option B — Différer comme chantier dédié**, à la manière de D4 (BIZ)/D32 (INF) : la fonctionnalité reste non fonctionnelle mais atteignable en l'état (aucune régression nouvelle), consignée pour une itération future.
- **Option C — Retirer la fonctionnalité du routage** en attendant (dé-router `/healthrecord/alerts[...]` et son entrée éventuelle) pour éviter qu'un patient ne rencontre une erreur d'exécution visible, sans pour autant construire le schéma maintenant.

**RG-DSN-01 (consentement, Critique) :**
- **Option A — Construire le modèle de consentement maintenant** (voir l'estimation §6.2) : le plus conforme à la criticité de la règle, mais le plus coûteux en développement pour ce tour d'audit.
- **Option B — Correctif RLS intermédiaire immédiat, en attendant le modèle complet** : restreindre l'accès professionnel/pharmacien à une preuve d'intervention déjà existante ailleurs dans le projet (ex. `professional_patient_interactions` du Module 19/INF, ou une réservation/consultation HOM/CNS active) plutôt qu'un accès non filtré — réduit l'exposition sans construire l'écran de gestion des partages, mais reste un palliatif, pas la règle telle qu'écrite (pas de révocation explicite, pas de consentement actif du patient).
- **Option C — Différer et documenter formellement le risque**, à la manière de D32, en actant que la donnée de santé du module reste, pour l'instant, non protégée par consentement — la seule option qui laisse le défaut Critique ouvert sans aucune atténuation.

**RG-DSN-02 (journal d'événements) et écrans manquants (partage, export) :** dans tous les cas, portée de reconception plus large que ce tour d'audit (nécessite la collaboration d'autres modules — HOM/CNS/HOP — pour écrire dans le dossier) ; proposé par défaut en **Option B différée**, sauf préférence contraire.

**Suppression silencieuse (A30) :** indépendamment du choix ci-dessus, corrigible immédiatement et sans risque par l'ajout d'une policy `delete` explicite (`for delete using (auth.uid() = patient_id)`) — recommandé de le faire dans tous les cas, quel que soit l'arbitrage retenu pour C95/RG-DSN-01/02.

---

## 8. Clôture — arbitrage du porteur du projet (30/08/2026)

Décisions retenues :

- **C96 (suppression silencieuse)** : corrigé immédiatement (`20260830047000_healthrecord_module_fixes.sql`, policy `delete` ajoutée), re-vérifié par exécution réelle (`DELETE 1` désormais, 0 ligne restante), rejoué avec succès sur les 85 migrations.
- **C95 (Alertes préventives)** : **Option C retenue** — dé-routage plutôt que construction. Les 3 routes (`/healthrecord/alerts`, `/healthrecord/alerts/new`, `/healthrecord/alerts/edit/:id`) et leurs imports ont été commentés dans `app_router.dart`, avec justification inline. Code Dart (écrans, provider, service, modèles) conservé intact. Recherche exhaustive confirmant qu'aucun autre écran du module ne référence ces routes — aucun risque de bouton orphelin. Consigné en **D33**.
- **RG-DSN-01/RG-DSN-02 (consentement, journal d'événements)** : **Option C retenue** — différé comme chantier de conception dédié, à la manière de D4/D32. Le risque Critique documenté par C97 reste actif sans atténuation : consigné formellement en **D34**, à traiter en priorité dès qu'un chantier DSN dédié sera planifié.

Voir le PV de recette, `PharmaConnect_Module20_PV_Recette.md`, pour la décision de recette formelle.

---

Le module Dossier de Santé Numérique Longitudinal (DSN) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au module suivant.
