output "info" {
  value = {
    name         = kubernetes_manifest.main.object.metadata.name
    path         = "/${kubernetes_manifest.main.object.metadata.name}"
    service_name = "el-${kubernetes_manifest.main.object.metadata.name}"
  }
}
