-- C273 (c) : rectification d'une caisse fermée, et règles des dépôts et
-- retraits imposées par le serveur (décisions d'Achille du 16/10/2026,
-- modifiant D62).
--
-- 1. Une caisse fermée n'est jamais modifiée. Le titulaire de l'officine peut
--    y rattacher une RECTIFICATION : nouveau montant compté, motif obligatoire,
--    auteur et heure. Le montant d'origine, son écart et les rectifications
--    précédentes restent visibles. Plusieurs rectifications sont possibles ;
--    la dernière fait foi.
-- 2. Dépôt ou retrait d'espèces (cash_add_movement) :
--    - motif obligatoire ;
--    - avant la première vente (ou remboursement) de la session : le caissier
--      de la session ou le titulaire (correction du fonds de caisse) ;
--    - après : le titulaire seul.
--    Le reste de la fonction est inchangé (20260930080000_cash_linked_to_sales.sql).
-- 3. cash_summary : trois colonnes ajoutées en fin de vue (montant compté et
--    écart après la dernière rectification, nombre de rectifications) ; les
--    colonnes existantes sont inchangées.
--
-- Aucune migration existante modifiée.

-- ============================================================
-- Rectifications
-- ============================================================

create table public.cash_drawer_rectifications (
  id uuid primary key default gen_random_uuid(),
  -- Ordre d'enregistrement : la dernière rectification fait foi (deux
  -- rectifications peuvent porter la même heure).
  seq bigint generated always as identity,
  cash_drawer_session_id uuid not null
    references public.cash_drawer_sessions(id) on delete cascade,
  -- Montant compté retenu avant cette rectification (fermeture ou
  -- rectification précédente), et nouveau montant compté.
  previous_counted_balance integer not null,
  counted_balance integer not null check (counted_balance >= 0),
  -- Solde attendu figé à la fermeture, et nouvel écart.
  expected_balance integer not null,
  difference integer not null,
  reason text not null check (length(btrim(reason)) > 0),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

comment on table public.cash_drawer_rectifications is
  'C273 (c) : rectifications rattachées à une caisse fermée, par le titulaire, motif obligatoire. La session n''est jamais modifiée ; la dernière rectification fait foi.';

create index cash_drawer_rectifications_session
  on public.cash_drawer_rectifications (cash_drawer_session_id, seq);

alter table public.cash_drawer_rectifications enable row level security;

-- Lecture par le personnel de l'officine ; aucune écriture directe (pas de
-- policy d'écriture) : uniquement par cash_rectify_closing.
create policy "Pharmacy staff view cash rectifications"
  on public.cash_drawer_rectifications
  for select to authenticated
  using (exists (select 1 from public.cash_drawer_sessions s
                  where s.id = cash_drawer_session_id
                    and public.is_pharmacy_staff(s.pharmacy_id)));

revoke all on public.cash_drawer_rectifications from anon;
revoke insert, update, delete on public.cash_drawer_rectifications from authenticated;
grant select on public.cash_drawer_rectifications to authenticated;

create or replace function public.cash_rectify_closing(
  p_session_id uuid,
  p_counted_balance integer,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session record;
  v_previous integer;
  v_id uuid;
begin
  select * into v_session from public.cash_drawer_sessions where id = p_session_id for update;
  if not found then
    raise exception 'CAISSE: session introuvable' using errcode = 'P0002';
  end if;
  if v_user_id is null or not public.is_pharmacy_manager(v_session.pharmacy_id) then
    raise exception 'CAISSE: rectification reservee au titulaire' using errcode = '42501';
  end if;
  if v_session.status <> 'closed' then
    raise exception 'CAISSE: seule une caisse fermee se rectifie' using errcode = '22023';
  end if;
  if p_counted_balance is null or p_counted_balance < 0 then
    raise exception 'CAISSE: montant compte invalide' using errcode = '22023';
  end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'CAISSE: motif obligatoire' using errcode = '22023';
  end if;

  select r.counted_balance into v_previous
  from public.cash_drawer_rectifications r
  where r.cash_drawer_session_id = p_session_id
  order by r.seq desc
  limit 1;

  insert into public.cash_drawer_rectifications (
    cash_drawer_session_id, previous_counted_balance, counted_balance,
    expected_balance, difference, reason, created_by
  ) values (
    p_session_id,
    coalesce(v_previous, v_session.closing_balance),
    p_counted_balance,
    v_session.expected_balance,
    p_counted_balance - v_session.expected_balance,
    btrim(p_reason),
    v_user_id
  )
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.cash_rectify_closing(uuid, integer, text) is
  'C273 (c) : rattache une rectification (nouveau montant compté, motif) à une caisse fermée, par le titulaire. La session n''est pas modifiée.';

revoke all on function public.cash_rectify_closing(uuid, integer, text) from public, anon;
grant execute on function public.cash_rectify_closing(uuid, integer, text) to authenticated;

-- ============================================================
-- Dépôts et retraits : motif obligatoire, titulaire seul après une vente
-- ============================================================

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
  -- C273 (c) : motif obligatoire.
  if p_notes is null or btrim(p_notes) = '' then
    raise exception 'CAISSE: motif obligatoire' using errcode = '22023';
  end if;
  -- C273 (c) : après la première vente ou le premier remboursement de la
  -- session, le titulaire seul.
  if exists (select 1 from public.cash_movements m
              where m.cash_drawer_session_id = p_session_id
                and m.type in ('sale', 'refund'))
     and not public.is_pharmacy_manager(v_session.pharmacy_id) then
    raise exception 'CAISSE: apres une vente, depot ou retrait reserve au titulaire' using errcode = '42501';
  end if;
  if p_type = 'withdrawal' and p_amount > public.cash_expected_balance(p_session_id) then
    raise exception 'CAISSE: retrait superieur aux especes attendues en caisse' using errcode = '22023';
  end if;

  insert into public.cash_movements (cash_drawer_session_id, type, amount, notes, created_by)
  values (p_session_id, p_type, p_amount, btrim(p_notes), v_user_id)
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.cash_add_movement(uuid, text, integer, text) is
  'C205, C273 (c) : dépôt ou retrait d''espèces dans une session ouverte, motif obligatoire ; par son caissier ou le titulaire avant la première vente, par le titulaire seul ensuite. Montant positif ; un retrait ne peut dépasser les espèces attendues.';

revoke all on function public.cash_add_movement(uuid, text, integer, text) from public, anon;
grant execute on function public.cash_add_movement(uuid, text, integer, text) to authenticated;

-- ============================================================
-- Résumé de session : montant compté et écart après rectification
-- ============================================================

create or replace view public.cash_summary
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
   - coalesce(sum(m.amount) filter (where m.type = 'withdrawal'), 0))::integer as current_expected_cash,
  -- C273 (c) : dernière rectification (null s'il n'y en a pas).
  r.counted_balance as rectified_closing_balance,
  r.difference as rectified_difference,
  coalesce(r.rectification_count, 0)::integer as rectification_count
from public.cash_drawer_sessions s
left join public.cash_movements m on m.cash_drawer_session_id = s.id
left join lateral (
  select last.counted_balance, last.difference, cnt.n as rectification_count
  from (select count(*) as n
          from public.cash_drawer_rectifications x
         where x.cash_drawer_session_id = s.id) cnt
  left join lateral (
    select x.counted_balance, x.difference
      from public.cash_drawer_rectifications x
     where x.cash_drawer_session_id = s.id
     order by x.seq desc
     limit 1
  ) last on true
) r on true
group by s.id, r.counted_balance, r.difference, r.rectification_count;

comment on view public.cash_summary is
  'C205 / D62 : résumé par session de caisse, calculé à la lecture (plus de vue matérialisée périmée) et soumis aux droits de l''appelant (security_invoker). total_sales / total_refunds : espèces uniquement ; total_non_cash_* : autres moyens ; current_expected_cash : solde d''espèces attendu. C273 (c) : rectified_closing_balance / rectified_difference : montant compté et écart de la dernière rectification (null sans rectification), rectification_count : nombre de rectifications.';

revoke all on public.cash_summary from anon;
grant select on public.cash_summary to authenticated;
