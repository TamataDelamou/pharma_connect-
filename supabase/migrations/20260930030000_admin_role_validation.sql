-- Correctif C214 : validation des rôles et vérification des professionnels
-- depuis l'administration GSG.
--
-- Contexte : depuis C211 / C212 (décision D58), un rôle déclaré n'ouvre aucun
-- droit tant qu'il n'est pas vérifié : grossiste, livreur et régulateur par
-- profiles.role_verified_at, professionnel par
-- professional_profiles.is_verified, pharmacien par le rattachement à une
-- officine validée (C208). Aucun écran ne permettait de faire ces validations :
-- elles se faisaient en base.
--
-- Ce fichier fournit au back-office :
--   1. admin_list_verification_requests() : les comptes à rôle déclaré, avec
--      leur état de vérification (à valider, validé, refusé) ; avec une
--      recherche, les patients aussi (pour attribuer un rôle institutionnel à
--      un compte existant : un régulateur ne s'inscrit pas lui-même, D58).
--   2. admin_review_role() : valider ou refuser un grossiste, un livreur ou un
--      régulateur. Refus = retour au rôle patient, motif obligatoire.
--   3. admin_verify_professional() : vérifier ou rejeter une fiche
--      professionnelle (motif obligatoire pour un rejet).
--   4. admin_set_user_role() (C211) recréée à l'identique, avec journalisation.
-- Chaque action est journalisée dans audit_logs (resource 'user').
--
-- Toutes les fonctions exigent is_gsg_admin() (42501 sinon), sont SECURITY
-- DEFINER, et ne sont pas exécutables par anon. Les pharmaciens ne sont pas
-- validés ici : leur rattachement passe par la validation de l'officine
-- (écran Pharmacies, C208).
--
-- Aucune migration existante modifiée.

-- ==================== Journalisation ====================

-- Interne : appelée uniquement par les fonctions ci-dessous (SECURITY DEFINER,
-- exécutées sous leur propriétaire). Non exécutable par les clients.
create or replace function public.admin_audit_log(
  p_action text,
  p_resource_id text,
  p_changes jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (
    auth.uid(),
    coalesce(
      (select au.full_name from public.admin_users au
        where au.user_id = auth.uid() and au.is_active limit 1),
      'Administrateur GSG'
    ),
    p_action,
    'user',
    p_resource_id,
    p_changes,
    'RPC C214'
  );
end;
$$;

comment on function public.admin_audit_log(text, text, jsonb) is
  'C214 : journalise une action d''administration des rôles dans audit_logs (resource user). Interne, appelée par les fonctions admin_* ; non exécutable par les clients.';

revoke all on function public.admin_audit_log(text, text, jsonb) from public, anon, authenticated;

-- ==================== Liste des demandes ====================

create or replace function public.admin_list_verification_requests(
  p_state text default 'pending',
  p_search text default null
)
returns table (
  user_id uuid,
  full_name text,
  phone text,
  email text,
  declared_role text,
  verification_state text,
  created_at timestamptz,
  role_verified_at timestamptz,
  role_verified_by_name text,
  pharmacy_id uuid,
  pharmacy_name text,
  pharmacy_status text,
  professional_status text,
  license_number text,
  license_issuing_body text,
  license_expiry_date date,
  specialty text,
  rejection_reason text
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_search text := nullif(btrim(p_search), '');
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;
  if p_state is null or p_state not in ('pending', 'verified', 'rejected', 'all') then
    raise exception 'PROFIL: filtre % inconnu (pending, verified, rejected, all)', p_state
      using errcode = '22023';
  end if;

  return query
  with base as (
    select
      p.id,
      p.full_name,
      p.phone,
      u.email::text as email,
      p.role,
      p.created_at,
      p.role_verified_at,
      vb.full_name as verified_by_name,
      -- Officine : celle où le pharmacien est rattaché, sinon la plus récente
      -- dont il est titulaire (en attente de validation).
      coalesce(ph_att.id, ph_mgr.id) as ph_id,
      coalesce(ph_att.name, ph_mgr.name) as ph_name,
      coalesce(ph_att.status, ph_mgr.status) as ph_status,
      pp.id is not null as has_pro,
      pp.is_verified,
      pp.verification_status,
      pp.license_number,
      pp.license_issuing_body,
      pp.license_expiry_date,
      pp.specialty,
      pp.rejection_reason,
      case
        when p.role in ('grossiste', 'livreur', 'regulateur') then
          case when p.role_verified_at is not null then 'verified' else 'pending' end
        when p.role = 'professionnel' then
          case
            when coalesce(pp.is_verified, false) then 'verified'
            when pp.verification_status = 'rejected' then 'rejected'
            else 'pending'
          end
        when p.role = 'pharmacien' then
          case when p.pharmacy_id is not null then 'verified' else 'pending' end
        else 'none'
      end as state
    from public.profiles p
    left join auth.users u on u.id = p.id
    left join public.profiles vb on vb.id = p.role_verified_by
    left join public.pharmacies ph_att on ph_att.id = p.pharmacy_id
    left join lateral (
      select ph.id, ph.name, ph.status
        from public.pharmacies ph
        where ph.manager_id = p.id
        order by ph.created_at desc
        limit 1
    ) ph_mgr on true
    left join public.professional_profiles pp on pp.id = p.id
    where
      -- Sans recherche : uniquement les rôles soumis à vérification.
      -- Avec recherche : tous les comptes (y compris patients), pour
      -- attribuer un rôle institutionnel.
      (v_search is not null or coalesce(p.role, 'patient') <> 'patient')
      and (
        v_search is null
        or p.full_name ilike '%' || v_search || '%'
        or p.phone ilike '%' || v_search || '%'
        or u.email ilike '%' || v_search || '%'
      )
  )
  select
    b.id, b.full_name, b.phone, b.email, coalesce(b.role, 'patient'), b.state,
    b.created_at, b.role_verified_at, b.verified_by_name,
    b.ph_id, b.ph_name, b.ph_status,
    case when b.has_pro then coalesce(b.verification_status, 'pending') else null end,
    b.license_number, b.license_issuing_body, b.license_expiry_date,
    b.specialty, b.rejection_reason
  from base b
  where p_state = 'all'
     or b.state = p_state
     or (b.state = 'none' and v_search is not null)
  order by
    case b.state when 'pending' then 0 when 'rejected' then 1 when 'verified' then 2 else 3 end,
    b.created_at desc
  limit 200;
end;
$$;

comment on function public.admin_list_verification_requests(text, text) is
  'C214 : comptes à rôle déclaré et leur état de vérification (pending, verified, rejected), pour le back-office GSG. Avec p_search (nom, téléphone, e-mail), inclut aussi les patients. 200 lignes au plus. Réservée à is_gsg_admin().';

revoke all on function public.admin_list_verification_requests(text, text) from public, anon;
grant execute on function public.admin_list_verification_requests(text, text) to authenticated;

-- ==================== Grossiste, livreur, régulateur ====================

create or replace function public.admin_review_role(
  p_user_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;

  select role into v_role from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'PROFIL: utilisateur % introuvable', p_user_id using errcode = 'P0002';
  end if;
  if v_role is null or v_role not in ('grossiste', 'livreur', 'regulateur') then
    raise exception 'PROFIL: role % non concerne (grossiste, livreur, regulateur uniquement)',
      coalesce(v_role, 'patient') using errcode = '22023';
  end if;
  if p_approve is null then
    raise exception 'PROFIL: decision manquante' using errcode = '22023';
  end if;

  if p_approve then
    update public.profiles
      set role_verified_at = now(), role_verified_by = auth.uid()
      where id = p_user_id;
    perform public.admin_audit_log('approve_role', p_user_id::text,
      jsonb_build_object('role', v_role));
  else
    if v_reason is null or char_length(v_reason) < 3 then
      raise exception 'PROFIL: motif du refus obligatoire' using errcode = '22023';
    end if;
    -- Refus : le compte redevient patient ; le rôle refusé et le motif sont
    -- conservés dans le journal.
    update public.profiles
      set role = 'patient', role_verified_at = null, role_verified_by = null
      where id = p_user_id;
    perform public.admin_audit_log('reject_role', p_user_id::text,
      jsonb_build_object('role', v_role, 'reason', v_reason));
  end if;
end;
$$;

comment on function public.admin_review_role(uuid, boolean, text) is
  'C214 : validation (role_verified_at) ou refus d''un grossiste, livreur ou régulateur déclaré. Refus : retour au rôle patient, motif obligatoire, conservé dans audit_logs. Réservée à is_gsg_admin().';

revoke all on function public.admin_review_role(uuid, boolean, text) from public, anon;
grant execute on function public.admin_review_role(uuid, boolean, text) to authenticated;

-- ==================== Professionnels ====================

create or replace function public.admin_verify_professional(
  p_user_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;

  select role into v_role from public.profiles where id = p_user_id;
  if not found then
    raise exception 'PROFIL: utilisateur % introuvable', p_user_id using errcode = 'P0002';
  end if;
  if v_role is distinct from 'professionnel' then
    raise exception 'PROFIL: le compte n''est pas un professionnel de sante (role %)',
      coalesce(v_role, 'patient') using errcode = '22023';
  end if;
  perform 1 from public.professional_profiles where id = p_user_id for update;
  if not found then
    raise exception 'PROFIL: fiche professionnelle absente pour %', p_user_id
      using errcode = 'P0002';
  end if;
  if p_approve is null then
    raise exception 'PROFIL: decision manquante' using errcode = '22023';
  end if;

  if p_approve then
    update public.professional_profiles
      set is_verified = true, verification_status = 'verified',
          rejection_reason = null, updated_by = auth.uid()
      where id = p_user_id;
    perform public.admin_audit_log('verify_professional', p_user_id::text, null);
  else
    if v_reason is null or char_length(v_reason) < 3 then
      raise exception 'PROFIL: motif du rejet obligatoire' using errcode = '22023';
    end if;
    update public.professional_profiles
      set is_verified = false, verification_status = 'rejected',
          rejection_reason = v_reason, updated_by = auth.uid()
      where id = p_user_id;
    perform public.admin_audit_log('reject_professional', p_user_id::text,
      jsonb_build_object('reason', v_reason));
  end if;
end;
$$;

comment on function public.admin_verify_professional(uuid, boolean, text) is
  'C214 : vérification (is_verified, verification_status verified) ou rejet motivé (verification_status rejected, rejection_reason) d''une fiche professionnelle. Le rejet d''une fiche vérifiée retire la vérification. Réservée à is_gsg_admin().';

revoke all on function public.admin_verify_professional(uuid, boolean, text) from public, anon;
grant execute on function public.admin_verify_professional(uuid, boolean, text) to authenticated;

-- ==================== admin_set_user_role (C211), journalisée ====================

-- Même signature, même comportement que 20260930010000 ; ajout de la
-- journalisation.
create or replace function public.admin_set_user_role(
  p_user_id uuid,
  p_role text,
  p_verified boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_role text;
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;
  if p_role not in ('patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel', 'regulateur') then
    raise exception 'PROFIL: role % inconnu', p_role using errcode = '22023';
  end if;
  select role into v_old_role from public.profiles where id = p_user_id;
  update public.profiles
    set role = p_role,
        role_verified_at = case when p_verified then now() else null end,
        role_verified_by = case when p_verified then auth.uid() else null end
    where id = p_user_id;
  if not found then
    raise exception 'PROFIL: utilisateur % introuvable', p_user_id using errcode = 'P0002';
  end if;
  perform public.admin_audit_log('set_role', p_user_id::text,
    jsonb_build_object('old_role', v_old_role, 'role', p_role, 'verified', p_verified));
end;
$$;

comment on function public.admin_set_user_role(uuid, text, boolean) is
  'C211 / D58, journalisée depuis C214 : attribution du rôle d''un utilisateur et validation (role_verified_at / role_verified_by) par un administrateur GSG. Ne touche ni pharmacy_id (C208, C209) ni professional_profiles.';

revoke all on function public.admin_set_user_role(uuid, text, boolean) from public, anon;
grant execute on function public.admin_set_user_role(uuid, text, boolean) to authenticated;
