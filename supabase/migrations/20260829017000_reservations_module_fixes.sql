-- Correctifs Module 6 (RES — Réservation & Retrait en officine / Click &
-- Collect), audit du 29/08/2026.
--
-- 1) 20260827001100_reservations.sql n'ouvrait AUCUNE policy d'écriture sur
--    reservations/reservation_items (select uniquement, patient-own) : ni le
--    dépôt d'une réservation par un patient, ni sa confirmation/mise en
--    "prête"/retrait par un pharmacien n'étaient possibles en production —
--    RLS refuse tout par défaut. Même défaut que celui déjà corrigé pour
--    prescriptions au Module 5 (20260829016000_prescriptions_module_fixes.sql).
-- 2) Contrairement à prescriptions (qui n'a pas de colonne pharmacy_id et
--    reste donc volontairement non-scopée par officine, cf. registre des
--    écarts item D6), reservations.pharmacy_id existe et est NOT NULL : la
--    réserve documentée dans le commentaire de la migration d'origine
--    ("faute d'un mécanisme de vérification de rôle/rattachement... même
--    réserve que pour prescriptions") ne s'applique donc pas ici —
--    is_pharmacy_staff(pharmacy_id) (Module 0/1) permet un scope propre par
--    officine dès maintenant.

-- ---------------------------------------------------------------------------
-- reservations
-- ---------------------------------------------------------------------------

-- Lecture pharmacien : file d'attente de sa propre officine
-- (pharmacy_queue_screen.dart). Absente jusqu'ici — le pharmacien ne
-- pouvait lire AUCUNE réservation, y compris les siennes.
create policy "reservations_staff_select" on public.reservations
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id));

-- Dépôt d'une réservation par le patient authentifié
-- (reservation_checkout_screen.dart → ReservationService.createReservation).
create policy "reservations_insert_own" on public.reservations
  for insert to authenticated
  with check (auth.uid() = patient_id);

-- Mise à jour par le patient propriétaire : annulation depuis l'historique
-- (reservation_history_screen.dart / ReservationProvider.cancelReservation).
-- Note (registre des écarts, item ajouté à la clôture) : comme pour
-- prescriptions_staff_update au Module 5, RLS ne restreint pas ici QUELLES
-- transitions de statut le patient peut effectuer (il pourrait en théorie se
-- mettre lui-même "pickedUp") — même limite déjà documentée et acceptée pour
-- rester cohérent avec le reste du projet plutôt que d'ajouter des triggers
-- hors cahier.
create policy "reservations_patient_update" on public.reservations
  for update to authenticated
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

-- Mise à jour par le pharmacien de son officine : confirmation, "prête",
-- retrait, expiration automatique (ReservationService.confirmReservation /
-- markAsReady / markAsPickedUp / expireOverdueReservations), et mise à jour
-- de la position de file (ReservationProvider.refreshQueue).
create policy "reservations_staff_update" on public.reservations
  for update to authenticated
  using (public.is_pharmacy_staff(pharmacy_id))
  with check (public.is_pharmacy_staff(pharmacy_id));

-- ---------------------------------------------------------------------------
-- reservation_items
-- ---------------------------------------------------------------------------

-- Lecture pharmacien : nécessaire pour que la file d'attente affiche le
-- contenu du panier de chaque réservation (embed reservation_items(*) dans
-- ReservationService._reservationSelect). Sans cette policy, la policy
-- staff sur reservations seule ne suffit pas — reservation_items a sa
-- propre RLS, indépendante.
create policy "reservation_items_staff_select" on public.reservation_items
  for select to authenticated
  using (
    exists (
      select 1 from public.reservations r
      where r.id = reservation_items.reservation_id
        and public.is_pharmacy_staff(r.pharmacy_id)
    )
  );

-- Dépôt des lignes d'une réservation par son propriétaire, au moment de la
-- création (ReservationService.createReservation insère reservation_items
-- juste après reservations).
create policy "reservation_items_insert_own" on public.reservation_items
  for insert to authenticated
  with check (
    exists (
      select 1 from public.reservations r
      where r.id = reservation_items.reservation_id
        and r.patient_id = auth.uid()
    )
  );
