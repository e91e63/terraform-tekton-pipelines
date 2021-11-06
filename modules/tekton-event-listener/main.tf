resource "kubernetes_manifest" "event_listener_gitlab_javascript_cicd_pipeline" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "EventListener"
    metadata = {
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
      name      = var.event_listener_conf.name
      namespace = var.event_listener_conf.namespace
    }
    spec = {
      namespaceSelector  = {}
      resources          = {}
      serviceAccountName = var.event_listener_conf.service_account_name
      triggers           = var.event_listener_conf.triggers
    }
  }
}
