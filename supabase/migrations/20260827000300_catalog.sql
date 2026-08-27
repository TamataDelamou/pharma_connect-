-- Module catalog (lib/modules/catalog, lib/shared/models/product.dart).
-- Référentiel médicament du produit — distinct du futur GSG Referential
-- (pays/devise/langue) : `code_domaine = pharmaceutique` du Referential
-- Engine n'est pas encore branché, voir PharmaConnect_CLAUDE.md.

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text not null,
  created_at timestamptz not null default now()
);

comment on table public.categories is 'Catégories de médicaments du catalogue.';

create table if not exists public.manufacturers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  logo_url text,
  created_at timestamptz not null default now()
);

comment on table public.manufacturers is 'Fabricants référencés au catalogue.';

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  generic_name text not null,
  dosage text not null,
  form text not null,
  category_id uuid references public.categories(id),
  manufacturer_id uuid references public.manufacturers(id),
  image_url text,
  is_generic boolean not null default false,
  is_prescription_required boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.products is
  'Médicaments du catalogue. category_id/manufacturer_id normalisent les champs texte category/manufacturer du modèle Dart Product.';

create index if not exists idx_products_category_id on public.products(category_id);
create index if not exists idx_products_manufacturer_id on public.products(manufacturer_id);

create trigger set_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.manufacturers enable row level security;
alter table public.products enable row level security;

create policy "categories_select_authenticated" on public.categories
  for select to authenticated using (true);

create policy "manufacturers_select_authenticated" on public.manufacturers
  for select to authenticated using (true);

create policy "products_select_authenticated" on public.products
  for select to authenticated using (true);
