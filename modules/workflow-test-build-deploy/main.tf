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
    age_keys_file      = "age-keys-file"
    context_path       = "context-path"
    context_path_code  = "context-path-code"
    context_path_infra = "context-path-infra"
    docker_image       = "docker-image"
    docker_image_url   = "docker-image-url"
    git_repo           = "git-repo"
    git_repo_code      = "git-repo-code"
    git_repo_code_url  = "git-repo-code-url"
    git_repo_infra     = "git-repo-infra"
    git_repo_infra_url = "git-repo-infra-url"
    image_digest       = "image-digest"
    pipeline_label     = "${local.conf.workflow_name}-test-build-deploy"
    version_tag        = "version-tag"
  }
}

module "pipeline" {
  source = "../tekton-pipeline"

  conf = {
    description = "${local.conf.workflow_name} test, build, and deploy pipeline"
    name        = local.labels.pipeline_label
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.labels.git_repo}.path)"
        description = "code context path"
        name        = local.labels.context_path_code
        type        = "string"
      },
      {
        description = "terragrunt context path"
        name        = local.labels.context_path_infra
        type        = "string"
      },
    ]
    resources = [
      {
        name = local.labels.docker_image
        type = "image"
      },
      {
        name = local.labels.git_repo_code
        type = "git"
      },
      {
        name = local.labels.git_repo_infra
        type = "git"
      },
    ]
    tasks = [
      {
        name = module.task_tests.info.name
        params = [
          {
            name  = local.labels.context_path
            value = "$(params.${local.labels.context_path_code})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.labels.git_repo
              resource = local.labels.git_repo_code
            },
          ]
        }
        taskRef = {
          name = module.task_tests.info.name
        }
      },
      {
        name = module.task_build.info.name
        params = [
          {
            name  = local.labels.version_tag
            value = "$(tasks.${module.task_tests.info.name}.results.${local.labels.version_tag})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.labels.git_repo
              resource = local.labels.git_repo_code
            },
          ]
          "outputs" = [
            {
              name     = local.labels.docker_image
              resource = local.labels.docker_image
            },
          ]
        }
        "runAfter" = [
          module.task_tests.info.name,
        ]
        taskRef = {
          name = module.task_build.info.name
        }
      },
      {
        name = module.task_deploy.info.name
        params = [
          {
            name  = local.labels.context_path
            value = "$(params.${local.labels.context_path_infra})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.labels.git_repo
              resource = local.labels.git_repo_infra
            },
          ]
        }
        "runAfter" = [
          module.task_build.info.name,
        ]
        taskRef = {
          name = module.task_build.info.name
        }
      },
    ]
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
        description = "kaniko build context path"
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

module "task_tests" {
  source = "../tekton-task"

  conf = {
    description = "run ${local.conf.workflow_name} tests on repo"
    name        = "${local.conf.workflow_name}-tests"
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

module "trigger_template" {
  source = "../tekton-trigger-template"

  conf = {
    name      = local.labels.pipeline_label
    namespace = local.conf.namespace
    params = [
      {
        description = "the ${local.conf.workflow_name} repo to build, test, and deploy"
        name        = local.labels.git_repo_code_url
      },
      {
        description = "the infrastructure configuration repo to update for deploys"
        name        = local.labels.git_repo_infra_url
      },
      {
        description = "the docker image url"
        name        = local.labels.docker_image_url
      },
    ]
    resourcetemplates = [
      {
        kind = "PipelineRun"
        spec = {
          pipelineRef = {
            name = module.pipeline.info.name
          }
          resources = [
            {
              name = local.labels.docker_image_url
              resourceSpec = {
                params = [
                  {
                    name  = "url"
                    value = "$(tt.params.${local.labels.docker_image_url})"
                  },
                ]
                type = "image"
              }
            },
            {
              name = local.labels.git_repo_infra
              resourceSpec = {
                params = [
                  {
                    name  = "refspec"
                    value = "refs/heads/main:refs/heads/main"
                  },
                  {
                    name  = "revision"
                    value = "main"
                  },
                  {
                    name  = "url"
                    value = "$(tt.params.${local.labels.git_repo_infra_url})"
                  },
                ]
                type = "git"
              }
            },
            {
              name = local.labels.git_repo_code
              resourceSpec = {
                params = [
                  {
                    name  = "refspec"
                    value = "refs/heads/main:refs/heads/main"
                  },
                  {
                    name  = "revision"
                    value = "main"
                  },
                  {
                    name  = "url"
                    value = "$(tt.params.${local.labels.git_repo_code_url})"
                  },
                ]
                type = "git"
              }
            },
          ]
          serviceAccountName = local.conf.workers.service_account_name
        }
      },
    ]
  }
}

output "test" {
  value = module.trigger_template.test
}
