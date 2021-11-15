locals {
  conf = defaults(merge(
    var.conf,
    { labels = merge(local.labels, var.conf.labels) },
    ),
    {
      webhooks = {
        subdomain = "webhooks"
      }
      working_dir = "$(workspaces.${local.labels.git_repo_workspace}.path)/$(params.${local.labels.context_path})"
  })

  # labels used in tasks and pipelines
  labels = {
    age_keys_file       = "age-keys-file"
    context_path        = "context-path"
    context_path_code   = "context-path-code"
    context_path_infra  = "context-path-infra"
    docker_image        = "docker-image"
    docker_image_digest = "docker-image-digest"
    docker_image_url    = "docker-image-url"
    git_clone_code      = "git-clone-code"
    git_clone_infra     = "git-clone-infra"
    git_repo            = "git-repo"
    git_repo_code       = "git-repo-code"
    git_repo_code_url   = "git-repo-code-url"
    git_repo_infra      = "git-repo-infra"
    git_repo_infra_url  = "git-repo-infra-url"
    git_repo_url        = "git-repo-url"
    git_repo_workspace  = "git-repo-workspace"
    version_tag         = "version-tag"
    webhook_token       = "webhook-token"
  }
}

module "janitor" {
  source = "../tekton/janitor"

  conf = merge(local.conf, {
    service_accounts = module.service_accounts.info
  })
}

module "javascript" {
  source = "../javascript"

  conf = merge(local.conf, {
    tasks = {
      build     = module.task_build_kaniko.info.name
      deploy    = module.task_deploy_terragrunt.info.name
      git_clone = module.task_git_clone.info.name
    }
    secret_names     = module.secrets.info
    service_accounts = module.service_accounts.info
  })
  domain_info = var.domain_info
}

module "secrets" {
  source = "../secrets"

  conf = local.conf
}

module "service_accounts" {
  source = "../service-accounts"

  conf = merge(local.conf, {
    secret_names = module.secrets.info
  })
}

module "task_build_kaniko" {
  source = "../tekton/tasks/build/kaniko"

  conf = local.conf
}

module "task_deploy_terragrunt" {
  source = "../tekton/tasks/deploy/terragrunt"

  conf = merge(local.conf, {
    secret_names = module.secrets.info
  })
}

module "task_git_clone" {
  source = "../tekton/tasks/git/clone"

  conf = local.conf
}

terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}