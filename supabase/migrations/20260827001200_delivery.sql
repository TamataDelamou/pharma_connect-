-- Module delivery (lib/modules/delivery). Livraison à domicile.

create table if not exists public.delivery_drivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  name text not null,
  phone text not null,
  photo_url text,
  is_available boolean not null default true,
  rating numeric,
  completed_deliveries integer not null default 0,
  vehicle_type text,
  vehicle_plate text,
  current_latitude double precision,
  current_longitude double precision,
  is_cold_chain_certified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.delivery_drivers is 'Livreurs (delivery/models/delivery_driver.dart).';

create index if not exists idx_delivery_drivers_user_id on public.delivery_drivers(user_id);

create trigger set_updated_at
  before update on public.delivery_drivers
  for each row execute function public.set_updated_at();

create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid references public.reservations(id),
  patient_id uuid references auth.users(id),
  patient_name text not null,
  patient_phone text not null,
  delivery_address text not null,
  latitude double precision,
  longitude double precision,
  driver_id uuid references public.delivery_drivers(id),
  tracking_history text[] not null default '{}',
  scheduled_at timestamptz not null,
  started_at timestamptz,
  picked_up_at timestamptz,
  arrived_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz,
  status text not null default 'scheduled' check (status in (
    'scheduled', 'preparing', 'inProgress', 'arrived', 'delivered', 'cancelled'
  )),
  is_cold_chain_required boolean not null default false,
  notes text,
  is_express boolean not null default false,
  pickup_point_id text,
  pickup_point_name text,
  distance_to_destination double precision,
  estimated_time_remaining integer,
  created_at timestamptz not null default now()
);

comment on table public.deliveries is 'Livraisons (delivery/models/delivery.dart).';

create index if not exists idx_deliveries_reservation_id on public.deliveries(reservation_id);
create index if not exists idx_deliveries_patient_id on public.deliveries(patient_id);
create index if not exists idx_deliveries_driver_id on public.deliveries(driver_id);
create index if not exists idx_deliveries_status on public.deliveries(status);

create table if not exists public.delivery_proofs (
  delivery_id uuid primary key references public.deliveries(id) on delete cascade,
  signature_data text,
  image_url text,
  confirmation_code text,
  recipient_name text,
  recipient_phone text,
  notes text,
  "timestamp" timestamptz not null default now()
);

comment on table public.delivery_proofs is 'Preuve de livraison, 1:1 avec deliveries (delivery/models/delivery_proof.dart).';

create table if not exists public.delivery_routes (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.delivery_drivers(id),
  date date not null,
  status text not null default 'planned' check (status in (
    'planned', 'inProgress', 'completed', 'cancelled'
  )),
  created_at timestamptz not null default now()
);

comment on table public.delivery_routes is 'Tournées de livraison (delivery/models/delivery_route.dart : DeliveryRoute).';

create index if not exists idx_delivery_routes_driver_id on public.delivery_routes(driver_id);

create table if not exists public.route_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.delivery_routes(id) on delete cascade,
  delivery_id uuid not null references public.deliveries(id),
  latitude double precision not null,
  longitude double precision not null,
  address text not null,
  stop_order integer not null,
  is_completed boolean not null default false
);

comment on table public.route_stops is 'Étapes d''une tournée (delivery/models/delivery_route.dart : RouteStop).';

create index if not exists idx_route_stops_route_id on public.route_stops(route_id);

alter table public.delivery_drivers enable row level security;
alter table public.deliveries enable row level security;
alter table public.delivery_proofs enable row level security;
alter table public.delivery_routes enable row level security;
alter table public.route_stops enable row level security;

create policy "delivery_drivers_select_authenticated" on public.delivery_drivers
  for select to authenticated using (true);

-- Accès livreur (tournée assignée) volontairement pas couvert ici, même
-- réserve que reservations/prescriptions : pas encore de mécanisme de
-- vérification de rôle. Patient : accès à ses propres livraisons uniquement.
create policy "deliveries_select_own" on public.deliveries
  for select to authenticated
  using (auth.uid() = patient_id);

create policy "delivery_proofs_select_own" on public.delivery_proofs
  for select to authenticated
  using (
    exists (
      select 1 from public.deliveries d
      where d.id = delivery_proofs.delivery_id
        and d.patient_id = auth.uid()
    )
  );

create policy "delivery_routes_select_authenticated" on public.delivery_routes
  for select to authenticated using (true);

create policy "route_stops_select_authenticated" on public.route_stops
  for select to authenticated using (true);
