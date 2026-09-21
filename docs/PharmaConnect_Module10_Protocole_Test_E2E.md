# PharmaConnect — Protocole de test E2E, Module 10 (ALR)

**Date d'émission :** 29/08/2026
**Contexte :** cette session ne dispose ni de SDK Flutter/Dart, ni d'accès CLI Supabase, ni d'appareil/émulateur réel (même limite déjà documentée pour les Modules 4 à 8 — voir registre A1, A7-A16). Les scénarios ci-dessous sont donc écrits pour exécution par le porteur du projet ou une équipe QA sur un environnement outillé (projet Supabase de test + appareil/émulateur), pas exécutés ici. En complément, chaque fichier modifié a été relu manuellement (dry-run) après implémentation ; aucune anomalie supplémentaire n'a été trouvée par cette relecture.

---

## Scénario 1 — Génération d'alerte stock faible (RG-ALR-01)

1. Sur un produit d'une officine, ajuster manuellement le stock pour passer sous `threshold_low` (ex. via `stock_adjustment_screen.dart` ou directement en base).
2. Ouvrir « Alertes de stock » (`/stock/alerts`) avec un compte pharmacien de cette officine.
3. **Attendu** : l'ajustement se reflète dans la liste (déjà couvert par le Module 4). En tâche de fond (`StockProvider.loadAlerts`), une requête `insert` vers `alerts` doit être émise.
4. Vérifier en base (`select * from alerts where reference_id = '<stock_item_id>' order by created_at desc`) qu'une ligne `type = 'stockLow'`, `severity = 'warning'`, `pharmacy_id` renseigné, `user_id` NULL a été créée.
5. Ouvrir le Centre d'alertes (`/alerts`) avec le même compte pharmacien — l'alerte doit apparaître (policy `alerts_staff_select_pharmacy`).

## Scénario 2 — Anti-doublon

1. Sans changer le stock, rouvrir « Alertes de stock » une seconde fois.
2. **Attendu** : aucune nouvelle ligne `alerts` n'est créée pour ce `stock_item_id` + `type = 'stockLow'` (vérifier le compte de lignes avant/après reste identique).

## Scénario 3 — Escalade (stockLow → stockCritical)

1. Depuis l'état du scénario 1, ajuster le stock pour passer sous `threshold_critical`.
2. Rouvrir « Alertes de stock ».
3. **Attendu** : une **nouvelle** ligne `alerts` `type = 'stockCritical'` est créée (l'anti-doublon est scopé par type, pas seulement par référence — l'ancienne alerte `stockLow`, non résolue, doit rester visible en parallèle).

## Scénario 4 — Alerte péremption (RG-ALR-02)

1. Créer ou faire pointer un lot vers une date de péremption à J+45 (dans l'horizon 60 jours câblé).
2. Ouvrir « Alertes de stock » avec un compte de l'officine concernée.
3. **Attendu** : une ligne `alerts` `type = 'expirySoon'`, `reference_type = 'batch'`, `reference_id = '<batch_id>'` est créée.
4. Faire passer la date de péremption dans le passé (lot déjà périmé) et répéter — **attendu** : `type = 'expired'`, `severity = 'critical'`.

## Scénario 5 — RLS, non-régression (accès refusé)

1. Avec un compte `patient` (aucun `pharmacy_id`), tenter de lire `alerts` où `pharmacy_id` est renseigné (ex. via une requête directe authentifiée en tant que ce patient).
2. **Attendu** : aucune ligne retournée (RLS filtre silencieusement).
3. Avec un compte pharmacien de l'officine A, tenter de lire/modifier une alerte `pharmacy_id = <officine B>`.
4. **Attendu** : refusé (0 ligne en lecture, erreur ou 0 ligne affectée en écriture).

## Scénario 6 — Écran de détail

1. Depuis le Centre d'alertes, cliquer une alerte non lue.
2. **Attendu** : ouverture de `/alerts/detail/:id`, l'alerte passe automatiquement à `is_read = true`/`status = 'read'`, la recommandation contextuelle s'affiche, les boutons « Marquer comme traité »/« Ignorer » fonctionnent et mettent bien à jour `status` en base (`actioned`/`dismissed`).
3. Si l'alerte a un `action_route`/`action_label`, vérifier que le bouton d'action principal navigue bien vers cette route.

## Scénario 7 — Mode hors-ligne (lecture)

1. Ouvrir le Centre d'alertes en ligne (peuple `cache_alerts`).
2. Couper le réseau.
3. Rouvrir le Centre d'alertes.
4. **Attendu** : le bandeau « Hors ligne — dernières alertes connues affichées » apparaît, et la liste précédemment chargée reste visible (issue du cache local, pas d'écran vide/erreur).

## Scénario 8 — Paramétrage des seuils (D15, nouvel écran)

1. Avec un compte pharmacien de l'officine, ouvrir le Centre d'alertes → menu (icône ⋮) → « Paramétrage des seuils ».
2. **Attendu** : la liste du stock de l'officine s'affiche avec les seuils actuels.
3. Modifier le seuil faible et le seuil critique d'un produit (ex. 20 → 30, 5 → 8), enregistrer.
4. **Attendu** : `stock_items.threshold_low`/`threshold_critical` mis à jour en base, `status` recalculé immédiatement si le changement fait basculer l'article en/hors alerte (ex. un stock à 25 devient `lowStock` après avoir relevé le seuil faible à 30, sans qu'aucun mouvement de stock n'ait eu lieu).
5. Réouvrir « Alertes de stock » — **attendu** : une nouvelle alerte est générée si le nouveau statut le justifie (le changement de seuil, pas de quantité, en est la cause).

## Scénario 9 — Paramétrage des seuils, validation et contrainte

1. Dans le dialogue d'édition, saisir un seuil critique supérieur au seuil faible (ex. faible = 10, critique = 20).
2. **Attendu (validation UI)** : le formulaire refuse l'enregistrement avec le message « Doit être ≤ au seuil faible », aucun appel réseau n'est émis.
3. Contourner l'UI (requête SQL directe) pour tenter `update stock_items set threshold_critical = 20, threshold_low = 10 where id = '<id>'`.
4. **Attendu (contrainte base)** : rejeté par la contrainte `stock_items_thresholds_valid` (violation de contrainte CHECK).

## Scénario 10 — Paramétrage des seuils, contrôle d'accès

1. Avec un compte `patient`, naviguer directement vers `/alerts/thresholds`.
2. **Attendu** : écran « Réservé aux pharmaciens de l'officine. », aucune liste de stock affichée.
3. Avec un compte pharmacien sans `pharmacy_id` rattaché, répéter.
4. **Attendu** : écran « Aucune officine rattachée à ce compte pharmacien. ».

---

## Synthèse

10 scénarios, dont 5 nouveaux pour l'ajout de l'écran « Paramétrage des seuils » (arbitrage D15). Comme pour le Module 8, aucun n'a été exécuté dans cette session — la relecture manuelle du code (`AlertService`, `StockProvider._generateStockAndExpiryAlerts`, `StockService.updateThresholds`, `AlertThresholdSettingsScreen`) n'a révélé aucune anomalie logique, mais seule une exécution réelle sur un environnement outillé peut clore ces scénarios.
