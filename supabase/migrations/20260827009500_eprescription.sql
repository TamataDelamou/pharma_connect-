-- EPrescription module: electronic prescriptions

-- E-prescriptions
create table public.eprescriptions (
  id uuid primary key default gen_random_uuid(),
  prescription_number text unique not null,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  prescribed_at timestamptz not null default now(),
  valid_until date not null,
  status text not null check (status in ('draft', 'sent', 'received', 'validated', 'dispensed', 'expired', 'cancelled')),
  diagnosis text,
  notes text,
  is_renewable boolean default false,
  renewable_count integer default 0,
  renewable_used integer default 0,
  consultation_id uuid references public.consultations(id) on delete set null,
  qr_code text,
  access_code text, -- code for pharmacy to retrieve
  validated_at timestamptz,
  dispensed_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- EPrescription items (medications)
create table public.eprescription_items (
  id uuid primary key default gen_random_uuid(),
  eprescription_id uuid not null references public.eprescriptions(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  medication_name text not null,
  dosage text not null,
  frequency text not null,
  duration text not null,
  quantity integer not null,
  instructions text,
  is_substitution_allowed boolean default false,
  days_supply integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- EPrescription history (audit trail for status changes)
create table public.eprescription_history (
  id uuid primary key default gen_random_uuid(),
  eprescription_id uuid not null references public.eprescriptions(id) on delete cascade,
  old_status text,
  new_status text not null,
  changed_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_eprescriptions_patient_id on public.eprescriptions(patient_id);
create index idx_eprescriptions_doctor_id on public.eprescriptions(doctor_id);
create index idx_eprescriptions_pharmacy_id on public.eprescriptions(pharmacy_id);
create index idx_eprescriptions_status on public.eprescriptions(status);
create index idx_eprescriptions_valid_until on public.eprescriptions(valid_until);
create index idx_eprescriptions_prescription_number on public.eprescriptions(prescription_number);
create index idx_eprescription_items_eprescription_id on public.eprescription_items(eprescription_id);
create index idx_eprescription_items_product_id on public.eprescription_items(product_id);

-- Function to generate prescription number
create or replace function generate_prescription_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(prescription_number from '^RX([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.eprescriptions;
  new.prescription_number := 'RX' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_eprescriptions_number
before insert on public.eprescriptions
for each row execute function generate_prescription_number();

-- Trigger for updated_at
create trigger trigger_eprescriptions_updated_at
before update on public.eprescriptions
for each row execute function public.update_updated_at();

create trigger trigger_eprescription_items_updated_at
before update on public.eprescription_items
for each row execute function public.update_updated_at();

-- Function to log status changes
create or replace function log_eprescription_status_change()
returns trigger as $$
begin
  if old.status is distinct from new.status then
    insert into public.eprescription_history (
      eprescription_id,
      old_status,
      new_status,
      changed_by,
      notes,
      created_at
    ) values (
      new.id,
      old.status,
      new.status,
      coalesce(auth.uid(), null),
      null,
      now()
    );
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_eprescriptions_status_log
after update of status on public.eprescriptions
for each row execute function log_eprescription_status_change();

-- RLS
alter table public.eprescriptions enable row level security;
alter table public.eprescription_items enable row level security;
alter table public.eprescription_history enable row level security;

-- Patients view own prescriptions
create policy "Patients view own eprescriptions" on public.eprescriptions
  for select using (auth.uid() = patient_id);

-- Doctors view and manage own prescriptions
create policy "Doctors manage own prescriptions" on public.eprescriptions
  for all using (auth.uid() = doctor_id);

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), extension du
-- ticket C86 (bug identique, découvert par exécution réelle en vérifiant
-- que le correctif C86 était complet) : les 4 policies ci-dessous
-- référençaient elles aussi `public.pharmacy_staff`, table inexistante,
-- avec la même auto-comparaison tautologique (`pharmacy_id = pharmacy_id`)
-- que dans `loyalty.sql`. `20260827008500_loyalty.sql` n'était donc PAS le
-- seul fichier concerné, contrairement à ce que le premier scan statique
-- (grep) avait laissé penser — corrigé de la même manière ici.
--
-- Pharmacies view prescriptions sent to them
create policy "Pharmacies view prescriptions" on public.eprescriptions
  for select using (public.is_pharmacy_staff(pharmacy_id));

-- Pharmacies can update status (validate/dispense)
create policy "Pharmacies update prescriptions" on public.eprescriptions
  for update using (public.is_pharmacy_staff(pharmacy_id));

-- Patients can cancel their prescriptions
create policy "Patients cancel own prescriptions" on public.eprescriptions
  for update using (auth.uid() = patient_id)
  with check (status = 'cancelled');

-- Items visible with parent
create policy "Items visible with parent" on public.eprescription_items
  for select using (
    exists (
      select 1 from public.eprescriptions
      where id = eprescription_id and (
        patient_id = auth.uid() or
        doctor_id = auth.uid() or
        public.is_pharmacy_staff(eprescriptions.pharmacy_id)
      )
    )
  );

-- Items managed with parent
create policy "Items managed with parent" on public.eprescription_items
  for all using (
    exists (
      select 1 from public.eprescriptions
      where id = eprescription_id and doctor_id = auth.uid()
    )
  );

-- History visible with parent
create policy "History visible with parent" on public.eprescription_history
  for select using (
    exists (
      select 1 from public.eprescriptions
      where id = eprescription_id and (
        patient_id = auth.uid() or
        doctor_id = auth.uid() or
        public.is_pharmacy_staff(eprescriptions.pharmacy_id)
      )
    )
  );
