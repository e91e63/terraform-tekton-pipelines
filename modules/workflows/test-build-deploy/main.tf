locals {
  conf = defaults(var.conf, {
    pipeline_name = "${var.conf.name}-test-build-deploy"
  })
}

module "event_listener" {
  source = "../../tekton/event-listeners"

  conf = {
    name               = local.conf.pipeline_name
    namespace          = local.conf.namespace
    serviceAccountName = local.conf.service_accounts.triggers
    triggers = [
      {
        bindings = [
          {
            ref = module.trigger_binding.info.name
          },
        ]
        interceptors = [
          {
            params = [
              {
                name = "secretRef"
                value = {
                  secretKey  = local.conf.labels.webhook_token
                  secretName = kubernetes_secret.webhook_token.metadata[0].name
                }
              },
              {
                name  = "eventTypes"
                value = local.conf.interceptors.git.event_types
              }
            ]
            ref = {
              kind = "Interceptor"
              name = local.conf.interceptors.git.name
            }
          },
        ]
        name = local.conf.pipeline_name
        template = {
          ref = module.trigger_template.info.name
        }
      },
    ]
  }
}

module "pipeline" {
  source = "../../tekton/pipelines"

  conf = {
    description = "${local.conf.name} test, build, and deploy pipeline"
    name        = local.conf.pipeline_name
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.conf.labels.git_repo}.path)"
        description = "code context path"
        name        = local.conf.labels.context_path_code
        type        = "string"
      },
      {
        description = "terragrunt context path"
        name        = local.conf.labels.context_path_infra
        type        = "string"
      },
    ]
    resources = [
      {
        name = local.conf.labels.docker_image
        type = "image"
      },
      {
        name = local.conf.labels.git_repo_code
        type = "git"
      },
      {
        name = local.conf.labels.git_repo_infra
        type = "git"
      },
    ]
    tasks = [
      {
        name = local.conf.tasks.tests
        params = [
          {
            name  = local.conf.labels.context_path
            value = "$(params.${local.conf.labels.context_path_code})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.conf.labels.git_repo
              resource = local.conf.labels.git_repo_code
            },
          ]
        }
        taskRef = {
          name = local.conf.tasks.tests
        }
      },
      {
        name = local.conf.tasks.build
        params = [
          {
            name  = local.conf.labels.version_tag
            value = "$(tasks.${local.conf.tasks.tests}.results.${local.conf.labels.version_tag})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.conf.labels.git_repo
              resource = local.conf.labels.git_repo_code
            },
          ]
          "outputs" = [
            {
              name     = local.conf.labels.docker_image
              resource = local.conf.labels.docker_image
            },
          ]
        }
        "runAfter" = [
          local.conf.tasks.tests,
        ]
        taskRef = {
          name = local.conf.tasks.build
        }
      },
      {
        name = local.conf.tasks.deploy
        params = [
          {
            name  = local.conf.labels.context_path
            value = "$(params.${local.conf.labels.context_path_infra})"
          },
          {
            name  = local.conf.labels.docker_image_digest
            value = "$(tasks.${local.conf.tasks.build}.results.${local.conf.labels.docker_image_digest})"
          },
        ]
        resources = {
          inputs = [
            {
              name     = local.conf.labels.git_repo
              resource = local.conf.labels.git_repo_infra
            },
          ]
        }
        "runAfter" = [
          local.conf.tasks.build,
        ]
        taskRef = {
          name = local.conf.tasks.deploy
        }
      },
    ]
  }
}

module "trigger_binding" {
  source = "../../tekton/trigger-bindings"

  conf = {
    name      = local.conf.pipeline_name
    namespace = local.conf.namespace
    params = [
      {
        name  = local.conf.labels.context_path_infra
        value = "digitalocean/cddc39/services/todo"
        # value = "$(inputs.resources.git-repo.path)/digitalocean/cddc39/services/todo"
      },
      {
        name  = local.conf.labels.git_repo_code_url
        value = "$(body.repository.git_ssh_url)"
      },
      {
        name = local.conf.labels.git_repo_infra_url
        # value = "$(body.repository.git_ssh_url)x"
        value = "git@gitlab.com:dmikalova/infrastructure.git"
      },
      {
        name = local.conf.labels.docker_image_url
        # value = "$(body.repository.git_ssh_url)x"
        value = "registry.digitalocean.com/dmikalova/todo"
      },
    ]
  }
}

module "trigger_template" {
  source = "../../tekton/trigger-templates"

  conf = {
    name      = local.conf.pipeline_name
    namespace = local.conf.namespace
    params = [
      {
        description = "the ${local.conf.name} repo to build, test, and deploy"
        name        = local.conf.labels.git_repo_code_url
      },
      {
        description = "the infrastructure configuration repo to update for deploys"
        name        = local.conf.labels.git_repo_infra_url
      },
      {
        description = "the docker image url"
        name        = local.conf.labels.docker_image_url
      },
      {
        description = "terragrunt context path"
        name        = local.conf.labels.context_path_infra
      }
    ]
    resourcetemplates = [
      {
        kind = "PipelineRun"
        spec = {
          params = [
            {
              name  = local.conf.labels.context_path_infra
              value = "$(tt.params.${local.conf.labels.context_path_infra})"
            },
          ]
          pipelineRef = {
            name = module.pipeline.info.name
          }
          resources = [
            {
              name = local.conf.labels.docker_image
              resourceSpec = {
                params = [
                  {
                    name  = "url"
                    value = "$(tt.params.${local.conf.labels.docker_image_url})"
                  },
                ]
                type = "image"
              }
            },
            {
              name = local.conf.labels.git_repo_infra
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
                    value = "$(tt.params.${local.conf.labels.git_repo_infra_url})"
                  },
                ]
                type = "git"
              }
            },
            {
              name = local.conf.labels.git_repo_code
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
                    value = "$(tt.params.${local.conf.labels.git_repo_code_url})"
                  },
                ]
                type = "git"
              }
            },
          ]
          serviceAccountName = local.conf.service_accounts.workers
        }
      },
    ]
  }
}

module "webhook_ingress" {
  source = "git@gitlab.com:e91e63/terraform-kubernetes-manifests.git//modules/traefik/ingress-route"

  domain_info = var.domain_info
  conf = {
    # TODO: pass in the public middleware
    middlewares = []
    path        = "/${module.event_listener.info.name}"
    service = {
      name      = "el-${module.event_listener.info.name}"
      namespace = local.conf.namespace
      port      = 8080
    }
    subdomain = local.conf.webhooks_subdomain
  }
}

resource "kubernetes_secret" "webhook_token" {
  data = {
    (local.conf.labels.webhook_token) = random_password.webhook_token.result
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "${local.conf.name}-webhook-token"
    namespace   = local.conf.namespace
  }
  type = "Opaque"
}

resource "random_password" "webhook_token" {
  length  = 16
  special = true
}
