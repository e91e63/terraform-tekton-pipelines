variable "conf" {
  type = object({
    labels = object({
      git_repo_url       = string
      git_repo_workspace = string
      git_repo_url       = string
      git_repo_workspace = string
    })
    images = object({
      alpine = string
    })
    name      = optional(string)
    namespace = string
  })
}
