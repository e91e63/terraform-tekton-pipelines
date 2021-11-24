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
          )] if k == "params" && v != null
        },
        { for k, v in var.conf.spec : k => [
          for result in flatten(var.conf.spec[k]) : merge(
            { for rk, rv in result : rk => rv if rv != null },
          )] if k == "results" && v != null
        },
        { for k, v in var.conf.spec : k => [
          for step in flatten(var.conf.spec.steps) : merge(
            # set default resources
            { resources = {} },
            { for k, v in step : k => v if v != null },
            { for k, v in step : k => [
              for arg in flatten(step[k]) : arg
            ] if k == "args" && v != null },
            { for k, v in step : k => [
              for env in flatten(step[k]) : {
                for ek, ev in env : ek => ev if ev != null
            }] if k == "env" && v != null },
            { for k, v in step : k => [
              for volumeMount in flatten(step[k]) : {
                for vk, vv in volumeMount : vk => vv if vv != null
            }] if k == "volumeMounts" && v != null },
          )
          ] if k == "steps" && v != null
        },
        { for k, v in var.conf.spec : k => [
          for volume in flatten(var.conf.spec[k]) : merge(
            { for vk, vv in volume : vk => vv if vv != null },
          )] if k == "volumes" && v != null
        },
        { for k, v in var.conf.spec : k => [
          for workspace in flatten(var.conf.spec[k]) : merge(
            { for wk, wv in workspace : wk => wv if wv != null },
          )] if k == "workspaces" && v != null
        },
      )
    },
  )
}

resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = local.conf.name
      namespace = local.conf.namespace
    }
    spec = local.conf.spec
  }
}
