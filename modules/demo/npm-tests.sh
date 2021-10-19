#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "Installing dependencies"
# https://docs.cypress.io/guides/continuous-integration/introduction#Dependencies
apk add "alsa-lib" "gconf" "gtk+2.0" "gtk+3.0" "libnotify-dev" "libx11" "libxtst" "mesa-gbm" "nss" "xauth" "xvfb"
# libgbm-dev libxss1 libasound2
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
