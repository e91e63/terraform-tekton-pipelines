locals {
  conf = defaults(var.conf, {})
  # TODO: deal with optional runafter and kind
}

resource "kubernetes_manifest" "pipeline" {
  manifest = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      description = local.conf.description
      params      = local.conf.params
      resources   = local.conf.resources
      tasks       = local.conf.tasks
    }
  }
}
