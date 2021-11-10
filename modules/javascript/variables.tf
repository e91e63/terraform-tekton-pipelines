variable "conf" {
  type = object({
    images = object({
      alpine     = string
      cypress    = string
      kaniko     = string
      node       = string
      terragrunt = string
    })
    interceptors = any
    namespace    = string
    secret_names = any
    triggers = object({
      service_account_name = string
    })
    webhooks_subdomain = string
    workers = object({
      service_account_name = string
    })
    workflow_name = optional(string)
  })
}

variable "domain_info" {
  type = any
}
