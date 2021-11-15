output "info" {
  value = {
    name = kubernetes_manifest.main.object.metadata.name
  }
}
