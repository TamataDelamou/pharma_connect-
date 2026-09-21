# PharmaConnect — Audit Module 26 (CHN — Gestion des chaînes & multi-officines)

**Étape 1 — Inspection & rapport de situation**
**Date : 05/09/2026**

---

## 1. Périmètre couvert (rappel cahier)

**Module 26 — CHN — Gestion des chaînes & multi-officines.** Standard. Axe 2 — Opérations d'officine (PHARMA), avec STK, BIZ, ALR, TRC.

**Objectif (cahier) :** permettre aux groupements et chaînes de pharmacies de gérer plusieurs points de vente au sein d'une organisation unique, avec transferts de stock inter-officines et reporting consolidé.

**Fonctionnalités clés (cahier) :**
- Rattachement de plusieurs officines à une même organisation (Org Registry du GSG Platform Kernel).
- Transfert de stock inter-officines avec traçabilité du mouvement.
- Reporting consolidé multi-sites.
- Politique de prix/promotions à l'échelle du groupement ou par officine.

**Écrans principaux (cahier) :** Vue groupement multi-officines, Transfert de stock inter-sites, Reporting consolidé.

**Règle de gestion — RG-CHN-01 (Standard, seule règle du module) :**
> « Un transfert de stock inter-officines génère deux mouvements symétriques tracés (sortie/entrée) et ne peut porter que sur des lots non expirés. »

---

## 2. Constat général

Le module `chains` est structurellement le plus étendu inspecté depuis plusieurs modules (20 fichiers Dart, 3 migrations, 2 features imbriquées — groupes/transferts et administration réseau) mais présente une densité de défauts inédite dans cet audit : **quatre imports non résolus vers des fichiers physiquement absents du projet**, dont deux référencés directement par `app_router.dart` — c'est-à-dire susceptibles de bloquer la compilation de l'application entière, pas seulement de ce module. S'y ajoute un motif RLS systémique (comparaison `auth.uid()` à un identifiant de pharmacie, déjà rencontré ailleurs dans le projet) touchant cette fois la quasi-totalité des policies propres au module, et une non-application quasi totale de RG-CHN-01, seule règle de gestion du module.

---

## 3. Inventaire du code trouvé

**Dossier `lib/modules/chains/`** — 20 fichiers : 6 modèles (`pharmacy_group.dart`, `group_member.dart`, `stock_transfer.dart` — contenant à la fois `StockTransfer` et `TransferItem` —, `network_admin_role.dart`, `network_alert.dart`, `network_dashboard.dart`), 2 providers (`chain_provider.dart`, `network_admin_provider.dart`), 2 services (`chain_service.dart`, `network_admin_service.dart`), 7 écrans (`groups_list_screen.dart`, `group_detail_screen.dart`, `group_create_screen.dart`, `group_edit_screen.dart`, `transfer_create_screen.dart`, `transfer_detail_screen.dart`, `network_dashboard_screen.dart`), 3 widgets (`group_card.dart`, `group_member_tile.dart`, `transfer_card.dart`).

**Migrations Supabase concernées :** `20260829000000_chains.sql` (ALTER de `pharmacy_groups`, créations de `group_members`, `stock_transfers`, `transfer_items`), `20260829007000_network_admin.sql` (`network_admin_roles`, vue matérialisée `network_dashboard`, `network_activity_log`, `network_alerts`) — un troisième fichier, `20260829006000_pos_and_network_admin.sql`, est **entièrement neutralisé** (doublon de table déjà traité lors de l'audit transverse Module 0, confirmé par lecture intégrale, aucune instruction SQL exécutable restante — non re-signalé ici).

**Routage (`app_router.dart`, vérifié par lecture directe) :** `/chains` (liste des groupes), `/chains/group/new`, `/chains/group/:id`, `/chains/group/edit/:id`, `/chains/transfer/new`, `/chains/transfer/:id`, `/network`, `/network/group/:id`, `/network/alerts`, `/network/roles` — 10 routes. **Aucun shadowing go_router détecté** : `/chains/group/new` précède bien `/chains/group/:id` et `/chains/transfer/new` précède bien `/chains/transfer/:id`, avec un commentaire d'audit référençant explicitement le balayage C69 du Module 18 (HOM) — motif déjà corrigé ici, pas une régression.

**Menu de navigation.** Confirmé absent de `dashboard_screen.dart` (lecture complète de `_navItems` et `_effectiveNavItems()`, aucune entrée `/chains` ni `/network`) — motif D6, **24ème occurrence**.

---

## 4. Défauts trouvés à l'ouverture (Étape 1)

### CHN-1 — Défaut de compilation : import vers un fichier inexistant (`models/transfer_item.dart`)

`transfer_create_screen.dart`, lignes 13-14 :
```dart
import '../models/stock_transfer.dart';
import '../models/transfer_item.dart';
```
Confirmé par listing intégral du dossier `lib/modules/chains/models/` (6 fichiers, aucun nommé `transfer_item.dart`) : ce fichier n'existe pas. La classe `TransferItem` existe bel et bien, mais elle est définie **dans** `stock_transfer.dart` (déjà importé juste au-dessus), pas dans un fichier séparé. Un import Dart relatif se résout par chemin de fichier, indépendamment du nom de classe recherché — cet import est donc invalide à coup sûr, indépendamment de tout usage de `TransferItem` dans le fichier. Défaut de compilation certain.

### CHN-2 — Défaut de compilation : import vers un fichier inexistant (`widgets/network_alert_card.dart`)

`network_dashboard_screen.dart`, ligne 11 :
```dart
import '../widgets/network_alert_card.dart';
```
puis usage du widget `NetworkAlertCard` (ligne ~190). Confirmé par listing intégral du dossier `lib/modules/chains/widgets/` (3 fichiers : `group_card.dart`, `group_member_tile.dart`, `transfer_card.dart` — aucun `network_alert_card.dart`, et la classe `NetworkAlertCard` n'est définie dans aucun des trois). Défaut de compilation certain.

### CHN-3 — Défaut de compilation, portée application entière : import vers un fichier inexistant (`screens/network_alerts_screen.dart`)

`app_router.dart`, ligne 203 :
```dart
import '../modules/chains/screens/network_alerts_screen.dart';
```
utilisé à la route `/network/alerts` (ligne 1360, `const NetworkAlertsScreen()`). Confirmé par le même listing intégral du dossier `screens/` (7 fichiers, aucun `network_alerts_screen.dart`, aucune classe `NetworkAlertsScreen` trouvée nulle part dans le module). **Cet import se trouve dans `app_router.dart`, fichier unique chargé au démarrage de toute l'application** — contrairement à CHN-1/CHN-2 qui ne bloqueraient que la compilation du fichier qui les contient, celui-ci empêche potentiellement l'application entière de compiler, tous modules confondus.

### CHN-4 — Défaut de compilation, portée application entière : import vers un fichier inexistant (`screens/network_roles_screen.dart`)

`app_router.dart`, ligne 204, même mécanisme que CHN-3 :
```dart
import '../modules/chains/screens/network_roles_screen.dart';
```
utilisé à la route `/network/roles` (ligne 1365, `const NetworkRolesScreen()`). Fichier et classe absents, confirmé par le même listing. Même gravité que CHN-3 (import dans `app_router.dart`).

**Récapitulatif CHN-1 à CHN-4** : quatre imports non résolus, découverts en croisant systématiquement chaque `import` du module avec un listing intégral et à jour des dossiers `models/`, `widgets/` et `screens/` de `chains/` — une méthode de vérification plus systématique que la simple relecture ligne à ligne utilisée jusqu'ici, qui explique la découverte simultanée de quatre défauts de cette nature (contre un seul, au mieux, dans les modules précédents). Deux de ces quatre défauts (CHN-3, CHN-4) se trouvent dans le routeur global de l'application.

### CHN-5 — Motif systémique `auth.uid() = pharmacy_id` sur la quasi-totalité des policies du module (Critique — confirmé par exécution réelle en Étape 3)

`20260829000000_chains.sql` compare à de multiples reprises `auth.uid()` (un identifiant **utilisateur**) à des colonnes qui référencent `public.pharmacies(id)` (un identifiant **d'officine**) — motif déjà rencontré et déjà corrigé ailleurs dans le projet (`stock_forecasting.sql`), au moyen du helper `public.is_pharmacy_staff(target_pharmacy_id)`. Dans ce module, une seule policy sur six avait reçu ce correctif, et seulement à moitié :

```sql
-- "Members view group members" (select) — jamais vraie
and gm.pharmacy_id = auth.uid()

-- "Admins manage group members" (all) — jamais vraie
and gm.pharmacy_id = auth.uid()

-- "Involved pharmacies view transfers" (select) — jamais vraie, aucune branche corrigée
auth.uid() in (from_pharmacy_id, to_pharmacy_id) or
... gm.pharmacy_id = auth.uid() ...

-- "Admins manage transfers" (all) — corrigée UNIQUEMENT sur sa branche OR secondaire
... gm.pharmacy_id = auth.uid() ...   -- toujours cassée
or public.is_pharmacy_staff(from_pharmacy_id)   -- correcte

-- "Transfer items viewable with transfer" (select) — jamais vraie
-- "Transfer items managed with transfer" (all) — jamais vraie
```

**Conséquence logique — confirmée par exécution réelle en Étape 3** :
- `group_members` : aucune des deux policies ne pouvait jamais être satisfaite — personne ne pouvait lire ni gérer la liste des officines membres d'un groupe via l'API applicative.
- `stock_transfers` en lecture : seule la pharmacie d'origine (via la branche correcte de la policy ALL) pouvait lire un transfert ; la pharmacie **destinataire** ne pouvait jamais le voir.
- `stock_transfers` en écriture : seule la pharmacie d'origine pouvait faire évoluer le statut — la pharmacie destinataire ne pouvait jamais elle-même faire passer un transfert à `received`, précisément le geste que `transfer_detail_screen.dart` propose pourtant à l'écran (bouton « Marquer comme reçu », voir CHN-6).
- `transfer_items` : ni lecture ni écriture n'était jamais possible pour quiconque via l'API applicative.

### CHN-6 — Miroir côté client du même motif : `isFromPharmacy`/`isToPharmacy` comparent un id pharmacie à un id utilisateur

`transfer_detail_screen.dart`, lignes 54-58 :
```dart
final isFromPharmacy =
    transfer.fromPharmacyId == SupabaseService().currentUser?.id;
final isToPharmacy =
    transfer.toPharmacyId == SupabaseService().currentUser?.id;
final canManage = isFromPharmacy || isToPharmacy;
```
Même erreur de nature que CHN-5, mais côté client cette fois — même famille de défaut que PRE-6 (Module 25). Conséquence : `canManage` était structurellement (quasiment) toujours `false`, quel que soit le compte connecté.

### CHN-7 — RG-CHN-01 (seule règle du module) non appliquée : ni mouvements symétriques, ni contrôle de péremption

Trois constats convergents, tous confirmés par lecture directe :

1. **Aucune saisie de lot/péremption dans l'UI.** `transfer_create_screen.dart` ne collectait que le produit et la quantité.
2. **Aucun mouvement de stock réel généré.** Ni `ChainService.createTransfer()` ni `updateTransferStatus()` ne référençaient `stock_movements`/`stock_batches`/`stock_items`.
3. **Données mockées côté création.** Listes codées en dur (`_mockPharmacies`/`_mockProducts`, identifiants non-UUID).

### CHN-8 — Défaut fonctionnel mineur : bascule actif/inactif inopérante dans `group_edit_screen.dart`

Callback `onChanged` vide sur le `Switch` d'activation — gravité mineure, aucun impact sécurité.

### CHN-9 — Motif D6, 24ème occurrence : aucune entrée de menu pour `/chains` ni `/network`

Confirmé par lecture complète de `_navItems`/`_effectiveNavItems()` dans `dashboard_screen.dart`.

---

## 5. Observations de périmètre (non-défauts, à l'ouverture)

- **Écrans principaux du cahier — couverture confirmée à ce stade** : « Vue groupement multi-officines », « Transfert de stock inter-sites », « Reporting consolidé » existent tous les trois sous une forme ou une autre.
- **Écart de périmètre cahier confirmé absent** : « politique de prix/promotions à l'échelle du groupement ou par officine » (4ème fonctionnalité clé du cahier).
- **Question de contrat de données, non tranchée à ce stade** : coexistence de `pharmacies.group_id` et de `public.group_members` — résolue en Étape 2, voir §6.
- Le troisième fichier de migration du cluster (`20260829006000_pos_and_network_admin.sql`) est confirmé entièrement neutralisé (audit Module 0).

---

## 6. Étape 2 — Analyse comparative

### 6.1 RG-CHN-01 au regard du cahier

Le cahier exige que « un transfert de stock inter-officines génère deux mouvements symétriques tracés (sortie/entrée) et ne peut porter que sur des lots non expirés ». À l'ouverture, aucun des deux volets n'était applicable : la donnée de lot/péremption n'était même pas saisie (CHN-7 point 1), et aucune écriture dans le grand livre de stock (module STK, Module 4) n'existait (CHN-7 point 2). Le correctif (§8, CHN-7) couvre la totalité de la règle : saisie obligatoire en UI, revalidation serveur à l'insertion (lot/péremption non nuls, non expirés au moment de la saisie), et génération réelle des deux mouvements symétriques à la réception, avec **revalidation de la péremption au moment réel du mouvement** (le cahier ne précise pas explicitement ce point, mais la formulation « ne peut porter que sur des lots non expirés » est ici interprétée au sens le plus strict et le plus protecteur : un lot valide à la création d'un transfert peut légitimement expirer avant sa réception effective, parfois plusieurs jours après — c'est ce cas précis que le trigger de réception revérifie, voir Test 14 §7).

### 6.2 Contrat de données `pharmacies.group_id` vs `group_members` — tranché

Recherche ciblée hors du dossier `chains/` (grep sur `group_id`/`groupId` dans tout `lib/`) : le champ `pharmacies.group_id` est bien lu ET écrit, mais **par un module distinct, non encore audité sous cette numérotation** — `lib/modules/admin/` (`AdminService.createPharmacy()`/`updatePharmacy()`, via `AdminPharmacy.toJson()` qui sérialise `group_id`). Ce module back-office GSG (probablement rattaché à l'administration de plateforme du Kernel, hors périmètre strict du cahier CHN) permet donc à un administrateur de plateforme de taguer une officine avec un groupe au moment de sa création/édition — un mécanisme **entièrement séparé** de `group_members`, seul mécanisme utilisé par CHN (RLS, `ChainService`, `ChainProvider`).

**Conclusion** : ce ne sont pas deux mécanismes redondants par erreur, mais deux couches réelles et actives, non synchronisées entre elles : `pharmacies.group_id` est une étiquette simple posée par le back-office (consommée uniquement par la vue matérialisée `network_dashboard`, à titre de regroupement de reporting), tandis que `group_members` est la table de gouvernance opérationnelle du module CHN (adhésion multiple possible, rôles admin/manager/viewer, statut actif/inactif, RLS). **Rien ne garantit leur cohérence** : une officine peut avoir `pharmacies.group_id = G1` tout en n'ayant aucune ligne dans `group_members` pour G1 (auquel cas elle apparaît dans le reporting consolidé de G1 sans jamais pouvoir voir ni recevoir de transfert pour ce groupe), ou inversement être membre opérationnel de `group_members` pour un groupe différent de celui tagué dans `pharmacies.group_id`. Ce risque de désynchronisation est réel mais **hors du périmètre strict de CHN** (la table `pharmacies` et le module `admin` n'appartiennent pas à ce module) — consigné en **D45** (voir §9), pas corrigé ce tour : le corriger impliquerait de modifier soit le module `admin` (non audité, non scellé), soit d'ajouter une synchronisation automatique (trigger) entre les deux tables, ce qui dépasse le mandat donné pour ce tour (feuille de route à 5 points, aucun ne couvrant ce point).

### 6.3 Écart de périmètre confirmé : pricing/promotions groupement

Recherche exhaustive (mots-clés `pricing`, `promotion`, `discount`, `tarif`) dans tout `lib/modules/chains/` et dans les 2 migrations du module : aucune table, aucun écran, aucune mention. La 4ème fonctionnalité clé du cahier (« politique de prix/promotions à l'échelle du groupement ou par officine ») est confirmée absente, sans ambiguïté. Différée en **D44** (voir §9), même famille que les écarts de périmètre cahier des modules précédents (D28/D29/D31/D32/D34/D36/D37/D39/D41/D43).

---

## 7. Étape 3 — Sécurité & résilience (exécution réelle Postgres 16)

### 7.1 Migration corrective

`20260830051000_chains_module_fixes.sql`, postérieure à `chains.sql`/`network_admin.sql` (29/08) et à `admin_helpers.sql` (dont dépend `is_pharmacy_staff()`), sur le modèle des migrations correctives des Modules 19-25 (édition en place évitée pour préserver le rejeu chronologique).

**CHN-5** : les 6 policies réécrites via `public.is_pharmacy_staff()`, chacune ajoutant l'accès manquant à l'officine destinataire (`to_pharmacy_id`).

**CHN-5-bis (découvert en cours de vérification par exécution réelle, non identifié à l'ouverture)** : la première version du correctif de la policy `"Members view group members"` échouait systématiquement à l'exécution avec `ERROR: infinite recursion detected in policy for relation "group_members"` (Test 1, confirmé par exécution réelle). Cause : la policy contenait une sous-requête `select ... from public.group_members gm where ...` **sur la table même qu'elle protège** — évaluer la policy exige de ré-évaluer la même policy sur les lignes de la sous-requête, indéfiniment. Corrigé en isolant la vérification d'appartenance dans une fonction dédiée `public.is_group_member(target_group_id uuid, min_role text default null)`, `SECURITY DEFINER` (même principe que `is_pharmacy_staff()`) : exécutée avec les privilèges du propriétaire de la table, elle sort la sous-requête interne du contexte RLS et supprime la récursion. Les policies de `group_members`, et les sous-requêtes vers `group_members` dans les policies de `stock_transfers`/`transfer_items`, appellent désormais toutes cette fonction plutôt que d'interroger `group_members` directement. **Portée méthodologique** : ce type d'erreur (policy auto-référente sur sa propre table) n'est détectable ni par relecture du SQL ni par traçage logique — seule l'exécution réelle contre un vrai moteur PostgreSQL 16 l'a révélée, confirmant une fois de plus la nécessité de cette étape (déjà établie depuis PRE-2/ASR-1).

**CHN-7** : deux triggers ajoutés — `chn_validate_transfer_item()` (BEFORE INSERT/UPDATE sur `transfer_items`, rejette lot manquant/vide, péremption nulle, ou péremption déjà passée à la saisie) et `chn_process_transfer_receipt()` (AFTER UPDATE sur `stock_transfers`, `SECURITY DEFINER`, déclenché uniquement sur transition vers `received`) : pour chaque article du transfert, revérifie la disponibilité du lot source, sa non-péremption **au moment réel de la réception**, la quantité suffisante, puis génère les deux mouvements symétriques réels (décrément `stock_items`/`stock_batches` source + `stock_movements` négatif ; upsert `stock_items`/`stock_batches` destination + `stock_movements` positif), avec `reference_id` commun aux deux mouvements pour la traçabilité. `SECURITY DEFINER` retenu car `stock_items`/`stock_batches`/`stock_movements` (module STK, Module 4, hors périmètre de cet audit) n'exposent aujourd'hui aucune policy d'écriture pour `authenticated` — plutôt que d'élargir les droits d'écriture d'un module tiers non audité, le mouvement réel est encapsulé sous ses propres privilèges, même principe que `is_pharmacy_staff()`/`is_gsg_admin()`. Ce gap RLS pré-existant de STK (lecture seule pour `authenticated`, aucune écriture) est noté pour mémoire, non corrigé (hors périmètre CHN), voir C131 en section C du registre.

**Défauts de compilation/câblage découverts en cours de correctif (non identifiés à l'ouverture, même famille qu'ASR-8/C105)** :
- **CHN-10** : `TransferItem` (dans `stock_transfer.dart`) n'avait aucune méthode `copyWith()`, alors que `ChainService.addTransferItem()` l'appelle (`item.copyWith(id: id, createdAt: now, updatedAt: now)`) — défaut de compilation certain, même famille qu'ASR-8. Corrigé.
- **CHN-11** : `ChainProvider.saveTransfer()` ne persistait jamais `transfer.items` — ni cette méthode ni `ChainService.createTransfer()` n'appelaient `addTransferItem()` pour chaque article ; les articles saisis en écran de création étaient donc systématiquement perdus, sans erreur visible. Même famille que C105 (Module 22/FAM, « câblage manquant »). Corrigé — `saveTransfer()` boucle désormais sur `transfer.items` et appelle `addTransferItem()` pour chacun après la création du transfert parent.

### 7.2 Vérification par exécution réelle (Postgres 16)

Harnais dédié `chn_rls_test.sql`, exécuté contre la chaîne complète des **90 migrations** (89 + le correctif ci-dessus), rôle `authenticated` distinct du propriétaire, RLS effectivement active, `GRANT` par défaut Supabase reproduits. **14 scénarios, 14/14 conformes** :

| # | Scénario | Résultat attendu | Résultat obtenu |
|---|---|---|---|
| 1 | Staff A (membre actif du groupe G) lit `group_members` | ≥1 ligne | ✅ 2 lignes |
| 2 | Staff C (hors groupe) lit `group_members` de G | 0 ligne | ✅ 0 ligne |
| 3 | Staff D (admin du groupe G) ajoute un membre | Réussit | ✅ Réussi |
| 4 | Staff A (staff, pas admin, dans G) tente d'ajouter un membre | Échoue (RLS) | ✅ Bloqué |
| 5 | Staff A (officine source) lit le transfert T1 | 1 ligne | ✅ 1 ligne |
| 6 | Staff B (officine **destinataire**) lit le transfert T1 | 1 ligne (0 avant correctif) | ✅ 1 ligne — CHN-5 confirmé résolu |
| 7 | Staff C (tiers, membre viewer du groupe) lit T1 | 0 ligne | ✅ 0 ligne — viewer insuffisant, conforme |
| 8 | Staff B (destinataire) fait passer T1 à `approved` | Réussit | ✅ Réussi — CHN-5/CHN-6 confirmés résolus |
| 9 | Staff B (destinataire) lit `transfer_items` de T1 | ≥1 ligne (0 avant correctif) | ✅ 1 ligne |
| 10 | Insertion d'un article avec lot périmé | Échoue (RG-CHN-01) | ✅ Bloqué |
| 11 | Insertion d'un article sans numéro de lot | Échoue (RG-CHN-01) | ✅ Bloqué |
| 12 | Réception réelle de T1 (chemin nominal complet) | 2 mouvements symétriques réels, stock A -10, stock B +10 | ✅ Confirmé (100→90 côté A, 0→10 côté B, 2 lignes `stock_movements`) |
| 13 | Réception avec quantité demandée > solde du lot | Échoue (RG-CHN-01) | ✅ Bloqué |
| 14 | Réception d'un lot expiré **entre la création et la réception** du transfert | Échoue (RG-CHN-01, revalidation au moment réel) | ✅ Bloqué |

**Observation annexe, hors périmètre CHN, notée sans correction** : la mise en place du harnais de test a nécessité de désactiver temporairement (`alter table ... disable/enable trigger`) les triggers `trigger_log_pharmacy_changes`/`trigger_log_user_changes` (`log_network_activity()`, hors module CHN) pendant les insertions de test non authentifiées, ce trigger échouant sur `admin_user_id` NOT NULL quand `auth.uid()` est NULL — défaut pré-existant, hors périmètre de ce tour, consigné en C132.

---

## 8. Récapitulatif des correctifs appliqués

| Défaut | Nature | Correctif |
|---|---|---|
| CHN-1 | Import inexistant | Import supprimé, `TransferItem` déjà accessible via `stock_transfer.dart` |
| CHN-2 | Import inexistant | Nouveau fichier `network_alert_card.dart` (`NetworkAlertCard`) |
| CHN-3 | Import inexistant (routeur global) | Nouveau fichier `network_alerts_screen.dart` (`NetworkAlertsScreen`) |
| CHN-4 | Import inexistant (routeur global) | Nouveau fichier `network_roles_screen.dart` (`NetworkRolesScreen`) |
| CHN-5 | RLS, motif `auth.uid()=pharmacy_id` (6 policies) | Migration corrective, `is_pharmacy_staff()` + accès destinataire |
| CHN-5-bis | Récursion RLS (découvert en exécution réelle) | Fonction `is_group_member()` SECURITY DEFINER |
| CHN-6 | Miroir client du motif CHN-5 | `isFromPharmacy`/`isToPharmacy` recalculés via `AuthProvider.pharmacyId` |
| CHN-7 | RG-CHN-01 non appliquée (3 angles) | UI (lot/péremption obligatoires) + trigger validation insertion + trigger réception avec mouvements réels |
| CHN-8 | Switch actif/inactif inopérant | `onChanged` câblé, état local + persistance |
| CHN-9 | D6, 24ème occurrence | 2 entrées de menu ajoutées (`/chains`, `/network`) |
| CHN-10 | `copyWith()` manquant (compilation) | Méthode ajoutée à `TransferItem` |
| CHN-11 | Articles de transfert jamais persistés (câblage) | `saveTransfer()` boucle sur `addTransferItem()` |

---

## 9. Décisions différées (non corrigées ce tour)

- **D44** : politique de prix/promotions à l'échelle du groupement (4ème fonctionnalité clé du cahier), confirmée absente — chantier de conception dédié, même famille que D28/D29/D31/D32/D34/D36/D37/D39/D41/D43.
- **D45** : absence de synchronisation entre `pharmacies.group_id` (posé par le back-office `admin`, non audité) et `public.group_members` (gouvernance opérationnelle de CHN) — deux mécanismes réels et actifs, non redondants par erreur mais non synchronisés ; risque de désalignement entre le reporting consolidé (basé sur `group_id`) et l'accès/gouvernance réels (basé sur `group_members`). Nécessite soit une correction dans le module `admin` (non audité, non scellé), soit un trigger de synchronisation dédié — hors mandat de ce tour.

---

## 10. Clôture

Séquence complète des 3 étapes menée en un seul tour, sur feu vert explicite et complet du porteur du projet (feuille de route à 5 points). Douze défauts corrigés au total (CHN-1 à CHN-11, plus CHN-5-bis découvert en cours de vérification), dont deux découverts uniquement en traçant les appelants réels pendant le correctif (CHN-10, CHN-11 — même famille qu'ASR-8/C105) et un uniquement par exécution réelle contre Postgres 16 (CHN-5-bis — récursion RLS, une classe d'erreur inédite dans cet audit). Migration corrective (`20260830051000_chains_module_fixes.sql`) validée par un harnais dédié de 14 scénarios, **14/14 conformes**, sur la chaîne complète des 90 migrations. Deux décisions différées consignées (D44, D45), aucune ne bloquant la sécurité ou le fonctionnement réel du module tel que livré. Navigation exposée immédiatement (24ème occurrence de D6). Voir `PharmaConnect_Module26_PV_Recette.md` pour la décision de recette formelle.
