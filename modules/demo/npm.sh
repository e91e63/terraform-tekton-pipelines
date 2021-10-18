#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
RUN_COMMAND="${RUN_COMMAND:?}"

echo "Running NPM install"
npm ci

echo "Running NPM ${RUN_COMMAND}"
npm run "${RUN_COMMAND}"

echo "Finished $(basename "${0}")"
