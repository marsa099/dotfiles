#!/usr/bin/env bash
#
# Testar Subscription/current-endpointen i dev, tst och prd.
#
# Ett fungerande anrop returnerar JSON med ett "location"-fält (redirect till
# login), oavsett statuskod. Ett trasigt anrop ger t.ex. 409 med
# "Unable to obtain configuration from: ..." och saknar location.
#
# Anropen körs parallellt; utskriften kommer alltid i ordningen DEV, TST, PRD.

set -u

# Färger (avaktiveras om stdout inte är en terminal)
if [ -t 1 ]; then
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
    CYAN=$'\033[36m'; GRAY=$'\033[90m'; RESET=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; GRAY=''; RESET=''
fi

declare -a ENVS=("DEV" "TST" "PRD")
declare -A URLS=(
    [DEV]="https://as-contentdelivery-dev.azurewebsites.net/Subscription/current"
    [TST]="https://as-contentdelivery-tst.azurewebsites.net/Subscription/current"
    [PRD]="https://as-contentdelivery-prd.azurewebsites.net/Subscription/current"
)

# Hjälpare: plocka ut ett fält ur JSON, skiftlägesokänsligt på nyckeln
# (jq om det finns, annars grep/sed). T.ex. både "location" och "Location".
json_field() {
    local field="$1" body="$2"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$body" | jq -r --arg f "$field" \
            'to_entries | map(select(.key | ascii_downcase == ($f | ascii_downcase))) | .[0].value // empty' 2>/dev/null
    else
        printf '%s' "$body" \
            | grep -ioE "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            | head -n1 \
            | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"
    fi
}

# Kör ett anrop och skriv det formaterade resultatblocket till stdout.
process_env() {
    local env="$1"
    local url="${URLS[$env]}"

    echo
    echo "[$env] $url"

    local response status body location detail curl_rc
    response=$(curl -sS -m 30 -H 'accept: */*' -w $'\n%{http_code}' "$url" 2>&1)
    curl_rc=$?

    if [ $curl_rc -ne 0 ]; then
        echo "  ${RED}FUNGERAR EJ  inget svar (anslutning misslyckades, curl rc=$curl_rc)${RESET}"
        echo "  ${GRAY}          ${response}${RESET}"
        return
    fi

    status="${response##*$'\n'}"
    body="${response%$'\n'*}"

    # "Fungerar" = svaret innehåller ett location-fält (redirect till login),
    # oavsett statuskod. Saknas det är anropet trasigt (t.ex. 409).
    location=$(json_field "location" "$body")

    if [ -n "$location" ]; then
        echo "  ${GREEN}FUNGERAR  HTTP $status - location: $location${RESET}"
    else
        detail=$(json_field "detail" "$body")
        [ -z "$detail" ] && detail="$body"
        # Visa bara första raden av detail (stacktrace blir annars en vägg)
        detail="${detail%%$'\n'*}"
        echo "  ${RED}FUNGERAR EJ  HTTP $status${RESET}"
        echo "  ${GRAY}          ${detail}${RESET}"
    fi
}

echo
echo "${CYAN}Testar Subscription/current parallellt mot DEV, TST och PRD${RESET}"
printf '%.0s=' {1..60}; echo

# Starta alla anrop parallellt, var och en till sin egen temp-fil.
declare -A TMP
for env in "${ENVS[@]}"; do
    TMP[$env]=$(mktemp)
    process_env "$env" > "${TMP[$env]}" &
done
wait

# Skriv ut i fast ordning: DEV, TST, PRD.
for env in "${ENVS[@]}"; do
    cat "${TMP[$env]}"
    rm -f "${TMP[$env]}"
done

echo
printf '%.0s=' {1..60}; echo
echo "${CYAN}Klart.${RESET}"
