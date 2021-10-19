#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "Installing dependencies"
npm ci

echo "Checking code formatting"
npm run fmt:check

echo "Checking code linting"
npm run lint:check

echo "Running unit tests"
npm run test:unit

echo "Running end-to-end tests"
npm run test:e2e

echo "Finished $(basename "${0}")"
