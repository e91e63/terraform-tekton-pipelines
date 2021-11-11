locals {
  conf = defaults(var.conf, {
    name = "javascript"
  })
}

module "task_tests" {
  source = "./tests"

  conf = local.conf
}

module "main" {
  source = "../workflows/test-build-deploy"

  conf = merge(local.conf, {
    tasks = {
      build  = local.conf.tasks.build
      deploy = local.conf.tasks.deploy
      tests  = module.task_tests.info.name
    }
  })
  domain_info = var.domain_info
}
