# PharmaConnect — PV de recette, Module 21 (IOT — Télésuivi & Objets médicaux connectés)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, avant arbitrage et clôture par le porteur du projet.

---

## 1. Objet

Constater l'état du Module 21 à l'issue de son inspection, de son analyse comparative, de sa vérification de sécurité, et de l'arbitrage de périmètre du porteur du projet (D35, D36), et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de deux défauts transverses dans la migration d'origine du module (C98 : `auth.uid() = pharmacy_id` et `role in ('admin', 'staff')` sans repli — 6 policies au total, corrigées en deux temps, voir §3) ; correction d'un biais d'identifiant côté client, balayé exhaustivement sur les 3 fichiers concernés (C99). Hors périmètre, par arbitrage explicite du porteur du projet : la fusion avec le module `coldchain/` (D35, différée vers l'audit dédié du Module 31/CLD) et la construction du télésuivi patient RG-IOT-01/02 (D36, chantier de conception différé) — tous deux consignés comme dette assumée, pas comme des défauts corrigés. La faille RLS trouvée incidemment sur `coldchain/` (C100) n'a pas été corrigée, ce module n'étant pas encore ouvert — signalée avec priorité absolue pour son ouverture future.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 9 fichiers Dart (`lib/modules/iot/`), migration propre au module (`20260829003000_iot.sql`), routage (`app_router.dart`) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-IOT-01/02 et les 4 écrans principaux, RG par RG et écran par écran — écart de périmètre radical confirmé et arbitré (D36) |
| Recherche exhaustive de code dupliqué/recouvrant un autre module du cahier | ✅ Oui | Confirmation directe (listing + lecture complète de `20260827000800_coldchain.sql`, 92 lignes) de l'existence réelle et indépendante de `lib/modules/coldchain/` — doublon confirmé, pas une hypothèse (D35) |
| Balayage exhaustif du motif de biais d'identifiant côté client | ✅ Oui | `grep` de `SupabaseService().currentUser` sur l'ensemble de `lib/modules/iot/` — 3 occurrences confirmées comme le bug (C99, corrigées), 6 occurrences confirmées comme un usage légitime distinct (`created_by`/`updated_by`, non modifiées) |
| Vérification d'ordre chronologique des migrations | ✅ Oui | Confirmé que le fichier corrigé pour C98 (29/08, 03h00) est antérieur à `is_gsg_admin()` (29/08, 03h800) — vérification inlined sur `admin_users` utilisée, pas d'appel prématuré |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Protocole à 9 scénarios (isolation multi-officines en lecture ET écriture, supervision admin, patient tiers) exécuté sur le schéma complet des 85 migrations, avec les `GRANT` par défaut Supabase explicitement reproduits — voir rapport d'audit §7. **A directement révélé que le correctif initial de C98 était incomplet** (4 policies supplémentaires portant le même défaut, non détectées par la seule relecture statique) |
| Re-vérification du correctif C98 complété par exécution réelle | ✅ Oui | 9/9 tests conformes après complément : isolation multi-officines (lecture ET `UPDATE`) et supervision admin toutes deux prouvées |
| Rejeu de la chaîne complète des 85 migrations après chaque lot de correctifs | ✅ Oui | `ALL MIGRATIONS APPLIED SUCCESSFULLY` confirmé après le correctif initial de C98, puis à nouveau après son complément |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les 3 écrans modifiés (C99) n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module confirme, et renforce, la valeur de la méthodologie d'exécution réelle établie au Module 19 (A29) et déjà appliquée au Module 20 : sans le harnais de test réel explicitement exigé par le porteur du projet pour valider C98, le correctif partiel serait resté silencieusement incomplet — 4 policies sur 6 corrigées, 2 laissées intactes, un défaut de sévérité identique à celui déjà « corrigé ». C'est la première fois dans cet audit qu'une vérification par exécution réelle contredit un statut « 🟢 Résolu » déjà annoncé, plutôt que de simplement confirmer un constat statique — un argument de fond en faveur de systématiser ce protocole avant toute clôture de module touchant à la RLS. Limite assumée et documentée : aucune vérification Flutter/Dart outillée n'a été possible, comme pour tous les modules précédents depuis le Module 0.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Motif transverse `auth.uid() = pharmacy_id` (6 policies au total) | Rapport d'audit §4, §7.1 (C98) | 🟢 Corrigé et validé par exécution réelle (9/9 tests) |
| Motif « rôle inatteignable » sans repli (3 policies) | Rapport d'audit §4 (C98) | 🟢 Corrigé — vérification inlined `admin_users`, validée par exécution réelle |
| Biais d'identifiant `pharmacyId` côté client (3 fichiers) | Rapport d'audit §6.2 (C99) | 🟢 Corrigé — livré et committé |
| Doublon `iot`/`coldchain` | Rapport d'audit §6.3 (D35) | 🟡 Consolidation différée vers le Module 31 (CLD) — arbitrage assumé |
| Faille RLS de `coldchain/` (lecture ouverte, aucune écriture) | Rapport d'audit §6.3 (C100) | 🔴 Non corrigé — hors périmètre de ce module, priorité absolue à l'ouverture du Module 31 |
| RG-IOT-01 (Critique, dispositifs validés) | Rapport d'audit §6.1 | 🔴 Non implémenté — différé (D36) |
| RG-IOT-02 (Standard, alerte au professionnel référent) | Rapport d'audit §6.1 | 🔴 Non implémenté (mécanique technique seuil→alerte réutilisable) — différé (D36) |
| Écran « Association d'un objet connecté » (patient) | Rapport d'audit §6.2 | 🔴 Absent |
| Écran « Historique des mesures » (patient) | Rapport d'audit §6.2 | 🔴 Absent |
| Écran « Auto-évaluation périodique » | Rapport d'audit §6.2 | 🔴 Absent |
| Écran « Alerte de télésuivi » (vue professionnel référent) | Rapport d'audit §6.2 | 🔴 Absent |
| Exposition en navigation | Rapport d'audit §8, Sujet 3 | 🟡 Non exposé, par décision explicite, tant que D35 n'est pas scellé |

## 5. Réserves formelles

1. **Le correctif C98 a dû être complété en Étape 3** — 4 policies sur 6 portant le motif `auth.uid() = pharmacy_id` n'avaient pas été détectées lors du premier passage à l'ouverture du module. Bien que désormais corrigées et validées par exécution réelle, ce constat est noté comme un rappel méthodologique : une correction annoncée « 🟢 Résolu » sur la seule base d'une relecture statique doit être considérée comme provisoire tant qu'elle n'a pas été vérifiée par exécution réelle.
2. **`coldchain/` reste en l'état, avec une faille RLS critique en lecture et bloquante en écriture** (C100) — non corrigée dans ce module par construction (module non encore ouvert), mais son existence documentée ici constitue une alerte de sécurité active dès aujourd'hui pour quiconque utiliserait ce module en production sans attendre l'audit du Module 31.
3. **Aucune fonctionnalité de télésuivi patient cahier n'existe** (RG-IOT-01/02, D36) — le module `iot` corrigé et sécurisé ce tour ne répond à aucune des exigences cahier IOT telles que rédigées ; il sécurise uniquement la fonction réellement codée (supervision d'équipements d'officine).
4. **Doublon `iot`/`coldchain` non résolu** (D35) — deux implémentations concurrentes et non synchronisées de la même donnée métier (température d'équipement) coexistent ; un risque de divergence silencieuse existe tant que la consolidation n'est pas tranchée au Module 31.
5. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique aussi aux 3 fichiers corrigés pour C99 : leur correction n'a été vérifiée que par lecture de code, pas par exécution Flutter réelle.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : correctif C98 initialement incomplet mais désormais complété et validé par exécution réelle ; faille RLS active de `coldchain/` (C100) non corrigée dans ce module, priorité absolue à l'ouverture du Module 31 ; doublon `iot`/`coldchain` non résolu, consolidation différée (D35) ; télésuivi patient RG-IOT-01/02 non implémenté, différé (D36) ; absence de vérification Flutter/Dart outillée (limite constante du projet).
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (30/08/2026), à l'issue de la séquence complète Étape 1 → Étape 2 → Étape 3 et de l'arbitrage des tickets D35/D36.*

---

Le module Télésuivi & Objets médicaux connectés (IOT) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au module suivant.
