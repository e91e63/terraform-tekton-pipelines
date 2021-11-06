variable "conf" {
  type = object({
    docker_secret_name = string
    git_secret_name    = string
    name               = optional(string)
    namespace          = string
  })
}
