# PharmaConnect — PV de recette, Module 27 (REG — Module Régulateur & Reporting Pharmacovigilance)

**Date d'émission :** 05/09/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, sur feu vert explicite et complet du porteur du projet donné avant correctif, selon une feuille de route à 2 points.

---

## 1. Objet

Constater l'état du Module 27 à l'issue de son inspection, de son analyse comparative, de ses correctifs de sécurité et de fonctionnement, et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de la totalité des défauts trouvés sur la migration et les 7 fichiers Dart d'origine du module, plus construction des 2 fonctionnalités clé manquantes :

- **REG-1** (Critique, motif « rôle inatteignable » `role in ('admin','regulator')` sur les 4 tables du module à la fois) — corrigé par une migration corrective dédiée (`20260905060000_regulator_module_fixes.sql`), nouveau helper `public.is_regulator()`, réutilisation de `public.is_gsg_admin()` déjà existant.
- **REG-2** (défaut de compilation certain, `SupabaseService` utilisé sans import) — corrigé (cause supprimée avec REG-3).
- **REG-3** (miroir du motif CHN-6/PRE-6, 2 occurrences : calcul de rôle par proxy en détail, route `/regulator/staff` câblée en dur) — corrigé dans les deux cas : `canManage = AuthProvider.isGsgAdmin` en détail, écran de liste auto-adapté au rôle réel, route dédiée supprimée.
- **REG-4** (3 tables orphelines) — `regulatory_inspections` et `marketing_authorizations` intégralement raccordées (modèles, service, 2 nouveaux providers, 6 nouveaux écrans, 6 nouvelles routes) ; `product_recalls` : RLS seule corrigée, décision de périmètre explicite (§9 du rapport d'audit, D46).
- **REG-5** (RG-REG-02, Critique — absence totale d'anonymisation) — corrigé par une vue `adverse_reactions_anonymized` avec garde d'accès au niveau de la vue elle-même (`WHERE is_gsg_admin() or is_regulator()`), seule source de données autorisée pour un compte `'regulateur'`.
- **REG-6** (motif D6, 25ème occurrence, aucune entrée de menu) — corrigé.

Hors périmètre, consigné comme décision différée (D46, D47) : réconciliation `product_recalls`/`recalls` (module `recall/`, futur Module 30/RCL) ; cartographie des officines/statut d'agrément et statistiques de disponibilité régionale (fonctionnalités clés n°1 et 3 du cahier), sans support de données dans la migration du module.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 7 fichiers Dart d'origine, 3 nouveaux modèles, 1 service étendu, 1 provider étendu, 2 nouveaux providers, 1 nouveau widget, 2 écrans corrigés, 6 nouveaux écrans, routage et menu mis à jour |
| Analyse comparative au cahier de conception | ✅ Oui | RG-REG-01/02, 4 fonctionnalités clés/3 écrans principaux — 1 fonctionnalité couverte à l'ouverture (non-conforme), 2 construites ce tour (inspections, AMM), 2 confirmées sans support de données (D47) |
| Vérification directe du routage (`app_router.dart`) | ✅ Oui | 6 nouvelles routes déclarées dans l'ordre sans risque de shadowing (statique avant `:id`, `new` avant `:id` par sous-arborescence, `/regulator/:id` en dernier du groupe) — même discipline que le motif C69 déjà appliqué dans ce fichier |
| Recherche transverse hors module pour trancher un chevauchement | ✅ Oui | `product_recalls` (REG, orpheline) confirmée table morte, sans rapport avec `recalls` (module `recall/`, futur Module 30/RCL déjà partiellement examiné, D23) — tranchée comme chevauchement cahier à réconcilier plus tard (D46), pas comme redondance à corriger ce tour |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Harnais dédié `reg_rls_test.sql`, 10 scénarios (accès staff GSG/régulateur/tiers sur les 4 tables, lecture de la vue anonymisée, absence de colonnes nominatives dans son schéma, non-régression de la lecture publique des AMM approuvées), exécuté sur le schéma complet des **91 migrations** — voir rapport d'audit §8 |
| Rejeu de la chaîne complète des migrations après le correctif REG-1/REG-5 | ✅ Oui | `ALL MIGRATIONS APPLIED SUCCESSFULLY` confirmé après chaque itération de la migration corrective |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) — vérification manuelle de l'équilibre des accolades/parenthèses de chaque fichier livré, et des signatures des widgets réutilisés (`GlassInput`, `PrimaryButton`, `TertiaryButton`, `GlassCard`), effectuée en substitution partielle |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les correctifs Dart n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module confirme, sur un cas plus sévère qu'à l'accoutumée, la leçon déjà établie sur le motif « rôle inatteignable » (ici les 4 tables d'un même module bloquées simultanément) et introduit une vigilance nouvelle propre à ce module : une vue conçue pour contourner RLS (motif « security-definer ») doit porter sa propre garde d'accès dans sa clause `WHERE`, faute de quoi un simple `GRANT` la rend lisible par n'importe quel compte authentifié — un piège de conception repéré et corrigé en cours d'écriture de la migration, avant toute exécution, plutôt que découvert par un test.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| REG-1 — RLS, motif « rôle inatteignable » sur 4 tables (Critique) | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 1-2-7-8-9) |
| REG-2 — import manquant (compilation) | Rapport d'audit, §8 | 🟢 Corrigé |
| REG-3 — miroir client (2 occurrences) | Rapport d'audit, §8 | 🟢 Corrigé (les deux) |
| REG-4 — tables orphelines (inspections, AMM) | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 7-9) |
| REG-4 — `product_recalls` | Rapport d'audit §9 | 🟡 RLS seule corrigée, UI non reconstruite — décision de périmètre explicite (D46) |
| REG-5 — RG-REG-02 non respectée (Critique) | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 3-4-5-6) |
| REG-6 — exposition en navigation (motif D6, 25ème occurrence) | Rapport d'audit, §8 | 🟢 Corrigé |
| Cartographie officines/statut d'agrément (D47) | Rapport d'audit §7.2/§11 | 🔴 Non implémenté — aucun support de données, différé |
| Statistiques de disponibilité régionale (D47) | Rapport d'audit §7.2/§11 | 🔴 Non implémenté — aucun support de données, différé |

## 5. Réserves formelles

1. **Deux fonctionnalités clés du cahier restent non couvertes** — cartographie des officines/statut d'agrément et statistiques de disponibilité régionale (D47), confirmées sans aucun support de données dans la migration `regulator.sql` ; les construire suppose un arbitrage produit (nouvelle migration ou rapprochement avec des données déjà exposées ailleurs), hors mandat de ce correctif.
2. **`product_recalls` reste sans UI**, par décision explicite plutôt que par omission — la table est un second mécanisme de rappel mort, distinct de celui réellement utilisé par le module `recall/` (futur Module 30/RCL) ; construire une UI dessus aurait créé une mécanique concurrente. RLS corrigée pour cohérence uniquement (D46).
3. **La création d'une inspection repose sur une saisie d'identifiant d'entité en UUID brut** (`entity_id`, polymorphe, sans FK), faute de tout sélecteur d'entité réutilisable existant dans ce module — même limite assumée que ASR-3/PRE-5/D42/D45 (chains), fonctionnellement réelle et sécurisée (RLS ne dépend pas de ce champ), ergonomiquement perfectible ; validation de format UUID ajoutée côté client par prudence, non re-consignée comme nouveau ticket D.
4. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique à l'ensemble des 18 fichiers Dart livrés ce tour (12 nouveaux, 6 modifiés). Un `flutter analyze` complet, hors du périmètre de cet environnement, reste recommandé avant toute mise en production.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : cartographie officines/statistiques régionales non implémentées, différées (D47) ; `product_recalls` sans UI par décision explicite, différé (D46) ; saisie UUID brute pour la création d'inspection ; absence de vérification Flutter/Dart outillée (limite constante du projet).
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (05/09/2026), sur la base d'un feu vert explicite et complet donné pour l'exécution intégrale des Étapes 2 et 3 et la clôture du module, selon une feuille de route à 2 points.*

---

Le module Régulateur & Reporting Pharmacovigilance (REG) est validé et clos. Conformément à la méthodologie du projet et à l'engagement du porteur du projet de suivre désormais l'ordre officiel du cahier, l'audit passe au **Module 28 (BI — Analytics & Business Intelligence)**.
