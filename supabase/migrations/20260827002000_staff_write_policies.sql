-- Politiques RLS d'écriture pour le staff (pharmacien/livreur). Jusqu'ici,
-- les tables stock/livraison n'avaient que des policies de lecture ouverte
-- à `authenticated` — aucune écriture n'était possible depuis le produit.
-- Décision de conception (confirmée avec l'utilisateur) : le rôle vit sur le
-- compte existant (public.profiles.role, déjà présent depuis la migration
-- profiles) plutôt qu'une table de rattachement séparée. profiles.pharmacy_id
-- (nouveau) complète ce rôle pour le staff officine. Les livreurs restent
-- rattachés via delivery_drivers.user_id (déjà existant) — pas ce champ.
--
-- pharmacy_id est volontairement rempli après vérification de licence
-- (RG-AUT-01), jamais à l'auto-inscription : aucune UI ne l'écrit
-- aujourd'hui (chantier séparé, non couvert ici).

alter table public.profiles
  add column if not exists pharmacy_id uuid references public.pharmacies(id);

comment on column public.profiles.pharmacy_id is
  'Officine de rattachement pour le staff (role = pharmacien). Renseigné après vérification de licence (RG-AUT-01), pas à l''auto-inscription. Non utilisé pour role = livreur (voir delivery_drivers.user_id).';

create index if not exists idx_profiles_pharmacy_id on public.profiles(pharmacy_id);

-- SECURITY DEFINER + search_path verrouillé : évite toute dépendance aux
-- policies de profiles (qui ne s'appliqueraient pas de la même façon executées
-- depuis une autre table) et toute récursion si profiles gagne un jour une
-- policy qui appellerait cette fonction.
create or replace function public.is_pharmacy_staff(target_pharmacy_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'pharmacien'
      and pharmacy_id = target_pharmacy_id
  );
$$;

comment on function public.is_pharmacy_staff(uuid) is
  'Vrai si l''utilisateur courant est staff (role pharmacien) rattaché à target_pharmacy_id. Utilisé par les policies RLS d''écriture stock.';

-- ==================== STOCK : écriture staff officine ====================
-- stock_items/stock_batches : gestion complète (le staff crée/ajuste son
-- inventaire). stock_movements/stock_adjustments : insertion seule — ce sont
-- des journaux, jamais modifiés ni supprimés une fois écrits.

create policy "stock_items_write_staff" on public.stock_items
  for all to authenticated
  using (public.is_pharmacy_staff(pharmacy_id))
  with check (public.is_pharmacy_staff(pharmacy_id));

create policy "stock_batches_write_staff" on public.stock_batches
  for all to authenticated
  using (
    exists (
      select 1 from public.stock_items si
      where si.id = stock_batches.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  )
  with check (
    exists (
      select 1 from public.stock_items si
      where si.id = stock_batches.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );

create policy "stock_movements_insert_staff" on public.stock_movements
  for insert to authenticated
  with check (
    exists (
      select 1 from public.stock_items si
      where si.id = stock_movements.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );

create policy "stock_adjustments_insert_staff" on public.stock_adjustments
  for insert to authenticated
  with check (
    exists (
      select 1 from public.stock_items si
      where si.id = stock_adjustments.stock_item_id
        and public.is_pharmacy_staff(si.pharmacy_id)
    )
  );

-- ==================== LIVRAISON : écriture livreur assigné ====================
-- Rattachement déjà existant via delivery_drivers.user_id — pas besoin de
-- profiles.pharmacy_id ici. Le livreur ne crée ni ne supprime ses livraisons
-- (assignées par l'officine/dispatch, chantier non couvert ici) : seulement
-- mise à jour de statut/position, et insertion de la preuve de livraison.

create policy "deliveries_update_own_driver" on public.deliveries
  for update to authenticated
  using (
    exists (
      select 1 from public.delivery_drivers dd
      where dd.id = deliveries.driver_id and dd.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.delivery_drivers dd
      where dd.id = deliveries.driver_id and dd.user_id = auth.uid()
    )
  );

create policy "delivery_proofs_insert_own_driver" on public.delivery_proofs
  for insert to authenticated
  with check (
    exists (
      select 1 from public.deliveries d
      join public.delivery_drivers dd on dd.id = d.driver_id
      where d.id = delivery_proofs.delivery_id and dd.user_id = auth.uid()
    )
  );

create policy "delivery_drivers_update_own" on public.delivery_drivers
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "delivery_routes_update_own_driver" on public.delivery_routes
  for update to authenticated
  using (
    exists (
      select 1 from public.delivery_drivers dd
      where dd.id = delivery_routes.driver_id and dd.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.delivery_drivers dd
      where dd.id = delivery_routes.driver_id and dd.user_id = auth.uid()
    )
  );

create policy "route_stops_update_own_driver" on public.route_stops
  for update to authenticated
  using (
    exists (
      select 1 from public.delivery_routes r
      join public.delivery_drivers dd on dd.id = r.driver_id
      where r.id = route_stops.route_id and dd.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.delivery_routes r
      join public.delivery_drivers dd on dd.id = r.driver_id
      where r.id = route_stops.route_id and dd.user_id = auth.uid()
    )
  );
