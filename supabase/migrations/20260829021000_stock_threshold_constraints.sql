-- Module 10 (ALR) — arbitrage D15 (porteur du projet, 29/08/2026) : l'écran
-- « Paramétrage des seuils par produit » manquant au cahier est construit ce
-- module (voir StockService.updateThresholds / AlertThresholdSettingsScreen).
-- stock_items.threshold_low/threshold_critical (20260827000600_stock.sql)
-- n'avaient aucune contrainte relative entre elles ni de borne basse — un
-- pharmacien pouvait déjà, avant ce correctif, écrire threshold_critical >
-- threshold_low via une requête directe (aucun écran ne le faisait, mais
-- rien ne l'empêchait au niveau base). Avec un écran d'édition qui rend ce
-- risque réel pour la première fois, une garde-fou base de données est
-- ajoutée en défense en profondeur, en plus de la validation côté écran.

alter table public.stock_items
  add constraint stock_items_thresholds_valid
  check (
    threshold_low >= 0
    and threshold_critical >= 0
    and threshold_critical <= threshold_low
  );
