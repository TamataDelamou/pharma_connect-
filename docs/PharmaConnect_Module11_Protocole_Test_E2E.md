# PharmaConnect — Protocole de test E2E, Module 11 (IA — Prévision de la demande)

**Date d'émission :** 29/08/2026
**Contexte :** même limite que les Modules 1 à 10 — pas de SDK Flutter/Dart, pas d'accès CLI Supabase, pas d'appareil/émulateur réel depuis cette session. Scénarios écrits pour exécution par le porteur du projet ou une équipe QA. Chaque fichier modifié a été relu manuellement (dry-run) ; aucune anomalie supplémentaire trouvée par cette relecture au-delà de celles déjà corrigées.

---

## Scénario 1 — Compilation (préalable à tout le reste)

1. Lancer `flutter analyze` (ou `flutter build`) sur le projet complet après application des correctifs de ce module.
2. **Attendu** : aucune erreur sur `demand_forecast.dart` (constructeur `ReorderAlert` désormais valide), `forecast_provider.dart` (`_client` supprimé) ni les fichiers dépendants. C'est le scénario le plus important de ce module : avant correctif, ces deux fichiers empêchaient la compilation du projet entier.

## Scénario 2 — Génération de prévision avec historique réel

1. Sur un produit ayant au moins 3-4 ventes confirmées (`StockMovementType.sale`, via une réservation retirée — Module 6) dans une officine donnée, se connecter avec un compte pharmacien de cette officine.
2. Ouvrir « Alertes de stock » (`/stock/alerts`) → icône « Prévision de la demande ».
3. Sélectionner ce produit dans le sélecteur (désormais alimenté par le stock réel de l'officine).
4. **Attendu** : la prévision générée reflète la vélocité de vente réelle (pas systématiquement 10/jour) ; vérifier en base que `demand_forecasts` contient bien des lignes `pharmacy_id` = l'officine testée (pas l'ID utilisateur).

## Scénario 3 — Génération de prévision sans historique

1. Répéter avec un produit n'ayant jamais été vendu.
2. **Attendu** : repli sur la moyenne par défaut (10/jour), comportement documenté, pas d'exception.

## Scénario 4 — RLS, écriture des prévisions (non-régression)

1. Avec le compte pharmacien de l'officine A, générer une prévision.
2. **Attendu** : insertion réussie dans `demand_forecasts` (policy `forecasts_insert_staff`).
3. Avec un compte pharmacien d'une officine B, tenter d'insérer directement une ligne `demand_forecasts` avec `pharmacy_id` = officine A.
4. **Attendu** : refusé par RLS.

## Scénario 5 — Alertes de réapprovisionnement, anti-doublon

1. Ouvrir l'écran de prévision une première fois (déclenche `checkAlerts`) pour une officine ayant au moins un produit sous son `threshold_low`.
2. Noter le nombre de lignes `reorder_alerts` (`status = 'pending'`) pour ce produit.
3. Rouvrir l'écran sans changer le stock.
4. **Attendu** : aucune nouvelle ligne insérée (le nombre reste identique).

## Scénario 6 — Commande recommandée, validation (D17, RG-IA-01)

1. Depuis la bannière d'alertes de réapprovisionnement, cliquer « Voir » → `/stock/forecast/orders`.
2. **Attendu** : liste des propositions en attente, avec quantité pré-remplie.
3. Modifier la quantité, valider.
4. **Attendu** : `reorder_alerts.status` passe à `'ordered'`, `quantity_to_order` mis à jour, l'item disparaît de la liste des propositions en attente. Vérifier qu'aucun appel réseau vers un service tiers (fournisseur) n'est émis — confirmer par lecture du code qu'aucune intégration de ce type n'existe.

## Scénario 7 — Commande recommandée, écarter

1. Sur une autre proposition, cliquer « Écarter ».
2. **Attendu** : `status` passe à `'cancelled'`, l'item disparaît de la liste.

## Scénario 8 — RLS, écriture des propositions (non-régression)

1. Avec le compte pharmacien de l'officine A, valider/écarter une proposition de son officine.
2. **Attendu** : réussi (policy `reorder_alerts_update_staff`).
3. Tenter la même opération sur une proposition d'une officine B.
4. **Attendu** : refusé par RLS (0 ligne affectée).

## Scénario 9 — Contrôle d'accès

1. Avec un compte `patient`, naviguer directement vers `/stock/forecast` puis `/stock/forecast/orders`.
2. **Attendu** : écran « Réservé aux pharmaciens de l'officine. » sur les deux écrans.
3. Avec un compte pharmacien sans `pharmacyId` rattaché, répéter.
4. **Attendu** : écran « Aucune officine rattachée à ce compte pharmacien. ».

## Scénario 10 — Mode hors-ligne (lecture)

1. Ouvrir l'écran de prévision en ligne (peuple `cache_forecasts`) puis l'écran de commande recommandée (peuple `cache_reorder_alerts`).
2. Couper le réseau.
3. Rouvrir les deux écrans.
4. **Attendu** : bandeau « Hors ligne » sur chacun, contenu précédemment chargé toujours visible.

---

## Synthèse

10 scénarios, dont le premier (compilation) est un préalable bloquant à tous les autres — avant les correctifs de ce module, le projet entier n'aurait pas pu être analysé/buildé à cause de `demand_forecast.dart`/`forecast_provider.dart`. Comme pour tous les modules précédents, aucun scénario n'a été exécuté dans cette session ; la relecture manuelle de chaque fichier modifié n'a révélé aucune anomalie supplémentaire.
