-- Correctifs C211 et C212 : role declare != role verifie. Verrouillage des
-- colonnes sensibles de profiles et professional_profiles, fonction de role
-- verifie, attribution des roles par l'administration GSG.
--
-- Constat (29/09/2026) :
--   1. Aucune creation de profil cote serveur : register_screen.dart propose
--      les six roles (dont « Regulateur / Institution ») et
--      ProfileService.upsertProfile() ecrit role directement dans profiles ;
--      profiles_insert_own n'impose rien sur role, profiles_update_own ne
--      restreint aucune colonne (20260827000200_profiles.sql).
--   2. pharmacy_id est modifiable par l'utilisateur : un patient se donne
--      role = 'pharmacien' et pharmacy_id = <officine> et devient
--      is_pharmacy_staff (preuve C211).
--   3. Des droits sont ouverts sur le seul role declare (tracabilite, rappels,
--      regulateur, triage, dossier de sante...) : voir
--      docs/audit/C211_inventaire_roles.md et la migration suivante
--      (20260930020000_role_policies_require_verification.sql).
--   4. C212 : la policy « Professionals can update own profile »
--      (20260827005500_professionals.sql) n'a ni with check ni restriction de
--      colonne ; un professionnel peut se declarer lui-meme verifie
--      (contournement de RG-PRE-01 et RG-INF-01).
--
-- Decision du porteur du projet (29/09/2026, registre D58) : un role declare
-- n'est pas un role verifie. Les droits ne s'ouvrent qu'apres verification :
-- pharmacien = rattachement a une officine validee (profiles.pharmacy_id, pose
-- uniquement par le declencheur C208) ; professionnel =
-- professional_profiles.is_verified, pose par un administrateur GSG ;
-- grossiste, livreur, regulateur = validation par un administrateur GSG
-- (role_verified_at). Le regulateur n'est plus propose a l'inscription.
-- Changement de role apres l'inscription : administrateur GSG uniquement.
--
-- Renvois : C208 (rattachement du titulaire, seul ecrivain legitime de
-- pharmacy_id cote serveur), C209 (rattachement du personnel non titulaire,
-- a construire cote serveur).
--
-- Verifications prealables : public.is_gsg_admin() est SECURITY DEFINER et ne
-- lit que public.admin_users (pas de recursion via profiles) ;
-- link_pharmacy_manager_on_verification() (C208) est SECURITY DEFINER : ses
-- ecritures sur profiles s'executent sous le proprietaire de la fonction et
-- ne sont pas bloquees par le verrou ci-dessous.
--
-- Aucune migration existante modifiee.

-- ==================== Traçabilité de la vérification ====================

alter table public.profiles
  add column role_verified_at timestamptz,
  add column role_verified_by uuid references public.profiles(id);

comment on column public.profiles.role_verified_at is
  'C211 / D58 : validation du rôle déclaré par un administrateur GSG (grossiste, livreur, régulateur). Null = rôle déclaré, non vérifié.';
comment on column public.profiles.role_verified_by is
  'C211 / D58 : administrateur GSG ayant validé le rôle.';

-- ==================== Verrouillage de profiles ====================

-- SECURITY INVOKER, volontairement : le déclencheur doit voir le vrai
-- current_user ('authenticated' pour un appel client, le propriétaire pour
-- une fonction SECURITY DEFINER, 'service_role', 'postgres' en migration).
create or replace function public.protect_profile_privileged_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Écritures faites par le serveur (fonctions SECURITY DEFINER comme le
  -- déclencheur C208, service_role, migrations) ou par un admin GSG : autorisées.
  if current_user not in ('authenticated', 'anon') or public.is_gsg_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.role := coalesce(new.role, 'patient');
    if new.role not in ('patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel') then
      raise exception 'PROFIL: le role % ne peut pas etre choisi a l''inscription', new.role
        using errcode = '42501';
    end if;
    if new.pharmacy_id is not null or new.role_verified_at is not null or new.role_verified_by is not null then
      raise exception 'PROFIL: rattachement et verification sont attribues par GSG'
        using errcode = '42501';
    end if;
    return new;
  end if;

  -- UPDATE : les colonnes sensibles ne changent pas (une valeur identique est
  -- acceptée, pour l'upsert de ProfileService).
  if new.role is distinct from old.role
     or new.pharmacy_id is distinct from old.pharmacy_id
     or new.role_verified_at is distinct from old.role_verified_at
     or new.role_verified_by is distinct from old.role_verified_by then
    raise exception 'PROFIL: role, rattachement et verification ne sont modifiables que par GSG'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

comment on function public.protect_profile_privileged_columns() is
  'C211 / D58 : un utilisateur ne peut ni choisir un rôle institutionnel à l''inscription, ni modifier ensuite role, pharmacy_id, role_verified_at, role_verified_by. Écritures serveur (SECURITY DEFINER, service_role, migrations) et administrateurs GSG non concernés.';

create trigger trigger_protect_profile_privileged_columns
  before insert or update on public.profiles
  for each row execute function public.protect_profile_privileged_columns();

-- ==================== Verrouillage de professional_profiles (C212) ====================

drop policy if exists "Professionals can update own profile" on public.professional_profiles;
create policy "Professionals can update own profile" on public.professional_profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.protect_professional_verification()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('authenticated', 'anon') or public.is_gsg_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.is_verified := false;
    new.verification_status := 'pending';
    new.rejection_reason := null;
    return new;
  end if;

  if new.is_verified is distinct from old.is_verified
     or new.verification_status is distinct from old.verification_status
     or new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'PROFIL: la verification d''un professionnel est attribuee par GSG'
      using errcode = '42501';
  end if;

  -- Licence modifiée sur une fiche vérifiée : nouvelle vérification
  -- nécessaire (sans erreur).
  if coalesce(old.is_verified, false)
     and (new.license_number is distinct from old.license_number
          or new.license_issuing_body is distinct from old.license_issuing_body
          or new.license_expiry_date is distinct from old.license_expiry_date) then
    new.is_verified := false;
    new.verification_status := 'pending';
  end if;
  return new;
end;
$$;

comment on function public.protect_professional_verification() is
  'C212 : is_verified, verification_status et rejection_reason ne sont posés que par l''administration GSG ; une modification de licence sur une fiche vérifiée la remet en attente de vérification.';

create trigger trigger_protect_professional_verification
  before insert or update on public.professional_profiles
  for each row execute function public.protect_professional_verification();

-- ==================== Rôle vérifié ====================

create or replace function public.has_verified_role(p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = any (p_roles)
      and (
        (p.role = 'pharmacien'    and p.pharmacy_id is not null)
        or (p.role = 'professionnel' and exists (
              select 1 from public.professional_profiles pp
              where pp.id = p.id and pp.is_verified = true))
        or (p.role in ('grossiste', 'livreur', 'regulateur') and p.role_verified_at is not null)
      )
  );
$$;

comment on function public.has_verified_role(text[]) is
  'C211 / D58 : vrai si l''utilisateur courant a l''un des rôles demandés ET que ce rôle est vérifié (pharmacien rattaché à une officine, professionnel vérifié, grossiste / livreur / régulateur validé par GSG). patient n''est jamais accepté.';

revoke all on function public.has_verified_role(text[]) from public, anon;
grant execute on function public.has_verified_role(text[]) to authenticated;

-- ==================== Attribution par l'administration GSG ====================

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
begin
  if not public.is_gsg_admin() then
    raise exception 'PROFIL: reserve a l''administration GSG' using errcode = '42501';
  end if;
  if p_role not in ('patient', 'pharmacien', 'grossiste', 'livreur', 'professionnel', 'regulateur') then
    raise exception 'PROFIL: role % inconnu', p_role using errcode = '22023';
  end if;
  update public.profiles
    set role = p_role,
        role_verified_at = case when p_verified then now() else null end,
        role_verified_by = case when p_verified then auth.uid() else null end
    where id = p_user_id;
  if not found then
    raise exception 'PROFIL: utilisateur % introuvable', p_user_id using errcode = 'P0002';
  end if;
end;
$$;

comment on function public.admin_set_user_role(uuid, text, boolean) is
  'C211 / D58 : attribution du rôle d''un utilisateur et validation (role_verified_at / role_verified_by) par un administrateur GSG. Ne touche ni pharmacy_id (C208, C209) ni professional_profiles.';

revoke all on function public.admin_set_user_role(uuid, text, boolean) from public, anon;
grant execute on function public.admin_set_user_role(uuid, text, boolean) to authenticated;
