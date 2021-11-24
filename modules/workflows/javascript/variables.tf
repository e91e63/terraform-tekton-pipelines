variable "conf" {
  type = object({
    bindings                    = map(string)
    container_registry_endpoint = string
    images                      = map(string)
    interceptors = map(object({
      event_types = list(string)
      name        = string
    }))
    labels           = map(string)
    name             = optional(string)
    namespace        = string
    secrets          = map(map(string))
    service_accounts = map(string)
    tasks            = map(string)
    webhooks = object({
      middlewares = list(map(string))
      subdomain   = string
    })
    workflow_name = optional(string)
    working_dir   = string
  })
}

variable "domain_info" {
  type = any
}
