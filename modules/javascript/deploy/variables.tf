
variable "task_conf" {
  type = object({
    namespace = string
    secret_names = object({
      age_keys            = string
      digitalocean_spaces = string
    })
  })
}
