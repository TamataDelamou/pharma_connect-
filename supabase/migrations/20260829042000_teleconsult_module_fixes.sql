-- Module 15 (CNS — Télé-conseil / réservé ici au sous-système téléconsultation
-- réellement codé sous lib/modules/teleconsult/) : correctifs RLS.
-- Audit du 29/08/2026.
--
-- Constat n°1 (verrou d'écriture, migration 20260828010000_teleconsult_ai.sql) :
-- les policies « Staff view all sessions » (pre_consultation_sessions) et
-- « Admin manage decision tree » (decision_tree_nodes) testent
-- `profiles.role in ('admin', 'staff')` / `role = 'admin'` — même défaut que
-- C49 (déjà rencontré 2 fois : Module 13 marketplace, Module 14 financing),
-- un rôle inatteignable par construction (`profiles.role` n'autorise jamais
-- 'admin'/'staff', voir la contrainte CHECK de 20260827000200_profiles.sql).
-- La seconde bloque TOUTE écriture sur `decision_tree_nodes`, y compris le
-- seed automatique (`PreConsultationAIService.seedDefaultTree()`), pour
-- n'importe quel compte, y compris un membre réel du back-office GSG.
-- Corrigé en réutilisant `is_gsg_admin()` (déjà introduite par
-- 20260829003800_admin_helpers.sql), à l'identique du correctif C49.
--
-- Constat n°2 (gap RLS systémique, découvert dans ce module) : `public.
-- profiles` ne porte qu'une seule policy de lecture, `profiles_select_own`
-- (`using (auth.uid() = id)`, Module 1) — aucune autre policy de select
-- n'existe nulle part dans le projet. Tout embed PostgREST vers `profiles`
-- pour afficher le nom d'un AUTRE utilisateur revient donc `null`,
-- silencieusement (pas d'erreur PostgREST, juste un champ vide côté
-- réponse) : `teleconsult_service.dart` (patientName/professionalName),
-- `messaging_service.dart` (senderName). Jamais rencontré avant ce module
-- car les modules précédents affichaient des noms d'OFFICINE (`pharmacies`,
-- déjà publique) et non de compte individuel — CNS est le premier module de
-- cet audit à mettre en relation deux comptes individuels directement.
--
-- Corrigé par deux policies étroites, pas par un accès public généralisé à
-- `profiles` (un compte pharmacien/patient ordinaire n'a aucune raison
-- d'être découvrable par n'importe qui) :
--   (a) un compte "professionnel" est par nature une offre de service
--       consultable — il doit être trouvable par les patients avant même
--       toute mise en relation (écran de réservation, RG-CNS pertinent :
--       le patient choisit son interlocuteur). Rendu visible en lecture
--       (nom/téléphone) à tout utilisateur authentifié, à l'identique de la
--       visibilité déjà publique de `professional_profiles`
--       (« Everyone can view professional profiles », 20260827005500).
--   (b) un patient n'est PAS un profil public — sa visibilité par un
--       professionnel est limitée aux seules relations réelles (une
--       consultation ou un message échangé ensemble), jamais plus large.

-- ==================== pre_consultation_sessions / decision_tree_nodes ====================

drop policy if exists "Staff view all sessions" on public.pre_consultation_sessions;
drop policy if exists "Admin manage decision tree" on public.decision_tree_nodes;

create policy "pre_consultation_sessions_admin_select" on public.pre_consultation_sessions
  for select to authenticated
  using (public.is_gsg_admin());

create policy "decision_tree_nodes_admin_manage" on public.decision_tree_nodes
  for all to authenticated
  using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ==================== profiles : visibilité ciblée ====================

-- (a) Annuaire des professionnels — nécessaire à la découverte avant
-- réservation (TeleconsultService.getAvailableProfessionals()) et à
-- l'affichage du nom du professionnel dans les embeds patient (consultations,
-- messagerie asynchrone).
create policy "profiles_select_professionals_public" on public.profiles
  for select to authenticated
  using (role = 'professionnel');

-- (b) Un professionnel peut voir le nom/téléphone d'un patient avec lequel
-- il partage une consultation (quel qu'en soit le statut, y compris passée)
-- ou un fil de messagerie asynchrone — jamais plus large qu'une relation de
-- soin réelle déjà établie.
create policy "profiles_select_patient_counterpart" on public.profiles
  for select to authenticated
  using (
    exists (
      select 1 from public.consultations c
      where c.patient_id = profiles.id
        and c.professional_id = auth.uid()
    )
    or exists (
      select 1 from public.async_messages m
      where m.patient_id = profiles.id
        and m.professional_id = auth.uid()
    )
  );
