locals {
  conf = defaults(var.conf, {
    workflow_name = "javascript"
  })
  labels = {
    webhook_token = "webhook-token"
  }
}

resource "random_password" "webhook_token" {
  length  = 16
  special = true
}

resource "kubernetes_secret" "webhook_token" {
  data = {
    (local.labels.webhook_token) = random_password.webhook_token.result
  }
  metadata {
    annotations = {}
    labels      = {}
    name        = "${local.conf.workflow_name}-webhook-token"
    namespace   = local.conf.namespace
  }
  type = "Opaque"
}

module "main" {
  source = "../workflow-test-build-deploy"

  conf = merge(local.conf, {
    interceptors = {
      git = merge(var.conf.interceptors.git, {
        secret_names = {
          webhook_token     = kubernetes_secret.webhook_token.metadata[0].name
          webhook_token_key = local.labels.webhook_token
        }
      })
    }
    tasks = {
      build = {
        images = {
          kaniko = local.conf.images.kaniko
        }
      }
      deploy = {
        images = {
          terragrunt = local.conf.images.terragrunt
        }
        secret_names = local.conf.secret_names
      }
      test = {
        images = {
          default = local.conf.images.alpine
        }
        steps = {
          dependencies = {
            script = file("${path.module}/scripts/npm-dependencies.sh")
          }
          fmt = {
            script = file("${path.module}/scripts/npm-fmt.sh")
          }
          lint = {
            script = file("${path.module}/scripts/npm-lint.sh")
          }
          unit = {
            script = file("${path.module}/scripts/npm-tests-unit.sh")
          }
          e2e = {
            image  = local.conf.images.cypress
            script = file("${path.module}/scripts/npm-tests-e2e.sh")
          }
          version_tag = {
            script = file("${path.module}/scripts/version-tag.sh")
          }
        }
      }
      triggers = local.conf.triggers
      workers  = local.conf.workers
    }
  })
}
