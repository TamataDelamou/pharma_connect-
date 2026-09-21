-- IoT module: connected devices for cold chain and stock monitoring

-- IoT devices
create table iot_devices (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  device_id text unique not null,
  name text not null,
  type text not null check (type in ('temperature_sensor', 'humidity_sensor', 'cold_chain_monitor', 'stock_scanner', 'motion_sensor')),
  model text,
  firmware_version text,
  status text default 'active' check (status in ('active', 'inactive', 'maintenance', 'offline')),
  last_reading_at timestamptz,
  last_battery_level integer check (last_battery_level between 0 and 100),
  location text,
  config jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Temperature readings
create table temperature_readings (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.iot_devices(id) on delete cascade,
  temperature numeric not null,
  timestamp timestamptz not null default now(),
  unit text default '°C',
  is_alert boolean default false,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Humidity readings
create table humidity_readings (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.iot_devices(id) on delete cascade,
  humidity numeric not null,
  timestamp timestamptz not null default now(),
  is_alert boolean default false,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- IoT alerts
create table iot_alerts (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.iot_devices(id) on delete cascade,
  type text not null check (type in ('temperature_high', 'temperature_low', 'humidity_high', 'battery_low', 'offline', 'motion')),
  message text not null,
  value numeric,
  threshold numeric,
  status text default 'active' check (status in ('active', 'acknowledged', 'resolved')),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_iot_devices_pharmacy_id on public.iot_devices(pharmacy_id);
create index idx_iot_devices_device_id on public.iot_devices(device_id);
create index idx_iot_devices_status on public.iot_devices(status);
create index idx_temperature_readings_device_id on public.temperature_readings(device_id);
create index idx_temperature_readings_timestamp on public.temperature_readings(timestamp);
create index idx_humidity_readings_device_id on public.humidity_readings(device_id);
create index idx_iot_alerts_device_id on public.iot_alerts(device_id);
create index idx_iot_alerts_status on public.iot_alerts(status);

-- Triggers for updated_at
create trigger trigger_iot_devices_updated_at
before update on public.iot_devices
for each row execute function public.update_updated_at();

create trigger trigger_iot_alerts_updated_at
before update on public.iot_alerts
for each row execute function public.update_updated_at();

-- RLS
alter table public.iot_devices enable row level security;
alter table public.temperature_readings enable row level security;
alter table public.humidity_readings enable row level security;
alter table public.iot_alerts enable row level security;

-- Audit Module 21 (IOT), ouverture (30/08/2026), C98 : deux défauts
-- transverses déjà rencontrés ailleurs dans l'audit, trouvés dans la
-- migration d'origine de ce module lui-même, corrigés dans le même
-- mouvement (même principe que C79/C94) :
-- (a) `auth.uid() = pharmacy_id` compare un id utilisateur à un id
--     d'officine (motif déjà documenté ailleurs — chains.sql,
--     stock_forecasting.sql — au registre C88, ici enfin corrigé plutôt
--     que laissé en dette) — remplacé par `public.is_pharmacy_staff()`.
-- (b) `role in ('admin', 'staff')`, SANS repli sur un rôle valide (à la
--     différence du motif C94/DSN où 'professionnel' restait fonctionnel) :
--     ces trois policies (ici et plus bas pour les lectures/alertes) sont
--     donc INTÉGRALEMENT mortes — aucun compte, quel qu'il soit, n'a
--     jamais pu superviser les équipements/lectures/alertes IoT. Ce fichier
--     (29/08, 03h00) est antérieur à `is_gsg_admin()` (29/08, 03h800),
--     même piège de non-antériorité que C90/C94 : vérification inlined sur
--     `admin_users` plutôt qu'un appel prématuré à la fonction.
--
-- Pharmacy view own devices
create policy "Pharmacy view own IoT devices" on public.iot_devices
  for select using (public.is_pharmacy_staff(pharmacy_id));

-- Pharmacy manage own devices
create policy "Pharmacy manage own IoT devices" on public.iot_devices
  for all using (public.is_pharmacy_staff(pharmacy_id));

-- Staff view all devices
create policy "Staff view all IoT devices" on public.iot_devices
  for select using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87 (nouveau type
-- de bug, pas encore rencontré ailleurs dans l'audit) : `iot_devices`
-- porte à la fois `id` (uuid, PK) et `device_id` (text, numéro de série,
-- voir la définition de la table). Dans `where id = device_id` ci-dessous,
-- la colonne `device_id` de la sous-requête corrélée (censée référencer
-- `temperature_readings.device_id`/`humidity_readings.device_id`, uuid,
-- la table externe de la policy) est capturée par la colonne de même nom
-- de `iot_devices` elle-même (text) — la portée SQL normale fait gagner la
-- colonne la plus interne. Résultat : `id = device_id` devient
-- silencieusement `uuid = text`, sans opérateur d'égalité — confirmé
-- bloquant par exécution réelle. Corrigé en qualifiant explicitement la
-- colonne de la table externe par son nom.
--
-- Audit Module 21 (IOT), Étape 3 (30/08/2026), C98 (complément) : le
-- correctif initial de C98 n'avait couvert que les policies portant
-- directement sur `iot_devices` (`auth.uid() = pharmacy_id`). Le harnais de
-- test réel exigé par l'utilisateur pour valider C98 a révélé que le MÊME
-- biais d'identifiant (comparer un id d'officine à un id de compte
-- utilisateur) était également présent, sans avoir été détecté au premier
-- passage, dans les quatre policies ci-dessous portant sur les lectures et
-- les alertes (`iot_devices.pharmacy_id = auth.uid()` au sein de la
-- sous-requête EXISTS) — un défaut aussi total que celui déjà corrigé sur
-- `iot_devices` : aucun compte pharmacien n'a jamais pu consulter ses
-- propres relevés de température/humidité ni ses propres alertes. Corrigé
-- selon le même principe que pour `iot_devices`, avec `public.is_pharmacy_staff()`.
--
-- Readings: pharmacy view own device readings
create policy "Pharmacy view device readings" on public.temperature_readings
  for select using (
    exists (
      select 1 from public.iot_devices
      where iot_devices.id = temperature_readings.device_id and public.is_pharmacy_staff(iot_devices.pharmacy_id)
    )
  );

create policy "Pharmacy view humidity readings" on public.humidity_readings
  for select using (
    exists (
      select 1 from public.iot_devices
      where iot_devices.id = humidity_readings.device_id and public.is_pharmacy_staff(iot_devices.pharmacy_id)
    )
  );

-- Staff view all readings (C98, voir le commentaire complet plus haut)
create policy "Staff view all readings" on public.temperature_readings
  for select using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );

-- Alerts: pharmacy view own device alerts (même correctif de portée SQL
-- que ci-dessus pour `iot_alerts.device_id`, et même correctif C98
-- complémentaire que pour les relevés ci-dessus)
create policy "Pharmacy view IoT alerts" on public.iot_alerts
  for select using (
    exists (
      select 1 from public.iot_devices
      where iot_devices.id = iot_alerts.device_id and public.is_pharmacy_staff(iot_devices.pharmacy_id)
    )
  );

-- Pharmacy manage own alerts (acknowledge/resolve)
create policy "Pharmacy manage own alerts" on public.iot_alerts
  for update using (
    exists (
      select 1 from public.iot_devices
      where iot_devices.id = iot_alerts.device_id and public.is_pharmacy_staff(iot_devices.pharmacy_id)
    )
  );

-- Staff manage all alerts (C98, voir le commentaire complet plus haut)
create policy "Staff manage all alerts" on public.iot_alerts
  for all using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );
