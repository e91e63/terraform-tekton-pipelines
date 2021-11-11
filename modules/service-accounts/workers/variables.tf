variable "conf" {
  type = object({
    secret_names = object({
      docker_credentials = string
      git_ssh_key        = string
    })
    name      = optional(string)
    namespace = string
  })
}
