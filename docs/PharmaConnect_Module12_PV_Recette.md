# PharmaConnect — PV de recette, Module 12 (TRC — Traçabilité & Lutte contre les médicaments contrefaits)

**Date d'émission :** 29/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module12_Protocole_Test_E2E.md`), en priorité le Scénario 1 (RLS d'écriture), sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 12 (TRC) à l'issue de son inspection, de ses correctifs et des arbitrages D19/D20/D21/D22, et servir de base à la décision de recette par le porteur du projet. Ce document couvre les deux passes de clôture : la première (§1-§6 initiaux du rapport d'audit) et l'addendum (§7 du rapport d'audit) demandé par le porteur du projet après refus de la première clôture.

## 2. Périmètre couvert

Vérification d'authenticité par scan (corrigée), boucle de rétroaction vérification→lot (nouvelle), écriture de mouvements pour réception/rappel/changement de statut (nouvelle), écran « Scan de réception » (D19, RG-TRC-01), écran « Signalement produit suspect » (D20, RG-TRC-02), correctifs RLS traceability (écriture manquante + sur-exposition en lecture), contrôle d'accès du dashboard, correction de la cause racine du menu de navigation (D6), **unification du rappel avec le module recall/pharmacovigilance et correctif RLS de ce module (D21, addendum §7.1)**, **extension du menu de navigation à « Rappels » (addendum §7.2)**. Hors périmètre, par arbitrage explicite ou dépendance non satisfaite : enforcement de RG-TRC-01 au point de vente réel (module POS, décision explicite D22 — le POS vend actuellement des produits fictifs, voir addendum §7.3), RG-TRC-03 (suspension fournisseur, dépend du Module 13 — Marketplace/B2B, non audité), suivi continu de la chaîne du froid (relevé ponctuel seulement, à la réception), audit dédié du module recall au-delà de son point d'intégration avec traceability (D23, question `stock_batches` vs `traceable_batches` ouverte).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 6 modèles (dont 1 nouveau), 1 service, 1 provider, 5 écrans (dont 2 nouveaux), 1 widget, 1 migration de base + 1 migration de correctifs, plus les points d'intégration transverses (app_router, dashboard_screen, alert_service, alert_type, offline_sync_service) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-TRC-01, RG-TRC-02, RG-TRC-03, 7 fonctionnalités clés, 4 écrans principaux |
| Vérification syntaxique statique (équilibrage accolades/parenthèses) | ✅ Oui | Script dédié, exécuté après chaque édition, sur les 11 fichiers Dart modifiés/créés |
| Recherche active d'octets de contrôle non désirés dans les fichiers édités | ✅ Oui | Vérification supplémentaire suite à un incident d'édition détecté et corrigé pendant cette session (séquence d'échappement `\x1d` mal interprétée) — aucun autre octet de contrôle indésirable trouvé |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Chemins de vérification, réception, rappel et signalement retracés, y compris le repli hors-ligne |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas de SDK Flutter/Dart disponible |
| Tests unitaires/`flutter test` | ❌ Non | Même limite |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Pas d'accès appareil/émulateur (limite documentée depuis le Module 1) |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, pas par exécution. Le Scénario 1 du protocole E2E (RLS d'écriture) doit être exécuté en priorité : avant correctif, aucune écriture de traçabilité (réception, rappel) n'était possible pour quiconque, y compris le staff légitime.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| RLS écriture (`traceable_batches`/`batch_movements`) | Rapport d'audit §3.1, migration `20260829023000` | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1 |
| RLS lecture restreinte (`batch_movements`/`cold_chain_records`/`certificates`/`verification_scans`) | Rapport d'audit §3.2 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 8 |
| Boucle de rétroaction vérification→lot | Rapport d'audit §4.1 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 2 |
| Mouvement produit à la réception/au rappel | Rapport d'audit §4.2/§4.3 | 🟢 Corrigé (revue de code) — à confirmer par les Scénarios 3/5 |
| Écran « Scan de réception » (D19) | Registre D19, arbitrage porteur du projet (29/08/2026) | 🟢 Construit (revue de code) — à confirmer par les Scénarios 3-4 |
| Écran « Signalement produit suspect » (D20) | Registre D20, arbitrage porteur du projet (29/08/2026) | 🟢 Construit (revue de code) — à confirmer par les Scénarios 6-7 |
| Table `counterfeit_reports` + RLS | Rapport d'audit §4.4/§4.5 | 🟢 Construit (revue de code) — à confirmer par le Scénario 6 |
| Alerte admin GSG sur signalement (`alerts_admin_select_all`) | Rapport d'audit §4.13 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| Extraction GS1 du scan (anti-crash) | Rapport d'audit §1.2 point 6 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 9 |
| Libellé `verifiedBy` dynamique | Rapport d'audit §1.2 point 7 | 🟢 Corrigé (revue de code) |
| Contrôle d'accès du dashboard (rôle) | Rapport d'audit §3.3 | 🟢 Construit (revue de code) — à confirmer par le Scénario 8 |
| Cause racine du menu de navigation (série D6, 11ème occurrence) | Rapport d'audit §1.3/§4.11 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 10 |
| Mode hors-ligne (lecture liste des lots) | Rapport d'audit §3.4 | 🟢 Construit (revue de code) — à confirmer par le Scénario 11 |
| Mode hors-ligne (réception, D19) | Rapport d'audit §3.4 | 🟢 Construit (revue de code) — non couvert par un scénario dédié, réutilise le patron STK déjà validé (A7) |
| RG-TRC-01 (chaîne continue, blocage lot rappelé/contrefait) | Rapport d'audit §2.1/§7.3 | 🟡 Enforcement partiel, désormais bloqué sur une dépendance explicite (D22 : audit dédié du module POS, non planifié) plutôt que sur une simple absence d'intégration |
| RG-TRC-02 (signalement, alerte immédiate) | Rapport d'audit §2.1 | 🟢 Satisfait (revue de code) — à confirmer par le Scénario 6 |
| RG-TRC-03 (suspension fournisseur) | Rapport d'audit §2.1 | 🔴 Hors périmètre — dépend du Module 13 (Marketplace/B2B), non audité |
| RLS écriture module recall (`recalls`/`recall_affected_batches`) | Rapport d'audit §7.1, migration `20260829024000` | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 12 |
| Unification rappel traceability ↔ recall (D21) | Rapport d'audit §7.1 | 🟢 Corrigé (revue de code) — best-effort, non bloquant pour le flag `is_recalled` — à confirmer par le Scénario 12 |
| Menu de navigation — entrée « Rappels » (série D6, 12ème occurrence) | Rapport d'audit §7.2 | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 12 (étape 9-10) |

## 5. Réserves formelles

1. **Aucun des 12 scénarios du protocole de test E2E n'a été exécuté**, en particulier le Scénario 1 (RLS d'écriture) et le Scénario 12 (unification recall) — bloquants pour toute écriture de traçabilité/de rappel avant correctif.
2. **RG-TRC-01 reste un enforcement partiel**, désormais bloqué sur une dépendance explicite (D22) plutôt qu'une absence d'intégration : un lot rappelé/contrefait ne peut plus être *réceptionné*, mais peut toujours être vendu s'il est déjà en stock — le module POS existe, sa RLS est correcte, mais son écran de caisse vend depuis des produits fictifs, sans sélection de lot réel ; un blocage RG-TRC-01 y serait sans effet tant que ce n'est pas corrigé (audit POS dédié, non planifié).
3. **RG-TRC-03 hors périmètre**, dépendance non satisfaite (Module 13, non audité) — à ne pas présenter comme fonctionnalité disponible.
4. **Signalement volontairement indisponible hors-ligne** (D20) — comportement assumé, pas un défaut.
5. **Chaîne du froid** : un relevé de température peut désormais être attaché à une réception (D19), mais aucun suivi continu/écran dédié n'existe — hors périmètre de ce correctif.
6. **Module recall non audité dans son ensemble** (D23) : seuls sa RLS et son point d'intégration avec traceability ont été corrigés/vérifiés. La numérotation de référence des rappels est calculée côté client sans séquence Postgres (course possible entre deux créations concurrentes), et la notification des parties prenantes (`notifiedParties`) n'est pas implémentée malgré le champ prévu (`RecallService._notifyStakeholders` est un stub).
7. **`stock_batches` (Module 4/STK, référencé par le module POS) et `traceable_batches` (Module 12/TRC) ne sont jamais réconciliés** (D23) : deux notions de « lot » potentiellement distinctes pour le même produit physique — question architecturale ouverte, à trancher avant tout enforcement RG-TRC-01 réel au point de vente.

## 6. Décision de recette

☐ **Recette prononcée sans réserve** — nécessite l'exécution complète du protocole de test E2E, Scénario 1 en priorité.
☐ **Recette prononcée avec réserves** — lister les réserves acceptées et la date limite de levée.
☐ **Recette refusée / reportée** — lister les motifs bloquants.

*Case à cocher et à signer par le porteur du projet après exécution du protocole de test E2E.*

Nom : _______________________ Date : _______________ Signature : _______________________

---

**Le module Traçabilité (TRC) est-il totalement clos et validé pour passer au suivant ?**
