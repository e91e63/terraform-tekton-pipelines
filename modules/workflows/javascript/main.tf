terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {
    workflow_name = "javascript"
  })
}

module "task_tests" {
  source = "./tests"

  conf = local.conf
}

module "main" {
  source = "../../pipelines/test-build-deploy"

  conf = merge(local.conf, {
    tasks = merge(
      local.conf.tasks,
      { tests = module.task_tests.info.name },
    )
  })
  domain_info = var.domain_info
}
