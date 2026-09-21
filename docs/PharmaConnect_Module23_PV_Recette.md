# PharmaConnect — PV de recette, Module 23 (HOP — Intégration Hôpitaux, Laboratoires & Imagerie)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, avant arbitrage et clôture par le porteur du projet.

---

## 1. Objet

Constater l'état du Module 23 à l'issue de son inspection, de son analyse comparative, de sa vérification de sécurité, et de l'arbitrage de périmètre du porteur du projet (D39, D40, exposition en navigation), et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de la totalité des défauts trouvés sur les 2 migrations et 3 écrans du module : HOP-1 (5 policies d'écriture inatteignables sur `hospitals`/`hospital_departments`/`hospital_affiliations`/`hospital_referrals`/`hospital_wait_times`, motif « rôle inatteignable »), HOP-2 (import cassé et route manquante sur l'écran des temps d'attente), HOP-3 (référence à un champ jamais déclaré sur `HospitalDetailScreen`) ; exposition en navigation de `/hospitals` (21ème occurrence du motif D6). Hors périmètre, par arbitrage explicite du porteur du projet : la prescription/suivi d'examens de laboratoire/imagerie et la transmission des résultats vers le DSN (D39, chantier de conception dédié différé, même famille que D28/D29/D31/D32/D34/D36/D37) et la construction d'un back-office de gestion des établissements/départements/affiliations/orientations (D40, dette d'outillage différée).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 10 fichiers Dart (`lib/modules/hospitals/`), 2 migrations propres au module, routage (`app_router.dart`), menu de navigation (`dashboard_screen.dart`) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-HOP-01/02 et les 4 fonctionnalités clés/3 écrans principaux, fonctionnalité par fonctionnalité — profil inédit dans cet audit : écart partiel, pas radical (voir rapport d'audit §6.2) |
| Recherche exhaustive de fonctionnalité manquante (`examen`/`exam_order`/`lab_order`/`imaging_order`/`resultat`/`result`) | ✅ Oui | Confirmation qu'aucune fonctionnalité de prescription/résultat d'examen n'existe dans tout le projet |
| Vérification croisée de doublon potentiel avec `professional_profiles` (Module 19/INF) | ✅ Oui | `hospital_affiliations` confirmée complémentaire (affectation physique), pas concurrente (référentiel professionnel) — aucun doublon |
| Recherche exhaustive de tout point d'appel des méthodes d'écriture back-office | ✅ Oui | `saveHospital()`/`.deleteHospital()`/`WaitTimeService.updateWaitTime()` confirmés jamais appelés par aucun widget (HOP-4) |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Protocole à 14 scénarios (écriture bloquée pour un compte non-admin puis réussie pour un compte `is_gsg_admin()`, sur les 5 tables concernées, plus 3 vérifications de non-régression) exécuté sur le schéma complet des ~86 migrations, `GRANT` par défaut Supabase explicitement reproduits — voir rapport d'audit §7.4 |
| Rejeu de la chaîne complète des migrations après le premier correctif tenté | ✅ Oui (a révélé un défaut) | Le correctif HOP-1 en édition directe a d'abord cassé le rejeu chronologique complet (`function public.is_gsg_admin() does not exist`) — détecté uniquement par cette exécution réelle, jamais par relecture statique |
| Rejeu de la chaîne complète des migrations après le correctif définitif (migration corrective dédiée) | ✅ Oui | `ALL MIGRATIONS APPLIED SUCCESSFULLY` confirmé |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les correctifs Dart (`hospital_wait_times_screen.dart`, `hospital_detail_screen.dart`, `app_router.dart`, `dashboard_screen.dart`) n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module introduit une leçon méthodologique nouvelle dans cet audit — la convention habituelle « défaut trouvé dans la migration propre au module en cours d'audit : correction directe autorisée » n'est valable que si la correction ne casse pas l'ordre chronologique du rejeu complet des migrations. Ici, `is_gsg_admin()` (introduite le 29/08/2026 pour corriger exactement ce motif dans d'autres modules) est postérieure aux deux migrations du module HOP (27-28/08/2026) : une édition en place aurait silencieusement cassé tout déploiement sur une base neuve si elle n'avait pas été détectée par exécution réelle. Le correctif retenu (migration corrective dédiée, datée après la dépendance) est désormais le modèle de référence pour tout défaut futur de ce type.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| HOP-1 — écritures RLS sur les 5 tables du module | Rapport d'audit §7.1 | 🟢 Corrigé (migration corrective dédiée) et validé par exécution réelle (14/14 tests) |
| HOP-2 — import cassé + route manquante (écran temps d'attente) | Rapport d'audit §7.2 | 🟢 Corrigé — écran désormais atteignable via un bouton sur le détail établissement |
| HOP-3 — référence à un champ jamais déclaré (`isSelectMode`) | Rapport d'audit §7.3 | 🟢 Corrigé |
| RG-HOP-01/02 (non-substitution hospitalière, validation résultat) | Rapport d'audit §6.1 | 🟡 Sans objet / vacuité — aucune fonctionnalité clinique ne les active encore |
| Prescription/suivi d'examens, transmission DSN | Rapport d'audit §9.1 (D39) | 🔴 Non implémenté — différé, chantier de conception dédié |
| Back-office établissements/départements/affiliations/orientations (HOP-4) | Rapport d'audit §9.2 (D40) | 🔴 Non implémenté — différé, dette d'outillage |
| `hospital_referrals` (orientation patient, 2ème fonctionnalité clé) | Rapport d'audit §6.2 | 🟡 Données/RLS prêtes, aucune UI — dépend de D40 |
| Exposition en navigation | Rapport d'audit §9.3 | 🟢 Corrigé — `/hospitals` exposé, livré et committé |

## 5. Réserves formelles

1. **Aucune des deux fonctionnalités les plus spécifiques du cahier (prescription d'examen, transmission DSN) n'existe** — le module `hospitals` corrigé, sécurisé et désormais exposé en navigation ce tour ne couvre que l'annuaire de structures et l'orientation (partiellement, sans UI), pas le cœur médical du module tel que décrit par le cahier (D39).
2. **Aucun back-office de gestion n'existe** — les écritures (création/édition d'un établissement, d'un département, d'une affiliation, d'une orientation, mise à jour d'un temps d'attente) sont désormais correctement sécurisées (réservées à `is_gsg_admin()`) mais restent inatteignables sans interface dédiée (D40).
3. **Le correctif HOP-1 repose sur une migration corrective distincte des migrations d'origine du module** — écart volontaire et documenté à la convention habituelle de cet audit, justifié par la contrainte d'ordre chronologique (voir §3) ; à garder à l'esprit pour toute future intervention sur ces mêmes fichiers.
4. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique à l'ensemble des fichiers Dart corrigés ce tour.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : périmètre cahier (prescription/DSN) non résolu, différé (D39) ; back-office HOP-4 non résolu, différé (D40) ; méthode de correction HOP-1 par migration corrective distincte, documentée comme exception justifiée ; absence de vérification Flutter/Dart outillée (limite constante du projet).
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (30/08/2026), à l'issue de la séquence complète Étape 1 → Étape 2 → Étape 3 et de l'arbitrage des tickets D39/D40 et de l'exposition en navigation.*

---

Le module Intégration Hôpitaux, Laboratoires & Imagerie (HOP) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au Module 24 (ASR — Assurance santé & Tiers-payant, à confirmer contre la table officielle du cahier).
