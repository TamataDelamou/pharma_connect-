-- Module payments (lib/modules/payments). Paiement, Mobile Money,
-- échéancier, portefeuille et facturation. Tous les montants en INTEGER,
-- unité mineure (KER-REF-05) — c'est le module où cette règle compte le
-- plus (voir REFERENTIEL_ARCHITECTE.md §3.1, déjà résolu côté Dart).

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid references public.reservations(id),
  delivery_id uuid references public.deliveries(id),
  prescription_id uuid references public.prescriptions(id),
  user_id uuid references auth.users(id),
  user_phone text not null,
  pharmacy_id uuid references public.pharmacies(id),
  pharmacy_name text,
  amount integer not null,
  fee integer,
  cashback integer,
  final_amount integer not null,
  method text not null check (method in (
    'orangeMoney', 'mtnMomo', 'moovMoney', 'bankCard', 'gsgWallet', 'cashOnDelivery', 'installment'
  )),
  status text not null default 'pending' check (status in (
    'pending', 'processing', 'completed', 'failed', 'refunded', 'disputed'
  )),
  completed_at timestamptz,
  refunded_at timestamptz,
  transaction_reference text,
  external_reference text,
  qr_code_token text,
  metadata jsonb,
  notes text,
  created_at timestamptz not null default now()
);

comment on table public.transactions is 'Transactions de paiement (payments/models/transaction.dart).';
comment on column public.transactions.amount is 'Unité mineure (KER-REF-05).';

create index if not exists idx_transactions_user_id on public.transactions(user_id);
create index if not exists idx_transactions_reservation_id on public.transactions(reservation_id);
create index if not exists idx_transactions_status on public.transactions(status);

create table if not exists public.installments (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  total_amount integer not null,
  number_of_payments integer not null,
  amount_per_payment integer not null,
  start_date date not null,
  status text not null default 'active' check (status in (
    'active', 'completed', 'delayed', 'cancelled'
  )),
  completed_at timestamptz
);

comment on table public.installments is 'Échéanciers de paiement (payments/models/installment.dart : Installment).';
comment on column public.installments.total_amount is 'Unité mineure (KER-REF-05).';

create index if not exists idx_installments_transaction_id on public.installments(transaction_id);

create table if not exists public.installment_payments (
  id uuid primary key default gen_random_uuid(),
  installment_id uuid not null references public.installments(id) on delete cascade,
  payment_number integer not null,
  amount integer not null,
  due_date date not null,
  paid_at timestamptz,
  status text not null default 'pending' check (status in (
    'pending', 'paid', 'late', 'cancelled'
  )),
  transaction_reference text
);

comment on table public.installment_payments is 'Échéances individuelles (payments/models/installment.dart : InstallmentPayment).';
comment on column public.installment_payments.amount is 'Unité mineure (KER-REF-05).';

create index if not exists idx_installment_payments_installment_id on public.installment_payments(installment_id);

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id),
  balance integer not null default 0,
  pending_balance integer not null default 0,
  total_earned integer not null default 0,
  total_spent integer not null default 0,
  cashback_available integer not null default 0,
  currency text not null default 'GNF',
  last_updated timestamptz not null default now()
);

comment on table public.wallets is 'Portefeuille GSG par utilisateur (payments/models/wallet.dart).';
comment on column public.wallets.balance is 'Unité mineure (KER-REF-05).';

create trigger set_updated_at
  before update on public.wallets
  for each row execute function public.set_updated_at();

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id),
  invoice_number text not null unique,
  pharmacy_name text not null,
  pharmacy_address text not null,
  pharmacy_phone text not null,
  patient_name text not null,
  patient_address text,
  patient_phone text not null,
  patient_email text,
  issued_at timestamptz not null default now(),
  due_date timestamptz,
  subtotal integer not null,
  tax integer not null default 0,
  discount integer not null default 0,
  total integer not null,
  status text not null default 'unpaid' check (status in (
    'paid', 'unpaid', 'cancelled', 'refunded'
  )),
  pdf_url text
);

comment on table public.invoices is 'Factures (payments/models/invoice.dart : Invoice).';
comment on column public.invoices.total is 'Unité mineure (KER-REF-05).';

create index if not exists idx_invoices_transaction_id on public.invoices(transaction_id);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total integer not null,
  dosage text
);

comment on table public.invoice_items is 'Lignes de facture (payments/models/invoice.dart : InvoiceItem).';
comment on column public.invoice_items.unit_price is 'Unité mineure (KER-REF-05).';

create index if not exists idx_invoice_items_invoice_id on public.invoice_items(invoice_id);

alter table public.transactions enable row level security;
alter table public.installments enable row level security;
alter table public.installment_payments enable row level security;
alter table public.wallets enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;

create policy "transactions_select_own" on public.transactions
  for select to authenticated
  using (auth.uid() = user_id);

create policy "installments_select_own" on public.installments
  for select to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = installments.transaction_id and t.user_id = auth.uid()
    )
  );

create policy "installment_payments_select_own" on public.installment_payments
  for select to authenticated
  using (
    exists (
      select 1 from public.installments i
      join public.transactions t on t.id = i.transaction_id
      where i.id = installment_payments.installment_id and t.user_id = auth.uid()
    )
  );

create policy "wallets_select_own" on public.wallets
  for select to authenticated
  using (auth.uid() = user_id);

create policy "invoices_select_own" on public.invoices
  for select to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = invoices.transaction_id and t.user_id = auth.uid()
    )
  );

create policy "invoice_items_select_own" on public.invoice_items
  for select to authenticated
  using (
    exists (
      select 1 from public.invoices inv
      join public.transactions t on t.id = inv.transaction_id
      where inv.id = invoice_items.invoice_id and t.user_id = auth.uid()
    )
  );
