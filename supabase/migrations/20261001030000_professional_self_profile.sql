-- C222 (décision D66) : fiche professionnelle créée par le professionnel.
--
-- Aucune règle n'autorisait un professionnel à créer sa fiche
-- (professional_profiles) : seule l'administration GSG le pouvait. Un compte
-- « professionnel » restait donc bloqué à l'état professional_profile_missing
-- (C213). Une fiche refusée par GSG ne pouvait pas non plus repartir en
-- vérification après correction : le statut restait « rejected ».
--
-- D66 : le professionnel crée lui-même sa fiche (spécialité, numéro d'ordre,
-- organisme, date d'expiration) ; elle part « en attente » et GSG la valide
-- depuis l'écran de vérification (C214). Une fiche refusée, corrigée sur sa
-- licence, repart en attente.

-- ============================================================
-- 1. Création par l'intéressé
-- ============================================================
drop policy if exists "Professionals can create own profile" on public.professional_profiles;
create policy "Professionals can create own profile" on public.professional_profiles
  for insert to authenticated
  with check (
    auth.uid() = id
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'professionnel')
  );

-- ============================================================
-- 2. Contrôles à l'écriture (déclencheur C212 étendu)
-- ============================================================
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
    -- C222 : une fiche créée par l'intéressé doit permettre la vérification.
    if nullif(btrim(coalesce(new.license_number, '')), '') is null
       or nullif(btrim(coalesce(new.license_issuing_body, '')), '') is null then
      raise exception 'PROFIL: numero d''ordre et organisme de delivrance obligatoires'
        using errcode = '22023';
    end if;
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

  -- Licence modifiée sur une fiche vérifiée ou refusée : nouvelle
  -- vérification nécessaire (sans erreur). C222 : une fiche refusée repart en
  -- attente et le motif du refus est effacé.
  if (coalesce(old.is_verified, false) or old.verification_status = 'rejected')
     and (new.license_number is distinct from old.license_number
          or new.license_issuing_body is distinct from old.license_issuing_body
          or new.license_expiry_date is distinct from old.license_expiry_date) then
    new.is_verified := false;
    new.verification_status := 'pending';
    new.rejection_reason := null;
  end if;
  return new;
end;
$$;
