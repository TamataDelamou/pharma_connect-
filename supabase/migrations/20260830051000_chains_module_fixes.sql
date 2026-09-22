-- Audit Module 26 (CHN), Étape 3 (05/09/2026) — migration corrective,
-- postérieure à chains.sql/network_admin.sql (29/08) et à
-- admin_helpers.sql (dont dépend is_pharmacy_staff()/is_gsg_admin()),
-- sur le même modèle que les migrations correctives des Modules 19-25
-- (édition en place évitée pour ne pas casser le rejeu chronologique de
-- la chaîne complète des migrations).

-- ============================================================
-- CHN-5 (Critique) : motif "auth.uid() = pharmacy_id" (un identifiant
-- UTILISATEUR comparé à un identifiant D'OFFICINE, jamais équivalents)
-- retrouvé sur 5 policies sur 6 de ce module ; la 6ème
-- ("Admins manage transfers") n'était corrigée que sur une de ses deux
-- branches. Toutes réécrites ci-dessous en réutilisant le helper déjà
-- existant et déjà validé par exécution réelle ailleurs dans le projet,
-- `public.is_pharmacy_staff(target_pharmacy_id)` — la sémantique requise
-- (« le compte connecté fait partie du personnel de l'officine X ») est
-- exactement ce que ce helper vérifie ; aucune nouvelle fonction n'est
-- nécessaire. Chaque policy ajoute également l'accès manquant pour
-- l'officine DESTINATAIRE d'un transfert (`to_pharmacy_id`), absent de
-- toutes les versions précédentes — sans quoi l'officine qui reçoit un
-- transfert ne pourrait jamais elle-même le consulter ni le faire passer
-- à "reçu".
-- ============================================================
--
-- CHN-5-bis (découvert en exécution réelle Postgres 16, pendant la
-- vérification de ce correctif) : la policy "Members view group members"
-- telle qu'initialement écrite ci-dessous interrogeait `group_members`
-- DANS une policy portant sur `group_members` lui-même (sous-requête
-- `exists (select 1 from public.group_members gm where ...)` à
-- l'intérieur d'une policy de `group_members`). Postgres échoue alors
-- systématiquement avec `ERROR: infinite recursion detected in policy
-- for relation "group_members"` (confirmé par exécution réelle, test 1
-- de `chn_rls_test.sql`) : évaluer la policy exige de ré-évaluer la
-- policy sur les lignes de la sous-requête, qui exige de la ré-évaluer
-- à nouveau, etc. Corrigé en suivant le même principe que
-- `is_pharmacy_staff()` (déjà utilisé partout ailleurs dans le projet) :
-- la vérification d'appartenance au groupe est déplacée dans une
-- fonction SECURITY DEFINER, exécutée avec les privilèges du
-- propriétaire de la table (exempté de RLS sur cette table), ce qui
-- sort la sous-requête du contexte RLS et supprime la récursion.
create or replace function public.is_group_member(target_group_id uuid, min_role text default null)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members gm
    where gm.group_id = target_group_id
      and public.is_pharmacy_staff(gm.pharmacy_id)
      and gm.is_active = true
      and (min_role is null or gm.role = min_role)
  );
$$;

comment on function public.is_group_member(uuid, text) is
  'Vrai si l''utilisateur courant (staff d''une officine membre active) appartient au groupe target_group_id, optionnellement avec un role precis. SECURITY DEFINER pour eviter la recursion RLS constatee (Module 26, CHN-5-bis) quand une policy de group_members s''auto-interroge.';

drop policy if exists "Members view group members" on public.group_members;
create policy "Members view group members" on public.group_members
  for select using (
    public.is_group_member(group_members.group_id)
  );

drop policy if exists "Admins manage group members" on public.group_members;
create policy "Admins manage group members" on public.group_members
  for all using (
    public.is_group_member(group_members.group_id, 'admin')
  );

drop policy if exists "Involved pharmacies view transfers" on public.stock_transfers;
create policy "Involved pharmacies view transfers" on public.stock_transfers
  for select using (
    public.is_pharmacy_staff(from_pharmacy_id)
    or public.is_pharmacy_staff(to_pharmacy_id)
    or public.is_group_member(stock_transfers.group_id, 'admin')
    or public.is_group_member(stock_transfers.group_id, 'manager')
  );

drop policy if exists "Admins manage transfers" on public.stock_transfers;
create policy "Admins manage transfers" on public.stock_transfers
  for all using (
    public.is_pharmacy_staff(from_pharmacy_id)
    or public.is_pharmacy_staff(to_pharmacy_id)
    or public.is_group_member(stock_transfers.group_id, 'admin')
    or public.is_group_member(stock_transfers.group_id, 'manager')
  );

drop policy if exists "Transfer items viewable with transfer" on public.transfer_items;
create policy "Transfer items viewable with transfer" on public.transfer_items
  for select using (
    exists (
      select 1 from public.stock_transfers st
      where st.id = transfer_items.transfer_id
      and (
        public.is_pharmacy_staff(st.from_pharmacy_id)
        or public.is_pharmacy_staff(st.to_pharmacy_id)
        or public.is_group_member(st.group_id, 'admin')
        or public.is_group_member(st.group_id, 'manager')
      )
    )
  );

drop policy if exists "Transfer items managed with transfer" on public.transfer_items;
create policy "Transfer items managed with transfer" on public.transfer_items
  for all using (
    exists (
      select 1 from public.stock_transfers st
      where st.id = transfer_items.transfer_id
      and (
        public.is_pharmacy_staff(st.from_pharmacy_id)
        or public.is_pharmacy_staff(st.to_pharmacy_id)
        or public.is_group_member(st.group_id, 'admin')
        or public.is_group_member(st.group_id, 'manager')
      )
    )
  );

-- ============================================================
-- CHN-7 (RG-CHN-01, seule règle du module) : « Un transfert de stock
-- inter-officines génère deux mouvements symétriques tracés (sortie/
-- entrée) et ne peut porter que sur des lots non expirés. » Non
-- appliquée à l'ouverture sous trois angles convergents (voir le rapport
-- d'audit §4, CHN-7) : aucune saisie de lot/péremption côté client
-- (corrigé côté Dart, `transfer_create_screen.dart`), aucune contrainte
-- serveur revérifiant cette saisie, et aucune génération réelle de
-- mouvement de stock. Les deux volets serveur sont corrigés ci-dessous.
-- ============================================================

-- Volet 1 : lot et péremption obligatoires et non expirés À LA SAISIE.
create or replace function public.chn_validate_transfer_item()
returns trigger
language plpgsql
as $$
begin
  if new.batch_number is null or length(trim(new.batch_number)) = 0 then
    raise exception 'RG-CHN-01: le numero de lot est obligatoire pour un transfert inter-officines';
  end if;
  if new.expiry_date is null then
    raise exception 'RG-CHN-01: la date de peremption est obligatoire pour un transfert inter-officines';
  end if;
  if new.expiry_date < current_date then
    raise exception 'RG-CHN-01: un transfert ne peut porter que sur des lots non expires (lot % perime le %)', new.batch_number, new.expiry_date;
  end if;
  return new;
end;
$$;

drop trigger if exists chn_validate_transfer_item on public.transfer_items;
create trigger chn_validate_transfer_item
before insert or update on public.transfer_items
for each row execute function public.chn_validate_transfer_item();

-- Volet 2 : génération réelle de deux mouvements symétriques tracés
-- (sortie officine source / entrée officine destination) à la RÉCEPTION
-- du transfert (transition de statut vers 'received'), avec re-
-- vérification de la non-péremption du lot AU MOMENT RÉEL DU MOUVEMENT
-- (pas seulement à la création du transfert, qui peut précéder la
-- réception de plusieurs jours) et de la disponibilité réelle de la
-- quantité en stock source. SECURITY DEFINER : `stock_items`/
-- `stock_batches`/`stock_movements` (module STK, Module 4, hors
-- périmètre de cet audit) n'exposent aujourd'hui aucune policy
-- d'écriture pour le rôle `authenticated` (uniquement `select ... using
-- (true)`, `20260827000600_stock.sql`) — plutôt que d'élargir les
-- droits d'écriture de ce module tiers sans l'auditer, cette fonction
-- encapsule le mouvement réel sous ses propres privilèges, même
-- principe que `is_gsg_admin()`/`is_pharmacy_staff()`.
create or replace function public.chn_process_transfer_receipt()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
  v_source_stock_item_id uuid;
  v_source_batch_id uuid;
  v_source_batch_qty integer;
  v_source_batch_expiry date;
  v_dest_stock_item_id uuid;
  v_dest_batch_id uuid;
  v_user_id uuid := auth.uid();
begin
  if new.status <> 'received' or old.status is not distinct from new.status then
    return new;
  end if;

  for v_item in
    select * from public.transfer_items where transfer_id = new.id
  loop
    if v_item.product_id is null then
      raise exception 'RG-CHN-01: article de transfert % sans produit associe, reception impossible', v_item.id;
    end if;

    select id into v_source_stock_item_id
      from public.stock_items
      where pharmacy_id = new.from_pharmacy_id and product_id = v_item.product_id;

    if v_source_stock_item_id is null then
      raise exception 'RG-CHN-01: aucun stock pour le produit % dans l officine source, transfert impossible', v_item.product_id;
    end if;

    select id, quantity, expiry_date
      into v_source_batch_id, v_source_batch_qty, v_source_batch_expiry
      from public.stock_batches
      where stock_item_id = v_source_stock_item_id
        and batch_number = v_item.batch_number
      limit 1;

    if v_source_batch_id is null then
      raise exception 'RG-CHN-01: lot % introuvable dans le stock source pour le produit %', v_item.batch_number, v_item.product_id;
    end if;

    if v_source_batch_expiry < current_date then
      raise exception 'RG-CHN-01: le lot % du produit % est perime (peremption %), transfert refuse a la reception', v_item.batch_number, v_item.product_id, v_source_batch_expiry;
    end if;

    if v_source_batch_qty < v_item.quantity then
      raise exception 'RG-CHN-01: quantite insuffisante sur le lot % (disponible %, demande %)', v_item.batch_number, v_source_batch_qty, v_item.quantity;
    end if;

    -- Mouvement de sortie (officine source).
    update public.stock_batches
      set quantity = quantity - v_item.quantity
      where id = v_source_batch_id;
    update public.stock_items
      set total_quantity = total_quantity - v_item.quantity
      where id = v_source_stock_item_id;
    insert into public.stock_movements (
      stock_item_id, batch_id, type, quantity, user_id, reference_id, reason, notes
    ) values (
      v_source_stock_item_id, v_source_batch_id, 'transfer', -v_item.quantity, v_user_id,
      new.id::text, 'Transfert inter-officines (sortie)',
      'Vers officine ' || new.to_pharmacy_id::text
    );

    -- Officine destination : upsert de l'article de stock et du lot
    -- (même numéro de lot et même péremption que la source — un
    -- transfert ne fabrique pas un nouveau lot, il déplace le même).
    select id into v_dest_stock_item_id
      from public.stock_items
      where pharmacy_id = new.to_pharmacy_id and product_id = v_item.product_id;

    if v_dest_stock_item_id is null then
      insert into public.stock_items (pharmacy_id, product_id, total_quantity, unit_price)
      values (new.to_pharmacy_id, v_item.product_id, 0, 0)
      returning id into v_dest_stock_item_id;
    end if;

    select id into v_dest_batch_id
      from public.stock_batches
      where stock_item_id = v_dest_stock_item_id
        and batch_number = v_item.batch_number;

    if v_dest_batch_id is null then
      insert into public.stock_batches (
        stock_item_id, batch_number, manufacturing_date, expiry_date, quantity
      ) values (
        v_dest_stock_item_id, v_item.batch_number, current_date, v_source_batch_expiry, v_item.quantity
      ) returning id into v_dest_batch_id;
    else
      update public.stock_batches
        set quantity = quantity + v_item.quantity
        where id = v_dest_batch_id;
    end if;

    update public.stock_items
      set total_quantity = total_quantity + v_item.quantity
      where id = v_dest_stock_item_id;

    insert into public.stock_movements (
      stock_item_id, batch_id, type, quantity, user_id, reference_id, reason, notes
    ) values (
      v_dest_stock_item_id, v_dest_batch_id, 'transfer', v_item.quantity, v_user_id,
      new.id::text, 'Transfert inter-officines (entree)',
      'Depuis officine ' || new.from_pharmacy_id::text
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists chn_process_transfer_receipt on public.stock_transfers;
create trigger chn_process_transfer_receipt
after update on public.stock_transfers
for each row execute function public.chn_process_transfer_receipt();
