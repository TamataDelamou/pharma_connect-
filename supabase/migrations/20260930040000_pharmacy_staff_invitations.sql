-- Correctif C209 : rattachement du personnel non titulaire à une officine
-- (décision D59, 30/09/2026).
--
-- Constat : profiles.pharmacy_id n'est écrit que par le déclencheur C208
-- (titulaire d'une officine validée) et, depuis C211, n'est plus modifiable
-- par l'utilisateur. Aucun employé ne pouvait donc être rattaché : seul le
-- titulaire pouvait travailler dans son officine.
--
-- Décision D59 :
--   1. Le titulaire (pharmacies.manager_id) d'une officine vérifiée ou active
--      invite un compte existant par son numéro de téléphone.
--   2. L'employé accepte (ou refuse) l'invitation dans l'application ; c'est
--      l'acceptation qui le rattache (profiles.pharmacy_id).
--   3. Le personnel s'inscrit avec le rôle « pharmacien » (vendeurs et
--      préparateurs compris) : aucune règle d'accès n'est réécrite,
--      is_pharmacy_staff() et has_verified_role() s'appliquent tels quels.
--   4. Le titulaire peut annuler une invitation en attente et retirer un
--      employé ; un employé peut quitter l'officine. Le titulaire ne peut pas
--      être retiré ainsi (son rattachement suit manager_id, C208).
--
-- La table pharmacy_staff_invitations garde la trace de chaque invitation
-- (auteur, réponse, retrait). Elle n'est écrite que par les fonctions
-- ci-dessous (SECURITY DEFINER), qui passent le verrou C211 sur
-- profiles.pharmacy_id parce qu'elles s'exécutent sous leur propriétaire.
--
-- Aucune migration existante modifiée.

-- ==================== Table ====================

create table public.pharmacy_staff_invitations (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  invited_user_id uuid not null references public.profiles(id) on delete cascade,
  invited_phone text,
  invited_by uuid references public.profiles(id) on delete set null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled', 'revoked', 'left')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  ended_at timestamptz,
  ended_by uuid references public.profiles(id) on delete set null
);

comment on table public.pharmacy_staff_invitations is
  'C209 / D59 : invitations du personnel d''officine par le titulaire. pending -> accepted (rattachement) | declined | cancelled ; accepted -> revoked (retrait par le titulaire) | left (départ de l''employé). Écrite uniquement par les fonctions pharmacy_*.';

-- Une seule invitation en attente par compte et par officine.
create unique index pharmacy_staff_invitations_one_pending
  on public.pharmacy_staff_invitations (pharmacy_id, invited_user_id)
  where status = 'pending';
create index pharmacy_staff_invitations_user
  on public.pharmacy_staff_invitations (invited_user_id, status);

alter table public.pharmacy_staff_invitations enable row level security;

-- Lecture : le titulaire de l'officine, le compte invité, l'administration GSG.
-- Aucune policy d'écriture : tout passe par les fonctions ci-dessous.
create policy pharmacy_staff_invitations_select on public.pharmacy_staff_invitations
  for select to authenticated
  using (
    invited_user_id = auth.uid()
    or public.is_gsg_admin()
    or exists (select 1 from public.pharmacies p
               where p.id = pharmacy_id and p.manager_id = auth.uid())
  );

-- ==================== Outil interne ====================

-- Vrai si l'utilisateur courant est titulaire de p_pharmacy_id et que
-- l'officine est vérifiée ou active.
create or replace function public.is_pharmacy_manager(p_pharmacy_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.pharmacies
    where id = p_pharmacy_id
      and manager_id = auth.uid()
      and status in ('verified', 'active')
  );
$$;

comment on function public.is_pharmacy_manager(uuid) is
  'C209 : vrai si l''utilisateur courant est le titulaire (manager_id) de l''officine, et qu''elle est vérifiée ou active.';

revoke all on function public.is_pharmacy_manager(uuid) from public, anon;
grant execute on function public.is_pharmacy_manager(uuid) to authenticated;

-- ==================== Inviter ====================

create or replace function public.pharmacy_invite_staff(
  p_pharmacy_id uuid,
  p_phone text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_digits text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_user_id uuid;
  v_count integer;
  v_role text;
  v_current_pharmacy uuid;
  v_invitation_id uuid;
begin
  if not public.is_pharmacy_manager(p_pharmacy_id) then
    raise exception 'OFFICINE: reserve au titulaire d''une officine validee' using errcode = '42501';
  end if;
  if char_length(v_digits) < 8 then
    raise exception 'OFFICINE: numero de telephone invalide' using errcode = '22023';
  end if;

  -- Recherche par les chiffres du numéro, dans le profil ou dans le compte
  -- d'authentification (Supabase stocke auth.users.phone sans « + »).
  select count(distinct p.id), min(p.id::text)::uuid
    into v_count, v_user_id
    from public.profiles p
    left join auth.users u on u.id = p.id
    where regexp_replace(coalesce(p.phone, ''), '[^0-9]', '', 'g') = v_digits
       or regexp_replace(coalesce(u.phone, ''), '[^0-9]', '', 'g') = v_digits;

  if v_count = 0 then
    raise exception 'OFFICINE: aucun compte inscrit avec ce numero' using errcode = 'P0002';
  end if;
  if v_count > 1 then
    raise exception 'OFFICINE: plusieurs comptes avec ce numero, contacter GSG' using errcode = '22023';
  end if;
  if v_user_id = auth.uid() then
    raise exception 'OFFICINE: le titulaire est deja rattache a son officine' using errcode = '22023';
  end if;

  select role, pharmacy_id into v_role, v_current_pharmacy
    from public.profiles where id = v_user_id;
  if v_role is distinct from 'pharmacien' then
    raise exception 'OFFICINE: le compte doit etre inscrit comme pharmacien (role actuel : %)',
      coalesce(v_role, 'patient') using errcode = '22023';
  end if;
  if v_current_pharmacy = p_pharmacy_id then
    raise exception 'OFFICINE: ce compte fait deja partie du personnel de l''officine' using errcode = '22023';
  end if;
  if v_current_pharmacy is not null then
    raise exception 'OFFICINE: ce compte est deja rattache a une autre officine' using errcode = '22023';
  end if;

  select id into v_invitation_id
    from public.pharmacy_staff_invitations
    where pharmacy_id = p_pharmacy_id and invited_user_id = v_user_id and status = 'pending';
  if found then
    raise exception 'OFFICINE: une invitation est deja en attente pour ce compte' using errcode = '22023';
  end if;

  insert into public.pharmacy_staff_invitations (pharmacy_id, invited_user_id, invited_phone, invited_by)
  values (p_pharmacy_id, v_user_id, p_phone, auth.uid())
  returning id into v_invitation_id;
  return v_invitation_id;
end;
$$;

comment on function public.pharmacy_invite_staff(uuid, text) is
  'C209 / D59 : le titulaire d''une officine validée invite un compte pharmacien non rattaché, retrouvé par son numéro de téléphone. Renvoie l''identifiant de l''invitation.';

revoke all on function public.pharmacy_invite_staff(uuid, text) from public, anon;
grant execute on function public.pharmacy_invite_staff(uuid, text) to authenticated;

-- ==================== Répondre ====================

create or replace function public.pharmacy_respond_invitation(
  p_invitation_id uuid,
  p_accept boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inv record;
  v_role text;
  v_current_pharmacy uuid;
  v_pharmacy_status text;
begin
  select * into v_inv from public.pharmacy_staff_invitations
    where id = p_invitation_id for update;
  if not found or v_inv.invited_user_id is distinct from auth.uid() then
    raise exception 'OFFICINE: invitation introuvable' using errcode = 'P0002';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'OFFICINE: invitation deja traitee (statut %)', v_inv.status using errcode = '22023';
  end if;
  if p_accept is null then
    raise exception 'OFFICINE: reponse manquante' using errcode = '22023';
  end if;

  if not p_accept then
    update public.pharmacy_staff_invitations
      set status = 'declined', responded_at = now()
      where id = p_invitation_id;
    return;
  end if;

  select role, pharmacy_id into v_role, v_current_pharmacy
    from public.profiles where id = auth.uid() for update;
  if v_role is distinct from 'pharmacien' then
    raise exception 'OFFICINE: le compte doit etre inscrit comme pharmacien' using errcode = '22023';
  end if;
  if v_current_pharmacy is not null then
    raise exception 'OFFICINE: compte deja rattache a une officine' using errcode = '22023';
  end if;
  select status into v_pharmacy_status from public.pharmacies where id = v_inv.pharmacy_id;
  if v_pharmacy_status is null or v_pharmacy_status not in ('verified', 'active') then
    raise exception 'OFFICINE: l''officine n''est plus validee' using errcode = '22023';
  end if;

  update public.profiles set pharmacy_id = v_inv.pharmacy_id where id = auth.uid();
  update public.pharmacy_staff_invitations
    set status = 'accepted', responded_at = now()
    where id = p_invitation_id;
  -- Les autres invitations en attente de ce compte deviennent sans objet.
  update public.pharmacy_staff_invitations
    set status = 'cancelled', ended_at = now()
    where invited_user_id = auth.uid() and status = 'pending' and id <> p_invitation_id;
end;
$$;

comment on function public.pharmacy_respond_invitation(uuid, boolean) is
  'C209 / D59 : le compte invité accepte (rattachement à l''officine, autres invitations annulées) ou refuse une invitation en attente.';

revoke all on function public.pharmacy_respond_invitation(uuid, boolean) from public, anon;
grant execute on function public.pharmacy_respond_invitation(uuid, boolean) to authenticated;

-- ==================== Annuler une invitation ====================

create or replace function public.pharmacy_cancel_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inv record;
begin
  select * into v_inv from public.pharmacy_staff_invitations
    where id = p_invitation_id for update;
  if not found then
    raise exception 'OFFICINE: invitation introuvable' using errcode = 'P0002';
  end if;
  if not public.is_pharmacy_manager(v_inv.pharmacy_id) then
    raise exception 'OFFICINE: reserve au titulaire d''une officine validee' using errcode = '42501';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'OFFICINE: invitation deja traitee (statut %)', v_inv.status using errcode = '22023';
  end if;
  update public.pharmacy_staff_invitations
    set status = 'cancelled', ended_at = now(), ended_by = auth.uid()
    where id = p_invitation_id;
end;
$$;

comment on function public.pharmacy_cancel_invitation(uuid) is
  'C209 / D59 : le titulaire annule une invitation encore en attente.';

revoke all on function public.pharmacy_cancel_invitation(uuid) from public, anon;
grant execute on function public.pharmacy_cancel_invitation(uuid) to authenticated;

-- ==================== Retirer un employé ====================

create or replace function public.pharmacy_remove_staff(
  p_pharmacy_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_pharmacy_manager(p_pharmacy_id) then
    raise exception 'OFFICINE: reserve au titulaire d''une officine validee' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'OFFICINE: le titulaire ne peut pas se retirer lui-meme' using errcode = '22023';
  end if;
  update public.profiles set pharmacy_id = null
    where id = p_user_id and pharmacy_id = p_pharmacy_id;
  if not found then
    raise exception 'OFFICINE: ce compte ne fait pas partie du personnel de l''officine' using errcode = 'P0002';
  end if;
  update public.pharmacy_staff_invitations
    set status = 'revoked', ended_at = now(), ended_by = auth.uid()
    where pharmacy_id = p_pharmacy_id and invited_user_id = p_user_id and status = 'accepted';
end;
$$;

comment on function public.pharmacy_remove_staff(uuid, uuid) is
  'C209 / D59 : le titulaire retire un employé (profiles.pharmacy_id remis à null, invitation acceptée passée à revoked). Le titulaire lui-même ne peut pas être retiré ainsi.';

revoke all on function public.pharmacy_remove_staff(uuid, uuid) from public, anon;
grant execute on function public.pharmacy_remove_staff(uuid, uuid) to authenticated;

-- ==================== Quitter l'officine ====================

create or replace function public.pharmacy_leave()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pharmacy_id uuid;
begin
  select pharmacy_id into v_pharmacy_id from public.profiles where id = auth.uid() for update;
  if v_pharmacy_id is null then
    raise exception 'OFFICINE: aucun rattachement a quitter' using errcode = '22023';
  end if;
  if exists (select 1 from public.pharmacies where id = v_pharmacy_id and manager_id = auth.uid()) then
    raise exception 'OFFICINE: le titulaire ne peut pas quitter son officine (changement de titulaire par GSG)'
      using errcode = '22023';
  end if;
  update public.profiles set pharmacy_id = null where id = auth.uid();
  update public.pharmacy_staff_invitations
    set status = 'left', ended_at = now(), ended_by = auth.uid()
    where pharmacy_id = v_pharmacy_id and invited_user_id = auth.uid() and status = 'accepted';
end;
$$;

comment on function public.pharmacy_leave() is
  'C209 / D59 : un employé (non titulaire) quitte son officine.';

revoke all on function public.pharmacy_leave() from public, anon;
grant execute on function public.pharmacy_leave() to authenticated;

-- ==================== Personnel et invitations d'une officine ====================

create or replace function public.pharmacy_list_staff(p_pharmacy_id uuid)
returns table (
  kind text,
  user_id uuid,
  invitation_id uuid,
  full_name text,
  phone text,
  is_manager boolean,
  status text,
  since timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  if not (public.is_pharmacy_manager(p_pharmacy_id) or public.is_gsg_admin()) then
    raise exception 'OFFICINE: reserve au titulaire d''une officine validee' using errcode = '42501';
  end if;

  return query
  select 'member'::text, pr.id, inv.id, pr.full_name, pr.phone,
         (ph.manager_id = pr.id), 'active'::text,
         coalesce(inv.responded_at, pr.created_at)
    from public.profiles pr
    join public.pharmacies ph on ph.id = p_pharmacy_id
    left join lateral (
      select i.id, i.responded_at from public.pharmacy_staff_invitations i
       where i.pharmacy_id = p_pharmacy_id and i.invited_user_id = pr.id and i.status = 'accepted'
       order by i.responded_at desc nulls last limit 1
    ) inv on true
    where pr.pharmacy_id = p_pharmacy_id
  union all
  select 'invitation'::text, i.invited_user_id, i.id, pr.full_name,
         coalesce(pr.phone, i.invited_phone), false, i.status, i.created_at
    from public.pharmacy_staff_invitations i
    join public.profiles pr on pr.id = i.invited_user_id
    where i.pharmacy_id = p_pharmacy_id and i.status = 'pending'
  order by 1 desc, 6 desc, 4;
end;
$$;

comment on function public.pharmacy_list_staff(uuid) is
  'C209 / D59 : personnel rattaché à l''officine (titulaire en tête) et invitations en attente. Réservée au titulaire et à l''administration GSG.';

revoke all on function public.pharmacy_list_staff(uuid) from public, anon;
grant execute on function public.pharmacy_list_staff(uuid) to authenticated;

-- ==================== Mes invitations ====================

create or replace function public.pharmacy_my_invitations()
returns table (
  invitation_id uuid,
  pharmacy_id uuid,
  pharmacy_name text,
  pharmacy_address text,
  invited_by_name text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  return query
  select i.id, ph.id, ph.name, ph.address, inviter.full_name, i.created_at
    from public.pharmacy_staff_invitations i
    join public.pharmacies ph on ph.id = i.pharmacy_id
    left join public.profiles inviter on inviter.id = i.invited_by
    where i.invited_user_id = auth.uid() and i.status = 'pending'
    order by i.created_at desc;
end;
$$;

comment on function public.pharmacy_my_invitations() is
  'C209 / D59 : invitations en attente adressées à l''utilisateur courant.';

revoke all on function public.pharmacy_my_invitations() from public, anon;
grant execute on function public.pharmacy_my_invitations() to authenticated;
