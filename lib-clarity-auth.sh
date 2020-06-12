#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${DIR}/lib-log.sh"
source "${DIR}/lib-jwt.sh"

CLARITY_HOST=""

function clarity-init() {
    CLARITY_HOST="${1}"
}

function clarity-get-token-from-api() {
    local KEY="${1}"
    local SECRET="${2}"
    local DATA=$(printf '{"key": "%s", "secret": "%s"}' "${KEY}" "${SECRET}")

    curl --silent --header 'Accept: application/json' \
         --header 'Content-type: application/json' \
         "${CLARITY_HOST}/clarity/v1/oauth/token" \
         --data "${DATA}"
}

function clarity-get-token-from-username-and-password() {
    local USERNAME="${1}"
    local PASSWORD="${2}"
    local DATA=$(printf '{"email":"%s","password":"%s"}' "${USERNAME}" "${PASSWORD}")

    curl --silent --header 'Accept: application/json' \
         --header 'Content-type: application/json' \
         "${CLARITY_HOST}/clarity/v1/auth/login" \
         --data "$DATA"
}

function clarity-get-token-from-refresh-token() {
    local REFRESH_TOKEN="${1}"

    curl --silent --header 'Accept: application/json' \
         --header 'Content-type: application/json' \
         --request POST "${CLARITY_HOST}/clarity/v1/auth/token" \
         --header "Authorization: Bearer ${REFRESH_TOKEN}"
}

function clarity-show-token() {
    local TOKEN="${1}"
    local HEADER=$(jwt-get-decoded-header "${TOKEN}")
    local PAYLOAD=$(jwt-get-decoded-payload "${TOKEN}")

    log "Token:"
    log "$TOKEN"
    log ""

    log "Header:"
    log_json "${HEADER}"
    log ""

    log "Payload:"
    log_json "${PAYLOAD}"
    log ""
}
