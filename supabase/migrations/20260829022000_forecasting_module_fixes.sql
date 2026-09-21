-- Module 11 (IA — Prévision de la demande) : correctifs RLS.
--
-- Audit Module 11 (29/08/2026) : `demand_forecasts`/`reorder_alerts`/
-- `scenario_simulations` (migration 20260829005000_stock_forecasting.sql)
-- n'avaient qu'une policy SELECT pour le staff d'officine
-- (`is_pharmacy_staff`) ; la seule autre policy était `for all using
-- (is_gsg_admin())`, réservée à l'admin GSG. Un pharmacien — pourtant le
-- seul rôle qui déclenche réellement `ForecastService.generateDemandForecast`
-- /`checkReorderAlerts`/`simulateScenario` — ne pouvait donc jamais insérer
-- ni mettre à jour ces lignes : 10ème occurrence confirmée du même motif que
-- C35 (alerts, Module 10) et les 8 occurrences précédentes de l'audit.
--
-- Additif, ne retire aucune policy existante (même précédent que
-- 20260829020000_alerts_module_fixes.sql).

create policy "forecasts_insert_staff" on public.demand_forecasts
  for insert to authenticated
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "forecasts_update_staff" on public.demand_forecasts
  for update to authenticated
  using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "reorder_alerts_insert_staff" on public.reorder_alerts
  for insert to authenticated
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "reorder_alerts_update_staff" on public.reorder_alerts
  for update to authenticated
  using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "scenario_simulations_insert_staff" on public.scenario_simulations
  for insert to authenticated
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));
