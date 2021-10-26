variable "container_registry_info" {
  type = object({
    name = string
  })
}

variable "domain_info" {
  default = {}
  type    = any
}

variable "git_conf" {
  type = object({
    domain          = string
    namespace       = string
    private_key_pem = string
  })
}

variable "gitlab_project_info" {
  type = object({
    path = string
    url = string
  })
}


variable "tekton_conf" {
  sensitive = true
  type = object({
    age_keys_file_base64       = string
    digitalocean_spaces_key    = string
    digitalocean_spaces_secret = string
  })
}
