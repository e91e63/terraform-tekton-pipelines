locals {
  # TODO: write a provider that removes all null values
  # json de-encoding resolves diffs in kubernetes provider from list(object()) types
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1482
  # for loops remove null values
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove null values
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    { resources = { for k, v in var.conf.resources : k => v if v != null } },
    { steps = [for step in var.conf.steps : merge(
      # set default resources
      { resources = {} },
      { for k, v in step : k => v if v != null },
      { for k, v in step : k => [
        for env in step[k] : { for ek, ev in env : ek => ev if ev != null }
        ] if k == "env" && v != null
      },
    )] },
  )))
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = { for k, v in {
      description = local.conf.description
      params      = local.conf.params
      resources   = local.conf.resources
      results     = local.conf.results
      steps       = local.conf.steps
      volumes     = local.conf.volumes
    } : k => v if v != [] }
  }
}