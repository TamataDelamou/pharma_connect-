-- Correctif C179 (Critique) : creation de profil impossible, erreur 42P17
-- « infinite recursion detected in policy for relation network_admin_roles ».
-- Constate le 27/09/2026 par execution locale : inscription via
-- /auth/v1/signup puis upsert du profil sous la session de l'utilisateur
-- (ProfileService.upsertProfile) -> HTTP 500, aucun profil cree.
--
-- Deux volets, aucune migration existante modifiee :
--
-- (a) log_network_activity() (20260829007000_network_admin.sql), declenche
--     sur public.profiles et public.pharmacies, n'etait pas SECURITY DEFINER :
--     l'ecriture dans network_activity_log se faisait sous les droits de
--     l'utilisateur, soumise a la policy « Network admins manage activity
--     log », reservee aux administrateurs reseau. Un patient qui cree son
--     profil ne pouvait donc pas ecrire la ligne de journal, et l'echec
--     faisait echouer l'upsert du profil. Le corps de la fonction n'est pas
--     modifie (il ne reference que des objets qualifies : public.* et
--     auth.uid()) ; seuls ses attributs changent.
--
-- (b) La policy « Network admins view group roles » de network_admin_roles
--     (20260829007000_network_admin.sql l.108-116) relisait
--     network_admin_roles elle-meme : recursion RLS, qui remontait aussi
--     dans les 7 autres policies lisant cette table (activity log, alerts x2,
--     pos_sales, customers, suppliers, cash_drawer_sessions). Seule cette
--     policy s'auto-lit (recherche par grep sur toutes les migrations) ; les
--     7 autres fonctionnent a nouveau une fois la recursion supprimee.
--     Remplacement de l'auto-lecture par une fonction SECURITY DEFINER
--     dediee, meme motif que is_group_member() (C125, CHN-5-bis) et
--     is_gsg_admin(). La semantique d'origine est conservee a l'identique :
--     l'appelant voit les roles d'un groupe s'il est super_admin ou
--     network_admin de ce groupe, ou super_admin de n'importe quel groupe.
--
-- Point ouvert, non tranche ici (C179) : perimetre du journal -- toute
-- modification de profil est journalisee, y compris celles des patients.

-- (a)
alter function public.log_network_activity()
  security definer
  set search_path = public;

-- (b)
create or replace function public.is_network_admin_for_group(target_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.network_admin_roles nar
    where nar.user_id = auth.uid()
      and nar.role in ('super_admin', 'network_admin')
      and (nar.pharmacy_group_id = target_group_id or nar.role = 'super_admin')
  );
$$;

comment on function public.is_network_admin_for_group(uuid) is
  'Vrai si l''utilisateur courant est super_admin ou network_admin du groupe target_group_id, ou super_admin de n''importe quel groupe. SECURITY DEFINER pour eviter la recursion RLS constatee (C179) quand une policy de network_admin_roles s''auto-interroge.';

drop policy if exists "Network admins view group roles" on public.network_admin_roles;
create policy "Network admins view group roles" on public.network_admin_roles
  for select using (public.is_network_admin_for_group(pharmacy_group_id));
