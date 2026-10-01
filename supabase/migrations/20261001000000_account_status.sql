-- C213 (décision D64) : état du compte pour l'application.
--
-- Depuis C211 (D58), un rôle déclaré n'ouvre aucun droit tant qu'il n'est pas
-- vérifié (has_verified_role). L'application affichait pourtant les menus du
-- rôle déclaré : un compte en attente n'obtenait qu'une suite de refus.
--
-- D64 : tant que son rôle n'est pas vérifié, le compte utilise l'application
-- comme un patient, avec un bandeau qui explique où en est la vérification ;
-- un pharmacien sans officine voit les invitations reçues et peut inscrire sa
-- propre officine.
--
-- my_account_status() renvoie, pour l'utilisateur connecté, l'état de son
-- rôle calculé avec exactement la même règle que has_verified_role(), et les
-- informations utiles au bandeau. Lecture seule ; aucun droit nouveau.

create or replace function public.my_account_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid         uuid := auth.uid();
  v_profile     public.profiles%rowtype;
  v_role        text;
  v_state       text;
  v_pharmacy    public.pharmacies%rowtype;
  v_application public.pharmacies%rowtype;
  v_pro         public.professional_profiles%rowtype;
  v_invitations integer;
  v_rejection   jsonb;
begin
  if v_uid is null then
    raise exception 'COMPTE: connexion requise' using errcode = '42501';
  end if;

  select * into v_profile from public.profiles where id = v_uid;
  v_role := coalesce(v_profile.role, 'patient');

  select count(*) into v_invitations
    from public.pharmacy_staff_invitations
   where invited_user_id = v_uid and status = 'pending';

  if v_profile.pharmacy_id is not null then
    select * into v_pharmacy from public.pharmacies where id = v_profile.pharmacy_id;
  end if;

  -- Dernière candidature d'officine déposée par l'utilisateur (titulaire).
  select * into v_application
    from public.pharmacies
   where manager_id = v_uid
   order by created_at desc
   limit 1;

  select * into v_pro from public.professional_profiles where id = v_uid;

  if v_role = 'patient' then
    v_state := 'patient';
    -- Refus d'un rôle par GSG (C214) : le compte est redevenu patient ; le
    -- dernier refus des 30 derniers jours est rendu à l'intéressé.
    select jsonb_build_object('role', a.changes->>'role', 'reason', a.changes->>'reason', 'at', a."timestamp")
      into v_rejection
      from public.audit_logs a
     where a.action = 'reject_role' and a.resource = 'user' and a.resource_id = v_uid::text
       and a."timestamp" > now() - interval '30 days'
     order by a."timestamp" desc
     limit 1;

  elsif v_role = 'pharmacien' then
    if v_pharmacy.id is not null and v_pharmacy.status in ('verified', 'active') then
      v_state := 'verified';
    elsif v_pharmacy.id is not null then
      v_state := 'pharmacy_inactive';
    elsif v_application.id is not null and v_application.status in ('pending', 'underReview') then
      v_state := 'pharmacy_application_pending';
    elsif v_application.id is not null and v_application.status = 'rejected' then
      v_state := 'pharmacy_application_rejected';
    else
      v_state := 'no_pharmacy';
    end if;

  elsif v_role = 'professionnel' then
    if v_pro.id is null then
      v_state := 'professional_profile_missing';
    elsif v_pro.is_verified then
      v_state := 'verified';
    elsif v_pro.verification_status = 'rejected' then
      v_state := 'professional_rejected';
    else
      v_state := 'pending_review';
    end if;

  else -- grossiste, livreur, regulateur
    v_state := case when v_profile.role_verified_at is not null then 'verified' else 'pending_review' end;
  end if;

  return jsonb_build_object(
    'role', v_role,
    'state', v_state,
    -- Même règle que les droits côté serveur.
    'role_active', v_role = 'patient' or public.has_verified_role(array[v_role]),
    'pharmacy', case when v_pharmacy.id is null then null else
      jsonb_build_object('id', v_pharmacy.id, 'name', v_pharmacy.name, 'status', v_pharmacy.status) end,
    'application', case when v_application.id is null then null else
      jsonb_build_object('id', v_application.id, 'name', v_application.name, 'status', v_application.status,
                         'submitted_at', v_application.created_at) end,
    'professional_status', v_pro.verification_status,
    'professional_rejection_reason', v_pro.rejection_reason,
    'pending_invitations', v_invitations,
    'last_role_rejection', v_rejection
  );
end;
$$;

comment on function public.my_account_status() is
  'C213 / D64 : état du compte connecté (patient, verified, pending_review, professional_profile_missing, professional_rejected, no_pharmacy, pharmacy_application_pending, pharmacy_application_rejected, pharmacy_inactive), role_active calculé par has_verified_role, officine, candidature, invitations en attente, dernier refus de rôle (30 jours). Lecture seule.';

revoke all on function public.my_account_status() from public, anon;
grant execute on function public.my_account_status() to authenticated;
