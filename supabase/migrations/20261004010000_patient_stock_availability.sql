-- C242 : la disponibilité montrée aux patients ne doit plus compter les lots
-- rappelés.
--
-- Constat : la recherche de disponibilité (search_service.dart), la fiche
-- produit et le contrôle fait à la réservation (StockService.reserveStock)
-- lisent stock_items.total_quantity - reserved_quantity, un total par
-- officine qui compte tous les lots, rappelés et périmés compris. Un patient
-- peut donc voir « disponible » et réserver un produit dont le seul stock est
-- un lot que C240 refuse ensuite à la vente. Le patient ne lit pas
-- stock_batches (réservé au personnel, 20260829015000) : le calcul par lot ne
-- peut se faire que côté serveur.
--
-- Cette migration ajoute une seule fonction, en lecture :
-- patient_stock_availability(produits, officine facultative), qui rend par
-- officine active la quantité réellement vendable : lots non périmés, non
-- rappelés (stock_batch_recall, C240), hors quantité réservée. Même règle que
-- pos_search_stock_products pour l'écran d'encaissement.
-- Aucune migration existante n'est modifiée ; aucune table, policy ni
-- fonction existante n'est touchée.

create or replace function public.patient_stock_availability(
  p_product_ids uuid[],
  p_pharmacy_id uuid default null
)
returns table (
  product_id uuid,
  pharmacy_id uuid,
  available_quantity integer,
  unit_price integer,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_today date := (now() at time zone 'Africa/Conakry')::date;
begin
  if auth.uid() is null then
    raise exception 'STK: connexion requise' using errcode = '42501';
  end if;

  return query
  select si.product_id, si.pharmacy_id,
         coalesce(lots.available, 0)::integer,
         si.unit_price,
         si.updated_at
    from public.stock_items si
    -- RG-AUT-04 : seules les officines actives sont montrées aux patients.
    join public.pharmacies ph on ph.id = si.pharmacy_id and ph.status = 'active'
    left join lateral (
      select sum(greatest(b.quantity - b.quantity_reserved, 0)) as available
        from public.stock_batches b
        where b.stock_item_id = si.id
          and b.expiry_date >= v_today
          and public.stock_batch_recall(b.id) is null
    ) lots on true
    where si.product_id = any(coalesce(p_product_ids, '{}'::uuid[]))
      and (p_pharmacy_id is null or si.pharmacy_id = p_pharmacy_id)
      and si.status <> 'discontinued';
end;
$$;

comment on function public.patient_stock_availability(uuid[], uuid) is
  'C242 : disponibilité montrée aux patients (recherche, fiche produit, contrôle à la réservation) : par officine active, quantité vendable d''un produit (lots non périmés, non rappelés au sens de C240, hors réservé), prix et date de mise à jour. Lecture seule ; ne révèle ni lot ni rappel. Utilisateurs connectés seulement.';

revoke all on function public.patient_stock_availability(uuid[], uuid) from public, anon;
grant execute on function public.patient_stock_availability(uuid[], uuid) to authenticated;
