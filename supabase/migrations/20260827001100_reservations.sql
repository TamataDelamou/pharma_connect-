-- Module reservations (lib/modules/reservations). Click & Collect.

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references auth.users(id),
  patient_name text not null,
  patient_phone text not null,
  patient_email text,
  pharmacy_id uuid not null references public.pharmacies(id),
  pharmacy_name text not null,
  pharmacy_address text not null,
  pharmacy_phone text,
  reserved_at timestamptz not null default now(),
  pickup_time timestamptz,
  pickup_deadline timestamptz,
  confirmed_at timestamptz,
  ready_at timestamptz,
  picked_up_at timestamptz,
  cancelled_at timestamptz,
  status text not null default 'pending' check (status in (
    'pending', 'confirmed', 'ready', 'pickedUp', 'cancelled', 'expired'
  )),
  total_price integer not null default 0,
  qr_code_token text,
  notes text,
  delivery_address text,
  payment_method text,
  queue_position integer,
  estimated_wait_minutes integer,
  created_at timestamptz not null default now()
);

comment on table public.reservations is 'Réservations Click & Collect (reservations/models/reservation.dart).';
comment on column public.reservations.total_price is 'Unité mineure (KER-REF-05).';

create index if not exists idx_reservations_patient_id on public.reservations(patient_id);
create index if not exists idx_reservations_pharmacy_id on public.reservations(pharmacy_id);
create index if not exists idx_reservations_status on public.reservations(status);

create table if not exists public.reservation_items (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  generic_name text,
  dosage text,
  price_per_unit integer not null default 0,
  quantity integer not null default 1,
  stock_at_reservation integer,
  is_substitution boolean not null default false
);

comment on table public.reservation_items is 'Lignes d''une réservation (reservations/models/reservation_item.dart).';
comment on column public.reservation_items.price_per_unit is 'Unité mineure (KER-REF-05).';

create index if not exists idx_reservation_items_reservation_id on public.reservation_items(reservation_id);

alter table public.reservations enable row level security;
alter table public.reservation_items enable row level security;

-- Accès pharmacien (file d'attente d'une officine, cf.
-- reservations/screens/pharmacy_queue_screen.dart) volontairement pas
-- couvert ici, faute d'un mécanisme de vérification de rôle/rattachement
-- utilisateur ↔ officine encore conçu côté produit — même réserve que pour
-- prescriptions. Politique à étendre quand ce fondement existera.
create policy "reservations_select_own" on public.reservations
  for select to authenticated
  using (auth.uid() = patient_id);

create policy "reservation_items_select_own" on public.reservation_items
  for select to authenticated
  using (
    exists (
      select 1 from public.reservations r
      where r.id = reservation_items.reservation_id
        and r.patient_id = auth.uid()
    )
  );
