terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {
    name = "terragrunt"
  })
  gpg_dir = "/root/.config/gpg"
}

module "main" {
  source = "../../../tekton/task"

  conf = {
    description = "deploy container to infrastructure"
    name        = "${local.conf.name}-deploy"
    namespace   = local.conf.namespace
    spec = {
      params = [[
        {
          description = "terragrunt context"
          name        = local.conf.labels.context_path
        },
        {
          description = "digest of docker image to deploy"
          name        = local.conf.labels.docker_image_digest
        },
      ]]
      steps = [[
        {
          "env" = [[
            {
              name  = "GPG_DIR"
              value = local.gpg_dir
            },
            {
              name  = "IMAGE_DIGEST"
              value = "$(params.${local.conf.labels.docker_image_digest})"
            },
          ]]
          image  = var.conf.images.terragrunt
          name   = "git-commit-push"
          script = file("${path.module}/../../git/scripts/git-commit-push.sh")
          volumeMounts = [[
            {
              mountPath = local.gpg_dir
              name      = local.conf.labels.gpg_key
            },
          ]]
          workingDir = local.conf.working_dir
        },
        {
          "env" = [[
            {
              name = "AWS_ACCESS_KEY_ID"
              valueFrom = {
                secretKeyRef = {
                  name = var.conf.secrets.names.terraform_remote_state
                  key  = "AWS_ACCESS_KEY_ID"
                }
              }
            },
            {
              name = "AWS_SECRET_ACCESS_KEY"
              valueFrom = {
                secretKeyRef = {
                  name = var.conf.secrets.names.terraform_remote_state
                  key  = "AWS_SECRET_ACCESS_KEY"
                }
              }
            },
          ]]
          image  = var.conf.images.terragrunt
          name   = "terragrunt-plan-apply"
          script = file("${path.module}/scripts/terragrunt-plan-apply.sh")
          volumeMounts = [[
            {
              mountPath = "/root/.config/sops/age"
              name      = local.conf.labels.age_keys_file
            },
          ]]
          workingDir = local.conf.working_dir
        },
      ]]
      volumes = [[
        {
          name = local.conf.labels.age_keys_file
          secret = {
            secretName = local.conf.secrets.names.age_keys_file
          }
        },
        {
          name = local.conf.labels.gpg_key
          secret = {
            secretName = local.conf.secrets.names.gpg_key
          }
        },
      ]]
      workspaces = [[
        {
          name = local.conf.labels.git_repo_workspace
        },
      ]]
    }
  }
}
