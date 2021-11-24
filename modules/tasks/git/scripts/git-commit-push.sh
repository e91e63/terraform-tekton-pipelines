#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"
DIR="${PWD}"
GPG_SECRET_DIR="${GPG_SECRET_DIR:?}"
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
    GPG_CONF_DIR="${HOME}/.gnupg"
    GPG_EMAIL="$(cat "${GPG_SECRET_DIR}/email.txt")"
    GPG_KEY_ID="$(cat "${GPG_SECRET_DIR}/key-id.txt")"
    GPG_KEY_GRIP="$(cat "${GPG_SECRET_DIR}/key-grip.txt")"
    GPG_KEY_PASSPHRASE="$(cat "${GPG_SECRET_DIR}/passphrase.txt")"

    mkdir --parents "${GPG_CONF_DIR}"
    echo "allow-preset-passphrase" >"${GPG_CONF_DIR}/gpg-agent.conf"
    echo "use-agent" >"${GPG_CONF_DIR}/gpg.conf"
    chmod 600 "${GPG_CONF_DIR}/"*
    gpg-connect-agent "reloadagent" "/bye"

    echo "${GPG_KEY_PASSPHRASE}" | gpg --batch --import --passphrase-fd 0 --yes "${GPG_SECRET_DIR}/private.key"
    /usr/libexec/gpg-preset-passphrase --preset --passphrase "${GPG_KEY_PASSPHRASE}" "${GPG_KEY_GRIP}"
    gpg --import "${GPG_SECRET_DIR}/private.key"
    gpg --import-ownertrust "${GPG_SECRET_DIR}/trust-level.txt"

    echo "Committing changes"
    git config --global "commit.gpgsign" "true"
    git config --global "tag.gpgsign" "true"
    git config --global "user.name" "infra automata"
    git config --global "user.email" "${GPG_EMAIL}"
    git config --global "user.signingkey" "${GPG_KEY_ID}"

    git add .
    git status
    git diff HEAD
    git commit -a -m "Updating image ${IMAGE}"

    echo "Pushing commit"
    git push --set-upstream "origin" "$(git branch --show-current)"
fi

echo "Finished $(basename "${0}")"
