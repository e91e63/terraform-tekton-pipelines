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

resource "kubernetes_service_account" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name      = local.conf.name
    namespace = local.conf.namespace
  }
  secret {
    name = var.conf.secrets.names.docker_credentials
  }
  secret {
    name = var.conf.secrets.names.git_ssh_key
  }
}
