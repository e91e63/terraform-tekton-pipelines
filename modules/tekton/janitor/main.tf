locals {
  conf = defaults(var.conf, {
    name = "tekton-janitor"
  })
}

resource "kubernetes_cron_job" "main" {
  metadata {
    labels = {
      app                           = local.conf.name
      "app.kubernetes.io/component" = "janitor"
      "app.kubernetes.io/name"      = local.conf.name
      "app.kubernetes.io/part-of"   = "tekton"
    }
    name      = local.conf.name
    namespace = local.conf.namespace
  }
  spec {
    concurrency_policy = "Forbid"
    job_template {
      metadata {
        labels = {
          app                           = local.conf.name
          "app.kubernetes.io/component" = "janitor"
          "app.kubernetes.io/name"      = local.conf.name
          "app.kubernetes.io/part-of"   = "tekton"
        }
        name = local.conf.name
      }
      spec {
        template {
          metadata {
            labels = {
              app                           = local.conf.name
              "app.kubernetes.io/component" = "janitor"
              "app.kubernetes.io/name"      = local.conf.name
              "app.kubernetes.io/part-of"   = "tekton"
            }
            name = local.conf.name
          }
          spec {
            container {
              command = [
                "/bin/bash",
                "-c",
                file("${path.module}/scripts/janitor.sh"),
              ]
              env {
                name  = "FAIL_TTL_MINUTES"
                value = 30
              }
              env {
                name  = "NAMESPACE"
                value = local.conf.namespace
              }
              env {
                name  = "SUCCESS_KEEP_NUM"
                value = 5
              }
              image = local.conf.images.kubectl
              name  = "kubectl"
              resources {
                limits = {
                  cpu    = "100m"
                  memory = "64Mi"
                }
                requests = {
                  cpu    = "50m"
                  memory = "32Mi"
                }
              }
            }
            restart_policy       = "OnFailure"
            service_account_name = local.conf.service_accounts.janitor
          }
        }
      }
    }
    schedule = "*/15 * * * *"
  }
}
