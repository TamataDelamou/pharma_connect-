-- Audit Module 25 (PRE), Étape 2/3 (30/08/2026) : correctifs RLS du module
-- e-prescription. Migration corrective postérieure à `admin_helpers.sql`
-- (20260829003800) et à `professionals.sql` (20260827005500), dont ce
-- correctif dépend directement — même méthode que pour tous les correctifs
-- RLS précédents de cet audit (HOP-1, ASR-1/ASR-2, etc.) : ne jamais éditer
-- en place une migration antérieure à ses dépendances, pour ne pas casser
-- le rejeu chronologique complet de la chaîne de migrations.

-- ==================== PRE-2 (Critique, RG-PRE-01) ====================
-- Constat d'ouverture (rapport d'audit §4, PRE-2) : "Doctors manage own
-- prescriptions" (eprescriptions) et "Items managed with parent"
-- (eprescription_items) ne vérifiaient que `auth.uid() = doctor_id`, sans
-- aucun contrôle de `profiles.role = 'professionnel'` ni de
-- `professional_profiles.is_verified` — RG-PRE-01 ("Seul un professionnel
-- de santé inscrit à son ordre et vérifié peut émettre une ordonnance
-- électronique opposable") n'était donc pas appliquée : n'importe quel
-- compte authentifié pouvait s'auto-émettre une ordonnance opposable pour
-- n'importe quel patient.
--
-- Note de coordination (trouvée en cours de vérification par exécution
-- réelle) : une fonction `public.is_verified_professional(prof_id uuid)`
-- existe déjà (20260830046000_professionals_module_fixes.sql, correctif
-- RG-INF-01 du Module 19/INF, déjà clos) — mais elle ne vérifie QUE
-- `professional_profiles.is_verified`, jamais `profiles.role`, ce qui
-- suffisait dans son contexte d'origine (`professional_id` y référence déjà
-- structurellement un professionnel). Ici, `eprescriptions.doctor_id`
-- référence `profiles(id)` sans restriction de rôle : un compte de
-- n'importe quel rôle pourrait avoir une ligne `professional_profiles`
-- orpheline. RG-PRE-01 exige les deux volets ("inscrit à son ordre" ET
-- "vérifié") — nouvelle fonction dédiée, nom distinct, pour ne pas modifier
-- le comportement déjà validé et scellé du Module 19.
--
-- SECURITY DEFINER + search_path verrouillé, même patron que
-- `is_pharmacy_staff()` (20260827002000_staff_write_policies.sql) : évite
-- toute dépendance aux policies de `profiles`/`professional_profiles` et
-- toute récursion RLS.
create or replace function public.is_verified_professional_account(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    join public.professional_profiles pp on pp.id = p.id
    where p.id = p_id
      and p.role = 'professionnel'
      and pp.is_verified = true
  );
$$;

comment on function public.is_verified_professional_account(uuid) is
  'Vrai si p_id est un compte role=professionnel ET vérifié (professional_profiles.is_verified). Implémente RG-PRE-01 (audit Module 25, Étape 2/3) — distincte de is_verified_professional() (Module 19/RG-INF-01) qui ne vérifie pas le rôle.';

drop policy if exists "Doctors manage own prescriptions" on public.eprescriptions;
create policy "Doctors manage own prescriptions" on public.eprescriptions
  for all
  using (auth.uid() = doctor_id and public.is_verified_professional_account(doctor_id))
  with check (auth.uid() = doctor_id and public.is_verified_professional_account(doctor_id));

drop policy if exists "Items managed with parent" on public.eprescription_items;
create policy "Items managed with parent" on public.eprescription_items
  for all
  using (
    exists (
      select 1 from public.eprescriptions
      where id = eprescription_id
        and doctor_id = auth.uid()
        and public.is_verified_professional_account(doctor_id)
    )
  )
  with check (
    exists (
      select 1 from public.eprescriptions
      where id = eprescription_id
        and doctor_id = auth.uid()
        and public.is_verified_professional_account(doctor_id)
    )
  );

-- ==================== PRE-7 — motif « rôle inatteignable » ====================
-- `scanned_prescriptions.sql` (28/08, antérieure à admin_helpers.sql) :
-- "Staff view scanned prescriptions" gardée par
-- `role in ('admin', 'staff')`, jamais atteignable (`profiles.role`
-- n'admet que 'patient','pharmacien','grossiste','livreur','professionnel',
-- 'regulateur' par contrainte CHECK). Motif déjà rencontré à de nombreuses
-- reprises dans cet audit (C49/C54/.../C94/HOP-1/ASR-1) — correctif
-- mécanique connu (`is_gsg_admin()`).
drop policy if exists "Staff view scanned prescriptions" on public.scanned_prescriptions;
create policy "Staff view scanned prescriptions" on public.scanned_prescriptions
  for select using (public.is_gsg_admin());
