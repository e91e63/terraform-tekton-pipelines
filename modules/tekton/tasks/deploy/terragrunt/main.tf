locals {
  conf = defaults(var.conf, {
    name = "terragrunt"
  })
}

module "main" {
  source = "../../../../tekton/tasks"

  conf = {
    description = "deploy container to infrastructure"
    name        = "${local.conf.name}-deploy"
    namespace   = local.conf.namespace
    params = [
      {
        description = "terragrunt context"
        name        = local.conf.labels.context_path
      },
      {
        description = "digest of docker image to deploy"
        name        = local.conf.labels.docker_image_digest
      },
    ]
    steps = [
      {
        "env" = [
          {
            name  = "IMAGE_DIGEST"
            value = "$(params.${local.conf.labels.docker_image_digest})"
          },
        ]
        image      = var.conf.images.terragrunt
        name       = "git-commit-push"
        script     = file("${path.module}/../../git/scripts/git-commit-push.sh")
        workingDir = local.conf.working_dir
      },
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
        ]
        image  = var.conf.images.terragrunt
        name   = "terragrunt-plan-apply"
        script = file("${path.module}/scripts/terragrunt-plan-apply.sh")
        volumeMounts = [
          {
            name      = local.conf.labels.age_keys_file
            mountPath = "/root/.config/sops/age"
          }
        ]
        workingDir = local.conf.working_dir
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
    workspaces = [
      {
        name = local.conf.labels.git_repo_workspace
      },
    ]
  }
}
