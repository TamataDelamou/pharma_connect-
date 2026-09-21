-- Première migration du projet PharmaConnect. Établit les extensions et
-- fonctions utilitaires partagées par toutes les migrations suivantes.
--
-- Conventions appliquées à l'ensemble du schéma (voir CLAUDE.md / KER-*) :
--   - Clé primaire locale `id uuid default gen_random_uuid()` sur chaque
--     table créée par ce produit (KER-VIS-01) — jamais la clé d'un système
--     externe.
--   - Aucune contrainte SQL ne référence un schéma hors de ce projet
--     Supabase (public/auth/storage/extensions/graphql_public) — vérifié par
--     scripts/ci/check_no_cross_schema_fk.sh (KER-VIS-03). Le lien vers le
--     Kernel GSG passe uniquement par des colonnes scalaires nullable
--     (`gsg_id`, `gsg_org_id`), jamais par une FK.
--   - Tout montant est stocké en INTEGER, unité mineure de la devise
--     (KER-REF-05). Le GNF n'a pas de sous-unité : son "unité mineure" est
--     l'unité elle-même, mais elle reste un entier, jamais un flottant.
--   - Row Level Security activée sur chaque table. Les données de
--     référentiel/catalogue sont lisibles par tout utilisateur authentifié ;
--     les données personnelles sont limitées à leur propriétaire
--     (`auth.uid()`) ; les données opérationnelles (réservations, stock,
--     paiements, traçabilité...) sont en lecture authentifiée pour cette
--     première migration — les écritures ne passent pour l'instant que par
--     `service_role` (aucun modèle d'autorisation par rôle métier n'est
--     encore conçu côté produit ; l'inventer ici serait une hypothèse, pas
--     une migration). Politiques d'écriture par rôle : chantier séparé,
--     à concevoir avec le produit plutôt qu'à deviner.

create extension if not exists pgcrypto with schema extensions;

-- Maintient `updated_at` à jour automatiquement sur les tables qui exposent
-- cette colonne, plutôt que de compter sur chaque appelant pour la fixer.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Trigger BEFORE UPDATE générique : fixe updated_at = now() sur la ligne modifiée.';

-- Audit Module 19 (INF), 1er refus de clôture (30/08/2026), ticket C82 :
-- `public.update_updated_at()` est appelée par `create trigger ... execute
-- function public.update_updated_at()` dans 18 fichiers de migration
-- distincts (teleconsult, homecare, triage, loyalty, eprescription,
-- gamification x3, professional_reviews, marketplace, financing, business,
-- stock_forecasting, pos, network_admin, cash, returns) mais n'était
-- définie nulle part dans le projet — seule `set_updated_at()` ci-dessus
-- existait, avec un corps identique mais un nom différent, laissant
-- penser à un renommage partiel jamais terminé. Sur une base neuve,
-- `supabase db push` échouait dès la première de ces 18 migrations
-- rencontrée dans l'ordre chronologique (`ERROR: function
-- public.update_updated_at() does not exist`) — y compris sur
-- `20260827005500_professionals.sql`, la migration d'origine du Module 19
-- lui-même. Confirmé bloquant par exécution réelle contre un Postgres 16
-- local (première exécution réelle de ce type sur l'ensemble de l'audit,
-- voir le registre A29). Ajoutée ici, dans la première migration du
-- projet, plutôt que dans une migration corrective plus tardive : les 18
-- fichiers appelants sont chronologiquement répartis sur toute la
-- deuxième moitié du projet, donc seule une définition à ce stade — avant
-- le premier appelant — respecte l'ordre chronologique d'application des
-- migrations, sur le même principe que la contrainte de non-antériorité
-- déjà documentée pour `is_gsg_admin()`. Corps identique à
-- `set_updated_at()` (aucune des deux n'est renommée ni supprimée, pour
-- ne pas modifier le comportement des tables qui utilisent déjà l'une ou
-- l'autre).
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.update_updated_at() is
  'Trigger BEFORE UPDATE générique, identique à set_updated_at() — ajoutée au correctif C82 (audit Module 19, 30/08/2026) car référencée par 18 fichiers de migration sans jamais avoir été définie.';
