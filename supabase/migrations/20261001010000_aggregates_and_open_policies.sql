-- C220 (décision D65) : données agrégées et règles d'accès ouvertes à tous.
--
-- Inventaire du 01/10/2026 (vues, vues précalculées, règles « true ») :
--   1. Les vues précalculées d'analyse (daily_stats, pharmacies_performance,
--      products_performance, top_products) ont été retirées aux utilisateurs
--      connectés le 05/09/2026 (20260905070000), mais pas au rôle anonyme :
--      la clé anonyme, livrée dans l'application, suffisait pour lire le
--      chiffre d'affaires de chaque officine, les prix moyens et les stocks.
--      Les vues filtrées (*_scoped) étaient elles aussi ouvertes à anon.
--   2. professional_stats (vue précalculée) : nombre de patients et de
--      consultations de chaque médecin et pharmacien, lisible par tous.
--   3. route_stops : adresse et coordonnées GPS de chaque arrêt de livraison
--      (domicile des patients), lisibles par tout utilisateur connecté.
--   4. delivery_drivers : téléphone et position GPS en direct de chaque
--      livreur, lisibles par tout utilisateur connecté ; delivery_routes de
--      même.
--   5. admin_users : nom, e-mail, téléphone et permissions des administrateurs
--      GSG, lisibles par tout utilisateur connecté.
--   6. system_configs : paramètres système lisibles par tout utilisateur
--      connecté (seul le back-office GSG les utilise).
--   7. family_alerts : la mise à jour par un membre de la famille n'avait
--      aucun contrôle sur la nouvelle ligne (with check true) : une alerte
--      pouvait être déplacée vers le lien familial d'une autre famille.
--   8. solidarity_impact et loyalty_leaderboard : lisibles sans compte.
--
-- D65 :
--   - livreurs : visibles par eux-mêmes, GSG, le personnel des officines
--     actives (pour choisir un livreur) et le patient pendant sa propre
--     livraison en cours ;
--   - statistiques des professionnels : note moyenne et nombre d'avis publics
--     pour les professionnels vérifiés (et les pharmaciens d'une officine
--     active) ; nombre de patients et de consultations réservés à
--     l'intéressé et à GSG ;
--   - bilans de solidarité et classement de fidélité : utilisateurs connectés.

-- ============================================================
-- 1. Analyse : rien pour anon
-- ============================================================
revoke all on public.daily_stats, public.pharmacies_performance,
              public.products_performance, public.top_products,
              public.network_dashboard
  from anon, authenticated;

revoke all on public.daily_stats_scoped, public.pharmacies_performance_scoped,
              public.products_performance_scoped, public.top_products_scoped,
              public.network_dashboard_scoped, public.adverse_reactions_anonymized
  from anon;
revoke insert, update, delete, truncate, references, trigger
  on public.daily_stats_scoped, public.pharmacies_performance_scoped,
     public.products_performance_scoped, public.top_products_scoped,
     public.network_dashboard_scoped, public.adverse_reactions_anonymized
  from authenticated;
grant select on public.daily_stats_scoped, public.pharmacies_performance_scoped,
                public.products_performance_scoped, public.top_products_scoped,
                public.network_dashboard_scoped, public.adverse_reactions_anonymized
  to authenticated;

-- Rafraîchissement des vues précalculées : réservé au serveur.
revoke all on function public.refresh_analytics_views() from public, anon, authenticated;
revoke all on function public.refresh_professional_stats() from public, anon, authenticated;
revoke all on function public.refresh_network_dashboard() from public, anon, authenticated;

-- ============================================================
-- 2. Statistiques des professionnels
-- ============================================================
revoke all on public.professional_stats from anon, authenticated;

create or replace view public.professional_stats_public
with (security_barrier = true) as
select s.professional_id,
       s.total_reviews,
       s.avg_rating,
       case when s.professional_id = auth.uid() or public.is_gsg_admin()
            then s.total_consultations end as total_consultations,
       case when s.professional_id = auth.uid() or public.is_gsg_admin()
            then s.total_patients end as total_patients
  from public.professional_stats s
  join public.profiles p on p.id = s.professional_id
 where s.professional_id = auth.uid()
    or public.is_gsg_admin()
    or (p.role = 'professionnel' and exists (
          select 1 from public.professional_profiles pp
           where pp.id = p.id and pp.is_verified))
    or (p.role = 'pharmacien' and exists (
          select 1 from public.pharmacies ph
           where ph.id = p.pharmacy_id and ph.status in ('verified', 'active')));

comment on view public.professional_stats_public is
  'C220 / D65 : note moyenne et nombre d''avis des professionnels vérifiés et des pharmaciens d''une officine active (public) ; nombre de consultations et de patients visibles seulement par l''intéressé et GSG (null sinon). Remplace la lecture directe de professional_stats.';

revoke all on public.professional_stats_public from public, anon, authenticated;
grant select on public.professional_stats_public to anon, authenticated;

-- ============================================================
-- 3 et 4. Livraisons : arrêts, tournées, livreurs
-- ============================================================
-- Fonctions SECURITY DEFINER : évitent la récursion entre les règles de
-- deliveries (qui lisent delivery_drivers) et celles de delivery_drivers.

create or replace function public.can_view_delivery(p_delivery_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
    public.is_gsg_admin()
    or exists (
      select 1 from public.deliveries d
       left join public.delivery_drivers dd on dd.id = d.driver_id
       left join public.reservations r on r.id = d.reservation_id
       where d.id = p_delivery_id
         and (d.patient_id = auth.uid()
              or dd.user_id = auth.uid()
              or (r.pharmacy_id is not null and public.is_pharmacy_staff(r.pharmacy_id)))
    )
  );
$$;

comment on function public.can_view_delivery(uuid) is
  'C220 / D65 : vrai pour GSG, le patient livré, le livreur assigné et le personnel de l''officine de la réservation.';

revoke all on function public.can_view_delivery(uuid) from public, anon;
grant execute on function public.can_view_delivery(uuid) to authenticated;

create or replace function public.can_view_delivery_driver(p_driver_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
    public.is_gsg_admin()
    or exists (select 1 from public.delivery_drivers dd
                where dd.id = p_driver_id and dd.user_id = auth.uid())
    or public.is_any_pharmacy_staff()
    or exists (select 1 from public.deliveries d
                where d.driver_id = p_driver_id
                  and d.patient_id = auth.uid()
                  and d.status in ('scheduled', 'preparing', 'inProgress', 'arrived'))
  );
$$;

comment on function public.can_view_delivery_driver(uuid) is
  'C220 / D65 : vrai pour GSG, le livreur lui-même, le personnel d''une officine active (choix du livreur) et le patient pendant sa propre livraison en cours.';

revoke all on function public.can_view_delivery_driver(uuid) from public, anon;
grant execute on function public.can_view_delivery_driver(uuid) to authenticated;

drop policy if exists "delivery_drivers_select_authenticated" on public.delivery_drivers;
create policy "delivery_drivers_select_scoped" on public.delivery_drivers
  for select to authenticated
  using (public.can_view_delivery_driver(id));

create or replace function public.can_view_delivery_route(p_route_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
    public.is_gsg_admin()
    or exists (select 1 from public.delivery_routes r
                join public.delivery_drivers dd on dd.id = r.driver_id
               where r.id = p_route_id and dd.user_id = auth.uid())
    or exists (select 1 from public.route_stops s
                where s.route_id = p_route_id
                  and s.delivery_id is not null
                  and public.can_view_delivery(s.delivery_id))
  );
$$;

comment on function public.can_view_delivery_route(uuid) is
  'C220 / D65 : vrai pour GSG, le livreur de la tournée et quiconque peut voir une des livraisons de la tournée.';

revoke all on function public.can_view_delivery_route(uuid) from public, anon;
grant execute on function public.can_view_delivery_route(uuid) to authenticated;

drop policy if exists "delivery_routes_select_authenticated" on public.delivery_routes;
create policy "delivery_routes_select_scoped" on public.delivery_routes
  for select to authenticated
  using (public.can_view_delivery_route(id));

-- Un arrêt : le livreur de la tournée et GSG voient tous les arrêts ; les
-- autres ne voient que les arrêts des livraisons qu'ils peuvent voir.
drop policy if exists "route_stops_select_authenticated" on public.route_stops;
create policy "route_stops_select_scoped" on public.route_stops
  for select to authenticated
  using (
    public.is_gsg_admin()
    or public.is_delivery_driver(
         (select r.driver_id from public.delivery_routes r where r.id = route_stops.route_id))
    or (delivery_id is not null and public.can_view_delivery(delivery_id))
  );

-- ============================================================
-- 5 et 6. Administration GSG
-- ============================================================
drop policy if exists "admin_users_select_authenticated" on public.admin_users;
create policy "admin_users_select_self_or_admin" on public.admin_users
  for select to authenticated
  using (user_id = auth.uid() or public.is_gsg_admin());

drop policy if exists "system_configs_select_authenticated" on public.system_configs;
create policy "system_configs_select_admin" on public.system_configs
  for select to authenticated
  using (public.is_gsg_admin());

-- ============================================================
-- 7. Alertes familiales
-- ============================================================
drop policy if exists "Family members can update alerts" on public.family_alerts;
create policy "Family members can update alerts" on public.family_alerts
  for update
  using (exists (select 1 from public.family_links
                  where family_links.id = family_alerts.family_link_id
                    and family_links.family_member_id = auth.uid()
                    and family_links.status = 'active'))
  with check (exists (select 1 from public.family_links
                       where family_links.id = family_alerts.family_link_id
                         and family_links.family_member_id = auth.uid()
                         and family_links.status = 'active'));

-- ============================================================
-- 8. Bilans de solidarité et classement de fidélité
-- ============================================================
revoke all on public.solidarity_impact from anon;
revoke insert, update, delete, truncate, references, trigger
  on public.solidarity_impact from authenticated;
grant select on public.solidarity_impact to authenticated;

drop policy if exists "Everyone view leaderboard" on public.loyalty_leaderboard;
create policy "Authenticated view leaderboard" on public.loyalty_leaderboard
  for select to authenticated
  using (true);
