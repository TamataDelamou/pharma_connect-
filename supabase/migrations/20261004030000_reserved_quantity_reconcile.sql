-- C243 (suite) : boîtes réservées fantômes.
--
-- Constat (lecture seule en production, 04/10/2026) : 98 lots sur 120 portent
-- une quantité réservée non nulle (640 boîtes) alors qu'aucune réservation
-- n'existe ; même total sur stock_items.reserved_quantity. Ces boîtes, venues
-- du jeu de données d'origine, sont exclues du disponible (vente au comptoir
-- par produit, disponibilité patient, réservation).
--
-- Décision d'Achille du 04/10/2026 : remise à zéro, après sauvegarde.
--
-- Cette migration :
--   - crée une table de sauvegarde datée, lisible par GSG seul ;
--   - ajoute stock_reconcile_reserved() (interne) : sauvegarde, puis remet la
--     quantité réservée de chaque lot et de chaque article au total des
--     boîtes réellement retenues par une réservation active
--     (reservation_item_batches) ; quantités physiques inchangées ;
--   - l'exécute une fois ;
--   - ferme l'écriture directe de la quantité réservée par l'application : la
--     règle d'écriture du personnel (stock_items_write_staff,
--     stock_batches_write_staff) laissait modifier cette colonne ; seules les
--     fonctions de réservation l'écrivent désormais.
-- Aucune migration existante n'est modifiée.

-- ============================================================
-- Sauvegarde
-- ============================================================

create table if not exists public.stock_reserved_backup_20261004 (
  source_table text not null check (source_table in ('stock_batches', 'stock_items')),
  row_id uuid not null,
  reserved integer not null,
  quantity integer not null,
  saved_at timestamptz not null default now(),
  primary key (source_table, row_id)
);

comment on table public.stock_reserved_backup_20261004 is
  'C243 : quantité réservée de chaque lot (stock_batches.quantity_reserved) et de chaque article (stock_items.reserved_quantity) avant la remise à zéro des boîtes réservées fantômes du 04/10/2026. quantity : quantité physique au même moment, pour mémoire. Lecture GSG seule, aucune écriture.';

alter table public.stock_reserved_backup_20261004 enable row level security;

create policy "stock_reserved_backup_20261004_gsg_select" on public.stock_reserved_backup_20261004
  for select to authenticated
  using (public.is_gsg_admin());

revoke all on public.stock_reserved_backup_20261004 from anon;

-- ============================================================
-- Remise au total réellement retenu
-- ============================================================

create or replace function public.stock_reconcile_reserved()
returns table (batches_fixed integer, items_fixed integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batches integer;
  v_items integer;
begin
  -- Lots verrouillés : ni vente ni réservation pendant le calcul.
  perform 1 from public.stock_batches order by id for update;

  -- Boîtes réellement retenues, lot par lot, par une réservation active.
  create temp table tmp_held on commit drop as
    select b.id as batch_id, b.stock_item_id,
           coalesce((
             select sum(h.quantity)
               from public.reservation_item_batches h
               join public.reservation_items ri on ri.id = h.reservation_item_id
               join public.reservations r on r.id = ri.reservation_id
               where h.batch_id = b.id and h.released_at is null
                 and r.status in ('pending', 'confirmed', 'ready')
           ), 0)::integer as held
      from public.stock_batches b;

  -- Sauvegarde avant toute modification. Une valeur déjà sauvegardée est
  -- conservée : la table garde l'état d'origine.
  insert into public.stock_reserved_backup_20261004 (source_table, row_id, reserved, quantity)
    select 'stock_batches', b.id, b.quantity_reserved, b.quantity
      from public.stock_batches b
      join tmp_held t on t.batch_id = b.id
      where b.quantity_reserved <> t.held
    on conflict (source_table, row_id) do nothing;

  insert into public.stock_reserved_backup_20261004 (source_table, row_id, reserved, quantity)
    select 'stock_items', si.id, si.reserved_quantity, si.total_quantity
      from public.stock_items si
      where si.reserved_quantity <> coalesce(
        (select sum(t.held) from tmp_held t where t.stock_item_id = si.id), 0)
    on conflict (source_table, row_id) do nothing;

  update public.stock_batches b
    set quantity_reserved = t.held
    from tmp_held t
    where t.batch_id = b.id and b.quantity_reserved <> t.held;
  get diagnostics v_batches = row_count;

  update public.stock_items si
    set reserved_quantity = coalesce(
      (select sum(t.held) from tmp_held t where t.stock_item_id = si.id), 0)
    where si.reserved_quantity <> coalesce(
      (select sum(t.held) from tmp_held t where t.stock_item_id = si.id), 0);
  get diagnostics v_items = row_count;

  drop table tmp_held;
  return query select v_batches, v_items;
end;
$$;

comment on function public.stock_reconcile_reserved() is
  'C243 : remet la quantité réservée de chaque lot et de chaque article au total des boîtes réellement retenues par une réservation active, après sauvegarde dans stock_reserved_backup_20261004. Quantités physiques inchangées. Interne : fermée aux clients.';

revoke all on function public.stock_reconcile_reserved() from public, anon, authenticated;

-- ============================================================
-- La quantité réservée n'est plus écrite directement
-- ============================================================
-- Les fonctions de réservation (SECURITY DEFINER) écrivent sous le rôle de
-- leur propriétaire ; un appel direct de l'application écrit sous le rôle
-- authenticated (ou anon) et est refusé ici.

create or replace function public.stock_guard_reserved()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if tg_table_name = 'stock_batches' then
    if (tg_op = 'INSERT' and new.quantity_reserved <> 0)
       or (tg_op = 'UPDATE' and new.quantity_reserved is distinct from old.quantity_reserved) then
      raise exception 'STK: la quantite reservee d''un lot est geree par les reservations'
        using errcode = '42501';
    end if;
  else
    if (tg_op = 'INSERT' and new.reserved_quantity <> 0)
       or (tg_op = 'UPDATE' and new.reserved_quantity is distinct from old.reserved_quantity) then
      raise exception 'STK: la quantite reservee d''un article est geree par les reservations'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.stock_guard_reserved() is
  'C243 : refuse toute écriture directe (rôle authenticated ou anon) de stock_batches.quantity_reserved et de stock_items.reserved_quantity ; seules les fonctions de réservation les écrivent.';

drop trigger if exists stock_batches_guard_reserved on public.stock_batches;
create trigger stock_batches_guard_reserved
  before insert or update on public.stock_batches
  for each row execute function public.stock_guard_reserved();

drop trigger if exists stock_items_guard_reserved on public.stock_items;
create trigger stock_items_guard_reserved
  before insert or update on public.stock_items
  for each row execute function public.stock_guard_reserved();

-- ============================================================
-- Exécution
-- ============================================================

do $$
declare
  v record;
begin
  select * into v from public.stock_reconcile_reserved();
  raise notice 'C243 : quantite reservee remise au total retenu sur % lots et % articles', v.batches_fixed, v.items_fixed;
end;
$$;
