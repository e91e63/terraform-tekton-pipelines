#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
RESULTS_PATH="${RESULTS_PATH:?}"

echo "Installing dependencies"
apk add "git" "jq"

echo "Getting version from package.json"
VERSION=$(jq -r ".version" package.json)
VERSION_TAG="v${VERSION}"

echo "Checking git commit for ${VERSION_TAG}"
TAGS=$(git tag --list --contains HEAD)

DEV_TAG=""
if ! (echo "${TAGS}" | grep -q "${VERSION_TAG}"); then
    GIT_COMMIT=$(git rev-parse --short HEAD)
    DEV_TAG="-dev-${GIT_COMMIT}"
fi
# TODO: bump package.json

echo "Writing tag to results"
echo "${VERSION_TAG}${DEV_TAG}" >"${RESULTS_PATH}"
cat "$RESULTS_PATH"
echo "Finished $(basename "${0}")"
