-- Correctif RLS Module 32 SAV (support) : les policies "Staff ..." testaient
-- role in ('admin','staff','support'), valeurs jamais atteignables vu la
-- contrainte CHECK reelle de profiles.role (20260827000200_profiles.sql:11-13),
-- qui n'autorise que 'patient','pharmacien','grossiste','livreur',
-- 'professionnel','regulateur'. Meme motif que RG-CSR-01 (Module 29).
-- Remplacement par is_gsg_admin(), coherent avec HOP-1/CSR-1.
--
-- Relecture des sources avant application (20260827008000_support.sql /
-- 20260828014000_support_ai.sql), demandee explicitement avant la fusion :
-- une divergence corrigee ici par rapport au brouillon initial -- "Staff
-- view all tickets" etait "for all" dans l'original (pas seulement select).
-- Le nom de la policy est trompeur mais c'est la seule policy non-patient
-- couvrant l'ecriture sur support_tickets (statut, assignation...). La
-- passer en select-only aurait retire au staff toute capacite de gestion
-- des tickets. Conservee "for all" pour preserver le perimetre fonctionnel
-- existant. Les 5 autres policies correspondent exactement au brouillon.

drop policy if exists "Staff view all tickets" on public.support_tickets;
create policy "Staff view all tickets" on public.support_tickets
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage responses" on public.support_responses;
create policy "Staff manage responses" on public.support_responses
  for all using (public.is_gsg_admin());

drop policy if exists "Staff manage knowledge articles" on public.support_knowledge_articles;
create policy "Staff manage knowledge articles" on public.support_knowledge_articles
  for all using (public.is_gsg_admin());

drop policy if exists "Staff view all conversations" on public.bot_conversations;
create policy "Staff view all conversations" on public.bot_conversations
  for select using (public.is_gsg_admin());

drop policy if exists "Staff view feedback" on public.bot_feedback;
create policy "Staff view feedback" on public.bot_feedback
  for select using (public.is_gsg_admin());

drop policy if exists "Staff manage intents" on public.bot_intents;
create policy "Staff manage intents" on public.bot_intents
  for all using (public.is_gsg_admin());
