-- Offline sync queue
create table sync_queue (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  table_name text not null,
  record_id text not null,
  operation text not null check (operation in ('insert', 'update', 'delete')),
  data jsonb not null,
  status text default 'pending' check (status in ('pending', 'syncing', 'completed', 'failed')),
  retry_count integer default 0,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Offline availability for homecare
create table homecare_offline_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  professional_id uuid not null references public.profiles(id) on delete cascade,
  plan_data jsonb not null,
  synced_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_sync_queue_patient_id on public.sync_queue(patient_id);
create index idx_sync_queue_status on public.sync_queue(status);
create index idx_homecare_offline_plans_patient_id on public.homecare_offline_plans(patient_id);
create index idx_homecare_offline_plans_professional_id on public.homecare_offline_plans(professional_id);

-- RLS
alter table public.sync_queue enable row level security;
alter table public.homecare_offline_plans enable row level security;

-- Patients manage own sync queue
create policy "Patients manage own sync queue" on public.sync_queue
  for all using (auth.uid() = patient_id);

-- Patients view own offline plans
create policy "Patients view own offline plans" on public.homecare_offline_plans
  for select using (auth.uid() = patient_id);

-- Professionals view assigned offline plans
create policy "Professionals view assigned offline plans" on public.homecare_offline_plans
  for select using (auth.uid() = professional_id);

-- Staff manage all
-- (audit Module 0, 29/08/2026 : role in ('admin','staff') sur profiles est
-- inatteignable, voir 20260829003800_admin_helpers.sql.)
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87 (même nature
-- bloquante, même piège déjà documenté ailleurs dans le projet pour
-- `is_gsg_admin()`) : ce fichier est daté du 28/08, AVANT
-- `20260829003800_admin_helpers.sql` (29/08) qui définit
-- `public.is_gsg_admin()` — le correctif Module 0 ci-dessus avait remplacé
-- le motif « rôle inatteignable » par un appel à cette fonction sans tenir
-- compte de l'ordre chronologique des migrations, provoquant
-- `ERROR: function public.is_gsg_admin() does not exist` à l'application
-- de CETTE migration, avant même d'atteindre celle qui la définit —
-- confirmé bloquant par exécution réelle. Corrigé en inlinant l'équivalent
-- directement (même principe que dans
-- `20260828020000_professional_reviews.sql`, voir C79).
create policy "Staff manage offline plans" on public.homecare_offline_plans
  for all using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );
