-- Module 17 (TRI) — correctifs d'audit, 30/08/2026
--
-- ============================================================================
-- PARTIE 1 — Policy d'écriture manquante (DELETE), motif désormais établi
-- ============================================================================
-- `triage_patients` (20260827004500_triage.sql) ne portait que des policies
-- select/update/insert pour le rôle 'professionnel' — aucune policy DELETE.
-- `TriageService.deletePatient()`/l'écran de détail (bouton « Supprimer »,
-- réservé aux dossiers sortis/transférés) auraient donc échoué silencieusement
-- (RLS refuse par défaut toute opération sans policy permissive correspondante) :
-- même motif que C35/C37/C39/C41 (migration de base incomplète en écriture),
-- ici sur DELETE plutôt que sur INSERT/UPDATE.

create policy "Nurses can delete triage patients" on public.triage_patients
  for delete using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

-- ============================================================================
-- PARTIE 2 — Motif « rôle inatteignable » (C49/C54/C63/C67), 2 occurrences
-- ============================================================================
-- `role in ('admin', 'staff', 'professionnel')`/`role in ('admin', 'staff')`
-- dans `20260828012000_triage_ai.sql` : mêmes valeurs impossibles que dans
-- tous les modules précédents (`public.profiles.role` n'autorise jamais
-- 'admin'/'staff'). 5ème+ module affecté par ce motif — recommandation déjà
-- réitérée à plusieurs reprises (voir le registre) d'un balayage complet du
-- projet plutôt que de continuer à le découvrir module par module.

drop policy if exists "Staff manage triage AI analyses" on public.triage_ai_analyses;
create policy "Staff manage triage AI analyses" on public.triage_ai_analyses
  for all using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

drop policy if exists "Staff manage triage rules" on public.triage_rules;
create policy "Staff manage triage rules" on public.triage_rules
  for all using (public.is_gsg_admin());
