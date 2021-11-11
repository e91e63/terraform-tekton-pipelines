locals {
  conf = merge(
    var.conf,
    { webhooks_subdomain = "webhooks" },
    { for k, v in var.conf : k => v if v != null },
  )
}

module "secrets" {
  source = "../secrets"

  conf = {
    namespace = local.conf.namespace
    secrets   = local.conf.secrets
  }
}

module "service_accounts" {
  source = "../service-accounts"

  conf = {
    namespace = local.conf.namespace
    secret_names = {
      docker_credentials = module.secrets.info.docker_credentials
      git_ssh_key        = module.secrets.info.git_ssh_key
    }
    service_accounts = local.conf.service_accounts
  }
}

module "javascript" {
  source = "../javascript"

  conf = merge(
    local.conf,
    {
      secret_names     = module.secrets.info
      service_accounts = module.service_accounts.info
    }
  )
  domain_info = var.domain_info
}
