# PharmaConnect — Audit Module 15 (CNS — Télé-conseil pharmaceutique & Orientation, réservé ici au sous-système téléconsultation réellement codé sous `lib/modules/teleconsult/`)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Le dossier trouvé en base est `lib/modules/teleconsult/` — 5 modèles (`consultation.dart`, `consultation_status.dart`, `availability_slot.dart`, `async_message.dart`, `pre_consultation.dart`), 2 providers (`teleconsult_provider.dart`, `pre_consultation_provider.dart`), 5 écrans (`teleconsult_list_screen.dart`, `teleconsult_detail_screen.dart`, `teleconsult_booking_screen.dart`, `async_messaging_screen.dart`, `pre_consultation_screen.dart`), 3 services (`teleconsult_service.dart`, `messaging_service.dart`, `pre_consultation_ai_service.dart`), 1 widget (`consultation_card.dart`), 3 migrations (`20260827003500_teleconsult.sql`, `20260828010000_teleconsult_ai.sql`, `20260828024000_async_messaging.sql`).

Fichiers inspectés : l'intégralité du dossier ci-dessus, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `auth_provider.dart`), plus `20260827000200_profiles.sql` et `20260827005500_professionals.sql` pour tracer un gap RLS découvert en cours d'audit (voir §3.2).

### 1.2 Défauts constatés

1. **5 défauts de compilation distincts sur 3 fichiers — le module entier ne compilait pas.** Une première dans cet audit : les deux précédents défauts de compilation (C38/Module 11, C44/Module 13) touchaient chacun un seul fichier. Le détail complet est en §3.1 (C59).
2. **Embed PostgREST invalide** — `TeleconsultService.getConsultationsForUser()`/`getConsultation()` embarquaient `professionals:professional_id(full_name, specialty)` ; `specialty` n'existe pas sur `profiles` (elle vit sur `professional_profiles`, table distincte). Même motif exact que C48/C52 (Modules 13/14) : PostgREST rejette la requête dans son intégralité. Voir C60.
3. **Gap RLS systémique, jamais rencontré avant ce module** — `public.profiles` ne porte qu'une policy `profiles_select_own` (`auth.uid() = id`) depuis le Module 1 ; aucune autre policy de lecture n'existe. Tout embed vers `profiles` pour afficher le nom d'un AUTRE utilisateur revient silencieusement `null`. Voir C61.
4. **Écran de réservation, écran principal du cahier, entièrement non fonctionnel avec des données réelles** — `TeleconsultBookingScreen` proposait une liste de professionnels codée en dur (`_mockProfessionals`, IDs `pro_1`/`pro_2`/`pro_3`, pas des UUID). Voir C62.
5. **Récurrence du motif « rôle RLS inatteignable »** (3ème occurrence, après Module 13/marketplace et Module 14/financing) sur `pre_consultation_sessions`/`decision_tree_nodes`. Voir C63.
6. **Aucun point d'entrée de navigation** vers `/teleconsult`/`/teleconsult/professional` — 15ème occurrence de la série D6, avec une particularité : deux routes racines distinctes selon le rôle. Voir §3.4.
7. **Écart de périmètre majeur avec le cahier, à risque médico-légal** — le sous-système « pré-consultation IA » (décision tree + analyse de symptômes) est un système factice qui, s'il était présenté comme faisant partie de CNS, contreviendrait à RG-CNS-01/02. Voir §2 et §3.3.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Écart de périmètre majeur — arbitré avec le porteur du projet

Le cahier décrit le Module 15 (CNS) ainsi : *« Offrir un canal d'information et d'orientation encadré, strictement distinct d'un service de diagnostic médical [...] l'IA informe, le professionnel décide. »* Fonctionnalités clés attendues : fiches d'information médicament validées par un pharmacien, assistant conversationnel limité à l'explication de vocabulaire et à l'orientation, mise en relation directe (chat, appel) **avec le pharmacien de l'officine choisie**, repérage de situations urgentes avec orientation vers les services de santé. Écrans principaux attendus : Fiche d'information médicament / Chat avec le pharmacien / Assistant d'orientation générale.

Le code trouvé sous `teleconsult/` ne correspond à AUCUN de ces trois écrans. C'est un système complet de téléconsultation vidéo avec calendrier (réservation, créneaux récurrents, statuts confirmée/terminée/annulée/manquée, lien de visio), mettant en relation un patient avec n'importe quel compte de rôle `professionnel` — pas spécifiquement le pharmacien d'une officine choisie — plus un sous-système de « pré-consultation IA » distinct (arbre de décision + analyse de symptômes).

Ce sous-système de pré-consultation, en particulier, est explicitement commenté **« Mock AI »** dans le code (`pre_consultation_ai_service.dart:analyzeSymptoms()`) : il génère, via `Random()` et une correspondance de mots-clés naïve sur texte libre, des « possible_conditions » (Infection/Allergie/Inflammation), un niveau d'urgence (1 à 5), une spécialité médicale suggérée (Cardiologie/Dermatologie/Pédiatrie/Gynécologie...), et affiche au patient un bandeau **« ⚠️ URGENCE - Consultez immédiatement »** quand `is_critical` est vrai. RG-CNS-01 (Critique) interdit explicitement à l'assistant de formuler « à aucun moment une recommandation de posologie, de diagnostic ou de choix thérapeutique individualisé » ; RG-CNS-02 (Critique) exige que toute réponse générée « s'appuie exclusivement sur des contenus validés par un pharmacien référent et versionnés dans le référentiel produit ». Ce sous-système, tel quel, ne respecte ni l'une ni l'autre — et ressemble bien davantage, dans son intention (triage de symptômes, niveau d'urgence, orientation spécialité), au **Module 17 (TRI — Triage & Orientation d'urgence, RG-TRI-01/02/03)**, module du cahier distinct de CNS et non encore audité.

**Arbitrage porteur du projet (AskUserQuestion, 29/08/2026)** : *« Corriger la compilation, ne pas exposer »* — les défauts de compilation du sous-système pré-consultation IA sont corrigés (l'application entière doit pouvoir compiler), mais il reste volontairement non routé, donc inatteignable pour tout utilisateur réel. Le sous-système téléconsultation vidéo proprement dit (réservation, calendrier, détail, messagerie) a été corrigé et exposé : il ne génère aucun contenu et met simplement en relation directe un patient et un professionnel, il ne contrevient donc à aucune RG-CNS en tant que tel. Voir registre **D26**.

### 2.2 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-CNS-01** | L'assistant ne formule jamais de diagnostic/posologie/choix thérapeutique individualisé | 🔴 Le sous-système pré-consultation IA violerait cette règle s'il était exposé — laissé non routé (D26). Le flux de téléconsultation vidéo lui-même ne génère aucun contenu, donc non concerné |
| **RG-CNS-02** | Tout contenu généré s'appuie exclusivement sur du contenu validé par un pharmacien référent, versionné | 🔴 Idem — le « décision tree » et l'« analyse de symptômes » actuels sont entièrement factices (`Random()`), aucun référentiel versionné n'existe |

### 2.3 Fonctionnalités clés et écrans principaux du cahier

| Fonctionnalité/écran (cahier) | Constat |
|---|---|
| Fiches d'information médicament validées par pharmacien | 🔴 Absent — aucune trace dans le code |
| Assistant conversationnel (vocabulaire + orientation, non-diagnostique) | 🔴 Absent tel que décrit — ce qui existe (pré-consultation IA) est d'une nature différente et non conforme, laissé non exposé |
| Chat avec le pharmacien de l'officine choisie | 🟡 Un équivalent existe (`AsyncMessagingScreen`, messagerie patient↔professionnel), mais avec n'importe quel compte `professionnel`, pas spécifiquement le pharmacien d'une officine choisie par le patient |
| Repérage de situations urgentes avec orientation | 🔴 Ce qui s'en approche (pré-consultation IA, `is_critical`) est factice et non exposé |
| *(hors cahier CNS, construit à la place)* Réservation/calendrier de téléconsultation vidéo | 🟢 Construit, corrigé et fonctionnel ce module — ne correspond à aucun écran principal du cahier CNS tel que rédigé |

---

## 3. Sécurité & résilience

### 3.1 Défauts de compilation (C59)

1. `teleconsult_detail_screen.dart` : `SupabaseService()` utilisé (lignes 57/59, calcul de `isProfessional`/`isPatient`) sans import de `supabase_service.dart` → `Undefined name 'SupabaseService'`.
2. `async_message.dart` (modèle) : `bool get isMine => senderId == SupabaseService().currentUser?.id;` sans import → même erreur, cette fois dans un fichier de modèle transverse.
3. `pre_consultation_screen.dart` : `final options = (currentNode.options['options'] as List?) ?? [];` déclaré comme statement à l'intérieur d'un spread de liste (`} else ...[ ... ]`) — une déclaration de variable locale n'est pas un élément de collection valide en Dart (seuls `if`/`for`/spread `...` le sont).
4. Même fichier : `provider._currentNodeId` — accès à un champ privé d'une AUTRE classe depuis un AUTRE fichier. En Dart, `_` limite la portée à la bibliothèque (le fichier), pas seulement à la classe : inaccessible depuis l'écran, quelle que soit la visibilité voulue.
5. Même fichier : `provider.decisionTree.firstWhere((n) => ..., orElse: () => provider.decisionTree.isNotEmpty ? provider.decisionTree.first : null)` — la signature de `firstWhere` exige que `orElse` retourne `DecisionTreeNode` (non-nullable) ; le ternaire peut retourner `null` → incompatibilité de type.

Corrigé : imports ajoutés (1, 2) ; `PreConsultationProvider` expose désormais `currentNodeId` (getter public) et `currentNode` (getter dérivé, ne retourne `null` que si l'arbre de décision est réellement vide, sans le défaut de typage de l'ancien `firstWhere`) — l'écran consomme ces deux getters plutôt que le champ privé (3, 4, 5).

### 3.2 Gap RLS systémique sur `profiles` (C61)

`public.profiles` ne porte qu'une policy de lecture, `profiles_select_own` (`using (auth.uid() = id)`, posée au Module 1). Aucune autre policy de select n'existe nulle part dans le projet — vérifié par recherche exhaustive sur toutes les migrations. Conséquence : tout embed PostgREST vers `profiles` pour afficher le nom d'un AUTRE utilisateur revient `null`, silencieusement (pas d'erreur réseau, juste un champ vide dans la réponse). Ce défaut existait déjà potentiellement pour tout module antérieur affichant un nom de compte individuel, mais ne s'était jamais manifesté : tous les modules précédents affichaient des noms d'OFFICINE (`pharmacies`, table déjà publique en lecture), jamais de compte individuel patient/professionnel. CNS est le premier module de cet audit à mettre directement en relation deux comptes individuels.

Corrigé par deux policies étroites plutôt qu'un accès public généralisé à `profiles` (un patient ou un pharmacien ordinaire n'a aucune raison d'être découvrable par n'importe qui) :

```sql
-- Annuaire des professionnels — nécessaire à la découverte avant réservation
create policy "profiles_select_professionals_public" on public.profiles
  for select to authenticated
  using (role = 'professionnel');

-- Un professionnel voit un patient uniquement s'ils partagent une
-- consultation ou un message échangé
create policy "profiles_select_patient_counterpart" on public.profiles
  for select to authenticated
  using (
    exists (select 1 from public.consultations c
            where c.patient_id = profiles.id and c.professional_id = auth.uid())
    or exists (select 1 from public.async_messages m
               where m.patient_id = profiles.id and m.professional_id = auth.uid())
  );
```

Justification de l'asymétrie : un compte `professionnel` propose un service de téléconsultation par nature découvrable (à l'identique d'une officine, déjà publique) ; un patient n'est pas un profil public — sa visibilité par un professionnel reste strictement bornée à une relation de soin réelle déjà établie (consultation ou message), jamais plus large.

### 3.3 Sous-système pré-consultation IA — risque médico-légal (D26)

Voir §2.1 pour l'analyse complète. Décision : compilation corrigée, sous-système laissé volontairement non routé. Un commentaire de bloc explicite (« ⚠️ NE PAS ROUTER SANS ARBITRAGE ») a été ajouté en tête de `pre_consultation_screen.dart` pour empêcher qu'un futur développeur/session l'ajoute au routeur sans revoir cette décision.

### 3.4 Navigation (D6, 15ème occurrence)

Aucune entrée vers `/teleconsult` ni `/teleconsult/professional` dans `dashboard_screen.dart` (menu unique de l'application). Particularité par rapport aux 14 occurrences précédentes de ce motif : CNS a DEUX routes racines distinctes selon le rôle connecté (patient → `/teleconsult`, `professionnel` → `/teleconsult/professional`), alors que chaque module précédent n'avait qu'une seule route montrée à tout le monde (le menu lui-même reste non filtré par rôle depuis l'origine — limite pré-existante, hors périmètre de ce correctif ponctuel). Plutôt que de n'exposer qu'une moitié du motif D6, l'entrée « Téléconsultation » est désormais calculée dans `_effectiveNavItems()` à partir d'`AuthProvider.userRole` plutôt qu'ajoutée en dur à la liste statique `_navItems`.

### 3.5 RLS — récurrence du motif « rôle inatteignable » (C63)

`pre_consultation_sessions`/`decision_tree_nodes` (migration `20260828010000_teleconsult_ai.sql`) testaient `profiles.role in ('admin', 'staff')`/`role = 'admin'` — même défaut que C49, remplacé par `is_gsg_admin()`. Impact réel nul tant que le sous-système reste non exposé (§3.3), mais corrigé par cohérence et parce que l'écriture (`seedDefaultTree()`) était de toute façon bloquée pour n'importe quel compte, y compris un membre réel du back-office.

---

## 4. Optimisation & améliorations

- **Réservation branchée sur de vrais professionnels (C62)** : `TeleconsultService.getAvailableProfessionals()` interroge `professional_profiles` réellement vérifiés (`is_verified = true`) et ouverts à de nouveaux patients (`is_accepting_new_patients = true`), avec nom/téléphone embarqués. L'écran affiche un état de chargement et un état vide explicite (« Aucun professionnel disponible pour le moment ») plutôt que de planter sur une liste vide.
- **Aucun mode hors-ligne** n'a été construit ce module (ni lecture ni écriture) — même famille que C13/C21/C28/C33/C46, mais ici une extension différée plutôt qu'un choix assumé documenté ; à considérer pour une prochaine passe si le porteur du projet le souhaite (lecture seule des consultations à venir serait le candidat naturel, à l'identique du Module 8/PAY).
- **`request_detail_screen`-style TODO resté ouvert** : le bouton « Rejoindre » (visio) de `teleconsult_detail_screen.dart` reste un `TODO: open meeting URL` — cohérent avec l'absence de tout provider de visioconférence réel dans le projet (aucune intégration Jitsi/Twilio/Agora trouvée), non corrigé ce module (nécessiterait une décision d'architecture à part entière, hors périmètre audit-et-corrige).

---

## 5. Documentation API / conformité aux règles métier

**`TeleconsultService.getAvailableProfessionals()`** *(nouveau)* — retourne les comptes `professional_profiles` avec `is_verified = true` et `is_accepting_new_patients = true`, nom/téléphone embarqués depuis `profiles` (nécessite la policy `profiles_select_professionals_public`, §3.2).

**`TeleconsultProvider.loadProfessionals()`/`professionals`** *(nouveau)* — état chargement/erreur standard, consommé par `TeleconsultBookingScreen`.

**`PreConsultationProvider.currentNodeId`/`currentNode`** *(nouveau)* — remplace l'accès direct au champ privé `_currentNodeId` depuis l'écran (impossible en Dart, portée de bibliothèque).

**RLS `profiles`** *(migration `20260829042000_teleconsult_module_fixes.sql`)* — voir §3.2 pour le détail des deux nouvelles policies et leur justification.

---

## 6. Scénarios de test (voir le protocole de test E2E dédié, `PharmaConnect_Module15_Protocole_Test_E2E.md`)

1. Démarrage/compilation — préalable bloquant, cette fois pour des raisons de syntaxe/portée plutôt que de routes dupliquées.
2. RLS `profiles` — un professionnel voit son propre nom partout ; un patient voit le nom d'un professionnel avant toute réservation (annuaire) ; un professionnel ne voit le nom d'un patient qu'après une consultation/un message partagé, jamais avant.
3. Réservation — liste de professionnels réelle, plus de mock ; état vide si aucun professionnel disponible.
4. Chargement des consultations (liste/détail) — embed emboîté `professional_profiles(specialty)`.
5. Messagerie asynchrone.
6. Confirmation que `pre_consultation`/`PreConsultationScreen` reste bien inaccessible (aucune route, aucun lien).

---

## 7. Livrables de ce module

Nouveau : `supabase/migrations/20260829042000_teleconsult_module_fixes.sql`.
Modifiés : `lib/modules/teleconsult/screens/teleconsult_detail_screen.dart`, `lib/modules/teleconsult/models/async_message.dart`, `lib/modules/teleconsult/providers/pre_consultation_provider.dart`, `lib/modules/teleconsult/screens/pre_consultation_screen.dart`, `lib/modules/teleconsult/services/teleconsult_service.dart`, `lib/modules/teleconsult/models/consultation.dart`, `lib/modules/teleconsult/providers/teleconsult_provider.dart`, `lib/modules/teleconsult/screens/teleconsult_booking_screen.dart`, `lib/modules/dashboard/dashboard_screen.dart`.
`PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A24 ; C59-C63 ; D26 ; D6 annoté d'une quinzième occurrence).
Ce rapport, le PV de recette provisoire, le protocole de test E2E.

---

**Le module Téléconsultation (CNS) est-il totalement clos et validé pour passer au suivant ?**
