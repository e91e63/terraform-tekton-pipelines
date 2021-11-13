#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
REPO_URL=${REPO_URL:?}

echo "Installing dependencies"
apk add "git" "openssh"

echo "git cloning ${REPO_URL} into ${PWD}"
git clone "${REPO_URL}"

echo "Finished $(basename "${0}")"
