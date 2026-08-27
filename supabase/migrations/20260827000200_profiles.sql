-- Module auth (lib/modules/auth). Le fournisseur d'identité est Supabase
-- Auth (auth.users) — cette table ne fait qu'étendre auth.users des champs
-- propres au produit (rôle métier, correspondance GSG ID). Elle n'est pas
-- l'équivalent d'un GSG Referential (pays_id/langue_id/devise_id) : cette
-- brique du Kernel n'est pas encore branchée (voir PharmaConnect_CLAUDE.md).

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  full_name text,
  role text check (role in (
    'patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel', 'regulateur'
  )),
  -- KER-VIS-01 : correspondance vers le GSG ID / Org Registry, jamais une FK.
  gsg_id uuid,
  gsg_org_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Extension produit de auth.users : rôle métier + correspondance GSG ID (KER-ID-02/03). id = auth.users.id, jamais une clé locale distincte.';
comment on column public.profiles.gsg_id is
  'Correspondance vers l''identité GSG ID (Kernel). Nullable tant que le Kernel n''est pas branché en production (KER-INT-02/03).';
comment on column public.profiles.gsg_org_id is
  'Correspondance vers l''organisation GSG (Org Registry). Nullable tant que le Kernel n''est pas branché.';

create trigger set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check (auth.uid() = id);
