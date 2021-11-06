resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "TriggerTemplate"
    metadata = {
      name      = var.trigger_template_conf.name
      namespace = var.trigger_template_conf.namespace
    }
    spec = {
      params = var.trigger_template_conf.params
      resourceTemplates = {
        metadata = var.trigger_template_conf.resource_templates.metadata
        spec = {
          pipelineRef = var.trigger_template_conf.resource_templates.spec.pipeline_ref
          resources = concat(
            var.trigger_template_conf.resource_templates.spec.resource_refs,
            var.trigger_template_conf.resource_templates.spec.resource_specs,
          )
          service_account_name = var.trigger_template_conf.resource_templates.spec.service_account_name
        }
      }
    }
  }
}
