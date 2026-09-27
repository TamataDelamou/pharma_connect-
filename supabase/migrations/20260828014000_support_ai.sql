-- AI Support: Knowledge base for chatbot
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87 (même nature —
-- bloquant pour `supabase db push` — corrigé dans le même mouvement) :
-- `embeddings vector(384)` ci-dessous utilise le type `vector` (extension
-- pgvector) sans jamais l'avoir activé via `create extension` — ni dans ce
-- fichier, ni dans aucun autre fichier du projet (seul consommateur du
-- type `vector` sur l'ensemble des ~90 migrations). Confirmé bloquant par
-- exécution réelle (`ERROR: type "vector" does not exist`). Contrairement
-- à `pgcrypto` (activée dès `20260827000100_extensions_and_helpers.sql`),
-- `pgvector` n'est disponible sur un projet Supabase qu'après activation
-- explicite — jamais automatique, même quand l'extension est au catalogue.
create extension if not exists vector with schema extensions;

create table support_knowledge_articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  category text,
  keywords text[],
  embeddings extensions.vector(384), -- for semantic search (C181 : type qualifie, extensions n'est pas dans le search_path du db push distant)
  is_active boolean default true,
  view_count integer default 0,
  helpful_count integer default 0,
  not_helpful_count integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Support bot conversations
create table bot_conversations (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  messages jsonb default '[]'::jsonb,
  status text default 'active' check (status in ('active', 'escalated', 'resolved', 'abandoned')),
  escalation_reason text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);

-- Bot conversation feedback
create table bot_feedback (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.bot_conversations(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  issue_resolved boolean,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- Intent recognition patterns (fallback when no embeddings)
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défauts
-- supplémentaires découverts lors de la vérification C82-C87, corrigés
-- dans le même mouvement (même nature bloquante) : `intent` ne portait
-- aucune contrainte unique alors que le seed plus bas utilise
-- `on conflict (intent) do nothing` (confirmé bloquant par exécution
-- réelle, même défaut que C87) — `unique` ajoutée ci-dessous.
create table bot_intents (
  id uuid primary key default gen_random_uuid(),
  intent text not null unique,
  patterns text[] not null,
  response text not null,
  is_active boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);

-- RLS
alter table support_knowledge_articles enable row level security;
alter table bot_conversations enable row level security;
alter table bot_feedback enable row level security;
alter table bot_intents enable row level security;

-- Everyone can view knowledge articles
create policy "Everyone view knowledge articles" on support_knowledge_articles
  for select using (is_active = true);

-- Staff manage articles
create policy "Staff manage knowledge articles" on support_knowledge_articles
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

-- Patients manage own conversations
create policy "Patients manage own conversations" on bot_conversations
  for all using (auth.uid() = patient_id);

-- Staff view all conversations
create policy "Staff view all conversations" on bot_conversations
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

-- Feedback: patients create own
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), défaut
-- supplémentaire découvert lors de la vérification C82-C87, même nature
-- bloquante : `bot_feedback` n'a pas de colonne `patient_id` (seulement
-- `conversation_id`, voir la définition de la table plus haut) —
-- confirmé bloquant par exécution réelle
-- (`ERROR: column "patient_id" does not exist`). Corrigé en vérifiant la
-- propriété via la conversation parente, sur le même principe que
-- « Items visible with parent » ailleurs dans le projet.
create policy "Patients create feedback" on bot_feedback
  for insert with check (
    exists (
      select 1 from public.bot_conversations
      where id = conversation_id and patient_id = auth.uid()
    )
  );

-- Staff view feedback
create policy "Staff view feedback" on bot_feedback
  for select using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

-- Intents: everyone view, staff manage
create policy "Everyone view intents" on bot_intents
  for select using (is_active = true);

create policy "Staff manage intents" on bot_intents
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'staff', 'support')
    )
  );

-- Seed default intents
--
-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C85
-- (même bug, occurrences supplémentaires) : `\'` (échappement MySQL non
-- standard) corrigé en `''` (standard SQL) sur les 4 occurrences
-- ci-dessous, confirmé bloquant par exécution réelle.
insert into bot_intents (intent, patterns, response)
values
  ('commandes', ARRAY['commande', 'suivi', 'livraison', 'où est ma commande'],
   'Pour suivre votre commande, allez dans l''onglet "Mes commandes" ou cliquez sur le lien de suivi reçu par email/SMS.'),
  ('medicaments', ARRAY['médicament', 'prix', 'disponibilité', 'stock'],
   'Vous pouvez rechercher un médicament dans l''onglet "Recherche" de l''application. Les prix et disponibilités sont mis à jour en temps réel.'),
  ('compte', ARRAY['compte', 'mot de passe', 'connexion', 'inscription', 'oublié'],
   'Pour gérer votre compte, allez dans "Paramètres" puis "Mon compte". Vous pouvez y modifier vos informations, changer votre mot de passe ou gérer vos préférences.'),
  ('facturation', ARRAY['facture', 'paiement', 'remboursement', 'assurance'],
   'Toutes vos factures et informations de paiement sont disponibles dans l''onglet "Paiements". Vous y trouverez également le suivi de vos remboursements.'),
  ('ordonnance', ARRAY['ordonnance', 'prescription', 'renouvellement'],
   'Pour gérer vos ordonnances, allez dans "Ordonnances" dans le menu principal. Vous pouvez y voir vos prescriptions actives et en demander le renouvellement.')
on conflict (intent) do nothing;
