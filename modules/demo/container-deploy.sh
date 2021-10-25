#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
CONTAINER_IMAGE="${CONTAINER_IMAGE:?}"
CONTAINER_IMAGE=$(echo "${CONTAINER_IMAGE}" | sed 's/@.*//')
DIR="${PWD}"
HCLEDIT_DIR="/tmp/hcledit"
HCLEDIT_VERSION="0.2.0"
HCLEDIT_URL="https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"

echo "Installing dependencies"
apk add "git" "wget"

echo "Installing hcledit"
mkdir -p "${HCLEDIT_DIR}"
cd "${HCLEDIT_DIR}"
wget --quiet "${HCLEDIT_URL}" --directory-prefix "${HCLEDIT_DIR}"
tar -xvzf "hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"
chmod +x "./hcledit"

echo "Updating terragrunt.hcl with ${CONTAINER_IMAGE}"
cd "${DIR}"
"${HCLEDIT_DIR}/hcledit" attribute set locals.image "\"${CONTAINER_IMAGE}\"" --file "./terragrunt.hcl" --update

GIT_DIFF=$(git status --porcelain)
if [ -n "${GIT_DIFF}" ]; then
    echo "Committing changes"
    git config --global "user.name" "Infrastructure robot"
    git config --global "user.email" "robot@e91e63.tech"

    git add .
    git status
    git diff HEAD
    git commit -a -m "Updating to ${CONTAINER_IMAGE}"
fi

echo "terragrunt init"
terragrunt init

echo "terragrunt plan"
terragrunt plan -out "terraform.plan"

if [ -n "${GIT_DIFF}" ]; then
    echo "Pushing commit"
    git push --set-upstream "origin" "$(git branch --show-current)"
fi

echo "terragrunt apply"
terragrunt apply "terraform.plan"

echo "Finished $(basename "${0}")"
