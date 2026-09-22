-- Audit Module 5 (ORD — Ordonnances numériques), 29/08/2026.
--
-- 1) prescriptions/prescription_items (20260827001000) n'avaient QUE des
--    policies SELECT (patient propriétaire). Sans policy INSERT, aucun
--    patient ne pouvait réellement téléverser d'ordonnance (RLS refuse par
--    défaut) ; sans policy UPDATE, aucun pharmacien ne pouvait valider/
--    dispenser — le flux entier décrit par le cahier (RG-ORD, « dépôt par
--    le patient jusqu'à la validation par le pharmacien ») était donc
--    irréalisable côté base, quel que soit ce qu'affichait l'écran.
--    Le commentaire d'origine différait volontairement cette policy staff
--    « une fois qu'un mécanisme de vérification de rôle existera » — ce
--    fondement existe depuis is_pharmacy_staff()/is_gsg_admin() (Module 0/1).
--
-- 2) `prescriptions` n'a pas de colonne pharmacy_id : contrairement au stock
--    (Module 4), le cahier ne précise pas quelle officine valide une
--    ordonnance déposée par OCR (aucune sélection d'officine à l'upload
--    côté écran). Inventer un rattachement officine ici serait spéculatif
--    (même discipline que le commentaire d'origine) — la policy staff
--    ci-dessous est donc volontairement non scopée par officine (tout
--    compte role='pharmacien' peut valider/dispenser n'importe quelle
--    ordonnance). Voir registre des écarts (item architecture) : décision
--    produit à trancher avant une éventuelle mise en cohérence avec le
--    modèle multi-officines.
--
-- 3) eprescriptions (20260827009500) a un bug RLS distinct et plus grave :
--    `exists (select 1 from pharmacy_staff where user_id = auth.uid() and
--    pharmacy_id = pharmacy_id)` compare la colonne pharmacy_staff.pharmacy_id
--    à elle-même (ambiguïté SQL résolue par la colonne la plus proche dans
--    la sous-requête) au lieu de la comparer à eprescriptions.pharmacy_id :
--    la condition est vraie pour n'importe quel staff dès lors qu'il a UNE
--    ligne dans pharmacy_staff, quelle que soit l'officine. Concrètement,
--    n'importe quel pharmacien du réseau pouvait lire/valider/dispenser
--    N'IMPORTE QUELLE e-prescription, de n'importe quelle officine. Ce
--    module n'est câblé à aucun écran Dart aujourd'hui (voir commentaire de
--    20260827001000_prescriptions.sql et le rapport d'audit), mais RLS est
--    la seule ligne de défense d'une table Supabase : un appel API direct
--    l'aurait exploité sans qu'aucun code Flutter n'ait besoin d'exister.
--    Remplacé par is_pharmacy_staff(eprescriptions.pharmacy_id), déjà
--    disponible et déjà utilisé pour le même besoin sur stock_items.
--
-- 4) scanned_prescriptions (20260828019000) : `role in ('admin', 'staff')`
--    est le même test structurellement cassé déjà diagnostiqué et corrigé
--    ailleurs par 20260829003800_admin_helpers.sql (ces valeurs ne sont pas
--    autorisées par la contrainte CHECK de profiles.role) — cette occurrence
--    n'était pas dans la liste des migrations corrigées par cet audit
--    Module 0. Remplacé par is_pharmacist() (nouvelle fonction ci-dessous,
--    même rôle que is_gsg_admin() mais pour le staff officine sans egard à
--    un rattachement précis, cf. point 2 ci-dessus).

-- ==================== HELPER ====================

create or replace function public.is_pharmacist()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'pharmacien'
  );
$$;

comment on function public.is_pharmacist() is
  'Vrai si l''utilisateur courant a role=pharmacien, sans égard à son officine de rattachement (profiles.pharmacy_id). À distinguer de is_pharmacy_staff(target_pharmacy_id), qui vérifie en plus l''officine précise. Utilisé là où le cahier ne définit pas de rattachement officine exploitable (ex. validation d''ordonnance OCR, prescriptions.pharmacy_id n''existe pas) — voir audit Module 5 (ORD), 29/08/2026.';

-- ==================== PRESCRIPTIONS : policies manquantes ====================

create policy "prescriptions_insert_own" on public.prescriptions
  for insert to authenticated
  with check (auth.uid() = patient_id);

create policy "prescriptions_staff_select" on public.prescriptions
  for select to authenticated
  using (public.is_pharmacist());

create policy "prescriptions_staff_update" on public.prescriptions
  for update to authenticated
  using (public.is_pharmacist())
  with check (public.is_pharmacist());

create policy "prescription_items_insert_own" on public.prescription_items
  for insert to authenticated
  with check (
    exists (
      select 1 from public.prescriptions p
      where p.id = prescription_items.prescription_id
        and p.patient_id = auth.uid()
    )
  );

create policy "prescription_items_staff_select" on public.prescription_items
  for select to authenticated
  using (public.is_pharmacist());

create policy "prescription_items_staff_update" on public.prescription_items
  for update to authenticated
  using (public.is_pharmacist())
  with check (public.is_pharmacist());

-- ==================== EPRESCRIPTIONS : correction faille RLS ====================

drop policy if exists "Pharmacies view prescriptions" on public.eprescriptions;
create policy "Pharmacies view prescriptions" on public.eprescriptions
  for select using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Pharmacies update prescriptions" on public.eprescriptions;
create policy "Pharmacies update prescriptions" on public.eprescriptions
  for update using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Items visible with parent" on public.eprescription_items;
create policy "Items visible with parent" on public.eprescription_items
  for select using (
    exists (
      select 1 from public.eprescriptions e
      where e.id = eprescription_items.eprescription_id and (
        e.patient_id = auth.uid() or
        e.doctor_id = auth.uid() or
        public.is_pharmacy_staff(e.pharmacy_id)
      )
    )
  );

drop policy if exists "History visible with parent" on public.eprescription_history;
create policy "History visible with parent" on public.eprescription_history
  for select using (
    exists (
      select 1 from public.eprescriptions e
      where e.id = eprescription_history.eprescription_id and (
        e.patient_id = auth.uid() or
        e.doctor_id = auth.uid() or
        public.is_pharmacy_staff(e.pharmacy_id)
      )
    )
  );

-- ==================== SCANNED_PRESCRIPTIONS : correction test de rôle ====================

drop policy if exists "Staff view scanned prescriptions" on public.scanned_prescriptions;
create policy "Staff view scanned prescriptions" on public.scanned_prescriptions
  for select using (public.is_pharmacist());
