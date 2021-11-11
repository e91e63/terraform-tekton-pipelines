variable "conf" {
  type = object({
    images = object({
      alpine     = string
      cypress    = string
      kaniko     = string
      node       = string
      terragrunt = string
    })
    interceptors       = any
    namespace          = string
    secret_names       = any
    service_accounts   = any
    webhooks_subdomain = string
    workflow_name      = optional(string)
  })
}

variable "domain_info" {
  type = any
}
