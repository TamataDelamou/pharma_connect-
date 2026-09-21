-- RG-AUT-01 : un compte pharmacie ne peut être activé qu'après vérification
-- de la licence. La table public.pharmacies (20260827000400_pharmacies.sql)
-- porte déjà tout le vocabulaire nécessaire (status, license_number,
-- license_verified_at, manager_id) et le documente explicitement dans son
-- propre commentaire — mais elle n'avait jusqu'ici qu'une policy SELECT :
-- aucune écriture n'était possible, ni pour un pharmacien soumettant sa
-- licence, ni pour le back-office GSG l'approuvant. C'est la cause directe
-- du constat de l'audit Module 1 (29/08/2026) : license_verification_screen.dart
-- ne persistait rien nulle part (délai simulé), et profiles.pharmacy_id —
-- volontairement laissé vide à l'auto-inscription par
-- 20260827002000_staff_write_policies.sql, "réservé à l'assignation
-- post-vérification de licence" — n'avait donc aucun mécanisme réel pour
-- être un jour renseigné. Toute la chaîne d'autorisation is_pharmacy_staff()
-- construite depuis Module 0 en dépend : sans ce correctif, aucun pharmacien
-- réel ne peut jamais satisfaire une policy d'écriture staff officine.

-- latitude/longitude étaient NOT NULL, ce qui supposait une création
-- exclusivement back-office (géocodage connu à la création). Un pharmacien
-- soumettant sa propre licence en auto-inscription ne connaît pas ses
-- coordonnées précises : nullable ici, à compléter par le back-office lors
-- de la vérification (ou par géocodage automatique de l'adresse, hors
-- périmètre de ce module).
alter table public.pharmacies alter column latitude drop not null;
alter table public.pharmacies alter column longitude drop not null;

comment on column public.pharmacies.latitude is
  'Nullable depuis l''audit Module 1 (29/08/2026) : une soumission pharmacien en auto-inscription ne fournit pas de coordonnées précises. À compléter par le back-office lors de la vérification.';
comment on column public.pharmacies.longitude is
  'Voir commentaire sur la colonne latitude.';

-- Un pharmacien authentifié peut soumettre UNE candidature d'officine (la
-- sienne), toujours à l'état 'pending' — jamais 'verified'/'active' à
-- l'auto-inscription, conformément à RG-AUT-01. La lecture est déjà ouverte
-- (pharmacies_select_authenticated), aucune policy supplémentaire requise
-- pour que le pharmacien revoie sa propre soumission en attente.
create policy "pharmacies_insert_own_pending" on public.pharmacies
  for insert to authenticated
  with check (
    manager_id = auth.uid()
    and status = 'pending'
  );

-- Seul le back-office GSG (public.admin_users, is_gsg_admin()) peut faire
-- progresser une candidature (pending -> verified/active/rejected/underReview)
-- ou corriger une fiche existante.
create policy "pharmacies_update_admin" on public.pharmacies
  for update to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- Rattachement automatique : dès qu'une officine passe à 'verified' ou
-- 'active', son manager (profiles.id = pharmacies.manager_id) reçoit son
-- pharmacy_id — le seul point du code qui écrit cette colonne, exactement
-- comme documenté par 20260827002000_staff_write_policies.sql ("rempli
-- après vérification de licence, jamais à l'auto-inscription"). SECURITY
-- DEFINER : la policy UPDATE de profiles (profiles_update_own) ne permet
-- qu'à l'utilisateur lui-même de modifier sa ligne, jamais à un tiers même
-- admin — ce trigger a besoin de ses propres privilèges pour accomplir ce
-- que RG-AUT-01 exige.
create or replace function public.link_pharmacy_manager_on_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status in ('verified', 'active')
     and old.status not in ('verified', 'active')
     and new.manager_id is not null then
    update public.profiles
    set pharmacy_id = new.id
    where id = new.manager_id;

    if new.license_verified_at is null then
      new.license_verified_at := now();
    end if;
  end if;
  return new;
end;
$$;

comment on function public.link_pharmacy_manager_on_verification() is
  'Implémente RG-AUT-01 : renseigne profiles.pharmacy_id du manager dès que sa pharmacie passe pending -> verified/active. Seul point d''écriture de cette colonne (voir 20260827002000_staff_write_policies.sql).';

create trigger trigger_link_pharmacy_manager
  before update on public.pharmacies
  for each row execute function public.link_pharmacy_manager_on_verification();
