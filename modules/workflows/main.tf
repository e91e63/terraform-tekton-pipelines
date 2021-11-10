locals {
  conf = merge(
    defaults(var.conf, {
      webhooks_subdomain = "webhooks"
      }
    )
  )
}

module "baseline" {
  source = "../baseline"

  conf = {
    credentials                   = local.conf.credentials
    namespace                     = local.conf.namespace
    triggers_service_account_name = local.conf.triggers_service_account_name
    workers_service_account_name  = local.conf.workers_service_account_name
  }
}

module "javascript" {
  source = "../javascript"

  conf = merge(
    local.conf,
    {
      secret_names = module.baseline.info.secret_names
      triggers = {
        service_account_name = module.baseline.info.service_account_names.triggers
      }
      workers = {
        service_account_name = module.baseline.info.service_account_names.workers
      }
    }
  )
  domain_info = var.domain_info
}
