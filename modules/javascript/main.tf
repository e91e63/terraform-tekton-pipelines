locals {
  conf = defaults(var.conf, {
    workflow_name = "javascript"
  })
}

module "main" {
  source = "../workflow-test-build-deploy"

  conf = merge(local.conf, {
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
    }
  })
}
