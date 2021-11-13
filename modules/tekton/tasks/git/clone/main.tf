locals {
  conf = defaults(var.conf, {
    name = "git-clone"
  })
}

module "main" {
  source = "../../../../tekton/tasks"

  conf = {
    description = "git clone repo into workspace"
    name        = local.conf.name
    namespace   = local.conf.namespace
    params = [
      {
        description = "git repo to clone"
        name        = local.conf.labels.git_repo_url
      },
    ]
    steps = [
      {
        "env" = [
          {
            name  = "REPO_URL"
            value = "$(params.${local.conf.labels.git_repo_url})"
          },
        ]
        image      = var.conf.images.alpine
        name       = local.conf.name
        script     = file("${path.module}/../scripts/git-clone.sh")
        workingDir = local.conf.labels.working_dir
      },
    ]
    workspaces = [
      {
        name = local.conf.labels.git_repo_workspace
      },
    ]
  }
}
