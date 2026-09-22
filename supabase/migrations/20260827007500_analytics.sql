-- Analytics module: dashboards and KPIs
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C84 :
-- ce fichier contenait 4 références bloquantes à des colonnes inexistantes,
-- confirmées une à une par exécution réelle contre un Postgres 16 local
-- (schéma réel du projet, sans simulation) : `deliveries.pharmacy_id`
-- (n'existe pas — la relation passe par
-- `deliveries.reservation_id -> reservations.pharmacy_id`),
-- `pharmacies.city` (n'existe pas, seule une colonne `address` texte libre
-- existe), `products.category` (n'existe pas, seule `category_id`, FK vers
-- `categories`, existe), `prescription_items.product_id` (n'existe pas —
-- les lignes d'ordonnance sont en texte libre `medication_name`, avec au
-- mieux un `suggested_generic_id` nullable pour les suggestions de
-- substitution, sémantiquement différent d'un « produit prescrit »
-- identifié). Ce module (« Analytics/BI ») reste hors périmètre du
-- Module 19 — non audité en profondeur ici — mais ces 4 défauts sont de
-- même nature que C78/C82/C83 (bloquants pour `supabase db push`) et ont
-- donc été corrigés en même temps sur demande explicite du porteur du
-- projet. `prescription_count` sur `products_performance` est retirée
-- plutôt que reconstruite sur une correspondance texte peu fiable
-- (`medication_name`) : une jointure fiable nécessiterait un changement de
-- modèle de données (lier `prescription_items` à `products`), décision de
-- conception hors du périmètre d'un correctif DDL. Deux anomalies non
-- bloquantes supplémentaires trouvées lors de cette vérification, non
-- corrigées ici (n'empêchent pas `supabase db push`, consignées au
-- registre sous C88) : `r.status = 'picked_up'` (deux occurrences,
-- `daily_stats`/`pharmacies_performance`) ne correspond à aucune valeur
-- réelle de `reservations.status` (`'pickedUp'`, camelCase — la comparaison
-- ne lève aucune erreur mais ne retourne jamais aucune ligne) ; et
-- `refresh_analytics_views()` utilise `refresh materialized view
-- concurrently`, qui nécessite un index unique sur chaque vue concernée —
-- aucun des 4 index créés dans ce fichier n'existe encore à ce stade
-- (aucun `create unique index`), donc le premier appel réel à cette
-- fonction échouerait, indépendamment de tout problème de colonnes.

-- Analytics dashboards (saved user dashboards)
create table public.analytics_dashboards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text,
  layout jsonb default '{"panels": []}'::jsonb,
  is_default boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Analytics views for aggregated data
-- These are materialized views refreshed periodically

-- Daily statistics view (aggregated)
create materialized view daily_stats as
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
left join reservations r on date_trunc('day', r.reserved_at) = ds.stat_date and r.status = 'picked_up'
left join deliveries d on date_trunc('day', d.delivered_at) = ds.stat_date
left join transactions t on date_trunc('day', t.completed_at) = ds.stat_date and t.status = 'completed'
group by ds.stat_date
order by ds.stat_date desc;

-- Pharmacies performance view
create materialized view pharmacies_performance as
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
left join reservations r on r.pharmacy_id = ph.id and r.status = 'picked_up'
left join deliveries d on d.reservation_id = r.id and d.status = 'delivered'
left join transactions t on t.pharmacy_id = ph.id and t.status = 'completed'
left join stock_items s on s.pharmacy_id = ph.id and s.total_quantity > 0
left join alerts sa on sa.pharmacy_id = ph.id and sa.status = 'active'
group by ph.id, ph.name;

-- Products performance view
create materialized view products_performance as
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

-- Top products (for quick display)
create materialized view top_products as
select *
from products_performance
order by total_quantity_sold desc
limit 100;

-- RLS for analytics views
alter table public.analytics_dashboards enable row level security;

-- Users can manage their own dashboards
create policy "Users manage own dashboards" on public.analytics_dashboards
  for all using (auth.uid() = user_id);

-- Refresh materialized views function
create or replace function refresh_analytics_views()
returns void as $$
begin
  refresh materialized view concurrently daily_stats;
  refresh materialized view concurrently pharmacies_performance;
  refresh materialized view concurrently products_performance;
  refresh materialized view concurrently top_products;
end;
$$ language plpgsql;

-- Schedule refresh via cron (if pg_cron is installed)
-- Otherwise, manual refresh via API or edge function

-- Grant access to authenticated users
grant select on daily_stats to authenticated;
grant select on pharmacies_performance to authenticated;
grant select on products_performance to authenticated;
grant select on top_products to authenticated;
