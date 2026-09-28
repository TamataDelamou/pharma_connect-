-- Correctif C193 : recus POS en stockage prive, liens a duree limitee.
--
-- Decision du porteur du projet (28/09/2026), option 1 : les recus vont dans
-- un bucket prive ; l'acces se fait par lien signe a duree limitee
-- (15 min consultation, 24 h export / telechargement), cree uniquement par
-- un membre du personnel de l'officine de la vente, connecte. La
-- consultation dans l'application passe par un telechargement authentifie
-- lie a la session, sans lien. Le lien public (getPublicUrl) est abandonne.
--
-- Avant cette migration, aucun bucket ni aucune policy storage.objects
-- n'existait : uploadBinary vers 'receipts' echouait faute de bucket.
-- Aucune migration existante modifiee.

-- 1. Bucket prive, PDF uniquement, 5 Mo max par recu.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 5242880, array['application/pdf'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Controle d'acces par chemin : '<pharmacy_id>/<sale_id>.pdf'.
-- Le premier dossier doit etre l'officine du pharmacien connecte.
-- Cast protege : un chemin mal forme renvoie false au lieu d'une erreur.
create or replace function public.is_pharmacy_staff_for_storage_path(p_object_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_pharmacy_id uuid;
begin
  begin
    v_pharmacy_id := ((storage.foldername(p_object_name))[1])::uuid;
  exception when others then
    return false;
  end;
  return public.is_pharmacy_staff(v_pharmacy_id);
end;
$$;

revoke all on function public.is_pharmacy_staff_for_storage_path(text) from public, anon;
grant execute on function public.is_pharmacy_staff_for_storage_path(text) to authenticated;

-- 3. Policies sur storage.objects, limitees au bucket 'receipts'.
-- Lecture, creation, remplacement (regeneration du recu).
-- Pas de suppression : un recu emis est une piece, on ne l'efface pas.
create policy "receipts_select_pharmacy_staff" on storage.objects
  for select to authenticated
  using (bucket_id = 'receipts' and public.is_pharmacy_staff_for_storage_path(name));

create policy "receipts_insert_pharmacy_staff" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'receipts' and public.is_pharmacy_staff_for_storage_path(name));

create policy "receipts_update_pharmacy_staff" on storage.objects
  for update to authenticated
  using (bucket_id = 'receipts' and public.is_pharmacy_staff_for_storage_path(name))
  with check (bucket_id = 'receipts' and public.is_pharmacy_staff_for_storage_path(name));

-- 4. On stocke le chemin, jamais une URL.
alter table public.pos_receipts add column if not exists receipt_path text;

comment on column public.pos_receipts.receipt_path is
  'C193 : chemin du PDF dans le bucket privé receipts (<pharmacy_id>/<sale_id>.pdf). Les liens sont générés à la demande (createSignedUrl, 15 min consultation / 24 h export), jamais stockés.';
comment on column public.pos_receipts.receipt_url is
  'Obsolète depuis C193 : contenait une URL publique. Plus écrite, vidée par cette migration.';

-- Aucun lien public ne doit survivre.
update public.pos_receipts set receipt_url = null where receipt_url is not null;
