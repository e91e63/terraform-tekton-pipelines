variable "conf" {
  type = object({
    credentials                   = any
    images                        = any
    interceptors                  = any
    namespace                     = string
    triggers_service_account_name = optional(string)
    webhooks_subdomain            = optional(string)
    workers_service_account_name  = optional(string)
  })
}

variable "domain_info" {
  type = any
}
