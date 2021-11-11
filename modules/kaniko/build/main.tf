locals {
  conf = defaults(var.conf, {
    name = "kaniko"
  })
}

module "main" {
  source = "../../tekton/tasks"

  conf = {
    description = "build code repo into a container"
    name        = "${local.conf.name}-build"
    namespace   = local.conf.namespace
    params = [
      {
        default     = "$(resources.inputs.${local.conf.labels.git_repo}.path)"
        description = "kaniko build context path"
        name        = local.conf.labels.context_path
        type        = "string"
      },
      {
        description = "version tag for container artifact"
        name        = local.conf.labels.version_tag
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
      outputs = [
        {
          name = local.conf.labels.docker_image
          type = "image"
        },
      ]
    }
    results = [
      {
        name        = local.conf.labels.docker_image_digest
        description = "build image digest"
      }
    ]
    steps = [
      {
        args = [
          "--cache=true",
          "--context=$(inputs.params.${local.conf.labels.context_path})",
          "--destination=$(outputs.resources.${local.conf.labels.docker_image}.url):$(inputs.params.${local.conf.labels.version_tag})",
          "--dockerfile=$(inputs.params.${local.conf.labels.context_path})/Dockerfile",
          "--image-name-tag-with-digest-file=$(results.${local.conf.labels.docker_image_digest}.path)",
          "--oci-layout-path=$(outputs.resources.${local.conf.labels.docker_image}.path)",
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
        image = var.conf.images.kaniko
        name  = "build"
      },
    ]
  }
}
