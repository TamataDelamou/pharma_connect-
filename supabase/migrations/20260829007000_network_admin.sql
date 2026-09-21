-- Network Admin module: Centralized administration for pharmacy networks

-- Network admin roles (extends profiles)
create table public.network_admin_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('super_admin', 'network_admin', 'pharmacy_manager', 'viewer')),
  pharmacy_group_id uuid references public.pharmacy_groups(id) on delete cascade,
  permissions jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(user_id, pharmacy_group_id)
);

-- Network dashboard views (cached aggregates)
create materialized view network_dashboard as
select
  pg.id as group_id,
  pg.name as group_name,
  count(distinct p.id) as pharmacy_count,
  count(distinct ps.id) as total_sales,
  coalesce(sum(ps.final_amount), 0) as total_revenue,
  count(distinct s.id) as total_stock_items,
  count(distinct a.id) as active_alerts,
  count(distinct u.id) as total_users
from pharmacy_groups pg
left join pharmacies p on p.group_id = pg.id
left join pos_sales ps on ps.pharmacy_id = p.id and ps.status = 'completed'
left join stock_items s on s.pharmacy_id = p.id
left join alerts a on a.pharmacy_id = p.id and a.status = 'active'
left join profiles u on u.pharmacy_id = p.id
group by pg.id, pg.name;

-- Network activity log
create table public.network_activity_log (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid not null references public.profiles(id) on delete cascade,
  action text not null,
  target_type text not null, -- 'pharmacy', 'user', 'group', 'stock', 'pos', 'contract'
  target_id uuid,
  details jsonb default '{}'::jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Network alerts (for network admins)
create table public.network_alerts (
  id uuid primary key default gen_random_uuid(),
  pharmacy_group_id uuid references public.pharmacy_groups(id) on delete cascade,
  severity text not null check (severity in ('critical', 'high', 'medium', 'low')),
  type text not null check (type in ('stock', 'sales', 'user', 'system', 'compliance')),
  title text not null,
  description text,
  is_read boolean default false,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_network_admin_roles_user_id on public.network_admin_roles(user_id);
create index idx_network_admin_roles_group_id on public.network_admin_roles(pharmacy_group_id);
create index idx_network_admin_roles_role on public.network_admin_roles(role);
create index idx_network_activity_log_admin_user_id on public.network_activity_log(admin_user_id);
create index idx_network_activity_log_created_at on public.network_activity_log(created_at);
create index idx_network_alerts_group_id on public.network_alerts(pharmacy_group_id);
create index idx_network_alerts_severity on public.network_alerts(severity);

-- Triggers for updated_at
create trigger trigger_network_admin_roles_updated_at
before update on public.network_admin_roles
for each row execute function public.update_updated_at();

create trigger trigger_network_alerts_updated_at
before update on public.network_alerts
for each row execute function public.update_updated_at();

-- RLS
alter table public.network_admin_roles enable row level security;
alter table public.network_activity_log enable row level security;
alter table public.network_alerts enable row level security;

-- Super admin can manage all
-- (audit Module 0, 29/08/2026 : `profiles.role = 'admin'` est inatteignable —
-- la contrainte CHECK de public.profiles.role n'autorise pas 'admin', voir
-- 20260827000200_profiles.sql. Le personnel back-office GSG est modélisé par
-- public.admin_users ; on utilise le helper centralisé is_gsg_admin(),
-- cf. 20260829003800_admin_helpers.sql.)
create policy "Super admin manage network roles" on public.network_admin_roles
  for all using (public.is_gsg_admin());

-- Users view their own roles
create policy "Users view own network roles" on public.network_admin_roles
  for select using (auth.uid() = user_id);

-- Network admins view roles in their group
create policy "Network admins view group roles" on public.network_admin_roles
  for select using (
    exists (
      select 1 from public.network_admin_roles nar
      where nar.user_id = auth.uid()
      and nar.role in ('super_admin', 'network_admin')
      and (nar.pharmacy_group_id = network_admin_roles.pharmacy_group_id or nar.role = 'super_admin')
    )
  );

-- Network admins manage activity log
create policy "Network admins manage activity log" on public.network_activity_log
  for all using (
    exists (
      select 1 from public.network_admin_roles
      where user_id = auth.uid() and role in ('super_admin', 'network_admin')
    )
  );

-- Network admins view alerts
create policy "Network admins view alerts" on public.network_alerts
  for select using (
    exists (
      select 1 from public.network_admin_roles
      where user_id = auth.uid() and role in ('super_admin', 'network_admin')
    )
  );

-- Network admins manage alerts
create policy "Network admins manage alerts" on public.network_alerts
  for all using (
    exists (
      select 1 from public.network_admin_roles
      where user_id = auth.uid() and role in ('super_admin', 'network_admin')
    )
  );

-- Network admins view all POS sales
-- (audit Module 0, 29/08/2026 : cette policy figurait à l'origine dans
-- 20260829006000_pos_and_network_admin.sql, neutralisé pour cause de
-- doublon de tables avec 20260829006000_pos.sql et le présent fichier ;
-- elle est réintroduite ici, seul endroit de la chronologie des migrations
-- où public.pos_sales [20260829006000_pos.sql] ET
-- public.network_admin_roles [ce fichier] existent déjà toutes les deux.)
create policy "Network admins view all POS" on public.pos_sales
  for select using (
    exists (
      select 1 from public.network_admin_roles
      where user_id = auth.uid() and role in ('super_admin', 'network_admin')
    )
  );

-- Function to log network activity
create or replace function log_network_activity()
returns trigger as $$
begin
  insert into public.network_activity_log (
    admin_user_id,
    action,
    target_type,
    target_id,
    details,
    created_at
  ) values (
    auth.uid(),
    TG_OP || ' ' || TG_TABLE_NAME,
    TG_TABLE_NAME,
    new.id,
    row_to_json(new),
    now()
  );
  return new;
end;
$$ language plpgsql;

-- Triggers for activity logging
create trigger trigger_log_pharmacy_changes
after insert or update or delete on public.pharmacies
for each row execute function log_network_activity();

create trigger trigger_log_user_changes
after insert or update or delete on public.profiles
for each row execute function log_network_activity();

-- Function to refresh network dashboard
create or replace function refresh_network_dashboard()
returns void as $$
begin
  refresh materialized view concurrently network_dashboard;
end;
$$ language plpgsql;

-- Function to create network alert
create or replace function create_network_alert(
  p_group_id uuid,
  p_severity text,
  p_type text,
  p_title text,
  p_description text
)
returns void as $$
begin
  insert into public.network_alerts (
    pharmacy_group_id,
    severity,
    type,
    title,
    description,
    created_at,
    updated_at,
    created_by,
    updated_by
  ) values (
    p_group_id,
    p_severity,
    p_type,
    p_title,
    p_description,
    now(),
    now(),
    auth.uid(),
    auth.uid()
  );
end;
$$ language plpgsql;

-- Seed default network admin role (super_admin)
-- Note: This should be assigned manually or via admin panel
