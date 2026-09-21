-- Stock forecasting extensions

-- Demand forecasts
create table public.demand_forecasts (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  pharmacy_id uuid references public.pharmacies(id) on delete cascade,
  product_name text not null,
  forecast_date date not null,
  predicted_demand integer not null,
  lower_bound integer,
  upper_bound integer,
  confidence_level numeric default 0.8,
  model_version text default 'v1',
  actual_demand integer, -- filled later for accuracy
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Forecast accuracy tracking
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87, corrigé dans
-- le même mouvement (même nature bloquante que C78/C83) : cette table
-- s'appelait à l'origine `public.forecast_accuracy`, en collision directe
-- avec `forecast_accuracy` déjà créée par `20260828013000_analytics_ai.sql`
-- (module Analytics/BI, hors périmètre du Module 19) — schéma proche mais
-- FK différente (`forecast_predictions`, générique tous indicateurs BI,
-- contre `demand_forecasts` ici, spécifique aux prévisions de demande de
-- stock) : deux concepts distincts, pas une même entité à fusionner comme
-- pour C78. Renommée `public.stock_forecast_accuracy` pour lever la
-- collision (2 références internes à ce fichier mises à jour) plutôt que
-- de toucher `analytics_ai.sql`, qui a une empreinte plus large dans son
-- propre fichier (fonction + trigger l'utilisant). Confirmé bloquant par
-- exécution réelle (`relation "forecast_accuracy" already exists`).
create table public.stock_forecast_accuracy (
  id uuid primary key default gen_random_uuid(),
  forecast_id uuid references public.demand_forecasts(id) on delete cascade,
  actual_value integer,
  error_percentage numeric,
  mae numeric,
  rmse numeric,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Reorder alerts
create table public.reorder_alerts (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid references public.pharmacies(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  product_name text not null,
  current_stock integer not null,
  reorder_point integer not null,
  quantity_to_order integer,
  status text default 'pending' check (status in ('pending', 'ordered', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Scenario simulations
create table public.scenario_simulations (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid references public.pharmacies(id) on delete cascade,
  name text not null,
  description text,
  parameters jsonb default '{}'::jsonb,
  results jsonb default '{}'::jsonb,
  status text default 'pending' check (status in ('pending', 'running', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_demand_forecasts_product_id on public.demand_forecasts(product_id);
create index idx_demand_forecasts_pharmacy_id on public.demand_forecasts(pharmacy_id);
create index idx_demand_forecasts_date on public.demand_forecasts(forecast_date);
create index idx_reorder_alerts_pharmacy_id on public.reorder_alerts(pharmacy_id);
create index idx_reorder_alerts_status on public.reorder_alerts(status);
create index idx_scenario_simulations_pharmacy_id on public.scenario_simulations(pharmacy_id);

-- Triggers
create trigger trigger_demand_forecasts_updated_at
before update on public.demand_forecasts
for each row execute function public.update_updated_at();

create trigger trigger_reorder_alerts_updated_at
before update on public.reorder_alerts
for each row execute function public.update_updated_at();

-- RLS
alter table public.demand_forecasts enable row level security;
alter table public.stock_forecast_accuracy enable row level security;
alter table public.reorder_alerts enable row level security;
alter table public.scenario_simulations enable row level security;

-- Pharmacy view own forecasts
create policy "Pharmacy view own forecasts" on public.demand_forecasts
  for select using (public.is_pharmacy_staff(pharmacy_id)); -- audit Module 0, 29/08/2026 : auth.uid() = pharmacy_id comparait un id utilisateur à un id d'officine

-- Staff manage forecasts
create policy "Staff manage forecasts" on public.demand_forecasts
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Pharmacy view own reorder alerts
create policy "Pharmacy view own reorder alerts" on public.reorder_alerts
  for select using (public.is_pharmacy_staff(pharmacy_id)); -- audit Module 0, 29/08/2026 : auth.uid() = pharmacy_id comparait un id utilisateur à un id d'officine

-- Staff manage reorder alerts
create policy "Staff manage reorder alerts" on public.reorder_alerts
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );

-- Pharmacy view own simulations
create policy "Pharmacy view own simulations" on public.scenario_simulations
  for select using (public.is_pharmacy_staff(pharmacy_id)); -- audit Module 0, 29/08/2026 : auth.uid() = pharmacy_id comparait un id utilisateur à un id d'officine

-- Staff manage simulations
create policy "Staff manage simulations" on public.scenario_simulations
  for all using (
    public.is_gsg_admin() -- audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est inatteignable, voir 20260829003800_admin_helpers.sql
  );
