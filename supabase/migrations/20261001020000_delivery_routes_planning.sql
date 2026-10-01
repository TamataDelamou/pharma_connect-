-- C221 (décision D66) : planification des tournées de livraison.
--
-- Aucune règle n'autorisait la création d'une tournée (delivery_routes) ni de
-- ses arrêts (route_stops) : DeliveryService.planRoute() était refusé par le
-- serveur. Le livreur pouvait en revanche modifier toutes les colonnes de sa
-- tournée et de ses arrêts (adresse, livraison, ordre).
--
-- D66 : le personnel d'une officine active crée une tournée avec ses propres
-- livraisons et choisit le livreur ; GSG peut tout faire ; le livreur suit
-- la tournée et coche les arrêts.
--
-- Mise en œuvre :
--   - delivery_create_route(livreur, date, livraisons dans l'ordre) et
--     delivery_cancel_route(tournée), SECURITY DEFINER ;
--   - plus d'écriture directe sur delivery_routes / route_stops, sauf le
--     statut de la tournée et l'arrêt effectué, pour le livreur.

-- ============================================================
-- 1. Création
-- ============================================================
create or replace function public.delivery_create_route(
  p_driver_id uuid,
  p_date date,
  p_delivery_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       uuid := auth.uid();
  v_admin     boolean := public.is_gsg_admin();
  v_driver    public.delivery_drivers%rowtype;
  v_route_id  uuid;
  v_count     integer;
  v_d         record;
  v_order     integer := 0;
begin
  if v_uid is null then
    raise exception 'TOURNEE: connexion requise' using errcode = '42501';
  end if;
  if not v_admin and not public.is_any_pharmacy_staff() then
    raise exception 'TOURNEE: reserve au personnel d''une officine validee et a GSG' using errcode = '42501';
  end if;
  if p_date is null or p_delivery_ids is null or cardinality(p_delivery_ids) = 0 then
    raise exception 'TOURNEE: date et livraisons obligatoires' using errcode = '22023';
  end if;
  if (select count(distinct x) from unnest(p_delivery_ids) x) <> cardinality(p_delivery_ids) then
    raise exception 'TOURNEE: une livraison figure deux fois' using errcode = '22023';
  end if;

  select * into v_driver from public.delivery_drivers where id = p_driver_id;
  if not found then
    raise exception 'TOURNEE: livreur introuvable' using errcode = '22023';
  end if;

  -- Toutes les livraisons doivent exister et, hors GSG, appartenir à une
  -- réservation d'une officine où l'appelant travaille. Même refus dans les
  -- deux cas : pas d'indication sur l'existence de livraisons d'autres
  -- officines.
  select count(*) into v_count
    from public.deliveries d
    left join public.reservations r on r.id = d.reservation_id
   where d.id = any (p_delivery_ids)
     and (v_admin or (r.pharmacy_id is not null and public.is_pharmacy_staff(r.pharmacy_id)));
  if v_count <> cardinality(p_delivery_ids) then
    raise exception 'TOURNEE: livraison introuvable ou d''une autre officine' using errcode = '42501';
  end if;

  for v_d in
    select d.*, u.ord
      from unnest(p_delivery_ids) with ordinality u(id, ord)
      join public.deliveries d on d.id = u.id
     order by u.ord
     for update of d
  loop
    if v_d.status in ('delivered', 'cancelled') then
      raise exception 'TOURNEE: la livraison % est deja terminee ou annulee', v_d.id using errcode = '22023';
    end if;
    if v_d.driver_id is not null and v_d.driver_id <> p_driver_id then
      raise exception 'TOURNEE: la livraison % est confiee a un autre livreur', v_d.id using errcode = '22023';
    end if;
    -- RG-LIV-01 : chaîne du froid réservée à un livreur certifié.
    if v_d.is_cold_chain_required and not v_driver.is_cold_chain_certified then
      raise exception 'TOURNEE: la livraison % exige un livreur certifie chaine du froid', v_d.id using errcode = '22023';
    end if;
    if exists (select 1 from public.route_stops s
                join public.delivery_routes r on r.id = s.route_id
               where s.delivery_id = v_d.id and r.status in ('planned', 'inProgress')) then
      raise exception 'TOURNEE: la livraison % figure deja dans une tournee en cours', v_d.id using errcode = '22023';
    end if;
  end loop;

  insert into public.delivery_routes (driver_id, date, status)
  values (p_driver_id, p_date, 'planned')
  returning id into v_route_id;

  for v_d in
    select d.*, u.ord
      from unnest(p_delivery_ids) with ordinality u(id, ord)
      join public.deliveries d on d.id = u.id
     order by u.ord
  loop
    v_order := v_order + 1;
    -- Coordonnées inconnues : centre de Conakry, comme le faisait déjà
    -- DeliveryService.planRoute() (route_stops exige des coordonnées).
    insert into public.route_stops (route_id, delivery_id, latitude, longitude, address, stop_order)
    values (v_route_id, v_d.id, coalesce(v_d.latitude, 9.5), coalesce(v_d.longitude, -13.7),
            v_d.delivery_address, v_order);
    update public.deliveries set driver_id = p_driver_id
     where id = v_d.id and driver_id is null;
  end loop;

  return v_route_id;
end;
$$;

comment on function public.delivery_create_route(uuid, date, uuid[]) is
  'C221 / D66 : crée une tournée (livreur, date, livraisons dans l''ordre de passage). Personnel d''une officine active pour ses propres livraisons, ou GSG. Livraisons non terminées, non confiées à un autre livreur, absentes de toute tournée en cours ; chaîne du froid : livreur certifié. Les livraisons sans livreur lui sont confiées.';

revoke all on function public.delivery_create_route(uuid, date, uuid[]) from public, anon;
grant execute on function public.delivery_create_route(uuid, date, uuid[]) to authenticated;

-- ============================================================
-- 2. Annulation
-- ============================================================
create or replace function public.delivery_cancel_route(p_route_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_route public.delivery_routes%rowtype;
begin
  if auth.uid() is null then
    raise exception 'TOURNEE: connexion requise' using errcode = '42501';
  end if;

  select * into v_route from public.delivery_routes where id = p_route_id for update;

  -- GSG, ou personnel d'une officine dont toutes les livraisons de la
  -- tournée relèvent.
  if not found or not (
       public.is_gsg_admin()
       or (exists (select 1 from public.route_stops s where s.route_id = p_route_id)
           and not exists (
             select 1 from public.route_stops s
               join public.deliveries d on d.id = s.delivery_id
               left join public.reservations r on r.id = d.reservation_id
              where s.route_id = p_route_id
                and not (r.pharmacy_id is not null and public.is_pharmacy_staff(r.pharmacy_id))))) then
    raise exception 'TOURNEE: tournee introuvable ou d''une autre officine' using errcode = '42501';
  end if;

  if v_route.status <> 'planned' then
    raise exception 'TOURNEE: seule une tournee planifiee (non commencee) peut etre annulee' using errcode = '22023';
  end if;

  update public.delivery_routes set status = 'cancelled' where id = p_route_id;
end;
$$;

comment on function public.delivery_cancel_route(uuid) is
  'C221 / D66 : annule une tournée planifiée (non commencée). GSG, ou personnel de l''officine de toutes ses livraisons.';

revoke all on function public.delivery_cancel_route(uuid) from public, anon;
grant execute on function public.delivery_cancel_route(uuid) to authenticated;

-- ============================================================
-- 3. Écritures directes
-- ============================================================
-- Le livreur ne change que le statut de sa tournée et l'arrêt effectué.
revoke insert, update, delete, truncate on public.delivery_routes, public.route_stops from anon, authenticated;
grant update (status) on public.delivery_routes to authenticated;
grant update (is_completed) on public.route_stops to authenticated;

-- Une tournée annulée n'est plus modifiable par le livreur.
drop policy if exists "delivery_routes_update_own_driver" on public.delivery_routes;
create policy "delivery_routes_update_own_driver" on public.delivery_routes
  for update to authenticated
  using (status <> 'cancelled' and public.is_delivery_driver(driver_id))
  with check (status <> 'cancelled' and public.is_delivery_driver(driver_id));

drop policy if exists "route_stops_update_own_driver" on public.route_stops;
create policy "route_stops_update_own_driver" on public.route_stops
  for update to authenticated
  using (public.is_delivery_driver(
           (select r.driver_id from public.delivery_routes r where r.id = route_stops.route_id)))
  with check (public.is_delivery_driver(
           (select r.driver_id from public.delivery_routes r where r.id = route_stops.route_id)));
