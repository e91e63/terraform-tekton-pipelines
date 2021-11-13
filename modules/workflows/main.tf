locals {
  conf = merge(
    defaults(var.conf, {
      webhooks_subdomain = "webhooks"
    }),
    { labels = {
      age_keys_file       = "age-keys-file"
      context_path        = local.context_path
      context_path_code   = "context-path-code"
      context_path_infra  = "context-path-infra"
      docker_image        = "docker-image"
      docker_image_digest = "docker-image-digest"
      docker_image_url    = "docker-image-url"
      git_clone_code      = "git-clone-code"
      git_clone_infra     = "git-clone-infra"
      git_repo            = "git-repo"
      git_repo_url        = "git-repo-url"
      git_repo_workspace  = local.git_repo_workspace
      git_repo_code       = "git-repo-code"
      git_repo_code_url   = "git-repo-code-url"
      git_repo_infra      = "git-repo-infra"
      git_repo_infra_url  = "git-repo-infra-url"
      version_tag         = "version-tag"
      working_dir         = "$(workspace.${local.git_repo_workspace}.path)/$(params.${local.context_path})"
      webhook_token       = "webhook-token"
    } },
  )
  context_path       = "context-path"
  git_repo_workspace = "git-repo-workspace"
}

module "javascript" {
  source = "../javascript"

  conf = merge(
    local.conf,
    {
      tasks = {
        build     = module.task_build_kaniko.info.name
        deploy    = module.task_deploy_terragrunt.info.name
        git_clone = module.task_git_clone.info.name
      }
      secret_names     = module.secrets.info
      service_accounts = module.service_accounts.info
    }
  )
  domain_info = var.domain_info
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

module "task_build_kaniko" {
  source = "../tekton/tasks/build/kaniko"

  conf = local.conf
}

module "task_deploy_terragrunt" {
  source = "../tekton/tasks/deploy/terragrunt"

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

module "task_git_clone" {
  source = "../tekton/tasks/git/clone"

  conf = local.conf
}
