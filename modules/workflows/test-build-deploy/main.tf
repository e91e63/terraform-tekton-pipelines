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
        description = "code context path"
        name        = local.conf.labels.context_path_code
      },
      {
        description = "infra context path"
        name        = local.conf.labels.context_path_infra
      },
      {
        description = "docker image url"
        name        = local.conf.labels.docker_image_url
      },
      {
        description = "git code repo url"
        name        = local.conf.labels.git_repo_code_url
      },
      {
        description = "git infra repo url"
        name        = local.conf.labels.git_repo_infra_url
      },
    ]
    tasks = [
      {
        name = local.conf.labels.git_clone_code
        params = [
          {
            name  = local.conf.labels.git_repo_url
            value = "$(params.${local.conf.labels.git_repo_code_url})"
          },
        ]
        taskRef = {
          name = local.conf.tasks.git_clone
        }
        workspaces = [
          {
            name      = local.conf.labels.git_repo_workspace
            workspace = local.conf.labels.git_repo_workspace
          },
        ]
      },
      {
        name = local.conf.tasks.tests
        params = [
          {
            name  = local.conf.labels.context_path
            value = "$(params.${local.conf.labels.context_path_code})"
          },
        ]
        runAfter = [
          local.conf.labels.git_clone_code,
        ]
        taskRef = {
          name = local.conf.tasks.tests
        }
        workspaces = [
          {
            name      = local.conf.labels.git_repo_workspace
            workspace = local.conf.labels.git_repo_workspace
          },
        ]
      },
      {
        name = local.conf.tasks.build
        params = [
          {
            name  = local.conf.labels.context_path
            value = "$(params.${local.conf.labels.context_path_code})"
          },
          {
            name  = local.conf.labels.docker_image_url
            value = "$(params.${local.conf.labels.docker_image_url})"
          },
          {
            name  = local.conf.labels.version_tag
            value = "$(tasks.${local.conf.tasks.tests}.results.${local.conf.labels.version_tag})"
          },
        ]
        runAfter = [
          local.conf.tasks.tests,
        ]
        taskRef = {
          name = local.conf.tasks.build
        }
        workspaces = [
          {
            name      = local.conf.labels.git_repo_workspace
            workspace = local.conf.labels.git_repo_workspace
          },
        ]
      },
      {
        name = local.conf.labels.git_clone_infra
        params = [
          {
            name  = local.conf.labels.git_repo_url
            value = "$(params.${local.conf.labels.git_repo_infra_url})"
          },
        ]
        runAfter = [
          local.conf.tasks.build,
        ]
        taskRef = {
          name = local.conf.tasks.git_clone
        }
        workspaces = [
          {
            name      = local.conf.labels.git_repo_workspace
            workspace = local.conf.labels.git_repo_workspace
          },
        ]
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
        runAfter = [
          local.conf.labels.git_clone_infra,
        ]
        taskRef = {
          name = local.conf.tasks.deploy
        }
        workspaces = [
          {
            name      = local.conf.labels.git_repo_workspace
            workspace = local.conf.labels.git_repo_workspace
          },
        ]
      },
    ]
    workspaces = [
      { name = local.conf.labels.git_repo_workspace },
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
        name  = local.conf.labels.context_path_code
        value = "$(body.project.name)"
      },
      {
        name  = local.conf.labels.context_path_infra
        value = "infrastructure/digitalocean/$(body.project.namespace)/services/$(body.project.name)"
      },
      {
        name  = local.conf.labels.docker_image_url
        value = "registry.digitalocean.com/dmikalova/$(body.project.namespace)/$(body.project.name)"
      },
      {
        name  = local.conf.labels.git_repo_code_url
        value = "$(body.project.git_ssh_url)"
      },
      {
        name  = local.conf.labels.git_repo_infra_url
        value = local.conf.bindings.git_repo_infra_url
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
        description = "code context path"
        name        = local.conf.labels.context_path_code
      },
      {
        description = "infra context path"
        name        = local.conf.labels.context_path_infra
      },
      {
        description = "docker image url"
        name        = local.conf.labels.docker_image_url
      },
      {
        description = "${local.conf.name} repo to build, test, and deploy"
        name        = local.conf.labels.git_repo_code_url
      },
      {
        description = "infrastructure configuration repo to update for deploys"
        name        = local.conf.labels.git_repo_infra_url
      },
    ]
    resourcetemplates = [
      {
        kind = "PipelineRun"
        spec = {
          params = [
            {
              name  = local.conf.labels.context_path_code
              value = "$(tt.params.${local.conf.labels.context_path_code})"
            },
            {
              name  = local.conf.labels.context_path_infra
              value = "$(tt.params.${local.conf.labels.context_path_infra})"
            },
            {
              name  = local.conf.labels.docker_image_url
              value = "$(tt.params.${local.conf.labels.docker_image_url})"
            },
            {
              name  = local.conf.labels.git_repo_code_url
              value = "$(tt.params.${local.conf.labels.git_repo_code_url})"
            },
            {
              name  = local.conf.labels.git_repo_infra_url
              value = "$(tt.params.${local.conf.labels.git_repo_infra_url})"
            },
          ]
          pipelineRef = {
            name = module.pipeline.info.name
          }
          serviceAccountName = local.conf.service_accounts.workers
          workspaces = [
            {
              name = local.conf.labels.git_repo_workspace
              volumeClaimTemplate = {
                spec = {
                  accessModes = [
                    "ReadWriteOnce"
                  ]
                  resources = {
                    requests = {
                      storage = "1Gi"
                    }
                  }
                }
              }
            },
          ]
        }
      },
    ]
  }
}

module "webhook_ingress" {
  source = "git@gitlab.com:e91e63/terraform-kubernetes-manifests.git//modules/traefik/ingress-route"

  domain_info = var.domain_info
  conf = {
    middlewares = local.conf.webhooks.middlewares
    path        = "/${module.event_listener.info.name}"
    service = {
      name      = "el-${module.event_listener.info.name}"
      namespace = local.conf.namespace
      port      = 8080
    }
    subdomain = local.conf.webhooks.subdomain
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

terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
  required_version = "~> 1"
}
