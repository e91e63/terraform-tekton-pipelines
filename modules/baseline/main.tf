terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

locals {
  conf = defaults(
    # merge is used to set multiple label values
    merge(
      var.conf,
      { labels = merge(local.labels, var.conf.labels) },
    ),
    {
      webhooks = {
        subdomain = "webhooks"
      }
      working_dir = "$(workspaces.${local.labels.git_repo_workspace}.path)/$(params.${local.labels.context_path})"
  })

  # labels values shared across Tekton CRDs
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
    git_repo_code_name  = "git-repo-code-name"
    git_repo_code_url   = "git-repo-code-url"
    git_repo_infra      = "git-repo-infra"
    git_repo_infra_url  = "git-repo-infra-url"
    git_repo_url        = "git-repo-url"
    git_repo_workspace  = "git-repo-workspace"
    gpg_key             = "gpg-key"
    version_tag         = "version-tag"
    webhook_token       = "webhook-token"
  }
}

module "janitor" {
  source = "./janitor"

  conf = merge(
    local.conf,
    { service_accounts = module.service_accounts.info },
  )
}

module "secrets" {
  source = "./secrets"

  conf = local.conf
}

module "service_accounts" {
  source = "./service-accounts"

  conf = merge(
    local.conf,
    { secrets = module.secrets.info },
  )
}

module "task_build_kaniko" {
  source = "../tasks/build/kaniko"

  conf = local.conf
}

module "task_deploy_terragrunt" {
  source = "../tasks/deploy/terragrunt"

  conf = merge(
    local.conf,
    { secrets = module.secrets.info },
  )
}

module "task_git_clone" {
  source = "../tasks/git/clone"

  conf = local.conf
}
