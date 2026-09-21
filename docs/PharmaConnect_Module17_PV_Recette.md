# PharmaConnect — PV de recette, Module 17 (TRI — réservé ici au système de triage interne hospitalier, `lib/modules/triage/`)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module17_Protocole_Test_E2E.md`), en priorité absolue le Scénario 1 (compilation ET premier rendu de chaque écran, ce module comptant à la fois des défauts de compilation et un défaut d'exécution invisible à la seule compilation), sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 17 à l'issue de son inspection, de ses correctifs, et des deux arbitrages de périmètre/architecture (D29, D30), et servir de base à la décision de recette par le porteur du projet.

## 2. Périmètre couvert

Correctif de 6 défauts de compilation/exécution regroupés (fichier modèle `TriageRule` entièrement absent malgré un usage extensif ailleurs — le plus sévère ; 3 imports manquants causant 3 identifiants non définis dans un fichier ; un accesseur inexistant ; une variable non définie ; un provider jamais déclaré causant un crash à l'exécution — nouvelle classe de défaut pour cet audit ; un formulaire de retour IA au bouton de soumission structurellement désactivé), correctif d'une nouvelle classe de bug pour cet audit (shadowing de route go_router, `/triage/new` capturée par `/triage/:id`), ajout d'une policy DELETE manquante sur `triage_patients`, correctif de 2 nouvelles occurrences du motif « rôle inatteignable » dans `triage_ai.sql`, câblage complet de la navigation du module (17ème occurrence de la série D6, incluant `TriageAIScreen` auparavant sans route ni bouton d'accès nulle part). Hors périmètre, par arbitrage explicite du porteur du projet (D29) : le questionnaire d'auto-évaluation patient réellement décrit par le cahier pour TRI (RG-TRI-01/02/03) n'est pas construit — le code trouvé et corrigé ce module est un système de triage interne hospitalier distinct, sans correspondance stricte avec aucun module cahier identifié. Également hors périmètre, par arbitrage explicite (D30) : l'accès RLS non scopé par hôpital (tout compte `role='professionnel'` peut voir/modifier les dossiers de triage de n'importe quel hôpital du réseau) reste en l'état, faute des fondations nécessaires (Org Registry, D2, jamais câblé).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 4+1 modèles (dont le modèle manquant, recréé), 2 providers, 2 services, 4 écrans, 1 widget, 2 migrations, plus les points d'intégration transverses (app_router, dashboard_screen, app.dart, profiles) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-TRI-01/02/03, 4 fonctionnalités clés/écrans principaux — écart de périmètre majeur identifié et arbitré (D29), Module 23/HOP explicitement vérifié et écarté comme correspondance alternative |
| Recherche exhaustive de nom de fichier (questionnaire patient) | ✅ Oui | Liste récursive complète de `lib/modules` + filtrage par mots-clés — zéro résultat pertinent |
| Vérification syntaxique statique (équilibrage accolades/parenthèses + scan d'octets de contrôle) | ✅ Oui | Script dédié `.dart` (`/home/claude/check_balance.py`) et script `.sql` distinct (`/tmp/balance_check.py`), exécutés après chaque édition sur l'ensemble des fichiers modifiés/créés ce module |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Intake infirmier, évaluation clinique, suggestion IA, routage, policies RLS des 4 tables concernées, retracés intégralement |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas de SDK Flutter/Dart disponible |
| Tests unitaires/`flutter test` | ❌ Non | Même limite |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Pas d'accès appareil/émulateur (limite documentée depuis le Module 1) |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, pas par exécution. Le Scénario 1 du protocole E2E (compilation ET premier rendu de chaque écran) doit être exécuté en priorité absolue et sans exception : ce module comptait à la fois des défauts de compilation classiques ET un défaut d'exécution invisible à la seule compilation (`ProviderNotFoundException`), une combinaison inédite dans cet audit.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Fichier modèle `TriageRule` manquant | Rapport d'audit §3.1 point 1 (C68) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1, priorité absolue |
| 3 imports manquants / identifiants non définis | Rapport d'audit §3.1 point 2 (C68) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1 |
| Accesseur `.isPast` inexistant | Rapport d'audit §3.1 point 3 (C68) | 🟢 Corrigé (revue de code) |
| Variable `provider` non définie | Rapport d'audit §3.1 point 4 (C68) | 🟢 Corrigé (revue de code) |
| `TriageAIProvider` non déclaré (crash à l'exécution) | Rapport d'audit §3.1 point 5 (C68) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1, spécifiquement le premier rendu de `TriageAIScreen` |
| Formulaire de retour IA au bouton désactivé | Rapport d'audit §3.1 point 6 (C68) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| Shadowing de route `/triage/new`↔`/triage/:id` | Rapport d'audit §3.2 (C69) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 2, priorité absolue |
| Policy DELETE manquante sur `triage_patients` | Rapport d'audit §3.3 (C70) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 3 |
| RLS « rôle inatteignable » (2 occurrences) | Rapport d'audit §3.3 (C70) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 4 |
| Navigation — entrée « Triage » + route/bouton `TriageAIScreen` (série D6, 17ème occurrence) | Rapport d'audit §3.4 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| Questionnaire de pré-évaluation patient (RG-TRI-01/02/03) | Rapport d'audit §2.2-2.3 | 🔴 Non implémenté — hors périmètre arbitré (D29) |
| RLS scopée par hôpital | Rapport d'audit §3.5 | 🟡 Dette d'architecture consignée, non corrigée ce module (D30) — à confirmer comme limitation connue par le Scénario 5 |
| Fonctionnalité de transfert (`_showTransferDialog`) | Rapport d'audit §4 | 🔴 Stub vide, non construit ce module — modèle de données « hôpital cible » manquant |
| Mode hors-ligne | Rapport d'audit §4 | 🔴 Non construit ce module, cohérent avec la nature temps réel du module |

## 5. Réserves formelles

1. **Aucun des scénarios du protocole de test E2E n'a été exécuté**, en particulier le Scénario 1 (compilation ET premier rendu de chaque écran) — ce module comptait un défaut d'exécution (`ProviderNotFoundException`) qui n'aurait été détecté par aucune compilation statique, seulement par l'ouverture réelle de l'écran `TriageAIScreen`.
2. ~~**Écart de périmètre majeur non résolu (D29)**~~ — **Scellé formellement au 1er refus de clôture, voir §5 bis, point 1** : le questionnaire d'auto-évaluation patient réellement décrit par le cahier pour TRI (RG-TRI-01/02/03) reste entièrement absent du projet et son report est désormais formellement confirmé par le porteur du projet ; le sous-système de triage hospitalier interne est maintenu en l'état pour les équipes soignantes. Reste en 🟡 au registre (report assumé, pas une construction) — décision de fond sur le questionnaire patient toujours à prendre pour un futur module dédié.
3. ~~**Dette d'architecture RLS non résolue (D30)**~~ — **Scellé formellement au 1er refus de clôture, voir §5 bis, point 2** : l'accès aux dossiers de triage n'est scopé par aucune notion d'hôpital — confirmé par relecture directe des 2 migrations du module qu'aucun helper d'autorisation hospitalier n'existe. Formellement consigné comme dette différée explicitement dépendante de D2 (Kernel/Org Registry). Reste en 🟡 au registre — non résolu tant que D2 ne l'est pas.
4. **Fonctionnalité de transfert non fonctionnelle** (`_showTransferDialog`, stub vide) — signalée, non corrigée, faute d'un modèle de données « hôpital cible ».
5. **Aucune migration/RLS/mise à jour de schéma n'a été exécutée sur un environnement réel** — les correctifs sont validés par relecture de code uniquement.

## 5 bis. Addendum — réponse au 1er refus de clôture (30/08/2026)

Le porteur du projet a refusé la clôture initiale, demandé le scellement formel au registre des deux points d'arbitrage (D29, D30) et l'exécution prioritaire du protocole de validation E2E. Traité par mise à jour explicite du registre puis relecture ciblée directe du code et des migrations livrés à l'appareil (pas de mémoire), avant réponse.

**Point 1 — Écart de périmètre (D29), confirmation formelle.**
Le registre (item D29) documentait déjà l'arbitrage mais sans formule de confirmation explicite au 1er refus de clôture, contrairement au précédent établi pour D26/D28. Ajouté : une phrase de scellement actant que (a) le sous-système de triage hospitalier interne (ESI, infirmier) trouvé et corrigé ce module est maintenu en l'état pour les équipes soignantes, sans nouvelle construction ce tour ; (b) le questionnaire d'auto-évaluation patient grand public réellement décrit par le cahier pour TRI (RG-TRI-01/02/03) est formellement reporté à un futur module orienté patients, distinct du système hospitalier actuel. Aucun changement de code requis par ce point — seule une clarification documentaire.

**Point 2 — Dette d'architecture RLS (D30), confirmation formelle et re-vérifiée.**
Même traitement pour D30, avec une vérification technique supplémentaire (pas seulement documentaire) : relecture directe des 2 migrations du module (`20260827004500_triage.sql`, `20260828012000_triage_ai.sql`) pour confirmer qu'aucun helper d'autorisation hospitalier de type `is_pharmacy_staff` n'existe, et qu'aucune colonne `hospital_id` n'est présente sur aucune des 4 tables du module. Une colonne `gsg_org_id` de type **`text`** existe bien sur `triage_patients`/`triage_ai_analyses` (confirmé par `grep`, 4 occurrences dans les 2 migrations) — mais il s'agit d'une colonne de compatibilité Kernel non exploitée par aucune policy RLS du module, distincte de `profiles.gsg_org_id` (type `uuid`, également non exploitable tant que le Kernel n'est pas branché, voir D2). Confirme sans ambiguïté que la dette D30 n'a aucune fondation partielle déjà en place sur laquelle un correctif RLS ciblé aurait pu s'appuyer — le registre est mis à jour en conséquence avec le résultat de cette vérification.

**Point 3 — Protocole de validation E2E prioritaire (Scénario 1), trace manuelle directe.**
`flutter analyze`/`flutter build`/exécution réelle restent hors de portée de cette session (A1, A26, inchangé). Une trace manuelle directe a été effectuée sur le Scénario 1 (compilation ET premier rendu de chaque écran, seul scénario capable de révéler le défaut d'exécution `ProviderNotFoundException` invisible à la seule compilation), par relecture des fichiers eux-mêmes plutôt que de la mémoire de la première passe, plus un ré-examen du Scénario 2 (routage) et du Scénario 5 (RLS hospitalière) directement liés aux deux points d'arbitrage ci-dessus :

- *Défaut 1 (`TriageRule` manquant)* : `class TriageRule extends Equatable` confirmé présent (ligne 13 de `triage_rules.dart`, fichier recréé). Vérification de balance syntaxique (accolades/parenthèses + octets de contrôle) : `OK`.
- *Défaut 2 (3 imports manquants)* : les 3 imports (`supabase_service.dart`, `triage_patient.dart`, `triage_assessment.dart`) confirmés présents en tête de `triage_detail_screen.dart` (lignes 10, 13, 14).
- *Défaut 3 (`.isPast`)* : plus aucune occurrence — `patient.status.isCompleted` confirmé aux deux sites d'usage (lignes 374, 414).
- *Défaut 4 (variable `provider` non définie)* : `context.read<TriageProvider>().loadPatient(...)` confirmé aux 3 sites d'usage (lignes 41, 661, 761) — plus aucune référence à une variable `provider` non qualifiée.
- *Défaut 5 (`TriageAIProvider` non déclaré — le défaut d'exécution)* : `ChangeNotifierProvider(create: (_) => TriageAIProvider())` confirmé présent dans le `MultiProvider` de `app.dart`, aux côtés de `TriageProvider()`, avec le commentaire d'audit expliquant le défaut d'origine. C'est le seul défaut de ce module qu'une exécution réelle de l'application (ouverture de `TriageAIScreen`) peut à elle seule confirmer comme définitivement clos — la relecture de code confirme la présence de la déclaration, pas l'absence de toute autre régression d'exécution possible.
- *Défaut 6 (formulaire de retour IA)* : champs `_feedbackPriority`/`_feedbackDepartment` confirmés au niveau `State` (lignes 32-33), `setState()` confirmé dans les deux callbacks `onChanged` (lignes 314, 346), garde `context.mounted` confirmée avant le `SnackBar` post-soumission (ligne 359).
- *Scénario 2 (routage, C69)* : ordre de déclaration confirmé directement dans `app_router.dart` — `/triage/new` (ligne 716) déclarée avant `/triage/:id` (ligne 721), avec un commentaire d'audit explicite documentant le bug d'origine (shadowing) aux lignes 707-711. Nouvelle route `/triage/:id/ai` également confirmée (ligne 735).
- *Scénario 5 (RLS hospitalière, D30)* : voir Point 2 ci-dessus — confirmé qu'aucune isolation par hôpital n'existe, conformément à la dette documentée, sans découverte d'un mécanisme partiel qui aurait dû être exploité.

Vérification syntaxique complémentaire : les 6 fichiers touchés par ce module (`triage_rules.dart`, `triage_detail_screen.dart`, `triage_ai_screen.dart`, `app_router.dart`, `dashboard_screen.dart`, `app.dart`) et la migration `20260830044000_triage_module_fixes.sql` ont tous été repassés au script de vérification de balance dédié (`.dart` : `/home/claude/check_balance.py` ; `.sql` : `/tmp/balance_check.py`) — tous `OK`, aucune régression syntaxique introduite depuis la livraison initiale.

**Aucun écart de comptage ni erreur de documentation trouvé pendant cette relecture** (à la différence de l'addendum du Module 16, qui avait révélé une erreur de comptage 12→11) — les 6 sites de correctif, les 2 routes et les 2 policies RLS correspondent exactement à ce qui était documenté dans le rapport d'audit et ce PV avant cet addendum.

**Fichiers/documents relus pour cet addendum** : `lib/modules/triage/models/triage_rules.dart`, `lib/modules/triage/screens/triage_detail_screen.dart`, `lib/modules/triage/screens/triage_ai_screen.dart`, `lib/routes/app_router.dart`, `lib/modules/dashboard/dashboard_screen.dart`, `lib/app.dart`, `supabase/migrations/20260830044000_triage_module_fixes.sql`, et les 2 migrations d'origine du module (`grep` exhaustif de `hospital_id`/`is_hospital_staff`/`gsg_org_id`). Aucun changement de code supplémentaire requis par cet addendum — seules les confirmations et clarifications documentaires ci-dessus (registre et présent PV).

## 6. Décision de recette

☐ **Recette prononcée sans réserve** — nécessite l'exécution complète du protocole de test E2E, Scénario 1 en priorité absolue.
☐ **Recette prononcée avec réserves** — lister les réserves acceptées et la date limite de levée.
☐ **Recette refusée / reportée** — lister les motifs bloquants.

*Case à cocher et à signer par le porteur du projet après exécution du protocole de test E2E.*

Nom : _______________________ Date : _______________ Signature : _______________________

---

**Le module Triage (TRI) est-il totalement clos et validé pour passer au suivant ?**
