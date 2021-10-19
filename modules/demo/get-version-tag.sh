#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
RESULTS_PATH="${RESULTS_PATH:?}"

echo "Installing dependencies"
apk add "git" "jq"

echo "Getting version from package.json"
VERSION=$(jq .version package.json)

echo "Finished $(basename "${0}")"
