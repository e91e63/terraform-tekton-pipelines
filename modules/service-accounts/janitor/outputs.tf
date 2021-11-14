output "info" {
  value = {
    name = kubernetes_service_account.main.metadata[0].name
  }
}
