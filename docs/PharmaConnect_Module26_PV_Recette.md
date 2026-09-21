# PharmaConnect — PV de recette, Module 26 (CHN — Gestion des chaînes & multi-officines)

**Date d'émission :** 05/09/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Définitif — les trois étapes de la méthodologie (inspection, analyse comparative, sécurité) ont été menées en un seul tour, incluant une vérification par exécution réelle sur Postgres 16 sous rôle restreint pour la sécurité RLS, sur feu vert explicite et complet du porteur du projet donné avant correctif, selon une feuille de route à 5 points.

---

## 1. Objet

Constater l'état du Module 26 à l'issue de son inspection, de son analyse comparative, de ses correctifs de sécurité et de fonctionnement, et servir de trace de la décision de recette.

## 2. Périmètre couvert

Correction de la totalité des défauts trouvés sur les 3 migrations et 20 fichiers Dart du module (2 migrations actives, 1 troisième déjà neutralisée) :

- **CHN-1** (import vers `models/transfer_item.dart`, inexistant) — corrigé, `TransferItem` déjà accessible via `stock_transfer.dart`.
- **CHN-2** (import vers `widgets/network_alert_card.dart`, inexistant) — corrigé par un nouveau widget `NetworkAlertCard`.
- **CHN-3** (import vers `screens/network_alerts_screen.dart`, inexistant, situé dans le routeur global) — corrigé par un nouvel écran `NetworkAlertsScreen`.
- **CHN-4** (import vers `screens/network_roles_screen.dart`, inexistant, situé dans le routeur global) — corrigé par un nouvel écran `NetworkRolesScreen`.
- **CHN-5** (Critique, motif `auth.uid() = pharmacy_id` sur 6 policies) — corrigé par une migration corrective dédiée (`20260830051000_chains_module_fixes.sql`), réutilisant `public.is_pharmacy_staff()` et ajoutant l'accès manquant à l'officine destinataire.
- **CHN-5-bis** (récursion RLS découverte en cours de vérification par exécution réelle, non identifiée à l'ouverture) — corrigé par une fonction dédiée `public.is_group_member()`, `SECURITY DEFINER`.
- **CHN-6** (miroir client du motif CHN-5, `isFromPharmacy`/`isToPharmacy` comparant un id pharmacie à un id utilisateur) — corrigé via `AuthProvider.pharmacyId`.
- **CHN-7** (RG-CHN-01, seule règle du module, non appliquée sous 3 angles) — corrigé : saisie UI obligatoire du lot/péremption, trigger de validation à l'insertion, trigger de génération réelle des 2 mouvements symétriques à la réception avec revalidation de péremption au moment réel du mouvement.
- **CHN-8** (bascule actif/inactif inopérante) — corrigé.
- **CHN-9** (motif D6, 24ème occurrence, aucune entrée de menu) — corrigé.
- **CHN-10** (découvert en cours de correctif : `TransferItem.copyWith()` manquant, défaut de compilation) — corrigé.
- **CHN-11** (découvert en cours de correctif : articles de transfert jamais persistés, câblage manquant) — corrigé.

Hors périmètre, consigné comme décision différée (D44, D45) : politique de prix/promotions à l'échelle du groupement (4ème fonctionnalité clé du cahier, confirmée absente) ; absence de synchronisation entre `pharmacies.group_id` (posé par le module back-office `admin`, non audité) et `group_members` (gouvernance opérationnelle réelle de CHN).

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 20 fichiers Dart d'origine, 3 nouveaux (`network_alert_card.dart`, `network_alerts_screen.dart`, `network_roles_screen.dart`), 6 fichiers modifiés (`chain_service.dart`, `stock_transfer.dart`, `transfer_create_screen.dart`, `chain_provider.dart`, `transfer_detail_screen.dart`, `group_edit_screen.dart`), routage vérifié (`app_router.dart`, aucune modification requise), 3 migrations propres au module (2 actives, 1 neutralisée confirmée) |
| Analyse comparative au cahier de conception | ✅ Oui | RG-CHN-01 (seule règle du module), 4 fonctionnalités clés/3 écrans principaux — 3 construits, 1 confirmé absent (D44) |
| Vérification directe du routage (`app_router.dart`) | ✅ Oui | Confirmation par lecture directe qu'aucun shadowing go_router n'affecte ce module (motif C69 déjà anticipé par un commentaire d'audit) |
| Recherche transverse hors module pour trancher un contrat de données | ✅ Oui | `pharmacies.group_id` retrouvé lu et écrit dans `lib/modules/admin/` (back-office, non audité) — tranché comme deux mécanismes réels non synchronisés plutôt qu'une redondance accidentelle (D45) |
| **Exécution réelle sur Postgres 16 (rôle non-superutilisateur, RLS effectivement active)** | ✅ Oui | Protocole à 14 scénarios (isolation/visibilité `group_members`, accès source ET destinataire d'un transfert, isolation tiers, écriture admin vs non-admin, validation RG-CHN-01 à l'insertion et à la réception, chemin nominal complet avec mouvements de stock réels, rejets quantité insuffisante et péremption au moment réel), exécuté sur le schéma complet des **90 migrations** — voir rapport d'audit §7 |
| Rejeu de la chaîne complète des migrations après le correctif CHN-5/CHN-7 | ✅ Oui | `ALL MIGRATIONS APPLIED SUCCESSFULLY` confirmé, ordre chronologique préservé (migration corrective postérieure à `admin_helpers.sql`) |
| Détection et résolution d'une récursion RLS en cours de vérification | ✅ Oui (a évité une régression bloquante) | Policy auto-référente sur `group_members` causant `ERROR: infinite recursion detected in policy` — isolée dans une fonction `SECURITY DEFINER` dédiée plutôt que laissée dans la policy |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas d'accès à un environnement Flutter outillé depuis cette session (limite documentée depuis le Module 0, item A1/A26-A29) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Idem — les correctifs Dart n'ont pas été exécutés sur un environnement Flutter réel, uniquement relus et committés |

**Conclusion de méthode :** ce module confirme et étend deux leçons déjà établies (un correctif peut casser le rejeu chronologique s'il n'est pas daté après ses dépendances ; la relecture exhaustive révèle des défauts de compilation/câblage qu'aucune exécution Postgres ne peut détecter — ici CHN-10/CHN-11, même famille qu'ASR-8/C105) et en ajoute une nouvelle, inédite dans cet audit : **une policy RLS peut se référencer elle-même** (sous-requête sur sa propre table dans son propre `USING`), provoquant une récursion infinie que ni la relecture du SQL ni le traçage logique ne peuvent détecter — seule l'exécution réelle contre Postgres 16 l'a révélée. Ce risque existe potentiellement dans d'autres policies déjà validées ailleurs dans le projet si elles contiennent une sous-requête sur leur propre table ; aucune autre occurrence n'a été recherchée systématiquement ce tour (hors mandat), à garder en tête pour un futur balayage transverse.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| CHN-1 — import `transfer_item.dart` inexistant (compilation) | Rapport d'audit, §8 | 🟢 Corrigé |
| CHN-2 — import `network_alert_card.dart` inexistant (compilation) | Rapport d'audit, §8 | 🟢 Corrigé |
| CHN-3 — import `network_alerts_screen.dart` inexistant (compilation, routeur global) | Rapport d'audit, §8 | 🟢 Corrigé |
| CHN-4 — import `network_roles_screen.dart` inexistant (compilation, routeur global) | Rapport d'audit, §8 | 🟢 Corrigé |
| CHN-5 — RLS, motif `auth.uid()=pharmacy_id` (Critique) | Rapport d'audit, §7 | 🟢 Corrigé et validé par exécution réelle (14/14 tests) |
| CHN-5-bis — récursion RLS (découverte en exécution réelle) | Rapport d'audit, §7 | 🟢 Corrigé et validé par exécution réelle |
| CHN-6 — miroir client du motif CHN-5 | Rapport d'audit, §7 | 🟢 Corrigé |
| CHN-7 — RG-CHN-01 non appliquée (3 angles) | Rapport d'audit, §7 | 🟢 Corrigé et validé par exécution réelle (mouvements réels confirmés) |
| CHN-8 — bascule actif/inactif inopérante | Rapport d'audit, §8 | 🟢 Corrigé |
| Exposition en navigation (motif D6, 24ème occurrence) | Rapport d'audit, §8 | 🟢 Corrigé — `/chains` et `/network` exposés, livrés et committés |
| CHN-10 — `copyWith()` manquant (compilation, découvert en correctif) | Rapport d'audit, §7 | 🟢 Corrigé |
| CHN-11 — articles de transfert jamais persistés (câblage, découvert en correctif) | Rapport d'audit, §7 | 🟢 Corrigé |
| Politique de prix/promotions groupement (D44) | Rapport d'audit §6.3/§9 | 🔴 Non implémenté — différé, chantier de conception dédié |
| Synchronisation `pharmacies.group_id`/`group_members` (D45) | Rapport d'audit §6.2/§9 | 🔴 Non implémenté — différé, dépend du module `admin` non audité |

## 5. Réserves formelles

1. **Une fonctionnalité clé du cahier reste non couverte** — la politique de prix/promotions à l'échelle du groupement (D44), confirmée absente par recherche exhaustive.
2. **Un risque de désynchronisation de données non corrigé** — `pharmacies.group_id` (back-office `admin`, non audité) et `group_members` (gouvernance réelle de CHN) ne sont reliés par aucun mécanisme de synchronisation ; le reporting consolidé (basé sur le premier) peut diverger de l'accès/gouvernance réels (basé sur le second) (D45).
3. **La création de rôle d'administration réseau repose sur une saisie d'identifiant utilisateur en UUID brut**, faute de tout composant de sélection utilisateur réutilisable existant dans le codebase — même limite assumée que ASR-3/PRE-5 (D42), fonctionnellement réelle et sécurisée, ergonomiquement perfectible. Non re-consignée comme nouveau ticket D, rattachée à D42 par nature identique.
4. **Deux défauts de compilation/câblage ont été trouvés en cours de correctif, pas à l'ouverture** (CHN-10, CHN-11) — confirme, pour la troisième fois consécutive (après ASR-8, C105), qu'aucune des méthodes de vérification mobilisées dans cet audit (relecture, exécution Postgres réelle) ne constitue une preuve de compilabilité Dart complète ; seul le traçage manuel des appelants réels en a eu raison. Un `flutter analyze` complet, hors du périmètre de cet environnement, reste recommandé avant toute mise en production.
5. **Une classe d'erreur RLS inédite dans cet audit a été rencontrée et corrigée** (CHN-5-bis, récursion de policy auto-référente) — non détectable par relecture, uniquement par exécution réelle ; sa possible récurrence ailleurs dans le projet (toute policy contenant une sous-requête sur sa propre table) n'a pas été recherchée systématiquement, hors mandat de ce tour.
6. **Le gap RLS pré-existant du module STK (Module 4, hors périmètre)** — `stock_items`/`stock_batches`/`stock_movements` sans aucune policy d'écriture pour `authenticated` — a été contourné par une fonction `SECURITY DEFINER` plutôt que corrigé à la racine, pour ne pas modifier un module tiers non audité (C131, registre).
7. **Aucune vérification Flutter/Dart outillée** (compilation, rendu d'écran, test E2E) n'a été possible — limite constante depuis le Module 0 (A1/A26-A29), qui s'applique à l'ensemble des fichiers Dart corrigés ce tour, dont les 3 nouveaux écrans/widgets.

## 6. Décision de recette

☑ **Recette prononcée avec réserves** — réserves acceptées : politique de prix/promotions groupement non implémentée, différée (D44) ; désynchronisation potentielle `pharmacies.group_id`/`group_members` non corrigée, différée (D45, dépend d'un module non audité) ; saisie UUID brute pour l'attribution de rôle réseau, rattachée à D42 ; absence de vérification Flutter/Dart outillée (limite constante du projet) ; récurrence possible non recherchée de la récursion RLS CHN-5-bis ailleurs dans le projet.
☐ **Recette prononcée sans réserve**

*Recette prononcée par le porteur du projet (05/09/2026), sur la base d'un feu vert explicite et complet donné pour l'exécution intégrale des Étapes 2 et 3 et la clôture du module, selon une feuille de route à 5 points, incluant l'exposition immédiate en navigation.*

---

Le module Gestion des chaînes & multi-officines (CHN) est validé et clos. Conformément à la méthodologie du projet, l'audit passe désormais au module suivant restant à traiter — à confirmer contre la table officielle du cahier.
