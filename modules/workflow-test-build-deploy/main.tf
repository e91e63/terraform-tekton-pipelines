variable "conf" {
  type = object({
    namespace = string
    tasks = object({
      build = object({
        images = object({
          kaniko = string
        })
      })
      deploy = object({
        images = object({
          terragrunt = string
        })
        secret_names = object({
          age_keys_file          = string
          terraform_remote_state = string
        })
      })
      test = object({
        images = object({
          default = string
        })
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
            image = var.conf.tasks.test.images.default
          }
          fmt = {
            image = var.conf.tasks.test.images.default
          }
          lint = {
            image = var.conf.tasks.test.images.default
          }
          unit = {
            image = var.conf.tasks.test.images.default
          }
          e2e = {
            image = var.conf.tasks.test.images.default
          }
          version_tag = {
            image = var.conf.tasks.test.images.default
          }
        }
      }
    }
  })
  labels = {
    age_keys_file = "age-keys-file"
    context_path  = "context-path"
    docker_image  = "docker-image"
    git_repo      = "git-repo"
    image_digest  = "image-digest"
    version_tag   = "version-tag"
  }
}

module "task_build" {
  source = "../tekton-task"

  conf = {
    description = "build ${local.conf.workflow_name} repo into a container"
    name        = "${local.conf.workflow_name}-build"
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.labels.git_repo}.path)"
        description = "kaniko build context"
        name        = local.labels.context_path
        type        = "string"
      },
      {
        description = "version tag for container artifact"
        name        = local.labels.version_tag
        type        = "string"
      },
    ]
    resources = {
      inputs = [
        {
          name = local.labels.git_repo
          type = "git"
        },
      ]
      outputs = [
        {
          name = local.labels.docker_image
          type = "image"
        },
      ]
    }
    results = [
      {
        name        = local.labels.image_digest
        description = "build image digest"
      }
    ]
    steps = [
      {
        args = [
          "--context=$(inputs.params.${local.labels.context_path})",
          "--destination=$(outputs.resources.${local.labels.docker_image}.url):$(inputs.params.${local.labels.version_tag})",
          "--dockerfile=$(inputs.params.${local.labels.context_path})/Dockerfile",
          "--image-name-tag-with-digest-file=$(results.${local.labels.image_digest}.path)",
          "--oci-layout-path=$(outputs.resources.${local.labels.docker_image}.path)"
        ]
        command = [
          "/kaniko/executor",
        ]
        "env" = [
          {
            name  = "DOCKER_CONFIG"
            value = "/tekton/home/.docker/"
          },
        ]
        image = var.conf.tasks.build.images.kaniko
        name  = "build"
      },
    ]
  }
}

module "task_deploy" {
  source = "../tekton-task"

  conf = {
    description = "deploy ${local.conf.workflow_name} container to infrastructure"
    name        = "${local.conf.workflow_name}-deploy"
    namespace   = local.conf.namespace
    params = [
      {
        description = "terragrunt context"
        name        = local.labels.context_path
        type        = "string"
      },
      {
        description = "docker image to deploy"
        name        = local.labels.docker_image
        type        = "string"
      },
    ]
    resources = {
      inputs = [
        {
          name = local.labels.git_repo
          type = "git"
        },
      ]
    }
    steps = [
      {
        "env" = [
          {
            name = "AWS_ACCESS_KEY_ID"
            valueFrom = {
              secretKeyRef = {
                name = var.conf.tasks.deploy.secret_names.terraform_remote_state
                key  = "AWS_ACCESS_KEY_ID"
              }
            }
          },
          {
            name = "AWS_SECRET_ACCESS_KEY"
            valueFrom = {
              secretKeyRef = {
                name = var.conf.tasks.deploy.secret_names.terraform_remote_state
                key  = "AWS_SECRET_ACCESS_KEY"
              }
            }
          },
          {
            name = "IMAGE"
            # TODO: split out git commit step
            value = "$(params.${local.labels.docker_image})"
          },
        ]
        image  = var.conf.tasks.deploy.images.terragrunt
        name   = "deploy"
        script = file("${path.module}/scripts/terragrunt-plan-apply.sh")
        volumeMounts = [
          {
            name      = local.labels.age_keys_file
            mountPath = "/root/.config/sops/age"
          }
        ]
        workingDir = "$(params.${local.labels.context_path})"
      },
    ]
    volumes = [
      {
        name = local.labels.age_keys_file
        secret = {
          secretName = local.conf.tasks.deploy.secret_names.age_keys_file
        }
      },
    ]
  }
}

module "task_test" {
  source = "../tekton-task"

  conf = {
    description = "run ${local.conf.workflow_name} tests on repo"
    name        = "${local.conf.workflow_name}-test"
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
          name = local.labels.git_repo
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
