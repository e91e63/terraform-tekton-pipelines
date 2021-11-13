variable "conf" {
  type = object({
    bindings = map(string)
    images   = map(string)
    labels   = map(string)
    interceptors = map(object({
      event_types = list(string)
      name        = string
    }))
    name               = optional(string)
    namespace          = string
    secret_names       = map(string)
    service_accounts   = map(string)
    tasks              = map(string)
    webhooks_subdomain = string
    workflow_name      = optional(string)
  })
}

variable "domain_info" {
  type = any
}
