# PharmaConnect — Audit Module 12 (TRC — Traçabilité & Lutte contre les médicaments contrefaits)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Contrairement au Module 11 (IA), ce module n'a révélé **aucune erreur de syntaxe ni identifiant non défini** — tous les modèles (`traceable_batch.dart`, `batch_movement.dart`, `verification_result.dart`, `cold_chain_record.dart`, `certificate.dart`) sont complets et compilables. Le défaut ici est d'une autre nature : un module **fonctionnellement incomplet**, avec des écritures manquantes plutôt que défaillantes.

Fichiers inspectés : `lib/modules/traceability/models/*.dart` (5), `services/traceability_service.dart`, `providers/traceability_provider.dart`, `screens/verification_screen.dart`, `screens/traceability_dashboard_screen.dart`, `screens/batch_detail_screen.dart`, `widgets/scan_fab.dart`, `supabase/migrations/20260827000700_traceability.sql`, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `alert_type.dart`, `alert_service.dart`, `20260827001400_alerts.sql`).

### 1.2 Une chaîne de traçabilité qui ne trace qu'un bout de la chaîne

Le cahier exige une « chaîne de traçabilité continue, du fabricant au patient ». Le code trouvé ne réalisait que le tout dernier maillon (vérification par scan patient/pharmacien) :

1. **Aucune méthode n'écrivait jamais dans `batch_movements`.** `TraceabilityService` ne fait que lire cette table (`getMovements`). Le modèle `BatchMovement`/`BatchMovementType` (shipment/receipt/sale/dispensation/customerReturn/recall/transfer/destruction) est complet, mais rien dans le code ne l'instancie côté écriture — la réception d'un lot par un grossiste ou une officine n'était tout simplement pas enregistrable.
2. **`recallBatch`/`updateBatchStatus` existaient déjà mais n'étaient appelés depuis aucun écran** — même motif D6 (récurrent depuis le Module 0), **10ème occurrence** : du code fonctionnel, jamais relié à l'UI, et qui de surcroît (voir §3.1) n'avait pas les policies RLS pour s'exécuter s'il avait été appelé.
3. **Le résultat d'un scan de vérification n'était jamais reporté sur le lot.** `verifyProduct` journalise chaque scan dans `verification_scans` (bonne pratique de pharmacovigilance déjà en place), mais `traceable_batches.is_authenticated`/`is_counterfeit`/`last_verified_at` restaient figés à leurs valeurs par défaut pour toujours — aucune boucle de rétroaction, alors que `TraceableBatch.needsVerification` en dépend directement.
4. **Deux des écrans principaux du cahier étaient absents** : « Scan de réception » (RG-TRC-01) et « Signalement produit suspect » (RG-TRC-02) — voir §4 (D19/D20, arbitrés avec le porteur du projet avant construction).
5. **Aucun point d'entrée de navigation** vers `/traceability` — **11ème occurrence** de D6, cette fois-ci retracée jusqu'à sa cause racine plutôt que traitée isolément (voir §1.3 et §4.11).
6. **Extraction du GTIN par scan fragile.** `_BarcodeScannerPage.onDetect` faisait `barcode.rawValue?.substring(0, 13)` — `RangeError` (crash) pour tout code-barres de moins de 13 caractères, trivialement atteignable (QR de test, série courte).
7. **Libellé `verifiedBy` codé en dur** (`'Pharmacien'`) dans `verification_screen.dart`, alors que cet écran est accessible à tout utilisateur authentifié, patient compris (via `ScanFloatingButton`).

### 1.3 Correction de cartographie — cause racine du motif D6

En creusant cette 11ème occurrence du motif D6 (module routé mais inatteignable) plutôt que de la traiter comme un fait isolé de plus, la cause racine a été identifiée : `dashboard_screen.dart` contient l'**unique** menu de navigation réel de l'application (`SidebarNavigation`/`_navItems`, liste codée en dur), qui n'avait jamais été mise à jour au fil de la construction des nouveaux modules — expliquant pourquoi Modules 8, 10, 11 et maintenant 12 partageaient tous le même symptôme. Corrigé à la racine ce module (voir §4.11) plutôt que par un point d'entrée isolé de plus.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-TRC-01** | Chaîne de traçabilité continue (fabricant → grossiste → officine → patient) ; blocage d'un lot rappelé/contrefait | 🟡 **Enforcement partiel, assumé** — la chaîne d'écriture existe désormais (D19, réception), et le blocage s'applique à l'entrée dans la traçabilité elle-même (`receiveBatch` refuse un lot rappelé/contrefait). **Non relié** au point de vente réel (Module 6 réservations / POS) : un lot déjà en stock peut toujours être vendu sans consulter `traceable_batches` — même famille de limite que B11 (stupéfiant/livraison à domicile), documentée au registre plutôt que laissée implicite |
| **RG-TRC-02** | Signalement d'un produit suspect par patient/pharmacien, alerte immédiate officine + admin GSG | 🟢 Construit ce module (D20) — voir §4.10 |
| **RG-TRC-03** | Fournisseur suspendu après 3 signalements confirmés en 12 mois | 🔴 Hors périmètre — nécessite le module Marketplace/B2B (Module 13, non encore audité) pour exister ne serait-ce qu'au niveau du modèle de données (aucune notion de « fournisseur suspendu » nulle part dans le projet). Documenté comme dépendance différée (registre, item B) |

### 2.2 Fonctionnalités clés du cahier

| Fonctionnalité (cahier) | Constat |
|---|---|
| Vérification d'authenticité par scan (GTIN/numéro de série) | 🟢 Existait déjà, fonctionnel — corrigé ce module (extraction GS1, libellé) |
| Historique des mouvements d'un lot (traçabilité amont) | 🟡 Le modèle et l'écran (`MovementTimeline`) existaient déjà ; **corrigé ce module** pour que des mouvements soient réellement produits (réception, rappel, changement de statut) |
| Détection de contrefaçon (comparaison GTIN/numéro de série, rappels) | 🟢 Existait déjà, fonctionnel — **corrigé ce module** pour reporter le résultat sur le lot (boucle de rétroaction) |
| Signalement produit suspect par le patient/pharmacien | 🟢 Construit ce module (D20) |
| Rappel de lot avec traçabilité de la décision | 🟡 `recallBatch` existait déjà ; **corrigé ce module** pour produire un mouvement et être réellement accessible (action « Déclarer un rappel », staff uniquement) |
| Chaîne du froid | 🟡 Modèle et lecture (`ColdChainRecord`) existaient déjà et ne sont pas modifiés ce module ; `receiveBatch` (D19) permet désormais d'attacher une température relevée à une réception, mais aucun écran dédié « relevé de température » n'existe (hors périmètre de ce correctif) |
| Suspension automatique de fournisseur (RG-TRC-03) | 🔴 Absent — voir §2.1 |

### 2.3 Écrans principaux (cahier)

| Écran (cahier) | Constat |
|---|---|
| Vérification produit (scan/saisie manuelle) | 🟢 Existait déjà — corrigé ce module (§1.2 points 6-7) |
| Historique / détail d'un lot | 🟢 Existait déjà, inchangé sauf ajout de l'action « Déclarer un rappel » (staff) |
| Scan de réception | 🟢 **Construit ce module** (D19) — `ReceptionScreen`, route `/traceability/receive` |
| Signalement produit suspect | 🟢 **Construit ce module** (D20) — `ReportScreen`, route `/traceability/report` |

---

## 3. Sécurité & résilience

### 3.1 RLS — 11ème occurrence confirmée du motif « migration de base incomplète en écriture »

`traceable_batches`/`batch_movements` (migration `20260827000700_traceability.sql`) n'avaient **aucune** policy INSERT/UPDATE — seulement `for select to authenticated using (true)`. Cela bloquait silencieusement les deux seules écritures déjà codées (`recallBatch`, `updateBatchStatus`) et aurait bloqué toute future écriture de mouvement. Même motif que C37 (forecasting, Module 11, 10ème occurrence de cette série), C35 (alerts, Module 10) et les occurrences antérieures — les deux tables sont corrigées par la même migration et comptent comme une seule occurrence de ce motif, même convention que C37 (qui couvrait trois tables en une occurrence).

**Corrigé** : migration `20260829023000_traceability_module_fixes.sql`, additive — policies `for all` scopées aux rôles de la chaîne d'approvisionnement (`pharmacien`, `grossiste`, `regulateur`) ou `is_gsg_admin()` sur `traceable_batches`/`batch_movements`. `traceable_batches` n'étant rattachée à aucune officine précise (un lot traverse plusieurs officines/grossistes), le scope ne peut pas utiliser `is_pharmacy_staff` comme les autres modules — d'où un test direct sur `profiles.role`, sur le modèle déjà documenté par `is_gsg_admin()` pour les valeurs CHECK valides.

### 3.2 Sur-exposition en lecture — même motif que C1 (Module 4), corrigé ici

`batch_movements`/`cold_chain_records`/`certificates`/`verification_scans` avaient une policy SELECT `using (true)` : tout compte authentifié, **y compris un patient**, pouvait lire l'intégralité des mouvements internes (utilisateur, numéro de suivi, notes), les relevés chaîne du froid, les certificats, et surtout l'historique de scan de vérification de **n'importe quel autre utilisateur**.

**Corrigé** (même migration) : ces quatre tables restreintes au staff de la chaîne d'approvisionnement (ou à l'auteur du scan pour `verification_scans`, qui doit pouvoir revoir son propre résultat). `traceable_batches` reste volontairement ouvert en lecture : c'est la table que le parcours patient « Vérifier un produit » doit pouvoir lire pour confirmer l'authenticité — seuls ses enfants imbriqués (mouvements, chaîne du froid, certificats) sont désormais masqués à un patient (le `select` imbriqué de `TraceabilityService` continue de fonctionner sans erreur pour un patient : PostgREST retourne simplement des tableaux vides pour les relations filtrées par RLS, sans faire échouer la requête parente — vérifié par relecture du comportement PostgREST/Supabase documenté).

### 3.3 Contrôle d'accès applicatif

- `TraceabilityDashboardScreen` : la vue complète (statistiques, liste de tous les lots) était accessible à **tout** compte authentifié, patient compris — c'est une vue d'exploitation de la chaîne d'approvisionnement, pas un service patient. **Corrigé ce module** : restreinte aux mêmes rôles que la policy RLS d'écriture ; un patient/livreur/professionnel voit désormais une vue réduite (Vérifier / Signaler uniquement).
- `ReceptionScreen` (D19) et l'action « Déclarer un rappel » (`BatchDetailScreen`) : réservées à `pharmacien`/`grossiste`/`regulateur`.
- `ReportScreen` (D20) : ouvert à tout utilisateur authentifié, par conception — un patient est la première ligne de détection d'un produit suspect.

### 3.4 Mode hors-ligne

Directive standing « privilégier le mode hors-ligne » appliquée de façon différenciée selon le risque de chaque écriture, décision documentée plutôt qu'un choix uniforme :

- **Lecture de la liste des lots** (`cache_traceable_batches`, même patron que STK/ORD/RES/LIV/ALR/IA) : repli automatique en cas d'échec réseau.
- **Réception d'un lot** (D19) : mise en file d'attente hors-ligne via `queueOperation` si le réseau est indisponible — jugée rejouable sans risque (idempotente côté serveur), même logique que les ajustements de stock (STK), contrairement aux paiements (PAY, D13).
- **Signalement d'un produit suspect** (D20) : **volontairement PAS mis en file d'attente hors-ligne** — un signalement déclenche une alerte immédiate vers l'officine et l'admin GSG (RG-TRC-02) ; différer cet enchaînement signalement+alerte via la file d'attente générique créerait un signalement silencieusement orphelin sans alerte associée. Un message explicite (« connexion requise ») est affiché plutôt qu'un échec silencieux — même précédent que PAY (D13).

---

## 4. Optimisation & améliorations livrées

1. **`verifyProduct` (`traceability_service.dart`)** — le résultat d'un scan est désormais reporté sur `traceable_batches.is_authenticated`/`is_counterfeit`/`last_verified_at` (best-effort, ne fait jamais échouer une vérification déjà journalisée).
2. **`recallBatch`/`updateBatchStatus`** — produisent désormais un `batch_movement` (type `recall`/déduit du nouveau statut) ; `updateBatchStatus` accepte des paramètres de lieu optionnels.
3. **`receiveBatch` (nouveau, D19, RG-TRC-01)** — enregistre la réception d'un lot (mouvement + changement de statut), bloque un lot rappelé/contrefait, mode hors-ligne.
4. **`reportSuspiciousProduct` (nouveau, D20, RG-TRC-02)** — table `counterfeit_reports` (nouvelle, RLS complète), déclenche une alerte `AlertType.counterfeit` (déjà présent dans le modèle, jamais exploité) vers l'officine concernée et l'admin GSG.
5. **`counterfeit_report.dart`** (nouveau) — modèle miroir de la table.
6. **`ReceptionScreen`** (nouveau, D19) — recherche d'un lot, formulaire de réception (provenance/destination, chaîne du froid optionnelle), réservé au staff.
7. **`ReportScreen`** (nouveau, D20) — formulaire de signalement (description, aspect/emballage/effet inattendu), ouvert à tout utilisateur.
8. **`verification_screen.dart`** — libellé `verifiedBy` dynamique (rôle réel) ; extraction GTIN/numéro de série corrigée (lecture GS1 basique AI(01)/AI(21) avant repli sur l'ancienne heuristique, désormais sans risque de `RangeError`).
9. **`traceability_dashboard_screen.dart`** — vue réduite pour les rôles non-staff ; boutons « Réceptionner » (staff) et « Signaler » (tous) ; chargement de la liste complète évité pour les rôles non-staff.
10. **`batch_detail_screen.dart`** — action « Déclarer un rappel » (staff), corrigeant l'orphelinage de `recallBatch`.
11. **`dashboard_screen.dart`** — cause racine du motif D6 corrigée : ajout de Traçabilité, Alertes (Module 10) et Prévision de la demande (Module 11) au menu de navigation unique de l'application.
12. **`offline_sync_service.dart`** — `cache_traceable_batches` (v9→v10).
13. **Migration `20260829023000_traceability_module_fixes.sql`** — policies RLS (§3.1/§3.2), table `counterfeit_reports`, policy `alerts_admin_select_all` (nécessaire à RG-TRC-02 : l'admin GSG n'avait jusqu'ici aucune policy SELECT sur `alerts` en dehors de ses propres alertes personnelles).
14. **`app_router.dart`** — routes `/traceability/receive`, `/traceability/report`.

---

## 5. Documentation API — `TraceabilityService` (méthodes nouvelles/modifiées)

| Méthode | Paramètres | Retour | Notes |
|---|---|---|---|
| `verifyProduct` | `serialNumber`, `gtin`, `verifiedBy?` | `VerificationResult` | Modifiée — reporte désormais le résultat sur le lot |
| `recallBatch` | `batchId`, `reason`, `issuedBy`, `severity` (défaut Classe II), `totalUnits` (défaut 0), `isPublic` (défaut false), `notes?` | `TraceableBatch` | Modifiée (addendum §7) — produit un `batch_movement` ET crée/publie un `Recall` complet via `RecallService` (module recall unifié) |
| `updateBatchStatus` | `batchId`, `newStatus`, `notes?`, `fromLocation?`, `toLocation?`, `fromLocationType?`, `toLocationType?` | `TraceableBatch` | Modifiée — produit désormais un `batch_movement` |
| `receiveBatch` | `batchId`, `fromLocation`, `toLocation`, `fromLocationType`, `toLocationType`, `newStatus?`, `trackingNumber?`, `notes?`, `temperature?`, `isColdChainRequired` | `TraceableBatch` | Nouvelle (D19) — RG-TRC-01, hors-ligne géré |
| `reportSuspiciousProduct` | `batchId?`, `serialNumber?`, `pharmacyId?`, `description`, `aspectSuspect`, `packagingSuspect`, `unexpectedEffect` | `CounterfeitReport` | Nouvelle (D20) — RG-TRC-02, en ligne uniquement |

---

## 6. Livrables et écarts documentés

Livrés ce module : correctif RLS (11ème occurrence de la série « migration incomplète en écriture »), correctif de sur-exposition en lecture (même motif que C1), boucle de rétroaction vérification→lot, écriture de mouvements pour rappel/changement de statut, écran « Scan de réception » (D19), écran « Signalement produit suspect » (D20), correctif de l'extraction GS1, correction du libellé `verifiedBy`, contrôle d'accès du dashboard, action « Déclarer un rappel » (10ème occurrence de la série D6), correction de la cause racine du menu de navigation (11ème occurrence de la série D6), mode hors-ligne (lecture + réception).

Écarts assumés et documentés : enforcement de RG-TRC-01 partiel (non relié au point de vente réel, même famille que B11) ; RG-TRC-03 hors périmètre (dépend du Module 13, Marketplace/B2B, non audité) ; simulation de scénario de chaîne du froid (relevé de température à la réception) sans écran dédié de suivi continu ; signalement volontairement non disponible hors-ligne (D20).

Voir `PharmaConnect_Module12_Protocole_Test_E2E.md` pour les scénarios de validation et `PharmaConnect_Module12_PV_Recette.md` pour l'état de recette provisoire.

---

## 7. Addendum — deuxième passe de clôture (29/08/2026)

Le porteur du projet a refusé la clôture initiale du module, pointant deux décisions non tranchées (blocage strict au point de vente, éventail des statuts de rappel). L'investigation de ces deux points a révélé que le périmètre inspecté en §1 était incomplet : deux modules hors-cahier entiers (`recall/` et `pos/`, comme `sales`/`cash`/`returns`/`business`, voir registre D3) existent, sont routés, mais n'avaient jamais été examinés par cet audit faute d'appartenir au dossier `traceability/`.

### 7.1 Découverte — module `recall` (pharmacovigilance)

`lib/modules/recall/` est un module complet et déjà routé (`/recall`, `/recall/create`, `/recall/:id`) : sévérité Classe I/II/III (`RecallSeverity`), statut de rappel draft/inProgress/completed/cancelled (`RecallStatus`), statut par lot affecté pending/inProgress/completed/partial/cancelled (`BatchRecallStatus`), numéro de référence auto-généré, action corrective, instructions de diffusion, diffusion publique (`isPublic`), unités retournées/détruites/non récupérées. `recall_affected_batches.batch_id` référence bien `traceable_batches(id)` — le schéma anticipait le lien — mais **aucun code** ne l'utilisait dans un sens ni dans l'autre : ce module et le flag `is_recalled` construit en §4 de ce rapport étaient deux enregistrements de rappel non synchronisés pour le même lot.

**Sécurité** : `recalls`/`recall_affected_batches` (migration `20260827000900_recall.sql`) n'avaient **aucune** policy INSERT/UPDATE — seulement `for select to authenticated using (true)`, qui de surcroît ne distinguait pas un rappel public d'un brouillon interne. **12ème occurrence** confirmée de la série « migration de base incomplète en écriture » (après C39/traceability). **Corrigé** : migration `20260829024000_recall_module_fixes.sql` — écriture réservée au staff de la chaîne d'approvisionnement/admin GSG ; lecture publique restreinte aux rappels `is_public = true`, le reste réservé au même staff/admin.

**Décision du porteur du projet** : unifier plutôt que documenter la duplication. `TraceabilityService.recallBatch` crée désormais un `Recall` (via `RecallService.createRecall` puis `publishRecall`) en plus du flag `is_recalled` — celui-ci reste écrit en parallèle comme lecture rapide sans jointure (utilisée par `receiveBatch` pour bloquer une réception, RG-TRC-01). Le formulaire « Déclarer un rappel » (`batch_detail_screen.dart`) a été étendu : sévérité (obligatoire, défaut Classe II), quantité concernée (optionnelle), diffusion publique (case à cocher, défaut non). `issuedBy` réutilise le même palliatif que `verifiedBy` (§1.2 point 7) : le libellé du rôle, faute de nom complet exposé côté client par `AuthProvider`. La création du `Recall` est best-effort (n'empêche pas le blocage du lot si elle échoue).

Registre : **C41** (RLS, 12ème occurrence) et **D21** (unification, arbitrée et corrigée).

### 7.2 Découverte — cause racine du menu de navigation, incomplète

Le correctif de §1.3/§4.11 (ajout de trois entrées au menu unique `_navItems`) était lui-même une occurrence incomplète du motif : `/recall` n'y figurait pas non plus — **12ème occurrence** de la série D6 (après la 11ème, §1.3, dans ce même module), cette fois découverte par l'unification ci-dessus plutôt que par un audit de module dédié. « Rappels » a été ajouté au menu. Aucune revue exhaustive des ~36 dossiers sous `lib/modules/` n'a été faite pour autant : ce correctif reste, comme le précédent, réactif plutôt qu'exhaustif — une revue de navigation dédiée reste recommandée (registre, nouvelle note sous D6).

### 7.3 Découverte — module `pos` (point de vente), RG-TRC-01 non applicable en l'état

`lib/modules/pos/` est routé et sa RLS est correcte (déjà corrigée lors d'un audit antérieur, commentaire daté dans la migration `20260829006000_pos.sql`). Mais `pos_checkout_screen.dart` vend depuis une liste de produits fictive codée en dur (`_mockProducts`) — même motif que C34 (tableau de bord) — sans sélection de lot réel : aucun `batchId` réel n'est donc jamais transmis à une vente aujourd'hui. De plus `pos_sale_items.batch_id` référence `stock_batches` (Module 4/STK), pas `traceable_batches` (Module 12/TRC) — deux notions de « lot » potentiellement distinctes, jamais réconciliées.

**Décision du porteur du projet** : ne pas construire de blocage RG-TRC-01 au point de vente maintenant — un blocage sur une vente fictive n'aurait aucun effet réel et masquerait le vrai problème (POS non câblé sur de vraies données). RG-TRC-01 reste donc en enforcement partiel, désormais documenté comme dépendant explicitement d'un audit dédié du module POS (hors-cahier, jamais audité, comme `sales`/`cash`/`returns`/`business`).

Registre : **C42** (données fictives POS, même motif que C34), **D22** (décision de report, arbitrée), **D23** (question architecturale ouverte : `stock_batches` vs `traceable_batches`).

### 7.4 Nouveaux livrables

Migration `20260829024000_recall_module_fixes.sql` ; `TraceabilityService.recallBatch`/`TraceabilityProvider.recallBatch` étendus (severity/totalUnits/isPublic/issuedBy) ; `batch_detail_screen.dart` (formulaire de rappel étendu) ; `dashboard_screen.dart` (entrée « Rappels »).

### 7.5 Nouvel écart formel

RG-TRC-01 reste en enforcement partiel — désormais bloqué sur une dépendance explicite (audit POS dédié, non planifié) plutôt que sur une simple absence d'intégration. Le module `recall` reste par ailleurs non couvert par sa propre revue module-par-module complète (seuls sa RLS et son point d'intégration avec `traceability` ont été examinés ici) — un audit dédié reste recommandé s'il doit porter des rappels réglementaires réels (numérotation de référence générée côté client sans séquence Postgres, notification des parties prenantes non implémentée malgré le champ `notifiedParties`, voir `recall_service.dart:_notifyStakeholders`).

---

**Le module Traçabilité (TRC) est-il totalement clos et validé pour passer au suivant ?**
