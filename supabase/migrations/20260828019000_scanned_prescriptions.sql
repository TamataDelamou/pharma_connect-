-- Scanned prescriptions (temporary storage before digitization)
create table scanned_prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  image_url text not null,
  ocr_result jsonb,
  extracted_items jsonb,
  status text default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table public.scanned_prescriptions enable row level security;

-- Patients manage own scans
create policy "Patients manage own scanned prescriptions" on public.scanned_prescriptions
  for all using (auth.uid() = patient_id);

-- Staff view all scans
create policy "Staff view scanned prescriptions" on public.scanned_prescriptions
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );
