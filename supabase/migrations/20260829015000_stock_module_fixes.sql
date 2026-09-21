-- Module stock (Module 4 — STK, audit 29/08/2026).
--
-- Registre des écarts, item C1 : stock_batches/stock_movements/
-- stock_adjustments étaient lisibles par n'importe quel utilisateur
-- authentifié (patient compris) via `for select to authenticated using
-- (true)`. Ce sont des journaux/détails opérationnels internes à
-- l'officine, sans consommateur public légitime — contrairement à
-- stock_items, dont la lecture large reste nécessaire pour la recherche de
-- disponibilité publique (Module 2 — REC, déjà clos : search_service.dart
-- lit stock_items pour tout patient). stock_items n'est donc volontairement
-- PAS restreint ici.

drop policy if exists "stock_batches_select_authenticated" on public.stock_batches;
drop policy if exists "stock_movements_select_authenticated" on public.stock_movements;
drop policy if exists "stock_adjustments_select_authenticated" on public.stock_adjustments;

create policy "stock_batches_select_staff" on public.stock_batches
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.stock_items si
      where si.id = stock_batches.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );

create policy "stock_movements_select_staff" on public.stock_movements
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.stock_items si
      where si.id = stock_movements.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );

create policy "stock_adjustments_select_staff" on public.stock_adjustments
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.stock_items si
      where si.id = stock_adjustments.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );
