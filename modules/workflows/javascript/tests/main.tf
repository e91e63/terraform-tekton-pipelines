terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {})
}

module "main" {
  source = "../../../tasks/tests"

  conf = merge(
    local.conf,
    {
      images = {
        default     = local.conf.images.node
        tests_e2e   = local.conf.images.cypress
        version_tag = local.conf.images.alpine
      }
      scripts = {
        dependencies = file("${path.module}/scripts/npm-dependencies.sh")
        tests_e2e    = file("${path.module}/scripts/npm-tests-e2e.sh")
        fmt          = file("${path.module}/scripts/npm-fmt.sh")
        lint         = file("${path.module}/scripts/npm-lint.sh")
        tests_unit   = file("${path.module}/scripts/npm-tests-unit.sh")
        version_tag  = file("${path.module}/scripts/version-tag.sh")
      }
    },
  )
}
