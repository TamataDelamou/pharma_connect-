-- Professional reviews with verification
--
-- Audit Module 19 (INF, 30/08/2026) : ce fichier entrait en collision directe
-- avec `20260827005500_professionals.sql`, qui crée DÉJÀ `public.professional_reviews`
-- (schéma plus simple : rating/review_text/is_anonymous) — un `create table`
-- sans `if not exists` sur un nom de table déjà pris par une migration
-- antérieure (même journée, 3 créneaux horaires plus tôt) provoque une erreur
-- Postgres bloquante (« relation already exists »), qui aurait interrompu
-- l'application de TOUTES les migrations suivantes sur une base neuve —
-- `supabase db push` n'a jamais pu être exécuté au cours de cet audit
-- (limite documentée depuis le Module 0, item A1), ce qui explique que cette
-- collision soit restée indétectée jusqu'à l'ouverture du Module 19,
-- propriétaire de la table d'origine. Trois collisions au total ont été
-- trouvées et corrigées ci-dessous : la table elle-même, 2 index de même nom
-- (`idx_professional_reviews_professional_id`, `idx_professional_reviews_rating`)
-- et 1 trigger de même nom (`trigger_professional_reviews_updated_at`).
-- Convertie en `alter table` pour enrichir la table existante plutôt que la
-- recréer — le schéma enrichi ici (modération, votes utiles, statistiques)
-- est clairement celui destiné à être réellement utilisé (aucun code Dart
-- ne consomme ni l'un ni l'autre schéma à ce jour, voir le registre D32),
-- et ses policies RLS (lecture limitée aux avis approuvés, modération)
-- remplacent celles, plus permissives et sans modération, de la migration
-- d'origine plutôt que de coexister avec elles en OR logique (ce qui aurait
-- rendu la modération inopérante : une policy SELECT `using (true)` autorise
-- la lecture même si une autre policy SELECT la restreint).

alter table public.professional_reviews
  add column if not exists consultation_id uuid references public.consultations(id) on delete set null,
  add column if not exists is_verified boolean default false,
  add column if not exists helpful_count integer default 0,
  add column if not exists not_helpful_count integer default 0,
  add column if not exists status text default 'pending' check (status in ('pending', 'approved', 'rejected', 'flagged')),
  add column if not exists moderation_notes text;

-- La contrainte unique d'origine (professional_id, patient_id) empêcherait
-- un même patient de laisser un second avis après une seconde consultation
-- avec le même professionnel — élargie pour inclure consultation_id.
--
-- Audit Module 19, 1er refus de clôture (30/08/2026) : la première version de
-- ce correctif supprimait la contrainte d'origine par un nom supposé
-- (`professional_reviews_professional_id_patient_id_key`, la convention de
-- nommage automatique standard de Postgres pour un `unique(...)` déclaré
-- inline dans un `create table` sans nom explicite). Remplacé par une
-- recherche dynamique dans `pg_constraint` plutôt qu'un nom deviné : si la
-- convention de nommage avait différé pour une raison quelconque, `drop
-- constraint if exists <nom supposé>` aurait échoué SILENCIEUSEMENT (aucune
-- erreur, `if exists` l'absorbe), laissant l'ancienne contrainte à 2
-- colonnes active EN PLUS de la nouvelle à 3 colonnes — un objet orphelin
-- qui aurait empêché tout second avis après une seconde consultation
-- (l'ancienne contrainte plus stricte continuant à s'appliquer), rendant cet
-- élargissement inopérant sans jamais lever d'erreur visible.
--
-- Vérifié par exécution réelle contre un Postgres 16 local (30/08/2026,
-- premier test de ce type sur l'ensemble de l'audit, cf. registre A28) :
-- cette exécution a elle-même révélé un second bug, cette fois dans le
-- correctif : `array_agg(attname order by attname)` produit un tableau de
-- type `name[]` (type interne des colonnes système Postgres), qui ne
-- dispose d'aucun opérateur d'égalité avec `text[]` — la comparaison
-- levait `ERREUR: operator does not exist: name[] = text[]`, empêchant ce
-- fichier de s'appliquer. Corrigé par un cast explicite
-- (`a.attname::text`) avant agrégation, revérifié avec succès ensuite.
do $$
declare
  v_constraint_name text;
begin
  -- Une contrainte UNIQUE (pas de clé étrangère, pas de clé primaire) sur
  -- EXACTEMENT (professional_id, patient_id), quel que soit son nom réel.
  select con.conname into v_constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  where nsp.nspname = 'public'
    and rel.relname = 'professional_reviews'
    and con.contype = 'u'
    and (
      select array_agg(a.attname::text order by a.attname)
      from unnest(con.conkey) as k(attnum)
      join pg_attribute a on a.attrelid = con.conrelid and a.attnum = k.attnum
    ) = array['patient_id', 'professional_id']::text[];

  if v_constraint_name is not null then
    execute format('alter table public.professional_reviews drop constraint %I', v_constraint_name);
  end if;
end $$;

alter table public.professional_reviews
  add constraint professional_reviews_professional_patient_consultation_key
  unique (professional_id, patient_id, consultation_id);

-- Review helpful votes
create table if not exists public.review_helpful_votes (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.professional_reviews(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  is_helpful boolean not null,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text,
  unique(review_id, patient_id)
);

-- Professional statistics (materialized view)
create materialized view if not exists professional_stats as
select
  p.id as professional_id,
  count(distinct r.id) filter (where r.status = 'approved') as total_reviews,
  coalesce(avg(r.rating) filter (where r.status = 'approved'), 0) as avg_rating,
  count(distinct r2.id) as total_consultations,
  count(distinct r3.patient_id) as total_patients
from profiles p
left join professional_reviews r on r.professional_id = p.id
left join consultations r2 on r2.professional_id = p.id and r2.status = 'completed'
left join consultations r3 on r3.professional_id = p.id and r3.patient_id is not null and r3.status = 'completed'
where p.role in ('professionnel', 'pharmacien')
group by p.id;

-- Indexes (idx_professional_reviews_professional_id et idx_professional_reviews_rating
-- existent déjà depuis 20260827005500_professionals.sql — non recréés ici)
create index if not exists idx_professional_reviews_patient_id on public.review_helpful_votes(patient_id);
create index if not exists idx_professional_reviews_status on public.professional_reviews(status);
create index if not exists idx_review_helpful_votes_review_id on public.review_helpful_votes(review_id);

-- Trigger for updated_at (déjà créé par 20260827005500_professionals.sql
-- sur cette même table — non recréé ici pour éviter une seconde collision
-- de nom).

-- RLS
alter table public.review_helpful_votes enable row level security;

-- Les policies de 20260827005500_professionals.sql ("Everyone can view
-- reviews" / "Patients can create reviews" / "Patients can update own
-- reviews") sont remplacées ici par un jeu cohérent avec la modération —
-- les conserver en parallèle rendrait la modération inopérante (policies
-- RLS permissives combinées en OR).
drop policy if exists "Everyone can view reviews" on public.professional_reviews;
drop policy if exists "Patients can create reviews" on public.professional_reviews;
drop policy if exists "Patients can update own reviews" on public.professional_reviews;

-- Everyone can view approved reviews
create policy "Everyone view approved reviews" on public.professional_reviews
  for select using (status = 'approved');

-- Patients can create reviews
create policy "Patients create reviews" on public.professional_reviews
  for insert with check (auth.uid() = patient_id);

-- Patients can update own reviews
create policy "Patients update own reviews" on public.professional_reviews
  for update using (auth.uid() = patient_id);

-- Patients can delete own reviews
create policy "Patients delete own reviews" on public.professional_reviews
  for delete using (auth.uid() = patient_id);

-- Staff moderate reviews
--
-- Audit Module 19 (30/08/2026) : `role in ('admin', 'staff')` sur
-- `public.profiles` est inatteignable par construction (même motif que
-- C49/C54/C63/C67/C70b/C78 — la contrainte CHECK de `profiles.role`
-- n'autorise jamais ces valeurs). Remplacée par un test direct sur
-- `public.admin_users`, PAS par l'appel à `public.is_gsg_admin()` : cette
-- fonction n'est créée que par `20260829003800_admin_helpers.sql`, daté
-- après ce fichier (`20260828020000`) — l'appeler ici provoquerait une
-- erreur « function does not exist » à l'application de CETTE migration,
-- avant même d'atteindre celle qui la définit. Ordre chronologique des
-- migrations respecté ; voir `is_gsg_admin()` pour le texte identique une
-- fois cette fonction disponible.
create policy "Staff moderate reviews" on public.professional_reviews
  for all using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  )
  with check (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid() and is_active = true
    )
  );

-- Helpful votes: patients manage
create policy "Patients manage helpful votes" on public.review_helpful_votes
  for all using (auth.uid() = patient_id);

-- Function to refresh professional stats
create or replace function refresh_professional_stats()
returns void as $$
begin
  refresh materialized view concurrently professional_stats;
end;
$$ language plpgsql;
