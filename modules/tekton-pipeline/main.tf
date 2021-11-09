locals {
  # json de-encoding resolves diffs in kubernetes provider from list(object()) types
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1482
  # for loops remove null values
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove optional keys from params
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    # set defaults for tasks
    { tasks = [for task in var.conf.tasks : merge(
      # remove optional keys from tasks
      { for k, v in task : k => v if v != null },
      # remove optional resources
      { resources = { for k, v in task.resources : k => v if v != null } },
      # add default task ref kind
      { taskRef = {
        kind = task.taskRef.kind == null ? "Task" : task.taskRef.kind
        name = task.taskRef.name
      } },
    )] },
  )))
}

output "test" {
  value = {
    description = local.conf.description
    params      = local.conf.params
    resources   = local.conf.resources
    tasks       = local.conf.tasks
  }
}

resource "kubernetes_manifest" "pipeline" {
  manifest = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = {
      description = local.conf.description
      params      = local.conf.params
      resources   = local.conf.resources
      tasks       = local.conf.tasks
    }
  }
}
