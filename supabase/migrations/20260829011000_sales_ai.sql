-- Sales AI: predictions and recommendations

-- Demand predictions
create table public.demand_predictions (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  prediction_date date not null,
  predicted_quantity integer not null,
  lower_bound integer,
  upper_bound integer,
  confidence_level numeric default 0.8,
  model_version text default 'v1',
  actual_quantity integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Price recommendations
create table public.price_recommendations (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  current_price integer not null,
  recommended_price integer not null,
  min_price integer,
  max_price integer,
  reason text,
  confidence_level numeric default 0.7,
  is_applied boolean default false,
  applied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Fraud alerts
create table public.fraud_alerts (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  transaction_id uuid references public.pos_sales(id) on delete set null,
  alert_type text not null check (alert_type in ('amount_anomaly', 'frequency_anomaly', 'pattern_anomaly', 'refund_anomaly')),
  severity text not null check (severity in ('low', 'medium', 'high', 'critical')),
  description text not null,
  score numeric,
  status text default 'pending' check (status in ('pending', 'reviewed', 'dismissed', 'confirmed')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Product recommendations (cross-sell)
create table public.product_recommendations (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  recommended_product_id uuid not null references public.products(id) on delete cascade,
  score numeric not null,
  support_count integer,
  confidence numeric,
  lift numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(product_id, recommended_product_id)
);

-- Sentiment analysis for returns
create table public.return_sentiment (
  id uuid primary key default gen_random_uuid(),
  return_id uuid references public.customer_returns(id) on delete cascade,
  sentiment text check (sentiment in ('positive', 'neutral', 'negative')),
  score numeric,
  key_phrases text[],
  category text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_demand_predictions_pharmacy_id on public.demand_predictions(pharmacy_id);
create index idx_demand_predictions_product_id on public.demand_predictions(product_id);
create index idx_demand_predictions_date on public.demand_predictions(prediction_date);
create index idx_price_recommendations_pharmacy_id on public.price_recommendations(pharmacy_id);
create index idx_price_recommendations_product_id on public.price_recommendations(product_id);
create index idx_fraud_alerts_pharmacy_id on public.fraud_alerts(pharmacy_id);
create index idx_fraud_alerts_status on public.fraud_alerts(status);
create index idx_product_recommendations_product_id on public.product_recommendations(product_id);

-- RLS
alter table public.demand_predictions enable row level security;
alter table public.price_recommendations enable row level security;
alter table public.fraud_alerts enable row level security;
alter table public.product_recommendations enable row level security;
alter table public.return_sentiment enable row level security;

-- Pharmacy staff manage
-- (audit Module 0, 29/08/2026 : `public.pharmacy_staff` n'existe pas, voir
-- la même note dans 20260829006000_pos.sql — remplacé par is_pharmacy_staff().)
create policy "Pharmacy staff manage demand predictions" on public.demand_predictions
  for all using (public.is_pharmacy_staff(pharmacy_id));

create policy "Pharmacy staff manage price recommendations" on public.price_recommendations
  for all using (public.is_pharmacy_staff(pharmacy_id));

create policy "Pharmacy staff view fraud alerts" on public.fraud_alerts
  for select using (public.is_pharmacy_staff(pharmacy_id));

create policy "Network admins view all fraud alerts" on public.fraud_alerts
  for select using (exists (select 1 from public.network_admin_roles where user_id = auth.uid() and role in ('super_admin', 'network_admin')));

-- Function to generate recommendations from sales data
create or replace function generate_product_recommendations()
returns void as $$
begin
  -- Market basket analysis: find products frequently bought together
  insert into public.product_recommendations (product_id, recommended_product_id, score, support_count)
  select
    a.product_id,
    b.product_id,
    count(*)::numeric / (select count(distinct sale_id) from public.pos_sale_items) as score,
    count(*) as support_count
  from public.pos_sale_items a
  join public.pos_sale_items b on a.sale_id = b.sale_id and a.product_id != b.product_id
  where a.product_id is not null and b.product_id is not null
  group by a.product_id, b.product_id
  having count(*) >= 5
  on conflict (product_id, recommended_product_id) do update
  set score = excluded.score,
      support_count = excluded.support_count,
      updated_at = now();
end;
$$ language plpgsql;
