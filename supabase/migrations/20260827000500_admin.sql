-- Module admin (lib/modules/admin). Répertoire du personnel back-office
-- (distinct de public.profiles, qui couvre tous les utilisateurs de l'app
-- y compris les patients — même séparation que côté Dart entre AuthProvider
-- et AdminProvider), journal d'audit et configuration système.

create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  email text not null unique,
  full_name text not null,
  phone text,
  role text not null check (role in (
    'superAdmin', 'admin', 'pharmacyManager', 'regulator', 'auditor', 'support', 'viewer'
  )),
  permissions text[] not null default '{}',
  is_active boolean not null default true,
  is_verified boolean not null default false,
  created_by uuid references auth.users(id),
  notes text,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.admin_users is 'Personnel back-office et ses permissions (admin/models/admin_user.dart).';

create index if not exists idx_admin_users_user_id on public.admin_users(user_id);

create trigger set_updated_at
  before update on public.admin_users
  for each row execute function public.set_updated_at();

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  user_name text not null,
  action text not null,
  resource text not null,
  resource_id text not null,
  changes jsonb,
  ip_address text,
  user_agent text,
  is_success boolean not null default true,
  error_message text,
  "timestamp" timestamptz not null default now()
);

comment on table public.audit_logs is
  'Journal d''audit centralisé (admin/models/audit_log.dart). Infalsifiable par construction applicative : aucune politique UPDATE/DELETE définie ci-dessous.';

create index if not exists idx_audit_logs_resource on public.audit_logs(resource, resource_id);
create index if not exists idx_audit_logs_timestamp on public.audit_logs("timestamp" desc);

create table if not exists public.system_configs (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  value text not null,
  category text not null,
  description text,
  is_editable boolean not null default true,
  updated_by text not null,
  updated_at timestamptz not null default now()
);

comment on table public.system_configs is 'Paramètres système clé/valeur (admin/models/system_config.dart).';

alter table public.admin_users enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_configs enable row level security;

create policy "admin_users_select_authenticated" on public.admin_users
  for select to authenticated using (true);

create policy "audit_logs_select_authenticated" on public.audit_logs
  for select to authenticated using (true);

create policy "system_configs_select_authenticated" on public.system_configs
  for select to authenticated using (true);
