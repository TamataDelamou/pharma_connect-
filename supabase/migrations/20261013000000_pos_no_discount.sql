-- C262 : remise bloquée au comptoir.
--
-- Constat (essai « release » des 12 et 13/10/2026) : la réglette de remise de
-- l'écran de vente, continue de 0 à 100 %, était déplacée par erreur en
-- faisant défiler l'écran ; une vente a été encaissée 1 541 GNF au lieu de
-- 1 575. Le serveur acceptait toute remise jusqu'au montant total.
--
-- Décision d'Achille du 13/10/2026 : remise bloquée par défaut. L'écran ne
-- la propose plus, et le serveur refuse toute vente dont la remise n'est pas
-- nulle. La remise exceptionnelle validée par un responsable est une
-- évolution à part (FEAT-005).
--
-- Cette migration recrée pos_create_sale (même signature, corps de
-- 20261004020000_server_side_reservation.sql repris tel quel) avec un seul
-- changement : le contrôle « remise supérieure au total » devient « remise
-- non nulle refusée ». La remise par ligne était déjà refusée. Le retrait
-- d'une réservation (reservation_pickup) passe une remise à 0 : il n'est pas
-- touché. Aucune migration existante n'est modifiée.

CREATE OR REPLACE FUNCTION public.pos_create_sale(p_pharmacy_id uuid, p_payment_method text, p_total_amount integer, p_discount_amount integer, p_tax_amount integer, p_final_amount integer, p_items jsonb, p_patient_id uuid DEFAULT NULL::uuid, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_batch_number text;
  v_product_id uuid;
  v_product_name text;
  v_product_label text;
  v_stock_item_id uuid;
  v_stock_price integer;
  v_session_id uuid;
  v_rx_required boolean;
  v_rx_checked boolean;
  v_remaining integer;
  v_take integer;
  v_available integer;
  v_recall text;
  v_recalled_units integer;
  v_batch_qty integer;
  v_batch_held integer;
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

  -- C262 : remise bloquée. Toute vente avec une remise non nulle est refusée
  -- (p_discount_amount est déjà contrôlé non négatif ci-dessus).
  if p_discount_amount <> 0 then
    raise exception 'POS: remise non autorisee (remise %)', p_discount_amount
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

  -- C205 / D62 : session de caisse ouverte du vendeur dans cette officine ;
  -- obligatoire pour une vente en espèces.
  select id into v_session_id
    from public.cash_drawer_sessions
    where pharmacy_id = p_pharmacy_id and cashier_id = v_user_id and status = 'open'
    order by opened_at desc
    limit 1;
  if p_payment_method = 'cash' and v_session_id is null then
    raise exception 'POS: ouvrez votre caisse avant une vente en especes' using errcode = '22023';
  end if;

  -- Caissier, auteur et statut fixés par le serveur, jamais par le client.
  insert into public.pos_sales (
    pharmacy_id, patient_id, cashier_id, total_amount, discount_amount,
    tax_amount, final_amount, payment_method, status, notes,
    created_by, updated_by, cash_drawer_session_id
  ) values (
    p_pharmacy_id, p_patient_id, v_user_id, p_total_amount, p_discount_amount,
    p_tax_amount, p_final_amount, p_payment_method, 'completed', p_notes,
    v_user_id, v_user_id, v_session_id
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
      select si.pharmacy_id, si.product_id, b.expiry_date, si.unit_price, b.batch_number,
             b.quantity
        into v_batch_pharmacy, v_batch_product, v_batch_expiry, v_stock_price, v_batch_number,
             v_batch_qty
        from public.stock_batches b
        join public.stock_items si on si.id = b.stock_item_id
        where b.id = v_batch_id
        -- C243 : lot verrouillé, le contrôle des boîtes retenues est fiable.
        for update of b;
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
           btrim(p.name || ' ' || coalesce(p.dosage, '')),
           p.is_prescription_required or p.regulatory_class in ('stupefiant', 'psychotrope')
      into v_product_name, v_product_label, v_rx_required
      from public.products p where p.id = v_product_id;
    if not found then
      raise exception 'POS: produit % inconnu', v_product_id using errcode = '22023';
    end if;
    v_product_name := coalesce(nullif(v_item->>'product_name', ''), v_product_name);

    if v_batch_id is not null then
      -- C240 : un lot rappelé n'est pas vendable.
      v_recall := public.stock_batch_recall(v_batch_id);
      if v_recall is not null then
        raise exception 'POS: vente impossible : le lot % de % est rappele (%). Retirez ce lot de la vente.',
          v_batch_number, v_product_label, v_recall
          using errcode = '22023';
      end if;
      -- C243 : les boîtes retenues par une réservation (reservation_item_batches)
      -- ne sont pas vendables au comptoir. Un lot sans assez de stock du tout
      -- garde le refus habituel de stock_apply_movement, plus bas.
      select coalesce(sum(h.quantity), 0)::integer into v_batch_held
        from public.reservation_item_batches h
        where h.batch_id = v_batch_id and h.released_at is null;
      if v_batch_held > 0 and v_qty <= v_batch_qty and v_qty > v_batch_qty - v_batch_held then
        raise exception 'POS: stock insuffisant pour % sur le lot % (demande %, disponible % hors boites reservees)',
          v_product_name, v_batch_number, v_qty, greatest(v_batch_qty - v_batch_held, 0)
          using errcode = 'P0001';
      end if;
      perform public.pos_check_unit_price(v_product_name, v_unit, v_stock_price);
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
    select id, unit_price into v_stock_item_id, v_stock_price
      from public.stock_items
      where pharmacy_id = p_pharmacy_id and product_id = v_product_id;
    if not found then
      raise exception 'POS: % absent du stock de cette officine', v_product_name
        using errcode = '22023';
    end if;
    perform public.pos_check_unit_price(v_product_name, v_unit, v_stock_price);

    v_remaining := v_qty;
    for v_lot in
      select b.id, greatest(b.quantity - b.quantity_reserved, 0) as available
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id
          and b.expiry_date >= v_today
          and b.quantity - b.quantity_reserved > 0
          -- C240 : lots rappelés écartés, comme les lots périmés.
          and public.stock_batch_recall(b.id) is null
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
      select coalesce(sum(greatest(b.quantity - b.quantity_reserved, 0))
                        filter (where public.stock_batch_recall(b.id) is null), 0)::integer,
             coalesce(sum(greatest(b.quantity - b.quantity_reserved, 0))
                        filter (where public.stock_batch_recall(b.id) is not null), 0)::integer
        into v_available, v_recalled_units
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id and b.expiry_date >= v_today;
      -- Les lots déjà décrémentés pour cette ligne sont comptés après sortie :
      -- on rapporte ce qui était vendable avant la ligne.
      if v_recalled_units > 0 then
        -- C240 : le caissier doit savoir qu'un lot rappelé est en rayon.
        raise exception 'POS: stock insuffisant pour % (demande %, disponible %) ; % unite(s) en lot rappele, a retirer de la vente',
          v_product_name, v_qty, v_available + (v_qty - v_remaining), v_recalled_units
          using errcode = 'P0001';
      end if;
      raise exception 'POS: stock insuffisant pour % (demande %, disponible %)',
        v_product_name, v_qty, v_available + (v_qty - v_remaining)
        using errcode = 'P0001';
    end if;
  end loop;

  insert into public.pos_receipts (sale_id, printed_at, printed_by)
  values (v_sale_id, now(), v_user_id);

  -- C205 / D62 : encaissement enregistré dans la session du vendeur (espèces :
  -- compté dans le solde attendu ; autres moyens : tracés à part).
  if v_session_id is not null then
    insert into public.cash_movements (
      cash_drawer_session_id, type, amount, payment_method,
      reference_id, reference_type, notes, created_by
    ) values (
      v_session_id, 'sale', p_final_amount, p_payment_method,
      v_sale_id::text, 'pos_sale', 'Vente POS', v_user_id
    );
  end if;

  return v_sale_id;
end;
$function$;

comment on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) is
  'C197 / C203 / C201 / C218 / C205 / C240 / C243 / C262 : vente POS complète en une transaction (vente, lignes, mouvements de stock, reçu). Lots choisis par le serveur, prix du stock imposé, ordonnance tracée. C205 / D62 : vente en espèces seulement avec une caisse ouverte du vendeur. C240 : lot rappelé refusé ou écarté. C243 : un lot désigné n''est vendable que hors boîtes retenues par une réservation. C262 : toute remise non nulle est refusée.';
