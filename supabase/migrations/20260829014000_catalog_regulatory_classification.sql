-- Module catalog (Module 3 — CAT, audit 29/08/2026).
--
-- RG-CAT-02 : « un produit stupéfiant/psychotrope n'est pas affichable en
-- disponibilité publique sans ordonnance ». Le module Prescriptions/ORD
-- (Module 5 du plan) n'a pas encore été audité et ne fournit aujourd'hui
-- aucun mécanisme vérifiable de « ordonnance valide pour ce produit » — en
-- attendant cette intégration, la règle est appliquée de façon conservative
-- au niveau RLS : un produit classé stupéfiant/psychotrope n'est visible
-- que du personnel opérationnel (tout rôle non-patient) et du back-office
-- GSG. Un patient ne le voit ni au catalogue ni en recherche de
-- disponibilité — search_service.dart et catalog_service.dart lisent tous
-- deux `products` sans filtre applicatif dédié : appliquer la règle en RLS
-- la propage automatiquement aux deux, sans toucher au code déjà audité et
-- clos du module REC (Module 2).
--
-- RG-CAT-03 (propagation automatique des changements de statut
-- réglementaire) : satisfaite par construction — `regulatory_class` vit
-- uniquement sur `public.products`, jamais dupliqué ailleurs (stock_items,
-- search...), donc toute mise à jour de ce champ se répercute
-- immédiatement partout où le produit est lu, sans étape de propagation
-- supplémentaire à écrire.

alter table public.products
  add column if not exists regulatory_class text not null default 'libre'
    check (regulatory_class in ('libre', 'sur_ordonnance', 'stupefiant', 'psychotrope'));

comment on column public.products.regulatory_class is
  'Classification réglementaire du produit (RG-CAT-02). "libre"/"sur_ordonnance" restent visibles publiquement (is_prescription_required porte déjà la distinction d''affichage) ; "stupefiant"/"psychotrope" sont retirés de la visibilité patient par la policy products_select_scoped ci-dessous, faute de mécanisme de vérification d''ordonnance opérationnel (dépend du Module 5 — ORD).';

-- Référentiel produit : ajout d'un identifiant code-barres/GTIN, absent
-- jusqu'ici (search_service.dart:searchByBarcode utilisait une heuristique
-- de comparaison d'ID, documentée comme un pis-aller dans l'audit Module 2).
alter table public.products
  add column if not exists barcode text unique;

comment on column public.products.barcode is
  'Code-barres / GTIN du produit. Ajouté au référentiel (Module 3 — CAT) ; search_service.dart (Module 2 — REC, déjà clos) devra migrer sa recherche par code-barres vers ce champ lors d''une prochaine passe sur ce module — non modifié ici pour respecter la clôture déjà validée de REC (voir registre des écarts, item B3).';

drop policy if exists "products_select_authenticated" on public.products;

create policy "products_select_scoped" on public.products
  for select to authenticated
  using (
    regulatory_class not in ('stupefiant', 'psychotrope')
    or public.is_gsg_admin()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role <> 'patient'
    )
  );

comment on policy "products_select_scoped" on public.products is
  'RG-CAT-02 : un produit stupéfiant/psychotrope est masqué pour le rôle patient (aucune vérification d''ordonnance disponible aujourd''hui) ; tout autre rôle authentifié (pharmacien, grossiste, livreur, professionnel, régulateur) et le back-office GSG conservent une visibilité complète du référentiel.';
