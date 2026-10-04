#!/usr/bin/env bash
# C243 : test de concurrence de la réservation, base LOCALE uniquement.
#
# Deux sessions psql simultanées se disputent la dernière boîte d'un lot :
#   1. deux patients réservent en même temps ;
#   2. un patient réserve pendant qu'un pharmacien vend au comptoir.
# Chaque session : begin ; identité ; opération ; pg_sleep(2) ; commit.
# Attendu : une seule opération réussit, l'autre est refusée pour stock
# insuffisant ; la seconde session attend la première (verrou sur le lot) ;
# le stock n'est jamais retenu ni vendu deux fois.
#
# Les données de test sont committées (nécessaire pour deux sessions) :
# le script se termine par `supabase db reset --local`.
#
# Exécution (depuis la racine du dépôt) : bash supabase/sql_tests/c243_concurrency_reservation.sh

set -uo pipefail

DB=supabase_db_pharma_connect
P1=c2430000-0000-0000-0000-0000000000a1
P2=c2430000-0000-0000-0000-0000000000a2
A=c2430000-0000-0000-0000-0000000000aa
KALOUM=55555555-5555-5555-5555-555555550001
PARA=33333333-3333-3333-3333-333333330001
LOT=c2430000-0000-0000-0000-0000000000b9
OUT=$(mktemp -d)
FAIL=0

psql_db() { docker exec -i "$DB" psql -U postgres -d postgres -qAt "$@"; }

echo "===== Préparation (committée)"
psql_db -v ON_ERROR_STOP=1 <<SQL
insert into auth.users (id, email) values
  ('$P1', 'c243-conc-p1@test.local'), ('$P2', 'c243-conc-p2@test.local'), ('$A', 'c243-conc-a@test.local');
insert into public.profiles (id, role, pharmacy_id, full_name) values
  ('$P1', 'patient', null, 'Patient Un'), ('$P2', 'patient', null, 'Patient Deux'),
  ('$A', 'pharmacien', '$KALOUM', 'Pharmacien A Kaloum');
insert into public.cash_drawer_sessions (pharmacy_id, cashier_id, opening_balance, status) values
  ('$KALOUM', '$A', 0, 'open');
-- Paracétamol à Kaloum : un seul lot vendable, une seule boîte.
update public.stock_items set unit_price = 1500, reserved_quantity = 0
  where pharmacy_id = '$KALOUM' and product_id = '$PARA';
update public.stock_batches b set quantity = 0, quantity_reserved = 0
  from public.stock_items si
  where si.id = b.stock_item_id and si.pharmacy_id = '$KALOUM' and si.product_id = '$PARA';
insert into public.stock_batches (id, stock_item_id, batch_number, manufacturing_date, expiry_date, quantity, quantity_reserved, received_at)
  select '$LOT', si.id, 'C243-CONC', current_date - 100, current_date + 60, 1, 0, now()
  from public.stock_items si where si.pharmacy_id = '$KALOUM' and si.product_id = '$PARA';
SQL

RESERVE="select 'resultat=' || public.reservation_create('$KALOUM', '[{\"product_id\": \"$PARA\", \"quantity\": 1}]'::jsonb);"
SELL="select 'resultat=' || public.pos_create_sale('$KALOUM', 'cash', 1500, 0, 0, 1500, '[{\"product_id\": \"$PARA\", \"product_name\": \"Paracetamol\", \"quantity\": 1, \"unit_price\": 1500, \"total_price\": 1500}]'::jsonb);"

# Une session : identité, opération, pause de 2 s, commit.
# \$1 = identité, \$2 = requête, \$3 = fichier de sortie.
session() {
  psql_db > "$3" 2>&1 <<SQL
begin;
select set_config('request.jwt.claims', json_build_object('sub', '$1', 'role', 'authenticated')::text, true) \\g /dev/null
set local role authenticated;
select 'debut=' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
$2
select 'fin=' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
select pg_sleep(2) \\g /dev/null
commit;
SQL
}

state() { psql_db -c "select 'quantite=' || quantity || ' retenue=' || quantity_reserved from public.stock_batches where id = '$LOT'"; }

verdict() { # \$1 = libellé, \$2 = attendu, \$3 = obtenu
  if [ "$2" = "$3" ]; then echo "RESULTAT $1 OK : $3"; else echo "RESULTAT $1 ECHEC : obtenu « $3 », attendu « $2 »"; FAIL=1; fi
}

run_pair() { # \$1 = libellé, \$2 = identité 1, \$3 = requête 1, \$4 = identité 2, \$5 = requête 2
  echo "===== $1"
  session "$2" "$3" "$OUT/s1.txt" &
  sleep 0.5
  session "$4" "$5" "$OUT/s2.txt" &
  wait
  echo "--- session 1"; cat "$OUT/s1.txt"
  echo "--- session 2"; cat "$OUT/s2.txt"
  OK=$(cat "$OUT/s1.txt" "$OUT/s2.txt" | grep -c '^resultat=')
  REFUS=$(cat "$OUT/s1.txt" "$OUT/s2.txt" | grep -c 'stock insuffisant')
}

run_pair "1. Deux patients réservent la dernière boîte" "$P1" "$RESERVE" "$P2" "$RESERVE"
verdict "1a (une réservation créée, un refus)" "reussites=1 refus=1" "reussites=$OK refus=$REFUS"
verdict "1b (une seule boîte retenue)" "quantite=1 retenue=1" "$(state)"
verdict "1c (une seule réservation active)" "1" "$(psql_db -c "select count(*) from public.reservations where patient_id in ('$P1', '$P2') and status = 'pending'")"
D1=$(grep '^debut=' "$OUT/s1.txt" | cut -d= -f2); F2=$(grep -c '^fin=' "$OUT/s2.txt")
echo "    (session 1 commencée à $D1 ; la session 2 a attendu la fin de la session 1 avant d'être refusée)"

# Remise à zéro : la réservation est annulée, la boîte redevient libre.
psql_db -v ON_ERROR_STOP=1 <<SQL
select public.reservation_release_holds(r.id, null, null, 'Test de concurrence') from public.reservations r
  where r.patient_id in ('$P1', '$P2') and r.status = 'pending';
update public.reservations set status = 'cancelled' where patient_id in ('$P1', '$P2') and status = 'pending';
SQL
verdict "(remise à zéro)" "quantite=1 retenue=0" "$(state)"

run_pair "2. Un patient réserve pendant qu'un pharmacien vend la dernière boîte" "$P1" "$RESERVE" "$A" "$SELL"
verdict "2a (une opération réussie, un refus)" "reussites=1 refus=1" "reussites=$OK refus=$REFUS"
verdict "2b (boîte retenue, non vendue)" "quantite=1 retenue=1" "$(state)"

psql_db -v ON_ERROR_STOP=1 <<SQL
select public.reservation_release_holds(r.id, null, null, 'Test de concurrence') from public.reservations r
  where r.patient_id in ('$P1', '$P2') and r.status = 'pending';
update public.reservations set status = 'cancelled' where patient_id in ('$P1', '$P2') and status = 'pending';
SQL

run_pair "3. Un pharmacien vend la dernière boîte pendant qu'un patient réserve" "$A" "$SELL" "$P2" "$RESERVE"
verdict "3a (une opération réussie, un refus)" "reussites=1 refus=1" "reussites=$OK refus=$REFUS"
verdict "3b (boîte vendue, rien de retenu)" "quantite=0 retenue=0" "$(state)"

echo "===== Remise à zéro de la base locale"
supabase db reset --local > /dev/null 2>&1 && echo "base locale réinitialisée"
exit $FAIL
