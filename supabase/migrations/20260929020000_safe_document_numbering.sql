-- Correctif C202 : numerotation globale sure des documents (retours client et
-- fournisseur, tickets de support, e-ordonnances, contrats B2B).
--
-- Meme defaut que celui corrige par C197 pour les ventes et les recus POS
-- (20260929010000_pos_atomic_sale_refund.sql), dont ce fichier reprend le
-- modele : les fonctions de numerotation calculaient max(numero) + 1 sans
-- SECURITY DEFINER, donc sous RLS : chaque utilisateur ne voyait que les
-- lignes que sa policy lui ouvre, alors que la colonne numerotee est unique
-- sur toute la table. Le premier document d'une deuxieme officine, d'un
-- deuxieme patient ou d'un deuxieme medecin reprenait le numero deja
-- attribue au premier et l'insertion echouait (23505). Deux insertions
-- simultanees pouvaient aussi obtenir le meme numero.
--
-- Fonctions recreees (format de numero strictement inchange) :
--   - generate_customer_return_number()  (20260829010000_returns.sql)
--   - generate_supplier_return_number()  (20260829010000_returns.sql)
--   - generate_ticket_number()           (20260827008000_support.sql)
--   - generate_prescription_number()     (20260827009500_eprescription.sql)
--   - generate_contract_number()         (20260829004000_business.sql)
--
-- Pour les contrats, la seule policy (is_gsg_admin()) voit toutes les
-- lignes : pas de collision entre utilisateurs, mais la course entre deux
-- insertions simultanees existait aussi.
--
-- SECURITY DEFINER pour voir toutes les lignes, verrou transactionnel pour
-- serialiser les creations simultanees. Pas de sequence : un rollback ne
-- laisse pas de trou dans la numerotation. Les declencheurs existants
-- appellent ces fonctions par leur nom : ils ne sont pas recrees.
--
-- Aucune migration existante modifiee.

create or replace function public.generate_customer_return_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('customer_returns.return_number'));
  select coalesce(max(substring(return_number from '^CR([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.customer_returns;
  new.return_number := 'CR' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

create or replace function public.generate_supplier_return_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('supplier_returns.return_number'));
  select coalesce(max(substring(return_number from '^SR([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.supplier_returns;
  new.return_number := 'SR' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

create or replace function public.generate_ticket_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('support_tickets.ticket_number'));
  select coalesce(max(substring(ticket_number from '^T([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.support_tickets;
  new.ticket_number := 'T' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

create or replace function public.generate_prescription_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('eprescriptions.prescription_number'));
  select coalesce(max(substring(prescription_number from '^RX([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.eprescriptions;
  new.prescription_number := 'RX' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;

create or replace function public.generate_contract_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  perform pg_advisory_xact_lock(hashtext('business_contracts.contract_number'));
  select coalesce(max(substring(contract_number from '^CON-([0-9]+)$')::integer), 0) + 1
    into next_number
    from public.business_contracts;
  new.contract_number := 'CON-' || lpad(next_number::text, 6, '0');
  return new;
end;
$$;
