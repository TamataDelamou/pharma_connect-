-- Correctif C175 : integrite des paiements de factures de vente.
-- Regles validees par le porteur du projet (27/09/2026, voir registre C175) :
--   (1) paid_amount est calcule uniquement par la base (somme des paiements) ;
--   (2) le statut 'paid' est pose uniquement par la base et ne peut plus etre
--       retire a la main ; le pharmacien garde draft, sent, cancelled (et
--       overdue, manuel, cf. C185) ;
--   (3) paiement refuse sur une facture draft ou cancelled ;
--   (4) paiement refuse s'il est nul, negatif ou superieur au reste du ;
--   (5) un paiement enregistre ne peut etre ni modifie ni supprime ;
--   (6) une facture qui a recu des paiements ne peut pas etre supprimee
--       (seulement annulee).
--
-- Aucune migration existante modifiee. Noms de contrainte et de politique
-- releves en base (pg_constraint, pg_policies), non devines.

-- (a) invoice_payments : montant strictement positif, index de lecture,
--     lecture et insertion seulement (regle 5 : aucune politique UPDATE ni
--     DELETE). Meme condition que la politique « for all » de C184
--     (20260927040000_sales_items_rls.sql), qu'elles remplacent.
alter table public.invoice_payments
  add constraint invoice_payments_amount_positive check (amount > 0);

create index idx_invoice_payments_invoice_id on public.invoice_payments(invoice_id);

drop policy "Pharmacy staff manage invoice payments" on public.invoice_payments;

create policy "Pharmacy staff view invoice payments" on public.invoice_payments
  for select
  using (exists (
    select 1 from public.sales_invoices si
    where si.id = invoice_payments.invoice_id
      and public.is_pharmacy_staff(si.pharmacy_id)
  ));

create policy "Pharmacy staff insert invoice payments" on public.invoice_payments
  for insert
  with check (exists (
    select 1 from public.sales_invoices si
    where si.id = invoice_payments.invoice_id
      and public.is_pharmacy_staff(si.pharmacy_id)
  ));

-- (b) Regle 6 : la suppression d'une facture ne supprime plus ses paiements
--     en cascade, elle est refusee tant qu'il en existe.
alter table public.invoice_payments
  drop constraint invoice_payments_invoice_id_fkey;

alter table public.invoice_payments
  add constraint invoice_payments_invoice_id_fkey
  foreign key (invoice_id) references public.sales_invoices(id) on delete restrict;

-- (f) Recalcul de paid_amount pour les factures existantes, avant la pose des
--     declencheurs de sales_invoices (point e), qui refuseraient cette ecriture.
update public.sales_invoices si
set paid_amount = coalesce((
  select sum(ip.amount) from public.invoice_payments ip where ip.invoice_id = si.id
), 0)::integer
where si.paid_amount is distinct from coalesce((
  select sum(ip.amount) from public.invoice_payments ip where ip.invoice_id = si.id
), 0);

alter table public.sales_invoices alter column paid_amount set not null;

-- (c) Controle avant insertion d'un paiement (regles 3 et 4). La facture est
--     verrouillee (for update) pour que deux paiements simultanes ne puissent
--     pas depasser ensemble le reste du.
create or replace function public.check_invoice_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_total integer;
  v_paid bigint;
begin
  select si.status, si.total_amount
    into v_status, v_total
    from public.sales_invoices si
   where si.id = new.invoice_id
   for update;

  if not found then
    raise exception 'Paiement refuse : facture % introuvable.', new.invoice_id
      using errcode = '23503';
  end if;

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

create trigger check_invoice_payment_before_insert
  before insert on public.invoice_payments
  for each row execute function public.check_invoice_payment();

-- (d) Recalcul apres insertion d'un paiement (regles 1 et 2). L'ecriture est
--     signalee comme « systeme » par un reglage local a la transaction, lu par
--     guard_sales_invoice_update() (point e), puis le reglage est retire.
create or replace function public.apply_invoice_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_paid bigint;
begin
  select coalesce(sum(ip.amount), 0)
    into v_paid
    from public.invoice_payments ip
   where ip.invoice_id = new.invoice_id;

  perform set_config('pharmaconnect.invoice_system_write', 'on', true);

  update public.sales_invoices si
     set paid_amount = v_paid::integer,
         status = case when v_paid >= si.total_amount then 'paid' else si.status end,
         updated_at = now()
   where si.id = new.invoice_id;

  perform set_config('pharmaconnect.invoice_system_write', 'off', true);

  return null;
end;
$$;

create trigger apply_invoice_payment_after_insert
  after insert on public.invoice_payments
  for each row execute function public.apply_invoice_payment();

-- (e) Garde-fous sur sales_invoices.
--     Insertion : paid_amount force a 0, statut 'paid' refuse.
create or replace function public.guard_sales_invoice_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.paid_amount := 0;

  if new.status = 'paid' then
    raise exception 'Creation refusee : le statut « payee » est pose uniquement par l''enregistrement des paiements.'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger guard_sales_invoice_before_insert
  before insert on public.sales_invoices
  for each row execute function public.guard_sales_invoice_insert();

--     Mise a jour, hors ecriture systeme du point d : seuls les changements
--     effectifs sont refuses (is distinct from), une mise a jour qui renvoie
--     les memes valeurs passe (le Dart renvoie toutes les colonnes).
create or replace function public.guard_sales_invoice_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('pharmaconnect.invoice_system_write', true), 'off') = 'on' then
    return new;
  end if;

  if new.paid_amount is distinct from old.paid_amount then
    raise exception 'Modification refusee : le montant paye est calcule a partir des paiements enregistres.'
      using errcode = 'P0001';
  end if;

  if new.status = 'paid' and old.status is distinct from 'paid' then
    raise exception 'Modification refusee : le statut « payee » est pose uniquement par l''enregistrement des paiements.'
      using errcode = 'P0001';
  end if;

  if old.status = 'paid' and new.status is distinct from 'paid' then
    raise exception 'Modification refusee : une facture payee ne peut plus changer de statut.'
      using errcode = 'P0001';
  end if;

  if new.total_amount is distinct from old.total_amount
     and exists (select 1 from public.invoice_payments ip where ip.invoice_id = old.id) then
    raise exception 'Modification refusee : le montant total ne peut plus changer, la facture a deja recu des paiements.'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger guard_sales_invoice_before_update
  before update on public.sales_invoices
  for each row execute function public.guard_sales_invoice_update();
