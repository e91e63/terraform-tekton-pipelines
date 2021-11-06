module "main" {
  source = "../"

  event_listener_conf = {
    name                 = "javascript-test-build-deploy"
    namespace            = var.event_listener_conf.namespace
    service_account_name = var.event_listener_conf.service_account_name
    triggers = [
      {
        bindings = [
          {
            kind = "TriggerBinding"
            ref  = kubernetes_manifest.trigger_binding_javascript_cicd_pipeline.object.metadata.name
          },
        ]
        interceptors = [
          {
            params = [
              {
                name = "secretRef"
                value = {
                  secretKey  = "secret-token"
                  secretName = kubernetes_secret.gitlab_webhook_secret_token.metadata[0].name
                }
              },
              {
                name  = "eventTypes"
                value = ["Push Hook"]
              }
            ]
            ref = {
              kind = "Interceptor"
              name = "gitlab"
            }
          },
        ]
        name = "gitlab-listener"
        template = {
          ref = kubernetes_manifest.trigger_template_javascript_cicd_pipeline.object.metadata.name
        }
      },
    ]
  }
}
