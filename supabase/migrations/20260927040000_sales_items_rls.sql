-- Correctif C184 (Critique) : 20260829008000_sales_management.sql (l.226-232)
-- active la RLS sur les tables parentes du module ventes mais oublie quatre
-- tables filles : invoice_payments, customer_order_items, quotation_items,
-- supplier_order_items. anon et authenticated y avaient tous les droits :
-- la seule cle anon suffisait pour lire, creer, modifier ou supprimer les
-- lignes de toutes les officines.
--
-- Aucune migration existante modifiee. Pour chaque table : RLS activee et
-- une politique « for all » dont using et with check sont identiques, qui
-- reprend la politique de la table parente (is_pharmacy_staff(pharmacy_id))
-- via la cle de liaison. Rien de plus : pas d'acces administrateur reseau,
-- pas de restriction par operation (hors perimetre, cf. C175).
--
-- Tables parentes et colonnes de liaison relevees en base (pg_constraint),
-- non devinees :
--   invoice_payments.invoice_id       -> sales_invoices(id)
--   customer_order_items.order_id     -> customer_orders(id)
--   quotation_items.quotation_id      -> quotations(id)
--   supplier_order_items.order_id     -> supplier_orders(id)

alter table public.invoice_payments enable row level security;
alter table public.customer_order_items enable row level security;
alter table public.quotation_items enable row level security;
alter table public.supplier_order_items enable row level security;

create policy "Pharmacy staff manage invoice payments" on public.invoice_payments
  for all
  using (exists (
    select 1 from public.sales_invoices si
    where si.id = invoice_payments.invoice_id
      and public.is_pharmacy_staff(si.pharmacy_id)
  ))
  with check (exists (
    select 1 from public.sales_invoices si
    where si.id = invoice_payments.invoice_id
      and public.is_pharmacy_staff(si.pharmacy_id)
  ));

create policy "Pharmacy staff manage customer order items" on public.customer_order_items
  for all
  using (exists (
    select 1 from public.customer_orders co
    where co.id = customer_order_items.order_id
      and public.is_pharmacy_staff(co.pharmacy_id)
  ))
  with check (exists (
    select 1 from public.customer_orders co
    where co.id = customer_order_items.order_id
      and public.is_pharmacy_staff(co.pharmacy_id)
  ));

create policy "Pharmacy staff manage quotation items" on public.quotation_items
  for all
  using (exists (
    select 1 from public.quotations q
    where q.id = quotation_items.quotation_id
      and public.is_pharmacy_staff(q.pharmacy_id)
  ))
  with check (exists (
    select 1 from public.quotations q
    where q.id = quotation_items.quotation_id
      and public.is_pharmacy_staff(q.pharmacy_id)
  ));

create policy "Pharmacy staff manage supplier order items" on public.supplier_order_items
  for all
  using (exists (
    select 1 from public.supplier_orders so
    where so.id = supplier_order_items.order_id
      and public.is_pharmacy_staff(so.pharmacy_id)
  ))
  with check (exists (
    select 1 from public.supplier_orders so
    where so.id = supplier_order_items.order_id
      and public.is_pharmacy_staff(so.pharmacy_id)
  ));
