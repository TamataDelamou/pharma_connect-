# PharmaConnect — Audit Module 6 : RES (Réservation & Retrait en officine / Click & Collect)

**Date :** 29/08/2026
**Périmètre :** `lib/modules/reservations/` (17 fichiers Dart), `supabase/migrations/20260827001100_reservations.sql`, plus les points d'intégration avec `lib/modules/stock/` (Module 4, STK) sollicités par ce module.

---

## 1. Inspection & rapport de situation

### 1.1 Panorama du module

Le module RES couvre le parcours « panier → validation → réservation → file d'attente pharmacien → retrait ». Il est structurellement complet côté UI (panier, 5 écrans, 6 widgets) et côté modèle (`Reservation`, `ReservationItem`, `ReservationStatus`, `TimeSlot`), avec une couverture RLS et un couplage au moteur de stock qui, eux, étaient largement absents avant cet audit.

| Fichier | Rôle | État avant audit |
|---|---|---|
| `models/reservation.dart` | Modèle réservation, getters d'état (`isCancelable`, `isRunningOutOfTime`, etc.) | Correct, inchangé |
| `models/reservation_item.dart` | Ligne de panier/réservation | Correct, inchangé |
| `models/reservation_status.dart` | Enum de statut | Correct, inchangé |
| `models/timeslot.dart` | Créneau horaire | Correct, inchangé |
| `services/reservation_service.dart` | Accès Supabase | Créait des réservations sans jamais toucher au stock — corrigé |
| `providers/reservation_provider.dart` | État applicatif, panier, file d'attente | Bug critique (file d'attente jamais peuplée), aucun mode hors-ligne — corrigé |
| `screens/cart_screen.dart` | Panier | Correct, inchangé |
| `screens/reservation_checkout_screen.dart` | Tunnel de commande (4 étapes) | Identité patient en dur, aucune étape de créneau — corrigé |
| `screens/pharmacy_queue_screen.dart` | File d'attente pharmacien | Identité officine en dur, aucun contrôle d'accès — corrigé |
| `screens/reservation_confirmation_screen.dart` | Écran de confirmation post-commande (QR) | Correct, inchangé |
| `screens/reservation_history_screen.dart` | Historique patient | Identité patient en dur — corrigé |
| `screens/reservation_qr_screen.dart` | QR de retrait | Correct, inchangé |
| `widgets/cart_item_tile.dart`, `checkout_step_indicator.dart`, `queue_position_widget.dart`, `reservation_status_card.dart` | Widgets d'affichage | Corrects, inchangés |
| `widgets/timeslot_picker.dart` | Sélecteur de créneau | Entièrement fonctionnel mais **orphelin** (aucun call site) — désormais câblé |

### 1.2 Respect des règles métier (cahier de conception)

| Règle | Constat avant audit | Après correctifs |
|---|---|---|
| RG-RES-01 (le stock affiché doit refléter les réservations en cours) | **Violée.** `StockService.reserveStock/confirmReservation/cancelReservation` (Module 4, FEFO, déjà audités corrects) avaient zéro appelant dans toute l'application — `ReservationService.createReservation` insérait directement dans `reservations`/`reservation_items` sans jamais réserver de stock | Corrigé — voir §4.1 |
| RG-RES-02 (expiration automatique au-delà du délai de retrait) | **Absente.** Aucune trace de gestion du dépassement de `pickup_deadline` | Implémentée en balayage opportuniste — voir §4.2 (limite documentée en A12) |
| « Réservation avec créneau de retrait » (fonctionnalité clé du cahier) | **Non exploitée en pratique.** `TimeslotPicker` et `loadAvailableSlots`/`selectSlot` existaient mais n'étaient appelés par aucun écran ; `preferredPickupTime` restait donc toujours `null` | Câblée dans le tunnel de commande — voir §5.2 |
| Accès pharmacien à la file d'attente de son officine | **Non fonctionnel** à deux niveaux distincts : RLS (aucune policy de lecture pour le personnel) et code (bug qui vidait systématiquement la liste affichée) | Corrigé aux deux niveaux — voir §3.1 et §4.3 |

### 1.3 Qualité du code et choix d'implémentation

Le code est propre et suit les conventions déjà établies dans les modules précédents (getters dérivés sur les modèles, séparation service/provider/écran, `copyWith`). Deux défauts de fond ont cependant été relevés à l'inspection, indépendamment des trois écarts métier ci-dessus :

- **Identité utilisateur en dur, quatrième et cinquième occurrence** du même motif déjà signalé aux Modules 4 et 5 : `'patient_123'`/`'Jean Dupont'`/`'+224612345678'` dans `reservation_checkout_screen.dart` et `reservation_history_screen.dart`, et `'ph_1'` dans `pharmacy_queue_screen.dart`. Au-delà de l'incohérence produit, `reservations.patient_id`/`pharmacy_id` sont de type `uuid` : ces écrans ne pouvaient fonctionner pour aucun compte réel une fois les policies d'écriture ouvertes.
- **Bug critique dans `ReservationProvider.refreshQueue()`** (détaillé en §4.3) : la file d'attente pharmacien était silencieusement non fonctionnelle depuis sa création, alors que le code compilait et s'exécutait sans erreur visible — le genre de défaut qu'une revue de code attentive attrape, mais qu'un simple test manuel de la happy path (avec des données factices déjà présentes en mémoire) aurait pu manquer.

---

## 2. Analyse comparative (code vs cahier de conception)

L'écart le plus significatif de ce module est **architectural** plutôt que ponctuel : un moteur de réservation de stock complet, FEFO-correct et déjà audité (Module 4) existait dans le projet, et le module dont c'était précisément la raison d'être (RES — réservation) ne l'utilisait pas. Ce n'est pas un oubli de détail mais une désynchronisation entre deux modules codés indépendamment sans référence croisée — le même motif que la dérive de gouvernance documentaire déjà signalée en D6 (code orphelin ou mal cartographié), ici sous une forme plus grave : ce n'est pas le nouveau code qui est orphelin, c'est l'ancien qui n'a jamais été rattaché.

Le deuxième écart notable est la fonctionnalité de créneau de retrait, présentée par le cahier comme une caractéristique du parcours Click & Collect, mais réduite en pratique à du code mort. C'est la même famille de défaut que `UploadGuidanceOverlay` au Module 5 : un composant fini, jamais relié.

Techniquement, aucune dette de conception nouvelle n'a été introduite par les correctifs — ils réutilisent scrupuleusement les patrons déjà établis (compensation best-effort sans transaction cross-table, cache `owner_key`-partitionné, garde d'erreur `&& liste.isEmpty`, distinction visuelle hors-ligne/erreur), pour rester cohérents avec le reste du projet plutôt que d'introduire un nouveau style de résolution d'incident propre à ce module.

---

## 3. Sécurité & résilience

### 3.1 RLS — écriture totalement absente, lecture pharmacien totalement absente

`20260827001100_reservations.sql` n'ouvrait que deux policies, toutes deux `select`, toutes deux limitées au patient propriétaire (`reservations_select_own`, `reservation_items_select_own`). Concrètement, avant correctif :

- Un patient ne pouvait **pas déposer** de réservation (RLS refuse tout INSERT par défaut) — le bouton « Confirmer la commande » échouait systématiquement en production.
- Aucun pharmacien ne pouvait **lire** ne serait-ce qu'une seule réservation de son officine, encore moins la confirmer, la marquer prête ou retirée.
- Le commentaire d'origine de la migration anticipait cette lacune côté lecture pharmacien mais la justifiait par l'absence de `is_pharmacy_staff` — **cette justification ne tenait déjà plus au moment où RES a été codé** : `is_pharmacy_staff(pharmacy_id)` existe depuis le Module 0/1, et `reservations.pharmacy_id` (contrairement à `prescriptions.patient_id`-only) est présent et `NOT NULL`. Il n'y avait donc aucune raison technique de laisser cette policy de côté.

**Correctif** (`20260829017000_reservations_module_fixes.sql`) : six nouvelles policies — `reservations_staff_select`, `reservations_insert_own`, `reservations_patient_update`, `reservations_staff_update`, `reservation_items_staff_select`, `reservation_items_insert_own` — toutes scopées via `is_pharmacy_staff(pharmacy_id)` côté pharmacien et `auth.uid() = patient_id` côté patient. Limite assumée et documentée (item C22 du registre, même famille que C18 pour prescriptions) : RLS n'interdit pas au patient de modifier n'importe quelle colonne de sa propre réservation (y compris, en théorie, son propre statut) — seule la couche applicative propose les transitions valides.

### 3.2 RG-RES-01 — le vrai trou de sécurité métier de ce module

Avant correctif, une réservation ne bloquait **aucune** quantité de stock. Deux patients pouvaient réserver le dernier exemplaire d'un produit en rupture imminente, chacun recevant une confirmation, avec un seul retrait effectivement honorable — un défaut qui, en pharmacie, dépasse le simple bug produit. Traité en détail au §4.1.

### 3.3 Accès et rôles côté client

`pharmacy_queue_screen.dart` n'avait aucun contrôle de rôle : tout compte authentifié pouvait afficher la file d'attente d'une officine (noms, téléphones et paniers de patients tiers) et actionner « Prêt »/« Retiré ». Corrigé par un gate `AuthProvider.userRole == UserRole.pharmacien`, même patron que `prescription_detail_screen.dart` (Module 5).

### 3.4 Résilience — absence de transaction et compensation

Aucune des écritures multi-tables de ce module (réservation + lignes + réservation de stock ligne par ligne) ne bénéficie d'une vraie transaction — limite déjà connue et acceptée dans tout le projet (client Supabase/PostgREST sans transaction cross-table exposée). Les correctifs de ce module ajoutent une compensation best-effort explicite (libération du stock déjà réservé si une ligne suivante échoue, ou si l'écriture finale de la réservation échoue) plutôt que de laisser du stock bloqué sans réservation qui le justifie — mais cette compensation elle-même n'est pas garantie (un deuxième échec réseau pendant la libération laisse un résidu, silencieusement avalé par le `catch (_) {}`). Documenté, pas éliminé : c'est une limite structurelle de l'architecture, pas un défaut de ce module en particulier.

---

## 4. Optimisation & améliorations (implémentées ce module)

### 4.1 RG-RES-01 — câblage du moteur de réservation de stock (correction métier majeure)

`ReservationService` appelle désormais `StockService` :

- **`createReservation`** : réserve chaque ligne du panier (`reserveStock`, FEFO) avant d'écrire quoi que ce soit dans `reservations`/`reservation_items` ; libère (`cancelReservation`) tout ce qui a déjà été réservé si une ligne suivante échoue par rupture, ou si l'écriture finale échoue.
- **`markAsPickedUp`** : finalise la vente (`confirmReservation`) — décrémente réellement le stock au moment du retrait physique.
- **`cancelReservation`** : libère le stock (`cancelReservation`) uniquement si la réservation le retenait encore (`pending`/`confirmed`/`ready` — jamais après un retrait déjà finalisé).

C'est la correction la plus importante de ce module : elle relie un moteur déjà construit et déjà validé (Module 4) au module qui en avait besoin depuis le début, sans réécrire ni retoucher ce moteur lui-même.

### 4.2 RG-RES-02 — expiration automatique

`ReservationService.expireOverdueReservations()` (nouveau) : balaie les réservations `pending`/`confirmed`/`ready` dont `pickup_deadline` est dépassé, libère le stock retenu, les passe à `expired`. Déclenché de façon opportuniste par `ReservationProvider` à l'ouverture de « mes réservations » (patient) et de la file d'attente (pharmacien) — aucune infrastructure de tâche planifiée n'existe dans ce projet (même limite déjà rencontrée ailleurs), donc pas de vraie tâche de fond. Limite documentée en A12 : une réservation expirée entre deux ouvertures de ces écrans reste bloquée jusqu'au prochain passage. Le « rappel automatique avant expiration » mentionné par le cahier n'a pas été implémenté (aucune infrastructure de notification dans le projet) — documenté en D9 comme décision à trancher plutôt que traité en silence.

### 4.3 Bug critique corrigé — file d'attente pharmacien toujours vide

`refreshQueue()` ne réassignait jamais son champ `_reservations` avec les données fraîchement récupérées pour l'officine ; il ne faisait que tenter de corriger, par id, des entrées dans l'ancienne liste en mémoire — jamais peuplée pour ce cas d'usage puisque `pharmacy_queue_screen.dart` n'appelle ni `loadReservations` ni `loadPatientReservations`. Résultat : l'écran affichait en permanence « Aucun client en file d'attente », quel que soit le nombre réel de réservations en attente. Corrigé, avec en prime la persistance côté serveur de la position de file recalculée (`ReservationService.updateQueuePosition`, nouveau) — jusqu'ici recalculée seulement en mémoire locale du pharmacien, jamais réécrite : un patient consultant sa propre réservation depuis un autre appareil voyait une position figée à celle du moment de la création.

### 4.4 Mode hors-ligne (directive standing)

`ReservationProvider` n'avait aucune gestion hors-ligne. Ajouté, même patron que Modules 4/5 :

- `OfflineSyncService` v4→v5 : nouvelle table `cache_reservations`, partitionnée par `owner_key` (`patientId` côté patient, `'staff_queue_<pharmacyId>'` côté pharmacien — pour ne jamais mélanger les deux vues sur un même appareil).
- `loadPatientReservations`/`refreshQueue` : cache la dernière lecture réussie, s'y replient avec un message informatif non bloquant en cas d'échec réseau (jamais un écran d'erreur qui masquerait des données déjà en cache — garde `&& reservations.isEmpty` appliquée aux deux écrans concernés).
- `createReservation` : file d'attente locale (`_queueOfflineReservation`) si le réseau est absent ou si l'appel réseau échoue techniquement — mais **pas** si le refus est un vrai motif métier (stock insuffisant, détecté en ligne) : ce cas est distingué explicitement (`on StateError { rethrow; }`) pour ne jamais le masquer derrière une file d'attente qui échouerait de la même façon à la synchronisation. Limite documentée en C21 : une réservation créée hors-ligne ne bloque pas réellement le stock avant sa synchronisation (le blocage lui-même est un appel réseau, non transposable dans une simple file d'écriture).

### 4.5 UX & fonctionnalité — créneau de retrait (directives standing 1 et 4)

`TimeslotPicker`, entièrement construit mais orphelin, est désormais câblé dans le tunnel de commande comme une étape à part entière (« Créneau », entre « Récapitulatif » et « Livraison »), avec navigation par jour et rechargement des créneaux disponibles à chaque changement de date/officine. Le choix reste optionnel (le champ `pickup_time` est nullable côté schéma) avec un message explicite si le patient passe l'étape. C'est à la fois une amélioration UX (le patient sait quand passer) et une fonctionnalité clé du cahier jusqu'ici invisible en pratique — `preferredPickupTime` n'était jamais renseigné avant ce module.

Deux bandeaux hors-ligne (patient et pharmacien) et un message de confirmation explicite (« la commande est enregistrée sur cet appareil… ») ont été ajoutés, cohérents avec le traitement déjà en place pour les ordonnances.

---

## 5. Documentation API (services)

### `ReservationService`

| Méthode | Description | Changé ce module |
|---|---|---|
| `getReservations({status})`, `getReservation(id)`, `getReservationsForPharmacy(pharmacyId)`, `getReservationsForPatient(patientId)` | Lecture | Non |
| `createReservation({...})` | Crée une réservation : réserve le stock ligne par ligne (FEFO, via `StockService`) puis écrit `reservations`/`reservation_items` ; compensation best-effort en cas d'échec partiel. Lève `StateError` si le stock est insuffisant | **Oui** |
| `confirmReservation(id)` | Transition `pending`→`confirmed`, recalcule la position de file | Non |
| `markAsReady(id)` | Transition →`ready` | Non |
| `markAsPickedUp(id)` | Transition →`pickedUp` ; finalise la vente (`StockService.confirmReservation` par ligne) | **Oui** |
| `cancelReservation(id, {reason})` | Transition →`cancelled` ; libère le stock retenu si la réservation le retenait encore | **Oui** |
| `expireOverdueReservations({pharmacyId})` | **Nouveau.** Balaie et expire les réservations dont le délai de retrait est dépassé, libère le stock | **Oui** |
| `updateQueuePosition(id, {position, estimatedWaitMinutes})` | **Nouveau.** Persiste côté serveur une position de file recalculée | **Oui** |
| `getAvailableTimeSlots({pharmacyId, date})` | Créneaux simulés (aucune table dédiée) — inchangé, documenté comme tel dans le code d'origine | Non |

### `ReservationProvider`

Ajouts : `isOffline`, cache/repli hors-ligne sur `loadPatientReservations`/`refreshQueue`, `_queueOfflineReservation`, correction de `refreshQueue` (voir §4.3), persistance de la position de file.

---

## 6. Scénarios de test (à exécuter — non exécutés dans cette session, voir registre A11-A13)

1. **RG-RES-01, cas nominal** : réserver un produit dont le stock disponible est 3 → vérifier que la quantité disponible affichée ailleurs (Module 4, recherche/stock) diminue immédiatement à 2. Retirer la réservation → vérifier que le stock total diminue réellement. Annuler une réservation `pending` → vérifier que le stock disponible remonte à 3.
2. **RG-RES-01, rupture concurrente** : deux réservations quasi simultanées sur le dernier exemplaire → la seconde doit échouer proprement (message « Stock insuffisant… »), sans laisser la première dans un état incohérent.
3. **RG-RES-02** : créer une réservation, avancer artificiellement `pickup_deadline` dans le passé (via SQL direct sur l'environnement de test) → ouvrir « mes réservations » ou la file pharmacien → vérifier le passage à `expired` et la libération du stock.
4. **File d'attente pharmacien (non-régression du bug §4.3)** : connecter un compte pharmacien avec des réservations `pending`/`confirmed` existantes sur son officine → vérifier qu'elles apparaissent bien dans la file, dans le bon ordre.
5. **Étanchéité multi-officines** : connecter deux comptes pharmaciens d'officines différentes → vérifier qu'aucun ne voit les réservations de l'autre officine (RLS `is_pharmacy_staff`).
6. **Rôle non-pharmacien sur la file d'attente** : connecter un compte `patient` et tenter d'accéder à l'écran → vérifier le blocage.
7. **Créneau de retrait** : parcourir le tunnel de commande jusqu'à l'étape « Créneau », changer de date, sélectionner un créneau, terminer la commande → vérifier que `pickup_time` est bien renseigné en base (auparavant toujours `null`).
8. **Mode hors-ligne — lecture** : couper le réseau après un premier chargement réussi de « mes réservations »/la file d'attente → vérifier l'affichage du bandeau informatif et des données en cache, pas d'écran d'erreur bloquant.
9. **Mode hors-ligne — écriture** : couper le réseau, passer une commande → vérifier la mise en file d'attente locale, l'apparition immédiate dans l'historique, puis la synchronisation réelle au retour du réseau (`syncAll`).
10. **Identité réelle** : vérifier qu'aucun des trois écrans corrigés (checkout, historique, file d'attente) ne référence plus `'patient_123'`/`'ph_1'` et que les insertions Supabase utilisent bien l'uuid réel de l'utilisateur connecté.

---

## 7. Livrables de ce module

- `supabase/migrations/20260829017000_reservations_module_fixes.sql` (nouveau)
- `lib/core/services/offline_sync_service.dart` (v4→v5, `cache_reservations`)
- `lib/modules/reservations/services/reservation_service.dart`
- `lib/modules/reservations/providers/reservation_provider.dart`
- `lib/modules/reservations/screens/reservation_checkout_screen.dart`
- `lib/modules/reservations/screens/reservation_history_screen.dart`
- `lib/modules/reservations/screens/pharmacy_queue_screen.dart`
- `PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A11-A13, B16, C21-C24, D9 ; B7/B9/B13/C13/D6 annotés)
- Ce rapport

---

## Le module RES est-il totalement clos et validé pour passer au suivant ?

Sous réserve de votre validation, le prochain module serait le **Module 7 (LIV — Livraison & Logistique du dernier kilomètre)**, selon l'ordre confirmé à l'Étape 1.
