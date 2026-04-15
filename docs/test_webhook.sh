#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Zoho Webhook – lokaler Test-Script
# Verwendung: bash docs/test_webhook.sh
#
# Voraussetzungen:
#   1. Rails Server läuft: ZOHO_WEBHOOK_SECRET=test-secret rails server
#   2. Migrationen ausgeführt: rails db:migrate
# ─────────────────────────────────────────────────────────────────────────────

BASE_URL="http://localhost:3000/api/v1/zoho/webhook"
SECRET="test-secret"
PASS=0
FAIL=0

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

send_request() {
  local label="$1"
  local payload="$2"
  local expected_status="${3:-202}"

  echo ""
  echo -e "${YELLOW}▶ ${label}${NC}"

  response=$(curl -s -o /tmp/webhook_response.json -w "%{http_code}" \
    -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SECRET" \
    -d "$payload")

  body=$(cat /tmp/webhook_response.json)

  if [ "$response" -eq "$expected_status" ]; then
    echo -e "  ${GREEN}✓ HTTP $response${NC}  $body"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗ HTTP $response (erwartet: $expected_status)${NC}  $body"
    FAIL=$((FAIL + 1))
  fi
}

echo "═══════════════════════════════════════════════════════"
echo " Zoho Webhook – Test Suite"
echo "═══════════════════════════════════════════════════════"

# ── 1. Unauthorized (falsches Token) ─────────────────────────────────────────
echo ""
echo "── AUTH TESTS ──────────────────────────────────────────"

echo ""
echo -e "${YELLOW}▶ Ungültiger Bearer Token → 401${NC}"
response=$(curl -s -o /tmp/webhook_response.json -w "%{http_code}" \
  -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FALSCHES-SECRET" \
  -d '{"event":"city.created","entity_type":"city","zoho_id":"TEST-1","triggered_at":"2026-04-14T10:00:00Z","data":{"name":"Test","currency":"EUR"}}')
body=$(cat /tmp/webhook_response.json)
if [ "$response" -eq "401" ]; then
  echo -e "  ${GREEN}✓ HTTP $response${NC}  $body"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}✗ HTTP $response (erwartet: 401)${NC}  $body"
  FAIL=$((FAIL + 1))
fi

echo ""
echo -e "${YELLOW}▶ Kein Token → 401${NC}"
response=$(curl -s -o /tmp/webhook_response.json -w "%{http_code}" \
  -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{"event":"city.created","entity_type":"city","zoho_id":"TEST-1","triggered_at":"2026-04-14T10:00:00Z","data":{"name":"Test","currency":"EUR"}}')
body=$(cat /tmp/webhook_response.json)
if [ "$response" -eq "401" ]; then
  echo -e "  ${GREEN}✓ HTTP $response${NC}  $body"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}✗ HTTP $response (erwartet: 401)${NC}  $body"
  FAIL=$((FAIL + 1))
fi

# ── 2. City ───────────────────────────────────────────────────────────────────
echo ""
echo "── CITY ────────────────────────────────────────────────"

send_request "city.created – Berlin" \
  '{"event":"city.created","entity_type":"city","zoho_id":"CITY-BER-001","triggered_at":"2026-04-14T10:00:00Z","data":{"name":"Berlin","currency":"EUR"}}'

send_request "city.created – Zürich (CHF)" \
  '{"event":"city.created","entity_type":"city","zoho_id":"CITY-ZRH-001","triggered_at":"2026-04-14T10:00:10Z","data":{"name":"Zürich","currency":"CHF"}}'

send_request "city.updated – Berlin umbenennen" \
  '{"event":"city.updated","entity_type":"city","zoho_id":"CITY-BER-001","triggered_at":"2026-04-14T10:01:00Z","data":{"name":"Berlin (updated)","currency":"EUR"}}'

# ── 3. Location ───────────────────────────────────────────────────────────────
echo ""
echo "── LOCATION ────────────────────────────────────────────"

send_request "location.created – Berlin Mitte" \
  '{"event":"location.created","entity_type":"location","zoho_id":"LOC-BER-001","triggered_at":"2026-04-14T10:02:00Z","data":{"name":"Satellite Office Berlin Mitte","address":"Friedrichstraße 100, 10117 Berlin","city_zoho_id":"CITY-BER-001","language":"de","picture_id":"ZO-IMG-4521","phone":"+49 30 12345678","email":"berlin@satelliteoffice.de","website":"https://satelliteoffice.de/berlin"}}'

send_request "location.created – unbekannte City → 422" \
  '{"event":"location.created","entity_type":"location","zoho_id":"LOC-INVALID","triggered_at":"2026-04-14T10:02:30Z","data":{"name":"Test","address":"Test","city_zoho_id":"CITY-DOESNT-EXIST","language":"de","phone":"","email":"","website":""}}' \
  422

# ── 4. Conference Room ────────────────────────────────────────────────────────
echo ""
echo "── CONFERENCE ROOM ─────────────────────────────────────"

send_request "conference_room.created" \
  '{"event":"conference_room.created","entity_type":"conference_room","zoho_id":"CR-BER-101","triggered_at":"2026-04-14T10:03:00Z","data":{"name":"Boardroom Alpha","number_of_people":12,"picture_id":"ZO-IMG-7890","location_zoho_id":"LOC-BER-001","price_intern":"45.00","price_extern":"75.00","translations":[{"language":"de","name":"Konferenzraum Alpha"},{"language":"en","name":"Boardroom Alpha"}]}}'

send_request "conference_room.updated – Preis erhöhen" \
  '{"event":"conference_room.updated","entity_type":"conference_room","zoho_id":"CR-BER-101","triggered_at":"2026-04-14T10:04:00Z","data":{"name":"Boardroom Alpha","number_of_people":12,"picture_id":"ZO-IMG-7890","location_zoho_id":"LOC-BER-001","price_intern":"50.00","price_extern":"80.00","translations":[{"language":"de","name":"Konferenzraum Alpha"},{"language":"en","name":"Boardroom Alpha"}]}}'

# ── 5. Office ─────────────────────────────────────────────────────────────────
echo ""
echo "── OFFICE ──────────────────────────────────────────────"

send_request "office.created" \
  '{"event":"office.created","entity_type":"office","zoho_id":"OFF-BER-201","triggered_at":"2026-04-14T10:05:00Z","data":{"name":"Office 3A","square_meters":28,"workspaces":3,"floor":"3. OG","floor_plan_image_id":"ZO-IMG-3310","location_zoho_id":"LOC-BER-001","price_3":"990.00","price_12":"850.00","translations":[{"language":"de","name":"Büro 3A","description":"<ul><li>28 m² Einzelbüro</li><li>3 Arbeitsplätze</li></ul>"},{"language":"en","name":"Office 3A","description":"<ul><li>28 m² private office</li><li>3 workspaces</li></ul>"}]}}'

# ── 6. Virtual Office ─────────────────────────────────────────────────────────
echo ""
echo "── VIRTUAL OFFICE ──────────────────────────────────────"

send_request "virtual_office.created" \
  '{"event":"virtual_office.created","entity_type":"virtual_office","zoho_id":"VO-BER-301","triggered_at":"2026-04-14T10:06:00Z","data":{"name":"Virtual Office Basic","location_zoho_id":"LOC-BER-001","price_3":"89.00","price_12":"75.00","translations":[{"language":"de","name":"Virtuelles Büro Basic","description":"<ul><li>Geschäftsadresse Berlin</li></ul>"},{"language":"en","name":"Virtual Office Basic","description":"<ul><li>Business address Berlin</li></ul>"}]}}'

# ── 7. Company Headquarter ────────────────────────────────────────────────────
echo ""
echo "── COMPANY HEADQUARTER ─────────────────────────────────"

send_request "company_headquarter.created" \
  '{"event":"company_headquarter.created","entity_type":"company_headquarter","zoho_id":"HQ-BER-401","triggered_at":"2026-04-14T10:07:00Z","data":{"name":"Company HQ Premium","location_zoho_id":"LOC-BER-001","price_3":"290.00","price_12":"249.00","translations":[{"language":"de","name":"Firmensitz Premium","description":"<ul><li>Repräsentative Adresse</li></ul>"},{"language":"en","name":"Company HQ Premium","description":"<ul><li>Representative address</li></ul>"}]}}'

# ── 8. Addon ──────────────────────────────────────────────────────────────────
echo ""
echo "── ADDON ───────────────────────────────────────────────"

send_request "addon.created – Parkplatz" \
  '{"event":"addon.created","entity_type":"addon","zoho_id":"ADD-001","triggered_at":"2026-04-14T10:08:00Z","data":{"name":"Parkplatz","location_zoho_id":"LOC-BER-001","billing_type":"monthly","category":"Mobility","unit":"pro Stellplatz","applies_to":["Office","VirtualOffice","CompanyHeadquarter"],"price_per_location":"75.00","translations":[{"language":"de","name":"Parkplatz","description":"<ul><li>Tiefgarage 24/7</li></ul>"},{"language":"en","name":"Parking Space","description":"<ul><li>Underground parking 24/7</li></ul>"}]}}'

# ── 9. Delete Tests ───────────────────────────────────────────────────────────
echo ""
echo "── DELETE TESTS ────────────────────────────────────────"

send_request "conference_room.deleted" \
  '{"event":"conference_room.deleted","entity_type":"conference_room","zoho_id":"CR-BER-101","triggered_at":"2026-04-14T10:09:00Z","data":{}}'

send_request "office.deleted – nicht existierende ID (idempotent)" \
  '{"event":"office.deleted","entity_type":"office","zoho_id":"OFF-DOESNT-EXIST","triggered_at":"2026-04-14T10:10:00Z","data":{}}'

# ── 10. Fehler-Cases ──────────────────────────────────────────────────────────
echo ""
echo "── ERROR CASES ─────────────────────────────────────────"

send_request "Unbekannter entity_type → 422" \
  '{"event":"foobar.created","entity_type":"foobar","zoho_id":"X-001","triggered_at":"2026-04-14T10:11:00Z","data":{}}' \
  422

send_request "Kein zoho_id → 422" \
  '{"event":"city.created","entity_type":"city","zoho_id":"","triggered_at":"2026-04-14T10:12:00Z","data":{"name":"Test","currency":"EUR"}}' \
  422

# ── Ergebnis ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL))
echo -e " Ergebnis: ${GREEN}${PASS}/${TOTAL} Tests bestanden${NC}"
if [ "$FAIL" -gt 0 ]; then
  echo -e " ${RED}${FAIL} Tests fehlgeschlagen${NC}"
fi
echo "═══════════════════════════════════════════════════════"
