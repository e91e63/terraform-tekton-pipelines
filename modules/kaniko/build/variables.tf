variable "conf" {
  type = object({
    labels = object({
      context_path        = string
      docker_image        = string
      docker_image_digest = string
      git_repo            = string
      version_tag         = string
    })
    images = object({
      kaniko = string
    })
    name      = optional(string)
    namespace = string
  })
}
