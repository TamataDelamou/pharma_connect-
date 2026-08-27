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
