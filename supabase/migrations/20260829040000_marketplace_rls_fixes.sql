-- Audit Module 13 (B2B — Marketplace B2B Grossistes ↔ Pharmacies), 29/08/2026
--
-- Bug de sécurité critique, distinct du motif « policy manquante » déjà vu
-- aux Modules 8/10/11/12 (registre C1/C35/C37/C39/C41) : ici les 8 policies
-- RLS écrites pour ce module comparent `auth.uid()` — l'identifiant de
-- l'utilisateur authentifié (`profiles.id`/`auth.users.id`) — directement à
-- une colonne typée `pharmacies.id` (`seller_pharmacy_id`/
-- `buyer_pharmacy_id`). Ces deux espaces d'identifiants ne coïncident
-- JAMAIS (un utilisateur n'est pas son officine) : la condition est donc
-- structurellement toujours fausse, quel que soit l'utilisateur connecté.
-- Concrètement, avant ce correctif : un pharmacien ne peut ni créer, ni
-- modifier, ni retirer sa propre offre ; un acheteur ne peut jamais créer de
-- commande ni de négociation ; un vendeur ne peut jamais confirmer/refuser
-- une commande reçue ni répondre à une négociation. Seule la policy
-- publique "Everyone view active offers" fonctionne (et fonctionne même
-- pour un utilisateur anonyme, faute de clause `to authenticated` — accepté
-- ici : le cahier prévoit un catalogue B2B consultable, RG-B2B-01 porte sur
-- le référencement du fournisseur, pas sur la visibilité du catalogue).
--
-- Correctif : remplacer chaque comparaison par `public.is_pharmacy_staff(...)`
-- (déjà utilisée dans tous les modules précédents), qui vérifie correctement
-- `profiles.pharmacy_id = target AND role IN (...)`.
--
-- Bug fonctionnel additionnel corrigé au passage : "Sellers update orders"
-- était la SEULE policy UPDATE sur b2b_orders — même après correction de
-- l'identifiant, un acheteur n'aurait jamais pu soumettre ('draft' →
-- 'submitted') ni annuler sa propre commande brouillon (order_detail_screen
-- .dart propose pourtant ces deux actions à l'acheteur). Ajout d'une policy
-- symétrique "Buyers update orders".

-- ---- b2b_offers ----

drop policy if exists "Sellers manage offers" on public.b2b_offers;
create policy "Sellers manage offers" on public.b2b_offers
  for all using (public.is_pharmacy_staff(seller_pharmacy_id))
  with check (public.is_pharmacy_staff(seller_pharmacy_id));

-- ---- b2b_orders ----

drop policy if exists "Involved pharmacies view orders" on public.b2b_orders;
create policy "Involved pharmacies view orders" on public.b2b_orders
  for select using (
    public.is_pharmacy_staff(buyer_pharmacy_id)
    or public.is_pharmacy_staff(seller_pharmacy_id)
  );

drop policy if exists "Buyers create orders" on public.b2b_orders;
create policy "Buyers create orders" on public.b2b_orders
  for insert with check (public.is_pharmacy_staff(buyer_pharmacy_id));

drop policy if exists "Sellers update orders" on public.b2b_orders;
create policy "Sellers update orders" on public.b2b_orders
  for update using (public.is_pharmacy_staff(seller_pharmacy_id))
  with check (public.is_pharmacy_staff(seller_pharmacy_id));

-- Nouvelle policy (absente à tort de la migration d'origine) : sans elle,
-- même après le correctif d'identifiant ci-dessus, un acheteur ne pourrait
-- jamais modifier sa propre commande (soumettre/annuler un brouillon —
-- actions proposées par order_detail_screen.dart, ligne ~244 et ~265).
create policy "Buyers update orders" on public.b2b_orders
  for update using (public.is_pharmacy_staff(buyer_pharmacy_id))
  with check (public.is_pharmacy_staff(buyer_pharmacy_id));

-- ---- b2b_order_items ----

drop policy if exists "Order items viewable with order" on public.b2b_order_items;
create policy "Order items viewable with order" on public.b2b_order_items
  for select using (
    exists (
      select 1 from public.b2b_orders o
      where o.id = order_id
        and (
          public.is_pharmacy_staff(o.buyer_pharmacy_id)
          or public.is_pharmacy_staff(o.seller_pharmacy_id)
        )
    )
  );

drop policy if exists "Order items managed with order" on public.b2b_order_items;
create policy "Order items managed with order" on public.b2b_order_items
  for all using (
    exists (
      select 1 from public.b2b_orders o
      where o.id = order_id
        and public.is_pharmacy_staff(o.buyer_pharmacy_id)
    )
  ) with check (
    exists (
      select 1 from public.b2b_orders o
      where o.id = order_id
        and public.is_pharmacy_staff(o.buyer_pharmacy_id)
    )
  );

-- ---- b2b_negotiations ----

drop policy if exists "Involved pharmacies view negotiations" on public.b2b_negotiations;
create policy "Involved pharmacies view negotiations" on public.b2b_negotiations
  for select using (
    exists (
      select 1 from public.b2b_offers f
      where f.id = offer_id
        and public.is_pharmacy_staff(f.seller_pharmacy_id)
    )
    or public.is_pharmacy_staff(buyer_pharmacy_id)
  );

drop policy if exists "Buyers create negotiations" on public.b2b_negotiations;
create policy "Buyers create negotiations" on public.b2b_negotiations
  for insert with check (public.is_pharmacy_staff(buyer_pharmacy_id));

drop policy if exists "Sellers update negotiations" on public.b2b_negotiations;
create policy "Sellers update negotiations" on public.b2b_negotiations
  for update using (
    exists (
      select 1 from public.b2b_offers f
      where f.id = offer_id
        and public.is_pharmacy_staff(f.seller_pharmacy_id)
    )
  ) with check (
    exists (
      select 1 from public.b2b_offers f
      where f.id = offer_id
        and public.is_pharmacy_staff(f.seller_pharmacy_id)
    )
  );
