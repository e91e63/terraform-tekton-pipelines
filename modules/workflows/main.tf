# locals {
#   # pipeline_conf = defaults(var.pipeline_conf, {
#   #   tasks = [
#   #     module.task_test.taskRef,
#   #     module.task_build.taskRef,
#   #     module.task_deploy.taskRef,
#   #   ]
#   # })
#   # route_service_name = "webhooks"
#   # route_path         = kubernetes_manifest.event_listener_gitlab_javascript_cicd_pipeline.object.metadata.name
#   task_build_conf = defaults(var.task_build_conf, {})
#   # task_deploy_conf   = defaults(var.task_deploy_conf, {})
#   # task_test_conf     = defaults(var.task_test_conf, {})
#   # webhook_url        = "https://${local.route_service_name}.${var.domain_info.name}/${local.route_path}"
# }

module "baseline" {
  source = "../baseline"

  conf = {
    credentials                   = var.conf.credentials
    namespace                     = var.conf.namespace
    triggers_service_account_name = var.conf.triggers_service_account_name
    workers_service_account_name  = var.conf.workers_service_account_name
  }
}

module "javascript" {
  source = "../javascript"

  conf = {
    images       = var.conf.images
    interceptors = var.conf.interceptors
    namespace    = var.conf.namespace
    secret_names = module.baseline.info.secret_names
    triggers = {
      service_account_name = module.baseline.info.service_account_names.triggers
    }
    workers = {
      service_account_name = module.baseline.info.service_account_names.workers
    }
  }
}

# module "pipeline" {
#   source = "../tekton-pipeline"

#   conf = local.pipeline_conf
# }

# module "task_build" {
#   source = "../tekton-task"

#   conf = local.conf.tasks.build
# }

# module "task_deploy" {
#   source = "../tekton-task"

#   conf = local.task_deploy_conf
# }

# module "task_test" {
#   source = "../tekton-task"

#   conf = local.task_test_conf
# }

# module "webhook_ingress" {
#   source = "git@gitlab.com:e91e63/terraform-kubernetes-manifests.git//modules/traefik-ingress-route"

#   domain_info = var.domain_info
#   route_conf = {
#     middlewares  = []
#     path         = local.route_path
#     service_name = "${kubernetes_manifest.event_listener_gitlab_javascript_cicd_pipeline.object.metadata.name}-event-listener"
#     service_port = 8080
#   }
#   service_conf = {
#     name      = local.route_service_name
#     namespace = kubernetes_namespace.tekton_workers.metadata[0].name
#   }
# }

# resource "gitlab_project_hook" "main" {
#   enable_ssl_verification   = true
#   project                   = var.gitlab_project_info.path
#   push_events               = true
#   push_events_branch_filter = "main"
#   token                     = kubernetes_secret.gitlab_webhook_secret_token.data["secret-token"]
#   url                       = local.webhook_url
# }

# resource "kubernetes_secret" "webhook_secret_token" {
#   data = {
#     "secret-token" = random_password.webhook_secret_token.result
#   }
#   metadata {
#     name      = "${var.conf.name}-webhook-secret-token"
#     namespace = var.conf.namespace
#   }
#   type = "Opaque"
# }

# resource "random_password" "webhook_secret_token" {
#   length  = 16
#   special = true
# }
