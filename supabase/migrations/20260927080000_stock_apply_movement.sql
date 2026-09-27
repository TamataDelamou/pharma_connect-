-- Correctif C156 : fonction unique de mouvement de stock, appelee par RPC.
--
-- Decision du porteur du projet (C156, 20/09/2026) : option (b), fonction
-- Postgres SECURITY DEFINER dediee, plutot qu'une lecture puis reecriture
-- non atomique cote client. D51 point 3 : aucune logique de mouvement de
-- stock dupliquee par module ; la vente POS, le remboursement POS et le
-- retour client passent tous par cette fonction.
--
-- Modele : chn_process_transfer_receipt()
-- (20260830051000_chains_module_fixes.sql), reference existante pour un
-- mouvement complet : stock_batches.quantity, stock_items.total_quantity et
-- une ligne stock_movements dans la meme transaction.
--
-- Aucune migration existante modifiee. Pas de contrainte check
-- (quantity >= 0) sur stock_batches (des donnees existantes pourraient la
-- violer) : la regle est portee par la fonction. Pas de colonne updated_at
-- ajoutee a stock_batches : les appelants Dart cessent de l'ecrire.

create or replace function public.stock_apply_movement(
  p_batch_id uuid,
  p_delta integer,
  p_type text,
  p_reference_id text default null,
  p_reason text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stock_item_id uuid;
  v_pharmacy_id uuid;
  v_new_qty integer;
begin
  if p_delta is null or p_delta = 0 then
    raise exception 'STK: quantite de mouvement nulle' using errcode = '22023';
  end if;

  -- Types acceptes : ceux des appelants actuels uniquement. Une vente sort
  -- du stock ; les reintegrations (remboursement, retour client) passent
  -- par 'adjustment' avec un motif explicite.
  if p_type not in ('sale', 'adjustment') then
    raise exception 'STK: type de mouvement % non autorise par cette fonction', p_type
      using errcode = '22023';
  end if;
  if p_type = 'sale' and p_delta > 0 then
    raise exception 'STK: une vente doit sortir du stock (delta negatif)'
      using errcode = '22023';
  end if;

  -- Verrou sur le lot : deux ventes simultanees du meme lot se serialisent.
  select b.stock_item_id, si.pharmacy_id
    into v_stock_item_id, v_pharmacy_id
    from public.stock_batches b
    join public.stock_items si on si.id = b.stock_item_id
    where b.id = p_batch_id
    for update of b;

  if not found then
    raise exception 'STK: lot % introuvable', p_batch_id using errcode = 'P0002';
  end if;

  -- SECURITY DEFINER contourne la RLS : on refait ici le controle de la
  -- policy stock_batches_write_staff.
  if not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'STK: acces refuse au stock de cette officine'
      using errcode = '42501';
  end if;

  update public.stock_batches
    set quantity = quantity + p_delta
    where id = p_batch_id
      and quantity + p_delta >= 0
    returning quantity into v_new_qty;

  if v_new_qty is null then
    raise exception 'STK: stock insuffisant sur le lot % (mouvement %)', p_batch_id, p_delta
      using errcode = 'P0001';
  end if;

  update public.stock_items
    set total_quantity = total_quantity + p_delta
    where id = v_stock_item_id;

  insert into public.stock_movements (
    stock_item_id, batch_id, type, quantity, user_id, reference_id, reason
  ) values (
    v_stock_item_id, p_batch_id, p_type, p_delta, auth.uid(), p_reference_id, p_reason
  );

  return v_new_qty;
end;
$$;

comment on function public.stock_apply_movement(uuid, integer, text, text, text) is
  'C156 / D51 point 3 : unique point d''entrée des mouvements de stock du cluster POS/retours. Verrouille le lot, contrôle is_pharmacy_staff, refuse un stock négatif, met à jour stock_batches.quantity et stock_items.total_quantity, journalise dans stock_movements. Renvoie la nouvelle quantité du lot.';

revoke all on function public.stock_apply_movement(uuid, integer, text, text, text) from public, anon;
grant execute on function public.stock_apply_movement(uuid, integer, text, text, text) to authenticated;
