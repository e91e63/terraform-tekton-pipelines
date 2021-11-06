#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "Running unit tests"
npm run test:unit

echo "Finished $(basename "${0}")"
