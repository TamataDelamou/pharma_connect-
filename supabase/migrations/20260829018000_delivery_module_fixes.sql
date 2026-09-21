-- Correctifs Module 7 (LIV — Livraison & Logistique du dernier kilomètre),
-- audit du 29/08/2026.
--
-- 1) Même défaut récurrent que reservations (Module 6) et prescriptions
--    (Module 5) : 20260827001200_delivery.sql n'ouvrait AUCUNE policy
--    d'écriture sur deliveries/delivery_drivers/delivery_proofs (select
--    uniquement) — ni la création d'une livraison par un patient, ni son
--    traitement (assignation, démarrage, arrivée, clôture) par un livreur
--    ou le personnel d'une officine n'étaient possibles en production.
-- 2) `deliveries` n'a pas de colonne pharmacy_id directe (contrairement à
--    reservations) : l'officine responsable d'une livraison se déduit de
--    reservations.pharmacy_id via deliveries.reservation_id. Les policies
--    "staff" ci-dessous scopent donc via une jointure sur reservations,
--    plutôt que directement comme pour RES.
-- 3) Colonne confirmation_code ajoutée à deliveries : générée à la
--    planification (DeliveryService.scheduleDelivery), affichée au patient,
--    et désormais vérifiée côté service à la clôture de la livraison
--    (RG-LIV-02 — voir le commentaire dans delivery_service.dart pour le
--    détail du bug corrigé : la preuve de remise était jusqu'ici un code
--    généré par le client lui-même au moment de cliquer "confirmer", donc
--    aucune vérification réelle).

alter table public.deliveries
  add column if not exists confirmation_code text;

comment on column public.deliveries.confirmation_code is
  'Code de remise généré à la planification (RG-LIV-02), affiché au patient et vérifié à la clôture de la livraison.';

-- Identifie si l'utilisateur authentifié est le livreur propriétaire de
-- delivery_drivers.id = target_driver_id (rattachement par user_id, comme
-- pharmacy_id/is_pharmacy_staff pour le personnel d'officine).
create or replace function public.is_delivery_driver(target_driver_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.delivery_drivers d
    where d.id = target_driver_id
      and d.user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- deliveries
-- ---------------------------------------------------------------------------

-- Lecture par le livreur assigné (driver_dashboard_screen.dart) — absente
-- jusqu'ici, aucun livreur ne pouvait voir ses propres courses.
create policy "deliveries_driver_select" on public.deliveries
  for select to authenticated
  using (driver_id is not null and public.is_delivery_driver(driver_id));

-- Lecture par le personnel de l'officine d'origine (delivery_schedule_screen.dart,
-- planification/assignation) — via la réservation d'origine.
create policy "deliveries_staff_select" on public.deliveries
  for select to authenticated
  using (
    exists (
      select 1 from public.reservations r
      where r.id = deliveries.reservation_id
        and public.is_pharmacy_staff(r.pharmacy_id)
    )
  );

-- Création d'une livraison par le patient authentifié
-- (DeliveryService.scheduleDelivery, appelé depuis reservation_checkout_screen.dart
-- quand une adresse de livraison a été renseignée).
create policy "deliveries_insert_own" on public.deliveries
  for insert to authenticated
  with check (auth.uid() = patient_id);

-- Mise à jour par le patient propriétaire : annulation depuis le suivi
-- (delivery_tracking_screen.dart / DeliveryProvider.cancelDelivery), et
-- confirmation de réception (limite documentée dans le registre des écarts :
-- RLS n'empêche pas plus ici qu'ailleurs dans le projet un patient de poser
-- n'importe quel statut sur sa propre livraison — même réserve que
-- reservations_patient_update au Module 6).
create policy "deliveries_patient_update" on public.deliveries
  for update to authenticated
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

-- Mise à jour par le livreur assigné : démarrage, position, arrivée, clôture
-- (DeliveryService.startDelivery/updateLocation/markAsArrived/completeDelivery).
create policy "deliveries_driver_update" on public.deliveries
  for update to authenticated
  using (driver_id is not null and public.is_delivery_driver(driver_id))
  with check (driver_id is not null and public.is_delivery_driver(driver_id));

-- Mise à jour par le personnel de l'officine d'origine : assignation d'un
-- livreur (DeliveryService.assignDriver, seule écriture qui change
-- driver_id lui-même — au moment de l'assignation, l'ancienne valeur de
-- driver_id peut être NULL, donc non couverte par deliveries_driver_update).
create policy "deliveries_staff_update" on public.deliveries
  for update to authenticated
  using (
    exists (
      select 1 from public.reservations r
      where r.id = deliveries.reservation_id
        and public.is_pharmacy_staff(r.pharmacy_id)
    )
  )
  with check (
    exists (
      select 1 from public.reservations r
      where r.id = deliveries.reservation_id
        and public.is_pharmacy_staff(r.pharmacy_id)
    )
  );

-- ---------------------------------------------------------------------------
-- delivery_proofs
-- ---------------------------------------------------------------------------

-- Écriture (upsert) de la preuve de remise par le livreur assigné, à la
-- clôture de la livraison (DeliveryService.completeDelivery).
create policy "delivery_proofs_driver_write" on public.delivery_proofs
  for insert to authenticated
  with check (
    exists (
      select 1 from public.deliveries d
      where d.id = delivery_proofs.delivery_id
        and d.driver_id is not null
        and public.is_delivery_driver(d.driver_id)
    )
  );

create policy "delivery_proofs_driver_update" on public.delivery_proofs
  for update to authenticated
  using (
    exists (
      select 1 from public.deliveries d
      where d.id = delivery_proofs.delivery_id
        and d.driver_id is not null
        and public.is_delivery_driver(d.driver_id)
    )
  )
  with check (
    exists (
      select 1 from public.deliveries d
      where d.id = delivery_proofs.delivery_id
        and d.driver_id is not null
        and public.is_delivery_driver(d.driver_id)
    )
  );

-- ---------------------------------------------------------------------------
-- delivery_drivers
-- ---------------------------------------------------------------------------

-- Un livreur met à jour sa propre fiche (disponibilité, position courante —
-- DeliveryService.updateDriverLocation). La création/désactivation d'un
-- livreur (recrutement, retrait du réseau) reste une opération back-office :
-- aucune UI de gestion des livreurs n'existe dans ce module (voir le
-- rapport d'audit) — seul is_gsg_admin() peut donc créer une fiche.
create policy "delivery_drivers_self_update" on public.delivery_drivers
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "delivery_drivers_admin_insert" on public.delivery_drivers
  for insert to authenticated
  with check (public.is_gsg_admin());
