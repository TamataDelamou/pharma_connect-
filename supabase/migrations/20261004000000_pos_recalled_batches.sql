-- C240 : un lot rappelé ne doit plus pouvoir être vendu.
--
-- Constat : pos_create_sale (20260930080000_cash_linked_to_sales.sql)
-- n'écarte que les lots périmés. Ni la vente à lot désigné, ni le choix des
-- lots par le serveur, ni la recherche de l'écran d'encaissement
-- (pos_search_stock_products), ni la remise en stock d'un remboursement
-- (pos_refund_sale) ne consultent un rappel.
--
-- Trois sources de rappel coexistent, aucune reliée au stock de l'officine :
--   - recalls + recall_affected_batches (module rappels) ;
--   - product_recalls (module régulateur) ;
--   - traceable_batches.is_recalled (traçabilité).
-- Toutes désignent un lot par son numéro ; le produit est facultatif dans
-- les deux premières. Le rapprochement avec stock_batches se fait donc par
-- produit et numéro de lot (casse et espaces ignorés) ; un rappel sans
-- produit renseigné s'applique sur le seul numéro de lot (décision d'Achille
-- du 04/10/2026 : refus plus sûr, au prix de rares faux refus).
--
-- Rappels pris en compte : en cours et terminés (un lot rappelé encore en
-- rayon reste rappelé). Ignorés : brouillons et annulés.
--
-- Cette migration :
--   - ajoute recall_norm_batch() et stock_batch_recall() (rapprochement
--     unique, réutilisé plus tard par la synchronisation hors ligne et C242) ;
--   - recrée pos_create_sale (même signature, corps C205 repris) : lot
--     désigné rappelé refusé ; lots rappelés écartés du choix du serveur ;
--   - recrée pos_search_stock_products (même signature) : lots rappelés hors
--     du disponible ;
--   - recrée pos_refund_sale (même signature, corps C205 repris) : un lot
--     rappelé ne peut plus être remis en stock, quarantaine imposée.
-- Aucune migration existante n'est modifiée.

-- ============================================================
-- Rapprochement lot de stock <-> rappel
-- ============================================================

create or replace function public.recall_norm_batch(p_batch_number text)
returns text
language sql
immutable
set search_path = public
as $$
  select upper(regexp_replace(coalesce(p_batch_number, ''), '\s+', '', 'g'))
$$;

comment on function public.recall_norm_batch(text) is
  'C240 : numéro de lot normalisé pour le rapprochement avec un rappel (majuscules, sans espaces).';

create index if not exists idx_recall_affected_batches_norm_batch
  on public.recall_affected_batches (public.recall_norm_batch(batch_number));
create index if not exists idx_product_recalls_norm_batch
  on public.product_recalls (public.recall_norm_batch(batch_number));
create index if not exists idx_traceable_batches_recalled_norm_batch
  on public.traceable_batches (public.recall_norm_batch(batch_number))
  where is_recalled;

create or replace function public.stock_batch_recall(p_batch_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with lot as (
    select si.product_id, public.recall_norm_batch(b.batch_number) as num
      from public.stock_batches b
      join public.stock_items si on si.id = b.stock_item_id
      where b.id = p_batch_id
  )
  select found.label
    from lot
    cross join lateral (
      -- Module rappels : rappel en cours ou terminé, ligne non annulée.
      select 'rappel ' || r.reference_number as label, 1 as ord, r.issued_at as at
        from public.recall_affected_batches rab
        join public.recalls r on r.id = rab.recall_id
        where r.status in ('inProgress', 'completed')
          and rab.status <> 'cancelled'
          and public.recall_norm_batch(rab.batch_number) = lot.num
          and (rab.product_id is null or rab.product_id = lot.product_id)
      union all
      -- Module régulateur : rappel publié, en cours ou terminé.
      select 'rappel du regulateur du ' || to_char(pr.announcement_date at time zone 'Africa/Conakry', 'DD/MM/YYYY'),
             2, pr.announcement_date
        from public.product_recalls pr
        where pr.status in ('published', 'in_progress', 'completed')
          and public.recall_norm_batch(pr.batch_number) = lot.num
          and (pr.product_id is null or pr.product_id = lot.product_id)
      union all
      -- Traçabilité : unité du même lot marquée rappelée.
      select 'rappel signale en tracabilite', 3, tb.recalled_at
        from public.traceable_batches tb
        where tb.is_recalled
          and public.recall_norm_batch(tb.batch_number) = lot.num
          and (tb.product_id is null or tb.product_id = lot.product_id)
    ) found
    where lot.num <> ''
    order by found.ord, found.at desc nulls last
    limit 1
$$;

comment on function public.stock_batch_recall(uuid) is
  'C240 : libellé du rappel qui vise un lot de stock (produit et numéro de lot, casse et espaces ignorés ; rappel sans produit : numéro de lot seul), null si le lot n''est pas rappelé. Sources : recalls (en cours, terminé), product_recalls (publié, en cours, terminé), traceable_batches.is_recalled. Contrôle interne, non appelable par les clients.';

revoke all on function public.stock_batch_recall(uuid) from public, anon, authenticated;

-- ============================================================
-- Vente : lot rappelé refusé ou écarté
-- ============================================================

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
      select si.pharmacy_id, si.product_id, b.expiry_date, si.unit_price, b.batch_number
        into v_batch_pharmacy, v_batch_product, v_batch_expiry, v_stock_price, v_batch_number
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
  'C197 / C203 / C201 / C218 / C205 / C240 : vente POS complète en une transaction (vente, lignes, mouvements de stock, reçu). Lots choisis par le serveur, prix du stock imposé, ordonnance tracée. C205 / D62 : vente en espèces seulement avec une caisse ouverte du vendeur ; encaissement enregistré dans sa session. C240 : un lot rappelé est refusé (lot désigné) ou écarté (lots choisis par le serveur).';

-- ============================================================
-- Recherche de l'écran d'encaissement : lots rappelés hors du disponible
-- ============================================================

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
          -- C240 : lots rappelés hors du disponible.
          and public.stock_batch_recall(b.id) is null
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
  'C201 / D60 / C240 : produits du stock de l''officine pour l''écran d''encaissement : prix (stock_items.unit_price), quantité vendable (lots non périmés, non rappelés, hors réservé), péremption la plus proche, produit sur ordonnance. Réservée au personnel de l''officine.';

-- ============================================================
-- Remboursement : pas de remise en stock d'un lot rappelé
-- ============================================================

CREATE OR REPLACE FUNCTION public.pos_refund_sale(p_sale_id uuid, p_reason text, p_disposition text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_pharmacy_id uuid;
  v_status text;
  v_final integer;
  v_created_at timestamptz;
  v_is_manager boolean;
  v_limit integer;
  v_reason text := nullif(btrim(p_reason), '');
  v_item record;
  v_payment text;
  v_session_id uuid;
  v_recalled record;
begin
  -- Verrou sur la vente : deux remboursements simultanés se sérialisent.
  select pharmacy_id, status, final_amount, created_at, payment_method
    into v_pharmacy_id, v_status, v_final, v_created_at, v_payment
    from public.pos_sales
    where id = p_sale_id
    for update;
  if not found then
    raise exception 'POS: vente % introuvable', p_sale_id using errcode = 'P0002';
  end if;

  select (p.manager_id = v_user_id), p.pos_refund_staff_limit
    into v_is_manager, v_limit
    from public.pharmacies p where p.id = v_pharmacy_id;
  v_is_manager := coalesce(v_is_manager, false);

  -- Accès : personnel de l'officine uniquement (le titulaire y est rattaché
  -- par C208) ; le statut de titulaire ne lève que la règle jour/plafond.
  if v_user_id is null or not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;
  if v_status is distinct from 'completed' then
    raise exception 'POS: seule une vente completee peut etre remboursee (statut %)', v_status
      using errcode = '22023';
  end if;
  if v_reason is null or char_length(v_reason) < 3 then
    raise exception 'POS: motif du remboursement obligatoire' using errcode = '22023';
  end if;
  if p_disposition is null or p_disposition not in ('restock', 'quarantine') then
    raise exception 'POS: destination du stock a preciser (restock ou quarantine)'
      using errcode = '22023';
  end if;

  -- Règle C204 : hors titulaire, le jour même et sous le plafond de l'officine.
  -- Jour calendaire en heure de Conakry (UTC+0) ; à paramétrer par officine
  -- le jour où PharmaConnect sort de Guinée.
  if not v_is_manager then
    if (v_created_at at time zone 'Africa/Conakry')::date
         <> (now() at time zone 'Africa/Conakry')::date then
      raise exception 'POS: remboursement reserve au titulaire (vente d''un jour precedent)'
        using errcode = '42501';
    end if;
    if v_final > v_limit then
      raise exception 'POS: remboursement reserve au titulaire (montant % superieur au plafond %)',
        v_final, v_limit using errcode = '42501';
    end if;
  end if;

  -- C240 : un lot rappelé ne retourne pas en stock vendable ; la quarantaine
  -- est imposée.
  if p_disposition = 'restock' then
    select b.batch_number,
           btrim(coalesce(p.name, si.product_name) || ' ' || coalesce(p.dosage, '')) as product_label,
           public.stock_batch_recall(si.batch_id) as recall
      into v_recalled
      from public.pos_sale_items si
      join public.stock_batches b on b.id = si.batch_id
      left join public.products p on p.id = si.product_id
      where si.sale_id = p_sale_id
        and si.batch_id is not null
        and public.stock_batch_recall(si.batch_id) is not null
      order by si.id
      limit 1;
    if found then
      raise exception 'POS: le lot % de % est rappele (%) : remise en stock impossible, choisissez la quarantaine',
        v_recalled.batch_number, v_recalled.product_label, v_recalled.recall
        using errcode = '22023';
    end if;
  end if;

  -- C205 / D62 : remboursement dans le moyen d'origine ; en espèces, il sort
  -- de la caisse ouverte de la personne qui rembourse (obligatoire).
  select id into v_session_id
    from public.cash_drawer_sessions
    where pharmacy_id = v_pharmacy_id and cashier_id = v_user_id and status = 'open'
    order by opened_at desc
    limit 1;
  if v_payment = 'cash' and v_session_id is null then
    raise exception 'POS: ouvrez votre caisse pour rembourser en especes' using errcode = '22023';
  end if;

  -- updated_at est géré par trigger_pos_sales_updated_at.
  update public.pos_sales
    set status = 'refunded',
        refunded_at = now(),
        refunded_by = v_user_id,
        refund_reason = v_reason,
        refund_stock_disposition = p_disposition,
        updated_by = v_user_id
    where id = p_sale_id;

  for v_item in
    select si.id, si.batch_id, si.product_id, si.product_name, si.quantity
      from public.pos_sale_items si
      where si.sale_id = p_sale_id and si.batch_id is not null
  loop
    if p_disposition = 'restock' then
      perform public.stock_apply_movement(
        v_item.batch_id, v_item.quantity, 'adjustment',
        p_sale_id::text, 'Remboursement vente POS : remise en stock'
      );
    else
      insert into public.pos_refund_quarantine (
        pharmacy_id, sale_id, sale_item_id, batch_id, product_id,
        product_name, quantity, reason, created_by
      ) values (
        v_pharmacy_id, p_sale_id, v_item.id, v_item.batch_id, v_item.product_id,
        v_item.product_name, v_item.quantity, v_reason, v_user_id
      );
    end if;
  end loop;

  if v_session_id is not null then
    insert into public.cash_movements (
      cash_drawer_session_id, type, amount, payment_method,
      reference_id, reference_type, notes, created_by
    ) values (
      v_session_id, 'refund', v_final, v_payment,
      p_sale_id::text, 'pos_sale', 'Remboursement vente POS', v_user_id
    );
  end if;
end;
$function$;

comment on function public.pos_refund_sale(uuid, text, text) is
  'C197 / C204 / C205 / C240 : remboursement POS complet en une transaction. Règle C204 (jour même et plafond hors titulaire, motif, remise en stock ou quarantaine). C205 / D62 : remboursement dans le moyen d''origine ; en espèces, caisse ouverte obligatoire. C240 : un lot rappelé ne peut pas être remis en stock, quarantaine imposée.';
