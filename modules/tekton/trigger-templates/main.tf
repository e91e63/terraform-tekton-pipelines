locals {
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {
      resourcetemplates = {
        metadata = {
          generateName = "${var.conf.name}-$(uid)"
          namespace    = var.conf.namespace
        }
      }
    }),
    # remove null values
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    # { resourcetemplates = [for template in var.conf.resourcetemplates : merge(
    #   # Set defaults
    #   { metadata = {
    #     generateName = "${var.conf.name}-$(uid)"
    #     namespace    = var.conf.namespace
    #   } },
    # )] },
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
