-- Correctif C208 : rattachement du titulaire a son officine (RG-AUT-01).
--
-- Constat (preparation de C204, 29/09/2026) : profiles.pharmacy_id du
-- titulaire (pharmacies.manager_id) n'etait renseigne que par
-- link_pharmacy_manager_on_verification() (20260829013000_pharmacy_registration.sql),
-- au seul passage d'une officine de pending a verified/active. Deux cas y
-- echappaient :
--   a) une officine inseree directement 'verified' ou 'active' avec un
--      manager_id (aucun declencheur a l'insertion) ;
--   b) un changement de manager_id sur une officine deja verified/active :
--      le nouveau titulaire n'etait pas rattache, l'ancien restait rattache.
-- Or toute la chaine d'autorisation officine (is_pharmacy_staff(), donc
-- stock_apply_movement, pos_create_sale, pos_refund_sale...) repose sur
-- profiles.pharmacy_id. Decision du porteur du projet (29/09/2026) : corriger
-- la cause (le rattachement) plutot que d'elargir les controles d'acces au
-- titulaire.
--
-- Correctif :
--   - fonction du declencheur recreee (meme nom, declencheur BEFORE UPDATE
--     existant conserve) : couvre aussi le changement de titulaire ;
--   - nouveau declencheur AFTER INSERT (AFTER : profiles.pharmacy_id est une
--     cle etrangere vers pharmacies, la ligne doit exister) ;
--   - rattrapage des titulaires non rattaches, par une fonction dediee
--     (reutilisable et testable), sans jamais ecraser une valeur differente.
--
-- Hors perimetre : le role n'est pas modifie (is_pharmacy_staff() exige
-- role = 'pharmacien') ; aucun mecanisme de rattachement du personnel non
-- titulaire (C209) ; is_pharmacy_staff() ignore le statut de l'officine
-- (C210).
--
-- Aucune migration existante modifiee.

create or replace function public.link_pharmacy_manager_on_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    -- AFTER INSERT : officine créée directement verified/active.
    if new.status in ('verified', 'active') and new.manager_id is not null then
      update public.profiles
        set pharmacy_id = new.id
        where id = new.manager_id;
    end if;
    return new;
  end if;

  -- BEFORE UPDATE.
  -- Changement de titulaire : l'ancien est détaché, seulement s'il était
  -- rattaché à cette officine.
  if old.manager_id is not null
     and old.manager_id is distinct from new.manager_id then
    update public.profiles
      set pharmacy_id = null
      where id = old.manager_id
        and pharmacy_id = new.id;
  end if;

  -- Rattachement du titulaire : au passage à verified/active (comportement
  -- d'origine), ou au changement de titulaire d'une officine verified/active.
  if new.status in ('verified', 'active')
     and new.manager_id is not null
     and (old.status not in ('verified', 'active')
          or old.manager_id is distinct from new.manager_id) then
    update public.profiles
      set pharmacy_id = new.id
      where id = new.manager_id;
  end if;

  if new.status in ('verified', 'active')
     and old.status not in ('verified', 'active')
     and new.license_verified_at is null then
    new.license_verified_at := now();
  end if;

  return new;
end;
$$;

comment on function public.link_pharmacy_manager_on_verification() is
  'Implémente RG-AUT-01 (C208) : renseigne profiles.pharmacy_id du titulaire (manager_id) quand l''officine passe pending -> verified/active, quand elle est insérée directement verified/active, et quand son titulaire change (nouveau rattaché, ancien détaché s''il pointait sur cette officine). Seul point d''écriture de cette colonne (voir 20260827002000_staff_write_policies.sql).';

create trigger trigger_link_pharmacy_manager_insert
  after insert on public.pharmacies
  for each row execute function public.link_pharmacy_manager_on_verification();

-- ==================== Rattrapage ====================

-- Rattache le titulaire de chaque officine verified/active dont le profil n'a
-- pas de pharmacy_id. Une valeur différente n'est jamais écrasée : elle est
-- signalée (raise notice). Renvoie le nombre de titulaires rattachés.
create or replace function public.attach_unlinked_pharmacy_managers()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
  v_count integer := 0;
begin
  for v_row in
    select ph.id as pharmacy_id, ph.name, ph.manager_id, pr.pharmacy_id as current_pharmacy_id
      from public.pharmacies ph
      join public.profiles pr on pr.id = ph.manager_id
      where ph.status in ('verified', 'active')
        and pr.pharmacy_id is distinct from ph.id
  loop
    if v_row.current_pharmacy_id is null then
      update public.profiles set pharmacy_id = v_row.pharmacy_id where id = v_row.manager_id;
      v_count := v_count + 1;
    else
      raise notice 'C208 : titulaire % de l''officine % (%) deja rattache a l''officine %, non modifie',
        v_row.manager_id, v_row.name, v_row.pharmacy_id, v_row.current_pharmacy_id;
    end if;
  end loop;
  return v_count;
end;
$$;

comment on function public.attach_unlinked_pharmacy_managers() is
  'C208 : rattrapage de profiles.pharmacy_id des titulaires d''officines verified/active non rattachés. N''écrase jamais une valeur différente (raise notice). Réservée à l''administration de la base.';

revoke all on function public.attach_unlinked_pharmacy_managers() from public, anon, authenticated;

do $$
declare
  v_count integer;
begin
  v_count := public.attach_unlinked_pharmacy_managers();
  raise notice 'C208 : % titulaire(s) rattache(s) par le rattrapage', v_count;
end;
$$;
