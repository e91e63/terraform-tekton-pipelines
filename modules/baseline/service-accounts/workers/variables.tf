variable "conf" {
  type = object({
    name      = string
    namespace = string
    secrets = object({
      names = object({
        docker_credentials = string
        git_ssh_key        = string
      })
    })
  })
}
