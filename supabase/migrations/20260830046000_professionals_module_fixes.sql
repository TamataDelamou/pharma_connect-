-- Module 19 (INF) — correctifs d'audit, 30/08/2026
--
-- Arbitrage porteur du projet (AskUserQuestion, 30/08/2026) : « Corriger
-- l'existant, différer la construction » — les 4 écrans cahier (Inscription
-- et vérification du professionnel / Application Health Professional /
-- Gestion de zone de couverture et disponibilités / Évaluations reçues)
-- restent à construire dans une future itération (voir le registre, D32).
-- Cette migration corrige les 3 défauts réels trouvés dans le code déjà
-- écrit (la fondation de données du module, `20260827005500_professionals.sql`,
-- et son usage par HOM/CNS), sans construire de nouvel écran.

-- ============================================================================
-- PARTIE 1 — Faille RLS « rôle inatteignable » (C49/C54/C63/C67/C70b),
-- nouvelle occurrence dans la migration d'origine du module en cours d'audit
-- ============================================================================
-- `public.profiles.role` n'autorise jamais 'admin' (contrainte CHECK,
-- 20260827000200_profiles.sql) — la policy "Admins can manage professional
-- profiles" était donc inatteignable par construction depuis sa création,
-- aucun compte back-office GSG n'ayant jamais pu gérer (vérifier/rejeter)
-- un profil professionnel. Remplacée par `is_gsg_admin()`
-- (20260829003800_admin_helpers.sql), même correctif que celui déjà
-- appliqué dans 6+ autres modules de ce projet.

drop policy if exists "Admins can manage professional profiles" on public.professional_profiles;

create policy "GSG admin can manage professional profiles" on public.professional_profiles
  for all using (public.is_gsg_admin())
  with check (public.is_gsg_admin());

-- ============================================================================
-- PARTIE 2 — Exposition excessive de données personnelles
-- ============================================================================
-- "Everyone can view professional profiles" (`for select using (true)`)
-- exposait l'intégralité de la ligne — y compris `license_number`,
-- `license_issuing_body`, `license_expiry_date`, `emergency_contact_name`,
-- `emergency_contact_phone`, `rejection_reason` — à tout utilisateur
-- authentifié, y compris pour un compte `role='professionnel'` qui vient de
-- s'inscrire et n'a encore JAMAIS été vérifié (`is_verified = false` par
-- défaut). Même famille de limite structurelle que D27 (Module 15,
-- `profiles.phone`) mais plus sévère ici : les colonnes concernées incluent
-- un numéro de téléphone de contact d'urgence et un numéro de licence
-- professionnelle, pas seulement un numéro de téléphone de contact
-- ordinaire. Resserrée pour n'exposer un profil complet qu'à son titulaire
-- ou à un admin GSG ; la découverte publique (réservation HOM/CNS) reste
-- fonctionnelle car ces parcours ne sélectionnent déjà que des profils
-- `is_verified = true` (HomecareService.getAvailableProfessionals,
-- TeleconsultService, corrigés aux Modules 15/18) — cette policy les
-- autorise donc explicitement, sans exposer les profils non vérifiés.
-- Les colonnes sensibles (license_number et consorts) restent techniquement
-- lisibles pour un profil VÉRIFIÉ par n'importe quel compte authentifié :
-- limite résiduelle assumée et consignée au registre (D32), au même titre
-- que D27, plutôt que résolue par une vue dédiée sans environnement outillé
-- disponible pour vérifier l'absence de régression sur HOM/CNS.

drop policy if exists "Everyone can view professional profiles" on public.professional_profiles;

create policy "Verified professionals are publicly discoverable" on public.professional_profiles
  for select using (
    is_verified = true
    or auth.uid() = id
    or public.is_gsg_admin()
  );

-- ============================================================================
-- PARTIE 3 — RG-INF-01 (Critique) non appliqué au niveau RLS
-- ============================================================================
-- « Un professionnel ne peut recevoir de demande de soin à domicile ou de
-- téléconsultation qu'après vérification de son inscription active à
-- l'ordre professionnel compétent. » Constat : cette règle n'était appliquée
-- QUE côté UI (les écrans de réservation HOM/CNS filtrent déjà
-- `is_verified = true` lors de la sélection, corrigé aux Modules 15/18) —
-- jamais au niveau des policies RLS d'écriture de `homecare_interventions`/
-- `consultations`. Un client alternatif (appel direct à l'API REST
-- Supabase, hors de l'application officielle) pouvait donc créer une
-- intervention ou une consultation avec n'importe quel `professional_id`
-- valide, y compris celui d'un compte `role='professionnel'` jamais vérifié
-- (voire sans aucune ligne `professional_profiles` du tout). Le
-- « professionnel » non vérifié pouvait ensuite consulter/accepter cette
-- demande via ses propres policies de lecture/mise à jour
-- (`auth.uid() = professional_id`), déjà en place et correctes une fois
-- l'admission bloquée en amont — corrigé ici en gatant uniquement le point
-- d'entrée (l'INSERT par le patient), sans toucher les policies de lecture/
-- mise à jour du professionnel elles-mêmes.

create or replace function public.is_verified_professional(prof_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.professional_profiles
    where id = prof_id and is_verified = true
  );
$$;

comment on function public.is_verified_professional(uuid) is
  'RG-INF-01 : vrai si prof_id correspond à un professional_profiles.is_verified = true. Utilisé en WITH CHECK sur les policies INSERT de homecare_interventions/consultations pour empêcher l''admission d''une demande vers un professionnel jamais vérifié, indépendamment du filtrage déjà fait côté UI de réservation.';

drop policy if exists "Patients can insert own interventions" on public.homecare_interventions;

create policy "Patients can insert own interventions" on public.homecare_interventions
  for insert with check (
    auth.uid() = patient_id
    and public.is_verified_professional(professional_id)
  );

drop policy if exists "Patients can insert own consultations" on public.consultations;

create policy "Patients can insert own consultations" on public.consultations
  for insert with check (
    auth.uid() = patient_id
    and public.is_verified_professional(professional_id)
  );
