#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "Checking code formatting"
npm run fmt:check

echo "Finished $(basename "${0}")"
