-- Module recall (lib/modules/recall). Rappels de lots et pharmacovigilance.

create table if not exists public.recalls (
  id uuid primary key default gen_random_uuid(),
  reference_number text not null unique,
  title text not null,
  description text not null,
  severity text not null check (severity in ('classI', 'classII', 'classIII')),
  status text not null default 'draft' check (status in (
    'draft', 'inProgress', 'completed', 'cancelled'
  )),
  issued_at timestamptz not null default now(),
  completed_at timestamptz,
  issued_by text not null,
  issued_by_user_id uuid references auth.users(id),
  reason text,
  corrective_action text,
  distribution_instructions text,
  is_public boolean not null default true,
  total_affected_units integer,
  units_returned integer default 0,
  units_destroyed integer default 0,
  units_unrecovered integer default 0,
  notified_parties text[],
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.recalls is 'Rappels de lots (recall/models/recall.dart).';

create index if not exists idx_recalls_status on public.recalls(status);

create trigger set_updated_at
  before update on public.recalls
  for each row execute function public.set_updated_at();

create table if not exists public.recall_affected_batches (
  id uuid primary key default gen_random_uuid(),
  recall_id uuid not null references public.recalls(id) on delete cascade,
  batch_id uuid references public.traceable_batches(id),
  batch_number text not null,
  product_id uuid references public.products(id),
  product_name text not null,
  total_units integer not null default 0,
  units_recalled integer not null default 0,
  units_returned integer not null default 0,
  units_destroyed integer not null default 0,
  status text not null default 'pending' check (status in (
    'pending', 'inProgress', 'completed', 'partial', 'cancelled'
  )),
  notes text
);

comment on table public.recall_affected_batches is 'Lots concernés par un rappel (recall/models/recall_affected_batch.dart).';

create index if not exists idx_recall_affected_batches_recall_id on public.recall_affected_batches(recall_id);
create index if not exists idx_recall_affected_batches_batch_id on public.recall_affected_batches(batch_id);

alter table public.recalls enable row level security;
alter table public.recall_affected_batches enable row level security;

create policy "recalls_select_authenticated" on public.recalls
  for select to authenticated using (true);

create policy "recall_affected_batches_select_authenticated" on public.recall_affected_batches
  for select to authenticated using (true);
