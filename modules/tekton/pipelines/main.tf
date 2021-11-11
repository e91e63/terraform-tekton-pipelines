locals {
  # json de-encoding resolves diffs in kubernetes provider from list(object()) types
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1482
  # for loops remove null values
  conf = jsondecode(jsonencode(merge(
    defaults(var.conf, {}),
    # remove null values
    { params = [for param in var.conf.params : {
      for k, v in param : k => v if v != null
    }] },
    { tasks = [for task in var.conf.tasks : merge(
      { for k, v in task : k => v if v != null },
      { resources = { for k, v in task.resources : k => v if v != null } },
      { taskRef = {
        # set default kind
        kind = task.taskRef.kind == null ? "Task" : task.taskRef.kind
        name = task.taskRef.name
      } },
    )] },
  )))
}

resource "kubernetes_manifest" "main" {
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
