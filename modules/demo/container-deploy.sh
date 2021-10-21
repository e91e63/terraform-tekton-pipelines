#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
CONTAINER_IMAGE="${CONTAINER_IMAGE:?}"

echo "Installing dependencies"
apk add "git" "wget"

echo "Installing hcledit"
HCLEDIT_VERSION="0.2.0"
wget "https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"
tar -xvzf "hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz"
chmod +x "./hcledit"

echo "${CONTAINER_IMAGE}"
./hcledit attribute set locals.image "\"${CONTAINER_IMAGE}\"" --file "./terragrunt.hcl"

echo "Committing changes"
git config --global user.name "Infrastructure automationn"
git config --global user.email "robot@e91e63.tech"

git add .
git commit -a -m "Updating to ${CONTAINER_IMAGE}"

echo "terragrunt plan"
terragrunt plan -out "terraform.plan"

echo "Pushing commit"
git push

echo "terragrunt apply"
terragrunt apply "terraform.plan"

echo "Finished $(basename "${0}")"
