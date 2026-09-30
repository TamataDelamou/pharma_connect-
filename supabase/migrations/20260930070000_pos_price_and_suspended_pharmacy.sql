-- Correctifs C218 (prix de vente imposé par le serveur) et C210 (officine
-- suspendue qui garde ses accès), 30/09/2026.
--
-- C218 — constat : depuis C201, l'écran d'encaissement prend le prix dans
-- stock_items.unit_price, mais pos_create_sale acceptait n'importe quel prix
-- unitaire envoyé par l'application (seule la cohérence des montants était
-- contrôlée). Correctif : pos_create_sale (même signature, corps C201 repris)
-- impose, pour chaque ligne, le prix de vente du stock de l'officine ; un
-- prix de vente nul ou absent est refusé (« prix non renseigné »). Les
-- remises restent possibles au niveau de la vente (C203).
--
-- C210 — constat : is_pharmacy_staff() ne regardait pas le statut de
-- l'officine : le personnel d'une officine suspendue, rejetée ou en cours
-- de révision gardait tous ses accès (stock, ventes, caisse, ordonnances).
-- Correctif : is_pharmacy_staff(), is_any_pharmacy_staff() et
-- has_verified_role('pharmacien') exigent une officine vérifiée ou active
-- (même règle que is_pharmacy_manager, C209). Ces fonctions gardent leur
-- signature : les ~100 policies et fonctions qui les appellent en héritent.
-- L'administration GSG garde ses accès (is_gsg_admin) ; le rattachement
-- (profiles.pharmacy_id) n'est pas modifié : il redevient effectif si
-- l'officine est réactivée.
--
-- Aucune migration existante modifiée.

-- ============================================================
-- C210 : officine vérifiée ou active exigée
-- ============================================================

create or replace function public.is_pharmacy_staff(target_pharmacy_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.profiles pr
      join public.pharmacies ph on ph.id = pr.pharmacy_id
     where pr.id = auth.uid()
       and pr.role = 'pharmacien'
       and pr.pharmacy_id = target_pharmacy_id
       and ph.status in ('verified', 'active')
  );
$$;

comment on function public.is_pharmacy_staff(uuid) is
  'Vrai si l''utilisateur courant est du personnel (rôle pharmacien) rattaché à target_pharmacy_id, et que l''officine est vérifiée ou active (C210 : une officine suspendue, rejetée ou en révision n''ouvre plus aucun accès).';

create or replace function public.is_any_pharmacy_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.profiles pr
      join public.pharmacies ph on ph.id = pr.pharmacy_id
     where pr.id = auth.uid()
       and pr.role = 'pharmacien'
       and ph.status in ('verified', 'active')
  );
$$;

comment on function public.is_any_pharmacy_staff() is
  'Vrai si l''utilisateur courant est du personnel d''une officine vérifiée ou active (C210).';

create or replace function public.has_verified_role(p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = any (p_roles)
      and (
        (p.role = 'pharmacien' and exists (
              select 1 from public.pharmacies ph
              where ph.id = p.pharmacy_id and ph.status in ('verified', 'active')))
        or (p.role = 'professionnel' and exists (
              select 1 from public.professional_profiles pp
              where pp.id = p.id and pp.is_verified = true))
        or (p.role in ('grossiste', 'livreur', 'regulateur') and p.role_verified_at is not null)
      )
  );
$$;

comment on function public.has_verified_role(text[]) is
  'C211 / D58, C210 : vrai si l''utilisateur courant a l''un des rôles demandés ET que ce rôle est vérifié (pharmacien rattaché à une officine vérifiée ou active, professionnel vérifié, grossiste / livreur / régulateur validé par GSG). patient n''est jamais accepté.';

-- ============================================================
-- C218 : prix de vente imposé
-- ============================================================

-- Interne : contrôle du prix d'une ligne de vente.
create or replace function public.pos_check_unit_price(
  p_product_name text,
  p_unit_price integer,
  p_stock_price integer
)
returns void
language plpgsql
immutable
set search_path = public
as $$
begin
  if p_stock_price is null or p_stock_price <= 0 then
    raise exception 'POS: prix de vente non renseigne pour %', p_product_name
      using errcode = '22023';
  end if;
  if p_unit_price is distinct from p_stock_price then
    raise exception 'POS: prix de % incorrect (% au lieu de %)', p_product_name, p_unit_price, p_stock_price
      using errcode = '22023';
  end if;
end;
$$;

comment on function public.pos_check_unit_price(text, integer, integer) is
  'C218 : refuse une ligne de vente dont le prix unitaire n''est pas le prix de vente du stock (stock_items.unit_price), ou dont le prix de vente n''est pas renseigné.';

revoke all on function public.pos_check_unit_price(text, integer, integer) from public, anon, authenticated;

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
  v_stock_price integer;
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
      select si.pharmacy_id, si.product_id, b.expiry_date, si.unit_price
        into v_batch_pharmacy, v_batch_product, v_batch_expiry, v_stock_price
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
  'C197 / C203 / C201 / C218 : vente POS complète en une transaction (vente, lignes, mouvements de stock via stock_apply_movement, reçu). Caissier = auth.uid(). Ligne avec produit sans lot : lots choisis par le serveur (péremption la plus proche, périmés et réservés exclus, une ligne par lot). Ligne avec lot : lot de l''officine, non périmé, du même produit. Chaque ligne désigne un produit ou un lot. Prix unitaire imposé : celui du stock de l''officine (stock_items.unit_price), prix nul refusé. Ordonnance tracée par ligne (prescription_required / prescription_checked), non bloquante. Toute erreur annule l''ensemble.';

revoke all on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) from public, anon;
grant execute on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) to authenticated;
