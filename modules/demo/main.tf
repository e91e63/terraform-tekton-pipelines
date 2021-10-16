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
    "apiVersion" = "tekton.dev/v1alpha1"
    "kind"       = "TaskRun"
    "metadata" = {
      annotations = {
        "pipeline.tekton.dev/release" = "f8c2eea"
      }
      labels = {
        "app.kubernetes.io/managed-by" = "tekton-pipelines"
        "tekton.dev/task"              = "echo-hello-world"
      }
      "name"    = "echo-hello-world-task-run"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    "spec" = {
      serviceAccountName = kubernetes_service_account.main.metadata[0].name
      "taskRef" = {
        kind   = "Task"
        "name" = "echo-hello-world"
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
  write = true
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
resource "kubernetes_manifest" "pipeline_source_todo" {
  manifest = {
    "apiVersion" = "tekton.dev/v1alpha1"
    "kind"       = "PipelineResource"
    "metadata" = {
      "name"    = "git-todo"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    "spec" = {
      "params" = [
        {
          "name"  = "revision"
          "value" = "main"
        },
        {
          "name"  = "url"
          "value" = "git@gitlab.com:cddc39/todo.git"
        },
      ]
      "type" = "git"
    }
  }
}

resource "kubernetes_manifest" "pipelineresource_todo_image" {
  manifest = {
    "apiVersion" = "tekton.dev/v1alpha1"
    "kind"       = "PipelineResource"
    "metadata" = {
      "name"    = "todo-image"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    "spec" = {
      "params" = [
        {
          "name"  = "url"
          "value" = "registry.digitalocean.com/dmikalova/todo"
        },
      ]
      "type" = "image"
    }
  }
}

resource "kubernetes_manifest" "task_build_docker_image_from_git_source" {
  manifest = {
    "apiVersion" = "tekton.dev/v1alpha1"
    "kind"       = "Task"
    "metadata" = {
      name      = "build-docker-image-from-git-source"
      namespace = kubernetes_namespace.tekton_workers.metadata[0].name
    }
    "spec" = {
      "params" = [
        {
          "default"     = "/workspace/${kubernetes_manifest.pipeline_source_todo.object.metadata.name}/Dockerfile"
          "description" = "The path to the dockerfile to build"
          "name"        = "pathToDockerFile"
          "type"        = "string"
        },
        {
          "default"     = "/workspace/${kubernetes_manifest.pipeline_source_todo.object.metadata.name}"
          "description" = "The build context used by Kaniko (https://github.com/GoogleContainerTools/kaniko#kaniko-build-contexts)"
          "name"        = "pathToContext"
          "type"        = "string"
        },
      ]
      "resources" = {
        inputs = [
          {
            "name" = kubernetes_manifest.pipeline_source_todo.object.metadata.name
            "type" = "git"
          },
        ]
        outputs = [
          {
            "name" = kubernetes_manifest.pipelineresource_todo_image.object.metadata.name
            "type" = "image"
          },
        ]
      }
      "steps" = [
        {
          "args" = [
            "--dockerfile=$(inputs.params.pathToDockerFile)",
            "--destination=$(outputs.resources.${kubernetes_manifest.pipelineresource_todo_image.object.metadata.name}.url)",
            "--context=$(inputs.params.pathToContext)",
          ]
          "command" = [
            "/kaniko/executor",
          ]
          "env" = [
            {
              "name"  = "DOCKER_CONFIG"
              "value" = "/tekton/home/.docker/"
            },
          ]
          "image"     = "gcr.io/kaniko-project/executor:v1.6.0"
          "name"      = "build-and-push"
          "resources" = {}
        },
      ]
    }
  }
}
