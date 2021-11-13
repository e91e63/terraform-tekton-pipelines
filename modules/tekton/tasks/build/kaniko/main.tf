locals {
  conf = defaults(var.conf, {
    name = "kaniko"
  })
}

module "main" {
  source = "../../../../tekton/tasks"

  conf = {
    description = "build code repo into a container"
    name        = "${local.conf.name}-build"
    namespace   = local.conf.namespace
    params = [
      {
        description = "kaniko build context path"
        name        = local.conf.labels.context_path
      },
      {
        description = "version tag for container artifact"
        name        = local.conf.labels.version_tag
      },
    ]
    resources = {
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
          "--context=${local.conf.labels.working_dir}",
          "--destination=$(outputs.resources.${local.conf.labels.docker_image}.url):$(params.${local.conf.labels.version_tag})",
          "--dockerfile=$(${local.conf.labels.working_dir})/Dockerfile",
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
    workspaces = [
      {
        name = local.conf.labels.git_repo_workspace
      },
    ]
  }
}
