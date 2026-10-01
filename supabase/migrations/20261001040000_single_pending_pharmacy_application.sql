-- C224 (relevé pendant C213) : une seule candidature d'officine en attente
-- par titulaire.
--
-- La règle pharmacies_insert_own_pending (20260829013000) laissait tout
-- utilisateur connecté déposer un nombre illimité de candidatures, quel que
-- soit son rôle déclaré : un même compte pouvait encombrer la file de
-- vérification de GSG, et un patient pouvait déposer une candidature.
--
-- Correctif : la candidature est réservée à un compte déclaré pharmacien, et
-- un titulaire ne peut avoir qu'une candidature en attente (pending ou
-- underReview) à la fois. Une candidature refusée, ou une officine déjà
-- validée, n'empêche pas d'en déposer une nouvelle. GSG et le serveur ne sont
-- pas concernés.

drop policy if exists "pharmacies_insert_own_pending" on public.pharmacies;
create policy "pharmacies_insert_own_pending" on public.pharmacies
  for insert to authenticated
  with check (
    manager_id = auth.uid()
    and status = 'pending'
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'pharmacien')
  );

create or replace function public.guard_single_pending_pharmacy_application()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.manager_id is null or new.status not in ('pending', 'underReview') then
    return new;
  end if;
  -- Écritures serveur et administration GSG non concernées (même convention
  -- que les déclencheurs C211 / C212, SECURITY INVOKER pour voir le vrai
  -- current_user).
  if current_user not in ('authenticated', 'anon') or public.is_gsg_admin() then
    return new;
  end if;

  -- Deux soumissions simultanées du même compte : la seconde attend la
  -- première, puis voit sa candidature.
  perform pg_advisory_xact_lock(hashtext('pharmacy_application:' || new.manager_id::text));

  if exists (select 1 from public.pharmacies
              where manager_id = new.manager_id
                and status in ('pending', 'underReview')) then
    raise exception 'OFFICINE: une candidature est deja en cours de verification pour ce compte'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

comment on function public.guard_single_pending_pharmacy_application() is
  'C224 : une seule candidature d''officine en attente (pending, underReview) par titulaire ; GSG et serveur non concernés.';

revoke all on function public.guard_single_pending_pharmacy_application() from public, anon, authenticated;

drop trigger if exists trigger_single_pending_pharmacy_application on public.pharmacies;
create trigger trigger_single_pending_pharmacy_application
  before insert on public.pharmacies
  for each row execute function public.guard_single_pending_pharmacy_application();
