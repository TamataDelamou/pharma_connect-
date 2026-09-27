-- Correctif C183 (Eleve) : network_activity_log.admin_user_id referencait
-- public.profiles(id) en « on delete cascade » (20260829007000_network_admin.sql) :
-- supprimer un profil effacait les lignes du journal correspondant a ses
-- actions, contournant l'immutabilite du journal etablie par C180.
--
-- Deux volets, aucune migration existante modifiee :
--
-- (a) « on delete set null ». La ligne de journal survit a la suppression du
--     profil ; admin_user_id NULL signifie alors « auteur supprime » (ou
--     action systeme sans session, cf. C132). Nom de la contrainte releve en
--     base (pg_constraint), non devine.
--
-- (b) Suppression d'un profil sous la session de son propre titulaire
--     (auth.uid() = id supprime) : log_network_activity() ecrivait auth.uid()
--     dans admin_user_id, qui ne reference plus aucun profil a ce moment
--     (declencheur AFTER DELETE) -> violation de cle etrangere, la
--     suppression echouait. Bloque avant (cascade) comme apres (set null).
--     L'auteur est desormais auth.uid() seulement s'il existe une ligne dans
--     profiles pour cet id, sinon NULL. Le reste de la fonction est
--     inchange (20260927020000_network_admin_scoping.sql).

-- (a)
alter table public.network_activity_log
  drop constraint network_activity_log_admin_user_id_fkey;

alter table public.network_activity_log
  add constraint network_activity_log_admin_user_id_fkey
  foreign key (admin_user_id) references public.profiles(id) on delete set null;

-- (b)
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
  v_author uuid;
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

  select p.id into v_author from public.profiles p where p.id = auth.uid();

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
    v_author,
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
