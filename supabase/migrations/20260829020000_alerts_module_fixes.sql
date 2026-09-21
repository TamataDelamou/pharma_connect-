-- Module 10 (ALR) — corrections RLS.
--
-- La table alerts (migration 20260827001400_alerts.sql) n'avait AUCUNE
-- policy INSERT : tout appel à AlertService.createAlert() — donc à
-- generateStockAlert()/generateExpiryAlert(), qui jusqu'à cet audit n'étaient
-- d'ailleurs jamais appelées nulle part dans l'app, voir le rapport d'audit
-- Module 10 — échouait avec permission denied dès la première tentative
-- d'écriture réelle.
--
-- Par ailleurs, les policies SELECT/UPDATE existantes (alerts_select_own /
-- alerts_update_own) ne couvrent que le cas auth.uid() = user_id, c'est-à-
-- dire une alerte strictement personnelle. Or generateStockAlert() et
-- generateExpiryAlert() créent des alertes rattachées à une OFFICINE
-- (pharmacy_id renseigné) et non à un utilisateur précis (user_id NULL) —
-- exactement comme le stock ou les lots eux-mêmes n'appartiennent pas à un
-- utilisateur mais à une officine. Avec les seules policies existantes, une
-- telle alerte, même une fois insérée, ne serait JAMAIS visible ni
-- actionnable par personne (auth.uid() = NULL n'est jamais vrai) : le centre
-- d'alertes resterait vide pour tout le staff de l'officine concernée.
--
-- Corrigé en ajoutant : une policy INSERT couvrant les deux cas (alerte
-- personnelle OU alerte d'officine créée par un membre du staff rattaché), et
-- des policies SELECT/UPDATE staff symétriques à alerts_select_own /
-- alerts_update_own pour le cas pharmacy_id. Réutilise
-- public.is_pharmacy_staff(), déjà en place depuis
-- 20260827002000_staff_write_policies.sql (Module 4).

create policy "alerts_insert_own_or_staff" on public.alerts
  for insert to authenticated
  with check (
    auth.uid() = user_id
    or (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  );

create policy "alerts_staff_select_pharmacy" on public.alerts
  for select to authenticated
  using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "alerts_staff_update_pharmacy" on public.alerts
  for update to authenticated
  using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));
