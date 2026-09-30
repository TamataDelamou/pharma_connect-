-- Correctif C201 : vente au comptoir sur le vrai stock de l'officine
-- (décision D60, 30/09/2026).
--
-- Constat : l'écran d'encaissement vendait un catalogue fictif (7 produits
-- codés en dur, sans lot) ; aucune vente réelle n'était possible, et une
-- ligne sans lot n'aurait de toute façon décrémenté aucun stock.
--
-- Décision D60 :
--   1. Le caissier choisit le produit et la quantité ; le serveur choisit les
--      lots : péremption la plus proche d'abord (FEFO), lots périmés exclus,
--      quantité réservée non vendable, répartition sur plusieurs lots si
--      besoin (une ligne de vente par lot).
--   2. Médicament sur ordonnance (products.is_prescription_required, ou
--      classe stupéfiant / psychotrope) : l'application avertit et demande au
--      pharmacien de confirmer qu'il a vu l'ordonnance ; la vente n'est pas
--      bloquée, mais le produit concerné et la confirmation sont enregistrés
--      sur chaque ligne (prescription_required, prescription_checked).
--
-- Ce fichier :
--   - ajoute pos_sale_items.prescription_required / prescription_checked ;
--   - recrée public.pos_create_sale (même signature, corps C203 repris) :
--       * une ligne doit désormais porter un produit ou un lot (les lignes
--         « catalogue » sans produit ni lot sont refusées) ;
--       * ligne avec produit sans lot : allocation FEFO par le serveur ;
--       * ligne avec lot (comportement C197 / C203 conservé) : lot périmé
--         refusé ;
--   - ajoute public.pos_search_stock_products() pour l'écran d'encaissement.
--
-- Non traité ici (ticket à part) : le prix unitaire reste celui envoyé par
-- l'application (lu dans stock_items.unit_price par l'écran) ; le serveur ne
-- l'impose pas encore.
--
-- Aucune migration existante modifiée.

-- ==================== Traçabilité ordonnance ====================

alter table public.pos_sale_items
  add column prescription_required boolean not null default false,
  add column prescription_checked boolean not null default false;

comment on column public.pos_sale_items.prescription_required is
  'C201 / D60 : produit sur ordonnance au moment de la vente (is_prescription_required, stupéfiant ou psychotrope).';
comment on column public.pos_sale_items.prescription_checked is
  'C201 / D60 : le vendeur a confirmé avoir vu l''ordonnance (avertissement non bloquant).';

-- ==================== Vente ====================

create or replace function public.pos_create_sale(
  p_pharmacy_id uuid,
  p_payment_method text,
  p_total_amount integer,
  p_discount_amount integer,
  p_tax_amount integer,
  p_final_amount integer,
  p_items jsonb,
  p_patient_id uuid default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_sale_id uuid;
  v_item jsonb;
  v_qty integer;
  v_unit integer;
  v_line integer;
  v_sum integer := 0;
  v_batch_id uuid;
  v_batch_pharmacy uuid;
  v_batch_product uuid;
  v_batch_expiry date;
  v_product_id uuid;
  v_product_name text;
  v_stock_item_id uuid;
  v_rx_required boolean;
  v_rx_checked boolean;
  v_remaining integer;
  v_take integer;
  v_available integer;
  v_lot record;
begin
  if v_user_id is null or not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'POS: une vente doit contenir au moins une ligne' using errcode = '22023';
  end if;

  if p_total_amount < 0 or p_discount_amount < 0 or p_tax_amount < 0 or p_final_amount < 0 then
    raise exception 'POS: montant negatif' using errcode = '22023';
  end if;

  if p_discount_amount > p_total_amount then
    raise exception 'POS: remise % superieure au total %', p_discount_amount, p_total_amount
      using errcode = '22023';
  end if;

  -- Le client arrondit total, remise et TVA séparément (pos_provider.dart) :
  -- écart d'au plus 1 avec final = total - remise + TVA.
  if abs(p_final_amount - (p_total_amount - p_discount_amount + p_tax_amount)) > 1 then
    raise exception 'POS: montant final % incoherent (attendu % a 1 pres)',
      p_final_amount, p_total_amount - p_discount_amount + p_tax_amount
      using errcode = '22023';
  end if;

  -- Contrôle de cohérence des lignes avant toute écriture.
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty  := (v_item->>'quantity')::integer;
    v_unit := (v_item->>'unit_price')::integer;
    v_line := (v_item->>'total_price')::integer;
    if v_qty is null or v_qty <= 0 or v_unit is null or v_unit < 0
       or v_line is distinct from v_qty * v_unit then
      raise exception 'POS: ligne incoherente (quantite %, prix %, total %)', v_qty, v_unit, v_line
        using errcode = '22023';
    end if;
    -- Remise par ligne non gérée : total_price = quantité × prix unitaire.
    if coalesce((v_item->>'discount_percentage')::numeric, 0) <> 0 then
      raise exception 'POS: remise par ligne non prise en charge' using errcode = '22023';
    end if;
    -- C201 : plus de ligne « catalogue » sans produit ni lot.
    if nullif(v_item->>'product_id', '') is null and nullif(v_item->>'batch_id', '') is null then
      raise exception 'POS: chaque ligne doit designer un produit du stock' using errcode = '22023';
    end if;
    v_sum := v_sum + v_line;
  end loop;

  if v_sum <> p_total_amount then
    raise exception 'POS: total % different de la somme des lignes %', p_total_amount, v_sum
      using errcode = '22023';
  end if;

  -- Caissier, auteur et statut fixés par le serveur, jamais par le client.
  insert into public.pos_sales (
    pharmacy_id, patient_id, cashier_id, total_amount, discount_amount,
    tax_amount, final_amount, payment_method, status, notes,
    created_by, updated_by
  ) values (
    p_pharmacy_id, p_patient_id, v_user_id, p_total_amount, p_discount_amount,
    p_tax_amount, p_final_amount, p_payment_method, 'completed', p_notes,
    v_user_id, v_user_id
  )
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_batch_id   := nullif(v_item->>'batch_id', '')::uuid;
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_qty        := (v_item->>'quantity')::integer;
    v_unit       := (v_item->>'unit_price')::integer;
    v_rx_checked := coalesce((v_item->>'prescription_checked')::boolean, false);

    if v_batch_id is not null then
      -- Lot désigné (comportement C197 / C203).
      select si.pharmacy_id, si.product_id, b.expiry_date
        into v_batch_pharmacy, v_batch_product, v_batch_expiry
        from public.stock_batches b
        join public.stock_items si on si.id = b.stock_item_id
        where b.id = v_batch_id;
      if not found then
        raise exception 'POS: lot % introuvable', v_batch_id using errcode = '22023';
      end if;
      if v_batch_pharmacy is distinct from p_pharmacy_id then
        raise exception 'POS: le lot % n''appartient pas a cette officine', v_batch_id
          using errcode = '42501';
      end if;
      if v_product_id is not null and v_product_id <> v_batch_product then
        raise exception 'POS: le lot % ne correspond pas au produit %', v_batch_id, v_product_id
          using errcode = '22023';
      end if;
      if v_batch_expiry < v_today then
        raise exception 'POS: le lot % est perime (%)', v_batch_id, v_batch_expiry
          using errcode = '22023';
      end if;
      v_product_id := v_batch_product;
    end if;

    select p.name,
           p.is_prescription_required or p.regulatory_class in ('stupefiant', 'psychotrope')
      into v_product_name, v_rx_required
      from public.products p where p.id = v_product_id;
    if not found then
      raise exception 'POS: produit % inconnu', v_product_id using errcode = '22023';
    end if;
    v_product_name := coalesce(nullif(v_item->>'product_name', ''), v_product_name);

    if v_batch_id is not null then
      insert into public.pos_sale_items (
        sale_id, product_id, product_name, quantity, unit_price, total_price,
        batch_id, discount_percentage, notes, prescription_required, prescription_checked
      ) values (
        v_sale_id, v_product_id, v_product_name, v_qty, v_unit, v_qty * v_unit,
        v_batch_id, 0, v_item->>'notes', v_rx_required, v_rx_checked
      );
      perform public.stock_apply_movement(
        v_batch_id, -v_qty, 'sale', v_sale_id::text, 'Vente POS'
      );
      continue;
    end if;

    -- C201 : produit sans lot désigné → allocation FEFO par le serveur.
    select id into v_stock_item_id
      from public.stock_items
      where pharmacy_id = p_pharmacy_id and product_id = v_product_id;
    if not found then
      raise exception 'POS: % absent du stock de cette officine', v_product_name
        using errcode = '22023';
    end if;

    v_remaining := v_qty;
    for v_lot in
      select b.id, greatest(b.quantity - b.quantity_reserved, 0) as available
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id
          and b.expiry_date >= v_today
          and b.quantity - b.quantity_reserved > 0
        order by b.expiry_date, b.received_at nulls last, b.id
        for update of b
    loop
      exit when v_remaining = 0;
      v_take := least(v_remaining, v_lot.available);
      insert into public.pos_sale_items (
        sale_id, product_id, product_name, quantity, unit_price, total_price,
        batch_id, discount_percentage, notes, prescription_required, prescription_checked
      ) values (
        v_sale_id, v_product_id, v_product_name, v_take, v_unit, v_take * v_unit,
        v_lot.id, 0, v_item->>'notes', v_rx_required, v_rx_checked
      );
      perform public.stock_apply_movement(
        v_lot.id, -v_take, 'sale', v_sale_id::text, 'Vente POS'
      );
      v_remaining := v_remaining - v_take;
    end loop;

    if v_remaining > 0 then
      select coalesce(sum(greatest(b.quantity - b.quantity_reserved, 0)), 0)::integer
        into v_available
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id and b.expiry_date >= v_today;
      -- Les lots déjà décrémentés pour cette ligne sont comptés après sortie :
      -- on rapporte ce qui était vendable avant la ligne.
      raise exception 'POS: stock insuffisant pour % (demande %, disponible %)',
        v_product_name, v_qty, v_available + (v_qty - v_remaining)
        using errcode = 'P0001';
    end if;
  end loop;

  insert into public.pos_receipts (sale_id, printed_at, printed_by)
  values (v_sale_id, now(), v_user_id);

  return v_sale_id;
end;
$$;

comment on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) is
  'C197 / C203 / C201 : vente POS complète en une transaction (vente, lignes, mouvements de stock via stock_apply_movement, reçu). Caissier = auth.uid(). Ligne avec produit sans lot : lots choisis par le serveur (péremption la plus proche, périmés et réservés exclus, une ligne par lot). Ligne avec lot : lot de l''officine, non périmé, du même produit. Chaque ligne désigne un produit ou un lot. Ordonnance tracée par ligne (prescription_required / prescription_checked), non bloquante. Toute erreur annule l''ensemble.';

revoke all on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) from public, anon;
grant execute on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) to authenticated;

-- ==================== Recherche en stock ====================

create or replace function public.pos_search_stock_products(
  p_pharmacy_id uuid,
  p_query text default null,
  p_limit integer default 30
)
returns table (
  product_id uuid,
  product_name text,
  generic_name text,
  dosage text,
  form text,
  unit_price integer,
  available_quantity integer,
  nearest_expiry date,
  prescription_required boolean,
  regulatory_class text
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_query text := nullif(btrim(p_query), '');
begin
  if auth.uid() is null or not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;

  return query
  select p.id, p.name, p.generic_name, p.dosage, p.form, si.unit_price,
         coalesce(lots.available, 0)::integer,
         lots.nearest_expiry,
         p.is_prescription_required or p.regulatory_class in ('stupefiant', 'psychotrope'),
         p.regulatory_class
    from public.stock_items si
    join public.products p on p.id = si.product_id
    left join lateral (
      select sum(greatest(b.quantity - b.quantity_reserved, 0)) as available,
             min(b.expiry_date) filter (where b.quantity - b.quantity_reserved > 0) as nearest_expiry
        from public.stock_batches b
        where b.stock_item_id = si.id and b.expiry_date >= v_today
    ) lots on true
    where si.pharmacy_id = p_pharmacy_id
      and si.status <> 'discontinued'
      and (v_query is null
           or p.name ilike '%' || v_query || '%'
           or p.generic_name ilike '%' || v_query || '%')
    order by (coalesce(lots.available, 0) > 0) desc, p.name
    limit greatest(least(coalesce(p_limit, 30), 100), 1);
end;
$$;

comment on function public.pos_search_stock_products(uuid, text, integer) is
  'C201 / D60 : produits du stock de l''officine pour l''écran d''encaissement : prix (stock_items.unit_price), quantité vendable (lots non périmés, hors réservé), péremption la plus proche, produit sur ordonnance. Réservée au personnel de l''officine.';

revoke all on function public.pos_search_stock_products(uuid, text, integer) from public, anon;
grant execute on function public.pos_search_stock_products(uuid, text, integer) to authenticated;
