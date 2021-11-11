locals {
  # json de-encoding resolves diffs in kubernetes provider from list(object()) types
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1482
  # for loops remove null values
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove null values
    { triggers = [for trigger in var.conf.triggers : merge(
      { for k, v in trigger : k => v if v != null },
      { bindings = [for binding in trigger.bindings : merge(
        { for k, v in binding : k => v if v != null },
        { kind = binding.kind != null ? binding.kind : "TriggerBinding" }
      )] },
    )] },
  )))
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "EventListener"
    metadata = {
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      namespaceSelector  = {}
      resources          = {}
      serviceAccountName = local.conf.serviceAccountName
      triggers           = local.conf.triggers
    }
  }
}
