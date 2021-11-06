variable "trigger_template_conf" {
  type = object({
    name      = string
    namespace = string
    params = list(object({
      description = string
      name        = string
    }))
    resource_templates = list(object({
      metadata = object({
        generate_name = string
        namespace     = string
      })
      spec = object({
        pipeline_ref = object({
          name = string
        })
        resource_refs = object({
          name = string
          resource_ref = object({
            name = string
          })
        })
        resource_specs = object({
          name = string
          resource_spec = {
            params = list(object({
              name  = string
              value = string
            }))
            type = string
          }
        })
        service_account_name = string
      })
    }))
  })
}
