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
    # remove null values
    { spec = {
      params = [for param in flatten(var.conf.spec.params) : {
        for k, v in param : k => v if v != null
      }]
      resourcetemplates = [for template in flatten(var.conf.spec.resourcetemplates) : merge(
        { apiVersion = "tekton.dev/v1beta1" },
        { for k, v in template : k => v if v != null },
        { spec = merge(
          { for k, v in template.spec : k => v if v != null },
          { params = flatten(template.spec.params) },
          { for k, v in template.spec : k => [
            for workspace in flatten(template.spec[k]) : {
              name = workspace.name
              volumeClaimTemplate = { spec = {
                accessModes = flatten(workspace.volumeClaimTemplate.spec.accessModes)
                resources   = workspace.volumeClaimTemplate.spec.resources
              } }
            }] if k == "workspaces" && v != null
          },
        ) }
      )]
      }
    },
  )
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = local.conf.spec
  }
}
