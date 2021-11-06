#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
RESULTS_PATH="${RESULTS_PATH:?}"

echo "Installing dependencies"
apk add "git" "jq"

echo "Getting version from package.json"
VERSION="v$(jq -r ".version" package.json)"

echo "Checking git commit for tag ${VERSION}"
TAGS=$(git tag --list --contains HEAD)

if ! (echo "${TAGS}" | grep -q "${VERSION}"); then
    GIT_COMMIT=$(git rev-parse --short HEAD)
    VERSION="${VERSION}-dev-${GIT_COMMIT}"
fi
# TODO: else bump package.json

echo "Writing tag ${VERSION} to results"
printf "%s" "${VERSION}" >"${RESULTS_PATH}"

echo "Finished $(basename "${0}")"
