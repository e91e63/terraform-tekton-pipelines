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
    # interceptors = {
    #   git = merge(var.conf.interceptors.git, {
    #     secret_names = {
    #       webhook_token     = kubernetes_secret.webhook_token.metadata[0].name
    #       webhook_token_key = local.labels.webhook_token
    #     }
    #   })
    # }
    tasks = {
      build  = local.conf.tasks.build
      deploy = local.conf.tasks.deploy
      tests  = module.task_tests.info.name

    }
  })
  domain_info = var.domain_info
}
