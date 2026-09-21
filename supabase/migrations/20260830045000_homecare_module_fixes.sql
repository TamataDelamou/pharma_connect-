-- Module 18 (HOM) — correctifs d'audit, 30/08/2026
--
-- ============================================================================
-- PARTIE 1 — Colonne manquante pour le motif de refus (fonctionnalité clé
-- cahier : « Acceptation ou refus de la demande par le professionnel, avec
-- motif obligatoire en cas de refus »)
-- ============================================================================
-- Absente de la migration d'origine (20260827004000_homecare.sql) : le refus
-- annulait directement l'intervention sans aucune saisie. Ajoutée pour que
-- `HomecareDetailScreen._showRefusalDialog` (nouveau) puisse la persister.

alter table public.homecare_interventions
  add column refusal_reason text;

-- ============================================================================
-- PARTIE 2 — Policy DELETE manquante, motif désormais établi
-- (C35/C37/C39/C41/C70a)
-- ============================================================================
-- `homecare_interventions` ne portait que des policies select/insert/update
-- pour patient_id/professional_id — aucune policy DELETE, alors que
-- `HomecareDetailScreen._confirmDelete` (bouton « Supprimer », réservé aux
-- interventions terminées/annulées/non honorées) existe réellement dans
-- l'UI. Même motif que C35/C37/C39/C41 (Modules 5/6/7/... ) et C70 point (a)
-- (Module 17) : migration de base incomplète en écriture, ici sur DELETE.

create policy "Patient or professional can delete past interventions" on public.homecare_interventions
  for delete using (
    status in ('completed', 'cancelled', 'missed')
    and (auth.uid() = patient_id or auth.uid() = professional_id)
  );

-- ============================================================================
-- PARTIE 3 — Absence de supervision GSG Admin
-- ============================================================================
-- Aucune policy de ce module n'accordait de visibilité à `is_gsg_admin()` —
-- une asymétrie avec la quasi-totalité des autres modules audités (support,
-- litige, modération). Ajoutée en lecture seule (pas de `for all`, un
-- administrateur n'a pas vocation à modifier une intervention médicale à la
-- place des parties concernées) pour permettre un support/litige réel sans
-- élargir les droits d'écriture.

create policy "GSG admin can view all interventions" on public.homecare_interventions
  for select using (public.is_gsg_admin());
