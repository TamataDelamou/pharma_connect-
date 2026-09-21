-- Real-time wait times per department
create table public.hospital_wait_times (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  department text not null,
  wait_time_minutes integer not null,
  patients_in_queue integer default 0,
  last_updated timestamptz not null default now(),
  is_accurate boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(hospital_id, department)
);

-- Indexes
create index idx_hospital_wait_times_hospital_id on public.hospital_wait_times(hospital_id);

-- RLS
alter table public.hospital_wait_times enable row level security;

-- Everyone can view wait times
create policy "Everyone view hospital wait times" on public.hospital_wait_times
  for select using (true);

-- Audit Module 23 (HOP), Étape 3 (30/08/2026), HOP-1 : voir le commentaire
-- détaillé dans 20260827006000_hospitals.sql — même motif « rôle
-- inatteignable », 5ème et dernière occurrence pour ce module. Correctif
-- appliqué dans 20260830048000_hospitals_module_fixes.sql, pas ici
-- (`is_gsg_admin()` n'existe qu'à partir du 29/08/2026, cette migration
-- est datée du 28/08/2026 — un appel direct casse le rejeu chronologique).
create policy "Staff manage wait times" on public.hospital_wait_times
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );
