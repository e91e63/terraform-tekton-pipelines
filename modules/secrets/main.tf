resource "kubernetes_secret" "age_keys_file" {
  data = {
    "keys.txt" = base64decode(var.conf.secrets.age.keys_file_base64)
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "age-keys-file"
    namespace   = var.conf.namespace
  }
  type = "Opaque"
}

resource "kubernetes_secret" "docker_credentials" {
  data = {
    ".dockerconfigjson" = var.conf.secrets.docker.credentials_write
  }
  metadata {
    annotations = {
      "tekton.dev/docker-${var.conf.secrets.docker.server_url}" = var.conf.secrets.docker.server_url
    }
    labels    = {}
    name      = "${var.conf.secrets.docker.registry_name}-docker-secrets"
    namespace = var.conf.namespace
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "git_ssh_key" {
  data = {
    known_hosts      = var.conf.secrets.git.known_hosts
    "ssh-privatekey" = var.conf.secrets.git.private_key_pem
  }
  metadata {
    annotations = {
      "tekton.dev/git-${var.conf.secrets.git.domain}" = var.conf.secrets.git.domain
    }
    labels    = {}
    name      = "${var.conf.secrets.git.domain}-ssh-key"
    namespace = var.conf.namespace
  }
  type = "kubernetes.io/ssh-auth"
}

resource "kubernetes_secret" "terraform_remote_state" {
  data = {
    "AWS_ACCESS_KEY_ID"     = var.conf.secrets.terraform_remote_state.access_key_id,
    "AWS_SECRET_ACCESS_KEY" = var.conf.secrets.terraform_remote_state.secret_access_key,
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "digitalocean-spaces-secrets"
    namespace   = var.conf.namespace
  }
  type = "Opaque"
}
