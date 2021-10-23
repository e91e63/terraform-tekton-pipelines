variable "container_registry_info" {
  type = object({
    name = string
  })
}

variable "git_conf" {
  type = object({
    domain          = string
    namespace       = string
    private_key_pem = string
  })
}

variable "tekton_conf" {
  type = object({
    age_keys_file_base64 = string
  })
}
