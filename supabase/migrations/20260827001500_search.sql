-- Module search (lib/modules/search). Les résultats de recherche
-- (SearchResult, AvailabilityResult, SearchSuggestion) sont calculés à la
-- volée à partir de public.products/public.stock_items/public.pharmacies —
-- aucune table dédiée pour eux. Seul l'historique de recherche est une
-- donnée réellement persistée (aujourd'hui une liste en mémoire côté
-- SearchService.getSearchHistory/addToHistory, sans notion d'utilisateur :
-- cette table lui donne un support réel, le câblage du service Dart sur
-- Supabase reste un chantier séparé de cette migration).

create table if not exists public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  query text not null,
  searched_at timestamptz not null default now()
);

comment on table public.search_history is 'Historique de recherche par utilisateur (search/services/search_service.dart : _searchHistory, actuellement en mémoire).';

create index if not exists idx_search_history_user_id on public.search_history(user_id, searched_at desc);

alter table public.search_history enable row level security;

create policy "search_history_select_own" on public.search_history
  for select to authenticated
  using (auth.uid() = user_id);

create policy "search_history_insert_own" on public.search_history
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "search_history_delete_own" on public.search_history
  for delete to authenticated
  using (auth.uid() = user_id);
