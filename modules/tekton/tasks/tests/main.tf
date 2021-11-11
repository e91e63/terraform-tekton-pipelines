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
  source = "../"

  conf = {
    description = "run tests on repo"
    name        = "${local.conf.name}-tests"
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.conf.labels.git_repo}.path)"
        description = "repo directory where test scripts are run"
        name        = local.conf.labels.context_path
        type        = "string"
      },
    ]
    resources = {
      inputs = [
        {
          name = local.conf.labels.git_repo
          type = "git"
        },
      ]
    }
    results = [
      {
        name        = local.conf.labels.version_tag
        description = "version tag for build artifacts"
      },
    ]
    steps = [
      {
        image      = local.conf.images.dependencies
        name       = "dependencies"
        script     = local.conf.scripts.dependencies
        workingDir = "$(params.${local.conf.labels.context_path})"
      },
      {
        image      = local.conf.images.fmt
        name       = "fmt"
        script     = local.conf.scripts.fmt
        workingDir = "$(params.${local.conf.labels.context_path})"
      },
      {
        image      = local.conf.images.lint
        name       = "lint"
        script     = local.conf.scripts.lint
        workingDir = "$(params.${local.conf.labels.context_path})"
      },
      {
        image      = local.conf.images.tests_unit
        name       = "tests-unit"
        script     = local.conf.scripts.tests_unit
        workingDir = "$(params.${local.conf.labels.context_path})"
      },
      {
        image      = local.conf.images.tests_e2e
        name       = "tests-e2e"
        script     = local.conf.scripts.tests_e2e
        workingDir = "$(params.${local.conf.labels.context_path})"
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
        workingDir = "$(params.${local.conf.labels.context_path})"
      },
    ]
  }
}
