locals {
  age_keys = "age-keys"
}

module "main" {
  source = "../"

  params = [
    {
      description = "Image to deploy"
      name        = "image"
      type        = "string"
    },
    {
      description = "Directory with terragrunt.hcl"
      name        = "context-path"
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
          name = "AWS_ACCESS_KEY_ID"
          valueFrom = {
            secretKeyRef = {
              name = var.task_conf.secret_names.digitalocean_spaces
              key  = "DIGITALOCEAN_SPACES_KEY"
            }
          }
        },
        {
          name = "AWS_SECRET_ACCESS_KEY"
          valueFrom = {
            secretKeyRef = {
              name = var.task_conf.secret_names.digitalocean_spaces
              key  = "DIGITALOCEAN_SPACES_SECRET"
            }
          }
        },
        {
          name  = "IMAGE"
          value = "$(params.container-image)"
        },
      ]
      # TODO: Create deploy container
      image  = "alpine/terragrunt"
      name   = "container-deploy"
      script = file("./scripts/terragrunt-plan-apply.sh")
      volumeMounts = [
        {
          name      = local.age_keys
          mountPath = "/root/.config/sops/age"
        }
      ]
      workingDir = "$(params.context-path)"
    },
  ]
  volumes = [
    {
      name = local.age_keys
      secret = {
        secretName = var.task_conf.secret_names.age_keys
      }
    },
  ]
}
