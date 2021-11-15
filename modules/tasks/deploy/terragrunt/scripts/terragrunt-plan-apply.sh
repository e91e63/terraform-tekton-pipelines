#!/bin/sh
set -eu
if [ "${DEBUG:=}" = true ]; then set -x; fi

echo "Starting $(basename "${0}")"

echo "terragrunt init"
terragrunt init

echo "terragrunt plan"
terragrunt plan -out "terraform.plan"

echo "terragrunt apply"
terragrunt apply "terraform.plan"

echo "Finished $(basename "${0}")"
