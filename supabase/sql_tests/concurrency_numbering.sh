#!/usr/bin/env bash
# C197 / C202 : test de concurrence de la numérotation, base LOCALE uniquement.
#
# Deux sessions psql simultanées, deux identités distinctes :
#   1. customer_returns : pharmacien A (Kaloum) et pharmacien B (Dixinn) ;
#   2. vente POS via public.pos_create_sale : A vend 1 unité de
#      LOT-2026-0009 (Kaloum), B vend 1 unité de LOT-2026-0028 (Dixinn).
# Chaque session : begin ; identité ; insertion ; pg_sleep(2) ; commit.
# Attendu : numéros distincts et consécutifs, aucune erreur 23505 ; la
# seconde session attend la première (verrou pg_advisory_xact_lock) pendant
# environ 2 s.
#
# Les données de test sont committées (nécessaire pour deux sessions) :
# le script se termine par `supabase db reset --local`.
#
# Exécution (depuis la racine du dépôt) : bash supabase/sql_tests/concurrency_numbering.sh

set -euo pipefail

DB=supabase_db_pharma_connect
A=aaaaaaaa-0000-0000-0000-00000000000a
B=bbbbbbbb-0000-0000-0000-00000000000b
PA=55555555-5555-5555-5555-555555550001
PB=55555555-5555-5555-5555-555555550002
OUT=$(mktemp -d)

psql_db() { docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

echo "===== Préparation (committée)"
psql_db <<SQL
insert into auth.users (id, email) values
  ('$A', 'conc-a@test.local'), ('$B', 'conc-b@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('$A', 'pharmacien', '$PA', 'Pharmacien A Kaloum'),
  ('$B', 'pharmacien', '$PB', 'Pharmacien B Dixinn');
-- C218 : prix de vente du stock aligné sur celui des ventes du script (1 000),
-- et au moins une unité en stock sur chaque lot vendu.
update public.stock_items si set unit_price = 1000
  from public.stock_batches b
  where b.stock_item_id = si.id
    and ((b.batch_number = 'LOT-2026-0009' and si.pharmacy_id = '$PA')
      or (b.batch_number = 'LOT-2026-0028' and si.pharmacy_id = '$PB'));
update public.stock_batches b set quantity = greatest(b.quantity, 5)
  from public.stock_items si
  where b.stock_item_id = si.id
    and ((b.batch_number = 'LOT-2026-0009' and si.pharmacy_id = '$PA')
      or (b.batch_number = 'LOT-2026-0028' and si.pharmacy_id = '$PB'));
SQL

# Une session : identité, insertion, horodatages, pause de 2 s, commit.
# \$1 = identité, \$2 = requête d'insertion renvoyant le numéro, \$3 = fichier de sortie.
session() {
  psql_db > "$3" 2>&1 <<SQL
begin;
select set_config('request.jwt.claims', json_build_object('sub', '$1', 'role', 'authenticated')::text, true) \\g /dev/null
set local role authenticated;
select 'debut=' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
$2
select 'fin_insert=' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
select pg_sleep(2) \\g /dev/null
commit;
SQL
}

run_pair() {
  local label=$1 q1=$2 q2=$3
  echo "===== $label"
  session "$A" "$q1" "$OUT/$label-1.txt" &
  local p1=$!
  sleep 0.5
  session "$B" "$q2" "$OUT/$label-2.txt" &
  local p2=$!
  local rc1=0 rc2=0
  wait $p1 || rc1=$?
  wait $p2 || rc2=$?
  echo "--- session 1 (A), code retour $rc1"; cat "$OUT/$label-1.txt"
  echo "--- session 2 (B), code retour $rc2"; cat "$OUT/$label-2.txt"
  if grep -q "23505\|duplicate key" "$OUT/$label-1.txt" "$OUT/$label-2.txt"; then
    echo "RESULTAT $label ECHEC : erreur d'unicité"
  elif [ $rc1 -ne 0 ] || [ $rc2 -ne 0 ]; then
    echo "RESULTAT $label ECHEC : session en erreur"
  fi
}

run_pair returns \
  "insert into public.customer_returns (pharmacy_id, status, total_amount) values ('$PA', 'pending', 0) returning 'numero=' || return_number;" \
  "insert into public.customer_returns (pharmacy_id, status, total_amount) values ('$PB', 'pending', 0) returning 'numero=' || return_number;"

sale_query() {
  # \$1 = officine, \$2 = numéro de lot
  # Deux instructions : la lecture doit voir les lignes écrites par la RPC,
  # ce que ne permet pas une jointure dans la même instruction (même instantané).
  cat <<SQL
select public.pos_create_sale('$1', 'cash', 1000, 0, 0, 1000,
    (select jsonb_build_array(jsonb_build_object(
        'product_id', si.product_id, 'product_name', 'Test concurrence', 'quantity', 1,
        'unit_price', 1000, 'total_price', 1000, 'batch_id', b.id))
       from public.stock_batches b join public.stock_items si on si.id = b.stock_item_id
       where b.batch_number = '$2' and si.pharmacy_id = '$1')) as sale_id \\gset
select 'numero=' || s.sale_number || ' recu=' || r.receipt_number
  from public.pos_sales s join public.pos_receipts r on r.sale_id = s.id
  where s.id = :'sale_id';
SQL
}

run_pair pos_sales "$(sale_query "$PA" LOT-2026-0009)" "$(sale_query "$PB" LOT-2026-0028)"

echo "===== Contrôle final (postgres)"
psql_db <<SQL
select 'customer_returns : ' || string_agg(return_number, ', ' order by return_number) from public.customer_returns;
select 'pos_sales : ' || string_agg(sale_number, ', ' order by sale_number) from public.pos_sales;
select 'pos_receipts : ' || string_agg(receipt_number, ', ' order by receipt_number) from public.pos_receipts;
select case when count(*) = 2 and count(distinct return_number) = 2
             and max(substring(return_number from 3)::int) - min(substring(return_number from 3)::int) = 1
            then 'RESULTAT returns OK : 2 numéros distincts et consécutifs'
            else 'RESULTAT returns ECHEC' end from public.customer_returns;
select case when count(*) = 2 and count(distinct sale_number) = 2
             and max(substring(sale_number from 2)::int) - min(substring(sale_number from 2)::int) = 1
            then 'RESULTAT pos_sales OK : 2 numéros distincts et consécutifs'
            else 'RESULTAT pos_sales ECHEC' end from public.pos_sales;
select case when count(*) = 2 and count(distinct receipt_number) = 2
             and max(substring(receipt_number from 2)::int) - min(substring(receipt_number from 2)::int) = 1
            then 'RESULTAT pos_receipts OK : 2 numéros distincts et consécutifs'
            else 'RESULTAT pos_receipts ECHEC' end from public.pos_receipts;
SQL

rm -rf "$OUT"

echo "===== Nettoyage : supabase db reset --local"
supabase db reset --local > /dev/null 2>&1 && echo "base locale réinitialisée"
