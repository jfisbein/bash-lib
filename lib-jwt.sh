#!/usr/bin/env bash

function jwt-get-decoded-header() {
  local TOKEN="${1}"
  local HEADER=$(echo "${TOKEN}" | cut -d '.' -f 1 | base64 --decode 2>/dev/null)

  echo "${HEADER}"
}

function jwt-get-decoded-payload() {
  local TOKEN="${1}"
  local PAYLOAD=$(echo "${TOKEN}" | cut -d '.' -f 2 | base64 --decode 2>/dev/null)

  echo "${PAYLOAD}"
}

function jwt-get-user-id() {
  local PAYLOAD="${1}"
  jwt-get-payload-path "${PAYLOAD}" ".userId"
}

function jwt-get-client-id() {
  local PAYLOAD="${1}"
  jwt-get-payload-path "${PAYLOAD}" ".clientId"
}

function jwt-get-email() {
  local PAYLOAD="${1}"
  jwt-get-payload-path "${PAYLOAD}" ".email"
}

function jwt-get-client-name() {
  local PAYLOAD="${1}"
  jwt-get-payload-path "${PAYLOAD}" ".clientName"
}

function jwt-get-expiration() {
  local PAYLOAD="${1}"
  jwt-get-payload-path "${PAYLOAD}" ".exp"
}

function jwt-is-valid-json() {
  local JSON="${1}"
  jq -e . >/dev/null 2>&1 <<<"$JSON"
}

function jwt-is-wellformed-token() {
  local TOKEN="${1}"
  local HEADER=$(jwt-get-decoded-header "${TOKEN}")
  if [[ "${HEADER}" != "" ]] &&  [[ "${HEADER}" != "null" ]] && jwt-is-valid-json "${HEADER}"; then
    local PAYLOAD=$(jwt-get-decoded-payload "${TOKEN}")
    if [[ "${PAYLOAD}" != "" ]] &&  [[ "${PAYLOAD}" != "null" ]] && jwt-is-valid-json "${PAYLOAD}"; then
      return 0
    fi
  fi
  return 1
}

function jwt-is-valid-token() {
  local TOKEN="${1}"
  local DELTA="${2:-0}"

  if jwt-is-wellformed-token "${TOKEN}"; then
    local PAYLOAD=$(jwt-get-decoded-payload "${TOKEN}")
    local EXP_DATE=$(jwt-get-expiration "${PAYLOAD}")
    ((EXP_DATE=EXP_DATE-DELTA))
    local CURRENT_TS=$(date +%s)
    if [[ ${EXP_DATE} > ${CURRENT_TS} ]]; then
      return 0
    fi
  fi

  return 1
}

function jwt-get-payload-path() {
  local PAYLOAD="${1}"
  local JSON_PATH="${2}"
  echo "${PAYLOAD}" | jq -r "${JSON_PATH}"
}
