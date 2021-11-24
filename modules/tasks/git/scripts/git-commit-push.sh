#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
DIR="${PWD}"
GPG_DIR="${GPG_DIR:?}"
HCLEDIT_DIR="/tmp/hcledit"
HCLEDIT_VERSION="0.2.0"
HCLEDIT_URL="https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"
IMAGE_DIGEST="${IMAGE_DIGEST:?}"
IMAGE=$(echo "${IMAGE_DIGEST}" | sed 's/@.*//')

echo "Installing dependencies"
apk add "git" "gnupg" "wget"

echo "Installing hcledit"
mkdir -p "${HCLEDIT_DIR}"
cd "${HCLEDIT_DIR}"
wget --quiet "${HCLEDIT_URL}" --directory-prefix "${HCLEDIT_DIR}"
tar -xvzf "hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"
chmod +x "./hcledit"

echo "Updating terragrunt.hcl with ${IMAGE}"
cd "${DIR}"
"${HCLEDIT_DIR}/hcledit" attribute set "locals.image" "\"${IMAGE}\"" --file "./terragrunt.hcl" --update

GIT_DIFF=$(git status --porcelain)
if [ -n "${GIT_DIFF}" ]; then
    echo "Configuring GPG"
    GPG_KEY_ID="$(cat "${GPG_DIR}/key-id.txt")"
    gpg --import "${GPG_DIR}/private.key"
    gpg --import-ownertrust "${GPG_DIR}/trustlevel.txt"

    echo "Committing changes"
    git config --global "commit.gpgsign" "true"
    git config --global "tag.gpgsign" "true"
    git config --global "user.name" "Infrastructure automation"
    git config --global "user.email" "automation@e91e63.tech"
    git config --global "user.signingkey" "${GPG_KEY_ID}"

    git add .
    git status
    git diff HEAD
    git commit -a -m "Updating to ${IMAGE}"

    echo "Pushing commit"
    git push --set-upstream "origin" "$(git branch --show-current)"
fi

echo "Finished $(basename "${0}")"
