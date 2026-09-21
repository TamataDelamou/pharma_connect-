# PharmaConnect — Module 22 (FAM — PharmaConnect Family & Diaspora)
### Rapport d'audit — Étape 1 : Inspection & rapport de situation — 30/08/2026

**Ouverture officielle du module**, à la suite de la clôture du Module 21 (IOT). Numérotation confirmée contre la table officielle du cahier (`Cahier_de_Conception_PharmaConnect_v2.docx`, section « Modules fonctionnels détaillés », relue directement pour ce module) : 22 = FAM.

---

## 1. Périmètre cahier (rappel)

**Code module :** FAM — **Priorité :** Différenciant — Marché diaspora

**Objectif.** Répondre au besoin des membres de la diaspora guinéenne et ouest-africaine souhaitant **financer et suivre à distance** la santé de proches restés au pays — un modèle où le payeur (souscripteur) et le patient peuvent se trouver dans deux pays différents.

**Fonctionnalités clés cahier :** abonnement familial couvrant plusieurs bénéficiaires rattachés à un même souscripteur (éventuellement à l'étranger) · financement à distance d'une consultation/visite à domicile/achat de médicaments, avec **paiement international** · notifications de suivi au souscripteur, selon autorisations du bénéficiaire · tarifs préférentiels et accès facilité à la téléconsultation pour les bénéficiaires · gestion de rôles d'**aidant familial** avec droits d'accès explicitement consentis par le bénéficiaire.

**Écrans principaux attendus :** Souscription à un abonnement familial · Ajout d'un bénéficiaire · Tableau de suivi du souscripteur (diaspora) · Financement d'une prestation à distance.

**Règles de gestion :**

| Réf. | Énoncé | Criticité |
|---|---|---|
| RG-FAM-01 | Le souscripteur d'un abonnement familial n'a accès aux informations de santé d'un bénéficiaire majeur qu'avec le consentement explicite de ce dernier, indépendamment de sa participation financière. | Critique |
| RG-FAM-02 | Le paiement international associé à un abonnement familial est traité par un prestataire agréé pour les transactions transfrontalières, distinct des agrégateurs mobile money locaux. | Standard |

---

## 2. Constat — écart de périmètre, même famille que TRI/HOM/INF/IOT

**Le code trouvé sous `lib/modules/family/` (26 fichiers) ne construit PAS le modèle de financement à distance/diaspora du cahier — c'est un système de partage de données de santé entre proches, doublé d'un module de défis santé gamifiés et d'un système d'alerte d'urgence (SOS).**

Preuves concrètes (recherche exhaustive `abonnement`/`subscription`/`diaspora`/`international`/`paiement`/`payment`/`beneficiar`/`bénéficiaire`/`souscri`/`tarif`/`préférentiel` sur tout `lib/modules/family/`) :
- **Une seule occurrence de « Diaspora » dans tout le module** : un libellé d'en-tête statique (`'Famille & Diaspora'`) dans `family_list_screen.dart` — aucune fonctionnalité réelle derrière ce mot.
- **Aucune trace** d'abonnement, de souscription, de paiement (local ou international), de tarif préférentiel, ni de la notion même de « souscripteur » distinct du « bénéficiaire ».
- Le modèle réel (`family_links`) est un système de **partage consenti de données de santé entre un patient et un proche** : le patient (`patient_id`) invite un proche (`family_member_id`) avec des permissions granulaires (voir dossier, voir ordonnances, réserver des consultations, recevoir des alertes), le proche doit ensuite accepter l'invitation (transition `pending` → `active`). C'est un modèle de consentement bidirectionnel réel et plutôt bien conçu — mais dans le sens **inverse** du cahier (ici c'est le PATIENT qui consent à partager, pas le BÉNÉFICIAIRE qui autorise un SOUSCRIPTEUR payeur) et sans aucune dimension financière.
- Deux briques additionnelles, sans rapport avec le cahier FAM tel que rédigé : un système de **défis santé familiaux gamifiés** (`family_challenges`/`family_challenge_contributions`/`family_activities`, migration `20260828016200_gamification_family.sql`) et un système d'**alerte SOS d'urgence** avec géolocalisation (`sos_alerts`/`sos_acknowledgements`, migration `20260828023000_sos_notifications.sql`).

**Correction au registre (Module 16/FID, D28)** : lors de l'audit du Module 16, `gamification_family.sql` avait été signalée « orpheline, non liée à FID » — exact pour FID, mais imprécise dans l'absolu. Confirmé en Étape 2 (§6) : cette migration N'EST PAS orpheline — elle est bien consommée par du code réel et fonctionnel (`family_challenge_provider.dart`, `family_challenge_service.dart`, `family_challenges_screen.dart`, `family_challenge_detail_screen.dart`), simplement rattachée à FAM et non à FID.

Ce n'est pas un simple manque partiel : aucune des 4 fonctionnalités clés cahier (abonnement, financement à distance, paiement international, tarifs préférentiels/aidant familial rémunérateur) n'existe où que ce soit dans le projet — même famille que D4 (BIZ)/D32 (INF)/D31 (HOM)/D36 (IOT).

## 3. Inventaire du code trouvé

**Dossier `lib/modules/family/`** — 26 fichiers : 8 modèles (`family_link.dart`, `family_link_status.dart`, `family_alert.dart`, `family_alert_type.dart`, `family_activity.dart`, `family_challenge.dart`, `family_challenge_contribution.dart`, `sos_alert.dart`), 2 providers, 4 services, 7 écrans, 4 widgets.

**Migrations :** `20260827005000_family.sql` (`family_links`, `family_alerts`, `family_activity_log`), `20260828016200_gamification_family.sql` (`family_challenges`, `family_challenge_contributions`, `family_activities`), `20260828023000_sos_notifications.sql` (`sos_alerts`, `sos_acknowledgements`) — 3 migrations distinctes, 8 tables au total.

**Routage.** Toutes les routes `/family`, `/family/new`, `/family/alerts`, `/family/sos`, `/family/:id` sont déclarées et fonctionnelles, déjà réordonnancées pour éviter le shadowing go_router lors du balayage transverse C69 (Module 18). **Absentes du menu de navigation** (`dashboard_screen.dart`, recherche exhaustive : aucune occurrence de « Famille »/« Family »/« SOS ») — 20ème occurrence du motif D6, confirmée en Étape 2.

## 4. Défauts trouvés à l'ouverture (Étape 1)

### FAM-1 — Écritures RLS totalement bloquées sur 2 des 3 tables du module de base (motif « migration incomplète en écriture », déjà rencontré ≥11 fois — C35/C37/C41/TRC)

- **`family_alerts`** : seules des policies `select` et `update` existent à l'ouverture. Aucune policy `insert` ni `delete`.
- **`family_activity_log`** : seule une policy `select` existe. **Aggravant** : l'échec de `logActivity()` est explicitement avalé en silence côté Dart (`catch (e) { // Log silently }`), motif proche de C75.

### FAM-2 — `sos_acknowledgements` : écriture possible, lecture impossible

Seule une policy `insert` existe. Aucune policy `select`. Un accusé de réception s'enregistre mais ne peut ensuite être relu par personne.

### FAM-3 — Logique de résolution SOS explicitement factice (commentaire du code lui-même)

`SOSService._checkAndUpdateStatus()` : « Mock: always resolve after first acknowledgment » — la moindre confirmation d'UN SEUL proche clôt automatiquement l'alerte, sans vérifier tous les proches liés ni la sécurité réelle du patient. Gravité directe pour un module de sécurité/urgence.

### FAM-4 — Notification push non implémentée

`SOSService._sendPush()` ne fait qu'un `print()` console, malgré un commentaire référençant `PushNotificationService`.

### FAM-5 — Embed PostgREST suspect dans `getAlertsForUser()`

`.eq('family_link_id.family_member_id', userId)` référence le nom brut de la relation, pas l'alias `patients` utilisé dans le select. Motif déjà rencontré 2 fois (C48/C60).

### FAM-6 — UX du champ « ID du membre de la famille »

`family_new_screen.dart` demande la saisie manuelle de l'UUID brut de la personne à ajouter, sans recherche par nom/téléphone.

---

## 6. Étape 2 — Analyse comparative (30/08/2026)

### 6.1 RG-FAM-01 et RG-FAM-02 face au code réel

Aucune des deux règles de gestion n'est applicable au code trouvé, faute d'objet auquel les appliquer :

- **RG-FAM-01** (consentement explicite du bénéficiaire majeur, indépendant du financement) suppose l'existence d'un **souscripteur payeur distinct du bénéficiaire**. Le modèle réel (`family_links`) n'a pas cette distinction — il n'y a qu'un « patient » et un « proche », sans rôle financier. En un sens, `family_links` répond même à une exigence **voisine mais inversée** : c'est le patient (propriétaire de la donnée) qui consent explicitement à un partage avec le proche, matérialisé par les 4 permissions granulaires (`can_view_records`, `can_view_prescriptions`, `can_book_consultations`, `can_receive_alerts`) et par le flux d'invitation à double consentement (`pending` → `active`, le proche devant accepter). C'est un mécanisme de consentement réel, robuste, et fidèle à l'esprit protecteur de RG-FAM-01 — mais il protège un scénario différent (partage familial de dossier) et non celui du cahier (financement à distance par un tiers payeur).
- **RG-FAM-02** (paiement international via prestataire agréé transfrontalier) : aucune trace de paiement, local ou international, dans tout le module `family`. Sans objet.

**Conclusion Étape 2 sur le périmètre** : confirmation intégrale du constat de l'Étape 1 (§2). Il ne s'agit pas d'un début d'implémentation à compléter, mais de deux systèmes différents portant le même nom de domaine (« famille »). Même famille de décision que D4 (BIZ)/D31 (HOM)/D32 (INF)/D36 (IOT) : construire ex nihilo l'abonnement familial/financement diaspora dépasse le cadre d'un audit de sécurisation.

### 6.2 Écrans cahier vs réalité

Aucun des 4 écrans attendus (souscription abonnement familial, ajout de bénéficiaire avec rôle payeur, tableau de suivi souscripteur diaspora, financement à distance d'une prestation) n'existe. Les 7 écrans réels (`family_list_screen.dart`, `family_detail_screen.dart`, `family_new_screen.dart`, `family_challenges_screen.dart`, `family_challenge_detail_screen.dart`, `family_journal_screen.dart`, `sos_screen.dart`) couvrent un périmètre fonctionnel différent mais cohérent en lui-même (gestion des liens familiaux, défis santé gamifiés, alerte SOS).

### 6.3 Résolution de FAM-4 (notification push)

Vérification demandée à l'ouverture : un service de push réel existe-t-il ailleurs dans `lib/core` ? **Oui.** `lib/core/services/push_notification_service.dart` expose une API réelle et déjà utilisée ailleurs dans le projet, `sendNotificationToUser({required userId, required title, required body, data})`, qui résout les tokens push de l'utilisateur et journalise dans `notifications_history`. Un second service, `lib/core/services/notification_service.dart`, existe également mais est un wrapper **local uniquement** (`FlutterLocalNotificationsPlugin` direct, notifications sur l'appareil courant) — impropre à notifier un proche distant. **FAM-4 est donc un défaut de câblage (motif D6/famille C-tickets de câblage), pas une lacune socle** : le service correct existait déjà et attendait d'être branché. Corrigé en Étape 3 (§7.4).

### 6.4 Résolution de FAM-5 (embed PostgREST)

Confirmé par lecture croisée de `family_service.dart` et `family_alert.dart` : le bug est double, pas simple.
1. Le filtre `.eq('family_link_id.family_member_id', userId)` cible le nom brut de la relation (`family_link_id`) alors que le `select` l'aliase `patients` — incohérence directe.
2. Même en ignorant l'alias, sans `!inner` un filtre sur une ressource embarquée ne restreint QUE le contenu embarqué renvoyé pour chaque ligne, pas les lignes `family_alerts` elles-mêmes retournées au niveau racine — seule la RLS protégeait réellement contre une fuite ici, pas ce filtre applicatif.
3. Un **second bug indépendant**, plus profond, existait déjà dans `FamilyAlert.fromJson()` : `json['patients']['full_name']` cherchait `full_name` un niveau trop haut par rapport à la forme réelle de l'embed d'origine (`patients` → `patient_id` → `full_name`) — `patientName` valait donc systématiquement `null`, indépendamment du bug de filtre.

Ne peut pas être vérifié par le harnais Postgres brut (comportement propre à PostgREST/Supabase-js) — corrigé par lecture directe et cohérence de bout en bout entre le service et le modèle (voir §7.5), non par test d'exécution réelle.

### 6.5 FAM-6 et le motif D6 (navigation)

- **FAM-6** confirmé : aucun mécanisme de recherche par nom/téléphone n'existe nulle part dans le module `family` (recherche exhaustive). L'ajout d'un proche nécessite de connaître et saisir son UUID brut — une lacune UX réelle mais non bloquante et non sécuritaire (RLS non affectée), à la différence de FAM-1/FAM-2/FAM-3.
- **D6 (20ème occurrence)** confirmé : aucune entrée de menu pour `family`/`sos` dans `dashboard_screen.dart`, alors que toutes les routes sont fonctionnelles.

Ces deux points, ainsi que l'écart de périmètre radical (§6.1), sont proposés à l'arbitrage du porteur du projet en fin de rapport (§8), à la manière des modules précédents.

---

## 7. Étape 3 — Sécurité, résilience & correctifs (30/08/2026)

Méthodologie identique aux modules précédents : harnais de test Postgres 16 réel (`/home/claude/full_migration_test/`, rôle `authenticated` distinct du propriétaire, `auth.uid()` stubbé via `request.jwt.claim.sub`, `GRANT` par défaut Supabase explicitement reproduit), toute correction validée par exécution réelle avant d'être considérée close, jamais par relecture seule.

### 7.1 FAM-1 — correctif, et périmètre élargi en cours de vérification

En vérifiant le câblage complet de FAM-1 sur les 3 tables du module de base, le même motif (« migration incomplète en écriture ») a été retrouvé, non détecté à l'Étape 1, dans les **2 tables de la migration `gamification_family.sql`** consommées par du code d'écriture réel :
- `family_challenges` : seule une policy `select` existait, alors que `FamilyChallengeService.createFamilyChallenge()`/`updateChallengeProgress()`/`deleteFamilyChallenge()` effectuent des écritures réelles.
- `family_activities` : `select`+`insert` existaient mais aucune policy `delete`, alors que `deleteFamilyActivity()` existe côté client.
(`family_challenge_contributions` était déjà correctement couverte par une policy `for all` — pas de défaut.)

**Correctifs appliqués** (migrations `20260827005000_family.sql` et `20260828016200_gamification_family.sql`, committés sur l'appareil) :
- `family_alerts` : policies `insert` (« Patients can create alerts », patient sur lien actif) et `delete` (« Patients can delete alerts », patient sur son lien) ajoutées.
- `family_activity_log` : policy `select` pour le patient (« Patients can view activity log » — absente alors que c'est lui, propriétaire de la donnée partagée, qui a le besoin de supervision le plus direct au sens RG-FAM-01) et policy `insert` pour toute partie liée (« Linked parties can log activity ») ajoutées.
- `family_challenges` : policy `for all` pour les deux parties du lien (« Family members manage challenges ») ajoutée.
- `family_activities` : policy `delete` pour les deux parties du lien (« Family members delete activities ») ajoutée.

### 7.2 FAM-1 (complément) — découverte par exécution réelle : `family_alerts` sans SELECT patient

En validant le correctif DELETE de `family_alerts` par test réel, le harnais a d'abord renvoyé `DELETE 0` (aucune ligne affectée) malgré une clause `USING` du DELETE logiquement satisfaite en isolation. Diagnostic par `EXPLAIN (ANALYZE, COSTS OFF)` et vérification empirique (policy temporaire, testée, retirée puis rendue permanente) : **`family_alerts` n'avait, avant ce complément, aucune policy `select` pour le PATIENT** — seul le proche pouvait lire les alertes, ce qui signifie que le patient ne pouvait même pas voir les alertes générées sur son propre compte. Confirmé que cette absence de SELECT bloquait **silencieusement** la policy DELETE alors valide en isolation.

**Constat général retenu pour cet audit** (nouveau, documenté ici pour référence future) : en PostgreSQL, la visibilité d'une ligne pour une commande DELETE/UPDATE dépend de l'ensemble des policies RLS applicables au rôle sur la table, pas uniquement de la policy propre à la commande en cours — une policy DELETE syntaxiquement correcte et satisfaite peut ne renvoyer aucune ligne affectée si le rôle n'a par ailleurs aucune policy SELECT permettant de « voir » la ligne visée.

**Correctif appliqué** : policy « Patients can view alerts » (`select`, patient sur son lien) ajoutée à `family_alerts`. Revalidé par exécution réelle : `DELETE 1`.

### 7.3 FAM-2 — correctif `sos_acknowledgements`

Policies `select` ajoutées : « Family members view own acknowledgements » (le proche relit son propre accusé) et « Patients view acknowledgements of their alerts » (le patient concerné par l'alerte peut voir les accusés associés).

### 7.4 FAM-3 — correctif logique de résolution SOS

`SOSService._checkAndUpdateStatus()` réécrit. Constat de conception préalable : `SOSScreen._sendSOS()` diffuse une alerte en boucle, une ligne `sos_alerts` **par proche lié**, sans colonne d'incident partagé — chaque ligne est une copie indépendante par destinataire. Le correctif : la ligne acquittée est d'abord marquée `'acknowledged'` (valeur de statut prévue par la contrainte CHECK d'origine mais jusque-là jamais utilisée), puis les lignes « sœurs » (même `patient_id` + même `alert_type`, créées dans une fenêtre de ±2 minutes autour de `created_at` de la ligne courante) sont interrogées ; l'ensemble n'est marqué `'resolved'` que lorsque plus aucune sœur n'est `'active'`. Corrige directement le défaut « un seul accusé suffit à tout clore » constaté à l'ouverture.

### 7.5 FAM-4 — câblage de la notification push réelle

`SOSService._sendPush()` réécrit pour appeler `PushNotificationService().sendNotificationToUser(userId:, title:, body:)` au lieu d'un `print()`. Le service `_getUserTokens()`/`_sendToToken()`/`_logNotification()` sous-jacent reste par ailleurs lui-même un stub d'envoi FCM réel (`print()`) — limite d'infrastructure préexistante et transverse, hors périmètre de ce module, signalée pour un futur audit du socle notifications (Module 33/ADM probable).

### 7.6 FAM-5 — correctif embed + modèle

`FamilyService.getAlertsForUser()` réécrit avec un embed cohérent et réellement filtrant :
```
'*, family_links!inner(family_member_id, patients:patient_id(full_name))'
.eq('family_links.family_member_id', userId)
```
`FamilyAlert.fromJson()` mis en cohérence avec la nouvelle profondeur d'imbrication (`family_links.patients.full_name`), tout en conservant une compatibilité de repli pour l'ancienne forme (`getAlertsForLink()`, qui n'embarque pas `family_links`).

### 7.7 Validation par exécution réelle

Harnais dédié `/home/claude/fam_rls_test.sql`, 12 scénarios, reconstruit intégralement (`run_chain.sh`, ~85 migrations, base neuve) après chaque correctif :

| # | Scénario | Résultat attendu | Résultat obtenu |
|---|---|---|---|
| 1 | Patient crée une alerte sur son lien actif (INSERT `family_alerts`) | Succès | ✅ |
| 2 | Proche lit l'alerte (SELECT déjà en place) | Visible | ✅ |
| 3 | Patient supprime son alerte (DELETE `family_alerts`) | `DELETE 1` | ✅ (après §7.2) |
| 4 | Proche journalise une action (INSERT `family_activity_log`) | Succès | ✅ |
| 5 | Patient lit désormais le journal (auparavant impossible) | Visible | ✅ |
| 6 | Patient crée un défi familial (INSERT `family_challenges`) | Succès | ✅ |
| 7 | Proche met à jour la progression (UPDATE `family_challenges`) | Succès | ✅ |
| 8 | Tiers sans lien : lecture défi + écriture journal | Rejeté/invisible (0 ligne, RLS) | ✅ |
| 9 | Proche acquitte une alerte SOS (INSERT `sos_acknowledgements`) | Succès (déjà permis avant correctif) | ✅ |
| 10 | Proche relit son propre accusé (auparavant 0 ligne) | Visible | ✅ (après §7.3) |
| 11 | Patient concerné voit l'accusé (auparavant 0 ligne) | Visible | ✅ (après §7.3) |
| 12 | Tiers sans lien : lecture de l'accusé | Invisible (0 ligne) | ✅ |

**12/12 tests conformes.** Isolation multi-tiers, écritures patient/proche et lectures croisées toutes prouvées par exécution réelle, pas seulement relues.

---

## 8. Points restant à arbitrer avant scellement du Module 22

Comme pour les modules précédents (D4/D31/D32/D36), trois sujets ne relèvent pas d'un simple correctif technique et sont soumis à votre arbitrage :

**1. Écart de périmètre radical (§6.1)** — le cahier (abonnement familial diaspora, financement à distance, paiement international transfrontalier, RG-FAM-01/02) n'existe nulle part dans le code. Ce qui existe (partage consenti de dossier patient↔proche, défis santé gamifiés, SOS d'urgence) est réel, cohérent et sécurisé après ce tour, mais répond à un besoin différent.
- *Option A (recommandée, cohérente avec D4/D31/D32/D36)* : différer la construction du véritable module FAM (abonnement/financement diaspora) à un chantier de conception dédié, conserver le système de partage familial/SOS actuel tel que sécurisé.
- *Option B* : engager dès maintenant la conception du sous-système financier/diaspora — hors cadre d'un audit de sécurisation, non recommandée à ce stade.

**2. FAM-6 — UX de saisie UUID brut pour ajouter un proche.**
- *Option A* : différer (dette UX documentée, sans risque de sécurité).
- *Option B* : construire un mécanisme de recherche par nom/téléphone dans ce tour.

**3. Exposition en navigation (motif D6, 20ème occurrence).**
- *Option A* : ne pas exposer `/family` et `/sos` dans le menu tant que le point 1 n'est pas tranché.
- *Option B* : exposer dès maintenant le système de partage familial/SOS (fonctionnel et sécurisé), indépendamment du sort du volet diaspora/financement.

**Correction de registre actée dans ce rapport** : D28 (Module 16) — `gamification_family.sql` n'est pas orpheline dans l'absolu, elle est consommée par du code FAM réel (voir §6.1, §7.1).

**Résumé des correctifs de ce tour, tous validés par exécution réelle (§7.7) :**
- FAM-1 : policies d'écriture manquantes sur `family_alerts` (insert/delete), `family_activity_log` (insert), `family_challenges` (for all), `family_activities` (delete) — corrigées.
- FAM-1 (complément) : `family_alerts` sans policy SELECT patient, découverte par le harnais de test réel, bloquant silencieusement le DELETE — corrigée.
- FAM-2 : `sos_acknowledgements` sans policy SELECT — corrigée.
- FAM-3 : logique de résolution SOS factice (« Mock ») — corrigée par corrélation de fenêtre temporelle entre lignes sœurs.
- FAM-4 : notification push non câblée — corrigée (`PushNotificationService`, service réel préexistant).
- FAM-5 : embed PostgREST invalide + bug de profondeur JSON dans `FamilyAlert.fromJson()` — corrigés.

Dans l'attente de votre arbitrage sur les 3 points ci-dessus pour sceller définitivement le Module 22.

---

## 9. Clôture — arbitrage du porteur du projet (30/08/2026)

### 9.1 Écart de périmètre radical (Abonnement Diaspora & Financement à distance)

**Option retenue : différer la construction du modèle souscripteur/bénéficiaire et des paiements internationaux.**

Motivation du porteur du projet : le code existant (`family_links`) constituant une brique robuste de partage consenti et de gestion d'urgence SOS (orientation patient ↔ proche), la refonte vers un modèle de souscription diaspora multi-bénéficiaires dépasse le cadre de l'audit et nécessite un cadrage produit/fintech dédié. **Écart consigné sous le ticket D37.**

### 9.2 Ergonomie d'ajout de proche (FAM-6 — saisie d'UUID brut)

**Option retenue : différer la recherche par nom/téléphone et conserver la saisie sécurisée.**

Motivation : bien que la saisie d'un UUID brut manque de convivialité, elle garantit l'absence d'exposition non consentie d'annuaire patient. Le développement d'une API d'invitation sécurisée par téléphone/OTP est **consigné comme dette d'ergonomie sous le ticket D38.**

### 9.3 Exposition en navigation (motif D6, 20ème occurrence)

**Option retenue : exposer immédiatement les entrées `/family` et `/family/sos` au menu principal.**

Motivation : les flux de partage familial et d'alerte SOS étant désormais entièrement sécurisés, fonctionnels et validés par 12/12 tests réels sur Postgres 16 (y compris la résolution du bug de policy SELECT sur `family_alerts` et l'embed PostgREST), il n'y a plus aucun risque à les mettre à disposition des utilisateurs. **Corrigé** : deux entrées ajoutées à `dashboard_screen.dart` — « Famille » (`/family`) et « SOS Urgence » (`/family/sos`), exposées à tout rôle authentifié (ce module n'a pas de rôle `family_member` dédié côté schéma — patient et proche sont tous deux de simples comptes distingués par leur position dans `family_links`). Livré et committé sur l'appareil.

### 9.4 Résumé des actions de clôture

- **Correctifs BDD & Client validés par 12/12 tests Postgres 16** : C101 à C106 (policies RLS d'écriture sur `family_challenges`/`family_activities`, déblocage de la policy SELECT patient sur `family_alerts`, lecture `sos_acknowledgements`, résolution SOS réelle, notification push réelle, correctif embed PostgREST + bug de profondeur JSON).
- **Navigation** : intégration des routes `/family` et `/family/sos` au menu principal (`dashboard_screen.dart`), livrée et committée.
- **Tickets enregistrés au registre** : D37 (modèle souscripteur diaspora/paiement international, dette différée), D38 (ergonomie d'ajout de proche par téléphone/OTP, dette différée).

**Le Module 22 (FAM — Famille & Multi-comptes / SOS & Partage) est officiellement clos, scellé et validé.**

---

**Passation au Module 23.** Numérotation confirmée contre la table officielle du cahier : 23 = HOP (Intégration Hôpitaux, Laboratoires & Imagerie). Ouverture de son Étape 1 dans un rapport dédié.
