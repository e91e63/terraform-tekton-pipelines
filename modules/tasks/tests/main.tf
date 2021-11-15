locals {
  conf = defaults(var.conf, {
    images = {
      dependencies = var.conf.images.default
      fmt          = var.conf.images.default
      lint         = var.conf.images.default
      tests_e2e    = var.conf.images.default
      tests_unit   = var.conf.images.default
      version_tag  = var.conf.images.default
    }
  })
}

module "main" {
  source = "../../tekton/task"

  conf = {
    description = "run tests on repo"
    name        = "${local.conf.name}-tests"
    namespace   = local.conf.namespace
    params = [
      {
        description = "repo directory where test scripts are run"
        name        = local.conf.labels.context_path
      },
    ]
    results = [
      {
        description = "version tag for build artifacts"
        name        = local.conf.labels.version_tag
      },
    ]
    steps = [
      {
        image      = local.conf.images.dependencies
        name       = "dependencies"
        script     = local.conf.scripts.dependencies
        workingDir = local.conf.working_dir
      },
      {
        image      = local.conf.images.fmt
        name       = "fmt"
        script     = local.conf.scripts.fmt
        workingDir = local.conf.working_dir
      },
      {
        image      = local.conf.images.lint
        name       = "lint"
        script     = local.conf.scripts.lint
        workingDir = local.conf.working_dir
      },
      {
        image      = local.conf.images.tests_unit
        name       = "tests-unit"
        script     = local.conf.scripts.tests_unit
        workingDir = local.conf.working_dir
      },
      {
        image      = local.conf.images.tests_e2e
        name       = "tests-e2e"
        script     = local.conf.scripts.tests_e2e
        workingDir = local.conf.working_dir
      },
      {
        env = [
          {
            name  = "RESULTS_PATH"
            value = "$(results.${local.conf.labels.version_tag}.path)"
          }
        ]
        image      = local.conf.images.version_tag
        name       = "version-tag"
        script     = local.conf.scripts.version_tag
        workingDir = local.conf.working_dir
      },
    ]
    workspaces = [
      {
        name = local.conf.labels.git_repo_workspace
      },
    ]
  }
}
