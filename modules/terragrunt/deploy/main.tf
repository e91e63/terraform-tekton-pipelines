locals {
  conf = defaults(var.conf, {
    name = "terragrunt"
  })
}

module "main" {
  source = "../../tekton/tasks"

  conf = {
    description = "deploy container to infrastructure"
    name        = "${local.conf.name}-deploy"
    namespace   = local.conf.namespace
    params = [
      {
        description = "terragrunt context"
        name        = local.conf.labels.context_path
        type        = "string"
      },
      {
        description = "digest of docker image to deploy"
        name        = local.conf.labels.docker_image_digest
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
    }
    steps = [
      # TODO: split out git commit step
      {
        "env" = [
          {
            name = "AWS_ACCESS_KEY_ID"
            valueFrom = {
              secretKeyRef = {
                name = var.conf.secret_names.terraform_remote_state
                key  = "AWS_ACCESS_KEY_ID"
              }
            }
          },
          {
            name = "AWS_SECRET_ACCESS_KEY"
            valueFrom = {
              secretKeyRef = {
                name = var.conf.secret_names.terraform_remote_state
                key  = "AWS_SECRET_ACCESS_KEY"
              }
            }
          },
          {
            name  = "IMAGE_DIGEST"
            value = "$(params.${local.conf.labels.docker_image_digest})"
          },
        ]
        image  = var.conf.images.terragrunt
        name   = "deploy"
        script = file("${path.module}/scripts/terragrunt-plan-apply.sh")
        volumeMounts = [
          {
            name      = local.conf.labels.age_keys_file
            mountPath = "/root/.config/sops/age"
          }
        ]
        workingDir = "$(inputs.resources.git-repo.path)/$(params.${local.conf.labels.context_path})"
      },
    ]
    volumes = [
      {
        name = local.conf.labels.age_keys_file
        secret = {
          secretName = local.conf.secret_names.age_keys_file
        }
      },
    ]
  }
}
