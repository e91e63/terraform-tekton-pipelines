variable "conf" {
  type = object({
    images = object({
      alpine     = string
      cypress    = string
      kaniko     = string
      node       = string
      terragrunt = string
    })
    namespace    = string
    secret_names = any
    triggers = object({
      service_account_name = string
    })
    workers = object({
      service_account_name = string
    })
    workflow_name = optional(string)
  })
}
