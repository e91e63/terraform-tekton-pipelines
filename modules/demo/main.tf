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
            "--destination=$(outputs.resources.docker-image.url)",
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
          name      = "build-and-push"
          resources = {}
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "task_npm" {
  manifest = {
    apiVersion = "tekton.dev/v1alpha1"
    kind       = "Task"
    metadata = {
      name      = "npm"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    spec = {
      description = "Run an NPM command on repos"
      params = [
        {
          description = "Arguments to pass to NPM"
          name        = "run_command"
          type        = "string"
        },
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
          env = [
            {
              name  = "RUN_COMMAND"
              value = "$(params.run_command)"
            }
          ]
          image     = "$(params.container_image)"
          name      = "npm"
          resources = {}
          script    = file("./npm.sh")
          workingDir : "$(params.context_path)"
        },
      ]
    }
  }
}

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
          name = "npm-lint"
          params = [
            {
              name  = "run_command"
              value = "lint"
            },
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
          retries = 3
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_npm.object.metadata.name
          }
        },
        # {
        #   name = "test"
        #   resources = {
        #     inputs = [
        #       {
        #         name     = "workspace"
        #         resource = "my-repo"
        #       },
        #     ]
        #   }
        #   taskRef = {
        #     name = "make-test"
        #   }
        # },
        {
          name = "build"
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
          retries = 3
          "runAfter" = [
            "npm-lint",
          ]
          taskRef = {
            kind = "Task"
            name = kubernetes_manifest.task_docker_build.object.metadata.name
          }
        },
        # {
        #   name = "build-frontend"
        #   resources = {
        #     inputs = [
        #       {
        #         name     = "workspace"
        #         resource = "my-repo"
        #       },
        #     ]
        #     "outputs" = [
        #       {
        #         name     = "image"
        #         resource = "my-frontend-image"
        #       },
        #     ]
        #   }
        #   "runAfter" = [
        #     "test-app",
        #   ]
        #   taskRef = {
        #     name = "kaniko-build-frontend"
        #   }
        # },
        # {
        #   name = "deploy-all"
        #   resources = {
        #     inputs = [
        #       {
        #         "from" = [
        #           "build-app",
        #         ]
        #         name     = "my-app-image"
        #         resource = "my-app-image"
        #       },
        #       {
        #         "from" = [
        #           "build-frontend",
        #         ]
        #         name     = "my-frontend-image"
        #         resource = "my-frontend-image"
        #       },
        #     ]
        #   }
        #   taskRef = {
        #     name = "deploy-kubectl"
        #   }
        # },
      ]
    }
  }
}
