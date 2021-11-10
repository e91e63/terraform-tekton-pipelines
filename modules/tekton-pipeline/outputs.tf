output "info" {
  value = {
    name = kubernetes_manifest.pipeline.object.metadata.name
  }
}
