# PharmaConnect — PV de recette, Module 15 (CNS — réservé ici au sous-système téléconsultation, `lib/modules/teleconsult/`)

**Date d'émission :** 29/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module15_Protocole_Test_E2E.md`), en priorité absolue le Scénario 1 (compilation) : ce module ne compilait pas du tout avant correctif, sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 15 à l'issue de son inspection, de ses correctifs, et de l'arbitrage de périmètre D26, et servir de base à la décision de recette par le porteur du projet.

## 2. Périmètre couvert

Correctif de 5 défauts de compilation distincts sur 3 fichiers (deux imports manquants, une syntaxe de collection invalide, un accès à un champ privé depuis un autre fichier, une incompatibilité de type sur `firstWhere` — le module entier ne compilait pas avant ce correctif), correctif d'un embed PostgREST invalide bloquant les deux méthodes de lecture principales du module, découverte et correctif d'un gap RLS systémique sur `public.profiles` (aucune policy ne permettait à un utilisateur de voir le nom d'un autre, jamais rencontré avant ce module), remplacement d'une liste de professionnels mockée (identifiants non-UUID) par une requête réelle sur les comptes professionnels vérifiés, correctif RLS du motif « rôle inatteignable » (3ème occurrence) sur le sous-système de pré-consultation, entrée de navigation « Téléconsultation » sensible au rôle (15ème occurrence de la série D6, première à nécessiter deux routes distinctes). Hors périmètre, par arbitrage explicite du porteur du projet (D26) : le sous-système « pré-consultation IA » (contenu factice à risque de non-conformité RG-CNS-01/02) reste corrigé pour compiler mais volontairement non routé — aucun patient n'y est exposé. Écart de périmètre non résolu et non résoluble dans le cadre d'un audit-et-corrige : le code construit sous `teleconsult/` ne correspond à aucun des trois écrans principaux du cahier CNS (fiche d'information médicament, chat avec le pharmacien de l'officine, assistant d'orientation générale) — voir D26 pour le détail complet.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 5 modèles, 2 providers, 5 écrans, 3 services, 1 widget, 3 migrations, plus les points d'intégration transverses (app_router, dashboard_screen, auth_provider) et deux migrations tierces (profiles, professionals) pour tracer le gap RLS |
| Analyse comparative au cahier de conception | ✅ Oui | RG-CNS-01, RG-CNS-02, 4 fonctionnalités clés, 3 écrans principaux — écart de périmètre majeur identifié et arbitré (D26) |
| Vérification syntaxique statique (équilibrage accolades/parenthèses + scan d'octets de contrôle) | ✅ Oui | Script dédié, exécuté après chaque édition, sur l'ensemble des fichiers Dart et SQL modifiés/créés ce module |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Chemins de réservation, chargement de consultations, RLS `profiles`, retracés intégralement |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas de SDK Flutter/Dart disponible |
| Tests unitaires/`flutter test` | ❌ Non | Même limite |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Pas d'accès appareil/émulateur (limite documentée depuis le Module 1) |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, pas par exécution. Le Scénario 1 du protocole E2E (compilation) doit être exécuté en priorité absolue et sans exception : ce module ne compilait pas du tout avant correctif (5 défauts distincts, C59), la première fois dans cet audit qu'un module entier — pas un seul fichier — était syntaxiquement invalide.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Défauts de compilation (5, sur 3 fichiers) | Rapport d'audit §3.1 (C59) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1, priorité absolue |
| Embed PostgREST invalide (`specialty` sur `profiles`) | Rapport d'audit §3.1 point 2 (C60) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 4 |
| Gap RLS systémique sur `profiles` (visibilité de nom) | Rapport d'audit §3.2 (C61) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 2, le plus important sur le plan de la vie privée |
| Réservation sur données réelles (plus de mock) | Rapport d'audit §4 (C62) | 🟢 Construit (revue de code) — à confirmer par le Scénario 3 |
| RLS pré-consultation (`is_gsg_admin()`) | Rapport d'audit §3.5 (C63) | 🟢 Corrigé (revue de code) — impact réel nul tant que non exposé |
| Navigation — entrée « Téléconsultation » sensible au rôle (série D6, 15ème occurrence) | Rapport d'audit §3.4 | 🟢 Corrigé (revue de code) |
| Garde de routage rôle-dépendant (`/teleconsult/professional` inatteignable pour un non-professionnel) | Addendum §5 bis, Point 1 (C64) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 8 |
| Minimisation des données personnelles de l'annuaire des professionnels (`phone` retiré) | Addendum §5 bis, Point 2 (C65) | 🟢 Corrigé (revue de code) — réserve résiduelle non levée, voir D27 et §5.7 |
| Isolation du sous-système Mock AI (absence de route + absence d'invocation croisée) | Addendum §5 bis, Point 3 | 🟢 Reconfirmé par recherche exhaustive (pas de changement de comportement) |
| RG-CNS-01 (jamais de diagnostic/posologie) | Rapport d'audit §2.2 | 🟡 Non applicable au flux exposé (aucun contenu généré) ; violée par le sous-système laissé non exposé (D26) |
| RG-CNS-02 (contenu validé par pharmacien référent) | Rapport d'audit §2.2 | 🟡 Idem |
| Fiche d'information médicament | Rapport d'audit §2.3 | 🔴 Non implémenté |
| Chat avec le pharmacien de l'officine choisie | Rapport d'audit §2.3 | 🟡 Un équivalent existe (messagerie patient↔professionnel générique), pas scopé à l'officine du patient |
| Assistant d'orientation générale, non-diagnostique | Rapport d'audit §2.3 | 🔴 Non implémenté conforme — le sous-système apparenté reste non exposé (D26) |
| Mode hors-ligne | Rapport d'audit §4 | 🔴 Non construit ce module |

## 5. Réserves formelles

1. **Aucun des scénarios du protocole de test E2E n'a été exécuté**, en particulier le Scénario 1 (compilation) : ce module ne compilait pas du tout avant correctif — bloquant pour l'application entière, pas seulement ce module.
2. **Écart de périmètre majeur non résolu (D26)** : le code construit sous `teleconsult/` ne correspond à aucun des trois écrans principaux du cahier CNS. Le sous-système le plus proche d'une des fonctionnalités attendues (orientation face à des symptômes) est un système factice (`Random()`) laissé volontairement non exposé — RG-CNS-01/02 restent non satisfaites par ce module dans son ensemble. Une décision de fond (retravailler ce sous-système pour le rendre conforme et le cadrer comme un futur Module 17/TRI dédié, ou le retirer purement) reste à prendre avant toute clôture définitive de CNS au sens du cahier.
3. **Chat avec le pharmacien de l'officine choisie** : la messagerie construite met en relation un patient avec n'importe quel compte `professionnel`, pas spécifiquement le pharmacien de l'officine que le patient a choisie — écart non corrigé ce module (nécessiterait de scoper la réservation/messagerie à une officine, absent du modèle de données `consultations` actuel, qui ne porte aucun `pharmacy_id`).
4. **Aucun mode hors-ligne** n'a été construit ce module — limite ouverte, non arbitrée explicitement avec le porteur du projet.
5. **Bouton « Rejoindre » (visio) non implémenté** — `TODO` resté en l'état, aucun provider de visioconférence réel dans le projet.
6. **Aucune migration/RLS/mise à jour de schéma n'a été exécutée sur un environnement réel** — les correctifs sont validés par relecture de code uniquement.
7. **(Ajoutée, 2ème passe de clôture) Granularité ligne de la RLS Postgres sur `profiles.phone`** (registre, item D27) : la suppression de `phone` de `getAvailableProfessionals()` (C65) ferme l'exposition applicative constatée, mais pas un accès direct à l'API REST Supabase par un utilisateur authentifié techniquement outillé pour le faire. Fermeture hermétique (vue dédiée ou GRANT/REVOKE colonne) non entreprise ce module, faute d'environnement pour vérifier l'absence de régression sur la relecture de son propre profil. Réserve ouverte, non silencieuse — décision explicite à prendre avec le porteur du projet avant mise en production.

## 5 bis. Addendum — réponse au 2ème refus de clôture (29/08/2026)

Le porteur du projet a refusé la clôture initiale et soulevé trois points de contrôle précis, plus une demande de traitement du protocole E2E « comme pour les modules précédents ». Chacun a été traité par relecture ciblée et recherche exhaustive (grep), pas de mémoire, avant réponse.

**Point 1 — Sécurisation du routage rôle-dépendant (Patient vs Professionnel).**
Vérification RLS : le texte des 4 policies de `consultations` (`Patients can view/update/insert own consultations`, `Professionals can view/update assigned consultations`) a été relu directement — chacune compare `auth.uid()` à `patient_id` ou `professional_id` selon le cas. Un compte patient ne peut structurellement jamais satisfaire `auth.uid() = professional_id` : aucune fuite de DONNÉES n'était possible même avant correctif. En revanche, un vrai défaut de cohérence d'INTERFACE a été confirmé par lecture du code : `app_router.dart` construit `/teleconsult/professional` sans jamais vérifier le rôle réel (`TeleconsultListScreen(asProfessional: true)`, statique). Corrigé (C64) : un garde de rôle dans `TeleconsultListScreen.build()` affiche un écran « Accès réservé » et bloque l'appel réseau `loadConsultations()` correspondant si `asProfessional == true` et `AuthProvider.userRole != UserRole.professionnel`. Voir Scénario 8 du protocole E2E.

**Point 2 — Annuaire des professionnels réels, sans fuite de données personnelles non médicales.**
Confirmé par relecture exhaustive : le filtre strict (`is_verified = true`, `is_accepting_new_patients = true`) était déjà correctement appliqué côté requête (C62) — ce point était déjà couvert. La partie non couverte a été identifiée : `getAvailableProfessionals()` embarquait `phone` sans qu'aucun écran ne l'affiche (vérifié dans `teleconsult_booking_screen.dart`). Corrigé (C65) : `phone` retiré de la sélection. Réserve non levée par ce correctif et documentée explicitement, pas silencieusement acceptée (registre, item D27) : la RLS Postgres autorise par LIGNE, pas par colonne — la policy `profiles_select_professionals_public` (nécessaire par ailleurs à l'affichage du nom d'un professionnel déjà lié à une consultation) resterait techniquement capable, via un appel direct à l'API REST (hors de l'application), d'exposer `phone`. Vérifié que `pharmacies.phone` (déjà public à tout authentifié depuis le Module 1) n'est PAS un précédent transposable : une officine est une entité professionnelle dont le numéro est par nature destiné à être public, alors qu'un `profiles.phone` de compte `professionnel` est une donnée personnelle également utilisée pour l'authentification (OTP SMS). Une fermeture hermétique (vue dédiée ou GRANT/REVOKE colonne sur `profiles`) toucherait un chemin partagé avec la relecture de son PROPRE profil (`ProfileService.upsertProfile()`) et n'a pas été entreprise sans environnement disponible pour vérifier l'absence de régression.

**Point 3 — Isolation du sous-système « Mock AI ».**
Le porteur du projet a référencé le garde-fou comme situé en tête de `pre_consultation_ai_service.dart` ; il avait en réalité été placé en tête de `pre_consultation_screen.dart` lors de la première passe. Recherche exhaustive exécutée (pas relue de mémoire) : `app_router.dart` ne déclare aucune route vers `PreConsultationScreen` (0 occurrence de `PreConsultation`/`pre_consultation`) ; aucun des 6 fichiers du flux téléconsultation exposé (liste, détail, réservation, messagerie, service, provider) n'importe ni ne référence `PreConsultationAIService`, `PreConsultationProvider` ou `PreConsultationScreen` (0 occurrence croisée). L'isolation structurelle est donc confirmée sur les deux axes demandés (absence de route ET absence d'invocation indirecte). L'avertissement documentaire a été dupliqué en tête de `pre_consultation_ai_service.dart` (fichier explicitement nommé par le porteur du projet) et de `pre_consultation_provider.dart`, en plus de celui déjà présent sur l'écran — défense en profondeur, aucun changement de comportement.

**Protocole de validation E2E.**
Traité à l'identique des modules précédents (Module 14 notamment) : `flutter analyze`, `flutter build`, tests réels et exécution sur base/appareil réels restent hors de portée de cette session (A1, A24, inchangé). Le Scénario 8 a été ajouté au protocole (garde de routage) et les Scénarios 3 et 7 étendus pour couvrir explicitement les Points 2 et 3 ci-dessus. Trace manuelle des trois points de contrôle effectuée ci-dessus par relecture directe du texte des policies et recherche exhaustive plutôt que par la seule mémoire de la première passe — même standard que la trace manuelle acceptée pour la clôture du Module 14.

**Fichiers modifiés dans cet addendum** : `teleconsult_list_screen.dart` (C64), `teleconsult_service.dart` (C65), `teleconsult_booking_screen.dart` (commentaire, C65), `pre_consultation_ai_service.dart` (avertissement dupliqué), `pre_consultation_provider.dart` (avertissement dupliqué). Tous relus, équilibrage accolades/parenthèses et scan d'octets de contrôle exécutés — aucune anomalie.

## 6. Décision de recette

☐ **Recette prononcée sans réserve** — nécessite l'exécution complète du protocole de test E2E, Scénario 1 en priorité absolue.
☐ **Recette prononcée avec réserves** — lister les réserves acceptées et la date limite de levée.
☐ **Recette refusée / reportée** — lister les motifs bloquants.

*Case à cocher et à signer par le porteur du projet après exécution du protocole de test E2E.*

Nom : _______________________ Date : _______________ Signature : _______________________

---

**Le module Téléconsultation (CNS) est-il totalement clos et validé pour passer au suivant ?**
