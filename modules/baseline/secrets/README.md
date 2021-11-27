# Baseline Secrets

This folder contains [Terraform modules](https://www.terraform.io/docs/language/modules/index.html) for creating [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/). The module outputs secret names that can be passed into Kubernetes service accounts or Tekton tasks.

## Secrets

Included secrets:

- Age keys file for decrypting sops files embedded in Git repos
- Docker credentials for `docker pull` and `docker push` access to private registries.
- SSH key for `git clone` and `git push` on repos.
- GPG key for signing in `git commit`.
- Terraform remote state credentials for reading and writing to S3 compatible object stores.
