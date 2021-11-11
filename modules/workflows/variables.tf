variable "conf" {
  type = object({
    images             = any
    interceptors       = any
    namespace          = string
    secrets            = any
    service_accounts   = optional(any)
    webhooks_subdomain = optional(string)
  })
}

variable "domain_info" {
  type = any
}
