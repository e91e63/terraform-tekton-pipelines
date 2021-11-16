locals {
  conf = defaults(var.conf, {
    service_accounts = {
      janitor  = "tekton-janitor"
      triggers = "tekton-triggers"
      workers  = "tekton-workers"
    }
  })
}

module "janitor" {
  source = "./janitor"

  conf = {
    name      = local.conf.service_accounts.janitor
    namespace = local.conf.namespace
  }
}

module "triggers" {
  source = "./triggers"

  conf = {
    name      = local.conf.service_accounts.triggers
    namespace = local.conf.namespace
  }
}

module "workers" {
  source = "./workers"

  conf = {
    name      = local.conf.service_accounts.workers
    namespace = local.conf.namespace
    secrets   = local.conf.secrets
  }
}

terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}
