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

function jwt-get-payload-path() {
  local PAYLOAD="${1}"
  local JSON_PATH="${2}"
  echo "${PAYLOAD}" | jq "${JSON_PATH}"
}
