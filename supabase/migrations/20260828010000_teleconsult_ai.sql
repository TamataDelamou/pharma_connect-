-- AI pre-consultation sessions
create table pre_consultation_sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  consultation_id uuid references public.consultations(id) on delete set null,
  symptoms text,
  analysis jsonb default '{}'::jsonb,
  specialty_suggestion text,
  urgency_level integer check (urgency_level between 1 and 5),
  is_critical boolean default false,
  summary text,
  status text default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Decision tree nodes
create table decision_tree_nodes (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references decision_tree_nodes(id) on delete cascade,
  question text not null,
  options jsonb, -- array of {label, next_node_id}
  leaf_result text, -- if leaf, contains specialty or recommendation
  is_leaf boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table pre_consultation_sessions enable row level security;
alter table decision_tree_nodes enable row level security;

-- Patients can view and manage their own sessions
create policy "Patients manage own sessions" on pre_consultation_sessions
  for all using (auth.uid() = patient_id);

-- Staff can view all sessions (for monitoring)
create policy "Staff view all sessions" on pre_consultation_sessions
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff')
    )
  );

-- Everyone can view decision tree (read-only)
create policy "Everyone view decision tree" on decision_tree_nodes
  for select using (true);

-- Only admin can manage decision tree
create policy "Admin manage decision tree" on decision_tree_nodes
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
