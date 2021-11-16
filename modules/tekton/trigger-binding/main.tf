locals {
  conf = jsondecode(jsonencode(defaults(var.conf, {})))
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      params = local.conf.params
    }
  }
}

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
