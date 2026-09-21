-- Fonction d'aide pour les policies RLS "back-office GSG" (Module 0 —
-- fondations transverses, audit du 29/08/2026).
--
-- Constat : plusieurs migrations écrites le 29/08 (business, network_admin,
-- returns, stock_forecasting, offline_sync) gatent des policies d'écriture
-- avec `exists (select 1 from public.profiles where id = auth.uid() and role
-- in ('admin', 'staff'))`. C'est inatteignable par construction :
-- `public.profiles.role` porte une contrainte CHECK qui n'autorise que
-- 'patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel',
-- 'regulateur' (voir 20260827000200_profiles.sql) — ni 'admin' ni 'staff' ne
-- peuvent jamais y être écrits. Le personnel back-office GSG est modélisé
-- séparément depuis le début du projet par `public.admin_users`
-- (20260827000500_admin.sql, avec son propre rôle
-- superAdmin/admin/pharmacyManager/regulator/auditor/support/viewer) —
-- exactement la même séparation que celle déjà documentée entre AuthProvider
-- (consumer) et AdminProvider (back-office) côté Dart. Cette fonction
-- centralise le bon test, sur le modèle de `is_pharmacy_staff()` déjà
-- introduite par 20260827002000_staff_write_policies.sql, pour que les
-- migrations suivantes n'aient plus à réinventer un test cassé.

create or replace function public.is_gsg_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
      and is_active = true
  );
$$;

comment on function public.is_gsg_admin() is
  'Vrai si l''utilisateur courant est un membre actif du personnel back-office GSG (public.admin_users, quel que soit son rôle précis). Remplace le test cassé `profiles.role in (''admin'',''staff'')` trouvé dans plusieurs migrations du 29/08/2026 — ''admin''/''staff'' ne sont pas des valeurs autorisées par la contrainte CHECK de profiles.role. Voir REFERENTIEL_ARCHITECTE.md, audit Module 0.';
