terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
  }
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {})
}

resource "kubernetes_secret" "age_keys_file" {
  data = {
    "keys.txt" = base64decode(local.conf.secrets.data.age.keys_file_base64)
  }
  immutable = false
  metadata {
    annotations = {}
    labels      = {}
    name        = "age-keys-file"
    namespace   = local.conf.namespace
  }
  type = "Opaque"
}

resource "kubernetes_secret" "docker_credentials" {
  data = {
    ".dockerconfigjson" = local.conf.secrets.data.docker.credentials_write
  }
  immutable = false
  metadata {
    annotations = {
      "tekton.dev/docker-${local.conf.secrets.data.docker.server_url}" = local.conf.secrets.data.docker.server_url
    }
    labels    = {}
    name      = "${local.conf.secrets.data.docker.server_url}-credentials"
    namespace = local.conf.namespace
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "git_ssh_key" {
  data = {
    known_hosts      = local.conf.secrets.data.git_ssh_key.known_hosts
    "ssh-privatekey" = base64decode(local.conf.secrets.data.git_ssh_key.private_key_base64)
  }
  immutable = false
  metadata {
    annotations = {
      "tekton.dev/git-${local.conf.secrets.data.git_ssh_key.domain}" = local.conf.secrets.data.git_ssh_key.domain
    }
    labels    = {}
    name      = "${local.conf.secrets.data.git_ssh_key.domain}-ssh-key"
    namespace = local.conf.namespace
  }
  type = "kubernetes.io/ssh-auth"
}

resource "kubernetes_secret" "gpg_key" {
  data = {
    "email.txt"       = local.conf.secrets.data.gpg.email
    "key-grip.txt"    = local.conf.secrets.data.gpg.key_grip
    "key-id.txt"      = local.conf.secrets.data.gpg.key_id
    "passphrase.txt"  = local.conf.secrets.data.gpg.passphrase
    "private.key"     = base64decode(local.conf.secrets.data.gpg.private_key_base64)
    "trust-level.txt" = base64decode(local.conf.secrets.data.gpg.trust_level_base64)
  }
  immutable = false
  metadata {
    annotations = {}
    labels      = {}
    name        = "gpg-key"
    namespace   = local.conf.namespace
  }
  type = "Opaque"
}

resource "kubernetes_secret" "terraform_remote_state" {
  data = {
    "AWS_ACCESS_KEY_ID"     = local.conf.secrets.data.terraform_remote_state.access_key_id,
    "AWS_SECRET_ACCESS_KEY" = local.conf.secrets.data.terraform_remote_state.secret_access_key,
  }
  immutable = false
  metadata {
    annotations = {}
    labels      = {}
    name        = "digitalocean-spaces-secrets"
    namespace   = local.conf.namespace
  }
  type = "Opaque"
}
