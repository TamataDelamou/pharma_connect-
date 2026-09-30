-- Correctif C205 : caisse reliée aux ventes et aux remboursements
-- (décision D62, 30/09/2026), et sécurisation du module de caisse.
--
-- Constat : ni la vente (pos_create_sale) ni le remboursement
-- (pos_refund_sale) ne créaient de mouvement de caisse : le solde attendu
-- d'une session ignorait tout le comptoir. En examinant le module, d'autres
-- défauts sont apparus, corrigés ici :
--   - open_cash_drawer / close_cash_drawer (20260829009000_cash.sql) étaient
--     SECURITY DEFINER sans search_path ni aucun contrôle, et exécutables par
--     anon : n'importe qui pouvait ouvrir une caisse pour n'importe quelle
--     officine et n'importe quel caissier, ou fermer n'importe quelle session
--     avec le montant de son choix ;
--   - close_cash_drawer calculait le solde attendu en ADDITIONNANT tous les
--     mouvements, retraits et remboursements compris (montants positifs) ;
--   - le personnel pouvait insérer, modifier et SUPPRIMER librement mouvements
--     et sessions (policies « for all ») : l'historique de caisse n'était pas
--     fiable ;
--   - cash_summary était une vue matérialisée jamais rafraîchie, lisible par
--     tout utilisateur (les vues matérialisées n'ont pas de RLS).
--
-- Décision D62 :
--   1. Une vente ou un remboursement EN ESPÈCES exige une session de caisse
--      ouverte de la personne qui encaisse ou rembourse, dans cette officine ;
--      le montant y est enregistré automatiquement.
--   2. Les autres moyens de paiement (mobile money, carte, assurance, crédit)
--      sont enregistrés dans la session si elle est ouverte, tracés à part
--      (colonne payment_method), sans toucher au solde d'espèces attendu.
--   3. Un remboursement se fait dans le moyen de paiement d'origine.
--   Une session appartient à un caissier ; il peut en avoir au plus une
--   ouverte par officine.
--
-- Solde d'espèces attendu = fonds de caisse + ventes en espèces
--   - remboursements en espèces + dépôts - retraits.
--
-- Aucune migration existante modifiée.

-- ============================================================
-- Structure
-- ============================================================

alter table public.cash_movements
  add column payment_method text
    check (payment_method in ('cash', 'mobile_money', 'card', 'insurance', 'credit'));
comment on column public.cash_movements.payment_method is
  'C205 / D62 : moyen de paiement d''une vente ou d''un remboursement enregistré dans la session. Seuls les mouvements en espèces (cash) comptent dans le solde attendu.';

alter table public.pos_sales
  add column cash_drawer_session_id uuid references public.cash_drawer_sessions(id) on delete set null;
comment on column public.pos_sales.cash_drawer_session_id is
  'C205 / D62 : session de caisse du vendeur au moment de la vente (obligatoire pour une vente en espèces).';

-- Au plus une session ouverte par caissier et par officine (index créé
-- seulement si les données existantes le permettent).
do $$
begin
  if not exists (
    select 1 from public.cash_drawer_sessions
    where status = 'open'
    group by pharmacy_id, cashier_id having count(*) > 1
  ) then
    create unique index cash_drawer_sessions_one_open
      on public.cash_drawer_sessions (pharmacy_id, cashier_id)
      where status = 'open';
  else
    raise notice 'C205 : plusieurs sessions ouvertes pour un meme caissier ; index unique non cree, controle assure par open_cash_drawer';
  end if;
end $$;

-- ============================================================
-- Solde attendu
-- ============================================================

create or replace function public.cash_expected_balance(p_session_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select s.opening_balance + coalesce((
    select sum(case
      when m.type = 'sale'       and coalesce(m.payment_method, 'cash') = 'cash' then m.amount
      when m.type = 'refund'     and coalesce(m.payment_method, 'cash') = 'cash' then -m.amount
      when m.type = 'deposit'    then m.amount
      when m.type = 'withdrawal' then -m.amount
      else 0 end)
    from public.cash_movements m
    where m.cash_drawer_session_id = s.id), 0)::integer
  from public.cash_drawer_sessions s
  where s.id = p_session_id;
$$;

comment on function public.cash_expected_balance(uuid) is
  'C205 / D62 : solde d''espèces attendu d''une session = fonds de caisse + ventes en espèces - remboursements en espèces + dépôts - retraits. Les autres moyens de paiement ne comptent pas.';

revoke all on function public.cash_expected_balance(uuid) from public, anon, authenticated;

-- ============================================================
-- Ouverture, mouvements, fermeture
-- ============================================================

-- Même signature qu'en 20260829009000 (appelée par CashService.openSession) ;
-- le caissier est toujours l'utilisateur courant.
create or replace function public.open_cash_drawer(
  p_pharmacy_id uuid,
  p_cashier_id uuid,
  p_opening_balance integer,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id uuid;
begin
  if v_user_id is null or not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'CAISSE: acces refuse a cette officine' using errcode = '42501';
  end if;
  if p_cashier_id is not null and p_cashier_id <> v_user_id then
    raise exception 'CAISSE: on ne peut ouvrir une caisse qu''a son nom' using errcode = '42501';
  end if;
  if p_opening_balance is null or p_opening_balance < 0 then
    raise exception 'CAISSE: fonds de caisse invalide' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('cash_open:' || p_pharmacy_id::text || ':' || v_user_id::text));
  if exists (select 1 from public.cash_drawer_sessions
              where pharmacy_id = p_pharmacy_id and cashier_id = v_user_id and status = 'open') then
    raise exception 'CAISSE: vous avez deja une caisse ouverte dans cette officine' using errcode = '22023';
  end if;

  insert into public.cash_drawer_sessions (
    pharmacy_id, cashier_id, opening_balance, expected_balance, status, notes,
    created_by, updated_by
  ) values (
    p_pharmacy_id, v_user_id, p_opening_balance, p_opening_balance, 'open', p_notes,
    v_user_id, v_user_id
  )
  returning id into v_session_id;

  insert into public.cash_movements (cash_drawer_session_id, type, amount, notes, created_by)
  values (v_session_id, 'opening', p_opening_balance, 'Ouverture de caisse', v_user_id);

  return v_session_id;
end;
$$;

comment on function public.open_cash_drawer(uuid, uuid, integer, text) is
  'C205 : ouvre une session de caisse au nom de l''utilisateur courant (personnel de l''officine), une seule ouverte par caissier et par officine.';

revoke all on function public.open_cash_drawer(uuid, uuid, integer, text) from public, anon;
grant execute on function public.open_cash_drawer(uuid, uuid, integer, text) to authenticated;

-- Dépôt ou retrait manuel (les ventes et remboursements passent par les RPC POS).
create or replace function public.cash_add_movement(
  p_session_id uuid,
  p_type text,
  p_amount integer,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session record;
  v_id uuid;
begin
  select * into v_session from public.cash_drawer_sessions where id = p_session_id for update;
  if not found then
    raise exception 'CAISSE: session introuvable' using errcode = 'P0002';
  end if;
  if v_user_id is null or not public.is_pharmacy_staff(v_session.pharmacy_id)
     or not (v_session.cashier_id = v_user_id or public.is_pharmacy_manager(v_session.pharmacy_id)) then
    raise exception 'CAISSE: reserve au caissier de la session ou au titulaire' using errcode = '42501';
  end if;
  if v_session.status <> 'open' then
    raise exception 'CAISSE: la session n''est pas ouverte' using errcode = '22023';
  end if;
  if p_type is null or p_type not in ('deposit', 'withdrawal') then
    raise exception 'CAISSE: seuls les depots et retraits se saisissent a la main' using errcode = '22023';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'CAISSE: montant invalide' using errcode = '22023';
  end if;
  if p_type = 'withdrawal' and p_amount > public.cash_expected_balance(p_session_id) then
    raise exception 'CAISSE: retrait superieur aux especes attendues en caisse' using errcode = '22023';
  end if;

  insert into public.cash_movements (cash_drawer_session_id, type, amount, notes, created_by)
  values (p_session_id, p_type, p_amount, p_notes, v_user_id)
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.cash_add_movement(uuid, text, integer, text) is
  'C205 : dépôt ou retrait d''espèces dans une session ouverte, par son caissier ou le titulaire. Montant positif ; un retrait ne peut dépasser les espèces attendues.';

revoke all on function public.cash_add_movement(uuid, text, integer, text) from public, anon;
grant execute on function public.cash_add_movement(uuid, text, integer, text) to authenticated;

-- Même signature qu'en 20260829009000 (appelée par CashService.closeSession).
create or replace function public.close_cash_drawer(
  p_session_id uuid,
  p_closing_balance integer,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session record;
  v_expected integer;
begin
  select * into v_session from public.cash_drawer_sessions where id = p_session_id for update;
  if not found then
    raise exception 'CAISSE: session introuvable' using errcode = 'P0002';
  end if;
  if v_user_id is null or not public.is_pharmacy_staff(v_session.pharmacy_id)
     or not (v_session.cashier_id = v_user_id or public.is_pharmacy_manager(v_session.pharmacy_id)) then
    raise exception 'CAISSE: reserve au caissier de la session ou au titulaire' using errcode = '42501';
  end if;
  if v_session.status <> 'open' then
    raise exception 'CAISSE: la session n''est pas ouverte' using errcode = '22023';
  end if;
  if p_closing_balance is null or p_closing_balance < 0 then
    raise exception 'CAISSE: montant compte invalide' using errcode = '22023';
  end if;

  v_expected := public.cash_expected_balance(p_session_id);

  update public.cash_drawer_sessions set
    closing_balance = p_closing_balance,
    expected_balance = v_expected,
    difference = p_closing_balance - v_expected,
    status = 'closed',
    closed_at = now(),
    notes = nullif(concat_ws(E'\n', notes, nullif(btrim(p_notes), '')), ''),
    updated_by = v_user_id
  where id = p_session_id;

  insert into public.cash_movements (cash_drawer_session_id, type, amount, notes, created_by)
  values (p_session_id, 'closing', p_closing_balance,
          'Fermeture de caisse' || coalesce(' - ' || nullif(btrim(p_notes), ''), ''), v_user_id);
end;
$$;

comment on function public.close_cash_drawer(uuid, integer, text) is
  'C205 : ferme une session ouverte (caissier de la session ou titulaire) ; solde attendu recalculé par cash_expected_balance, écart = compté - attendu.';

revoke all on function public.close_cash_drawer(uuid, integer, text) from public, anon;
grant execute on function public.close_cash_drawer(uuid, integer, text) to authenticated;

-- ============================================================
-- Droits : lecture seule pour le personnel, écritures par les fonctions
-- ============================================================

drop policy if exists "Pharmacy staff manage cash sessions" on public.cash_drawer_sessions;
create policy "Pharmacy staff view cash sessions" on public.cash_drawer_sessions
  for select to authenticated
  using (public.is_pharmacy_staff(pharmacy_id));

drop policy if exists "Pharmacy staff manage cash movements" on public.cash_movements;
create policy "Pharmacy staff view cash movements" on public.cash_movements
  for select to authenticated
  using (exists (select 1 from public.cash_drawer_sessions s
                  where s.id = cash_drawer_session_id
                    and public.is_pharmacy_staff(s.pharmacy_id)));

-- ============================================================
-- Résumé de session : vue ordinaire soumise aux droits de l'appelant
-- ============================================================

drop materialized view if exists public.cash_summary;
create view public.cash_summary
with (security_invoker = true)
as
select
  s.pharmacy_id,
  s.id as session_id,
  s.cashier_id,
  s.status,
  s.opened_at,
  s.closed_at,
  s.opening_balance,
  s.closing_balance,
  coalesce(s.expected_balance, 0) as expected_balance,
  s.difference,
  coalesce(sum(m.amount) filter (where m.type = 'sale' and coalesce(m.payment_method, 'cash') = 'cash'), 0)::integer as total_sales,
  coalesce(sum(m.amount) filter (where m.type = 'refund' and coalesce(m.payment_method, 'cash') = 'cash'), 0)::integer as total_refunds,
  coalesce(sum(m.amount) filter (where m.type = 'deposit'), 0)::integer as total_deposits,
  coalesce(sum(m.amount) filter (where m.type = 'withdrawal'), 0)::integer as total_withdrawals,
  coalesce(sum(m.amount) filter (where m.type = 'sale' and m.payment_method <> 'cash'), 0)::integer as total_non_cash_sales,
  coalesce(sum(m.amount) filter (where m.type = 'refund' and m.payment_method <> 'cash'), 0)::integer as total_non_cash_refunds,
  (s.opening_balance
   + coalesce(sum(m.amount) filter (where m.type = 'sale' and coalesce(m.payment_method, 'cash') = 'cash'), 0)
   - coalesce(sum(m.amount) filter (where m.type = 'refund' and coalesce(m.payment_method, 'cash') = 'cash'), 0)
   + coalesce(sum(m.amount) filter (where m.type = 'deposit'), 0)
   - coalesce(sum(m.amount) filter (where m.type = 'withdrawal'), 0))::integer as current_expected_cash
from public.cash_drawer_sessions s
left join public.cash_movements m on m.cash_drawer_session_id = s.id
group by s.id;

comment on view public.cash_summary is
  'C205 / D62 : résumé par session de caisse, calculé à la lecture (plus de vue matérialisée périmée) et soumis aux droits de l''appelant (security_invoker). total_sales / total_refunds : espèces uniquement ; total_non_cash_* : autres moyens ; current_expected_cash : solde d''espèces attendu.';

revoke all on public.cash_summary from anon;
grant select on public.cash_summary to authenticated;

-- ============================================================
-- Vente et remboursement : mouvements de caisse
-- ============================================================

CREATE OR REPLACE FUNCTION public.pos_create_sale(p_pharmacy_id uuid, p_payment_method text, p_total_amount integer, p_discount_amount integer, p_tax_amount integer, p_final_amount integer, p_items jsonb, p_patient_id uuid DEFAULT NULL::uuid, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'Africa/Conakry')::date;
  v_sale_id uuid;
  v_item jsonb;
  v_qty integer;
  v_unit integer;
  v_line integer;
  v_sum integer := 0;
  v_batch_id uuid;
  v_batch_pharmacy uuid;
  v_batch_product uuid;
  v_batch_expiry date;
  v_product_id uuid;
  v_product_name text;
  v_stock_item_id uuid;
  v_stock_price integer;
  v_session_id uuid;
  v_rx_required boolean;
  v_rx_checked boolean;
  v_remaining integer;
  v_take integer;
  v_available integer;
  v_lot record;
begin
  if v_user_id is null or not public.is_pharmacy_staff(p_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'POS: une vente doit contenir au moins une ligne' using errcode = '22023';
  end if;

  if p_total_amount < 0 or p_discount_amount < 0 or p_tax_amount < 0 or p_final_amount < 0 then
    raise exception 'POS: montant negatif' using errcode = '22023';
  end if;

  if p_discount_amount > p_total_amount then
    raise exception 'POS: remise % superieure au total %', p_discount_amount, p_total_amount
      using errcode = '22023';
  end if;

  -- Le client arrondit total, remise et TVA séparément (pos_provider.dart) :
  -- écart d'au plus 1 avec final = total - remise + TVA.
  if abs(p_final_amount - (p_total_amount - p_discount_amount + p_tax_amount)) > 1 then
    raise exception 'POS: montant final % incoherent (attendu % a 1 pres)',
      p_final_amount, p_total_amount - p_discount_amount + p_tax_amount
      using errcode = '22023';
  end if;

  -- Contrôle de cohérence des lignes avant toute écriture.
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty  := (v_item->>'quantity')::integer;
    v_unit := (v_item->>'unit_price')::integer;
    v_line := (v_item->>'total_price')::integer;
    if v_qty is null or v_qty <= 0 or v_unit is null or v_unit < 0
       or v_line is distinct from v_qty * v_unit then
      raise exception 'POS: ligne incoherente (quantite %, prix %, total %)', v_qty, v_unit, v_line
        using errcode = '22023';
    end if;
    -- Remise par ligne non gérée : total_price = quantité × prix unitaire.
    if coalesce((v_item->>'discount_percentage')::numeric, 0) <> 0 then
      raise exception 'POS: remise par ligne non prise en charge' using errcode = '22023';
    end if;
    -- C201 : plus de ligne « catalogue » sans produit ni lot.
    if nullif(v_item->>'product_id', '') is null and nullif(v_item->>'batch_id', '') is null then
      raise exception 'POS: chaque ligne doit designer un produit du stock' using errcode = '22023';
    end if;
    v_sum := v_sum + v_line;
  end loop;

  if v_sum <> p_total_amount then
    raise exception 'POS: total % different de la somme des lignes %', p_total_amount, v_sum
      using errcode = '22023';
  end if;

  -- C205 / D62 : session de caisse ouverte du vendeur dans cette officine ;
  -- obligatoire pour une vente en espèces.
  select id into v_session_id
    from public.cash_drawer_sessions
    where pharmacy_id = p_pharmacy_id and cashier_id = v_user_id and status = 'open'
    order by opened_at desc
    limit 1;
  if p_payment_method = 'cash' and v_session_id is null then
    raise exception 'POS: ouvrez votre caisse avant une vente en especes' using errcode = '22023';
  end if;

  -- Caissier, auteur et statut fixés par le serveur, jamais par le client.
  insert into public.pos_sales (
    pharmacy_id, patient_id, cashier_id, total_amount, discount_amount,
    tax_amount, final_amount, payment_method, status, notes,
    created_by, updated_by, cash_drawer_session_id
  ) values (
    p_pharmacy_id, p_patient_id, v_user_id, p_total_amount, p_discount_amount,
    p_tax_amount, p_final_amount, p_payment_method, 'completed', p_notes,
    v_user_id, v_user_id, v_session_id
  )
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_batch_id   := nullif(v_item->>'batch_id', '')::uuid;
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_qty        := (v_item->>'quantity')::integer;
    v_unit       := (v_item->>'unit_price')::integer;
    v_rx_checked := coalesce((v_item->>'prescription_checked')::boolean, false);

    if v_batch_id is not null then
      -- Lot désigné (comportement C197 / C203).
      select si.pharmacy_id, si.product_id, b.expiry_date, si.unit_price
        into v_batch_pharmacy, v_batch_product, v_batch_expiry, v_stock_price
        from public.stock_batches b
        join public.stock_items si on si.id = b.stock_item_id
        where b.id = v_batch_id;
      if not found then
        raise exception 'POS: lot % introuvable', v_batch_id using errcode = '22023';
      end if;
      if v_batch_pharmacy is distinct from p_pharmacy_id then
        raise exception 'POS: le lot % n''appartient pas a cette officine', v_batch_id
          using errcode = '42501';
      end if;
      if v_product_id is not null and v_product_id <> v_batch_product then
        raise exception 'POS: le lot % ne correspond pas au produit %', v_batch_id, v_product_id
          using errcode = '22023';
      end if;
      if v_batch_expiry < v_today then
        raise exception 'POS: le lot % est perime (%)', v_batch_id, v_batch_expiry
          using errcode = '22023';
      end if;
      v_product_id := v_batch_product;
    end if;

    select p.name,
           p.is_prescription_required or p.regulatory_class in ('stupefiant', 'psychotrope')
      into v_product_name, v_rx_required
      from public.products p where p.id = v_product_id;
    if not found then
      raise exception 'POS: produit % inconnu', v_product_id using errcode = '22023';
    end if;
    v_product_name := coalesce(nullif(v_item->>'product_name', ''), v_product_name);

    if v_batch_id is not null then
      perform public.pos_check_unit_price(v_product_name, v_unit, v_stock_price);
      insert into public.pos_sale_items (
        sale_id, product_id, product_name, quantity, unit_price, total_price,
        batch_id, discount_percentage, notes, prescription_required, prescription_checked
      ) values (
        v_sale_id, v_product_id, v_product_name, v_qty, v_unit, v_qty * v_unit,
        v_batch_id, 0, v_item->>'notes', v_rx_required, v_rx_checked
      );
      perform public.stock_apply_movement(
        v_batch_id, -v_qty, 'sale', v_sale_id::text, 'Vente POS'
      );
      continue;
    end if;

    -- C201 : produit sans lot désigné → allocation FEFO par le serveur.
    select id, unit_price into v_stock_item_id, v_stock_price
      from public.stock_items
      where pharmacy_id = p_pharmacy_id and product_id = v_product_id;
    if not found then
      raise exception 'POS: % absent du stock de cette officine', v_product_name
        using errcode = '22023';
    end if;
    perform public.pos_check_unit_price(v_product_name, v_unit, v_stock_price);

    v_remaining := v_qty;
    for v_lot in
      select b.id, greatest(b.quantity - b.quantity_reserved, 0) as available
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id
          and b.expiry_date >= v_today
          and b.quantity - b.quantity_reserved > 0
        order by b.expiry_date, b.received_at nulls last, b.id
        for update of b
    loop
      exit when v_remaining = 0;
      v_take := least(v_remaining, v_lot.available);
      insert into public.pos_sale_items (
        sale_id, product_id, product_name, quantity, unit_price, total_price,
        batch_id, discount_percentage, notes, prescription_required, prescription_checked
      ) values (
        v_sale_id, v_product_id, v_product_name, v_take, v_unit, v_take * v_unit,
        v_lot.id, 0, v_item->>'notes', v_rx_required, v_rx_checked
      );
      perform public.stock_apply_movement(
        v_lot.id, -v_take, 'sale', v_sale_id::text, 'Vente POS'
      );
      v_remaining := v_remaining - v_take;
    end loop;

    if v_remaining > 0 then
      select coalesce(sum(greatest(b.quantity - b.quantity_reserved, 0)), 0)::integer
        into v_available
        from public.stock_batches b
        where b.stock_item_id = v_stock_item_id and b.expiry_date >= v_today;
      -- Les lots déjà décrémentés pour cette ligne sont comptés après sortie :
      -- on rapporte ce qui était vendable avant la ligne.
      raise exception 'POS: stock insuffisant pour % (demande %, disponible %)',
        v_product_name, v_qty, v_available + (v_qty - v_remaining)
        using errcode = 'P0001';
    end if;
  end loop;

  insert into public.pos_receipts (sale_id, printed_at, printed_by)
  values (v_sale_id, now(), v_user_id);

  -- C205 / D62 : encaissement enregistré dans la session du vendeur (espèces :
  -- compté dans le solde attendu ; autres moyens : tracés à part).
  if v_session_id is not null then
    insert into public.cash_movements (
      cash_drawer_session_id, type, amount, payment_method,
      reference_id, reference_type, notes, created_by
    ) values (
      v_session_id, 'sale', p_final_amount, p_payment_method,
      v_sale_id::text, 'pos_sale', 'Vente POS', v_user_id
    );
  end if;

  return v_sale_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.pos_refund_sale(p_sale_id uuid, p_reason text, p_disposition text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_pharmacy_id uuid;
  v_status text;
  v_final integer;
  v_created_at timestamptz;
  v_is_manager boolean;
  v_limit integer;
  v_reason text := nullif(btrim(p_reason), '');
  v_item record;
  v_payment text;
  v_session_id uuid;
begin
  -- Verrou sur la vente : deux remboursements simultanés se sérialisent.
  select pharmacy_id, status, final_amount, created_at, payment_method
    into v_pharmacy_id, v_status, v_final, v_created_at, v_payment
    from public.pos_sales
    where id = p_sale_id
    for update;
  if not found then
    raise exception 'POS: vente % introuvable', p_sale_id using errcode = 'P0002';
  end if;

  select (p.manager_id = v_user_id), p.pos_refund_staff_limit
    into v_is_manager, v_limit
    from public.pharmacies p where p.id = v_pharmacy_id;
  v_is_manager := coalesce(v_is_manager, false);

  -- Accès : personnel de l'officine uniquement (le titulaire y est rattaché
  -- par C208) ; le statut de titulaire ne lève que la règle jour/plafond.
  if v_user_id is null or not public.is_pharmacy_staff(v_pharmacy_id) then
    raise exception 'POS: acces refuse a cette officine' using errcode = '42501';
  end if;
  if v_status is distinct from 'completed' then
    raise exception 'POS: seule une vente completee peut etre remboursee (statut %)', v_status
      using errcode = '22023';
  end if;
  if v_reason is null or char_length(v_reason) < 3 then
    raise exception 'POS: motif du remboursement obligatoire' using errcode = '22023';
  end if;
  if p_disposition is null or p_disposition not in ('restock', 'quarantine') then
    raise exception 'POS: destination du stock a preciser (restock ou quarantine)'
      using errcode = '22023';
  end if;

  -- Règle C204 : hors titulaire, le jour même et sous le plafond de l'officine.
  -- Jour calendaire en heure de Conakry (UTC+0) ; à paramétrer par officine
  -- le jour où PharmaConnect sort de Guinée.
  if not v_is_manager then
    if (v_created_at at time zone 'Africa/Conakry')::date
         <> (now() at time zone 'Africa/Conakry')::date then
      raise exception 'POS: remboursement reserve au titulaire (vente d''un jour precedent)'
        using errcode = '42501';
    end if;
    if v_final > v_limit then
      raise exception 'POS: remboursement reserve au titulaire (montant % superieur au plafond %)',
        v_final, v_limit using errcode = '42501';
    end if;
  end if;

  -- C205 / D62 : remboursement dans le moyen d'origine ; en espèces, il sort
  -- de la caisse ouverte de la personne qui rembourse (obligatoire).
  select id into v_session_id
    from public.cash_drawer_sessions
    where pharmacy_id = v_pharmacy_id and cashier_id = v_user_id and status = 'open'
    order by opened_at desc
    limit 1;
  if v_payment = 'cash' and v_session_id is null then
    raise exception 'POS: ouvrez votre caisse pour rembourser en especes' using errcode = '22023';
  end if;

  -- updated_at est géré par trigger_pos_sales_updated_at.
  update public.pos_sales
    set status = 'refunded',
        refunded_at = now(),
        refunded_by = v_user_id,
        refund_reason = v_reason,
        refund_stock_disposition = p_disposition,
        updated_by = v_user_id
    where id = p_sale_id;

  for v_item in
    select si.id, si.batch_id, si.product_id, si.product_name, si.quantity
      from public.pos_sale_items si
      where si.sale_id = p_sale_id and si.batch_id is not null
  loop
    if p_disposition = 'restock' then
      perform public.stock_apply_movement(
        v_item.batch_id, v_item.quantity, 'adjustment',
        p_sale_id::text, 'Remboursement vente POS : remise en stock'
      );
    else
      insert into public.pos_refund_quarantine (
        pharmacy_id, sale_id, sale_item_id, batch_id, product_id,
        product_name, quantity, reason, created_by
      ) values (
        v_pharmacy_id, p_sale_id, v_item.id, v_item.batch_id, v_item.product_id,
        v_item.product_name, v_item.quantity, v_reason, v_user_id
      );
    end if;
  end loop;

  if v_session_id is not null then
    insert into public.cash_movements (
      cash_drawer_session_id, type, amount, payment_method,
      reference_id, reference_type, notes, created_by
    ) values (
      v_session_id, 'refund', v_final, v_payment,
      p_sale_id::text, 'pos_sale', 'Remboursement vente POS', v_user_id
    );
  end if;
end;
$function$;

comment on function public.pos_refund_sale(uuid, text, text) is
  'C197 / C204 / C205 : remboursement POS complet en une transaction. Règle C204 (jour même et plafond hors titulaire, motif, remise en stock ou quarantaine). C205 / D62 : remboursement dans le moyen d''origine ; en espèces, caisse ouverte obligatoire, montant sorti de la caisse de la personne qui rembourse.';

comment on function public.pos_create_sale(uuid, text, integer, integer, integer, integer, jsonb, uuid, text) is
  'C197 / C203 / C201 / C218 / C205 : vente POS complète en une transaction (vente, lignes, mouvements de stock, reçu). Lots choisis par le serveur, prix du stock imposé, ordonnance tracée. C205 / D62 : vente en espèces seulement avec une caisse ouverte du vendeur ; encaissement enregistré dans sa session (espèces comptées dans le solde attendu, autres moyens tracés à part).';
