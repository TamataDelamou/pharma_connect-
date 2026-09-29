-- Correctif C203 : controles manquants dans public.pos_create_sale (C197,
-- 20260929010000_pos_atomic_sale_refund.sql).
--
-- Corps recopie integralement depuis C197, meme signature (sinon une
-- surcharge serait creee), avec trois controles ajoutes :
--   1. Montants : remise <= total, et montant final coherent avec
--      total - remise + TVA a 1 pres (le client arrondit chaque montant
--      separement, pos_provider.dart).
--   2. Remise par ligne : toute valeur non nulle de discount_percentage est
--      refusee (total_price = quantite x prix unitaire ; aucun ecran ne la
--      renseigne, a concevoir avant de l'autoriser).
--   3. Lot et produit : le produit de la ligne doit etre celui du lot
--      (stock_items.product_id) ; absent, il est pris sur le lot. Un lot
--      inexistant est refuse avec un message explicite (« lot introuvable »)
--      au lieu de « n'appartient pas a cette officine ».
--
-- public.pos_refund_sale n'est pas modifiee. Aucune migration existante
-- modifiee.

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
  v_sale_id uuid;
  v_item jsonb;
  v_qty integer;
  v_unit integer;
  v_line integer;
  v_sum integer := 0;
  v_batch_id uuid;
  v_batch_pharmacy uuid;
  v_batch_product uuid;
  v_product_id uuid;
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
    -- Aucun écran ne la renseigne ; à concevoir avant de l'autoriser.
    if coalesce((v_item->>'discount_percentage')::numeric, 0) <> 0 then
      raise exception 'POS: remise par ligne non prise en charge' using errcode = '22023';
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

    if v_batch_id is not null then
      select si.pharmacy_id, si.product_id into v_batch_pharmacy, v_batch_product
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
      -- Le produit de la ligne est celui du lot : fourni et différent → refus ;
      -- absent → pris sur le lot.
      if v_product_id is not null and v_product_id <> v_batch_product then
        raise exception 'POS: le lot % ne correspond pas au produit %', v_batch_id, v_product_id
          using errcode = '22023';
      end if;
      v_product_id := v_batch_product;
    end if;

    insert into public.pos_sale_items (
      sale_id, product_id, product_name, quantity, unit_price, total_price,
      batch_id, discount_percentage, notes
    ) values (
      v_sale_id,
      v_product_id,
      v_item->>'product_name',
      (v_item->>'quantity')::integer,
      (v_item->>'unit_price')::integer,
      (v_item->>'total_price')::integer,
      v_batch_id,
      coalesce((v_item->>'discount_percentage')::numeric, 0),
      v_item->>'notes'
    );

    -- Ligne sans lot : enregistrée sans mouvement de stock (catalogue
    -- de l'écran d'encaissement, voir C201).
    if v_batch_id is not null then
      perform public.stock_apply_movement(
        v_batch_id, -((v_item->>'quantity')::integer), 'sale',
        v_sale_id::text, 'Vente POS'
      );
    end if;
  end loop;

  insert into public.pos_receipts (sale_id, printed_at, printed_by)
  values (v_sale_id, now(), v_user_id);

  return v_sale_id;
end;
$$;

comment on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) is
  'C197 / C203 : vente POS complète en une transaction (vente, lignes, mouvements de stock via stock_apply_movement, reçu). Caissier = auth.uid(). Contrôles C203 : remise <= total, montant final = total - remise + TVA à 1 près, remise par ligne refusée, produit de la ligne = produit du lot, lot introuvable signalé. Toute erreur annule l''ensemble.';

revoke all on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) from public, anon;
grant execute on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) to authenticated;
