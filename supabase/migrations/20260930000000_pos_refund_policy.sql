-- Correctif C204 : regle de remboursement POS et destination du stock rendu.
--
-- Decision du porteur du projet (29/09/2026, registre D57) :
--   1. Regle graduee (option C) : tout pharmacien rattache a l'officine peut
--      rembourser une vente le jour meme et jusqu'a un plafond ; au-dela du
--      jour ou du plafond, seul le titulaire (pharmacies.manager_id) peut
--      rembourser.
--   2. Controle apres coup (option E) : chaque remboursement porte un motif
--      obligatoire, son auteur et son heure ; la liste des remboursements est
--      consultable dans les rapports POS.
--   3. Plafond propre a chaque officine (pharmacies.pos_refund_staff_limit),
--      100 000 GNF par defaut, jamais code en dur dans la logique.
--   4. Destination du stock rendu choisie a chaque remboursement, sans valeur
--      par defaut : 'restock' (remise en stock, boite intacte) ou
--      'quarantine' (hors stock vendable, en attente de destruction ou de
--      retour fournisseur).
--
-- Remplace public.pos_refund_sale(uuid) de C197
-- (20260929010000_pos_atomic_sale_refund.sql) : la signature change, l'ancienne
-- version est supprimee pour ne pas coexister avec la nouvelle.
--
-- Acces : is_pharmacy_staff() uniquement (decision du porteur du projet,
-- 29/09/2026). manager_id sert seulement a lever la regle jour/plafond. Le
-- rattachement du titulaire a son officine (profiles.pharmacy_id) est assure
-- par C208 (20260929040000_pharmacy_manager_attachment.sql), qui precede ce
-- fichier ; stock_apply_movement (C156) n'est pas modifiee.
--
-- Aucune migration existante modifiee. Aucune reprise de donnees : les ventes
-- deja remboursees gardent les nouvelles colonnes a null.

-- ==================== Plafond par officine ====================

alter table public.pharmacies
  add column pos_refund_staff_limit integer not null default 100000
  check (pos_refund_staff_limit >= 0);
comment on column public.pharmacies.pos_refund_staff_limit is
  'C204 : montant final maximal (GNF) qu''un pharmacien non titulaire peut rembourser, le jour même de la vente. Au-delà, remboursement réservé au titulaire (manager_id).';

-- ==================== Traçabilité sur la vente ====================

alter table public.pos_sales
  add column refunded_at timestamptz,
  add column refunded_by uuid references public.profiles(id),
  add column refund_reason text,
  add column refund_stock_disposition text
    check (refund_stock_disposition in ('restock', 'quarantine'));

comment on column public.pos_sales.refunded_at is 'C204 : heure du remboursement (null pour les remboursements antérieurs à C204).';
comment on column public.pos_sales.refunded_by is 'C204 : auteur du remboursement (auth.uid()).';
comment on column public.pos_sales.refund_reason is 'C204 : motif obligatoire du remboursement.';
comment on column public.pos_sales.refund_stock_disposition is 'C204 : destination du stock rendu : restock (remis en stock) ou quarantine.';

-- ==================== Quarantaine ====================

-- Une boîte en quarantaine est déjà sortie du stock au moment de la vente :
-- aucun mouvement de stock n'est créé, on enregistre seulement où elle se
-- trouve. La résolution (destroyed / returned_to_supplier) relève de C206.
create table public.pos_refund_quarantine (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  sale_id uuid not null references public.pos_sales(id) on delete cascade,
  sale_item_id uuid references public.pos_sale_items(id) on delete set null,
  batch_id uuid references public.stock_batches(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  status text not null default 'quarantined'
    check (status in ('quarantined', 'destroyed', 'returned_to_supplier')),
  reason text not null,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id),
  notes text
);
create index on public.pos_refund_quarantine (pharmacy_id, status);
alter table public.pos_refund_quarantine enable row level security;

comment on table public.pos_refund_quarantine is
  'C204 : produits rendus lors d''un remboursement POS et mis en quarantaine (hors stock vendable). Lignes créées uniquement par pos_refund_sale ; aucune policy d''écriture.';

create policy "pos_refund_quarantine_select_staff" on public.pos_refund_quarantine
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id)
         or exists (select 1 from public.pharmacies p
                    where p.id = pharmacy_id and p.manager_id = auth.uid()));

-- ==================== Remboursement ====================

drop function public.pos_refund_sale(uuid);

create function public.pos_refund_sale(
  p_sale_id uuid,
  p_reason text,
  p_disposition text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
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
begin
  -- Verrou sur la vente : deux remboursements simultanés se sérialisent.
  select pharmacy_id, status, final_amount, created_at
    into v_pharmacy_id, v_status, v_final, v_created_at
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
end;
$$;

comment on function public.pos_refund_sale(uuid, text, text) is
  'C197 / C204 : remboursement POS complet en une transaction. Accès : is_pharmacy_staff. Pharmacien de l''officine : le jour même (heure de Conakry) et jusqu''à pharmacies.pos_refund_staff_limit ; au-delà, titulaire (manager_id) seul. Motif obligatoire (3 caractères min.), destination explicite : restock (réintégration via stock_apply_movement) ou quarantine (ligne pos_refund_quarantine, aucun mouvement de stock). Seule une vente completed peut être remboursée.';

revoke all on function public.pos_refund_sale(uuid, text, text) from public, anon;
grant execute on function public.pos_refund_sale(uuid, text, text) to authenticated;
