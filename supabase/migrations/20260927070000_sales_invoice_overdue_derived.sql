-- Correctifs C185 et C187 sur sales_invoices.
--
-- C185 — decision du porteur du projet (27/09/2026) : « en retard » est
-- calcule a la volee, jamais stocke : une facture est en retard si
-- status = 'sent', due_date non NULL et anterieure a la date du jour. Une
-- facture payee, en brouillon ou annulee n'est jamais en retard. La valeur
-- 'overdue' disparait donc des statuts stockes.
--
-- C187 — total_amount n'avait aucune contrainte de valeur : un montant
-- negatif etait accepte.
--
-- Aucune migration existante modifiee. Nom de contrainte releve en base
-- (pg_constraint), non devine.

-- (a) Les factures stockees en 'overdue' redeviennent 'sent' : leur retard est
--     desormais deduit de due_date. guard_sales_invoice_update()
--     (20260927050000_sales_invoice_payments_integrity.sql) laisse passer ce
--     changement, qui ne touche ni 'paid' ni paid_amount.
update public.sales_invoices
   set status = 'sent',
       updated_at = now()
 where status = 'overdue';

-- (b) Contrainte des statuts sans 'overdue'.
alter table public.sales_invoices
  drop constraint sales_invoices_status_check;

alter table public.sales_invoices
  add constraint sales_invoices_status_check
  check (status in ('draft', 'sent', 'paid', 'cancelled'));

-- (c) C187 : montant total positif ou nul.
alter table public.sales_invoices
  add constraint sales_invoices_total_amount_non_negative
  check (total_amount >= 0);
