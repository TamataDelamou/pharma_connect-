-- Module 29 (CSR) — corrective migration, Étape 3
--
-- RG-CSR-01 : deux défauts cumulés sur solidarity.sql (20260827009000, datée
-- 27/08, donc ANTÉRIEURE à public.is_gsg_admin() — 20260829003800, 29/08).
-- Les corriger en place casserait le rejeu chronologique de la chaîne de
-- migrations (même piège que HOP-1/Module 23) — corrigés ici par une
-- migration corrective postérieure, modèle de référence HOP-1/ASR-1/REG-1/BI-1.
--
-- 1) Motif « rôle inatteignable » déjà rencontré à de nombreuses reprises
--    dans cet audit : les 4 policies "Staff manage ..." (solidarity_programs,
--    solidarity_beneficiaries, solidarity_distributions, solidarity_donations)
--    testent role in ('admin', 'staff'), une valeur que la contrainte CHECK
--    de profiles.role n'autorise jamais ('patient', 'pharmacien', 'grossiste',
--    'livreur', 'professionnel', 'regulateur' uniquement — voir
--    20260827000200_profiles.sql). Remplacées ici par public.is_gsg_admin().
--
-- 2) Défaut propre à RG-CSR-01 : la policy "Patients enroll themselves"
--    laissait un patient insérer directement sa propre ligne
--    solidarity_beneficiaries avec n'importe quel statut, y compris
--    'active' — une auto-inscription immédiatement effective, sans aucune
--    validation par un partenaire/le staff. Combiné au défaut (1), qui
--    rendait toute policy de gestion staff inatteignable, ce chemin était en
--    pratique le SEUL moyen d'écrire dans la table : RG-CSR-01 n'était pas
--    seulement non vérifiée, elle était activement contournée. Corrigé ici :
--    l'auto-inscription patient n'est plus autorisée qu'avec status =
--    'pending' ; seul is_gsg_admin() peut la faire passer à 'active' (via la
--    policy "Staff manage beneficiaries" corrigée en (1)).

-- 'pending' n'existait pas dans la contrainte CHECK d'origine de
-- solidarity_beneficiaries.status (seuls 'active', 'completed', 'suspended',
-- 'expired' étaient autorisés) — ajouté ici, requis par le correctif (2).
alter table public.solidarity_beneficiaries
  drop constraint if exists solidarity_beneficiaries_status_check;
alter table public.solidarity_beneficiaries
  add constraint solidarity_beneficiaries_status_check
  check (status in ('pending', 'active', 'completed', 'suspended', 'expired'));

-- (1) remplacement des 4 policies "Staff manage ..." par is_gsg_admin()

drop policy if exists "Staff manage solidarity programs" on public.solidarity_programs;
create policy "Staff manage solidarity programs" on public.solidarity_programs
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage beneficiaries" on public.solidarity_beneficiaries;
create policy "Staff manage beneficiaries" on public.solidarity_beneficiaries
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage distributions" on public.solidarity_distributions;
create policy "Staff manage distributions" on public.solidarity_distributions
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage donations" on public.solidarity_donations;
create policy "Staff manage donations" on public.solidarity_donations
  for all using (public.is_gsg_admin());

-- (2) auto-inscription patient restreinte à status = 'pending' — cœur du
-- correctif RG-CSR-01 : une inscription patient ne devient jamais 'active'
-- sans passer par is_gsg_admin() (policy "Staff manage beneficiaries").

drop policy if exists "Patients enroll themselves" on public.solidarity_beneficiaries;
create policy "Patients enroll themselves" on public.solidarity_beneficiaries
  for insert with check (auth.uid() = patient_id and status = 'pending');
