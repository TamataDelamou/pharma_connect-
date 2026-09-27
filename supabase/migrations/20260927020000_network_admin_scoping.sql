-- Correctifs C180 (cloisonnement par groupe du module network_admin) et
-- C182 (Critique : network_dashboard lisible par anon et authenticated,
-- tous groupes). Aucune migration existante modifiee.
--
-- Constats (27/09/2026) :
--   - les politiques « Network admins… » de pos_sales, customers, suppliers,
--     cash_drawer_sessions, network_alerts (x2) et network_activity_log ne
--     testaient que role in ('super_admin', 'network_admin'), sans condition
--     sur le groupe : tout administrateur reseau lisait tous les groupes ;
--   - le journal network_activity_log etait modifiable et supprimable par
--     tout network_admin (politique for all), contraire a la brique Audit
--     du Kernel ;
--   - log_network_activity() lisait new sur DELETE (NULL) : suppressions
--     journalisees sans target_id ni details ;
--   - network_dashboard (vue materialisee, sans RLS possible) : meme motif
--     que C139, corrige ici comme daily_stats_scoped
--     (20260905070000_analytics_module_fixes.sql).
--
-- Rattachement d'une officine a un groupe : group_members (is_active), pas
-- pharmacies.group_id (cf. D45). network_dashboard, elle, agrege toujours
-- sur pharmacies.group_id (definition d'origine, non modifiee ici).

-- ==================== (a) is_network_admin_for_group ====================
-- Retrait de la clause « super_admin de n'importe quel groupe » (C179) :
-- un super_admin n'administre que son groupe ; le personnel GSG garde un
-- acces transverse via is_gsg_admin().

create or replace function public.is_network_admin_for_group(target_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_gsg_admin()
    or exists (
      select 1 from public.network_admin_roles nar
      where nar.user_id = auth.uid()
        and nar.role in ('super_admin', 'network_admin')
        and nar.pharmacy_group_id = target_group_id
    );
$$;

comment on function public.is_network_admin_for_group(uuid) is
  'Vrai si l''utilisateur courant est super_admin ou network_admin du groupe target_group_id, ou personnel GSG (is_gsg_admin()). SECURITY DEFINER pour eviter la recursion RLS constatee (C179). Cloisonnement par groupe : C180.';

-- ==================== (b) administers_pharmacy ====================

create or replace function public.administers_pharmacy(target_pharmacy_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_gsg_admin()
    or exists (
      select 1
      from public.group_members gm
      join public.network_admin_roles nar
        on nar.pharmacy_group_id = gm.group_id
      where gm.pharmacy_id = target_pharmacy_id
        and gm.is_active
        and nar.user_id = auth.uid()
        and nar.role in ('super_admin', 'network_admin')
    );
$$;

comment on function public.administers_pharmacy(uuid) is
  'Vrai si l''utilisateur courant est personnel GSG (is_gsg_admin()), ou super_admin/network_admin d''un groupe dont l''officine target_pharmacy_id est membre active (group_members.is_active). C180.';

-- ==================== (c) donnees d'officine ====================

drop policy if exists "Network admins view all POS" on public.pos_sales;
create policy "Network admins view all POS" on public.pos_sales
  for select using (public.administers_pharmacy(pharmacy_id));

drop policy if exists "Network admins view all sales" on public.customers;
create policy "Network admins view all sales" on public.customers
  for select using (public.administers_pharmacy(pharmacy_id));

drop policy if exists "Network admins view all suppliers" on public.suppliers;
create policy "Network admins view all suppliers" on public.suppliers
  for select using (public.administers_pharmacy(pharmacy_id));

drop policy if exists "Network admins view cash sessions" on public.cash_drawer_sessions;
create policy "Network admins view cash sessions" on public.cash_drawer_sessions
  for select using (public.administers_pharmacy(pharmacy_id));

-- ==================== (d) network_alerts ====================

drop policy if exists "Network admins view alerts" on public.network_alerts;
create policy "Network admins view alerts" on public.network_alerts
  for select using (public.is_network_admin_for_group(pharmacy_group_id));

drop policy if exists "Network admins manage alerts" on public.network_alerts;
create policy "Network admins manage alerts" on public.network_alerts
  for all
  using (public.is_network_admin_for_group(pharmacy_group_id))
  with check (public.is_network_admin_for_group(pharmacy_group_id));

-- ==================== (e) network_activity_log ====================
-- Pas de cle etrangere sur les deux colonnes : le journal doit survivre a la
-- suppression de l'officine ou du groupe, et le declencheur AFTER DELETE sur
-- pharmacies ecrit l'id d'une ligne qui n'existe deja plus.

alter table public.network_activity_log
  add column if not exists pharmacy_id uuid,
  add column if not exists pharmacy_group_id uuid;

create index if not exists idx_network_activity_log_pharmacy_id
  on public.network_activity_log(pharmacy_id);
create index if not exists idx_network_activity_log_pharmacy_group_id
  on public.network_activity_log(pharmacy_group_id);

-- Lecture seule pour tous les roles applicatifs : seul le declencheur
-- log_network_activity() (SECURITY DEFINER) ecrit dans le journal.
drop policy if exists "Network admins manage activity log" on public.network_activity_log;
create policy "Network admins view activity log" on public.network_activity_log
  for select using (
    public.is_gsg_admin()
    or public.administers_pharmacy(pharmacy_id)
    or public.is_network_admin_for_group(pharmacy_group_id)
  );

-- ==================== (f) log_network_activity ====================
-- Profils : seuls les comptes non patients sont journalises. Sur UPDATE, la
-- ligne est journalisee si l'ancien OU le nouveau role est professionnel,
-- pour garder la trace d'une promotion (patient -> pharmacien) ou d'un
-- retrait de role.

create or replace function public.log_network_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
  v_pharmacy_id uuid;
  v_group_id uuid;
  v_new_role text;
  v_old_role text;
begin
  v_row := coalesce(new, old);

  if TG_TABLE_NAME = 'profiles' then
    if TG_OP <> 'DELETE' then
      v_new_role := new.role;
    end if;
    if TG_OP <> 'INSERT' then
      v_old_role := old.role;
    end if;
    if coalesce(v_new_role, 'patient') = 'patient'
       and coalesce(v_old_role, 'patient') = 'patient' then
      return null;
    end if;
    v_pharmacy_id := v_row.pharmacy_id;
  elsif TG_TABLE_NAME = 'pharmacies' then
    v_pharmacy_id := v_row.id;
    v_group_id := v_row.group_id;
  end if;

  insert into public.network_activity_log (
    admin_user_id,
    action,
    target_type,
    target_id,
    details,
    pharmacy_id,
    pharmacy_group_id,
    created_at
  ) values (
    auth.uid(),
    TG_OP || ' ' || TG_TABLE_NAME,
    TG_TABLE_NAME,
    v_row.id,
    row_to_json(v_row),
    v_pharmacy_id,
    v_group_id,
    now()
  );
  return null;
end;
$$;

-- ==================== (g) network_dashboard (C182) ====================

revoke select on public.network_dashboard from anon, authenticated;

create view public.network_dashboard_scoped as
select nd.*
from public.network_dashboard nd
where public.is_gsg_admin() or public.is_network_admin_for_group(nd.group_id);

comment on view public.network_dashboard_scoped is
  'Vue d''acces pour network_dashboard (vue materialisee sans RLS possible) : is_gsg_admin() voit tous les groupes, un super_admin/network_admin ne voit que les siens. C182, meme motif que daily_stats_scoped (C139).';

grant select on public.network_dashboard_scoped to authenticated;
