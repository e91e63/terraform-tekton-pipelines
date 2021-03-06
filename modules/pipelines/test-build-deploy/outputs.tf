output "info" {
  value = {
    name          = local.conf.workflow_name
    webhook_token = kubernetes_secret.webhook_token.data[local.conf.labels.webhook_token]
    webhook_url   = module.webhook_ingress.info.url
  }
}
