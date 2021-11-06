variable "conf" {
  type = object({
    description = string
    name        = string
    namespace   = string
    params = list(object({
      default     = optional(string)
      description = string
      name        = string
      type        = string
    }))
    resources = optional(object({
      inputs = optional(list(object({
        name = string
        type = string
      })))
      outputs = optional(list(object({
        name = string
        type = string
      })))
    }))
    results = optional(list(object({
      name        = string
      description = string
    })))
    steps = list(object({
      args    = optional(list(string))
      command = optional(list(string))
      env = optional(list(object({
        name  = string
        value = string
      })))
      image = string
      name  = string
      resources = optional(object({
        limits = optional(object({
          cpu    = string
          memory = string
        }))
        requests = optional(object({
          cpu    = string
          memory = string
        }))
      }))
      script     = optional(string)
      workingDir = string
    }))
  })
}

locals {
  conf = merge(
    defaults(var.conf, {}),
    { for k, v in var.conf : k => v if v != null },
    { resources = { for k, v in var.conf.resources : k => v if v != null } },
    # { resources = { inputs = [
    #   {
    #     name = "git-repo"
    #     type = "git"
    #   },
    # ] } },
    { steps = [for step in var.conf.steps : merge(
      { resources = {} },
      { for k, v in step : k => v if v != null },
    )] },
  )
}

resource "kubernetes_manifest" "task" {
  manifest = jsondecode(jsonencode({
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      description = local.conf.description
      params      = local.conf.params
      resources   = local.conf.resources
      results     = local.conf.results
      steps       = local.conf.steps
    }
  }))
}
