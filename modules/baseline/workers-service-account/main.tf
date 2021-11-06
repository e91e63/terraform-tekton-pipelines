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
    name = var.conf.docker_secret_name
  }
  secret {
    name = var.conf.git_secret_name
  }
}
