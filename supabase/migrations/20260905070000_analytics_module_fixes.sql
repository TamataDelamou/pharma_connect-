-- Correctifs Module 28 (BI — Analytics & Business Intelligence), Étape 2/3
-- (Audit du 05/09/2026, PharmaConnect_Module28_Audit_BI.md).
--
-- BI-1 (Critique) : les 4 vues matérialisées du module (`daily_stats`,
-- `pharmacies_performance`, `products_performance`, `top_products`) ne
-- peuvent, par construction PostgreSQL, porter aucune RLS — et étaient
-- accordées en lecture à tout compte `authenticated` sans restriction,
-- exposant nommément le chiffre d'affaires de chaque officine du réseau à
-- n'importe quel compte, patient inclus. Corrigé selon le même principe que
-- REG-5 (`adverse_reactions_anonymized`) : les vues matérialisées brutes sont
-- reprises à `authenticated`, et remplacées par des vues classiques
-- « scoped » dont la clause WHERE elle-même fait office de garde d'accès
-- (une vue simple, contrairement à une vue matérialisée, peut porter un
-- filtre réévalué à chaque appel — ce n'est pas de la RLS au sens strict de
-- Postgres, mais le même mécanisme de rempart que celui déjà validé pour
-- REG-5).
--
-- BI-2 (fonctionnalité clé cahier absente) : profité de ce correctif pour
-- construire la donnée manquante du « Tableau de bord officine » (1ère
-- fonctionnalité clé BI) — une fonction scopée par officine,
-- `get_pharmacy_daily_stats()`, plutôt qu'une nouvelle vue matérialisée non
-- rafraîchissable en temps réel.
--
-- BI-3/C88 : les 4 vues matérialisées n'avaient aucun index unique, ce qui
-- aurait fait échouer `refresh materialized view concurrently` au premier
-- appel réel (signalé au registre depuis le Module 19/INF, jamais corrigé).
-- Corrigé ici, dans le périmètre auquel ces 4 vues appartiennent en totalité.
--
-- BI-4/C88 : `r.status = 'picked_up'` (snake_case) ne correspondait à aucune
-- valeur réelle de `reservations.status` (contrainte CHECK réelle :
-- 'pickedUp', camelCase) — corrigé en même temps que la reconstruction des
-- vues qu'impose BI-1.
--
-- BI-5 (Critique) : même motif « rôle inatteignable » que dans >15 modules
-- (`role in ('admin','staff')`, valeurs jamais autorisées par la contrainte
-- CHECK de profiles.role) sur les policies d'écriture de
-- `forecast_predictions`/`forecast_historical_data`/`forecast_alerts`,
-- combiné à une lecture ouverte à tout compte authentifié sans scoping
-- pharmacie (`auth.role() = 'authenticated'`). Corrigé par le même modèle
-- que `pharmacies_performance_scoped` : `is_gsg_admin()` pour l'accès
-- réseau complet, `is_pharmacy_staff(pharmacy_id)` pour la gestion des
-- prévisions propres à une officine, lecture des prévisions globales
-- (pharmacy_id null) ouverte à tout membre du personnel officine.
--
-- Défaut supplémentaire trouvé en cours de validation par exécution réelle,
-- non identifié à l'ouverture (même méthodologie que CHN-5-bis/C88) :
-- `forecast_accuracy` avait RLS activée (`enable row level security`) mais
-- AUCUNE policy définie — inaccessible en pratique à tout rôle non
-- superutilisateur, y compris `is_gsg_admin()`. Corrigé ici (BI-12).

begin;

-- ==================== BI-1/BI-3/BI-4 : reconstruction des 4 vues ====================
-- Ordre de suppression : dans l'ordre inverse des dépendances
-- (top_products dépend de products_performance).

drop view if exists public.top_products_scoped;
drop view if exists public.products_performance_scoped;
drop view if exists public.pharmacies_performance_scoped;
drop view if exists public.daily_stats_scoped;

drop materialized view if exists public.top_products;
drop materialized view if exists public.products_performance;
drop materialized view if exists public.pharmacies_performance;
drop materialized view if exists public.daily_stats;

create materialized view public.daily_stats as
with date_series as (
  select generate_series(
    date_trunc('day', now() - interval '30 days'),
    date_trunc('day', now()),
    interval '1 day'
  ) as stat_date
)
select
  ds.stat_date,
  coalesce(count(distinct c.id), 0) as consultations_count,
  coalesce(count(distinct p.id), 0) as prescriptions_count,
  coalesce(count(distinct r.id), 0) as reservations_count,
  coalesce(count(distinct d.id), 0) as deliveries_count,
  coalesce(count(distinct t.id), 0) as transactions_count,
  coalesce(sum(t.amount), 0) as revenue
from date_series ds
left join consultations c on date_trunc('day', c.scheduled_at) = ds.stat_date and c.status in ('completed', 'confirmed')
left join prescriptions p on date_trunc('day', p.created_at) = ds.stat_date
left join reservations r on date_trunc('day', r.reserved_at) = ds.stat_date and r.status = 'pickedUp'
left join deliveries d on date_trunc('day', d.delivered_at) = ds.stat_date
left join transactions t on date_trunc('day', t.completed_at) = ds.stat_date and t.status = 'completed'
group by ds.stat_date
order by ds.stat_date desc;

create unique index idx_daily_stats_stat_date on public.daily_stats(stat_date);

create materialized view public.pharmacies_performance as
select
  ph.id,
  ph.name,
  count(distinct r.id) as total_reservations,
  count(distinct d.id) as total_deliveries,
  count(distinct t.id) as total_transactions,
  coalesce(sum(t.amount), 0) as total_revenue,
  count(distinct s.id) as products_in_stock,
  count(distinct sa.id) as active_alerts
from pharmacies ph
left join reservations r on r.pharmacy_id = ph.id and r.status = 'pickedUp'
left join deliveries d on d.reservation_id = r.id and d.status = 'delivered'
left join transactions t on t.pharmacy_id = ph.id and t.status = 'completed'
left join stock_items s on s.pharmacy_id = ph.id and s.total_quantity > 0
left join alerts sa on sa.pharmacy_id = ph.id and sa.status = 'new'
group by ph.id, ph.name;

create unique index idx_pharmacies_performance_id on public.pharmacies_performance(id);

create materialized view public.products_performance as
select
  pr.id,
  pr.name,
  pr.generic_name,
  pr.category_id,
  count(distinct r.id) as reservation_count,
  coalesce(sum(r.quantity), 0) as total_quantity_sold,
  coalesce(avg(s.unit_price), 0) as avg_price,
  count(distinct s.id) as pharmacies_with_stock,
  count(distinct si.id) as total_stock_quantity
from products pr
left join reservation_items r on r.product_id = pr.id
left join stock_items s on s.product_id = pr.id and s.total_quantity > 0
left join stock_batches si on si.stock_item_id = s.id
group by pr.id, pr.name, pr.generic_name, pr.category_id;

create unique index idx_products_performance_id on public.products_performance(id);

create materialized view public.top_products as
select *
from products_performance
order by total_quantity_sold desc
limit 100;

create unique index idx_top_products_id on public.top_products(id);

-- Note sur `alerts.status = 'new'` (remplace `'active'`, valeur inexistante
-- dans la contrainte CHECK réelle de `alerts.status`
-- ('new'/'read'/'dismissed'/'actioned') — deuxième anomalie de valeur
-- d'enum trouvée dans ces vues en plus de BI-4, révélée par confrontation
-- directe au schéma réel pendant l'écriture de ce correctif plutôt que par
-- exécution du harnais de test (BI-13, corrigée dans le même mouvement).

-- Rafraîchissement : CONCURRENTLY est désormais possible (BI-3/C88).
create or replace function refresh_analytics_views()
returns void as $$
begin
  refresh materialized view concurrently daily_stats;
  refresh materialized view concurrently pharmacies_performance;
  refresh materialized view concurrently products_performance;
  refresh materialized view concurrently top_products;
end;
$$ language plpgsql;

-- ==================== BI-1 : verrouillage + vues scoped ====================

revoke select on public.daily_stats from authenticated;
revoke select on public.pharmacies_performance from authenticated;
revoke select on public.products_performance from authenticated;
revoke select on public.top_products from authenticated;

-- Helper : vrai si l'utilisateur courant est staff officine, quelle que soit
-- l'officine (contrairement à is_pharmacy_staff(uuid), qui teste une
-- officine précise) — nécessaire pour les métriques réseau agrégées par
-- produit (BI, non identifiantes par officine) plutôt que par CA nominatif
-- (pharmacies_performance/daily_stats, réservées à l'officine concernée ou
-- à is_gsg_admin()).
create or replace function public.is_any_pharmacy_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'pharmacien' and pharmacy_id is not null
  );
$$;

comment on function public.is_any_pharmacy_staff() is
  'Vrai si l''utilisateur courant est staff officine (role pharmacien, rattaché à une officine), sans restriction à une officine précise. Utilisé pour les indicateurs BI agrégés par produit, non identifiants par officine.';

-- daily_stats : agrégat réseau entier sans colonne pharmacy_id -> réservé au
-- « Tableau de bord réseau GSG » (is_gsg_admin() uniquement). Le « Tableau
-- de bord officine » (1ère fonctionnalité clé cahier, BI-2) est couvert
-- séparément par get_pharmacy_daily_stats() ci-dessous.
create view public.daily_stats_scoped as
select ds.*
from public.daily_stats ds
where public.is_gsg_admin();

comment on view public.daily_stats_scoped is
  'Vue d''accès pour daily_stats (vue matérialisée sans RLS possible) : réservée à is_gsg_admin() — agrégat de plateforme entière, périmètre "Tableau de bord réseau GSG". BI-1.';

-- pharmacies_performance : chaque ligne est nommément une officine avec son
-- CA -> is_gsg_admin() voit tout le réseau, is_pharmacy_staff(id) ne voit
-- que sa propre officine, tout le monde d'autre ne voit rien.
create view public.pharmacies_performance_scoped as
select pp.*
from public.pharmacies_performance pp
where public.is_gsg_admin() or public.is_pharmacy_staff(pp.id);

comment on view public.pharmacies_performance_scoped is
  'Vue d''accès pour pharmacies_performance (vue matérialisée sans RLS possible) : is_gsg_admin() voit toutes les officines, is_pharmacy_staff(id) ne voit que la sienne. BI-1, corrige la fuite de CA inter-officines.';

-- products_performance / top_products : agrégat par produit, non
-- identifiant par officine -> ouvert à tout membre du personnel officine
-- (utilité métier réelle : savoir quels produits tournent le mieux sur le
-- réseau) ou à is_gsg_admin(), fermé à un compte patient/livreur/etc.
create view public.products_performance_scoped as
select pp.*
from public.products_performance pp
where public.is_gsg_admin() or public.is_any_pharmacy_staff();

comment on view public.products_performance_scoped is
  'Vue d''accès pour products_performance (vue matérialisée sans RLS possible) : réservée au personnel officine (toutes officines) et à is_gsg_admin() — non identifiant par officine, mais pas une donnée publique. BI-1.';

create view public.top_products_scoped as
select tp.*
from public.top_products tp
where public.is_gsg_admin() or public.is_any_pharmacy_staff();

comment on view public.top_products_scoped is
  'Vue d''accès pour top_products (vue matérialisée sans RLS possible), même garde que products_performance_scoped. BI-1.';

grant select on public.daily_stats_scoped to authenticated;
grant select on public.pharmacies_performance_scoped to authenticated;
grant select on public.products_performance_scoped to authenticated;
grant select on public.top_products_scoped to authenticated;

-- ==================== BI-2 : Tableau de bord officine (donnée manquante) ====================

create or replace function public.get_pharmacy_daily_stats(
  target_pharmacy_id uuid,
  days_back integer default 30
)
returns table (
  stat_date date,
  reservations_count bigint,
  deliveries_count bigint,
  transactions_count bigint,
  revenue bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (public.is_gsg_admin() or public.is_pharmacy_staff(target_pharmacy_id)) then
    raise exception 'access denied';
  end if;

  return query
  with date_series as (
    select generate_series(
      date_trunc('day', now() - (days_back || ' days')::interval),
      date_trunc('day', now()),
      interval '1 day'
    )::date as d
  ),
  res as (
    select date_trunc('day', reserved_at)::date as d, count(*) as c
    from public.reservations
    where pharmacy_id = target_pharmacy_id and status = 'pickedUp'
    group by 1
  ),
  del as (
    select date_trunc('day', dl.delivered_at)::date as d, count(*) as c
    from public.deliveries dl
    join public.reservations r on r.id = dl.reservation_id
    where r.pharmacy_id = target_pharmacy_id and dl.status = 'delivered'
    group by 1
  ),
  txn as (
    select date_trunc('day', completed_at)::date as d, count(*) as c, coalesce(sum(amount), 0) as rev
    from public.transactions
    where pharmacy_id = target_pharmacy_id and status = 'completed'
    group by 1
  )
  select
    ds.d,
    coalesce(res.c, 0),
    coalesce(del.c, 0),
    coalesce(txn.c, 0),
    coalesce(txn.rev, 0)::bigint
  from date_series ds
  left join res on res.d = ds.d
  left join del on del.d = ds.d
  left join txn on txn.d = ds.d
  order by ds.d desc;
end;
$$;

comment on function public.get_pharmacy_daily_stats(uuid, integer) is
  'Statistiques quotidiennes (réservations/livraisons/transactions/CA) scopées à UNE officine — couvre le "Tableau de bord officine" (1ère fonctionnalité clé cahier BI), absent avant ce correctif (BI-2). Garde d''accès interne (is_gsg_admin() ou is_pharmacy_staff(target_pharmacy_id)) plutôt que RLS, une fonction SECURITY DEFINER n''étant pas soumise à la RLS de ses tables sources.';

grant execute on function public.get_pharmacy_daily_stats(uuid, integer) to authenticated;

-- ==================== BI-5 : forecast_predictions / forecast_historical_data / forecast_alerts ====================

drop policy if exists "Staff manage forecasts" on public.forecast_predictions;
drop policy if exists "Authenticated view forecasts" on public.forecast_predictions;

create policy "forecast_predictions_admin_all" on public.forecast_predictions
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

create policy "forecast_predictions_pharmacy_manage" on public.forecast_predictions
  for all using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "forecast_predictions_pharmacy_view_global" on public.forecast_predictions
  for select using (pharmacy_id is null and public.is_any_pharmacy_staff());

drop policy if exists "Staff manage historical data" on public.forecast_historical_data;
drop policy if exists "Authenticated view historical data" on public.forecast_historical_data;

create policy "forecast_historical_admin_all" on public.forecast_historical_data
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

create policy "forecast_historical_pharmacy_manage" on public.forecast_historical_data
  for all using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "forecast_historical_pharmacy_view_global" on public.forecast_historical_data
  for select using (pharmacy_id is null and public.is_any_pharmacy_staff());

drop policy if exists "Staff manage forecast alerts" on public.forecast_alerts;
drop policy if exists "Authenticated view forecast alerts" on public.forecast_alerts;

create policy "forecast_alerts_admin_all" on public.forecast_alerts
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

create policy "forecast_alerts_pharmacy_manage" on public.forecast_alerts
  for all using (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "forecast_alerts_pharmacy_view_global" on public.forecast_alerts
  for select using (pharmacy_id is null and public.is_any_pharmacy_staff());

-- BI-12 (découverte en cours de validation par exécution réelle, non
-- identifiée à l'ouverture) : forecast_accuracy avait RLS activée sans
-- aucune policy -- inaccessible à tout rôle non superutilisateur. Accès
-- scopé via le forecast parent.
create policy "forecast_accuracy_admin_all" on public.forecast_accuracy
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

create policy "forecast_accuracy_pharmacy_select" on public.forecast_accuracy
  for select using (
    exists (
      select 1 from public.forecast_predictions fp
      where fp.id = forecast_accuracy.forecast_id
        and fp.pharmacy_id is not null
        and public.is_pharmacy_staff(fp.pharmacy_id)
    )
  );

-- ==========================================================================
-- BI-7 : Recadrage du système de personnalisation de tableau de bord
-- (`user_dashboards`/`dashboard_widgets`, écran DashboardEditorScreen) sur
-- les rôles officine/réseau du cahier, au lieu d'un système strictement
-- individuel. `patient_id` était un nom trompeur hérité : la colonne
-- référence déjà n'importe quel profil (FK vers profiles, pas vers une
-- table patients) -- confusion de nommage plutôt que restriction
-- fonctionnelle réelle, mais source du contresens repéré à l'ouverture.
-- Corrige au passage le motif récurrent « rôle inatteignable »
-- (`role in ('admin','staff')`, jamais satisfiable -- CHECK réel de
-- profiles.role) sur ces deux tables, déjà repéré mais explicitement
-- différé au Module 28 lors de la clôture du Module 16 (voir commentaire
-- dans 20260829043000_loyalty_module_fixes.sql).
--
-- Le système `analytics_dashboards` (AnalyticsDashboardScreen, RLS
-- `auth.uid() = user_id`) est volontairement laissé inchangé : il est déjà
-- correctement isolé par compte, déjà câblé/fonctionnel, et ne stocke que
-- des types de métriques (pas de chiffres bruts) -- la vraie étanchéité
-- réseau/officine est de toute façon portée par BI-1 en amont. La
-- coexistence de deux systèmes de tableau de bord distincts reste un doublon
-- documenté (voir D49 du registre) plutôt que fusionnée ici : périmètre
-- disproportionné pour ce correctif, risque de régression sur un système
-- déjà en production contre un système jusqu'ici totalement inatteignable.
-- ==========================================================================

alter table public.user_dashboards rename column patient_id to owner_id;

alter table public.user_dashboards
  add column if not exists pharmacy_id uuid references public.pharmacies(id),
  add column if not exists scope text not null default 'personal';

alter table public.user_dashboards
  drop constraint if exists user_dashboards_scope_check;
alter table public.user_dashboards
  add constraint user_dashboards_scope_check
  check (scope in ('personal', 'officine', 'reseau'));

alter table public.user_dashboards
  drop constraint if exists user_dashboards_scope_pharmacy_check;
alter table public.user_dashboards
  add constraint user_dashboards_scope_pharmacy_check
  check (
    (scope = 'officine' and pharmacy_id is not null)
    or (scope in ('personal', 'reseau') and pharmacy_id is null)
  );

comment on column public.user_dashboards.owner_id is
  'Profil créateur/rattachement (renommé depuis patient_id : la colonne référençait déjà tout profil, pas seulement un patient). Détermine seul l''accès quand scope = personal.';
comment on column public.user_dashboards.scope is
  'personal : tableau de bord propre à owner_id. officine : partagé entre le staff de pharmacy_id (Tableau de bord officine, cahier BI). reseau : partagé entre les comptes GSG admin (Tableau de bord réseau, cahier BI).';

drop index if exists idx_user_dashboards_patient_id;
create index if not exists idx_user_dashboards_owner_id on public.user_dashboards(owner_id);
create index if not exists idx_user_dashboards_pharmacy_id on public.user_dashboards(pharmacy_id) where pharmacy_id is not null;

drop policy if exists "Patients manage own dashboards" on public.user_dashboards;
drop policy if exists "Staff view user dashboards" on public.user_dashboards;

create policy "user_dashboards_personal_owner" on public.user_dashboards
  for all using (scope = 'personal' and auth.uid() = owner_id)
  with check (scope = 'personal' and auth.uid() = owner_id);

create policy "user_dashboards_officine_staff" on public.user_dashboards
  for all using (scope = 'officine' and pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id))
  with check (scope = 'officine' and pharmacy_id is not null and public.is_pharmacy_staff(pharmacy_id));

create policy "user_dashboards_reseau_admin" on public.user_dashboards
  for all using (scope = 'reseau' and public.is_gsg_admin())
  with check (scope = 'reseau' and public.is_gsg_admin());

drop policy if exists "Staff manage dashboard widgets" on public.dashboard_widgets;
create policy "dashboard_widgets_admin_manage" on public.dashboard_widgets
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());
-- "Everyone view dashboard widgets" (catalogue en lecture seule, aucune
-- donnée nominative/financière) reste inchangée.

commit;
