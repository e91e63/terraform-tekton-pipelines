variable "conf" {
  type = object({
    labels = object({
      context_path        = string
      docker_image        = string
      docker_image_digest = string
      git_repo            = string
      git_repo_workspace  = string
      version_tag         = string
      working_dir         = string
    })
    images = object({
      kaniko = string
    })
    name      = optional(string)
    namespace = string
  })
}
