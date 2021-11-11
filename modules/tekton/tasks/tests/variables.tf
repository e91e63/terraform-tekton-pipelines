variable "conf" {
  type = object({
    images = object({
      default      = string
      dependencies = optional(string)
      fmt          = optional(string)
      lint         = optional(string)
      tests_e2e    = optional(string)
      tests_unit   = optional(string)
      version_tag  = optional(string)
    })
    labels = object({
      git_repo     = string
      context_path = string
      version_tag  = string
    })
    name      = string
    namespace = string
    scripts = object({
      dependencies = string
      fmt          = string
      lint         = string
      tests_e2e    = string
      tests_unit   = string
      version_tag  = string
    })
  })
}
