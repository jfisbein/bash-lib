#!/bin/bash
SLACK_API_URL="https://slack.com/api/"
TOKEN=""

function slack-init() {
    TOKEN="${1}"
}

function slack-update-status() {
    local TEXT="${1}"
    local EMOJI="${2}"
    local EXPIRATION="${3}"

    local DATA=$(printf '{"status_text":"%s","status_emoji":"%s","status_expiration":%s}' "${TEXT}" "${EMOJI}" "${EXPIRATION}")

    ##curl --silent --header "Authorization: Bearer ${TOKEN}" --header "Content-type: application/json; charset=utf-8" --data "${DATA}" "${SLACK_API_URL}users.profile.set"

    curl --silent -X POST ${SLACK_API_URL}users.profile.set \
        --data-urlencode "profile=${DATA}" \
        --data-urlencode "token=${TOKEN}"
}

function slack-reset-status() {
    local DATA='{"status_text":"","status_emoji":""}'

    curl --silent -X POST ${SLACK_API_URL}users.profile.set \
        --data-urlencode "profile=${DATA}" \
        --data-urlencode "token=${TOKEN}"
}
