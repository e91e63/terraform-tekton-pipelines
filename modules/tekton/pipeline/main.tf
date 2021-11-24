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
      spec = merge(
        # remove null values
        { for k, v in var.conf.spec : k => v if v != null },
        { for k, v in var.conf.spec : k => [
          for param in flatten(var.conf.spec[k]) : merge(
            # set default type
            { type = "string" },
            { for pk, pv in param : pk => pv if pv != null },
          )
        ] if k == "params" && v != null },
        { for k, v in var.conf.spec : k => [
          for task in flatten(var.conf.spec.tasks) : merge(
            { for k, v in task : k => v if v != null },
            { for k, v in task : k => [
              for param in flatten(task[k]) : {
                for pk, pv in param : pk => pv if pv != null
              }
            ] if k == "params" && v != null },
            { for k, v in task : k => flatten(v) if k == "runAfter" && v != null },
            { taskRef = {
              # set default kind
              kind = task.taskRef.kind == null ? "Task" : task.taskRef.kind
              name = task.taskRef.name
            } },
            { for k, v in task : k => [
              for workspace in flatten(task[k]) : {
                for wk, wv in workspace : wk => wv if wv != null
              }
            ] if k == "workspaces" && v != null },
          )
        ] if k == "tasks" && v != null },
        { for k, v in var.conf.spec : k => [
          for workspace in flatten(var.conf.spec[k]) : {
            for wk, wv in workspace : wk => wv if wv != null
          }
        ] if k == "workspaces" && v != null },
      )
    },
  )
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = local.conf.spec
  }
}
