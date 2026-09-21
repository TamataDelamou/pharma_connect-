-- AI Forecasts for analytics
create table forecast_predictions (
  id uuid primary key default gen_random_uuid(),
  metric_type text not null check (metric_type in ('consultations', 'prescriptions', 'reservations', 'deliveries', 'revenue', 'stock')),
  target_date date not null,
  predicted_value numeric not null,
  lower_bound numeric,
  upper_bound numeric,
  confidence_level numeric default 0.8,
  model_version text default 'v1',
  actual_value numeric, -- filled later for accuracy tracking
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Historical data for training (aggregated daily)
create table forecast_historical_data (
  id uuid primary key default gen_random_uuid(),
  metric_type text not null check (metric_type in ('consultations', 'prescriptions', 'reservations', 'deliveries', 'revenue', 'stock')),
  date date not null,
  value numeric not null,
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(metric_type, date, pharmacy_id, product_id)
);

-- Forecast accuracy tracking
create table forecast_accuracy (
  id uuid primary key default gen_random_uuid(),
  forecast_id uuid references forecast_predictions(id) on delete cascade,
  actual_value numeric,
  error_percentage numeric,
  mae numeric, -- Mean Absolute Error
  rmse numeric, -- Root Mean Square Error
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Alert configurations for forecasting
create table forecast_alerts (
  id uuid primary key default gen_random_uuid(),
  metric_type text not null check (metric_type in ('consultations', 'prescriptions', 'reservations', 'deliveries', 'revenue', 'stock')),
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  threshold_type text not null check (threshold_type in ('min', 'max', 'change_percent')),
  threshold_value numeric not null,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table forecast_predictions enable row level security;
alter table forecast_historical_data enable row level security;
alter table forecast_accuracy enable row level security;
alter table forecast_alerts enable row level security;

-- Staff manage forecasts
create policy "Staff manage forecasts" on forecast_predictions
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Authenticated users view forecasts
create policy "Authenticated view forecasts" on forecast_predictions
  for select using (auth.role() = 'authenticated');

-- Historical data: staff manage, others view
create policy "Staff manage historical data" on forecast_historical_data
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

create policy "Authenticated view historical data" on forecast_historical_data
  for select using (auth.role() = 'authenticated');

-- Alerts: staff manage, authenticated view
create policy "Staff manage forecast alerts" on forecast_alerts
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

create policy "Authenticated view forecast alerts" on forecast_alerts
  for select using (auth.role() = 'authenticated');

-- Function to calculate forecast accuracy
create or replace function calculate_forecast_accuracy()
returns trigger as $$
declare
  error_pct numeric;
begin
  if new.actual_value is not null then
    error_pct = ((new.actual_value - new.predicted_value) / new.predicted_value) * 100;
    insert into forecast_accuracy (
      forecast_id,
      actual_value,
      error_percentage,
      created_at
    ) values (
      new.id,
      new.actual_value,
      error_pct,
      now()
    );
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_forecast_accuracy_update
after update of actual_value on forecast_predictions
for each row when (new.actual_value is not null)
execute function calculate_forecast_accuracy();
