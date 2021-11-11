locals {
  conf = defaults(var.conf, {
    }
  )
}

module "main" {
  source = "../../tekton/tasks/tests"

  conf = {
    images = {
      default     = local.conf.images.node
      e2e         = local.conf.images.cypress
      version_tag = local.conf.images.alpine
    }
    labels    = local.conf.labels
    name      = local.conf.name
    namespace = local.conf.namespace
    scripts = {
      dependencies = file("${path.module}/scripts/npm-dependencies.sh")
      tests_e2e    = file("${path.module}/scripts/npm-tests-e2e.sh")
      fmt          = file("${path.module}/scripts/npm-fmt.sh")
      lint         = file("${path.module}/scripts/npm-lint.sh")
      tests_unit   = file("${path.module}/scripts/npm-tests-unit.sh")
      version_tag  = file("${path.module}/scripts/version-tag.sh")
    }
  }
}
