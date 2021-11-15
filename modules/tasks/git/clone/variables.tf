variable "conf" {
  type = object({
    labels = object({
      context_path       = string
      git_repo_url       = string
      git_repo_workspace = string
      git_repo_url       = string
      git_repo_workspace = string
    })
    images = object({
      alpine = string
    })
    name        = optional(string)
    namespace   = string
    working_dir = string
  })
}
