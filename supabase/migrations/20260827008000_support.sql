-- Support module: customer support tickets

-- Support categories
create table public.support_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  description text,
  icon text,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Support tickets
create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_number text unique not null,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid references public.support_categories(id) on delete set null,
  subject text not null,
  description text not null,
  status text not null check (status in ('new', 'in_progress', 'waiting_for_patient', 'resolved', 'closed', 'cancelled')),
  priority text not null check (priority in ('low', 'medium', 'high', 'critical')),
  assigned_to uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  closed_at timestamptz,
  escalation_level integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Ticket responses (conversation)
create table public.support_responses (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  is_internal boolean default false, -- staff internal notes
  attachments text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Ticket feedback
create table public.support_feedback (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(ticket_id)
);

-- Indexes
create index idx_support_tickets_patient_id on public.support_tickets(patient_id);
create index idx_support_tickets_assigned_to on public.support_tickets(assigned_to);
create index idx_support_tickets_status on public.support_tickets(status);
create index idx_support_tickets_priority on public.support_tickets(priority);
create index idx_support_tickets_ticket_number on public.support_tickets(ticket_number);
create index idx_support_responses_ticket_id on public.support_responses(ticket_id);
create index idx_support_responses_author_id on public.support_responses(author_id);
create index idx_support_feedback_ticket_id on public.support_feedback(ticket_id);

-- Triggers for updated_at
create trigger trigger_support_categories_updated_at
before update on public.support_categories
for each row execute function public.update_updated_at();

create trigger trigger_support_tickets_updated_at
before update on public.support_tickets
for each row execute function public.update_updated_at();

create trigger trigger_support_responses_updated_at
before update on public.support_responses
for each row execute function public.update_updated_at();

-- Function to generate ticket number
create or replace function generate_ticket_number()
returns trigger as $$
declare
  next_number integer;
begin
  select coalesce(max(substring(ticket_number from '^T([0-9]+)$')::integer), 0) + 1
  into next_number
  from public.support_tickets;
  new.ticket_number := 'T' || lpad(next_number::text, 6, '0');
  return new;
end;
$$ language plpgsql;

create trigger trigger_support_tickets_number
before insert on public.support_tickets
for each row execute function generate_ticket_number();

-- RLS
alter table public.support_categories enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_responses enable row level security;
alter table public.support_feedback enable row level security;

-- Categories: everyone can view
create policy "Everyone can view support categories" on public.support_categories
  for select using (true);

-- Tickets: patients view own, staff view all
create policy "Patients view own tickets" on public.support_tickets
  for select using (auth.uid() = patient_id);

create policy "Staff view all tickets" on public.support_tickets
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

create policy "Patients create tickets" on public.support_tickets
  for insert with check (auth.uid() = patient_id);

-- Responses: patients view own ticket responses, staff view all
create policy "Patients view own responses" on public.support_responses
  for select using (
    exists (
      select 1 from public.support_tickets
      where id = ticket_id and patient_id = auth.uid()
    )
  );

create policy "Staff manage responses" on public.support_responses
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

create policy "Patients add responses to own tickets" on public.support_responses
  for insert with check (
    exists (
      select 1 from public.support_tickets
      where id = ticket_id and patient_id = auth.uid()
    )
  );

-- Feedback: patients submit for their tickets
create policy "Patients manage own feedback" on public.support_feedback
  for all using (auth.uid() = patient_id);

-- Seed categories
insert into public.support_categories (id, name, code, description, icon, is_active)
values
  -- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C85 :
  -- `\'` est un échappement non standard (convention MySQL). Postgres 16 /
  -- Supabase ayant `standard_conforming_strings` activé par défaut, `\'` ne
  -- ferme pas la chaîne de caractères comme prévu et provoque une erreur de
  -- syntaxe bloquante pour `supabase db push`. Corrigé en doublant le
  -- guillemet simple (`''`), convention standard SQL. Confirmé par
  -- exécution réelle contre un Postgres 16 local.
  (gen_random_uuid(), 'Technique / App', 'TECH', 'Problèmes techniques avec l''application', 'build', true),
  (gen_random_uuid(), 'Facturation', 'BILL', 'Questions sur la facturation et les paiements', 'receipt_long', true),
  (gen_random_uuid(), 'Médicaments', 'DRUG', 'Questions sur les médicaments et ordonnances', 'medication', true),
  (gen_random_uuid(), 'Livraison', 'DELIV', 'Problèmes de livraison', 'local_shipping', true),
  (gen_random_uuid(), 'Compte utilisateur', 'ACCT', 'Problèmes de connexion ou de compte', 'person', true),
  (gen_random_uuid(), 'Autre', 'OTHER', 'Autres demandes', 'help_outline', true)
on conflict (code) do nothing;
