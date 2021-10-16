variable "git_conf" {
  type = object({
    domain          = string
    namespace       = string
    private_key_pem = string
  })
}

variable "container_registry_info" {
  type = object({
    name = string
  })
}
