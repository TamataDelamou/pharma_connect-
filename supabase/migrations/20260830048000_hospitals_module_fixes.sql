-- Audit Module 23 (HOP), Étape 3 (30/08/2026) — correctif HOP-1.
--
-- Les 5 policies d'écriture du module HOP (« Admins can manage hospitals »,
-- « Admins can manage departments », « Admins manage affiliations »,
-- « Admins manage referrals » dans 20260827006000_hospitals.sql,
-- « Staff manage wait times » dans 20260828021000_hospital_wait_times.sql)
-- gataient l'écriture avec `role in ('admin', 'staff')` — motif « rôle
-- inatteignable » déjà documenté et outillé par `is_gsg_admin()` dans
-- 20260829003800_admin_helpers.sql : `profiles.role` n'autorise par
-- contrainte CHECK que 'patient'/'pharmacien'/'grossiste'/'livreur'/
-- 'professionnel'/'regulateur' — ni 'admin' ni 'staff' ne peuvent jamais y
-- figurer, rendant ces 5 policies structurellement inatteignables (aucune
-- écriture possible sur les 6 tables du module, par quiconque, y compris
-- le personnel back-office GSG légitime).
--
-- Corrigé ici, PAR MIGRATION CORRECTIVE plutôt que par édition en place
-- des deux migrations d'origine du module (27-28/08/2026) : `is_gsg_admin()`
-- n'existe qu'à partir de 20260829003800_admin_helpers.sql (29/08/2026,
-- POSTÉRIEURE) — une édition en place casserait le rejeu chronologique
-- complet de la chaîne de migrations sur une base neuve (vérifié par
-- exécution réelle : `function public.is_gsg_admin() does not exist`).
-- Seul cas de ce type rencontré dans cet audit où le motif habituel
-- (« défaut trouvé dans la migration propre au module en cours d'audit :
-- correction directe autorisée ») entre en conflit avec la contrainte
-- d'ordre chronologique des migrations Supabase — d'où le recours
-- exceptionnel à une migration corrective pour un défaut du module
-- actuellement ouvert, motif habituellement réservé aux modules déjà clos.

drop policy if exists "Admins can manage hospitals" on public.hospitals;
create policy "Admins can manage hospitals" on public.hospitals
  for all using (public.is_gsg_admin());

drop policy if exists "Admins can manage departments" on public.hospital_departments;
create policy "Admins can manage departments" on public.hospital_departments
  for all using (public.is_gsg_admin());

drop policy if exists "Admins manage affiliations" on public.hospital_affiliations;
create policy "Admins manage affiliations" on public.hospital_affiliations
  for all using (public.is_gsg_admin());

drop policy if exists "Admins manage referrals" on public.hospital_referrals;
create policy "Admins manage referrals" on public.hospital_referrals
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage wait times" on public.hospital_wait_times;
create policy "Staff manage wait times" on public.hospital_wait_times
  for all using (public.is_gsg_admin());
