# PharmaConnect — PV de recette, Module 22 (FAM — PharmaConnect Family & Diaspora)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, avant arbitrage et clôture par le porteur du projet.

---

## 1. Objet

Constater l'état du Module 22 à l'issue de son inspection, de son analyse comparative, de sa vérification de sécurité, et de l'arbitrage de périmètre du porteur du projet (D37, D38, exposition en navigation), et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de l'ensemble des défauts RLS d'écriture/lecture trouvés sur les 3 migrations du module (`20260827005000_family.sql`, `20260828016200_gamification_family.sql`, `20260828023000_sos_notifications.sql`) : C101 (écritures manquantes sur `family_alerts`/`family_activity_log`/`family_challenges`/`family_activities`), C102 (SELECT patient manquant sur `family_alerts`, découvert par exécution réelle, bloquant silencieusement le DELETE par ailleurs valide), C103 (SELECT manquant sur `sos_acknowledgements`) ; correction d'un défaut fonctionnel de sécurité (C104, logique de résolution SOS explicitement factice) ; câblage d'un service de notification push réel préexistant (C105) ; correction d'un embed PostgREST invalide doublé d'un bug indépendant de profondeur JSON (C106) ; exposition en navigation de `/family` et `/family/sos` (20ème occurrence du motif D6). Hors périmètre, par arbitrage explicite du porteur du projet : le modèle souscripteur/bénéficiaire diaspora et le paiement international du cahier (D37, chantier de conception/fintech différé), et la recherche par nom/téléphone pour l'ajout d'un proche (D38, dette d'ergonomie différée, sans risque de sécurité).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 26 fichiers Dart (`lib/modules/family/`), 3 migrations propres au module, routage (`app_router.dart`), menu de navigation (`dashboard_screen.dart`) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-FAM-01/02 et les 4 écrans principaux, RG par RG et écran par écran — écart de périmètre radical confirmé et arbitré (D37) |
| Recherche exhaustive de terminologie cahier (`abonnement`/`diaspora`/`paiement`/`souscri`/`tarif`) | ✅ Oui | Une seule occurrence de « Diaspora » dans tout le module (libellé UI statique), aucune trace d'abonnement/paiement/souscription |
| Vérification croisée d'un constat de registre antérieur (D28, Module 16) | ✅ Oui | `gamification_family.sql` confirmée non orpheline dans l'absolu — consommée par du code FAM réel (`family_challenge_provider.dart` et 3 autres fichiers) ; correction de précision actée au registre |
| Balayage du câblage complet de FAM-1 au-delà du périmètre initial de l'Étape 1 | ✅ Oui | 2 tables supplémentaires (`family_challenges`, `family_activities`) portant le même motif détectées en cours de correctif, non repérées à l'ouverture |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Protocole à 12 scénarios (écritures FAM-1, lecture SOS FAM-2, étanchéité tiers) exécuté sur le schéma complet des ~85 migrations, `GRANT` par défaut Supabase explicitement reproduits — voir rapport d'audit §7.7. **A directement révélé un défaut non détecté par relecture** (`family_alerts` sans SELECT patient, bloquant silencieusement le DELETE) |
| Re-vérification du correctif DELETE `family_alerts` après ajout du SELECT manquant | ✅ Oui | `DELETE 0` → `DELETE 1`, confirmé par exécution réelle |
| Rejeu de la chaîne complète des migrations après chaque lot de correctifs | ✅ Oui | Base `pharma_test` reconstruite intégralement (`run_chain.sh`) à chaque itération, aucune régression |
| Vérification FAM-4 (existence d'un service de push réel ailleurs dans le projet) | ✅ Oui | `PushNotificationService` confirmé réel et déjà utilisé ailleurs, distinct du wrapper local `NotificationService` — câblage plutôt que construction ex nihilo |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les correctifs Dart (`sos_service.dart`, `family_service.dart`, `family_alert.dart`, `dashboard_screen.dart`) n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module confirme, pour la deuxième fois consécutive (après C98/Module 21), qu'une correction RLS validée par la seule relecture statique reste provisoire — le harnais d'exécution réelle a ici révélé un défaut d'une nature nouvelle pour cet audit : une policy DELETE syntaxiquement correcte et logiquement satisfaite en isolation, mais rendue inopérante par l'absence de policy SELECT sur la même table. Ce constat général sur le comportement de la RLS PostgreSQL (visibilité de ligne pour DELETE/UPDATE dépendante de l'ensemble des policies applicables au rôle) est documenté au rapport d'audit §7.2 pour référence dans les modules restants.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| FAM-1 — écritures RLS `family_alerts` (insert/delete), `family_activity_log` (insert/select patient) | Rapport d'audit §7.1 (C101) | 🟢 Corrigé et validé par exécution réelle (12/12 tests) |
| FAM-1 (périmètre élargi) — écritures RLS `family_challenges`, `family_activities` | Rapport d'audit §7.1 (C101) | 🟢 Corrigé et validé par exécution réelle |
| FAM-1 (complément) — SELECT patient manquant sur `family_alerts`, bloquant le DELETE | Rapport d'audit §7.2 (C102) | 🟢 Corrigé et validé par exécution réelle (`DELETE 1`) |
| FAM-2 — lecture `sos_acknowledgements` | Rapport d'audit §7.3 (C103) | 🟢 Corrigé et validé par exécution réelle |
| FAM-3 — logique de résolution SOS factice | Rapport d'audit §7.4 (C104) | 🟢 Corrigé (corrélation de lignes sœurs par fenêtre temporelle) |
| FAM-4 — notification push non câblée | Rapport d'audit §7.5 (C105) | 🟢 Corrigé (service réel préexistant câblé) |
| FAM-5 — embed PostgREST invalide + bug de profondeur JSON | Rapport d'audit §7.6 (C106) | 🟢 Corrigé — non vérifiable par le harnais Postgres brut (comportement PostgREST/Supabase-js), corrigé par cohérence de bout en bout |
| FAM-6 — UX de saisie UUID brut | Rapport d'audit §9.2 (D38) | 🟡 Différé — dette d'ergonomie, sans risque de sécurité |
| RG-FAM-01/02 (abonnement diaspora, paiement international) | Rapport d'audit §9.1 (D37) | 🔴 Non implémenté — différé, chantier de conception/fintech dédié |
| 4 écrans cahier (souscription, ajout bénéficiaire, tableau de suivi souscripteur, financement à distance) | Rapport d'audit §6.2 | 🔴 Absents |
| Exposition en navigation | Rapport d'audit §9.3 | 🟢 Corrigé — `/family` et `/family/sos` exposés, livrés et committés |
| Correction de registre D28 (Module 16) | Rapport d'audit §6.1, §7.1 | 🟢 Actée — `gamification_family.sql` non orpheline dans l'absolu |

## 5. Réserves formelles

1. **Aucune fonctionnalité du cahier FAM (abonnement diaspora, financement à distance, paiement international, RG-FAM-01/02) n'existe** — le module `family` corrigé et sécurisé ce tour, et désormais exposé en navigation, répond à un besoin réel (partage familial de dossier, défis santé, SOS) mais différent de celui décrit par le cahier sous ce nom (D37).
2. **L'ajout d'un proche reste fondé sur la saisie manuelle d'un UUID brut** — ergonomiquement limitant mais sans risque de sécurité, différé par arbitrage explicite (D38).
3. **FAM-5 (embed PostgREST + bug de profondeur JSON) n'a pas pu être vérifié par exécution réelle** — le harnais Postgres brut utilisé pour cet audit ne reproduit pas le comportement PostgREST/Supabase-js ; le correctif repose sur une cohérence de bout en bout vérifiée par lecture (service ↔ modèle), pas sur un test d'exécution.
4. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique à l'ensemble des fichiers Dart corrigés ce tour (`sos_service.dart`, `family_service.dart`, `family_alert.dart`, `dashboard_screen.dart`) : leur correction n'a été vérifiée que par lecture de code, pas par exécution Flutter réelle.
5. **`PushNotificationService._sendToToken()` reste lui-même un stub d'envoi FCM réel** (`print()`) — limite d'infrastructure préexistante et transverse à tout le projet, hors périmètre de ce module, signalée pour un futur audit du socle notifications.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : écart de périmètre cahier radical non résolu, différé (D37) ; ergonomie d'ajout de proche non résolue, différée (D38) ; FAM-5 non vérifiable par exécution réelle dans cet environnement ; absence de vérification Flutter/Dart outillée (limite constante du projet) ; stub FCM sous-jacent non traité.
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (30/08/2026), à l'issue de la séquence complète Étape 1 → Étape 2 → Étape 3 et de l'arbitrage des tickets D37/D38 et de l'exposition en navigation.*

---

Le module Family & Diaspora (FAM) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au Module 23 (HOP — Intégration Hôpitaux, Laboratoires & Imagerie).
