-- Correctif C197 : vente et remboursement POS atomiques (RPC).
--
-- Cible C197, coherente avec D51 : la vente complete (vente, lignes,
-- mouvements de stock, recu) est enregistree en une seule transaction par
-- public.pos_create_sale(). Son pendant public.pos_refund_sale() rend le
-- remboursement atomique et non rejouable (seule une vente 'completed' peut
-- etre remboursee, verrou sur la vente).
--
-- Reutilisation de C156 : les mouvements de stock passent par
-- public.stock_apply_movement() (20260927080000_stock_apply_movement.sql),
-- appelee depuis ces fonctions et non modifiee. Une erreur de stock (stock
-- insuffisant, P0001) annule desormais toute la vente.
--
-- Defaut de numerotation corrige ici (nouveau, hors registre avant ce
-- correctif) : generate_sale_number() et generate_receipt_number()
-- (20260829006000_pos.sql) calculaient max(numero) + 1 sans SECURITY
-- DEFINER, donc sous RLS : chaque officine ne voyait que ses propres
-- numeros alors que sale_number / receipt_number sont uniques sur toute la
-- table. La premiere vente de l'officine B reprenait le numero S000001 deja
-- attribue a A et l'insertion echouait. Deux ventes simultanees pouvaient
-- aussi obtenir le meme numero.
--
-- Aucune migration existante modifiee.

-- ==================== Numerotation sure ====================

-- Numérotation globale : SECURITY DEFINER pour voir toutes les officines
-- (sinon collision sous RLS : la 1re vente de B reprenait le numéro de A),
-- verrou transactionnel pour sérialiser les créations simultanées. Pas de
-- séquence : un rollback ne laisse pas de trou dans la numérotation.
create or replace function public.generate_sale_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('pos_sales.sale_number'));
  select coalesce(max(substring(sale_number from '^S([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.pos_sales;
  new.sale_number := 'S' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

-- Même modèle pour les reçus.
create or replace function public.generate_receipt_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('pos_receipts.receipt_number'));
  select coalesce(max(substring(receipt_number from '^R([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.pos_receipts;
  new.receipt_number := 'R' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

-- ==================== Vente atomique ====================

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
    v_batch_id := nullif(v_item->>'batch_id', '')::uuid;

    if v_batch_id is not null then
      select si.pharmacy_id into v_batch_pharmacy
        from public.stock_batches b
        join public.stock_items si on si.id = b.stock_item_id
        where b.id = v_batch_id;
      if v_batch_pharmacy is distinct from p_pharmacy_id then
        raise exception 'POS: le lot % n''appartient pas a cette officine', v_batch_id
          using errcode = '42501';
      end if;
    end if;

    insert into public.pos_sale_items (
      sale_id, product_id, product_name, quantity, unit_price, total_price,
      batch_id, discount_percentage, notes
    ) values (
      v_sale_id,
      nullif(v_item->>'product_id', '')::uuid,
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
  'C197 : vente POS complète en une transaction (vente, lignes, mouvements de stock via stock_apply_movement, reçu). Caissier = auth.uid(). Toute erreur annule l''ensemble.';

revoke all on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) from public, anon;
grant execute on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) to authenticated;

-- ==================== Remboursement atomique ====================

create or replace function public.pos_refund_sale(p_sale_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_pharmacy_id uuid;
  v_status text;
  v_item record;
begin
  -- Verrou sur la vente : deux remboursements simultanés se sérialisent.
  select pharmacy_id, status into v_pharmacy_id, v_status
    from public.pos_sales
    where id = p_sale_id
    for update;

  if not found then
    raise exception 'POS: vente % introuvable', p_sale_id using errcode = 'P0002';
  end if;
  if v_user_id is null or not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;
  if v_status is distinct from 'completed' then
    raise exception 'POS: seule une vente completee peut etre remboursee (statut %)', v_status
      using errcode = '22023';
  end if;

  -- updated_at est géré par trigger_pos_sales_updated_at.
  update public.pos_sales
    set status = 'refunded', updated_by = v_user_id
    where id = p_sale_id;

  for v_item in
    select batch_id, quantity from public.pos_sale_items
    where sale_id = p_sale_id and batch_id is not null
  loop
    perform public.stock_apply_movement(
      v_item.batch_id, v_item.quantity, 'adjustment',
      p_sale_id::text, 'Remboursement vente POS'
    );
  end loop;
end;
$$;

comment on function public.pos_refund_sale(uuid) is
  'C197 : remboursement POS complet en une transaction (statut refunded, réintégration du stock via stock_apply_movement). Verrouille la vente ; seule une vente completed peut être remboursée, un second remboursement est refusé.';

revoke all on function public.pos_refund_sale(uuid) from public, anon;
grant execute on function public.pos_refund_sale(uuid) to authenticated;
