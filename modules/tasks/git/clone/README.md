# Git Clone Task

This folder contains a [Terraform module](https://terraform.io/docs/language/modules/index.html) for creating a Tekton task that clones a Git repo. The repo is cloned into a Tekton workspace which is backed by a Kubernetes persistent volume. Other Tekton tasks that run with this workspace will have access to the cloned repo.
