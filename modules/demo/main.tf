resource "kubernetes_manifest" "task_echo_hello_world" {
  depends_on = [kubernetes_namespace.tekton_workers]

  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "echo-hello-world"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      steps = [
        {
          args = [
            "HelloWorld",
          ]
          command = [
            "echo",
          ]
          image     = "ubuntu"
          name      = "echo"
          resources = {}
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "taskrun_echo_hello_world_task_run" {
  depends_on = [kubernetes_namespace.tekton_workers]
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "TaskRun"
    metadata = {
      annotations = {
        "pipeline.tekton.dev/release" = "f8c2eea"
      }
      labels = {
        "app.kubernetes.io/managed-by" = "tekton-pipelines"
        "tekton.dev/task"              = "echo-hello-world"
      }
      name      = "echo-hello-world-task-run"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      serviceAccountName = kubernetes_service_account.main.metadata[0].name
      taskRef = {
        kind = "Task"
        name = "echo-hello-world"
      }
      timeout = "1h0m0s"
    }
  }
}

resource "kubernetes_secret" "gitlab" {
  metadata {
    annotations = {
      "tekton.dev/git-${var.git_conf.domain}" = var.git_conf.domain
    }
    name      = "${var.git_conf.domain}-deploy-key"
    namespace = kubernetes_namespace.tekton_workers.metadata[0].name
  }

  data = {
    known_hosts      = file("known-hosts-${var.git_conf.domain}.txt")
    "ssh-privatekey" = var.git_conf.private_key_pem
  }

  type = "kubernetes.io/ssh-auth"
}

resource "digitalocean_container_registry_docker_credentials" "main" {
  registry_name = var.container_registry_info.name
  write         = true
}

data "digitalocean_container_registry" "main" {
  name = var.container_registry_info.name
}

resource "kubernetes_secret" "docker" {
  metadata {
    annotations = {
      "tekton.dev/docker-registry.digitalocean.com" = "registrydigitalocean.com"
    }
    name      = "docker-registry-${var.container_registry_info.name}-credentials"
    namespace = kubernetes_namespace.tekton_workers.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.main.docker_credentials
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_service_account" "main" {
  metadata {
    name      = "tekton-worker"
    namespace = kubernetes_namespace.tekton_workers.metadata[0].name
  }
  secret {
    name = kubernetes_secret.gitlab.metadata[0].name
  }
  secret {
    name = kubernetes_secret.docker.metadata[0].name
  }
}

resource "kubernetes_namespace" "tekton_workers" {
  metadata {
    labels = {
      "app.kubernetes.io/instance" = "default"
      "app.kubernetes.io/part-of"  = "tekton-workers"
    }
    name = "tekton-workers"
  }
}

resource "kubernetes_manifest" "pipeline_resource_git_repo_cddc39_todo" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "PipelineResource"
    metadata = {
      name      = "git-repo-cddc39-todo"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      params = [
        {
          name  = "revision"
          value = "main"
        },
        {
          name  = "url"
          value = "git@gitlab.com:cddc39/todo.git"
        },
      ]
      type = "git"
    }
  }
}

resource "kubernetes_manifest" "pipeline_resource_docker_todo" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "PipelineResource"
    metadata = {
      name      = "todo-image"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      params = [
        {
          name  = "url"
          value = "registry.digitalocean.com/dmikalova/todo"
        },
      ]
      type = "image"
    }
  }
}

resource "kubernetes_manifest" "task_docker_build" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "docker-build"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      description = "Build Docker image with Kaniko"
      params = [
        {
          default     = "$(resources.inputs.git-repo.path)/Dockerfile"
          description = "The path to the dockerfile to build"
          name        = "dockerfile_path"
          type        = "string"
        },
        {
          default     = "$(resources.inputs.git-repo.path)"
          description = "The build context used by Kaniko (https://github.com/GoogleContainerTools/kaniko#kaniko-build-contexts)"
          name        = "context_path"
          type        = "string"
        },
        {
          description = "The Docker image version tag"
          name        = "version_tag"
          type        = "string"
        },
      ]
      resources = {
        inputs = [
          {
            name = "git-repo"
            type = "git"
          },
        ]
        outputs = [
          {
            name = "docker-image"
            type = "image"
          },
        ]
      }
      steps = [
        {
          args = [
            "--dockerfile=$(inputs.params.dockerfile_path)",
            "--destination=$(outputs.resources.docker-image.url):$(inputs.params.version_tag)",
            "--context=$(inputs.params.context_path)",
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
          image     = "gcr.io/kaniko-project/executor:v1.6.0"
          name      = "container-build"
          resources = {}
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "task_npm_tests" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "npm-tests"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      description = "Run NPM tests on repo"
      params = [
        {
          default     = "node:16-alpine"
          description = "Node image to run in"
          name        = "container_image"
          type        = "string"
        },
        {
          default     = "$(resources.inputs.git-repo.path)"
          description = "Directory with package.json"
          name        = "context_path"
          type        = "string"
        },
      ]
      resources = {
        inputs = [
          {
            name = "git-repo"
            type = "git"
          },
        ]
      }
      steps = [
        {
          image     = "$(params.container_image)"
          name      = "npm-tests"
          resources = {}
          script    = file("./npm-tests.sh")
          workingDir : "$(params.context_path)"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "task_npm_test_e2e" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "npm-test-e2e"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      description = "Run NPM cypress test on repo"
      params = [
        {
          default     = "cypress/base:16.5.0"
          description = "Node image to run in"
          name        = "container_image"
          type        = "string"
        },
        {
          default     = "$(resources.inputs.git-repo.path)"
          description = "Directory with package.json"
          name        = "context_path"
          type        = "string"
        },
      ]
      resources = {
        inputs = [
          {
            name = "git-repo"
            type = "git"
          },
        ]
      }
      steps = [
        {
          image     = "$(params.container_image)"
          name      = "npm-test-e2e"
          resources = {}
          script    = file("./npm-test-e2e.sh")
          workingDir : "$(params.context_path)"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "task_npm_version_tag" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "npm-version-tag"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      description = "Get version of NPM package"
      params = [
        {
          default     = "$(resources.inputs.git-repo.path)"
          description = "Directory with package.json"
          name        = "context_path"
          type        = "string"
        },
      ]
      resources = {
        inputs = [
          {
            name = "git-repo"
            type = "git"
          },
        ]
      }
      results = [
        {
          name        = "version-tag"
          description = "The version tag to use for the container"
        },
      ]
      steps = [
        {
          env = [
            {
              name  = "RESULTS_PATH"
              value = "$(results.version-tag.path)"
            }
          ]
          image     = "alpine"
          name      = "npm-version-tag"
          resources = {}
          script    = file("./npm-version-tag.sh")
          workingDir : "$(params.context_path)"
        },
      ]
    }
  }
}

# resource "kubernetes_manifest" "task_container_deploy" {
#   manifest = {
#     apiVersion = "tekton.dev/v1alpha1"
#     kind       = "Task"
#     metadata = {
#       name      = "container-deploy"
#       namespace = kubernetes_namespace.tekton_workers.metadata[0].name
#     }
#     spec = {
#       description = "Deploy container to infrastructure"
#       params = [
#         {
#           default     = "$(resources.inputs.git-repo.path)"
#           description = "Directory in repo with terragrunt.hcl"
#           name        = "context_path"
#           type        = "string"
#         },
#       ]
#       resources = {
#         inputs = [
#           {
#             name = "git-repo"
#             type = "git"
#           },
#         ]
#       }
#       steps = [
#         {
#           env = [
#             {
#               name  = "RESULTS_PATH"
#               value = "$(results.version-tag.path)"
#             }
#           ]
#           image     = "alpine"
#           name      = "npm-version-tag"
#           resources = {}
#           script    = file("./npm-version-tag.sh")
#           workingDir : "$(params.context_path)"
#         },
#       ]
#     }
#   }
# }

resource "kubernetes_manifest" "pipeline_javascript_cicd" {
  manifest = {
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      name      = "javascript-cicd"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      params = [
        {
          default     = "cypress/base:16.5.0"
          description = "Cypress image to run in"
          name        = "cypress_container_image"
          type        = "string"
        },
        {
          default     = "node:16-alpine"
          description = "Node image to run in"
          name        = "npm_container_image"
          type        = "string"
        },
        {
          default     = "$(resources.inputs.git-repo.path)"
          description = "Directory with package.json"
          name        = "npm_context_path"
          type        = "string"
        },
      ]
      resources = [
        {
          name = "docker-image"
          type = "image"
        },
        {
          name = "git-repo"
          type = "git"
        },
      ]
      "tasks" = [
        {
          name = "tests"
          params = [
            {
              name  = "container_image"
              value = "$(params.npm_container_image)"
            },
            {
              name  = "context_path"
              value = "$(params.npm_context_path)"
            },
          ]
          resources = {
            inputs = [
              {
                name     = "git-repo"
                resource = "git-repo"
              },
            ]
          }
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_npm_tests.object.metadata.name
          }
        },
        {
          name = "test-e2e"
          params = [
            {
              name  = "container_image"
              value = "$(params.cypress_container_image)"
            },
            {
              name  = "context_path"
              value = "$(params.npm_context_path)"
            },
          ]
          resources = {
            inputs = [
              {
                name     = "git-repo"
                resource = "git-repo"
              },
            ]
          }
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_npm_test_e2e.object.metadata.name
          }
        },
        {
          name = "version-tag"
          params = [
            {
              name  = "context_path"
              value = "$(params.npm_context_path)"
            },
          ]
          resources = {
            inputs = [
              {
                name     = "git-repo"
                resource = "git-repo"
              },
            ]
          }
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_npm_version_tag.object.metadata.name
          }
        },
        {
          name = "build"
          params = [
            {
              name  = "version_tag"
              value = "$(tasks.version-tag.results.version-tag)"
            },
          ]
          resources = {
            inputs = [
              {
                name     = "git-repo"
                resource = "git-repo"
              },
            ]
            "outputs" = [
              {
                name     = "docker-image"
                resource = "docker-image"
              },
            ]
          }
          "runAfter" = [
            "tests",
            "test-e2e",
            "version-tag",
          ]
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_docker_build.object.metadata.name
          }
        },
      ]
    }
  }
}
