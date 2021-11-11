output "info" {
  value = {
    name          = local.conf.name
    webhook_token = kubernetes_secret.webhook_token.data[local.conf.labels.webhook_token]
    webhook_url   = local.webhook_url
  }
}
