-- C219 (décision D63) : accès d'urgence au dossier de santé (« bris de glace »)
-- et interactions professionnelles limitées au lien de soin.
--
-- Depuis C216 (D61), un professionnel ne voit le dossier de santé d'un patient
-- qu'avec une consultation ou un soin à domicile créés par le patient. Aux
-- urgences, le médecin qui prend en charge un patient n'a donc pas accès à son
-- dossier.
--
-- D63 :
--   1. Un professionnel vérifié, affilié à l'hôpital où le patient est au
--      triage (prise en charge en cours), peut déclarer une urgence avec un
--      motif écrit. L'accès au dossier est immédiat, dure 24 heures et se
--      renouvelle par une nouvelle déclaration (nouveau motif).
--   2. Chaque déclaration est tracée (table emergency_access_grants et journal
--      audit_logs), visible par le patient, par le professionnel et par
--      l'administration GSG. Le patient, le professionnel ou GSG peuvent y
--      mettre fin avant l'échéance.
--   3. Les interactions professional_patient_interactions ne peuvent plus être
--      créées ou modifiées que pour un patient avec qui le professionnel a un
--      lien de soin (consultation, soin à domicile ou urgence déclarée).
--
-- Les interactions déjà enregistrées ne sont pas supprimées : elles n'ouvrent
-- aucun accès depuis C216.

-- ============================================================
-- 1. Table des accès d'urgence
-- ============================================================
create table public.emergency_access_grants (
  id                uuid primary key default gen_random_uuid(),
  patient_id        uuid not null references public.profiles(id) on delete cascade,
  professional_id   uuid not null references public.profiles(id) on delete cascade,
  hospital_id       uuid not null references public.hospitals(id) on delete cascade,
  triage_patient_id uuid references public.triage_patients(id) on delete set null,
  reason            text not null check (length(btrim(reason)) >= 10),
  granted_at        timestamptz not null default now(),
  expires_at        timestamptz not null,
  ended_at          timestamptz,
  ended_by          uuid references auth.users(id),
  check (expires_at > granted_at),
  check (ended_at is null or ended_by is not null)
);

comment on table public.emergency_access_grants is
  'C219 / D63 : accès d''urgence (bris de glace) d''un professionnel au dossier de santé d''un patient pris en charge au triage. Créé uniquement par declare_emergency_access(), terminé par end_emergency_access(). Visible par le patient, le professionnel et GSG.';

create index idx_emergency_access_active
  on public.emergency_access_grants (professional_id, patient_id, expires_at)
  where ended_at is null;
create index idx_emergency_access_patient
  on public.emergency_access_grants (patient_id, granted_at desc);

alter table public.emergency_access_grants enable row level security;

-- Lecture seule : aucune écriture directe, tout passe par les fonctions.
revoke all on public.emergency_access_grants from public, anon;
revoke insert, update, delete, truncate on public.emergency_access_grants from authenticated;
grant select on public.emergency_access_grants to authenticated;

create policy "Emergency access visible to parties and GSG"
  on public.emergency_access_grants for select to authenticated
  using (patient_id = auth.uid() or professional_id = auth.uid() or public.is_gsg_admin());

-- ============================================================
-- 2. Lien de soin : ajout de l'accès d'urgence en cours
-- ============================================================
create or replace function public.has_care_relationship(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_verified_role(array['professionnel'])
    and (
      exists (select 1 from public.consultations c
               where c.professional_id = auth.uid()
                 and c.patient_id = p_patient_id
                 and c.status <> 'cancelled')
      or exists (select 1 from public.homecare_interventions h
                  where h.professional_id = auth.uid()
                    and h.patient_id = p_patient_id
                    and h.status <> 'cancelled')
      or exists (select 1 from public.emergency_access_grants g
                  where g.professional_id = auth.uid()
                    and g.patient_id = p_patient_id
                    and g.ended_at is null
                    and g.expires_at > now()
                    and public.is_hospital_professional(g.hospital_id))
    );
$$;

comment on function public.has_care_relationship(uuid) is
  'C216 / D61, C219 / D63 : vrai si l''utilisateur courant est un professionnel vérifié ayant, avec ce patient, une consultation ou un soin à domicile non annulés (rendez-vous créés par le patient), ou un accès d''urgence en cours (déclaré depuis le triage, 24 heures, affiliation à l''hôpital toujours active). Les interactions professional_patient_interactions ne comptent pas.';

revoke all on function public.has_care_relationship(uuid) from public, anon;
grant execute on function public.has_care_relationship(uuid) to authenticated;

-- ============================================================
-- 3. Déclaration d'une urgence
-- ============================================================
create or replace function public.declare_emergency_access(
  p_triage_patient_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid     uuid := auth.uid();
  v_triage  public.triage_patients%rowtype;
  v_reason  text := btrim(coalesce(p_reason, ''));
  v_grant   public.emergency_access_grants%rowtype;
begin
  if v_uid is null or not public.has_verified_role(array['professionnel']) then
    raise exception 'URGENCE: réservé aux professionnels de santé vérifiés'
      using errcode = '42501';
  end if;

  select * into v_triage from public.triage_patients where id = p_triage_patient_id;

  -- Même refus que le triage soit inconnu ou d'un autre hôpital : pas
  -- d'indication sur l'existence d'une prise en charge ailleurs.
  if not found or v_triage.hospital_id is null
     or not public.is_hospital_professional(v_triage.hospital_id) then
    raise exception 'URGENCE: accès refusé à cette prise en charge (affiliation à l''hôpital requise)'
      using errcode = '42501';
  end if;

  if v_triage.status not in ('waiting', 'in_assessment', 'assigned') then
    raise exception 'URGENCE: la prise en charge est terminée (patient sorti ou transféré)'
      using errcode = '22023';
  end if;

  if length(v_reason) < 10 then
    raise exception 'URGENCE: motif obligatoire (10 caractères au moins)'
      using errcode = '22023';
  end if;

  insert into public.emergency_access_grants
    (patient_id, professional_id, hospital_id, triage_patient_id, reason, expires_at)
  values
    (v_triage.patient_id, v_uid, v_triage.hospital_id, v_triage.id, v_reason, now() + interval '24 hours')
  returning * into v_grant;

  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (
    v_uid,
    coalesce((select full_name from public.profiles where id = v_uid), 'Professionnel'),
    'emergency_access_granted',
    'health_record',
    v_grant.patient_id::text,
    jsonb_build_object(
      'grant_id', v_grant.id,
      'triage_patient_id', v_grant.triage_patient_id,
      'hospital_id', v_grant.hospital_id,
      'reason', v_grant.reason,
      'expires_at', v_grant.expires_at
    ),
    'RPC C219'
  );

  return v_grant.id;
end;
$$;

comment on function public.declare_emergency_access(uuid, text) is
  'C219 / D63 : bris de glace. Professionnel vérifié affilié à l''hôpital du triage (prise en charge en cours), motif de 10 caractères au moins. Ouvre le dossier de santé du patient pendant 24 heures, tracé dans emergency_access_grants et audit_logs.';

revoke all on function public.declare_emergency_access(uuid, text) from public, anon;
grant execute on function public.declare_emergency_access(uuid, text) to authenticated;

-- ============================================================
-- 4. Fin anticipée d'un accès d'urgence
-- ============================================================
create or replace function public.end_emergency_access(p_grant_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_grant public.emergency_access_grants%rowtype;
begin
  if v_uid is null then
    raise exception 'URGENCE: connexion requise' using errcode = '42501';
  end if;

  select * into v_grant from public.emergency_access_grants where id = p_grant_id for update;

  if not found or not (v_grant.patient_id = v_uid
                       or v_grant.professional_id = v_uid
                       or public.is_gsg_admin()) then
    raise exception 'URGENCE: accès d''urgence introuvable' using errcode = '42501';
  end if;

  if v_grant.ended_at is not null or v_grant.expires_at <= now() then
    raise exception 'URGENCE: cet accès d''urgence est déjà terminé' using errcode = '22023';
  end if;

  update public.emergency_access_grants
     set ended_at = now(), ended_by = v_uid
   where id = v_grant.id;

  insert into public.audit_logs (user_id, user_name, action, resource, resource_id, changes, user_agent)
  values (
    v_uid,
    coalesce((select full_name from public.profiles where id = v_uid), 'Utilisateur'),
    'emergency_access_ended',
    'health_record',
    v_grant.patient_id::text,
    jsonb_build_object(
      'grant_id', v_grant.id,
      'ended_by_role', case when v_uid = v_grant.patient_id then 'patient'
                            when v_uid = v_grant.professional_id then 'professionnel'
                            else 'gsg' end
    ),
    'RPC C219'
  );
end;
$$;

comment on function public.end_emergency_access(uuid) is
  'C219 / D63 : met fin à un accès d''urgence en cours. Appelable par le patient, le professionnel concerné ou l''administration GSG. Tracé dans audit_logs.';

revoke all on function public.end_emergency_access(uuid) from public, anon;
grant execute on function public.end_emergency_access(uuid) to authenticated;

-- ============================================================
-- 5. Liste lisible (noms du professionnel, du patient et de l'hôpital)
-- ============================================================
create or replace function public.list_emergency_access()
returns table (
  id uuid,
  patient_id uuid,
  patient_name text,
  professional_id uuid,
  professional_name text,
  hospital_name text,
  reason text,
  granted_at timestamptz,
  expires_at timestamptz,
  ended_at timestamptz,
  is_active boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select g.id, g.patient_id, pp.full_name, g.professional_id, pr.full_name, h.name,
         g.reason, g.granted_at, g.expires_at, g.ended_at,
         (g.ended_at is null and g.expires_at > now())
  from public.emergency_access_grants g
  left join public.profiles pp on pp.id = g.patient_id
  left join public.profiles pr on pr.id = g.professional_id
  left join public.hospitals h on h.id = g.hospital_id
  where auth.uid() is not null
    and (g.patient_id = auth.uid() or g.professional_id = auth.uid() or public.is_gsg_admin())
  order by g.granted_at desc
  limit 200;
$$;

comment on function public.list_emergency_access() is
  'C219 / D63 : accès d''urgence visibles par l''appelant (en tant que patient ou professionnel ; tous pour GSG), avec les noms, du plus récent au plus ancien.';

revoke all on function public.list_emergency_access() from public, anon;
grant execute on function public.list_emergency_access() to authenticated;

-- ============================================================
-- 6. Interactions : limitées au lien de soin
-- ============================================================
drop policy if exists "Professionals view own interactions" on public.professional_patient_interactions;

create policy "Professionals view own interactions"
  on public.professional_patient_interactions for select to authenticated
  using (auth.uid() = professional_id);

create policy "Care team can record interactions"
  on public.professional_patient_interactions for insert to authenticated
  with check (auth.uid() = professional_id and public.has_care_relationship(patient_id));

create policy "Professionals update own interactions"
  on public.professional_patient_interactions for update to authenticated
  using (auth.uid() = professional_id)
  with check (auth.uid() = professional_id and public.has_care_relationship(patient_id));

create policy "Professionals delete own interactions"
  on public.professional_patient_interactions for delete to authenticated
  using (auth.uid() = professional_id);
