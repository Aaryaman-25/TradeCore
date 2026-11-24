#!/bin/sh
# Replays the worked example from the proposal (page 2) against a running
# server. Start the server first:  make run
# Then in another terminal:        sh scripts/demo.sh
B=${TRADECORE_URL:-http://127.0.0.1:8080}

step() { printf '\n== %s\n' "$1"; }

step "Sign in as the demo account"
TOKEN=$(curl -s -X POST "$B/api/auth/login" -d '{"username":"demo","password":"demo1234"}' | sed -E 's/.*"token":"([0-9a-f]+)".*/\1/')
AUTH="Authorization: Bearer $TOKEN"
echo "token ${TOKEN%"${TOKEN#????????????}"}..."

step "Pause the live bots so only our orders are in the book"
curl -s -X POST -H "$AUTH" "$B/api/sim" -d '{"running":false}' >/dev/null; echo ok

step "Reset the session"
curl -s -X POST -H "$AUTH" "$B/api/reset"; echo

step "Rest four sell orders S1..S4"
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"sell","price":100.00,"qty":80,"label":"S1"}' >/dev/null
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"sell","price":100.00,"qty":70,"label":"S2"}' >/dev/null
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"sell","price":101.00,"qty":100,"label":"S3"}' >/dev/null
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"sell","price":102.00,"qty":40,"label":"S4"}' >/dev/null
curl -s "$B/api/book"; echo

step "B1: buy 200 @ 101.00  (expect fills 80@100 S1, 70@100 S2, 50@101 S3)"
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"buy","price":101.00,"qty":200,"label":"B1"}'; echo

step "B2: buy 80 @ 101.00  (expect 50@101 from S3, 30 rests as a bid)"
curl -s -X POST -H "$AUTH" "$B/api/orders" -d '{"side":"buy","price":101.00,"qty":80,"label":"B2"}'; echo

step "Final book  (best bid 30 @ 101.00, best ask 40 @ 102.00)"
curl -s "$B/api/book"; echo

step "Invariant check"
curl -s "$B/api/check"; echo

step "Resume the live bots"
curl -s -X POST -H "$AUTH" "$B/api/sim" -d '{"running":true}' >/dev/null; echo ok
