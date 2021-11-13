variable "conf" {
  type = object({
    bindings = map(string)
    images   = map(string)
    interceptors = map(object({
      event_types = list(string)
      name        = string
    }))
    labels           = optional(map(string))
    namespace        = string
    secrets          = map(map(string))
    service_accounts = optional(map(string))
    webhooks = object({
      middlewares = list(map(string))
      subdomain   = optional(string)
    })
    working_dir = optional(string)
  })
}

variable "domain_info" {
  type = any
}
