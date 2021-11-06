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
    workflow_name = optional(string)
  })
}
