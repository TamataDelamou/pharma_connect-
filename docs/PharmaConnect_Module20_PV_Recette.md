# PharmaConnect — PV de recette, Module 20 (DSN — Dossier de Santé Numérique Longitudinal)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 pour les deux points de sécurité les plus sensibles, avant arbitrage et clôture par le porteur du projet.

---

## 1. Objet

Constater l'état du Module 20 à l'issue de son inspection, de son analyse comparative, de sa vérification de sécurité, et de l'arbitrage de périmètre du porteur du projet (D33, D34), et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de 4 occurrences du motif « rôle inatteignable » dans les 2 migrations propres au module (C94) ; ajout de l'entrée de menu manquante, 19ème occurrence du motif D6 (aucune correction fonctionnelle, uniquement un défaut d'atteignabilité) ; correction d'une suppression RLS silencieuse sur `health_records`, confirmée par exécution réelle avant et après correctif (C96). Hors périmètre, par arbitrage explicite du porteur du projet : le sous-module « Alertes préventives » (C95, dé-routé plutôt que reconstruit — D33) et le modèle de consentement RG-DSN-01/journal d'événements RG-DSN-02 (D34, chantier de conception différé) — tous deux consignés comme dette assumée, pas comme des défauts corrigés.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 24 fichiers Dart (`lib/modules/healthrecord/`), 3 migrations propres au module, routage (`app_router.dart`), menu de navigation (`dashboard_screen.dart`) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-DSN-01/02 et les 3 écrans principaux, RG par RG et écran par écran — écarts identifiés et arbitrés (D33, D34) |
| Recherche exhaustive de tables consommées par le code mais absentes des migrations | ✅ Oui | `grep` de `preventive_alert`/`health_actions`/`health_record_vaccinations` sur l'ensemble de `supabase/migrations/` (85 fichiers) — 3 tables confirmées absentes (C95) |
| Recherche exhaustive de références croisées avant dé-routage | ✅ Oui | `grep` sur l'ensemble de `lib/modules/healthrecord/` confirmant qu'aucun autre écran/widget du module ne référence les routes `/healthrecord/alerts[...]` avant leur désactivation — aucun risque de bouton orphelin |
| Vérification d'ordre chronologique des migrations | ✅ Oui | Confirmé que les 2 fichiers corrigés pour C94 (28/08, 11h00 et 16h30) sont antérieurs à `is_gsg_admin()` (29/08) — vérification inlined sur `admin_users` utilisée, pas d'appel prématuré |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Protocole complet à 7 scénarios (insertion/suppression patient, lecture croisée professionnel/pharmacien/patient B, génération de résumé IA) exécuté sur le schéma complet des 85 migrations, avec les `GRANT` par défaut Supabase explicitement reproduits (absents du stub minimal utilisé jusqu'ici) — voir rapport d'audit §6. Ce module est le premier à vérifier une hypothèse de sécurité RLS (pas seulement une collision de schéma) par exécution réelle sous un rôle restreint plutôt que par lecture statique seule |
| Re-vérification du correctif C96 par exécution réelle | ✅ Oui | Même protocole rejoué après correctif : `DELETE 1` (au lieu de `DELETE 0`), 0 ligne restante |
| Rejeu de la chaîne complète des 85 migrations après chaque lot de correctifs | ✅ Oui | `ALL MIGRATIONS APPLIED SUCCESSFULLY` confirmé après C94, puis à nouveau après C96 |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — aucun écran modifié n'a été exécuté sur un environnement Flutter réel, seul le routage (dé-routage) a été vérifié par lecture de code |

**Conclusion de méthode :** ce module bénéficie, dès son ouverture, de la méthodologie d'exécution réelle établie au Module 19 (A29) — les deux constats de sécurité les plus sensibles (suppression silencieuse, absence de consentement) ont été prouvés empiriquement plutôt que déduits par lecture statique, avec un protocole nouveau pour cet audit : simulation de plusieurs identités authentifiées sous un rôle Postgres non-superutilisateur, RLS réellement active. Limite assumée et documentée : aucune vérification Flutter/Dart outillée (compilation, rendu d'écran) n'a été possible, comme pour tous les modules précédents depuis le Module 0.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Motif « rôle inatteignable » ×4 (`healthrecord_ai.sql`, `gamification_health.sql`) | Rapport d'audit §3 (C94) | 🟢 Corrigé — rejoué avec succès sur les 85 migrations |
| 19ème occurrence de D6 (menu de navigation) | Rapport d'audit §2 | 🟢 Corrigé — entrée « Dossier de santé » ajoutée, réservée au rôle patient |
| Suppression silencieuse de `health_records` | Rapport d'audit §6.1 (C96) | 🟢 Corrigé et re-vérifié par exécution réelle |
| Sous-module « Alertes préventives » (3 tables inexistantes) | Rapport d'audit §3 (C95) | 🟡 Dé-routé, non construit — arbitrage assumé (D33) |
| RG-DSN-01 (Critique, consentement) | Rapport d'audit §6.2 (C97) | 🔴 Non implémenté — confirmé par exécution réelle, différé (D34), risque assumé sans atténuation |
| RG-DSN-02 (journal d'événements automatique) | Rapport d'audit §5 | 🔴 Non implémenté — architecture différente de l'objectif cahier, différé (D34) |
| Écran « Historique de santé du patient » | Rapport d'audit §5 | 🟡 Partiel — fiche unique plutôt qu'historique d'événements |
| Écran « Détail d'un événement de santé » | Rapport d'audit §5 | 🟡 Partiel — même écart |
| Écran « Gestion des partages et autorisations » | Rapport d'audit §5 | 🔴 Absent — corollaire direct de D34 |
| Export du dossier à la demande du patient | Rapport d'audit §5 | 🔴 Absent — confirmé par lecture directe (`export_service.dart` non utilisé par ce module) |

## 5. Réserves formelles

1. **RG-DSN-01 (Critique) reste sans aucune atténuation** — l'option de correctif RLS palliatif (restreindre l'accès professionnel à une preuve d'intervention existante, ex. `professional_patient_interactions` d'INF) a été présentée mais non retenue par le porteur du projet. Le risque documenté par C97 reste donc actif tel quel jusqu'à la construction du chantier D34 : tout compte `pharmacien`/`professionnel` lit aujourd'hui l'intégralité de n'importe quel dossier de santé patient, sans consentement ni relation de soin vérifiée.
2. **Architecture RG-DSN-02 non conforme à l'objectif cahier** — le dossier reste une fiche auto-déclarée par le patient, pas un journal d'événements généré par les interventions HOM/CNS/HOP ; aucune intégration croisée entre ces modules et DSN n'existe (constat par lecture directe des services HOM/CNS, non exhaustif à 100 % sur l'ensemble du projet).
3. **Sous-module « Alertes préventives » non fonctionnel et non accessible** (D33) — code Dart conservé intact mais dé-routé ; toute reprise future nécessite la construction du schéma manquant avant réactivation du routage.
4. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique aussi à l'entrée de menu ajoutée ce module et au dé-routage des alertes préventives : leur correction n'a été vérifiée que par lecture de code, pas par exécution Flutter réelle.
5. **Interopérabilité avec HOP (Module 23, non encore audité)** — la fonctionnalité clé cahier « interopérabilité prévue avec les dossiers des établissements de santé partenaires » n'a pas pu être évaluée, HOP n'ayant pas encore fait l'objet de son propre audit.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : absence totale d'atténuation du risque RG-DSN-01 (D34, chantier de conception distinct à cadrer en priorité) ; architecture RG-DSN-02 non conforme au cahier (D34) ; sous-module Alertes préventives dé-routé et non fonctionnel (D33) ; absence de vérification Flutter/Dart outillée (limite constante du projet) ; interopérabilité HOP non évaluable à ce stade.
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (30/08/2026), à l'issue de la séquence complète Étape 1 → Étape 2 → Étape 3 et de l'arbitrage des tickets D33/D34.*

---

Le module Dossier de Santé Numérique Longitudinal (DSN) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au module suivant.
