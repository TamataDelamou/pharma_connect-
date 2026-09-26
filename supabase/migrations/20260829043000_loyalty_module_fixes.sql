-- Module 16 (FID) — correctifs d'audit, 29/08/2026
--
-- ============================================================================
-- PARTIE 1 — Faille RLS critique (privilège élevé cross-officine), C66
-- ============================================================================
-- `20260827008500_loyalty.sql` (5 policies) comparait, à l'intérieur d'une
-- sous-requête corrélée `exists (select 1 from public.pharmacy_staff where
-- user_id = auth.uid() and pharmacy_id = pharmacy_id)`, la colonne
-- `pharmacy_id` À ELLE-MÊME : en SQL, un nom de colonne non qualifié dans une
-- sous-requête se résout d'abord contre le FROM de CETTE sous-requête —
-- `pharmacy_staff` possédant elle-même une colonne `pharmacy_id`, les DEUX
-- occurrences de `pharmacy_id = pharmacy_id` se résolvent contre
-- `pharmacy_staff.pharmacy_id`, jamais contre la table externe
-- (`loyalty_programs.pharmacy_id`, `loyalty_accounts.pharmacy_id`, etc.).
-- Résultat : une tautologie toujours vraie pour quiconque a NE SERAIT-CE
-- QU'UNE ligne dans `pharmacy_staff`, quelle que soit l'officine. Concrètement,
-- avant ce correctif, le personnel de N'IMPORTE QUELLE officine pouvait
-- consulter ET MODIFIER (via "for all") le programme de fidélité, les
-- comptes clients (y compris ajuster leur solde de points), le catalogue de
-- récompenses et les parrainages de TOUTES LES AUTRES officines du réseau —
-- une fuite de données et un risque de fraude cross-tenant, pas seulement un
-- bug d'accès. Corrigé en utilisant le helper existant et déjà correct
-- `public.is_pharmacy_staff(target_pharmacy_id uuid)` (SECURITY DEFINER),
-- dont l'argument est évalué dans le contexte de la ligne de la table sur
-- laquelle porte la policy (pas de sous-requête, pas d'ambiguïté possible).

drop policy if exists "Staff manage loyalty programs" on public.loyalty_programs;
create policy "Staff manage loyalty programs" on public.loyalty_programs
  for all using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Staff view pharmacy accounts" on public.loyalty_accounts;
create policy "Staff view pharmacy accounts" on public.loyalty_accounts
  for select using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Staff manage accounts" on public.loyalty_accounts;
create policy "Staff manage accounts" on public.loyalty_accounts
  for all using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Staff manage rewards" on public.loyalty_rewards;
create policy "Staff manage rewards" on public.loyalty_rewards
  for all using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Staff view referrals" on public.loyalty_referrals;
create policy "Staff view referrals" on public.loyalty_referrals
  for select using (public.is_pharmacy_staff(pharmacy_id));

-- ============================================================================
-- PARTIE 2 — Motif « rôle inatteignable » (C49/C54/C63), 12 occurrences, C67
-- ============================================================================
-- `role in ('admin', 'staff')` ou `role = 'admin'` : valeurs impossibles par
-- construction (`public.profiles.role` n'autorise que 'patient', 'pharmacien',
-- 'grossiste', 'livreur', 'professionnel', 'regulateur' — voir la contrainte
-- CHECK de `20260827000200_profiles.sql`). 4ème+ récurrence de ce motif dans
-- cet audit (Modules 13, 14, 15 x2, désormais 16 x12 rien que dans ce
-- module). Remplacé par `is_gsg_admin()` pour les tables sans notion
-- d'officine (badges, défis, actions santé, récompenses personnalisées,
-- objectifs/jalons santé — aucune n'a de colonne `pharmacy_id`, il ne peut
-- donc s'agir que d'une supervision GSG plutôt que d'un accès scopé à une
-- officine), et par `is_pharmacy_staff(pharmacy_id)` pour `loyalty_leaderboard`
-- (qui, elle, a bien une colonne `pharmacy_id`).

-- gamification_badges.sql
drop policy if exists "Staff manage loyalty badges" on public.loyalty_badges;
create policy "Staff manage loyalty badges" on public.loyalty_badges
  for all using (public.is_gsg_admin());

-- gamification_leaderboard.sql (a pharmacy_id : scoping officine, pas GSG admin)
drop policy if exists "Staff update leaderboard" on public.loyalty_leaderboard;
create policy "Staff update leaderboard" on public.loyalty_leaderboard
  for all using (
    public.is_pharmacy_staff(pharmacy_id) or public.is_gsg_admin()
  );

-- gamification_health.sql (le rôle 'professionnel' était déjà atteignable ;
-- seule la branche 'admin'/'staff' était morte)
drop policy if exists "Staff view health goals" on public.health_goals;
create policy "Staff view health goals" on public.health_goals
  for select using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

drop policy if exists "Staff view milestones" on public.health_milestones;
create policy "Staff view milestones" on public.health_milestones
  for select using (
    public.is_gsg_admin()
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'professionnel'
    )
  );

-- loyalty_ai.sql
drop policy if exists "Staff manage challenges" on public.health_challenges;
create policy "Staff manage challenges" on public.health_challenges
  for all using (public.is_gsg_admin());

drop policy if exists "Staff view all progress" on public.challenge_progress;
create policy "Staff view all progress" on public.challenge_progress
  for select using (public.is_gsg_admin());

drop policy if exists "Staff view all earnings" on public.reward_earnings;
create policy "Staff view all earnings" on public.reward_earnings
  for select using (public.is_gsg_admin());

drop policy if exists "Staff view health actions" on public.health_actions;
create policy "Staff view health actions" on public.health_actions
  for select using (public.is_gsg_admin());

-- personalized_rewards.sql
drop policy if exists "Staff manage personalized rewards" on public.personalized_rewards;
create policy "Staff manage personalized rewards" on public.personalized_rewards
  for all using (public.is_gsg_admin());

-- ============================================================================
-- Note (non corrigé ici, hors périmètre de ce module) : le même motif
-- `role in ('admin', 'staff')` apparaît aussi dans
-- `20260828016500_dashboard_customization.sql` ("Staff view user dashboards",
-- "Staff manage dashboard widgets") — migration orphaline, aucun fichier Dart
-- de ce projet ne référence `user_dashboards`/`dashboard_widgets` (territoire
-- probable du futur Module 28, BI). Non corrigée ici pour rester dans le
-- périmètre strict du Module 16 ; à traiter lors de l'audit de ce module. Voir
-- le registre pour la recommandation d'un balayage complet du projet sur ce
-- motif plutôt que de continuer à le découvrir module par module.
