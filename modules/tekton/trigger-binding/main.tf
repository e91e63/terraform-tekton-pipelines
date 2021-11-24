terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
  }
}

locals {
  conf = merge(
    defaults(var.conf, {}),
    {
      spec = {
        params = flatten(var.conf.spec.params)
      }
    }
  )
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = local.conf.spec
  }
}
