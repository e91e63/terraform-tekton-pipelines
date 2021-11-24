terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {
    name = "git-clone"
  })
}

module "main" {
  source = "../../../tekton/task"

  conf = {
    description = "git clone repo into workspace"
    name        = local.conf.name
    namespace   = local.conf.namespace
    spec = {
      params = [[
        {
          default     = "./"
          description = "dir to clone into"
          name        = local.conf.labels.context_path
        },
        {
          description = "git repo to clone"
          name        = local.conf.labels.git_repo_url
        },
      ]]
      steps = [[
        {
          "env" = [[
            {
              name  = "REPO_URL"
              value = "$(params.${local.conf.labels.git_repo_url})"
            },
          ]]
          image      = var.conf.images.alpine
          name       = local.conf.name
          script     = file("${path.module}/../scripts/git-clone.sh")
          workingDir = local.conf.working_dir
        },
      ]]
      workspaces = [[
        {
          name = local.conf.labels.git_repo_workspace
        },
      ]]
    }
  }
}
