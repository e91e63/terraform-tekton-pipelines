resource "kubernetes_manifest" "trigger_binding_javascript_cicd_pipeline" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "TriggerBinding"
    metadata = {
      name      = var.trigger_binding_conf.name
      namespace = var.trigger_binding_conf.namespace
    }
    spec = {
      params = var.trigger_binding_conf.params
    }
  }
}
