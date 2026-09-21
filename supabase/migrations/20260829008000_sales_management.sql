-- Sales management: customers, suppliers, orders, invoices

-- Customers (extends profiles for non-patient customers)
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  code text unique,
  first_name text not null,
  last_name text not null,
  phone text,
  email text,
  address text,
  city text,
  credit_limit integer default 0,
  balance integer default 0,
  is_active boolean default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Suppliers
create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  code text unique,
  name text not null,
  contact_person text,
  phone text,
  email text,
  address text,
  city text,
  tax_id text,
  is_active boolean default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Customer orders (special orders, not POS sales)
create table public.customer_orders (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  order_number text unique not null,
  order_date timestamptz not null default now(),
  delivery_date timestamptz,
  status text not null check (status in ('draft', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled')),
  total_amount integer not null,
  paid_amount integer default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Customer order items
create table public.customer_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.customer_orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Quotations (proforma invoices)
create table public.quotations (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  quotation_number text unique not null,
  quotation_date timestamptz not null default now(),
  valid_until date,
  total_amount integer not null,
  status text not null check (status in ('draft', 'sent', 'accepted', 'rejected', 'expired')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Quotation items
create table public.quotation_items (
  id uuid primary key default gen_random_uuid(),
  quotation_id uuid not null references public.quotations(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Invoices
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C83 :
-- cette table s'appelait à l'origine `public.invoices`, en collision
-- directe avec `public.invoices` déjà créée par `20260827001300_payments.sql`
-- (Module 8/PAY, déjà clôturé) — schéma totalement différent et sans
-- rapport (facture de vente/achat B2B ici, avec `pharmacy_id`/`customer_id`/
-- `sale_id`/`paid_amount`, contre reçu de transaction patient là-bas, avec
-- `transaction_id`/`pharmacy_name` texte libre/`subtotal`+`tax`+`discount`).
-- Sur une base neuve, `create table public.invoices` (sans `if not exists`,
-- contrairement à celle de payments.sql) aurait échoué avec « relation
-- "invoices" already exists » dès l'application de ce fichier. À la
-- différence de C78 (professional_reviews), il ne s'agit pas ici de deux
-- versions du même concept à fusionner par `alter table` : ce sont deux
-- concepts métier distincts qui ne doivent PAS partager une table — seule
-- `payments.sql`/`invoices` est consommée par du code Dart réel
-- (`lib/modules/payments/models/invoice.dart`, utilisé par
-- `payment_screen.dart`/`transaction_detail_screen.dart`/etc.) ; aucun
-- modèle Dart n'existe pour la table définie ici (`lib/modules/sales` n'a
-- pas d'`invoice.dart`). Renommée `public.sales_invoices` pour lever la
-- collision sans toucher à `payments.sql` ni risquer de mélanger deux
-- schémas métier différents ; les 8 références internes à ce fichier
-- (index, RLS, policy, FK de `invoice_payments`) sont mises à jour en
-- conséquence.
create table public.sales_invoices (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  sale_id uuid references public.pos_sales(id) on delete set null,
  invoice_number text unique not null,
  invoice_date timestamptz not null default now(),
  due_date date,
  total_amount integer not null,
  paid_amount integer default 0,
  status text not null check (status in ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Invoice payments
create table public.invoice_payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.sales_invoices(id) on delete cascade,
  amount integer not null,
  payment_date timestamptz not null default now(),
  payment_method text not null check (payment_method in ('cash', 'mobile_money', 'card', 'bank_transfer')),
  reference text,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Supplier orders (purchase orders)
create table public.supplier_orders (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  order_number text unique not null,
  order_date timestamptz not null default now(),
  expected_delivery date,
  status text not null check (status in ('draft', 'sent', 'received', 'cancelled')),
  total_amount integer not null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Supplier order items
create table public.supplier_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.supplier_orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  received_quantity integer default 0,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_customers_pharmacy_id on public.customers(pharmacy_id);
create index idx_customers_code on public.customers(code);
create index idx_suppliers_pharmacy_id on public.suppliers(pharmacy_id);
create index idx_customer_orders_pharmacy_id on public.customer_orders(pharmacy_id);
create index idx_customer_orders_customer_id on public.customer_orders(customer_id);
create index idx_customer_orders_status on public.customer_orders(status);
create index idx_quotations_pharmacy_id on public.quotations(pharmacy_id);
create index idx_quotations_customer_id on public.quotations(customer_id);
create index idx_sales_invoices_pharmacy_id on public.sales_invoices(pharmacy_id);
create index idx_sales_invoices_customer_id on public.sales_invoices(customer_id);
create index idx_sales_invoices_status on public.sales_invoices(status);
create index idx_supplier_orders_pharmacy_id on public.supplier_orders(pharmacy_id);
create index idx_supplier_orders_supplier_id on public.supplier_orders(supplier_id);

-- RLS (simplifié)
alter table public.customers enable row level security;
alter table public.suppliers enable row level security;
alter table public.customer_orders enable row level security;
alter table public.quotations enable row level security;
alter table public.sales_invoices enable row level security;
alter table public.supplier_orders enable row level security;

-- Pharmacy staff manage all
-- (audit Module 0, 29/08/2026 : `public.pharmacy_staff` n'existe pas, voir
-- la même note dans 20260829006000_pos.sql — remplacé par is_pharmacy_staff().
-- Les tables customer_returns / customer_return_items / cash_drawer_sessions
-- / cash_movements, définies plus bas dans la version d'origine de ce
-- fichier, ont été retirées : elles dupliquaient exactement les mêmes
-- tables + policies déjà créées par 20260829010000_returns.sql et
-- 20260829009000_cash.sql, sous le même timestamp que ce fichier
-- [20260829008000] — un `supabase db push` aurait échoué sur "relation
-- already exists" dès l'application du second fichier concerné. Voir la
-- note équivalente dans 20260829008000_sales.sql, neutralisé pour la même
-- raison de collision de nommage.)
create policy "Pharmacy staff manage sales" on public.customers for all using (public.is_pharmacy_staff(pharmacy_id));
create policy "Pharmacy staff manage suppliers" on public.suppliers for all using (public.is_pharmacy_staff(pharmacy_id));
create policy "Pharmacy staff manage orders" on public.customer_orders for all using (public.is_pharmacy_staff(pharmacy_id));
create policy "Pharmacy staff manage quotations" on public.quotations for all using (public.is_pharmacy_staff(pharmacy_id));
create policy "Pharmacy staff manage sales invoices" on public.sales_invoices for all using (public.is_pharmacy_staff(pharmacy_id));
create policy "Pharmacy staff manage supplier orders" on public.supplier_orders for all using (public.is_pharmacy_staff(pharmacy_id));

-- Network admins view all
create policy "Network admins view all sales" on public.customers for select using (exists (select 1 from public.network_admin_roles where user_id = auth.uid() and role in ('super_admin', 'network_admin')));
create policy "Network admins view all suppliers" on public.suppliers for select using (exists (select 1 from public.network_admin_roles where user_id = auth.uid() and role in ('super_admin', 'network_admin')));
