locals {
  conf = defaults(var.conf, {
    name = "kaniko"
  })
}

module "main" {
  source = "../../../tekton/task"

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
        description = "docker image url"
        name        = local.conf.labels.docker_image_url
      },
      {
        description = "version tag for container artifact"
        name        = local.conf.labels.version_tag
      },
    ]
    results = [
      {
        name        = local.conf.labels.docker_image_digest
        description = "build image digest"
      }
    ]
    steps = [
      {
        args = [
          "--context=${local.conf.working_dir}",
          "--destination=$(params.${local.conf.labels.docker_image_url}):$(params.${local.conf.labels.version_tag})",
          "--dockerfile=${local.conf.working_dir}/Dockerfile",
          "--image-name-tag-with-digest-file=$(results.${local.conf.labels.docker_image_digest}.path)",
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
