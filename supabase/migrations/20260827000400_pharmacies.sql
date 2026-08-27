-- Officines. Trois modèles Dart décrivent chacun une vue partielle de la
-- même entité réelle (une pharmacie) : AdminPharmacy (admin/models,
-- gestion DNPM), Pharmacy (search/models, vue publique/recherche) et
-- PharmacyBranch (stock/models/pharmacy_group.dart, notion de succursale).
-- Une seule table canonique ici plutôt que trois tables dupliquées — chaque
-- service Dart peut continuer à exposer sa propre vue (sous-ensemble de
-- colonnes) sans que le schéma la duplique physiquement.
--
-- RG-AUT-01 : un compte pharmacie ne peut être activé (status = 'active')
-- qu'après vérification de la licence auprès de la DNPM.

create table if not exists public.pharmacy_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.pharmacy_groups is
  'Groupes/enseignes de pharmacies (stock/models/pharmacy_group.dart : PharmacyGroup).';

create table if not exists public.pharmacies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  phone text not null,
  email text,
  license_number text,
  status text not null default 'pending' check (status in (
    'pending', 'verified', 'active', 'suspended', 'underReview', 'rejected'
  )),
  license_expiry_date timestamptz,
  license_verified_at timestamptz,
  manager_id uuid references auth.users(id),
  manager_name text,
  group_id uuid references public.pharmacy_groups(id),
  latitude double precision not null,
  longitude double precision not null,
  is_active boolean not null default true,
  status_updated_at timestamptz,
  notes text,
  -- KER-VIS-01 / Org Registry : une pharmacie est l'entité "Organisation"
  -- de PharmaConnect au sens du Kernel GSG. Correspondance nullable, jamais
  -- une FK, tant que l'Org Registry n'est pas branché en production.
  gsg_org_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.pharmacies is
  'Table canonique des officines. Fusionne AdminPharmacy (admin/models), Pharmacy (search/models) et PharmacyBranch (stock/models/pharmacy_group.dart).';
comment on column public.pharmacies.gsg_org_id is
  'Correspondance vers l''organisation GSG (Org Registry, KER-VIS-01). Nullable tant que le Kernel n''est pas branché.';

create index if not exists idx_pharmacies_group_id on public.pharmacies(group_id);
create index if not exists idx_pharmacies_status on public.pharmacies(status);

create trigger set_updated_at
  before update on public.pharmacies
  for each row execute function public.set_updated_at();

alter table public.pharmacy_groups enable row level security;
alter table public.pharmacies enable row level security;

create policy "pharmacy_groups_select_authenticated" on public.pharmacy_groups
  for select to authenticated using (true);

create policy "pharmacies_select_authenticated" on public.pharmacies
  for select to authenticated using (true);
