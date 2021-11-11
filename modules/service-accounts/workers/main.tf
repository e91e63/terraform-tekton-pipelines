locals {
  conf = defaults(var.conf, {
    name = "tekton-workers"
  })
}

resource "kubernetes_service_account" "main" {
  metadata {
    annotations = {}
    labels      = {}
    name        = local.conf.name
    namespace   = local.conf.namespace
  }
  secret {
    name = var.conf.secret_names.docker_credentials
  }
  secret {
    name = var.conf.secret_names.git_ssh_key
  }
}
