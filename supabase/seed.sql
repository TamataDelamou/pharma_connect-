-- Données de départ (démo) pour le projet Supabase réel qemizapoldevapmygryp.
-- Portée volontairement limitée aux tables référentielles/catalogue, à lecture
-- ouverte à tout utilisateur authentifié (catalog, pharmacies, stock) : elles
-- ne dépendent d'aucun compte auth.users réel. Les tables à portée personnelle
-- (profiles, wallets, prescriptions, reservations, transactions, alerts,
-- deliveries...) ne sont pas semées ici — leurs politiques RLS les limitent à
-- auth.uid(), donc des lignes fictives sans utilisateur authentifié réel
-- seraient invisibles depuis l'app et n'auraient aucune valeur de démo.
-- Idempotent : ré-exécutable sans dupliquer (ON CONFLICT / garde sur table
-- vide selon les tables, voir plus bas).

-- ==================== CATALOGUE ====================

insert into public.categories (id, name, icon) values
  ('11111111-1111-1111-1111-111111110001', 'Antalgiques & Antipyrétiques', '💊'),
  ('11111111-1111-1111-1111-111111110002', 'Antibiotiques', '🧫'),
  ('11111111-1111-1111-1111-111111110003', 'Antipaludéens', '🦟'),
  ('11111111-1111-1111-1111-111111110004', 'Cardiovasculaire', '❤️'),
  ('11111111-1111-1111-1111-111111110005', 'Vitamines & Compléments', '🌿'),
  ('11111111-1111-1111-1111-111111110006', 'Dispositifs médicaux', '🩹')
on conflict (id) do nothing;

insert into public.manufacturers (id, name) values
  ('22222222-2222-2222-2222-222222220001', 'Sanofi'),
  ('22222222-2222-2222-2222-222222220002', 'GSK'),
  ('22222222-2222-2222-2222-222222220003', 'Cipla'),
  ('22222222-2222-2222-2222-222222220004', 'Pharmaguinée'),
  ('22222222-2222-2222-2222-222222220005', 'Laborex Guinée')
on conflict (id) do nothing;

insert into public.products (id, name, generic_name, dosage, form, category_id, manufacturer_id, is_generic, is_prescription_required, description) values
  ('33333333-3333-3333-3333-333333330001', 'Paracétamol', 'Paracétamol', '500mg', 'Comprimé', '11111111-1111-1111-1111-111111110001', '22222222-2222-2222-2222-222222220004', true, false, 'Antalgique et antipyrétique de première intention.'),
  ('33333333-3333-3333-3333-333333330002', 'Doliprane', 'Paracétamol', '1000mg', 'Comprimé', '11111111-1111-1111-1111-111111110001', '22222222-2222-2222-2222-222222220001', false, false, 'Antalgique et antipyrétique de marque.'),
  ('33333333-3333-3333-3333-333333330003', 'Ibuprofène', 'Ibuprofène', '400mg', 'Comprimé', '11111111-1111-1111-1111-111111110001', '22222222-2222-2222-2222-222222220003', true, false, 'Anti-inflammatoire non stéroïdien.'),
  ('33333333-3333-3333-3333-333333330004', 'Aspirine', 'Acide acétylsalicylique', '500mg', 'Comprimé', '11111111-1111-1111-1111-111111110001', '22222222-2222-2222-2222-222222220001', true, false, 'Antalgique, antipyrétique et anti-inflammatoire.'),
  ('33333333-3333-3333-3333-333333330005', 'Amoxicilline', 'Amoxicilline', '500mg', 'Gélule', '11111111-1111-1111-1111-111111110002', '22222222-2222-2222-2222-222222220003', true, true, 'Antibiotique à large spectre de la famille des pénicillines.'),
  ('33333333-3333-3333-3333-333333330006', 'Augmentin', 'Amoxicilline/Acide clavulanique', '1g', 'Comprimé', '11111111-1111-1111-1111-111111110002', '22222222-2222-2222-2222-222222220002', false, true, 'Antibiotique associé à un inhibiteur de bêta-lactamase.'),
  ('33333333-3333-3333-3333-333333330007', 'Ciprofloxacine', 'Ciprofloxacine', '500mg', 'Comprimé', '11111111-1111-1111-1111-111111110002', '22222222-2222-2222-2222-222222220003', true, true, 'Antibiotique de la famille des fluoroquinolones.'),
  ('33333333-3333-3333-3333-333333330008', 'Métronidazole', 'Métronidazole', '500mg', 'Comprimé', '11111111-1111-1111-1111-111111110002', '22222222-2222-2222-2222-222222220004', true, true, 'Antibiotique et antiparasitaire.'),
  ('33333333-3333-3333-3333-333333330009', 'Coartem', 'Artéméther/Luméfantrine', '20/120mg', 'Comprimé', '11111111-1111-1111-1111-111111110003', '22222222-2222-2222-2222-222222220003', false, true, 'Traitement de première ligne du paludisme non compliqué.'),
  ('33333333-3333-3333-3333-333333330010', 'Artésunate-Amodiaquine', 'Artésunate/Amodiaquine', '100/270mg', 'Comprimé', '11111111-1111-1111-1111-111111110003', '22222222-2222-2222-2222-222222220004', true, true, 'Combinaison thérapeutique à base d''artémisinine.'),
  ('33333333-3333-3333-3333-333333330011', 'Quinine', 'Quinine', '300mg', 'Comprimé', '11111111-1111-1111-1111-111111110003', '22222222-2222-2222-2222-222222220001', true, true, 'Traitement du paludisme grave et de deuxième ligne.'),
  ('33333333-3333-3333-3333-333333330012', 'Amlodipine', 'Amlodipine', '5mg', 'Comprimé', '11111111-1111-1111-1111-111111110004', '22222222-2222-2222-2222-222222220003', true, true, 'Inhibiteur calcique antihypertenseur.'),
  ('33333333-3333-3333-3333-333333330013', 'Lisinopril', 'Lisinopril', '10mg', 'Comprimé', '11111111-1111-1111-1111-111111110004', '22222222-2222-2222-2222-222222220002', true, true, 'Inhibiteur de l''enzyme de conversion antihypertenseur.'),
  ('33333333-3333-3333-3333-333333330014', 'Atorvastatine', 'Atorvastatine', '20mg', 'Comprimé', '11111111-1111-1111-1111-111111110004', '22222222-2222-2222-2222-222222220003', true, true, 'Hypolipémiant de la famille des statines.'),
  ('33333333-3333-3333-3333-333333330015', 'Vitamine C', 'Acide ascorbique', '1000mg', 'Comprimé effervescent', '11111111-1111-1111-1111-111111110005', '22222222-2222-2222-2222-222222220001', false, false, 'Complément vitaminique.'),
  ('33333333-3333-3333-3333-333333330016', 'Complexe B', 'Vitamines B1/B6/B12', 'standard', 'Comprimé', '11111111-1111-1111-1111-111111110005', '22222222-2222-2222-2222-222222220004', true, false, 'Complexe de vitamines B.'),
  ('33333333-3333-3333-3333-333333330017', 'Fer + Acide folique', 'Sulfate ferreux/Acide folique', 'standard', 'Comprimé', '11111111-1111-1111-1111-111111110005', '22222222-2222-2222-2222-222222220005', true, false, 'Supplémentation martiale, notamment prénatale.'),
  ('33333333-3333-3333-3333-333333330018', 'Thermomètre digital', 'n/a', 'unité', 'Dispositif', '11111111-1111-1111-1111-111111110006', '22222222-2222-2222-2222-222222220005', false, false, 'Thermomètre médical électronique.'),
  ('33333333-3333-3333-3333-333333330019', 'Tensiomètre électronique', 'n/a', 'unité', 'Dispositif', '11111111-1111-1111-1111-111111110006', '22222222-2222-2222-2222-222222220005', false, false, 'Tensiomètre automatique brassard bras.'),
  ('33333333-3333-3333-3333-333333330020', 'Masques chirurgicaux', 'n/a', 'boîte de 50', 'Dispositif', '11111111-1111-1111-1111-111111110006', '22222222-2222-2222-2222-222222220005', false, false, 'Masques chirurgicaux à usage unique.')
on conflict (id) do nothing;

-- ==================== OFFICINES ====================

insert into public.pharmacy_groups (id, name, code) values
  ('44444444-4444-4444-4444-444444440001', 'Groupe Pharma Conakry', 'GPC')
on conflict (id) do nothing;

insert into public.pharmacies (id, name, address, phone, email, license_number, status, license_expiry_date, license_verified_at, manager_name, group_id, latitude, longitude, is_active) values
  ('55555555-5555-5555-5555-555555550001', 'Pharmacie Kaloum Centrale', 'Avenue de la République, Kaloum, Conakry', '+224620111111', 'contact@pharmacie-kaloum.gn', 'DNPM-GN-2024-0142', 'active', now() + interval '18 months', now() - interval '6 months', 'Dr. Fatoumata Camara', '44444444-4444-4444-4444-444444440001', 9.5092, -13.7122, true),
  ('55555555-5555-5555-5555-555555550002', 'Pharmacie de Dixinn', 'Route de Donka, Dixinn, Conakry', '+224620222222', 'contact@pharmacie-dixinn.gn', 'DNPM-GN-2024-0187', 'active', now() + interval '12 months', now() - interval '4 months', 'Dr. Mamadou Diallo', '44444444-4444-4444-4444-444444440001', 9.5354, -13.6802, true),
  ('55555555-5555-5555-5555-555555550003', 'Pharmacie Ratoma Nouvelle', 'Carrefour Kobaya, Ratoma, Conakry', '+224621333333', 'contact@pharmacie-ratoma.gn', 'DNPM-GN-2023-0098', 'active', now() + interval '9 months', now() - interval '10 months', 'Dr. Aïssatou Bah', null, 9.6021, -13.6234, true),
  ('55555555-5555-5555-5555-555555550004', 'Pharmacie Matoto Solidarité', 'Marché de Matoto, Matoto, Conakry', '+224621444444', 'contact@pharmacie-matoto.gn', 'DNPM-GN-2023-0156', 'active', now() + interval '15 months', now() - interval '8 months', 'Dr. Ibrahima Sow', null, 9.5623, -13.6112, true),
  ('55555555-5555-5555-5555-555555550005', 'Pharmacie Kipé Santé', 'Route de Kipé, Kipé, Conakry', '+224622555555', 'contact@pharmacie-kipe.gn', 'DNPM-GN-2025-0021', 'pending', null, null, 'Dr. Mariama Barry', null, 9.5789, -13.6501, true),
  ('55555555-5555-5555-5555-555555550006', 'Pharmacie Matam Providence', 'Avenue Tombo, Matam, Conakry', '+224622666666', 'contact@pharmacie-matam.gn', 'DNPM-GN-2024-0203', 'active', now() + interval '20 months', now() - interval '2 months', 'Dr. Ousmane Keita', null, 9.5201, -13.6534, true)
on conflict (id) do nothing;

-- ==================== STOCK ====================
-- Toutes les officines portent l'ensemble du catalogue (produit croisé
-- pharmacie), avec une quantité pseudo-aléatoire par ligne pour obtenir un
-- mélange réaliste (rupture, stock bas, stock normal). Garde sur table vide
-- plutôt que ON CONFLICT : les id sont générés côté serveur, pas de clé
-- naturelle simple à opposer à un doublon (voir unique (pharmacy_id, product_id)
-- du schéma, qui empêcherait de toute façon un second passage complet).

insert into public.stock_items (pharmacy_id, product_id, total_quantity, reserved_quantity, unit_price, status)
select
  ph.id,
  pr.id,
  q.qty,
  -- C243 : aucune quantité réservée dans le jeu de données. Elle n'est écrite
  -- que par les fonctions de réservation ; le jeu ne crée aucune réservation.
  0,
  price.base_price,
  case
    when q.qty = 0 then 'outOfStock'
    when q.qty <= 5 then 'critical'
    when q.qty <= 20 then 'lowStock'
    else 'inStock'
  end
from public.pharmacies ph
cross join public.products pr
join (values
  ('33333333-3333-3333-3333-333333330001'::uuid, 1500),
  ('33333333-3333-3333-3333-333333330002'::uuid, 3500),
  ('33333333-3333-3333-3333-333333330003'::uuid, 2000),
  ('33333333-3333-3333-3333-333333330004'::uuid, 1200),
  ('33333333-3333-3333-3333-333333330005'::uuid, 4500),
  ('33333333-3333-3333-3333-333333330006'::uuid, 12000),
  ('33333333-3333-3333-3333-333333330007'::uuid, 6000),
  ('33333333-3333-3333-3333-333333330008'::uuid, 3000),
  ('33333333-3333-3333-3333-333333330009'::uuid, 15000),
  ('33333333-3333-3333-3333-333333330010'::uuid, 8000),
  ('33333333-3333-3333-3333-333333330011'::uuid, 5000),
  ('33333333-3333-3333-3333-333333330012'::uuid, 4000),
  ('33333333-3333-3333-3333-333333330013'::uuid, 5500),
  ('33333333-3333-3333-3333-333333330014'::uuid, 7000),
  ('33333333-3333-3333-3333-333333330015'::uuid, 4000),
  ('33333333-3333-3333-3333-333333330016'::uuid, 3500),
  ('33333333-3333-3333-3333-333333330017'::uuid, 2500),
  ('33333333-3333-3333-3333-333333330018'::uuid, 25000),
  ('33333333-3333-3333-3333-333333330019'::uuid, 150000),
  ('33333333-3333-3333-3333-333333330020'::uuid, 20000)
) as price(product_id, base_price) on price.product_id = pr.id
-- Corrélées explicitement à ph.id/pr.id (clause where) : une lateral non
-- corrélée est hissée par le planificateur et évaluée une seule fois pour
-- toutes les lignes au lieu d'une fois par ligne — bug constaté au premier
-- chargement (120 lignes avec la même quantité, donc toutes en 'inStock').
cross join lateral (select floor(random() * 161)::int as qty where ph.id is not null and pr.id is not null) q
where not exists (select 1 from public.stock_items limit 1);

insert into public.stock_batches (stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, purchase_price, received_at, supplier_name)
select
  si.id,
  'LOT-' || to_char(now(), 'YYYY') || '-' || lpad((row_number() over ())::text, 4, '0'),
  (now() - (floor(random() * 365) + 30) * interval '1 day')::date,
  (now() + (floor(random() * 700) + 15) * interval '1 day')::date,
  si.total_quantity,
  0,
  floor(si.unit_price * 0.65)::int,
  now() - (floor(random() * 60) * interval '1 day'),
  (array['Laborex Guinée', 'Ubipharm Guinée', 'Sodipharm', 'Cofguipharm'])[floor(random() * 4 + 1)::int]
from public.stock_items si
where not exists (select 1 from public.stock_batches limit 1);
