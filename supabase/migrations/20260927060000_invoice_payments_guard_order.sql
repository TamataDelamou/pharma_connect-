-- Correctif C186 (a) et (c) : check_invoice_payment()
-- (20260927050000_sales_invoice_payments_integrity.sql) s'execute en
-- SECURITY DEFINER avant la RLS d'invoice_payments. Un pharmacien qui tentait
-- de payer la facture d'une autre officine recevait un message revelant son
-- statut ou son reste du (le paiement restait refuse par la RLS ensuite).
--
-- Aucune migration existante modifiee. La fonction est recreee avec deux
-- controles places avant tout le reste :
--   1. acces : is_pharmacy_staff(pharmacy_id de la facture), sinon 42501 et
--      un message neutre identique que la facture existe ou non ; aucun
--      verrou n'est pose sur la facture avant ce controle ;
--   2. montant : amount <= 0 refuse avec un message en francais. La
--      contrainte invoice_payments_amount_positive est conservee en filet de
--      securite.
-- Le reste (verrou for update, refus draft/cancelled, refus au-dela du reste
-- du) est inchange. Le declencheur check_invoice_payment_before_insert
-- appelle toujours cette fonction, il n'est pas recree.

create or replace function public.check_invoice_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pharmacy_id uuid;
  v_status text;
  v_total integer;
  v_paid bigint;
begin
  select si.pharmacy_id
    into v_pharmacy_id
    from public.sales_invoices si
   where si.id = new.invoice_id;

  if v_pharmacy_id is null or not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'Accès refusé.'
      using errcode = '42501';
  end if;

  if new.amount is null or new.amount <= 0 then
    raise exception 'Paiement refuse : le montant doit etre strictement positif.'
      using errcode = 'P0001';
  end if;

  select si.status, si.total_amount
    into v_status, v_total
    from public.sales_invoices si
   where si.id = new.invoice_id
   for update;

  if v_status = 'draft' then
    raise exception 'Paiement refuse : la facture est encore en brouillon ; elle doit etre envoyee avant tout paiement.'
      using errcode = 'P0001';
  end if;

  if v_status = 'cancelled' then
    raise exception 'Paiement refuse : la facture est annulee.'
      using errcode = 'P0001';
  end if;

  select coalesce(sum(ip.amount), 0)
    into v_paid
    from public.invoice_payments ip
   where ip.invoice_id = new.invoice_id;

  if new.amount > v_total - v_paid then
    raise exception 'Paiement refuse : le montant (%) depasse le reste du de la facture (%).',
      new.amount, v_total - v_paid
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;
