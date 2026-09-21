# PharmaConnect — Audit Module 7 : LIV (Livraison & Logistique du dernier kilomètre)

**Date :** 29/08/2026
**Périmètre :** `lib/modules/delivery/` (5 modèles, 1 service, 1 provider, 4 écrans, 4 widgets), `supabase/migrations/20260827001200_delivery.sql`, plus le point d'intégration avec `lib/modules/reservations/screens/reservation_checkout_screen.dart` (Module 6, RES) nécessaire pour rendre ce module atteignable depuis l'application.

---

## 1. Inspection & rapport de situation

### 1.1 Panorama du module

Le module LIV couvre le parcours « livraison programmée → assignation d'un livreur → prise en charge → suivi en temps réel → clôture par preuve de remise ». Il est structurellement complet côté modèle et côté service — cinq modèles riches, un service couvrant l'intégralité du cycle de vie d'une livraison — mais présentait, avant cet audit, le défaut le plus sévère rencontré depuis le début de cette série d'audits : **le point d'entrée du module entier n'avait aucun appelant**.

| Fichier | Rôle | État avant audit |
|---|---|---|
| `models/delivery.dart` | Modèle livraison, getters d'état (`statusLabel`, `isActive`, `progress`, etc.) | Correct, complété (`confirmationCode`) |
| `models/delivery_driver.dart` | Modèle livreur | Correct, inchangé |
| `models/delivery_proof.dart` | Preuve de remise (signature/photo/code) | Correct, inchangé |
| `models/delivery_route.dart` | `DeliveryRoute`/`RouteStop` — tournée multi-livraisons | Correct, mais **entièrement orphelin** — voir §1.2 et D10 du registre |
| `models/delivery_status.dart` | Enum de statut | Correct, inchangé |
| `services/delivery_service.dart` | Accès Supabase | `scheduleDelivery` sans aucun appelant ; RG-LIV-01/02 non appliquées côté serveur — corrigé |
| `providers/delivery_provider.dart` | État applicatif | Aucun mode hors-ligne, méthodes de lecture ciblées absentes, `notifyListeners()` manquant sur plusieurs chemins d'erreur — corrigé |
| `screens/delivery_schedule_screen.dart` | Planification/assignation (pharmacien) | Aucun contrôle d'accès — corrigé |
| `screens/delivery_tracking_screen.dart` | Suivi patient (carte, timeline) | Position toujours figée, fausse preuve de remise — corrigé |
| `screens/delivery_history_screen.dart` | Historique patient | Aucun mode hors-ligne, bug de garde d'erreur — corrigé |
| `screens/driver_dashboard_screen.dart` | Tableau de bord livreur | Identité livreur en dur, aucun contrôle d'accès, aucune position réelle, fausse preuve de remise — corrigé |
| `widgets/delivery_card.dart`, `delivery_status_badge.dart`, `delivery_timeline.dart`, `driver_info_card.dart` | Widgets d'affichage | Corrects, inchangés |

### 1.2 Respect des règles métier (cahier de conception)

| Règle | Constat avant audit | Après correctifs |
|---|---|---|
| Livraison à domicile (fonctionnalité clé du cahier) | **Inatteignable.** `DeliveryService.scheduleDelivery` — et donc tout le module LIV en aval — n'avait strictement aucun appelant dans l'application. `reservation_checkout_screen.dart` collectait une adresse de livraison depuis le Module 6 sans jamais l'exploiter | Corrigé — voir §4.1 |
| RG-LIV-01 (livreur certifié chaîne du froid pour une livraison qui l'exige) | **Filtrée côté UI uniquement.** Le sélecteur de livreur (`_DriverPickerSheet`) filtrait déjà correctement, mais rien n'empêchait un appel direct à `assignDriver()` avec un livreur non certifié — aucune défense en profondeur | Corrigée côté service — voir §3.2 |
| RG-LIV-02 (preuve de remise obligatoire à la clôture) | **Vidée de son sens.** Les deux écrans de clôture fabriquaient eux-mêmes un `confirmationCode` (`'CONF' + timestamp`) au moment du clic, jamais vérifié contre quoi que ce soit — toute tentative de clôture réussissait par construction, avec ou sans remise réelle | Corrigée — voir §3.3 |
| Suivi en temps réel de la course (fonctionnalité clé du cahier) | **Non réalisé.** `DeliveryService.updateLocation`/`updateDriverLocation` existaient mais n'avaient aucun appelant — la carte patient affichait en permanence la position figée au moment de la planification | Corrigé (sondage en avant-plan) — voir §4.2, limite documentée en C26 |

### 1.3 Qualité du code et choix d'implémentation

Le code est propre et suit les conventions déjà établies (getters dérivés, séparation service/provider/écran, `copyWith`, patron offline `owner_key`). Deux défauts de fond, indépendants des trois écarts métier ci-dessus :

- **Identité utilisateur en dur, sixième occurrence** du même motif déjà signalé aux Modules 4, 5 et 6 (`'admin'`, `'patient_123'`/`'ph_1'`, désormais `'drv_001'` dans `driver_dashboard_screen.dart`). `DeliveryDriver.id` n'a aucun rapport avec `auth.uid()` — cet écran ne pouvait fonctionner pour aucun livreur réel une fois les policies RLS de lecture correctement scopées.
- **`DeliveryProvider`** : les chemins d'erreur de `assignDriver`/`startDelivery`/`markAsArrived`/`completeDelivery`/`cancelDelivery` fixaient `_error` sans jamais appeler `notifyListeners()` — un écran qui observe le provider via `context.watch` (plutôt que de lire le résultat juste après l'`await`) ne se redessinait pas pour afficher l'échec. Même défaut structurel déjà corrigé pour `ReservationProvider` au Module 6.

---

## 2. Analyse comparative (code vs cahier de conception)

L'écart le plus significatif de ce module dépasse en gravité tout ce qui a été trouvé jusqu'ici dans cette série d'audits : ce n'est pas une règle métier mal appliquée ou une policy RLS manquante, c'est un **module entier construit et jamais relié au reste de l'application**. `DeliveryService`/`DeliveryProvider`/les quatre écrans existaient, étaient cohérents entre eux, et n'auraient jamais pu être atteints par un utilisateur réel : rien, nulle part dans l'application, ne créait de `Delivery`. C'est la cinquième occurrence du motif de gouvernance documentaire déjà signalé en D6 (code existant mais mal cartographié ou orphelin), et la plus grave — les précédentes concernaient un composant ou une méthode isolée (`TimeslotPicker` au Module 6, `UploadGuidanceOverlay` au Module 5), celle-ci concerne le point d'entrée de tout un module du cahier.

Un deuxième écart, de nature différente, mérite d'être noté sans être traité comme un défaut : le sous-système `DeliveryRoute`/`RouteStop` (planification de tournées multi-livraisons pour un livreur) est lui aussi entièrement construit et orphelin, mais **n'a pas été câblé ce module** — une décision délibérée plutôt qu'un oubli. Ce sous-système ne figure pas parmi les écrans principaux LIV listés au cahier ; le câbler aurait nécessité de construire un nouvel écran de « gestion des tournées », ce qui dépasse le périmètre audit-et-corrige de ce module. Documenté en D10 du registre comme décision à trancher : construire cet écran dans une prochaine itération, ou retirer ce sous-système comme code mort assumé.

La fausse preuve de remise (RG-LIV-02) est la même famille de défaut que le faux vérificateur de disponibilité et le simulateur de créneaux déjà rencontrés aux Modules 5/6 : du code qui *a l'air* de faire une vérification réelle (un appel de méthode, un paramètre nommé `confirmationCode`) sans qu'aucune vérification réelle n'ait jamais lieu. C'est la variante la plus sérieuse de ce motif rencontrée jusqu'ici : contrairement à un simulateur de créneaux (cosmétique), une preuve de remise qui ne prouve rien touche directement à la fiabilité opérationnelle du dernier kilomètre — un litige « colis non reçu » n'aurait aujourd'hui aucune trace exploitable pour trancher.

---

## 3. Sécurité & résilience

### 3.1 RLS — écriture totalement absente (sixième occurrence de ce motif)

`20260827001200_delivery.sql` n'ouvrait que des policies `select` (`delivery_drivers_select_authenticated`, `deliveries_select_own`, `delivery_proofs_select_own`, plus deux policies `select` sur les tables de tournées). Le commentaire d'origine de la migration anticipait explicitement cette lacune (« Accès livreur volontairement pas couvert ici, même réserve que reservations/prescriptions ») — c'est la sixième fois que ce motif exact se répète depuis le Module 2 (stock), et la référence croisée du commentaire lui-même confirme qu'il s'agit d'un choix systématique reporté de module en module plutôt que d'un oubli isolé.

Concrètement, avant correctif : aucun patient ne pouvait créer de livraison ; aucun livreur ne pouvait lire, encore moins traiter, la moindre course ; aucun membre du personnel d'officine ne pouvait assigner de livreur.

**Correctif** (`20260829018000_delivery_module_fixes.sql`) : une nouvelle fonction `is_delivery_driver(target_driver_id)` (SECURITY DEFINER, même patron que `is_pharmacy_staff`/`is_gsg_admin`), et neuf nouvelles policies couvrant `deliveries` (lecture livreur/staff, création patient, mise à jour patient/livreur/staff), `delivery_proofs` (écriture/mise à jour livreur) et `delivery_drivers` (mise à jour de sa propre fiche, création réservée à `is_gsg_admin`). Particularité de ce module : `deliveries` n'a pas de colonne `pharmacy_id` directe (contrairement à `reservations`) — l'officine responsable se déduit de `reservations.pharmacy_id` via `deliveries.reservation_id` ; les policies « staff » scopent donc via une jointure plutôt que directement.

Limite assumée et documentée (item C25 du registre, même famille que C18/C22) : RLS n'empêche pas plus ici qu'ailleurs dans le projet le patient ou le livreur de poser n'importe quel statut sur leur propre ligne — seule la couche applicative propose les transitions valides.

### 3.2 RG-LIV-01 — défense en profondeur ajoutée

`assignDriver()` vérifie désormais explicitement `current.isColdChainRequired && !driver.isColdChainCertified` et lève un `StateError` explicite avant toute écriture, en complément (pas en remplacement) du filtre déjà correct de `_DriverPickerSheet`. Limite reportée au registre (B17) : `Delivery.isColdChainRequired` dépend en amont d'une case à cocher manuelle ajoutée ce module au tunnel de commande, faute de tout flag automatique au niveau produit — un patient qui omet de la cocher contourne silencieusement cette protection.

### 3.3 RG-LIV-02 — la correction la plus importante de ce module

Avant correctif, `completeDelivery` acceptait sans vérification tout appel portant un `confirmationCode` fabriqué côté client à l'instant même du clic « confirmer » — un code jamais comparé à rien. Corrigé en deux temps : un vrai code à 6 chiffres est désormais généré à la planification (`scheduleDelivery`) et affiché au patient sur l'écran de suivi ; `completeDelivery` exige désormais que le code saisi corresponde à ce code de référence, **ou** qu'une signature/photo soit réellement fournie — une clôture sans aucune preuve exploitable n'est plus acceptée (`StateError` explicite).

Deux chemins de clôture coexistent désormais : le livreur saisit le code communiqué oralement par le patient (`driver_dashboard_screen.dart` — preuve à deux parties, robuste), et le patient peut aussi confirmer lui-même depuis son propre écran avec son propre code déjà connu (`delivery_tracking_screen.dart` — pas une preuve indépendante, un patient malveillant pourrait confirmer un colis jamais reçu). Cette deuxième voie est une limite assumée, documentée en C27, et une décision produit à trancher (D11) plutôt qu'un défaut corrigé en silence : les deux chemins doivent-ils coexister, ou la clôture doit-elle être réservée au seul livreur ?

### 3.4 Accès et rôles côté client

`delivery_schedule_screen.dart` n'avait aucun contrôle de rôle : tout compte authentifié pouvait ouvrir la planification et assigner un livreur. `driver_dashboard_screen.dart` n'avait aucun contrôle de rôle non plus, au-delà de l'identité en dur qui, de fait, empêchait l'écran de fonctionner pour quiconque. Les deux ont été corrigés avec le même patron déjà établi (`pharmacy_queue_screen.dart`, Module 6) : gate explicite sur `UserRole.pharmacien`/`UserRole.livreur`.

### 3.5 Résilience — même limite structurelle que RES

Comme pour RES (Module 6), aucune transaction cross-table n'existe pour la création conjointe d'une réservation et de sa livraison associée (`reservation_checkout_screen.dart`) : un échec réseau entre les deux appels laisse une réservation sans livraison programmée, signalé par un avertissement non bloquant mais sans mécanisme de rattrapage automatique. Documenté en A15.

---

## 4. Optimisation & améliorations (implémentées ce module)

### 4.1 Câblage du point d'entrée manquant (correction la plus critique de ce module)

`reservation_checkout_screen.dart` appelle désormais `DeliveryProvider.scheduleDelivery` immédiatement après la création réussie d'une réservation, si une adresse de livraison a été renseignée (elle reste optionnelle — sans adresse, le patient retire en officine, sans création de `Delivery`). Amélioration UX associée : l'écran de confirmation affiche désormais un bouton « Suivre ma livraison » routant directement vers `delivery_tracking_screen.dart` quand une livraison a bien été programmée, plutôt que de laisser le patient la retrouver lui-même dans l'historique. Une case à cocher « Livraison chaîne du froid » a été ajoutée à cette même étape (voir §3.2 et B17).

### 4.2 Suivi de position réel (fonctionnalité clé jusqu'ici invisible)

`driver_dashboard_screen.dart` résout désormais l'identité réelle du livreur (`AuthProvider.userId` → `DeliveryService.getDriverForUser` → fiche `delivery_drivers`, nouveau) puis interroge `LocationService` (déjà utilisé par le module recherche) toutes les 25 secondes tant qu'au moins une course est `inProgress`, et pousse la position à `DeliveryProvider.updateMyLocation`/`updateDeliveryLocation`. `delivery_tracking_screen.dart` reflète désormais une position réelle plutôt que figée. Limite documentée en C26 : ce n'est qu'un sondage en avant-plan (l'écran doit rester ouvert), pas un vrai service de localisation en tâche de fond — amélioration réelle par rapport à l'absence totale de mise à jour qui existait avant ce module, mais qui ne réalise pas pleinement le « suivi en temps réel » tel que décrit au cahier.

### 4.3 Résolution d'identité réelle du livreur (sixième occurrence corrigée)

Nouvelle méthode `DeliveryService.getDriverForUser(userId)`, même patron que les corrections précédentes (Modules 4/5/6) : résout la fiche `delivery_drivers` rattachée à l'utilisateur authentifié via sa colonne `user_id`, remplaçant l'identifiant `'drv_001'` en dur.

### 4.4 Mode hors-ligne (directive standing)

`OfflineSyncService` v5→v6 : nouvelle table `cache_deliveries`, partitionnée par `owner_key` (`patientId` côté patient, `'driver_<driverId>'` côté livreur). `DeliveryProvider` gagne `loadDeliveriesForPatient`/`loadDeliveriesForDriver` (nouvelles, remplaçant l'usage jusqu'ici orphelin de `DeliveryService.getDeliveriesForDriver`/`getDeliveriesForPatient`) et un repli hors-ligne sur `loadDelivery(id)` — même patron déjà audité que `ReservationProvider` (Module 6) : cache à l'écriture réussie, repli avec message informatif non bloquant à l'échec, jamais un écran d'erreur qui masquerait des données déjà en cache. Les trois écrans concernés (`delivery_history_screen.dart`, `delivery_tracking_screen.dart`, `driver_dashboard_screen.dart`) portent désormais un bandeau hors-ligne cohérent avec celui déjà en place pour RES/ORD ; `delivery_history_screen.dart` portait en plus le même bug de garde d'erreur déjà rencontré et corrigé ailleurs (`provider.error != null` sans `&& deliveries.isEmpty`, qui aurait masqué une liste pourtant chargée depuis le cache) — corrigé au passage. Limite documentée en C28 : seules les lectures bénéficient de ce repli — la planification, l'assignation et la clôture d'une livraison restent strictement en ligne.

---

## 5. Documentation API (services)

### `DeliveryService`

| Méthode | Description | Changé ce module |
|---|---|---|
| `getDeliveries({status})`, `getDelivery(id)`, `getAvailableDrivers()`, `getDriver(id)` | Lecture | Non |
| `getDeliveriesForDriver(driverId)`, `getDeliveriesForPatient(patientId)` | Lecture ciblée — existaient déjà mais sans appelant | **Oui** (câblées ce module) |
| `getDriverForUser(userId)` | **Nouveau.** Résout la fiche `delivery_drivers` rattachée à l'utilisateur authentifié | **Oui** |
| `scheduleDelivery({...})` | Crée une livraison programmée, génère le code de remise (RG-LIV-02) | **Oui** (désormais appelée) |
| `assignDriver(deliveryId, driverId)` | Assigne un livreur ; vérifie désormais RG-LIV-01 côté serveur | **Oui** |
| `startDelivery(deliveryId)`, `markAsArrived(deliveryId)` | Transitions de statut | Non |
| `updateLocation({deliveryId, latitude, longitude})`, `updateDriverLocation(driverId, lat, lon)` | Position — existaient déjà mais sans appelant | **Oui** (câblées ce module) |
| `completeDelivery({...})` | Clôture avec vérification de preuve de remise (RG-LIV-02) — paramètre renommé `enteredConfirmationCode` | **Oui** |
| `cancelDelivery(deliveryId, {reason})` | Annulation | Non |
| `planRoute`/`getRoute`/`getRoutesForDriver` | Sous-système de tournées multi-livraisons | Non — volontairement laissé orphelin, voir D10 |
| `sendProximityAlert`/`sendStatusNotification` | Stubs sans effet, documentés comme tels dans le code d'origine | Non — hors périmètre, dépend d'une future intégration ALR |

### `DeliveryProvider`

Ajouts : `isOffline`, `myDriverProfile`, `loadDeliveriesForPatient`/`loadDeliveriesForDriver`/`loadMyDriverProfile`, `updateMyLocation`/`updateDeliveryLocation`, `notifyListeners()` ajouté sur tous les chemins d'erreur des actions, paramètre `completeDelivery` renommé en cohérence avec le service.

---

## 6. Scénarios de test (à exécuter — non exécutés dans cette session, voir registre A14-A15)

1. **Câblage du point d'entrée (correction la plus critique)** : passer une commande avec une adresse de livraison renseignée → vérifier qu'une `Delivery` est bien créée en base, visible côté pharmacien dans `delivery_schedule_screen.dart`, et que le bouton « Suivre ma livraison » de l'écran de confirmation mène bien vers le suivi.
2. **RG-LIV-01** : programmer une livraison avec la case « chaîne du froid » cochée, tenter d'assigner un livreur non certifié directement via un appel service (contournant le sélecteur UI) → vérifier le `StateError` explicite.
3. **RG-LIV-02, clôture livreur** : démarrer une course, tenter de la clôturer avec un code erroné → vérifier le rejet explicite ; avec le bon code communiqué par le patient → vérifier la clôture réussie et la preuve enregistrée dans `delivery_proofs`.
4. **RG-LIV-02, clôture patient** : vérifier que le code affiché sur `delivery_tracking_screen.dart` correspond bien à celui exigé côté livreur pour la même livraison.
5. **Suivi de position** : démarrer une course, laisser l'écran tableau de bord livreur ouvert, vérifier que la position affichée côté patient évolue toutes les ~25 secondes ; quitter l'écran livreur → vérifier que la position cesse de se mettre à jour (limite C26).
6. **Étanchéité des rôles** : connecter un compte `patient` et tenter d'accéder à `/deliveries/schedule` et au tableau de bord livreur → vérifier le blocage des deux.
7. **Étanchéité livreur** : connecter deux comptes livreurs différents → vérifier qu'aucun ne voit les courses assignées à l'autre (RLS `is_delivery_driver`).
8. **Mode hors-ligne — lecture** : couper le réseau après un premier chargement réussi de l'historique patient/du tableau de bord livreur → vérifier le bandeau informatif et l'affichage des données en cache, pas d'écran d'erreur bloquant.
9. **Identité réelle** : vérifier qu'aucun écran corrigé ne référence plus `'drv_001'` et que les insertions/lectures Supabase utilisent bien l'uuid réel de l'utilisateur connecté.
10. **Échec partiel réservation/livraison (A15)** : simuler un échec réseau juste après la création de la réservation mais avant `scheduleDelivery` → vérifier que l'avertissement s'affiche et que la réservation reste exploitable manuellement par l'officine.

---

## 7. Livrables de ce module

- `supabase/migrations/20260829018000_delivery_module_fixes.sql` (nouveau)
- `lib/core/services/offline_sync_service.dart` (v5→v6, `cache_deliveries`)
- `lib/modules/delivery/models/delivery.dart`
- `lib/modules/delivery/services/delivery_service.dart`
- `lib/modules/delivery/providers/delivery_provider.dart`
- `lib/modules/delivery/screens/driver_dashboard_screen.dart`
- `lib/modules/delivery/screens/delivery_tracking_screen.dart`
- `lib/modules/delivery/screens/delivery_history_screen.dart`
- `lib/modules/delivery/screens/delivery_schedule_screen.dart`
- `lib/modules/reservations/screens/reservation_checkout_screen.dart` (Module 6, intégration cross-module nécessaire pour rendre LIV atteignable)
- `PharmaConnect_Registre_Ecarts_A_Verifier.md` — mis à jour (A14-A15, B11 réévalué, B17, C25-C29, D10-D11 ; D6 annoté d'une cinquième occurrence)
- Ce rapport

---

## Le module LIV est-il totalement clos et validé pour passer au suivant ?

Sous réserve de votre validation, le prochain module serait le **Module 8 (PAY — Paiement, Mobile Money & Portefeuille)**, selon l'ordre confirmé à l'Étape 1.
