locals {
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove null values
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    { resourcetemplates = [for template in var.conf.resourcetemplates : merge(
      { for k, v in template : k => v if v != null },
      # Set defaults
      { apiVersion = template.apiVersion != null ? template.apiVersion : "tekton.dev/v1beta1" },
      { metadata = {
        generateName = "${var.conf.name}-$(uid)"
        namespace    = var.conf.namespace
      } },
      merge(
        { for k, v in template : k => v if v != null },
        { spec = merge(
          { for k, v in template.spec : k => v if v != null },
          { resources = [
            for resource in template.spec.resources : {
              for k, v in resource : k => v if v != null
            }
          ] },
        ) }
      ),
    )] },
  )))
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
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