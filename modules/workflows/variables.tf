variable "conf" {
  type = object({
    images = map(string)
    interceptors = map(object({
      event_types = list(string)
      name        = string
    }))
    namespace          = string
    secrets            = map(map(string))
    service_accounts   = optional(map(string))
    webhooks_subdomain = optional(string)
  })
}

variable "domain_info" {
  type = any
}
