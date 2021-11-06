variable "conf" {
  type = object({
    namespace = string
    tasks = object({
      test = object({
        image_default = string
        steps = object({
          dependencies = object({
            image  = optional(string)
            script = string
          })
          fmt = object({
            image  = optional(string)
            script = string
          })
          lint = object({
            image  = optional(string)
            script = string
          })
          unit = object({
            image  = optional(string)
            script = string
          })
          e2e = object({
            image  = optional(string)
            script = string
          })
          version_tag = object({
            image  = optional(string)
            script = string
          })
        })
      })
    })
    workflow_name = string
  })
}

locals {
  conf = defaults(var.conf, {
    tasks = {
      test = {
        steps = {
          dependencies = {
            image = var.conf.tasks.test.image_default
          }
          fmt = {
            image = var.conf.tasks.test.image_default
          }
          lint = {
            image = var.conf.tasks.test.image_default
          }
          unit = {
            image = var.conf.tasks.test.image_default
          }
          e2e = {
            image = var.conf.tasks.test.image_default
          }
          version_tag = {
            image = var.conf.tasks.test.image_default
          }
        }
      }
    }
  })
  labels = {
    context_path = "context-path"
    git_repo     = "git-repo"
    version_tag  = "version-tag"
  }
}

module "task_test" {
  source = "../tekton-task"

  conf = {
    description = "run ${local.conf.workflow_name} tests on repo"
    name        = "${local.conf.workflow_name}-task-test"
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.labels.git_repo}.path)"
        description = "repo directory where test scripts are run"
        name        = local.labels.context_path
        type        = "string"
      },
    ]
    resources = {
      inputs = [
        {
          name = "${local.labels.git_repo}"
          type = "git"
        },
      ]
    }
    results = [
      {
        name        = local.labels.version_tag
        description = "version tag for build artifacts"
      },
    ]
    steps = [
      {
        image      = local.conf.tasks.test.steps.dependencies.image
        name       = "${local.conf.workflow_name}-dependencies"
        script     = local.conf.tasks.test.steps.dependencies.script
        workingDir = "$(params.${local.labels.context_path})"
      },
      {
        image      = local.conf.tasks.test.steps.fmt.image
        name       = "${local.conf.workflow_name}-fmt"
        script     = local.conf.tasks.test.steps.fmt.script
        workingDir = "$(params.${local.labels.context_path})"
      },
      {
        image      = local.conf.tasks.test.steps.lint.image
        name       = "${local.conf.workflow_name}-lint"
        script     = local.conf.tasks.test.steps.lint.script
        workingDir = "$(params.${local.labels.context_path})"
      },
      {
        image      = local.conf.tasks.test.steps.unit.image
        name       = "${local.conf.workflow_name}-unit"
        script     = local.conf.tasks.test.steps.unit.script
        workingDir = "$(params.${local.labels.context_path})"
      },
      {
        image      = local.conf.tasks.test.steps.e2e.image
        name       = "${local.conf.workflow_name}-e2e"
        script     = local.conf.tasks.test.steps.e2e.script
        workingDir = "$(params.${local.labels.context_path})"
      },
      {
        env = [
          {
            name  = "RESULTS_PATH"
            value = "$(results.${local.labels.version_tag}.path)"
          }
        ]
        image      = local.conf.tasks.test.steps.version_tag.image
        name       = "${local.conf.workflow_name}-version-tag"
        script     = local.conf.tasks.test.steps.version_tag.script
        workingDir = "$(params.${local.labels.context_path})"
      },
    ]
  }
}
