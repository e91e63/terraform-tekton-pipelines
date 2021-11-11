locals {
  conf = merge(
    defaults(var.conf, {
      webhooks_subdomain = "webhooks"
    }),
    { labels = {
      age_keys_file       = "age-keys-file"
      context_path        = "context-path"
      context_path_code   = "context-path-code"
      context_path_infra  = "context-path-infra"
      docker_image        = "docker-image"
      docker_image_digest = "docker-image-digest"
      docker_image_url    = "docker-image-url"
      git_repo            = "git-repo"
      git_repo_code       = "git-repo-code"
      git_repo_code_url   = "git-repo-code-url"
      git_repo_infra      = "git-repo-infra"
      git_repo_infra_url  = "git-repo-infra-url"
      version_tag         = "version-tag"
      webhook_token       = "webhook-token"
    } },
  )
}

module "javascript" {
  source = "../javascript"

  conf = merge(
    local.conf,
    {
      tasks = {
        build  = module.kaniko_build.info.name
        deploy = module.terragrunt_deploy.info.name
      }
      secret_names     = module.secrets.info
      service_accounts = module.service_accounts.info
    }
  )
  domain_info = var.domain_info
}

module "kaniko_build" {
  source = "../kaniko/build"

  conf = local.conf
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

module "terragrunt_deploy" {
  source = "../terragrunt/deploy"

  conf = merge(
    local.conf,
    {
      secret_names = {
        age_keys_file          = module.secrets.info.age_keys_file
        terraform_remote_state = module.secrets.info.terraform_remote_state
      }
    }
  )
}
