output "info" {
  sensitive = true
  value = merge(
    module.main.info,
    {
      webhook_token = kubernetes_secret.webhook_token.data[local.labels.webhook_token]
    }
  )
}
