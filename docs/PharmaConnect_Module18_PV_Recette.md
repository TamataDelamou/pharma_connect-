# PharmaConnect — PV de recette, Module 18 (HOM — PharmaConnect HomeCare, Consultation & Soins à domicile)

**Date d'émission :** 30/08/2026
**Émis par :** Session d'audit (Superviseur & Architecte Logiciel Senior)
**Statut du document :** Provisoire — la recette formelle ne peut être close qu'après exécution du protocole de test E2E (`PharmaConnect_Module18_Protocole_Test_E2E.md`), en priorité absolue le Scénario 1 (compilation) puis le Scénario 2 (cycle de statut d'une intervention jusqu'en base, seul moyen de confirmer C72 hors relecture de code), sur un environnement outillé non disponible depuis cette session.

---

## 1. Objet

Constater l'état du Module 18 à l'issue de son inspection, de ses correctifs, et de l'arbitrage de périmètre (D31), et servir de base à la décision de recette par le porteur du projet.

## 2. Périmètre couvert

Correctif de 4 défauts de compilation/exécution (méthode inexistante appelée, 3 imports `SupabaseService` manquants dans autant de fichiers), correctif d'une nouvelle classe de bug pour cet audit (désynchronisation entre la sérialisation Dart d'un enum et la contrainte CHECK SQL correspondante, `HomecareStatus.inProgress`), remplacement de la liste de professionnels mockée par une vraie requête `professional_profiles` (même précédent que le Module 15), mise en conformité de RG-HOM-03 (compte-rendu obligatoire à la clôture) et ajout du motif de refus obligatoire (fonctionnalité clé cahier absente), suppression d'un bouton mort, correctif d'une seconde nouvelle classe de bug (dérive de schéma du cache SQLite hors-ligne, erreur avalée silencieusement), ajout d'une policy DELETE manquante et d'une policy de supervision admin, câblage de la navigation (18ème occurrence de la série D6), et surtout un balayage transverse complet de `app_router.dart` révélant que le bug de shadowing de route go_router (découvert au Module 17, C69) est systémique — 16 relocalisations effectuées, dans 10+ modules dont plusieurs déjà clos.

Hors périmètre, par arbitrage explicite du porteur du projet (D31) : les 4 fonctionnalités clés du cahier les plus différenciantes de HOM — arbitrage télécons/domicile par le professionnel, recherche multi-critères du professionnel le plus pertinent, estimation/suivi temps réel de l'approche, intégration du compte-rendu au DSN (Module 21) — ne sont pas construites ce module.

## 3. Méthode de vérification effectuée dans cette session

| Méthode | Réalisée | Détail |
|---|---|---|
| Revue de code exhaustive du module | ✅ Oui | 2 modèles, 2 services, 2 providers, 5 écrans, 1 widget, 1 migration d'origine, plus les fichiers précédents du Module 15 relus pour fidélité du motif de correctif |
| Analyse comparative au cahier de conception | ✅ Oui | RG-HOM-01/02/03, 5 fonctionnalités clés/écrans principaux — écart de périmètre identifié et arbitré (D31) |
| Vérification syntaxique statique (équilibrage accolades/parenthèses) | ✅ Oui | Script dédié `.dart` (`/home/claude/check_balance.py`) exécuté après chaque édition, y compris une passe complète finale sur `app_router.dart` après les 16 relocalisations |
| Détection programmatique de shadowing de route go_router | ✅ Oui | Script Python dédié, écrit spécifiquement pour ce module, exécuté sur `app_router.dart` en entier après les correctifs — 0 conflit restant à la vérification finale (2 conflits résiduels trouvés puis corrigés lors d'une première exécution) |
| Comptage de contrôle (routes orphelines/noms dupliqués) | ✅ Oui | `grep -c "GoRoute("` = `grep -c "path: '"` = 160 ; aucun nom de route dupliqué |
| Relecture manuelle de trace d'exécution (dry-run) | ✅ Oui | Cycle de statut d'une intervention, réservation, clôture, refus, cache hors-ligne, policies RLS, retracés intégralement |
| Analyse statique outillée (`dart analyze`/`flutter analyze`) | ❌ Non | Pas de SDK Flutter/Dart disponible |
| Tests unitaires/`flutter test` | ❌ Non | Même limite |
| Exécution réelle des migrations sur base de test | ❌ Non | Pas d'accès CLI Supabase (limite documentée depuis le Module 0, item A1) |
| Test end-to-end sur appareil/émulateur réel | ❌ Non | Pas d'accès appareil/émulateur (limite documentée depuis le Module 1) |

**Conclusion de méthode :** ce PV atteste d'une recette **par revue de code et raisonnement statique**, complétée cette fois d'une vérification programmatique dédiée (script de détection de shadowing) plutôt que d'une simple relecture visuelle — précisément parce que la relecture visuelle initiale de `app_router.dart` s'est révélée incomplète (2 conflits manqués sur 18). Le Scénario 2 du protocole E2E (cycle de statut d'une intervention jusqu'en base) doit être exécuté en priorité, C72 étant par construction invisible à toute vérification qui ne va pas jusqu'à la base de données réelle.

## 4. Critères de recette et statut

| Critère | Référence | Statut |
|---|---|---|
| Méthode `getInterventionsForPatient` inexistante | Rapport d'audit §3.1 point 1 (C71) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1 |
| 3 imports `SupabaseService` manquants | Rapport d'audit §3.1 points 2-4 (C71) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 1 |
| Désynchronisation enum/CHECK SQL (`inProgress`) | Rapport d'audit §3.2 (C72) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 2, priorité absolue, seul scénario capable de révéler ce défaut |
| Liste de professionnels mockée | Rapport d'audit §3.3 (C73) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 3 |
| RG-HOM-03 (compte-rendu obligatoire) | Rapport d'audit §3.4 (C74) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 4 |
| Motif de refus obligatoire | Rapport d'audit §3.4 (C74) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 4 |
| Bouton « Terminer » mort | Rapport d'audit §3.4 | 🟢 Supprimé |
| Dérive de schéma du cache hors-ligne | Rapport d'audit §3.5 (C75) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 5 |
| Policy DELETE manquante | Rapport d'audit §3.6 (C76) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| Supervision admin manquante | Rapport d'audit §3.6 (C76) | 🟢 Corrigé (revue de code) — à confirmer par le Scénario 6 |
| Shadowing de route go_router — 16 relocalisations transverses | Rapport d'audit §3.7 (C77) | 🟢 Corrigé et vérifié programmatiquement (0 conflit restant, script dédié) — à confirmer en conditions réelles par le Scénario 7 |
| Navigation — entrée « Soins à domicile » (série D6, 18ème occurrence) | Rapport d'audit §3.8 | 🟢 Corrigé (revue de code) |
| Choix télécons/domicile arbitré par le professionnel | Rapport d'audit §2.2 | 🔴 Non implémenté — hors périmètre arbitré (D31) |
| Recherche multi-critères du professionnel (distance/disponibilité/langue) | Rapport d'audit §2.2 | 🟡 Partiel — spécialité/vérification/acceptation filtrés ; distance/disponibilité/langue non filtrés malgré des données disponibles en base (D31) |
| Estimation/suivi temps réel de l'approche | Rapport d'audit §2.2 | 🔴 Non implémenté — hors périmètre arbitré (D31) |
| Intégration DSN à la clôture | Rapport d'audit §2.2 | 🔴 Non implémenté — Module 21 (DSN) non encore audité/construit (D31) |
| RG-HOM-01 (exclusion des urgences TRI) | Rapport d'audit §2.2 | 🔴 Aucune vérification croisée HOM↔TRI — non traité ce module, non arbitré explicitement |
| RG-HOM-02 (rémunération indépendante des actes) | Rapport d'audit §2.2 | ⚪ Non applicable — aucune fonctionnalité de rémunération n'existe dans ce module |

## 5. Réserves formelles

1. ~~**Aucun des scénarios du protocole de test E2E n'a été exécuté**~~ — **Scellé pour sa part statique au 1er refus de clôture, voir §5 bis, Point 2** : la correction C72 est désormais vérifiée exhaustivement contre les 6 valeurs de l'enum et la contrainte CHECK réelle (aucune désynchronisation résiduelle). Reste néanmoins vrai qu'aucun scénario du protocole E2E n'a été exécuté sur un environnement outillé — seule une écriture réelle contre Supabase (Scénario 2) peut clore ce point de façon définitive, la vérification statique ne pouvant qu'exclure une erreur de raisonnement, pas une erreur d'exécution réelle.
2. **Écart de périmètre significatif non résolu (D31)** — 4 des 5 fonctionnalités clés du cahier pour HOM restent absentes ou partielles (arbitrage professionnel, matching multi-critères, suivi temps réel, intégration DSN). Reste en 🟡 au registre — report assumé, pas une clôture du périmètre cahier complet.
3. **RG-HOM-01 (exclusion des urgences TRI) non vérifié** — aucun lien technique n'existe entre HOM et TRI ; ni corrigé ni explicitement arbitré comme dette ce module, faute d'avoir été identifié comme un défaut à corriger avant la rédaction de ce PV plutôt que comme un écart de périmètre. Signalé ici pour que le porteur du projet puisse trancher explicitement s'il doit être traité avant clôture ou reporté formellement au même titre que le reste de D31.
4. ~~**Balayage transverse C77 corrigé sur la seule base d'une vérification statique**~~ — **Renforcé au 1er refus de clôture, voir §5 bis, Point 1** : au-delà des 3 vérifications structurelles déjà réalisées (équilibrage, détection de shadowing, comptages), les 18 routes concernées (16 relocalisées + les 2 sœurs dynamiques de STK/teleconsult explicitement demandées) ont été relues individuellement pour confirmer que `path`/`name`/`builder` sont restés strictement identiques à leur déclaration d'origine. Reste néanmoins vrai qu'aucune navigation réelle dans l'application (clic sur chaque bouton concerné) n'a pu être exercée, faute d'environnement outillé — seul le Scénario 7 peut clore ce point de façon définitive.
5. **Aucune migration/RLS/mise à jour de schéma n'a été exécutée sur un environnement réel** — les correctifs sont validés par relecture de code uniquement.

## 5 bis. Addendum — réponse au 1er refus de clôture (30/08/2026)

Le porteur du projet a refusé la clôture initiale sur deux points de contrôle précis : (1) confirmer que le balayage transverse de routage (C77, 16 relocalisations touchant 14 modules au-delà de HOM, dont STK et CNS/teleconsult déjà clos) n'a introduit aucune rupture dans la déclaration des routes existantes ; (2) sceller la correction de désynchronisation enum/contrainte CHECK (C72) en confirmant explicitement qu'aucune désynchronisation similaire ne subsiste sur les autres statuts du flux HomeCare (`pending`, `confirmed`, `completed`, `cancelled`, `missed`). Traité par relecture ciblée directe du code et de la migration livrés à l'appareil (pas de mémoire), avant réponse — même méthode que l'addendum du Module 17.

**Point 1 — Intégrité du balayage transverse de routage (C77), re-vérifiée.**

Trois vérifications indépendantes ont été ré-exécutées sur `app_router.dart` tel que livré à l'appareil :

- **Équilibrage syntaxique** (`/home/claude/check_balance.py`) : `OK`, aucune accolade/parenthèse orpheline.
- **Détection programmatique de shadowing** (script Python dédié, parcourt chaque route à segment dynamique et vérifie l'absence de sœur statique de même profondeur déclarée plus loin) : `0 conflicts remain`.
- **Comptage de contrôle** : 160 `GoRoute(` = 160 `path: '` (aucune déclaration orpheline issue d'une erreur d'édition), aucun nom de route dupliqué (`grep -oE "name: '...'" | sort | uniq -d` vide), aucun chemin dupliqué.

Au-delà de ces vérifications structurelles déjà réalisées avant la livraison, une vérification de **contenu** ciblée a été effectuée spécifiquement sur les deux modules cités par le porteur du projet (STK, déjà clos au Module 4 ; teleconsult/CNS, déjà clos au Module 15), plus l'ensemble des 16 routes relocalisées de ce balayage, en relisant directement chaque bloc `GoRoute` après relocalisation pour confirmer que `path`/`name`/`builder` sont restés strictement identiques à leur déclaration d'origine — seule leur position dans le fichier a changé :

| Route | Fichier/ligne actuelle | `name` | `builder` | Statut |
|---|---|---|---|---|
| `/stock/forecast` | ligne 484 | `stock-forecast` | `DemandForecastScreen()` | 🟢 Conforme |
| `/stock/:id` | ligne 489 (inchangée, non déplacée) | `stock-detail` | `StockDetailScreen(stockId: id)` | 🟢 Conforme — non-régression confirmée |
| `/teleconsult/book` | ligne 681 | `teleconsult-book` | `TeleconsultBookingScreen()` | 🟢 Conforme |
| `/teleconsult/:id` | ligne 686 (inchangée) | `teleconsult-detail` | `TeleconsultDetailScreen(consultationId: id)` | 🟢 Conforme — non-régression confirmée |
| `/homecare/book` | ligne 714 | `homecare-book` | `HomecareBookingScreen()` | 🟢 Conforme |
| `/homecare/offline` | ligne 719 | `homecare-offline` | `OfflineHomecareScreen()` | 🟢 Conforme |
| `/recall/create`, `/coldchain/add`, `/healthrecord/edit`, `/healthrecord/alerts`, `/family/new`, `/family/alerts`, `/family/sos`, `/regulator/report`, `/support/new`, `/eprescription/scan`, `/chains/group/new`, `/iot/device/new`, `/business/company/new`, `/sales/customer/new`, `/returns/customer/new` | (14 emplacements relus individuellement) | — | Chacune pointe vers son écran d'origine (`RecallCreateScreen`, `EquipmentAddScreen`, `HealthRecordEditScreen`, `PreventiveAlertsScreen`, `FamilyNewScreen`, `FamilyListScreen`, `SOSScreen`, `AdverseReactionReportScreen`, `NewTicketScreen`, `ScannerScreen`, `GroupCreateScreen`, `DeviceCreateScreen`, `CompanyCreateScreen`, `CustomerCreateScreen`, `CustomerReturnCreateScreen`) | 🟢 Conforme, 14/14 |

**Conclusion Point 1** : les 18 routes déplacées ou revérifiées comme non-régressées (16 relocalisations + les 2 routes dynamiques sœurs de STK/teleconsult explicitement demandées) sont toutes conformes — la relocalisation a strictement modifié l'ordre de déclaration, jamais le contenu d'une route. Aucune rupture trouvée dans STK ni dans CNS/teleconsult. Cette vérification reste une revue de code statique, pas une navigation réelle dans l'application (voir réserve n°4, inchangée) — seul le Scénario 7 du protocole E2E peut clore ce point de façon définitive.

**Point 2 — Scellement de la correction enum/contrainte CHECK (C72), tous statuts vérifiés.**

Relecture directe de la contrainte CHECK réelle (`supabase/migrations/20260827004000_homecare.sql`, ligne 25) : `status text not null check (status in ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'missed'))`. Comparaison exhaustive avec les 6 valeurs de l'enum Dart `HomecareStatus` (`pending`, `confirmed`, `inProgress`, `completed`, `cancelled`, `missed`) :

| Valeur enum Dart | `.name` (forme brute, l'ancien bug) | Valeur CHECK SQL | `dbValue` (après correctif) | Désynchronisation ? |
|---|---|---|---|---|
| `pending` | `pending` | `pending` | `pending` | Non — coïncidence déjà correcte |
| `confirmed` | `confirmed` | `confirmed` | `confirmed` | Non — coïncidence déjà correcte |
| `inProgress` | `inProgress` | `in_progress` | `in_progress` | **Oui — seule valeur affectée, corrigée** |
| `completed` | `completed` | `completed` | `completed` | Non — coïncidence déjà correcte |
| `cancelled` | `cancelled` | `cancelled` | `cancelled` | Non — coïncidence déjà correcte |
| `missed` | `missed` | `missed` | `missed` | Non — coïncidence déjà correcte |

`inProgress` est la seule valeur de l'enum dont l'identifiant Dart est composé de plusieurs mots (camelCase) — c'est structurellement la seule qui pouvait diverger de sa forme snake_case ; les 5 autres valeurs sont des mots simples, insensibles à la distinction de casse camelCase/snake_case. Confirmé par ailleurs, par recherche exhaustive dans le module (`grep -n "\.name\b"` sur `homecare_service.dart`, `intervention.dart`, `homecare_provider.dart`, `offline_homecare_provider.dart`, tous les écrans) : **aucun usage résiduel de `.name` brut** pour la colonne `status` — les 3 écritures (`Intervention.toJson()`, `HomecareService.updateInterventionStatus`, `HomecareService.getInterventionsForUser`/`getAvailableSlotsForDate`) passent toutes par `.dbValue`, et l'unique lecture (`Intervention.fromJson()`) passe par `homecareStatusFromDb()`. Un commentaire d'audit explicite (lignes 54-66 de `homecare_status.dart`) documente le piège pour éviter sa réintroduction lors d'un futur ajout de statut composé.

Vérification syntaxique complémentaire sur `homecare_status.dart` et `intervention.dart` : `check_balance.py` → `OK`, aucune régression introduite par cette relecture.

**Conclusion Point 2 — scellé** : la correction ne couvre pas seulement `inProgress` par accident de coïncidence, mais par une vérification exhaustive des 6 valeurs de l'enum contre la contrainte CHECK réelle — aucune désynchronisation résiduelle sur `pending`/`confirmed`/`completed`/`cancelled`/`missed`.

**Fichiers relus pour cet addendum** : `lib/routes/app_router.dart` (18 blocs `GoRoute` cités ci-dessus + 2 scripts de vérification), `supabase/migrations/20260827004000_homecare.sql` (contrainte CHECK d'origine, ligne 25), `lib/modules/homecare/models/homecare_status.dart`, `lib/modules/homecare/models/intervention.dart`, `lib/modules/homecare/services/homecare_service.dart`, `lib/modules/homecare/providers/homecare_provider.dart`, `lib/modules/homecare/providers/offline_homecare_provider.dart`. Aucun changement de code supplémentaire requis par cet addendum — les deux points étaient déjà corrects dans le code livré ; seules les confirmations et preuves documentaires ci-dessus sont nouvelles (présent PV).

**Le protocole de validation E2E complet (Scénario 1 à 7) reste entièrement à exécuter sur un environnement outillé** — cet addendum objective le raisonnement statique (structure, contenu, exhaustivité), il ne remplace pas une exécution réelle contre une base Postgres et une navigation réelle dans l'application. Réserves n°1 et n°4 (§5) restent donc ouvertes en l'état ; seule leur base de confiance (relecture superficielle → relecture exhaustive et vérifiée par script) a changé.

## 6. Décision de recette

☐ **Recette prononcée sans réserve** — nécessite l'exécution complète du protocole de test E2E, Scénario 2 en priorité absolue.
☐ **Recette prononcée avec réserves** — lister les réserves acceptées et la date limite de levée.
☐ **Recette refusée / reportée** — lister les motifs bloquants.

*Case à cocher et à signer par le porteur du projet après exécution du protocole de test E2E.*

Nom : _______________________ Date : _______________ Signature : _______________________

---

**Le module HomeCare (HOM) est-il totalement clos et validé pour passer au suivant ?**
