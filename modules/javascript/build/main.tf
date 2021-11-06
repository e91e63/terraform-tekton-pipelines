module "main" {
  source = "../"

  task_conf = {
    description = "Build container image with Kaniko"
    name        = "build"
    namespace   = var.task_conf.namespace
    params = [
      {
        default     = "$(resources.inputs.git-repo.path)"
        description = "Build context used by Kaniko"
        name        = "context-path"
        type        = "string"
      },
      {
        default     = "$(resources.inputs.git-repo.path)/Dockerfile"
        description = "The path to the dockerfile to build"
        name        = "dockerfile-path"
        type        = "string"
      },
      {
        description = "Container image version tag"
        name        = "version-tag"
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
    results = [
      {
        name        = "image-digest"
        description = "Digest of the built image"
      }
    ]
    steps = [
      {
        args = [
          "--context=$(inputs.params.context-path)",
          "--destination=$(outputs.resources.docker-image.url):$(inputs.params.version-tag)",
          "--dockerfile=$(inputs.params.dockerfile-path)",
          "--image-name-tag-with-digest-file=$(results.image-digest.path)",
          "--oci-layout-path=$(outputs.resources.docker-image.path)"
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
        image = "gcr.io/kaniko-project/executor:v1.6.0"
        name  = "build"
      },
    ]
  }
}
