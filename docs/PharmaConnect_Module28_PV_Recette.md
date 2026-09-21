# PharmaConnect — PV de recette, Module 28 (BI — Analytics & Business Intelligence)

**Date d'émission :** 05/09/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, sur feu vert explicite et complet du porteur du projet donné avant correctif, selon une feuille de route à 2 points (Étape 2 : BI-1/BI-5 ; Étape 3 : BI-6/BI-7/BI-8).

---

## 1. Objet

Constater l'état du Module 28 à l'issue de son inspection, de son analyse comparative, de ses correctifs de sécurité et de fonctionnement, et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de la totalité des défauts trouvés sur la migration et les 15 fichiers Dart d'origine du module, plus construction des fonctionnalités clés manquantes explicitement demandées :

- **BI-1** (Critique, fuite du chiffre d'affaires et des indicateurs opérationnels de chaque officine du réseau à tout compte authentifié, y compris patient) — corrigé par verrouillage des 4 vues matérialisées et création de 4 vues scopées (`_scoped`) dont la clause `WHERE` fait office de garde d'accès.
- **BI-2** (fonctionnalité clé cahier absente, « Tableau de bord officine ») — corrigé par une nouvelle fonction `SECURITY DEFINER` scopée, `get_pharmacy_daily_stats()`.
- **BI-3/BI-4** (C88, index unique manquant + valeur d'enum erronée) — corrigés dans le même mouvement que la reconstruction des 4 vues.
- **BI-5** (Critique, motif « rôle inatteignable » + lecture ouverte à tout le réseau sur les prévisions IA) — corrigé par un modèle RLS à 3 niveaux identique à BI-1.
- **BI-6** (2 écrans sur 3 inatteignables, providers non enregistrés) — corrigé : routes ajoutées, providers enregistrés, 3 boutons d'accès ajoutés à l'écran principal.
- **BI-7** (fonctionnalité clé cahier « Tableaux de bord personnalisables par rôle », doublon non intégré et scopé au patient) — recadré sur `scope` (`personal`/`officine`/`reseau`) + `pharmacy_id`, RLS correspondante, écran réellement câblé (widget picker, suppression de panneau).
- **BI-8** (fonctionnalité clé cahier « Export de rapports » absente) — livré : `ExportReportsScreen`, 3 exports CSV agrégés.
- **BI-10** (motif D6, 26ème occurrence) — corrigé, entrée « Analytics » ajoutée au menu.
- **BI-12** (découvert en cours de validation, `forecast_accuracy` sans aucune policy) — corrigé.
- **BI-13** (découvert en confrontant le correctif au schéma réel, valeur d'enum `alerts.status` erronée dans les vues) — corrigé.
- **BI-14** (découvert en cours de câblage Dart, `_uuid` non défini — défaut de compilation) — corrigé.

Hors périmètre, consigné comme décision différée (D48, D49) ou réserve (BI-11, indicateurs réseau/officine du cahier) : rattachement définitif de la Prévision IA au futur Module 11 ; fusion des deux systèmes de tableau de bord (`analytics_dashboards`/`user_dashboards`) ; dérive de champs Dart morts depuis C84 ; indicateurs de couverture géographique et rotation de stock/taux de rupture/panier moyen, sans support de données.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 15 fichiers Dart d'origine, 1 nouveau service, 1 nouvel écran, 1 modèle réécrit, 1 service réécrit, 1 provider réécrit, 2 écrans modifiés, `app.dart`/`app_router.dart`/`dashboard_screen.dart` mis à jour |
| Analyse comparative au cahier de conception | ✅ Oui | 4 fonctionnalités clés/3 écrans principaux — 2 fonctionnalités livrées ce tour (export, personnalisation officine/réseau), 1 partiellement (tableau de bord officine sans les 3 indicateurs précis du cahier), 1 toujours sans support de données (indicateurs réseau) |
| Vérification directe du routage (`app_router.dart`) | ✅ Oui | 3 nouvelles routes statiques sous `/analytics/...`, aucun risque de shadowing avec la route racine (motif C69 déjà appliqué dans ce fichier) |
| Vérification de non-régression de la couche Dart consommatrice | ✅ Oui | `AnalyticsService` interrogeait directement les 4 vues matérialisées brutes — repéré et corrigé avant livraison, faute de quoi le correctif SQL aurait bloqué l'écran pour tout rôle, pas seulement un patient |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Harnais dédié `bi_rls_test.sql`, 24 scénarios (verrouillage des vues brutes, vues scopées par rôle/officine, fonction officine, écriture/lecture des prévisions par officine, `forecast_accuracy`, recadrage officine/réseau du tableau de bord personnalisé), exécuté sur le schéma complet des **91 migrations** — voir rapport d'audit §8 |
| Rejeu de la chaîne complète des migrations après le correctif | ✅ Oui | Migration corrective appliquée sans erreur sur une base Postgres 16 neuve, à 3 reprises au fil des itérations (BI-1/BI-5 puis BI-7, puis vérification finale) |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) — vérification manuelle ligne à ligne de chaque fichier livré (imports, signatures, types de retour) en substitution partielle ; c'est cette revue manuelle, et non un outil, qui a mis en évidence BI-14 |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les correctifs Dart n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module confirme, sur un cas plus sévère qu'à l'accoutumée (fuite de CA de réseau entier plutôt que d'une seule officine), la leçon déjà établie sur les vues matérialisées sans RLS possible (REG-5) et introduit une vigilance nouvelle propre à ce module : corriger une fuite de données côté base sans vérifier la couche Dart consommatrice peut transformer une fuite de sécurité en panne totale pour tous les rôles légitimes — un risque de régression repéré et neutralisé avant toute livraison, pas après coup.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| BI-1 — fuite de CA/indicateurs réseau entier (Critique) | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 1-6, 9-10) |
| BI-2 — Tableau de bord officine absent | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 7-8) |
| BI-3/BI-4 (C88) — index unique et enum erronée | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-5 — RLS prévisions IA (Critique) | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 11-17) |
| BI-6 — écrans/providers inatteignables | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-7 — personnalisation par rôle | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (tests 18-24) |
| BI-8 — export de rapports absent | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-10 — exposition en navigation (motif D6, 26ème occurrence) | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-12 — `forecast_accuracy` sans policy | Rapport d'audit, §8 | 🟢 Corrigé et validé par exécution réelle (test 16) |
| BI-13 — valeur d'enum `alerts.status` erronée | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-14 — défaut de compilation (`_uuid` non défini) | Rapport d'audit, §8 | 🟢 Corrigé |
| BI-11 — champs Dart morts depuis C84 | Rapport d'audit §9 | 🔴 Non corrigé — dette cosmétique différée |
| Indicateurs réseau (couverture géographique) | Rapport d'audit §9 | 🔴 Non implémenté — aucun support de données, différé |
| Rotation de stock / taux de rupture / panier moyen | Rapport d'audit §9 | 🔴 Non implémenté — différé |
| Fusion `analytics_dashboards`/`user_dashboards` (D49) | Rapport d'audit §8/§9 | 🟡 Décision de périmètre explicite — doublon documenté, non fusionné |

## 5. Réserves formelles

1. **Deux fonctionnalités clés du cahier restent non couvertes** — indicateurs réseau (couverture géographique, densité de disponibilité) sans aucun support de données ; rotation de stock/taux de rupture/panier moyen (indicateurs officine) non calculés par `get_pharmacy_daily_stats()`, qui couvre réservations/livraisons/transactions/CA. Les construire suppose soit une nouvelle migration, soit un arbitrage produit sur les données déjà disponibles ailleurs — hors mandat de ce correctif.
2. **Le doublon `analytics_dashboards`/`user_dashboards` n'a pas été fusionné**, par décision explicite plutôt que par omission (D49) — le premier système est déjà en production et fonctionnel, le second était jusqu'ici totalement inatteignable ; les fusionner aurait représenté un risque de régression disproportionné pour ce correctif.
3. **BI-11 (champs Dart morts depuis C84) reste en l'état** — dérive cosmétique sans risque de sécurité, non traitée ce tour.
4. **Le rattachement du sous-système Prévision IA au futur Module 11 (D48) reste noté pour mémoire** malgré son traitement dans ce tour — une revue de conception dédiée à l'ouverture du Module 11 reste recommandée.
5. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique à l'ensemble des 9 fichiers Dart livrés ce tour (2 nouveaux, 7 modifiés). La découverte de BI-14 (défaut de compilation pur, sans aucun rapport avec la RLS) au cours même de ce correctif illustre concrètement ce que cette limite peut laisser passer — un `flutter analyze` complet, hors du périmètre de cet environnement, reste recommandé avant toute mise en production.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : indicateurs réseau/officine du cahier non implémentés, différés ; doublon de systèmes de tableau de bord non fusionné par décision explicite (D49) ; champs Dart morts BI-11 non nettoyés ; rattachement Module 11 de la Prévision IA noté pour mémoire (D48) ; absence de vérification Flutter/Dart outillée (limite constante du projet).
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (05/09/2026), sur la base d'un feu vert explicite et complet donné pour l'exécution intégrale des Étapes 2 et 3 et la clôture du module, selon une feuille de route à 2 points.*

---

## 7. Fichiers livrés

**1 migration SQL** : `supabase/migrations/20260905070000_analytics_module_fixes.sql`.

**2 nouveaux fichiers Dart** :
- `lib/modules/analytics/services/analytics_user_scope.dart`
- `lib/modules/analytics/screens/export_reports_screen.dart`

**9 fichiers Dart modifiés** :
- `lib/modules/analytics/models/user_dashboard.dart` (réécrit — BI-7)
- `lib/modules/analytics/services/analytics_service.dart` (BI-1, non-régression)
- `lib/modules/analytics/services/dashboard_customization_service.dart` (réécrit — BI-7)
- `lib/modules/analytics/providers/dashboard_customization_provider.dart` (réécrit — BI-7/BI-14)
- `lib/modules/analytics/screens/dashboard_editor_screen.dart` (BI-7)
- `lib/modules/analytics/screens/analytics_dashboard_screen.dart` (BI-6)
- `lib/app.dart` (BI-6)
- `lib/routes/app_router.dart` (BI-6/BI-8)
- `lib/modules/dashboard/dashboard_screen.dart` (BI-10)

Soit **11 fichiers Dart** (2 nouveaux + 9 modifiés) et **1 migration SQL**, déposés sur le poste de l'utilisateur.

---

Le module Analytics & Business Intelligence (BI) est validé et clos. Conformément à la méthodologie du projet et à l'engagement du porteur du projet de suivre désormais l'ordre officiel du cahier, l'audit peut passer au module suivant restant à couvrir dans la numérotation officielle (Module 29, ou Module 11/IA si le porteur du projet souhaite trancher immédiatement l'arbitrage D48 laissé en mémoire).
