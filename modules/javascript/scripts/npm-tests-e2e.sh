#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
npm ci

echo "Running end-to-end tests"
npm run test:e2e

echo "Finished $(basename "${0}")"
