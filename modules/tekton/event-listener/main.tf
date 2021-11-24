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
        namespaceSelector  = {}
        resources          = {}
        serviceAccountName = var.conf.spec.serviceAccountName
        triggers = [for trigger in flatten(var.conf.spec.triggers) : merge(
          { for k, v in trigger : k => v if v != null },
          { bindings = [for binding in flatten(trigger.bindings) : {
            kind = binding.kind != null ? binding.kind : "TriggerBinding"
            ref  = binding.ref
          }] },
          { interceptors = [for interceptor in flatten(trigger.interceptors) : {
            params = flatten([
              [for param in interceptor.params[0] : {
                name  = param.name
                value = flatten(param.value)
              }],
              interceptor.params[1],
            ])
            ref = interceptor.ref
          }] },
        )]
      }
    }
  )
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = local.conf.spec
  }
}
