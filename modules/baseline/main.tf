module "triggers_service_account" {
  source = "./triggers-service-account"

  conf = {
    docker_secret_name = kubernetes_secret.docker.metadata[0].name
    git_secret_name    = kubernetes_secret.git.metadata[0].name
    name               = var.conf.triggers_service_account_name
    namespace          = var.conf.namespace
  }
}

module "workers_service_account" {
  source = "./workers-service-account"

  conf = {
    docker_secret_name = kubernetes_secret.docker.metadata[0].name
    git_secret_name    = kubernetes_secret.git.metadata[0].name
    name               = var.conf.workers_service_account_name
    namespace          = var.conf.namespace
  }
}

resource "kubernetes_secret" "age_keys_file" {
  data = {
    "keys.txt" = base64decode(var.conf.credentials.age.keys_file_base64)
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "age-keys-file"
    namespace   = var.conf.namespace
  }
  type = "Opaque"
}

resource "kubernetes_secret" "terraform_remote_state" {
  data = {
    "AWS_ACCESS_KEY_ID"     = var.conf.credentials.terraform_remote_state.access_key_id,
    "AWS_SECRET_ACCESS_KEY" = var.conf.credentials.terraform_remote_state.secret_access_key,
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "digitalocean-spaces-credentials"
    namespace   = var.conf.namespace
  }
  type = "Opaque"
}

resource "kubernetes_secret" "docker" {
  data = {
    ".dockerconfigjson" = var.conf.credentials.docker.credentials_write
  }
  metadata {
    annotations = {
      "tekton.dev/docker-${var.conf.credentials.docker.server_url}" = var.conf.credentials.docker.server_url
    }
    labels    = {}
    name      = "${var.conf.credentials.docker.registry_name}-docker-credentials"
    namespace = var.conf.namespace
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "git" {
  data = {
    known_hosts      = var.conf.credentials.git.known_hosts
    "ssh-privatekey" = var.conf.credentials.git.private_key_pem
  }
  metadata {
    annotations = {
      "tekton.dev/git-${var.conf.credentials.git.domain}" = var.conf.credentials.git.domain
    }
    labels    = {}
    name      = "${var.conf.credentials.git.domain}-ssh-key"
    namespace = var.conf.namespace
  }
  type = "kubernetes.io/ssh-auth"
}
