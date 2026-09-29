-- Correctif C200 : scans d'ordonnances en stockage prive.
--
-- scanner_service.dart televersait l'image dans un bucket 'prescriptions'
-- jamais cree, puis publiait getPublicUrl() dans scanned_prescriptions :
-- donnees de sante nominatives lisibles par quiconque possede le lien.
--
-- Regle d'acces : aucune nouvelle decision. Le fichier suit exactement la
-- regle deja validee pour les lignes scanned_prescriptions (PRE-7, Module 25,
-- 20260830050000_eprescription_module_fixes.sql) : lecture par le patient
-- proprietaire et par is_gsg_admin() ; ecriture, remplacement et suppression
-- par le proprietaire seul (meme portee que la policy "for all" de la ligne).
-- Motif repris de C193 (20260928000000_pos_receipts_private_storage.sql) :
-- bucket prive, controle par chemin, chemin stocke au lieu d'une URL.
--
-- Aucune migration existante modifiee.

-- 1. Bucket prive, images uniquement, 10 Mo max.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('prescriptions', 'prescriptions', false, 10485760,
        array['image/jpeg', 'image/png'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Proprietaire du chemin '<patient_id>/<scan_id>.jpg'.
-- Cast protege, meme motif que is_pharmacy_staff_for_storage_path (C193).
create or replace function public.is_storage_path_owner(p_object_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  begin
    v_owner_id := ((storage.foldername(p_object_name))[1])::uuid;
  exception when others then
    return false;
  end;
  return v_owner_id = auth.uid();
end;
$$;

revoke all on function public.is_storage_path_owner(text) from public, anon;
grant execute on function public.is_storage_path_owner(text) to authenticated;

-- 3. Policies alignees sur celles de la table (PRE-7).
create policy "prescription_scans_select_owner_or_gsg_admin" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'prescriptions'
    and (public.is_storage_path_owner(name) or public.is_gsg_admin())
  );

create policy "prescription_scans_insert_owner" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'prescriptions' and public.is_storage_path_owner(name));

create policy "prescription_scans_update_owner" on storage.objects
  for update to authenticated
  using (bucket_id = 'prescriptions' and public.is_storage_path_owner(name))
  with check (bucket_id = 'prescriptions' and public.is_storage_path_owner(name));

create policy "prescription_scans_delete_owner" on storage.objects
  for delete to authenticated
  using (bucket_id = 'prescriptions' and public.is_storage_path_owner(name));

-- 4. On stocke le chemin, jamais une URL.
alter table public.scanned_prescriptions add column if not exists image_path text;
alter table public.scanned_prescriptions alter column image_url drop not null;

comment on column public.scanned_prescriptions.image_path is
  'C200 : chemin de l''image dans le bucket privé prescriptions (<patient_id>/<scan_id>.jpg). Lue par téléchargement authentifié ; aucune URL stockée.';
comment on column public.scanned_prescriptions.image_url is
  'Obsolète depuis C200 : contenait une URL publique. Plus écrite, vidée par cette migration.';

update public.scanned_prescriptions set image_url = null where image_url is not null;
