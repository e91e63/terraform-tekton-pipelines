variable "conf" {
  type = object({
    images = object({
      alpine     = string
      cypress    = string
      kaniko     = string
      node       = string
      terragrunt = string
    })
    namespace     = string
    secret_names  = any
    workflow_name = optional(string)
  })
}
