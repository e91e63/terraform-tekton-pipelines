locals {
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove null values
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    # Set default values
    { resourcetemplates = [for template in var.conf.resourcetemplates : merge(
      { for k, v in template : k => v if v != null },
      {
        apiVersion = "tekton.dev/v1beta1"
      },
    )] },
  )))
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      params            = local.conf.params
      resourcetemplates = local.conf.resourcetemplates
    }
  }
}
