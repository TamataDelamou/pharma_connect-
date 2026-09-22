-- Chains module: multi-pharmacy groups and stock transfers
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87, corrigé dans
-- le même mouvement (même nature bloquante que C78/C83) :
-- `create table pharmacy_groups` entrait en collision directe avec
-- `public.pharmacy_groups` déjà créée par `20260827000400_pharmacies.sql`
-- (schéma plus simple : id/name/code/is_active/created_at, consommé par un
-- modèle Dart réel — `lib/modules/stock/models/pharmacy_group.dart`,
-- classe `PharmacyGroup`, champs id/name/code/isActive — préservés à
-- l'identique ici). Confirmé bloquant par exécution réelle
-- (`relation "pharmacy_groups" already exists`). Convertie en
-- `alter table ... add column if not exists`, même principe que C78, pour
-- enrichir la table existante (description, logo, propriétaire, audit
-- trail, lien Kernel GSG) sans la recréer ni casser le modèle Dart déjà
-- consommé.
--
-- Anomalie non bloquante trouvée au passage, non corrigée ici (n'empêche
-- pas `supabase db push`, consignée au registre sous C88 avec le reste) :
-- la policy `pharmacy_groups_select_authenticated` (`using (true)`,
-- `20260827000400_pharmacies.sql`) reste active et n'est pas remplacée
-- par la policy plus restreinte "Everyone view active groups" ci-dessous
-- (`is_active = true`) -- combinées en OR, la première rend la seconde
-- inopérante (un groupe inactif reste visible), même défaut de principe
-- que celui déjà corrigé pour C78/C79 ailleurs dans le projet.
alter table public.pharmacy_groups
  add column if not exists description text,
  add column if not exists logo_url text,
  add column if not exists owner_id uuid references public.profiles(id) on delete set null,
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists created_by uuid references public.profiles(id),
  add column if not exists updated_by uuid references public.profiles(id),
  add column if not exists gsg_org_id text, -- Kernel Org Registry ID
  add column if not exists gsg_id text;

-- Group members (pharmacies in the group)
create table group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.pharmacy_groups(id) on delete cascade,
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  role text not null check (role in ('admin', 'manager', 'staff', 'viewer')),
  permissions jsonb default '[]'::jsonb,
  joined_at timestamptz not null default now(),
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text,
  unique(group_id, pharmacy_id)
);

-- Group stock transfers
create table stock_transfers (
  id uuid primary key default gen_random_uuid(),
  from_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  to_pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  group_id uuid references public.pharmacy_groups(id) on delete set null,
  status text not null check (status in ('pending', 'approved', 'in_transit', 'received', 'cancelled')),
  transfer_date timestamptz not null default now(),
  received_date timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Transfer items
create table transfer_items (
  id uuid primary key default gen_random_uuid(),
  transfer_id uuid not null references public.stock_transfers(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  batch_number text,
  expiry_date date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Indexes
create index idx_group_members_group_id on public.group_members(group_id);
create index idx_group_members_pharmacy_id on public.group_members(pharmacy_id);
create index idx_stock_transfers_from_pharmacy on public.stock_transfers(from_pharmacy_id);
create index idx_stock_transfers_to_pharmacy on public.stock_transfers(to_pharmacy_id);
create index idx_stock_transfers_group_id on public.stock_transfers(group_id);
create index idx_transfer_items_transfer_id on public.transfer_items(transfer_id);

-- Triggers for updated_at
create trigger trigger_pharmacy_groups_updated_at
before update on public.pharmacy_groups
for each row execute function public.update_updated_at();

create trigger trigger_group_members_updated_at
before update on public.group_members
for each row execute function public.update_updated_at();

create trigger trigger_stock_transfers_updated_at
before update on public.stock_transfers
for each row execute function public.update_updated_at();

create trigger trigger_transfer_items_updated_at
before update on public.transfer_items
for each row execute function public.update_updated_at();

-- RLS
alter table public.pharmacy_groups enable row level security;
alter table public.group_members enable row level security;
alter table public.stock_transfers enable row level security;
alter table public.transfer_items enable row level security;

-- Pharmacy groups: everyone can view active groups
create policy "Everyone view active groups" on public.pharmacy_groups
  for select using (is_active = true);

-- Admins can manage groups they own
create policy "Admins manage own groups" on public.pharmacy_groups
  for all using (auth.uid() = owner_id);

-- Group members: members can view
create policy "Members view group members" on public.group_members
  for select using (
    exists (
      select 1 from public.group_members gm
      where gm.group_id = group_members.group_id
      and gm.pharmacy_id = auth.uid()
      and gm.is_active = true
    )
  );

-- Admins can manage group members
create policy "Admins manage group members" on public.group_members
  for all using (
    exists (
      select 1 from public.group_members gm
      where gm.group_id = group_members.group_id
      and gm.pharmacy_id = auth.uid()
      and gm.role = 'admin'
      and gm.is_active = true
    )
  );

-- Stock transfers: involved pharmacies can view
create policy "Involved pharmacies view transfers" on public.stock_transfers
  for select using (
    auth.uid() in (from_pharmacy_id, to_pharmacy_id) or
    exists (
      select 1 from public.group_members gm
      where gm.group_id = stock_transfers.group_id
      and gm.pharmacy_id = auth.uid()
      and gm.role in ('admin', 'manager')
    )
  );

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87, corrigé dans
-- le même mouvement : le `or auth.uid() = from_pharmacy_id` ci-dessous
-- était placé HORS des parenthèses de `using (...)`, une erreur de syntaxe
-- bloquante pour `supabase db push` (confirmée par exécution réelle :
-- `ERROR: syntax error at or near "or"`). En le corrigeant, une seconde
-- anomalie apparaît : `auth.uid() = from_pharmacy_id` compare un id
-- utilisateur (`auth.uid()`) à un id d'officine (`from_pharmacy_id`
-- référence `public.pharmacies(id)`), motif déjà documenté et corrigé
-- ailleurs dans le projet (`stock_forecasting.sql`, « auth.uid() =
-- pharmacy_id comparait un id utilisateur à un id d'officine ») — corrigé
-- de la même manière ici via `is_pharmacy_staff()`.
--
-- Admins can manage transfers
create policy "Admins manage transfers" on public.stock_transfers
  for all using (
    exists (
      select 1 from public.group_members gm
      where gm.group_id = stock_transfers.group_id
      and gm.pharmacy_id = auth.uid()
      and gm.role in ('admin', 'manager')
    )
    or public.is_pharmacy_staff(from_pharmacy_id)
  );

-- Transfer items: viewable with transfer
create policy "Transfer items viewable with transfer" on public.transfer_items
  for select using (
    exists (
      select 1 from public.stock_transfers
      where id = transfer_id
      and (auth.uid() in (from_pharmacy_id, to_pharmacy_id) or
           exists (
             select 1 from public.group_members gm
             where gm.group_id = stock_transfers.group_id
             and gm.pharmacy_id = auth.uid()
             and gm.role in ('admin', 'manager')
           ))
    )
  );

-- Transfer items: managed with transfer
create policy "Transfer items managed with transfer" on public.transfer_items
  for all using (
    exists (
      select 1 from public.stock_transfers
      where id = transfer_id
      and (auth.uid() = from_pharmacy_id or
           exists (
             select 1 from public.group_members gm
             where gm.group_id = stock_transfers.group_id
             and gm.pharmacy_id = auth.uid()
             and gm.role in ('admin', 'manager')
           ))
    )
  );
