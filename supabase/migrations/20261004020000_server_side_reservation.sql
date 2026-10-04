-- C243 : la réservation (Click & Collect) est faite par le serveur.
--
-- Constat : l'application écrivait elle-même la réservation et le stock
-- (ReservationService.createReservation, StockService.reserveStock). Pour un
-- patient, l'écriture du stock ne touchait aucune ligne (lots illisibles,
-- stock_items et stock_batches réservés au personnel) : aucune boîte n'était
-- retenue. La règle reservations_patient_update laissait en outre le patient
-- modifier toute sa réservation, statut et montant compris. Le retrait ne
-- créait aucune vente.
--
-- Décisions d'Achille du 04/10/2026 :
--   - réservation retenue 24 h, puis expirée (tâche planifiée et contrôle à
--     l'usage) ;
--   - prix indicatif à la réservation, prix du jour imposé au retrait (C218) ;
--   - au plus 3 réservations actives par patient et 5 boîtes par ligne,
--     réglables par officine ;
--   - stupéfiants et psychotropes non réservables ; produits sur ordonnance
--     réservables ;
--   - retrait partiel autorisé quand un lot rappelé ou périmé n'a pas de
--     remplaçant, motif enregistré ;
--   - code de retrait exigé au retrait : 6 caractères sans 0/O ni 1/I,
--     unique parmi les réservations actives de l'officine ;
--   - vente au comptoir à lot désigné : ne prend plus une boîte retenue ;
--   - statut « confirmed » non utilisé pendant le pilote
--     (pending → ready → pickedUp).
--
-- Cette migration :
--   - ajoute les réglages par officine, le lien vers la vente, l'auteur et le
--     motif d'annulation, et la table des lots retenus par ligne ;
--   - supprime les règles d'écriture directe de reservations et
--     reservation_items (les règles de lecture restent) ;
--   - ajoute reservation_create, reservation_mark_ready, reservation_cancel,
--     reservation_pickup, reservation_pickup_preview,
--     reservation_unavailable_items, reservation_expire_for_pharmacy et les
--     fonctions internes de retenue, de libération et d'expiration ;
--   - recrée pos_create_sale (même signature, corps C240 repris) : un lot
--     désigné n'est vendable que hors boîtes retenues ;
--   - prépare la tâche planifiée d'expiration (pg_cron), sans échec si
--     l'extension est indisponible.
-- Aucune migration existante n'est modifiée.

-- ============================================================
-- Schéma
-- ============================================================

alter table public.pharmacies
  add column if not exists reservation_max_active_per_patient integer not null default 3
    check (reservation_max_active_per_patient > 0),
  add column if not exists reservation_max_quantity_per_line integer not null default 5
    check (reservation_max_quantity_per_line > 0);

comment on column public.pharmacies.reservation_max_active_per_patient is
  'C243 : nombre maximal de réservations actives d''un même patient dans cette officine (3 par défaut).';
comment on column public.pharmacies.reservation_max_quantity_per_line is
  'C243 : nombre maximal de boîtes par ligne de réservation dans cette officine (5 par défaut).';

alter table public.reservations
  add column if not exists pos_sale_id uuid references public.pos_sales(id),
  add column if not exists cancelled_by uuid references auth.users(id),
  add column if not exists cancel_reason text,
  add column if not exists expired_at timestamptz;

comment on column public.reservations.pos_sale_id is
  'C243 : vente au comptoir créée au retrait (reservation_pickup).';

alter table public.reservation_items
  add column if not exists prescription_required boolean not null default false,
  add column if not exists removed_at timestamptz,
  add column if not exists removed_reason text;

comment on column public.reservation_items.removed_at is
  'C243 : ligne retirée lors d''un retrait partiel (lot rappelé ou périmé sans remplaçant).';

create table if not exists public.reservation_item_batches (
  id uuid primary key default gen_random_uuid(),
  reservation_item_id uuid not null references public.reservation_items(id) on delete cascade,
  batch_id uuid not null references public.stock_batches(id),
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default now(),
  released_at timestamptz
);

comment on table public.reservation_item_batches is
  'C243 : boîtes retenues par ligne de réservation, lot par lot. released_at : retenue levée (retrait, annulation, expiration, lot remplacé). Écrite par les seules fonctions reservation_*.';

create index if not exists idx_reservation_item_batches_item
  on public.reservation_item_batches(reservation_item_id);
create index if not exists idx_reservation_item_batches_batch_active
  on public.reservation_item_batches(batch_id) where released_at is null;
create index if not exists idx_reservations_active_deadline
  on public.reservations(pharmacy_id, pickup_deadline)
  where status in ('pending', 'confirmed', 'ready');

alter table public.reservation_item_batches enable row level security;

-- Lecture : personnel de l'officine et GSG. Le patient ne lit aucun lot.
-- Aucune règle d'écriture : lignes créées par les seules fonctions.
create policy "reservation_item_batches_staff_select" on public.reservation_item_batches
  for select to authenticated
  using (
    public.is_gsg_admin()
    or exists (
      select 1
        from public.reservation_items ri
        join public.reservations r on r.id = ri.reservation_id
        where ri.id = reservation_item_batches.reservation_item_id
          and public.is_pharmacy_staff(r.pharmacy_id)
    )
  );

-- ============================================================
-- Fin des écritures directes depuis l'application
-- ============================================================
-- Règles de lecture conservées : reservations_select_own,
-- reservations_staff_select, reservation_items_select_own,
-- reservation_items_staff_select.

drop policy if exists "reservations_insert_own" on public.reservations;
drop policy if exists "reservations_patient_update" on public.reservations;
drop policy if exists "reservations_staff_update" on public.reservations;
drop policy if exists "reservation_items_insert_own" on public.reservation_items;

-- ============================================================
-- Fonctions internes : retenue, libération, expiration
-- ============================================================

-- Retient p_qty boîtes d'un article de stock pour une ligne : péremption la
-- plus proche d'abord, lots périmés et rappelés exclus, lots verrouillés.
-- Rend la quantité qui n'a pas pu être retenue (0 si tout est retenu).
create or replace function public.reservation_hold_stock(
  p_reservation_id uuid,
  p_item_id uuid,
  p_stock_item_id uuid,
  p_qty integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_remaining integer := p_qty;
  v_take integer;
  v_lot record;
begin
  for v_lot in
    select b.id, greatest(b.quantity - b.quantity_reserved, 0) as available
      from public.stock_batches b
      where b.stock_item_id = p_stock_item_id
        and b.expiry_date >= v_today
        and b.quantity - b.quantity_reserved > 0
        and public.stock_batch_recall(b.id) is null
      order by b.expiry_date, b.received_at nulls last, b.id
      for update of b
  loop
    exit when v_remaining = 0;
    v_take := least(v_remaining, v_lot.available);
    update public.stock_batches
      set quantity_reserved = quantity_reserved + v_take
      where id = v_lot.id;
    insert into public.reservation_item_batches (reservation_item_id, batch_id, quantity)
      values (p_item_id, v_lot.id, v_take);
    insert into public.stock_movements (
      stock_item_id, batch_id, type, quantity, user_id, reference_id, reason
    ) values (
      p_stock_item_id, v_lot.id, 'reservation', -v_take, auth.uid(),
      p_reservation_id::text, 'Reservation'
    );
    v_remaining := v_remaining - v_take;
  end loop;

  if v_remaining < p_qty then
    update public.stock_items
      set reserved_quantity = reserved_quantity + (p_qty - v_remaining)
      where id = p_stock_item_id;
  end if;
  return v_remaining;
end;
$$;

comment on function public.reservation_hold_stock(uuid, uuid, uuid, integer) is
  'C243 : retenue de boîtes pour une ligne de réservation (lots verrouillés, péremption la plus proche, périmés et rappelés exclus). Interne.';

revoke all on function public.reservation_hold_stock(uuid, uuid, uuid, integer) from public, anon, authenticated;

-- Lève les retenues encore actives d'une réservation, d'une ligne ou d'une
-- seule retenue ; les boîtes redeviennent vendables.
create or replace function public.reservation_release_holds(
  p_reservation_id uuid,
  p_item_id uuid,
  p_hold_id uuid,
  p_reason text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hold record;
  v_released integer := 0;
begin
  for v_hold in
    select h.id, h.batch_id, h.quantity, b.stock_item_id
      from public.reservation_item_batches h
      join public.reservation_items ri on ri.id = h.reservation_item_id
      join public.stock_batches b on b.id = h.batch_id
      where ri.reservation_id = p_reservation_id
        and (p_item_id is null or ri.id = p_item_id)
        and (p_hold_id is null or h.id = p_hold_id)
        and h.released_at is null
      order by h.batch_id, h.id
      for update of h, b
  loop
    update public.stock_batches
      set quantity_reserved = greatest(quantity_reserved - v_hold.quantity, 0)
      where id = v_hold.batch_id;
    update public.stock_items
      set reserved_quantity = greatest(reserved_quantity - v_hold.quantity, 0)
      where id = v_hold.stock_item_id;
    insert into public.stock_movements (
      stock_item_id, batch_id, type, quantity, user_id, reference_id, reason
    ) values (
      v_hold.stock_item_id, v_hold.batch_id, 'unreservation', v_hold.quantity, auth.uid(),
      p_reservation_id::text, p_reason
    );
    update public.reservation_item_batches set released_at = now() where id = v_hold.id;
    v_released := v_released + v_hold.quantity;
  end loop;
  return v_released;
end;
$$;

comment on function public.reservation_release_holds(uuid, uuid, uuid, text) is
  'C243 : libération des boîtes retenues (réservation entière, une ligne ou une retenue). Interne.';

revoke all on function public.reservation_release_holds(uuid, uuid, uuid, text) from public, anon, authenticated;

-- Expire les réservations actives dont l'échéance de retrait est passée et
-- libère leurs boîtes. Appelée par la tâche planifiée (toutes officines) et
-- par les fonctions de réservation (officine concernée).
create or replace function public.reservation_expire_overdue(p_pharmacy_id uuid default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_res record;
  v_count integer := 0;
begin
  for v_res in
    select r.id
      from public.reservations r
      where r.status in ('pending', 'confirmed', 'ready')
        and r.pickup_deadline is not null
        and r.pickup_deadline < now()
        and (p_pharmacy_id is null or r.pharmacy_id = p_pharmacy_id)
      order by r.id
      for update of r skip locked
  loop
    perform public.reservation_release_holds(v_res.id, null, null, 'Reservation expiree');
    update public.reservations
      set status = 'expired', expired_at = now(), queue_position = 0, estimated_wait_minutes = 0
      where id = v_res.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

comment on function public.reservation_expire_overdue(uuid) is
  'C243 : expiration des réservations non retirées à l''échéance (24 h) et libération de leurs boîtes. Interne : tâche planifiée et fonctions reservation_*.';

revoke all on function public.reservation_expire_overdue(uuid) from public, anon, authenticated;

-- ============================================================
-- Code de retrait
-- ============================================================

-- Un même code ne désigne qu'une réservation active par officine.
create unique index if not exists idx_reservations_active_pickup_code
  on public.reservations(pharmacy_id, upper(qr_code_token))
  where status in ('pending', 'confirmed', 'ready');

-- Code court de 6 caractères, sans caractères ambigus (ni 0/O, ni 1/I),
-- unique parmi les réservations actives de l'officine.
create or replace function public.reservation_new_pickup_code(p_pharmacy_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_bytes bytea;
  v_code text;
  v_try integer;
begin
  for v_try in 1..20 loop
    -- Octets 0 à 5 d'un uuid aléatoire : 32 valeurs équiprobables chacun.
    v_bytes := uuid_send(gen_random_uuid());
    v_code := '';
    for i in 0..5 loop
      v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, i) % 32) + 1, 1);
    end loop;
    if not exists (
      select 1 from public.reservations r
        where r.pharmacy_id = p_pharmacy_id and upper(r.qr_code_token) = v_code
          and r.status in ('pending', 'confirmed', 'ready')
    ) then
      return v_code;
    end if;
  end loop;
  raise exception 'RES: code de retrait non attribue, reessayez' using errcode = 'P0001';
end;
$$;

comment on function public.reservation_new_pickup_code(uuid) is
  'C243 : code de retrait de 6 caractères (alphabet sans 0, O, 1, I), unique parmi les réservations actives de l''officine. Interne : appelée par reservation_create.';

revoke all on function public.reservation_new_pickup_code(uuid) from public, anon, authenticated;

-- ============================================================
-- Réserver
-- ============================================================

create or replace function public.reservation_create(
  p_pharmacy_id uuid,
  p_items jsonb,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_pharmacy record;
  v_profile record;
  v_email text;
  v_auth_phone text;
  v_reservation_id uuid;
  v_item_id uuid;
  v_line record;
  v_product record;
  v_stock record;
  v_remaining integer;
  v_available integer;
  v_active integer;
  v_pending integer;
  v_total integer := 0;
begin
  if v_user_id is null then
    raise exception 'RES: connexion requise' using errcode = '42501';
  end if;

  select id, name, address, phone, status,
         reservation_max_active_per_patient as max_active,
         reservation_max_quantity_per_line as max_qty
    into v_pharmacy
    from public.pharmacies where id = p_pharmacy_id;
  if not found or v_pharmacy.status <> 'active' then
    raise exception 'RES: cette officine ne prend pas de reservation' using errcode = '22023';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'RES: une reservation doit contenir au moins un produit' using errcode = '22023';
  end if;

  -- Un patient à la fois : le décompte des réservations actives est fiable.
  perform pg_advisory_xact_lock(hashtext('reservation:' || v_user_id::text));

  -- Contrôle à l'usage : les boîtes des réservations dépassées sont libérées
  -- avant de compter le vendable.
  perform public.reservation_expire_overdue(p_pharmacy_id);

  select count(*) into v_active
    from public.reservations
    where patient_id = v_user_id and pharmacy_id = p_pharmacy_id
      and status in ('pending', 'confirmed', 'ready');
  if v_active >= v_pharmacy.max_active then
    raise exception 'RES: vous avez deja % reservations en cours dans cette officine (maximum %)',
      v_active, v_pharmacy.max_active using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_items) e
      where nullif(e->>'product_id', '') is null
  ) then
    raise exception 'RES: chaque ligne doit designer un produit' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) e
      group by e->>'product_id' having count(*) > 1
  ) then
    raise exception 'RES: un meme produit figure sur plusieurs lignes' using errcode = '22023';
  end if;

  select p.full_name, p.phone into v_profile from public.profiles p where p.id = v_user_id;
  select u.email, u.phone into v_email, v_auth_phone from auth.users u where u.id = v_user_id;

  select count(*) into v_pending
    from public.reservations
    where pharmacy_id = p_pharmacy_id and status in ('pending', 'confirmed', 'ready');

  -- Patient, échéance, prix et code de retrait fixés par le serveur.
  insert into public.reservations (
    patient_id, patient_name, patient_phone, patient_email,
    pharmacy_id, pharmacy_name, pharmacy_address, pharmacy_phone,
    reserved_at, pickup_deadline, status, total_price, qr_code_token, notes,
    queue_position, estimated_wait_minutes
  ) values (
    v_user_id,
    coalesce(nullif(btrim(v_profile.full_name), ''), v_email, v_profile.phone, v_auth_phone, 'Patient'),
    coalesce(v_profile.phone, v_auth_phone, ''),
    v_email,
    p_pharmacy_id, v_pharmacy.name, v_pharmacy.address, v_pharmacy.phone,
    now(), now() + interval '24 hours', 'pending', 0,
    public.reservation_new_pickup_code(p_pharmacy_id),
    nullif(btrim(p_notes), ''),
    v_pending + 1, 5 + v_pending * 3
  )
  returning id into v_reservation_id;

  -- Lignes traitées dans l'ordre des produits : deux réservations
  -- simultanées verrouillent les lots dans le même ordre.
  for v_line in
    select (e->>'product_id')::uuid as product_id, (e->>'quantity')::integer as quantity
      from jsonb_array_elements(p_items) e
      order by e->>'product_id'
  loop
    if v_line.quantity is null or v_line.quantity <= 0 then
      raise exception 'RES: quantite invalide' using errcode = '22023';
    end if;

    select p.id, p.name, p.generic_name, p.dosage, p.regulatory_class,
           p.is_prescription_required
      into v_product
      from public.products p where p.id = v_line.product_id;
    if not found then
      raise exception 'RES: produit % inconnu', v_line.product_id using errcode = '22023';
    end if;
    if v_product.regulatory_class in ('stupefiant', 'psychotrope') then
      raise exception 'RES: % ne peut pas etre reserve (stupefiant ou psychotrope) : presentez-vous a l''officine avec votre ordonnance',
        v_product.name using errcode = '22023';
    end if;
    if v_line.quantity > v_pharmacy.max_qty then
      raise exception 'RES: % : % boites au plus par reservation (demande %)',
        v_product.name, v_pharmacy.max_qty, v_line.quantity using errcode = '22023';
    end if;

    select si.id, si.unit_price into v_stock
      from public.stock_items si
      where si.pharmacy_id = p_pharmacy_id and si.product_id = v_line.product_id
        and si.status <> 'discontinued';
    if not found then
      raise exception 'RES: % n''est pas en stock dans cette officine', v_product.name
        using errcode = 'P0001';
    end if;
    if coalesce(v_stock.unit_price, 0) <= 0 then
      raise exception 'RES: prix de % non renseigne par l''officine', v_product.name
        using errcode = '22023';
    end if;

    insert into public.reservation_items (
      reservation_id, product_id, product_name, generic_name, dosage,
      price_per_unit, quantity, prescription_required
    ) values (
      v_reservation_id, v_product.id, v_product.name, v_product.generic_name, v_product.dosage,
      v_stock.unit_price, v_line.quantity,
      v_product.is_prescription_required or v_product.regulatory_class = 'sur_ordonnance'
    )
    returning id into v_item_id;

    v_remaining := public.reservation_hold_stock(v_reservation_id, v_item_id, v_stock.id, v_line.quantity);
    if v_remaining > 0 then
      v_available := v_line.quantity - v_remaining;
      raise exception 'RES: stock insuffisant pour % (demande %, disponible %)',
        v_product.name, v_line.quantity, v_available using errcode = 'P0001';
    end if;

    update public.reservation_items
      set stock_at_reservation = (
        select coalesce(sum(greatest(b.quantity - b.quantity_reserved, 0)), 0)
          from public.stock_batches b where b.stock_item_id = v_stock.id
      )
      where id = v_item_id;

    v_total := v_total + v_line.quantity * v_stock.unit_price;
  end loop;

  update public.reservations set total_price = v_total where id = v_reservation_id;
  return v_reservation_id;
end;
$$;

comment on function public.reservation_create(uuid, jsonb, text) is
  'C243 : réservation complète en une transaction : boîtes retenues lot par lot (péremption la plus proche, périmés et rappelés exclus, lots verrouillés), refus si le vendable ne suffit pas. Patient, prix (indicatif), échéance (24 h) et code de retrait fixés par le serveur. Limites par officine : réservations actives par patient, boîtes par ligne. Stupéfiants et psychotropes refusés.';

revoke all on function public.reservation_create(uuid, jsonb, text) from public, anon;
grant execute on function public.reservation_create(uuid, jsonb, text) to authenticated;

-- ============================================================
-- Prête, annulation, expiration à l'usage
-- ============================================================

create or replace function public.reservation_mark_ready(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_res record;
begin
  select pharmacy_id, status, pickup_deadline into v_res
    from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'RES: reservation % introuvable', p_reservation_id using errcode = 'P0002';
  end if;
  if auth.uid() is null or not public.is_pharmacy_staff(v_res.pharmacy_id) then
    raise exception 'RES: acces refuse a cette officine' using errcode = '42501';
  end if;
  if v_res.status not in ('pending', 'confirmed') then
    raise exception 'RES: seule une reservation en cours peut etre marquee prete (statut %)', v_res.status
      using errcode = '22023';
  end if;
  if v_res.pickup_deadline < now() then
    raise exception 'RES: reservation expiree (delai de retrait depasse)' using errcode = '22023';
  end if;
  update public.reservations set status = 'ready', ready_at = now() where id = p_reservation_id;
end;
$$;

comment on function public.reservation_mark_ready(uuid) is
  'C243 : passage à « prête » par le personnel de l''officine. L''échéance de retrait n''est pas prolongée.';

revoke all on function public.reservation_mark_ready(uuid) from public, anon;
grant execute on function public.reservation_mark_ready(uuid) to authenticated;

create or replace function public.reservation_cancel(p_reservation_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_res record;
  v_is_patient boolean;
  v_reason text := nullif(btrim(p_reason), '');
begin
  select patient_id, pharmacy_id, status into v_res
    from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'RES: reservation % introuvable', p_reservation_id using errcode = 'P0002';
  end if;
  v_is_patient := v_user_id is not null and v_res.patient_id = v_user_id;
  if v_user_id is null or not (v_is_patient or public.is_pharmacy_staff(v_res.pharmacy_id)) then
    raise exception 'RES: acces refuse a cette reservation' using errcode = '42501';
  end if;
  if v_res.status not in ('pending', 'confirmed', 'ready') then
    raise exception 'RES: cette reservation ne peut plus etre annulee (statut %)', v_res.status
      using errcode = '22023';
  end if;
  -- L'officine motive son annulation ; le patient n'y est pas tenu.
  if not v_is_patient and (v_reason is null or char_length(v_reason) < 3) then
    raise exception 'RES: motif d''annulation obligatoire' using errcode = '22023';
  end if;

  perform public.reservation_release_holds(p_reservation_id, null, null, 'Reservation annulee');
  update public.reservations
    set status = 'cancelled', cancelled_at = now(), cancelled_by = v_user_id,
        cancel_reason = v_reason, queue_position = 0, estimated_wait_minutes = 0
    where id = p_reservation_id;
end;
$$;

comment on function public.reservation_cancel(uuid, text) is
  'C243 : annulation par le patient (la sienne) ou par le personnel de l''officine (motif obligatoire) ; boîtes libérées, auteur et motif enregistrés.';

revoke all on function public.reservation_cancel(uuid, text) from public, anon;
grant execute on function public.reservation_cancel(uuid, text) to authenticated;

create or replace function public.reservation_expire_for_pharmacy(p_pharmacy_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'RES: acces refuse a cette officine' using errcode = '42501';
  end if;
  return public.reservation_expire_overdue(p_pharmacy_id);
end;
$$;

comment on function public.reservation_expire_for_pharmacy(uuid) is
  'C243 : expiration à l''usage, appelée au chargement de la file de l''officine par son personnel.';

revoke all on function public.reservation_expire_for_pharmacy(uuid) from public, anon;
grant execute on function public.reservation_expire_for_pharmacy(uuid) to authenticated;

-- ============================================================
-- Produits devenus indisponibles (lot rappelé ou périmé)
-- ============================================================

-- Sans officine : réservations actives de l'utilisateur connecté (patient).
-- Avec officine : réservations actives de l'officine (personnel).
-- Ne révèle ni lot ni rappel : seulement la ligne concernée.
create or replace function public.reservation_unavailable_items(p_pharmacy_id uuid default null)
returns table (
  reservation_id uuid,
  reservation_item_id uuid,
  product_name text
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
    raise exception 'RES: connexion requise' using errcode = '42501';
  end if;
  if p_pharmacy_id is not null and not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'RES: acces refuse a cette officine' using errcode = '42501';
  end if;

  return query
  select distinct r.id, ri.id, ri.product_name
    from public.reservations r
    join public.reservation_items ri on ri.reservation_id = r.id and ri.removed_at is null
    join public.reservation_item_batches h on h.reservation_item_id = ri.id and h.released_at is null
    join public.stock_batches b on b.id = h.batch_id
    where r.status in ('pending', 'confirmed', 'ready')
      and ((p_pharmacy_id is null and r.patient_id = auth.uid())
           or (p_pharmacy_id is not null and r.pharmacy_id = p_pharmacy_id))
      and (b.expiry_date < v_today or public.stock_batch_recall(b.id) is not null);
end;
$$;

comment on function public.reservation_unavailable_items(uuid) is
  'C243 : lignes de réservations actives dont une boîte retenue est sur un lot rappelé ou périmé (patient : les siennes ; personnel : celles de son officine). Aucun lot ni rappel révélé.';

revoke all on function public.reservation_unavailable_items(uuid) from public, anon;
grant execute on function public.reservation_unavailable_items(uuid) to authenticated;

-- ============================================================
-- Retrait : aperçu, puis vente au comptoir
-- ============================================================

create or replace function public.reservation_pickup_preview(p_reservation_id uuid)
returns table (
  reservation_item_id uuid,
  product_name text,
  dosage text,
  quantity integer,
  reserved_unit_price integer,
  current_unit_price integer,
  prescription_required boolean,
  unavailable_quantity integer
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_pharmacy_id uuid;
begin
  select r.pharmacy_id into v_pharmacy_id from public.reservations r where r.id = p_reservation_id;
  if not found then
    raise exception 'RES: reservation % introuvable', p_reservation_id using errcode = 'P0002';
  end if;
  if auth.uid() is null or not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'RES: acces refuse a cette officine' using errcode = '42501';
  end if;

  return query
  select ri.id, ri.product_name, ri.dosage, ri.quantity, ri.price_per_unit,
         si.unit_price,
         ri.prescription_required,
         -- Boîtes sur un lot rappelé ou périmé, moins ce qu'un autre lot
         -- vendable peut remplacer.
         greatest(coalesce(bad.qty, 0) - coalesce(spare.qty, 0), 0)::integer
    from public.reservation_items ri
    join public.stock_items si on si.pharmacy_id = v_pharmacy_id and si.product_id = ri.product_id
    left join lateral (
      select sum(h.quantity) as qty
        from public.reservation_item_batches h
        join public.stock_batches b on b.id = h.batch_id
        where h.reservation_item_id = ri.id and h.released_at is null
          and (b.expiry_date < v_today or public.stock_batch_recall(b.id) is not null)
    ) bad on true
    left join lateral (
      select sum(greatest(b.quantity - b.quantity_reserved, 0)) as qty
        from public.stock_batches b
        where b.stock_item_id = si.id and b.expiry_date >= v_today
          and public.stock_batch_recall(b.id) is null
    ) spare on true
    where ri.reservation_id = p_reservation_id and ri.removed_at is null
    order by ri.product_name, ri.id;
end;
$$;

comment on function public.reservation_pickup_preview(uuid) is
  'C243 : aperçu du retrait pour le personnel : par ligne, prix indicatif de la réservation, prix du jour (stock_items.unit_price), ordonnance à présenter, boîtes qui ne peuvent plus être remises (lot rappelé ou périmé sans remplaçant).';

revoke all on function public.reservation_pickup_preview(uuid) from public, anon;
grant execute on function public.reservation_pickup_preview(uuid) to authenticated;

create or replace function public.reservation_pickup(
  p_reservation_id uuid,
  p_pickup_code text,
  p_prescription_checked boolean default false,
  p_allow_partial boolean default false,
  p_partial_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_res record;
  v_item record;
  v_hold record;
  v_missing integer;
  v_items jsonb := '[]'::jsonb;
  v_total integer := 0;
  v_sale_id uuid;
  v_partial_reason text := nullif(btrim(p_partial_reason), '');
begin
  -- Verrou sur la réservation : deux retraits simultanés se sérialisent.
  select id, patient_id, pharmacy_id, status, pickup_deadline, qr_code_token into v_res
    from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'RES: reservation % introuvable', p_reservation_id using errcode = 'P0002';
  end if;
  if v_user_id is null or not public.is_pharmacy_staff(v_res.pharmacy_id) then
    raise exception 'RES: acces refuse a cette officine' using errcode = '42501';
  end if;
  if v_res.status not in ('pending', 'confirmed', 'ready') then
    raise exception 'RES: cette reservation ne peut pas etre retiree (statut %)', v_res.status
      using errcode = '22023';
  end if;
  if v_res.pickup_deadline < now() then
    raise exception 'RES: reservation expiree (delai de retrait depasse)' using errcode = '22023';
  end if;
  -- Code de retrait du patient, saisi ou lu sur son QR : espaces et casse
  -- ignorés. Sans le bon code, rien n'est remis.
  if v_res.qr_code_token is null
     or upper(regexp_replace(coalesce(p_pickup_code, ''), '\s', '', 'g')) <> upper(v_res.qr_code_token) then
    raise exception 'RES: code de retrait incorrect' using errcode = '22023';
  end if;

  for v_item in
    select ri.id, ri.product_id, ri.product_name, ri.quantity, ri.prescription_required,
           si.id as stock_item_id, si.unit_price
      from public.reservation_items ri
      join public.stock_items si on si.pharmacy_id = v_res.pharmacy_id and si.product_id = ri.product_id
      where ri.reservation_id = p_reservation_id and ri.removed_at is null
      order by ri.product_id
  loop
    -- Lot rappelé ou périmé depuis la réservation : la retenue est levée et
    -- un autre lot vendable est cherché.
    v_missing := 0;
    for v_hold in
      select h.id, h.quantity
        from public.reservation_item_batches h
        join public.stock_batches b on b.id = h.batch_id
        where h.reservation_item_id = v_item.id and h.released_at is null
          and (b.expiry_date < v_today or public.stock_batch_recall(b.id) is not null)
    loop
      perform public.reservation_release_holds(p_reservation_id, v_item.id, v_hold.id,
        'Lot rappele ou perime avant le retrait');
      v_missing := v_missing + v_hold.quantity;
    end loop;

    if v_missing > 0 then
      v_missing := public.reservation_hold_stock(p_reservation_id, v_item.id, v_item.stock_item_id, v_missing);
      if v_missing > 0 then
        if not coalesce(p_allow_partial, false) then
          raise exception 'RES: % ne peut plus etre remis (lot rappele ou perime, aucun autre lot) : proposez un retrait partiel ou annulez la reservation',
            v_item.product_name using errcode = 'P0001';
        end if;
        if v_partial_reason is null or char_length(v_partial_reason) < 3 then
          raise exception 'RES: motif du retrait partiel obligatoire' using errcode = '22023';
        end if;
        perform public.reservation_release_holds(p_reservation_id, v_item.id, null,
          'Ligne retiree : retrait partiel');
        update public.reservation_items
          set removed_at = now(), removed_reason = v_partial_reason
          where id = v_item.id;
        continue;
      end if;
    end if;

    -- Une ligne de vente par lot retenu, au prix du jour (C218).
    for v_hold in
      select h.batch_id, sum(h.quantity)::integer as quantity
        from public.reservation_item_batches h
        where h.reservation_item_id = v_item.id and h.released_at is null
        group by h.batch_id
        order by h.batch_id
    loop
      v_items := v_items || jsonb_build_object(
        'product_id', v_item.product_id,
        'product_name', v_item.product_name,
        'quantity', v_hold.quantity,
        'unit_price', v_item.unit_price,
        'total_price', v_hold.quantity * v_item.unit_price,
        'batch_id', v_hold.batch_id,
        'prescription_checked', v_item.prescription_required and coalesce(p_prescription_checked, false)
      );
      v_total := v_total + v_hold.quantity * v_item.unit_price;
    end loop;
  end loop;

  if jsonb_array_length(v_items) = 0 then
    raise exception 'RES: aucun produit ne peut etre remis : annulez la reservation' using errcode = '22023';
  end if;

  -- Pas de double compte : la retenue est levée et les mêmes lots sont
  -- vendus dans la même transaction. Si la vente échoue (caisse fermée,
  -- prix non renseigné…), tout est annulé et la retenue reste en place.
  perform public.reservation_release_holds(p_reservation_id, null, null, 'Retrait a l''officine');
  v_sale_id := public.pos_create_sale(
    v_res.pharmacy_id, 'cash', v_total, 0, 0, v_total, v_items, v_res.patient_id,
    'Retrait de la reservation ' || p_reservation_id::text
  );

  update public.reservations
    set status = 'pickedUp', picked_up_at = now(), pos_sale_id = v_sale_id,
        total_price = v_total, queue_position = 0, estimated_wait_minutes = 0
    where id = p_reservation_id;
  return v_sale_id;
end;
$$;

comment on function public.reservation_pickup(uuid, text, boolean, boolean, text) is
  'C243 : retrait à l''officine : la réservation devient une vente au comptoir en espèces (pos_create_sale) sur les lots retenus, au prix du jour, dans une seule transaction ; retenue levée et stock sorti une seule fois. Lot rappelé ou périmé : autre lot cherché ; sans remplaçant, refus ou retrait partiel motivé. Code de retrait du patient exigé. Réservée au personnel de l''officine ; caisse ouverte exigée (D62).';

revoke all on function public.reservation_pickup(uuid, text, boolean, boolean, text) from public, anon;
grant execute on function public.reservation_pickup(uuid, text, boolean, boolean, text) to authenticated;

-- ============================================================
-- Vente au comptoir : un lot désigné n'est vendable que hors boîtes retenues
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
  'C197 / C203 / C201 / C218 / C205 / C240 / C243 : vente POS complète en une transaction (vente, lignes, mouvements de stock, reçu). Lots choisis par le serveur, prix du stock imposé, ordonnance tracée. C205 / D62 : vente en espèces seulement avec une caisse ouverte du vendeur. C240 : lot rappelé refusé ou écarté. C243 : un lot désigné n''est vendable que hors boîtes retenues par une réservation.';

-- ============================================================
-- Tâche planifiée : expiration toutes les 15 minutes
-- ============================================================
-- Préparée ici ; sans effet (simple avis) si pg_cron n'est pas disponible.
-- Le contrôle à l'usage (reservation_create, file de l'officine) couvre
-- l'expiration même sans tâche planifiée.

do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule(jobid) from cron.job where jobname = 'reservation-expire-overdue';
  perform cron.schedule(
    'reservation-expire-overdue',
    '*/15 * * * *',
    'select public.reservation_expire_overdue()'
  );
exception when others then
  raise notice 'C243 : tache planifiee non creee (pg_cron indisponible : %) ; expiration assuree par le controle a l''usage', sqlerrm;
end $$;
