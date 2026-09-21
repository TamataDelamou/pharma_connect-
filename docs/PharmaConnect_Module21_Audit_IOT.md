# PharmaConnect — Module 21 (IOT — Télésuivi & Objets médicaux connectés)
### Rapport d'audit — Étape 1 : Inspection & rapport de situation — 30/08/2026

**Ouverture officielle du module**, à la suite de la clôture du Module 20 (DSN). Numérotation confirmée contre la table officielle du cahier (voir Module 20) : 21 = IOT.

---

## 1. Périmètre cahier (rappel)

**Code module :** IOT — **Priorité :** Différenciant

**Objectif.** Permettre le suivi à distance de certains **patients**, notamment chroniques ou en sortie d'hospitalisation, par la remontée de constantes mesurées via des **dispositifs médicaux connectés validés** (tensiomètre, thermomètre, oxymètre, glucomètre, balance).

**Écrans principaux attendus :** Association d'un objet connecté · Historique des mesures · Auto-évaluation périodique · Alerte de télésuivi (vue professionnel).

**Règles de gestion :**

| Réf. | Énoncé | Criticité |
|---|---|---|
| RG-IOT-01 | Seuls des dispositifs médicaux validés et référencés par la plateforme peuvent être connectés au télésuivi ; une mesure issue d'un dispositif non validé est signalée comme non certifiée. | Critique |
| RG-IOT-02 | Le dépassement d'un seuil défini pour un patient donné déclenche une alerte au professionnel référent, sans interprétation médicale automatique de la mesure par la plateforme. | Standard |

---

## 2. Constat majeur — écart de périmètre radical, pas un simple manque

**Le code trouvé sous `lib/modules/iot/` (9 fichiers) et sa migration d'origine (`20260829003000_iot.sql`, dont le commentaire d'en-tête dit lui-même « connected devices for **cold chain and stock monitoring** ») ne construisent PAS le télésuivi patient décrit par le cahier — c'est un module de supervision d'**équipements d'officine**.**

Preuves concrètes :
- `iot_devices.type` (contrainte CHECK) : `'temperature_sensor'`, `'humidity_sensor'`, `'cold_chain_monitor'`, `'stock_scanner'`, `'motion_sensor'` — capteurs de température/humidité de réfrigérateur, scanner de stock, détecteur de mouvement. **Aucun** des dispositifs cahier (tensiomètre, thermomètre corporel, oxymètre, glucomètre, balance patient) n'apparaît.
- `iot_devices.pharmacy_id` référence `public.pharmacies(id)` — **aucune colonne `patient_id` nulle part** dans `iot_devices`/`temperature_readings`/`humidity_readings`/`iot_alerts`. Le télésuivi cahier est par nature rattaché à un patient ; ce qui existe est rattaché à une officine.
- Les écrans (`iot_dashboard_screen.dart` : « 📡 Objets connectés — Surveillez vos capteurs et équipements ») et widgets parlent explicitement d'équipements d'officine, pas de suivi de patient.
- **Recouvrement direct avec un autre module du cahier, non encore audité** : la surveillance de température de chaîne du froid (`cold_chain_monitor`, `temperature_sensor`) est very précisément l'objet du **Module CLD (31 — Chaîne du froid & Produits thermosensibles, RG-CLD-01)**. Ce code semble avoir anticipé une partie de CLD sous le nom IOT, plutôt que de construire IOT tel que décrit — à confirmer/coordonner explicitement lors de l'audit futur de CLD, pour éviter d'auditer deux fois le même code sous deux numéros de module, ou à l'inverse de laisser un doublon non résolu.

Ce n'est pas un manque partiel (comme le sous-module hors-RG de DSN) — c'est un remplacement complet de l'objet du module, du même ordre de sévérité que le Module 17 (TRI, « le système trouvé est un triage d'urgences hospitalier interne, pas le questionnaire d'auto-évaluation patient du cahier ») et le Module 18/19 (« business » confondu avec BIZ). Aucune des fonctionnalités patient du cahier (association d'objet connecté par le patient, historique de constantes, auto-évaluation périodique, alerte au professionnel référent d'UN patient) n'existe où que ce soit dans le projet.

## 3. Inventaire du code trouvé

**Dossier `lib/modules/iot/`** — 9 fichiers : modèles (`iot_device.dart`, `iot_alert.dart`, `temperature_reading.dart` — pas de modèle dédié pour l'humidité, alors que la table `humidity_readings` existe), `iot_provider.dart`, `iot_service.dart`, 3 écrans (dashboard, détail, création — pas d'écran d'édition dédié, `device_create_screen.dart` est réutilisé en mode édition via un `deviceId` optionnel), `device_card.dart`.

**Migration :** `20260829003000_iot.sql` — 4 tables (`iot_devices`, `temperature_readings`, `humidity_readings`, `iot_alerts`), RLS activée, déjà partiellement corrigée lors de l'audit du Module 19 (C92, confusion de portée SQL `id`/`device_id` dans les sous-requêtes corrélées) et à l'instant lors de l'ouverture de ce module (**C98**, voir §4).

**Routage.** Toutes les routes `/iot`, `/iot/device/new`, `/iot/device/:id`, `/iot/device/edit/:id` sont déclarées et fonctionnelles ; déjà réordonnancées pour éviter le shadowing go_router lors du balayage transverse C69 (Module 18). Absentes du menu de navigation (`dashboard_screen.dart`) — décision déjà actée aux Modules 14/18 d'attendre l'audit dédié avant d'exposer, précisément la situation présente. **Pas de décision d'exposition prise dans cette Étape 1** — l'écart de périmètre au §2 rend la question « sous quel libellé l'exposer, à quel rôle » non triviale (voir §5).

## 4. Défauts trouvés et corrigés à l'ouverture

### C98 — Deux motifs transverses déjà rencontrés, dans la migration d'origine du module (🟢 corrigé ce même mouvement)

1. **`auth.uid() = pharmacy_id`** (confusion id utilisateur / id officine, motif C88/C91/C93) sur les 2 policies `iot_devices` réservées au pharmacien (« Pharmacy view/manage own IoT devices ») — remplacé par `public.is_pharmacy_staff(pharmacy_id)`.
2. **`role in ('admin', 'staff')` sans repli** (motif « rôle inatteignable », mais ici **intégralement mort** — à la différence de C94/DSN où `'professionnel'` restait fonctionnel, aucune des 3 policies concernées — « Staff view all IoT devices », « Staff view all readings », « Staff manage all alerts » — n'a jamais pu être satisfaite par aucun compte réel) — remplacées par une vérification inlined sur `admin_users` (fichier antérieur à `is_gsg_admin()`, même piège de non-antériorité que C90/C94).

Rejoué avec succès sur la chaîne complète des 85 migrations (`ALL MIGRATIONS APPLIED SUCCESSFULLY`). Correctif non re-vérifié par un test fonctionnel dédié (le motif et le correctif sont identiques, mot pour mot, à ceux déjà prouvés par exécution réelle pour C90/C91/C94 — jugé suffisant à ce stade, à re-tester explicitement si l'Étape 3 de ce module le justifie).

### C99 — Bug fonctionnel côté client : mauvais identifiant transmis comme `pharmacyId` (🔴 trouvé, non corrigé)

`iot_dashboard_screen.dart._loadDevices()` appelle `IotProvider.loadDevices(pharmacyId: userId, ...)` où `userId = SupabaseService().currentUser?.id` — c'est-à-dire l'**id du compte utilisateur connecté** (un `profiles.id`), pas l'id de la ligne `pharmacies` à laquelle ce compte est rattaché. Même famille de confusion que C98/C88/C91, mais ici côté client, pas seulement RLS : même avec le correctif RLS de C98 appliqué, la requête `iot_devices.eq('pharmacy_id', userId)` ne retournera jamais aucune ligne pour un pharmacien réel (son id de compte ne correspond à aucun id de ligne `pharmacies`) — le tableau de bord IoT affichera donc toujours « Aucun appareil connecté », quel que soit l'état réel des données. Non corrigé à ce stade : la résolution correcte de « l'officine du pharmacien actuellement connecté » est vraisemblablement déjà résolue ailleurs dans le projet (modules stock/réservations) — à retrouver et réutiliser plutôt qu'improviser un nouveau mécanisme, proposé pour l'Étape 2.

## 5. Statut à ce stade

- **C98** — corrigé ce même mouvement.
- **C99** — trouvé, non corrigé, nécessite d'abord d'identifier le mécanisme déjà établi ailleurs dans le projet pour résoudre l'officine du pharmacien connecté.
- **Écart de périmètre radical (§2)** — pas encore consigné formellement en item D (à faire en Étape 2), et surtout : **recouvrement potentiel avec le futur Module CLD (31)** à clarifier avant toute décision d'exposition en navigation — construire/exposer une entrée de menu maintenant sous un intitulé qui ne correspond ni au cahier IOT ni encore à un CLD audité serait prématuré.

---

**Comme pour les modules précédents, ce rapport s'arrête à l'Étape 1.** Deux questions avant de poursuivre : (1) souhaitez-vous que j'enchaîne directement sur l'Étape 2 (analyse comparative) et l'Étape 3 (sécurité/exécution réelle), comme pour le Module 20 ? (2) Sur le recouvrement CLD : préférez-vous que je vérifie dès maintenant, par une recherche ciblée, si un dossier de code `coldchain`/`CLD` existe déjà dans le projet (pour savoir si ce recouvrement est déjà un doublon actif ou seulement un risque futur), avant de trancher comment ce module doit être positionné et, le cas échéant, exposé en navigation ?


---

## 6. Étape 2 — Analyse comparative

### 6.1 RG-IOT-01/RG-IOT-02 vs réalité

| Réf. | Exigence cahier | Réalité code |
|---|---|---|
| RG-IOT-01 | Seuls des dispositifs médicaux validés et référencés par la plateforme peuvent être connectés au télésuivi ; une mesure d'un dispositif non validé est signalée non certifiée | Inapplicable telle quelle : `iot_devices` n'a aucun concept de « validation »/« certification » d'un dispositif, ni de patient à qui l'associer. Le champ le plus proche, `status` (`active`/`inactive`/`maintenance`/`offline`), décrit l'état opérationnel d'un capteur d'officine, pas une homologation médicale d'un dispositif patient |
| RG-IOT-02 | Le dépassement d'un seuil déclenche une alerte au professionnel référent DU PATIENT, sans interprétation médicale automatique | Un mécanisme de seuil et d'alerte existe bel et bien (`iot_alerts`, `simulateReading()` compare à des seuils fixes 2°C/30°C) — mais l'alerte est rattachée à un appareil d'officine (`device_id` → `pharmacy_id`), jamais à un patient ni à un professionnel référent. La mécanique technique (seuil → alerte, sans interprétation automatique du message) est saine et directement réutilisable le jour où un vrai module de télésuivi patient sera construit — seul le rattachement (officine plutôt que patient/professionnel référent) est à refaire |

**Conclusion : la mécanique (dispositif → mesure → seuil → alerte) est correcte et de bonne qualité technique ; c'est l'objet métier (patient vs officine) qui est entièrement substitué.** Aucun correctif RLS ou fonctionnel ne peut combler cet écart — c'est un chantier de construction, pas un audit-et-corrige, exactement comme D4 (BIZ)/D32 (INF).

### 6.2 Écrans cahier attendus vs réalité

| Écran cahier | Trouvé ? |
|---|---|
| Association d'un objet connecté (par le patient) | Non — `device_create_screen.dart` existe mais crée un appareil rattaché à une OFFICINE (pharmacien), pas à un patient |
| Historique des mesures (patient) | Non — `device_detail_screen.dart` affiche un historique, mais côté officine |
| Auto-évaluation périodique | Non — aucune trace nulle part dans le projet |
| Alerte de télésuivi (vue professionnel référent) | Non — `iot_alerts` existe mais vue pharmacien/admin d'officine, jamais vue professionnel référent d'un patient |

### 6.3 Le doublon CLD — confirmé, pas seulement une hypothèse (voir C100, D35)

La vérification demandée par le porteur du projet confirme que `lib/modules/coldchain/` existe réellement (13 fichiers Dart + `20260827000800_coldchain.sql`, daté du 27/08 — **antérieur** à `iot.sql` du 29/08) et implémente, de façon totalement indépendante d'`iot`, la surveillance d'équipement de chaîne du froid :

| | `iot` (device types cold-chain uniquement : `temperature_sensor`, `cold_chain_monitor`) | `coldchain` |
|---|---|---|
| Table équipement | `iot_devices` (générique, 5 types dont 2 hors-cold-chain) | `cold_equipment` (dédiée : `refrigerator`/`freezer`/`coldRoom`/`transportBox`/`coolBox`, calibration, seuils min/max par équipement) |
| Table relevés | `temperature_readings`/`humidity_readings` | `temperature_records` (min/max/type manuel-automatique-capteur) |
| Incidents/rappel | `iot_alerts` (générique, pas de lien lot) | `cold_incidents`, **relié à `traceable_batches`** — intégration directe avec le rappel de lots (Module TRC/12) |
| RLS | Corrigée et validée par exécution réelle ce module (C98) | **`for select to authenticated using (true)` sur les 3 tables — lecture totale ouverte, toutes officines et tous rôles confondus** ; **aucune policy insert/update/delete** — l'app ne peut écrire aucune donnée réelle en RLS normale (voir C100) |
| Maturité fonctionnelle vs cahier CLD (calibration, seuils par équipement, lien rappel de lots) | Faible — pas de notion de calibration ni de lot | Nettement plus proche du cahier CLD (RG-CLD probable, à confirmer lors de l'audit dédié du Module 31) |

**`coldchain` est donc la base la plus proche du futur Module CLD (31), mais sa sécurité est aujourd'hui pire que ce qu'`iot` avait avant correctif** (RLS totalement absente en écriture, ouverte en lecture — pas juste un biais d'identifiant comme C98/C88, une absence totale de restriction). Conformément à la convention établie de cet audit (ne pas corriger un module qui n'est pas encore ouvert), **ce défaut n'est pas corrigé ici** — il est consigné en C100 et réservé au Module 31, mais signalé avec la priorité la plus haute pour cette ouverture future.

Les device types non-cold-chain d'`iot_devices` (`humidity_sensor`, `stock_scanner`, `motion_sensor`) ne recouvrent ni CLD ni aucun autre module identifié du cahier — scope creep, sans impact sécurité propre (RLS désormais saine) mais sans rattachement cahier non plus.

## 7. Étape 3 — Sécurité & tests DDL/RLS réels (Postgres 16)

### 7.1 C98 — le correctif initial était incomplet ; complété et prouvé par exécution réelle

En relisant `iot.sql` en entier pour préparer le harnais de test demandé, le même motif déjà corrigé sur `iot_devices` (`auth.uid() = pharmacy_id`) s'est révélé **encore présent, non détecté au premier passage**, dans 4 autres policies : « Pharmacy view device readings » (`temperature_readings`), « Pharmacy view humidity readings » (`humidity_readings`), « Pharmacy view IoT alerts » et « Pharmacy manage own alerts » (`iot_alerts`) — sous la forme `iot_devices.pharmacy_id = auth.uid()` au sein de la sous-requête EXISTS reliant la lecture au device. Corrigé selon le même principe (`public.is_pharmacy_staff(iot_devices.pharmacy_id)`), dans le même fichier migration (module encore ouvert, correctif direct conforme à la convention établie), livré et committé sur l'appareil de l'utilisateur, rejoué avec succès sur la chaîne complète des 85 migrations.

**Ce miss du premier passage est noté explicitement pour la discipline de l'audit** : c'est précisément le type d'angle mort qu'une relecture statique, même attentive, peut manquer — et que seule l'exécution réelle demandée par le porteur du projet a permis de détecter avec certitude.

### 7.2 Protocole de test réel

Harnais Postgres 16 (`iot_rls_test.sql`), protocole identique à celui déjà validé pour C90/C91/C94/C96/C97 : reproduction explicite des `GRANT` par défaut Supabase (absents du stub minimal de test), `auth.uid()` réécrite pour lire `current_setting('request.jwt.claim.sub')`, `SET`/`RESET role authenticated` + `SET`/`RESET request.jwt.claim.sub` pour simuler successivement chaque compte (rôle `postgres` superutilisateur exclu, car il contourne toute RLS).

**Jeu de données :** 2 officines A/B, 1 pharmacien par officine (`profiles.pharmacy_id` renseigné), 1 compte admin GSG (`admin_users`, rôle `profiles` non-pharmacien — vérifie que c'est bien l'appartenance à `admin_users` qui compte, pas le rôle `profiles`), 1 patient tiers sans aucun lien, 1 appareil + 1 relevé de température + 1 relevé d'humidité + 1 alerte par officine.

### 7.3 Résultats

| # | Test | Attendu | Obtenu |
|---|---|---|---|
| 1 | Pharmacien A lit `iot_devices` | 1 ligne (DEV-A-01) | ✅ 1 ligne |
| 2 | Pharmacien A lit `temperature_readings` | 1 ligne (4.5°C) | ✅ 1 ligne |
| 3 | Pharmacien A lit `humidity_readings` | 1 ligne (45%) | ✅ 1 ligne |
| 4 | Pharmacien A lit `iot_alerts` | 1 ligne (Alerte A) | ✅ 1 ligne |
| 5 | Pharmacien A cible explicitement les lignes de B (device/relevés/alerte) | 0 partout | ✅ 0 partout (4 requêtes) |
| 6 | Pharmacien A tente d'ACQUITTER (`UPDATE`) une alerte de B | `UPDATE 0`, statut de B inchangé | ✅ `UPDATE 0`, alerte B reste `active` |
| 7 | Admin GSG (compte `profiles.role='patient'`, membre `admin_users`) lit tous les appareils/relevés/alertes | 2 lignes chacun (A + B) | ✅ 2/2/2 |
| 8 | Admin GSG gère (`UPDATE`) une alerte de n'importe quelle officine | Succès | ✅ `UPDATE 1`, statut passé à `resolved` |
| 9 | Patient tiers (aucun lien pharmacie/admin) lit tout | 0 partout | ✅ 0/0/0/0 |

**L'étanchéité multi-officines (lecture ET écriture) et la supervision admin (C98) sont désormais prouvées par exécution réelle, pas seulement corrigées par relecture** — y compris pour les 4 policies dont le défaut n'avait pas été vu au premier passage (§7.1).

## 8. Options d'arbitrage pour sceller le Module 21 (IOT)

Trois sujets distincts sont soumis à l'arbitrage du porteur du projet.

**Sujet 1 — le doublon `iot`/`coldchain` (D35).**
- *Option A (fusion différée, recommandée)* : conserver `iot` et `coldchain` séparés pour l'instant (aucun code à modifier ce module), mais consigner formellement `coldchain` comme la base à privilégier pour le futur Module 31 (CLD) — le module `iot` conserverait uniquement ses device types génériques hors cold-chain (`humidity_sensor`, `stock_scanner`, `motion_sensor`), le recouvrement cold-chain (`temperature_sensor`, `cold_chain_monitor`) étant dé-routé/marqué obsolète lors de l'ouverture du Module 31, une fois `coldchain.sql` sécurisé (C100).
- *Option B (statu quo total)* : ne rien trancher ce module, laisser les deux implémentations coexister telles quelles jusqu'à l'ouverture du Module 31, où la décision de fusion/dé-routage sera prise avec une vision complète du cahier CLD.
- *Option C (dé-routage immédiat des types cold-chain d'iot)* : retirer dès maintenant `temperature_sensor`/`cold_chain_monitor` de la liste des types sélectionnables dans `device_create_screen.dart` (UI seule, sans toucher au schéma), pour éviter que de nouvelles données cold-chain continuent à être créées des deux côtés en parallèle avant l'arbitrage définitif au Module 31.

**Sujet 2 — l'écart de périmètre IOT lui-même (télésuivi patient jamais construit).**
- *Option recommandée, cohérente avec D4/D32/D31* : différer la construction du vrai télésuivi patient (RG-IOT-01/02, 4 écrans cahier) comme chantier de conception dédié, consigné en registre à la clôture. Le module `iot` corrigé (supervision d'équipement d'officine, sécurisé) reste utile tel quel pour sa propre fonction réelle, sous réserve de trancher le Sujet 1.

**Sujet 3 — exposition en navigation.**
Compte tenu des Sujets 1 et 2 non tranchés, la recommandation est de **ne pas exposer** de nouvelle entrée de menu pour `iot` à ce stade (cohérent avec la décision déjà prise aux Modules 14/18/20 d'attendre la clarification de périmètre avant d'exposer) — à revoir une fois le Sujet 1 arbitré.

---

## 9. Clôture

**Arbitrage du porteur du projet (30/08/2026)** sur les 3 sujets soumis au §8 :

1. **Doublon `iot`/`coldchain` (D35)** — option retenue : **consolidation et fusion différées vers le Module 31 (CLD)**. `iot` reste en l'état (corrigé et validé, C98/C99) et conserve la supervision technique d'officine (réfrigérateurs, scanners) ; la fusion avec `coldchain/` est explicitement différée jusqu'à l'audit dédié du Module 31, qui devra trancher quel modèle de données devient la base unique. C100 (faille RLS de `coldchain/`) reste inscrit avec priorité absolue d'ouverture pour ce futur module.
2. **Télésuivi patient RG-IOT-01/02 (D36)** — option retenue : **différer la construction ex nihilo**, comme D4 (BIZ)/D32 (INF)/D34 (DSN). La mécanique technique seuil→alerte déjà construite (`iot_alerts`, `simulateReading()`) reste réutilisable le jour venu ; seul le rattachement patient/professionnel référent est à construire.
3. **Exposition en navigation** — option retenue : **ne pas exposer** l'entrée IoT dans le menu principal tant que la consolidation avec le Module 31 et le rôle du module d'officine ne sont pas définitivement scellés.

**Résumé des correctifs appliqués et validés ce module :**
- C98 : correctif RLS étendu aux 4 policies de relevés/alertes manquées au premier passage, validé par 9/9 tests réels sous Postgres 16 (rôle `authenticated`, isolation multi-officines et supervision admin prouvées).
- C99 : harmonisation de `pharmacyId` sur les 3 écrans IoT via `AuthProvider.pharmacyId`, livrée et committée.

**Tickets consignés au registre :**
- C100 : faille RLS majeure sur `coldchain/` (lecture ouverte à tout authentifié, aucune policy d'écriture) — reportée avec priorité absolue à l'ouverture du Module 31.
- D35 : recouvrement `iot`/`coldchain` — consolidation différée vers le Module 31 (CLD).
- D36 : télésuivi patient RG-IOT-01/02 — non implémenté, dette différée.

**Le Module 21 (IOT — Télésuivi & Objets médicaux connectés / supervision d'équipements d'officine) est officiellement clos, scellé et validé.**
